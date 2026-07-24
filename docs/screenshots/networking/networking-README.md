# Networking

QuizLab-vpc is 10.0.0.0/16, split into 2 public and 2 private subnets across ap-southeast-2a/2b.

vpc-resource-map.png — the resource map view, shows all 4 subnets, the route tables, and the only two network connections this VPC has: the internet gateway (public subnets only) and the S3 gateway endpoint.

subnets-list.png — the actual subnet list with CIDRs and route table associations. Private subnets have no route to the internet — there's no NAT Gateway, so that's expected, not a gap.

vpc-s3-gateway-endpoint.png — the S3 endpoint, attached to both private route tables. This is the only VPC endpoint in the whole setup. No interface endpoints for Bedrock, Secrets Manager, or SQS, since the Lambdas that call those live outside the VPC anyway (see main README).

Security groups just chain: internet, then ALB, then EC2, then RDS/ElastiCache.

sg-alb-inbound.png — ALB security group, open on 80 and 443 to everyone. Only thing in this whole setup that's open to 0.0.0.0/0.

sg-ec2-inbound.png — EC2 security group, only accepts port 80 from the ALB security group. Not reachable directly.

sg-rds-inbound.png — RDS security group, only accepts port 3306 from the EC2 security group.

sg-cache-inbound.png — ElastiCache security group, no inbound rules at all right now. There used to be a rule letting a Lambda security group reach Redis on port 6379, from back when I was planning to put Lambda inside the VPC. Didn't end up doing that, so I pulled the rule and the security group it pointed to. Nothing hits the cache right now.
