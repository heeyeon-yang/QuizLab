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
        Sid      = "SQSSend"
        Effect   = "Allow"
        Action   = ["sqs:SendMessage"]
        Resource = var.quiz_jobs_queue_arn
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
