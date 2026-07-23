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

