# Cost Management

Cost was treated as a design constraint throughout this project, not an afterthought. Decisions documented elsewhere in this repo — no NAT Gateway, on-demand Bedrock inference, deferred WAF, CloudFront Price Class 100, short CloudWatch log retention — were all made with actual AWS spend in mind. This folder shows the result.

## Cost and Usage Report

cost-explorer-credit-offset.png

Cost Explorer, filtered to the project's active development period (2026-06-01 to 2026-07-24), grouped by service. Unblended cost — the actual amount AWS billed after Free Tier discounts — comes out to $0.00 across 18 services. This is because every compute and storage choice in this architecture stayed inside Free Tier limits: t3.micro EC2, db.t3.micro RDS, on-demand Bedrock inference, S3 and Lambda usage well under their free thresholds, and CloudFront under its free data transfer allowance.

## Remaining Credit Balance

remaining-credit-balance.png

Separate from the actual bill above, this account has AWS promotional credits available: $200 total, with an estimated $31.91 used against specific credits (EC2, Bedrock, Lambda, RDS, Budgets). These are a different accounting track from Cost Explorer's unblended cost — they reflect the credit program's own usage estimate, not the final invoice. The two numbers aren't expected to match; the credits are a buffer on top of an architecture already designed to bill near zero.

