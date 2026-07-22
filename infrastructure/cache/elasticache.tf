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

resource "aws_elasticache_subnet_group" "quizlab" {
  name       = "quizlab-cache-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "cache" {
  name        = "quizlab-cache-sg"
  description = "quizlab-cache-sg"
  vpc_id      = var.vpc_id


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "quizlab-cache-sg"
    Project = "QuizLab"
  }
}

# Single node, no replication group - cost-conscious choice for a portfolio
# project. A prod deployment would use a replication group with automatic
# failover; documented as a known trade-off.
resource "aws_elasticache_cluster" "quizlab" {
  cluster_id           = "quizlab-cache"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.node_type
  num_cache_nodes      = 1
  port                 = 6379
  parameter_group_name = "default.redis7"

  subnet_group_name = aws_elasticache_subnet_group.quizlab.name
  security_group_ids = [aws_security_group.cache.id]

  tags = {
    Name    = "quizlab-cache"
    Project = "QuizLab"
  }
}
