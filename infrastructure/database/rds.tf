terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_db_subnet_group" "quizlab" {
  name       = "quizlab-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name    = "quizlab-db-subnet-group"
    Project = "QuizLab"
  }
}

resource "aws_security_group" "rds" {
  name        = "quizlab-rds-sg"
  description = "Allow MySQL access from EC2 only"
  vpc_id      = var.vpc_id

  tags = {
    Name    = "quizlab-rds-sg"
    Project = "QuizLab"
  }

  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_security_group_rule" "rds_from_lambda" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = var.lambda_sg_id
  description               = "MySQL from Lambda"
}

resource "random_password" "db_password" {
  length  = 24
  special = false # avoid characters RDS/Secrets Manager JSON escaping chokes on
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "quizlab/rds/credentials"
  description = "QuizLab RDS MySQL credentials"

  tags = {
    Project = "QuizLab"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    dbname   = var.db_name
    engine   = "mysql"
    port     = 3306
  })
}

resource "aws_db_instance" "quizlab" {
  identifier     = "quizlab-db"
  engine         = "mysql"
  engine_version = "8.0"

  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.quizlab.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  multi_az                = var.multi_az
  backup_retention_period = 1 # minimal cost; portfolio-scale, not prod
  skip_final_snapshot     = true # avoid lingering snapshot storage cost on teardown
  deletion_protection     = false # allows easy teardown between layers during dev

  tags = {
    Name    = "quizlab-db"
    Project = "QuizLab"
  }
}
