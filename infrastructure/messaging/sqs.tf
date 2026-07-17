terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "aws_region" {
  default = "ap-southeast-2"
}

provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------------------------
# Decouples upload trigger from Bedrock quiz generation: S3 upload -> Lambda
# enqueues a job -> a worker Lambda consumes from this queue and calls
# Bedrock. Keeps the upload path fast and gives natural retry/backoff.
# ---------------------------------------------------------------------------
resource "aws_sqs_queue" "quiz_jobs_dlq" {
  name                      = "quizlab-quiz-jobs-dlq"
  message_retention_seconds = 1209600 # 14 days, max - inspect failures at leisure

  tags = {
    Project = "QuizLab"
  }
}

resource "aws_sqs_queue" "quiz_jobs" {
  name                       = "quizlab-quiz-jobs"
  visibility_timeout_seconds = 300 # match/exceed worker Lambda timeout
  message_retention_seconds  = 345600 # 4 days

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.quiz_jobs_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Project = "QuizLab"
  }
}

data "aws_iam_policy_document" "lambda_sqs_access" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
    ]
    resources = [
      aws_sqs_queue.quiz_jobs.arn,
    ]
  }
}

resource "aws_iam_policy" "lambda_sqs_access" {
  name   = "quizlab-lambda-sqs-access"
  policy = data.aws_iam_policy_document.lambda_sqs_access.json
}
