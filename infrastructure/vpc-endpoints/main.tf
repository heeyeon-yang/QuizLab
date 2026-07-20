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

