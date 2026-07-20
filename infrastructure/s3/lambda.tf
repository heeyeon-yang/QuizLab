resource "aws_cloudwatch_log_group" "quiz_lambda_logs" {
  name              = "/aws/lambda/quizlab-quiz-generator"
  retention_in_days = 14
}
data "archive_file" "quiz_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/build/quiz_lambda.zip"
}
resource "aws_lambda_function" "quiz_generator" {
  function_name = "quizlab-quiz-generator"
  role          = aws_iam_role.quiz_lambda_role.arn
  handler       = "lambda_function.handler"
  runtime       = "python3.12"
  timeout       = 10
  memory_size   = 128
  filename         = data.archive_file.quiz_lambda_zip.output_path
  source_code_hash = data.archive_file.quiz_lambda_zip.output_base64sha256
  environment {
    variables = {
      QUEUE_URL = var.quiz_jobs_queue_url
    }
  }
  depends_on = [aws_cloudwatch_log_group.quiz_lambda_logs]
}
resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.quiz_generator.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.uploads.arn
}
