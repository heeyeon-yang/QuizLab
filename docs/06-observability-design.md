# 06. Observability Design

## Overview
CloudWatch alarms, an SNS topic, and a CloudWatch dashboard provide alerting and at-a-glance visibility into the QuizLab infrastructure. The alarm set is deliberately scoped to signals that indicate the quiz-generation pipeline is actually broken, rather than every metric CloudWatch can expose.

## Architecture

Resources (ALB/ASG/RDS/ElastiCache/Lambda/SQS)
-> CloudWatch metrics
-> CloudWatch alarms (threshold breach)
-> SNS topic -> email subscription
-> CloudWatch dashboard (manual inspection)


## Design Decisions

### Alarm scope
Alarms cover the layers where a failure directly breaks a user-facing path:
- ALB 5xx rate and unhealthy host count — user-visible failures
- ASG CPU — scaling signal
- RDS CPU and free storage — the stateful layer with the highest blast radius
- Lambda errors and throttles, tracked separately for the trigger and worker functions
- SQS DLQ message count — the final signal that the pipeline dropped a job

ElastiCache CPU was considered and dropped. A cache outage degrades performance but the application still functions; a Lambda error or a DLQ message means a quiz was never generated. Given a fixed number of alarms, degradation-tolerant metrics were traded off against failure-indicating ones.

### Decoupling and how it shows up in alerting
The original design ran PDF parsing, the Bedrock call, and the S3 write inside a single Lambda triggered directly by the S3 upload event. A timeout anywhere in that chain silently dropped the request. Splitting it into a lightweight trigger Lambda (S3 event -> SQS message only) and a worker Lambda (SQS consumer that does the actual processing) means each stage retries independently and failures land in a DLQ instead of disappearing. The alarm set mirrors this split — trigger and worker errors/throttles are tracked as separate alarms, so the alarm itself tells you which stage failed.

As part of this refactor, the trigger Lambda's memory and timeout were reduced (512MB/60s -> 128MB/10s) since it no longer does PDF processing, only a single SQS publish.

### Lambda outside the VPC, and the endpoints that followed from it
Lambda runs outside the VPC to avoid a NAT Gateway. Interface endpoints for Bedrock, Secrets Manager, and SQS had been provisioned earlier under the assumption Lambda would eventually sit inside the VPC — but a Lambda outside the VPC never uses interface endpoints at all, so they were unused. They were removed (the S3 gateway endpoint was kept, since it's used by the EC2 layer). Moving Lambda into the VPC instead would reintroduce the NAT Gateway cost this design was avoiding in the first place, so the endpoints were removed rather than the architecture changed.

### IAM re-scoping
The EC2 IAM role had `AmazonS3FullAccess` attached with no application code using it — removed. The S3 trigger Lambda's role was scoped down to `sqs:SendMessage` only, with S3 read/write and Bedrock invoke permissions moved to the worker Lambda's role, matching what each function actually does post-refactor.

### Dashboard layout
Alarms only fire on threshold breach; the dashboard is for reading the shape of normal operation. It shows ALB request count/5xx, healthy vs unhealthy host count, ASG CPU, RDS CPU/free storage, ElastiCache CPU, Lambda errors/throttles (trigger vs worker side by side), and SQS queue depth alongside DLQ depth.

### Verification
Ran a full PDF upload through the pipeline to confirm the decoupled path behaves as designed: upload triggers the lightweight Lambda (single SQS publish, sub-second), the message is picked up and processed by the worker Lambda (PDF parse, Bedrock call, S3 write), and a quiz JSON lands in the output bucket. Queue depth returned to zero after processing and the DLQ stayed empty throughout, confirming no retries or dropped messages during the run.

## Future Improvements
- Revisit ElastiCache CPU alarm once there's real traffic data to justify it
- Add Bedrock invocation latency/error rate to the dashboard (currently inferred indirectly from Lambda duration/errors)
- Automate the E2E check (upload -> worker -> output bucket) instead of running it manually
