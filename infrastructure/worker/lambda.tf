resource "aws_cloudwatch_log_group" "quiz_worker_logs" {
  name              = "/aws/lambda/quizlab-quiz-worker"
  retention_in_days = 14
}
data "archive_file" "quiz_worker_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/build/quiz_worker.zip"
}
resource "aws_lambda_layer_version" "pypdf_layer" {
  layer_name          = "quizlab-pypdf-layer"
  filename            = "${path.module}/build/pypdf_layer.zip"
  compatible_runtimes = ["python3.12"]
}
resource "aws_lambda_function" "quiz_worker" {
  function_name = "quizlab-quiz-worker"
  role          = aws_iam_role.quiz_worker_role.arn
  handler       = "worker_function.handler"
  runtime       = "python3.12"
  timeout       = 90
  memory_size   = 512
  filename         = data.archive_file.quiz_worker_zip.output_path
  source_code_hash = data.archive_file.quiz_worker_zip.output_base64sha256
  layers = [aws_lambda_layer_version.pypdf_layer.arn]
  environment {
    variables = {
      RESULTS_BUCKET   = var.quizzes_bucket_name
      BEDROCK_MODEL_ID = var.bedrock_model_id
    }
  }
  depends_on = [aws_cloudwatch_log_group.quiz_worker_logs]
}
resource "aws_lambda_event_source_mapping" "quiz_jobs_trigger" {
  event_source_arn = var.quiz_jobs_queue_arn
  function_name    = aws_lambda_function.quiz_worker.arn
  batch_size       = 1
}
