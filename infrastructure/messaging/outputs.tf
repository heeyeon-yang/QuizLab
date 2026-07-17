output "quiz_jobs_queue_url" {
  value = aws_sqs_queue.quiz_jobs.id
}

output "quiz_jobs_queue_arn" {
  value = aws_sqs_queue.quiz_jobs.arn
}

output "quiz_jobs_dlq_arn" {
  value = aws_sqs_queue.quiz_jobs_dlq.arn
}

output "lambda_sqs_policy_arn" {
  description = "Attach this to the Lambda execution role"
  value       = aws_iam_policy.lambda_sqs_access.arn
}
