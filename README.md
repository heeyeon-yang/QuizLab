# QuizLab

QuizLab is an AI-powered quiz generation platform. Students upload lecture PDFs and get practice questions generated automatically through Amazon Bedrock. This is a portfolio project — I built the entire AWS infrastructure from scratch, layer by layer, while studying for the AWS Solutions Architect Associate exam.

## Why I built this

Back in school I worked on a generative AI learning platform that won an award — that project was mostly UX and prompt design. QuizLab is me rebuilding that idea on real cloud infrastructure, with a focus on being able to explain every design choice in an interview, not just make something that works. Each layer has a short design doc with alternatives I considered and the tradeoffs I made.

## Architecture

```
[User] -> [ALB] -> [EC2 ASG]

[S3 uploads] --(presigned URL)--
     |
     v (S3 event)
[Lambda] -> [SQS: quiz-jobs] -> [Lambda worker] -> [Bedrock: Claude Haiku 4.5, au.* profile]
                                      |
                            [RDS MySQL]   [ElastiCache Redis]
                                      |
                                [S3 quizzes]
```

Region is ap-southeast-2 (Sydney). Data residency was treated as a real constraint throughout, not an afterthought — it shaped the Bedrock model choice and the networking decisions below.

Everything is built with Terraform, one layer at a time: networking, then compute, then the AI pipeline, then data/messaging, then CDN/security, then observability.

No NAT Gateway anywhere in this project. Instead of giving Lambda a route to the whole internet, I used VPC endpoints so it can only reach the specific AWS services it actually needs. Cheaper, and a better story for least-privilege design.

## What's built so far

- Networking — VPC, subnets, layered security groups, internet gateway
- Compute — Auto Scaling Group, ALB, IAM role
- AI Pipeline — S3, Lambda, Bedrock | [design doc](docs/architecture-decisions.md#ai-pipeline--s3-lambda-bedrock) 
- RDS / ElastiCache / SQS | [design doc](docs/architecture-decisions.md#rds-elasticache-sqs) 

Still to come: CloudFront/WAF, CloudWatch and IAM hardening.

## A few design decisions worth mentioning

Bedrock model — only Claude Haiku 4.5 through the au.* cross-region inference profile is available on-demand without routing inference traffic outside Australia. Newer or flashier models weren't an option once data residency was a hard requirement.

S3 bucket split — uploads and generated quizzes live in separate buckets on purpose. Different lifecycle rules, different access patterns, different IAM scope. Small thing, but it's a decision I can defend.

VPC endpoints instead of NAT — covered above, but it's probably the single decision I'd talk about most in an interview.

RDS/ElastiCache sizing — single-AZ, small instances, on purpose. I know exactly what I'd change for a production workload and why I didn't build that here.

Credentials — the DB password is generated with Terraform's random provider and stored in Secrets Manager, never hardcoded or committed.

## Stack

Terraform, AWS VPC/EC2/ASG/ALB, S3, Lambda, Amazon Bedrock, RDS (MySQL), ElastiCache (Redis), SQS. CloudFront and WAF are next.

## Repo layout

```
infrastructure/
  vpc/                networking
  ec2/                compute
  s3/                 AI pipeline storage
  lambda/             Bedrock integration
  vpc-endpoints/      NAT replacement
  database/           RDS
  cache/              ElastiCache
  messaging/          SQS
docs/
  03-s3-lambda-bedrock-design.md
  04-rds-elasticache-sqs-design.md
```

## Running this locally

Layers apply in sequence, each with its own state.

```
cd infrastructure/vpc-endpoints
terraform init && terraform apply

# take the lambda_security_group_id output and put it into
# terraform.tfvars in database/ and cache/

cd ../database && terraform init && terraform apply
cd ../cache && terraform init && terraform apply
cd ../messaging && terraform init && terraform apply
```
