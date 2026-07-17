# Architecture Decisions

This file tracks the significant design decisions made while building QuizLab, along with the alternatives considered and why they were rejected. Written for my own reference and for interview prep.

## AI Pipeline — S3, Lambda, Bedrock

### Model selection

Only Claude Haiku 4.5, accessed through the au.* geographic cross-region inference profile, is available on-demand in ap-southeast-2 without routing inference traffic outside Australia. This was an update from an earlier decision to use Claude 3 Haiku, which Bedrock later retired. No Bedrock model currently supports pure single-region on-demand inference in Sydney — the au.* profile keeps traffic within Sydney and Melbourne, which was close enough to the original data residency goal to still be defensible. Newer or more capable models weren't considered because they'd route requests outside Australia.

### Two S3 buckets instead of one

quizlab-uploads holds the raw PDFs students submit. quizlab-quizzes holds the generated question sets. They're separate on purpose:

- Different lifecycle rules — uploads expire after 7 days, generated quizzes don't
- Different access patterns — uploads are write-once-read-once, quizzes get read repeatedly
- Different IAM scope — the upload path only ever needs to write to one bucket and read from the other, never both directions

A single bucket with prefixes would have worked too, but splitting them made the IAM policies and lifecycle rules cleaner to reason about individually.

### Presigned URLs instead of proxying uploads through the app

Students upload directly to S3 using a presigned URL rather than sending the file through Lambda or the ALB. Keeps large PDF uploads off the application tier entirely, and avoids Lambda's payload size limits.

### Encryption

Both buckets are fully private, SSE-S3 encrypted, no public access.

## RDS, ElastiCache, SQS

This layer is where Lambda first had to join the VPC. RDS and ElastiCache are both private with no public access, so anything talking to them — the quiz-generation Lambda — has to run inside the VPC's private subnets. Once Lambda is in the VPC it loses its default internet route, and that's what drove most of the decisions below: Lambda still needs to reach Bedrock, S3, and SQS, and something had to restore that access.

### VPC endpoints instead of a NAT Gateway

A NAT Gateway would give Lambda a route back to the entire internet. VPC endpoints only restore access to the specific AWS APIs Lambda actually calls — S3, Bedrock Runtime, SQS, Secrets Manager. The S3 endpoint is a free Gateway endpoint; the other three are Interface endpoints billed hourly per AZ, roughly comparable to NAT at idle. The real reason for choosing this over NAT isn't the cost line, though — it's that Lambda's actual requirement was never "internet access," it was "access to four specific AWS services." A NAT Gateway grants far more than that.

Tradeoff: at production scale, with many services needing egress, the per-endpoint hourly cost across multiple AZs can end up costing more than a single NAT Gateway. Worth revisiting if this project ever needed to reach more than a handful of services from inside the VPC.

### Reusing an existing security group instead of creating a duplicate

Applying this layer initially failed with InvalidGroup.Duplicate — quizlab-rds-sg already existed from the compute layer, created in anticipation of EC2 needing direct RDS access, with the description "Allow MySQL access from EC2 only."

Instead of renaming the new resource, the existing security group was imported into Terraform state and extended:

- The description in the Terraform resource had to match the existing AWS value exactly, with lifecycle.ignore_changes on description, since SG descriptions are immutable after creation and any mismatch forces a destroy-and-recreate
- The existing EC2-to-RDS ingress rule was left unmanaged by Terraform rather than imported, so a separate aws_security_group_rule resource could add the new Lambda-to-RDS path without disturbing it

End result: RDS is reachable from EC2 (an admin path, e.g. via SSM Session Manager for migrations) and from Lambda (the application runtime path), and nothing else.

### RDS sizing

db.t3.micro, single-AZ, gp3 storage, encrypted at rest. db.t3.micro is free-tier eligible for the first 12 months. Multi-AZ wasn't enabled — it roughly doubles the cost for automatic failover, which isn't justified without real production traffic. This was a deliberate scope-down, not an oversight, and it's the first thing that would change before this handled real users. skip_final_snapshot and deletion_protection are both off so the resource can be torn down cleanly between iterations during development.

### ElastiCache sizing

cache.t3.micro, single node, no replication group. Same reasoning as the RDS Multi-AZ decision — no failover, which is an explicit and known gap rather than something missed.

### Credentials

The DB password is generated with Terraform's random provider and stored in Secrets Manager rather than hardcoded into a .tf file or passed as a plain variable. Terraform state still holds it in plaintext, which is why state files are never committed and ideally belong in an encrypted remote backend — noted below as something to fix.

### SQS as a buffer between upload and generation

A standard queue (quizlab-quiz-jobs) sits between the upload-triggered Lambda and the Bedrock-calling worker Lambda, with a dead-letter queue after 3 failed receives. This keeps the fast, user-facing part of the flow (upload, presigned URL handoff) separate from the slower and less predictable part (Bedrock inference), and gives failed jobs somewhere to land instead of retrying forever or silently disappearing. Visibility timeout is set to comfortably exceed the expected worker execution time to avoid duplicate processing from premature redelivery.

## Cost summary (approximate, ap-southeast-2, monthly)

| Resource | Estimated cost |
|---|---|
| RDS db.t3.micro, single-AZ, 20GB gp3 | Free tier for 12 months, ~$15-20/mo after |
| ElastiCache cache.t3.micro | ~$12-15/mo |
| SQS, standard queue, low volume | Effectively free |
| Secrets Manager, 1 secret | ~$0.40/mo |
| VPC interface endpoints (3 services x 2 AZs) | ~$15-20/mo |
| VPC gateway endpoint (S3) | Free |
| NAT Gateway avoided | ~$45+/mo saved |

## Future improvements

- Move Terraform state to a remote backend (S3 + DynamoDB lock table) with encryption. Local state currently holds the DB password in plaintext.
- Multi-AZ RDS and a Redis replication group, gated behind an environment variable rather than a hard no.
- IAM database authentication for RDS to remove the long-lived password entirely.
- Revisit the NAT Gateway vs. interface endpoint cost tradeoff if more services need VPC egress.
