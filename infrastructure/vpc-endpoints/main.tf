terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------------------------
# Lambda now needs to sit inside the VPC to reach RDS/ElastiCache in private
# subnets. This SG is what RDS/ElastiCache SGs will allow ingress from.
# ---------------------------------------------------------------------------
resource "aws_security_group" "lambda" {
  name        = "quizlab-lambda-sg"
  description = "quizlab-lambda-sg" # keep description identical to console value for future import safety
  vpc_id      = var.vpc_id

  egress {
    description = "Allow all outbound (to RDS/ElastiCache in-VPC and VPC endpoints)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "quizlab-lambda-sg"
    Project = "QuizLab"
  }
}

# ---------------------------------------------------------------------------
# SG for interface endpoints - only allow HTTPS from the Lambda SG
# ---------------------------------------------------------------------------
resource "aws_security_group" "vpc_endpoints" {
  name        = "quizlab-vpce-sg"
  description = "quizlab-vpce-sg"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTPS from Lambda"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "quizlab-vpce-sg"
    Project = "QuizLab"
  }
}

# ---------------------------------------------------------------------------
# S3 Gateway endpoint - free, attaches to route tables of private subnets
# ---------------------------------------------------------------------------
data "aws_route_table" "private" {
  count     = length(var.private_subnet_ids)
  subnet_id = var.private_subnet_ids[count.index]
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = distinct(data.aws_route_table.private[*].id)

  tags = {
    Name    = "quizlab-s3-endpoint"
    Project = "QuizLab"
  }
}

# ---------------------------------------------------------------------------
# Interface endpoints - Bedrock Runtime, SQS, Secrets Manager
# Billed per AZ per hour (~2 AZs each). This is the direct cost trade-off
# against a NAT Gateway - narrower blast radius, comparable idle cost.
# ---------------------------------------------------------------------------
locals {
  interface_services = {
    bedrock_runtime  = "bedrock-runtime"
    sqs              = "sqs"
    secretsmanager   = "secretsmanager"
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each            = local.interface_services
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name    = "quizlab-${each.key}-endpoint"
    Project = "QuizLab"
  }
}
