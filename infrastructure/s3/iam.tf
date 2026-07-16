
resource "aws_iam_role" "quiz_lambda_role" {
  name = "quizlab-lambda-quiz-generator-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "quiz_lambda_policy" {
  name = "quizlab-lambda-quiz-generator-policy"
  role = aws_iam_role.quiz_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3Access"
        Effect = "Allow"
        Action = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.uploads.arn}/*"
      },
      {
        Sid    = "S3WriteResults"
        Effect = "Allow"
        Action = ["s3:PutObject"]
        Resource = "${aws_s3_bucket.quizzes.arn}/*"
      },
      {
        Sid    = "BedrockInvoke"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          "arn:aws:bedrock:ap-southeast-2:${data.aws_caller_identity.current.account_id}:inference-profile/au.anthropic.claude-haiku-4-5-20251001-v1:0",
          "arn:aws:bedrock:ap-southeast-2::foundation-model/anthropic.claude-haiku-4-5-20251001-v1:0",
          "arn:aws:bedrock:ap-southeast-4::foundation-model/anthropic.claude-haiku-4-5-20251001-v1:0"
        ]
      },
      {
        Sid    = "Logs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:ap-southeast-2:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}
