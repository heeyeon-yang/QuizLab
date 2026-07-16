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
  timeout       = 60
  memory_size   = 512

  filename         = data.archive_file.quiz_lambda_zip.output_path
  source_code_hash = data.archive_file.quiz_lambda_zip.output_base64sha256

  layers = [aws_lambda_layer_version.pypdf_layer.arn]

  environment {
    variables = {
      RESULTS_BUCKET   = aws_s3_bucket.quizzes.bucket
      BEDROCK_MODEL_ID = "au.anthropic.claude-haiku-4-5-20251001-v1:0"
    }
  }

  depends_on = [aws_cloudwatch_log_group.quiz_lambda_logs]
}

resource "aws_lambda_layer_version" "pypdf_layer" {
  layer_name          = "quizlab-pypdf-layer"
  filename            = "${path.module}/build/pypdf_layer.zip"
  compatible_runtimes = ["python3.12"]
}

resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.quiz_generator.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.uploads.arn
}
