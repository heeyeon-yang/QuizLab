variable "uploads_bucket_arn" {}
variable "quizzes_bucket_arn" {}
variable "quizzes_bucket_name" {}
variable "quiz_jobs_queue_arn" {}
variable "bedrock_model_id" {
  default = "au.anthropic.claude-haiku-4-5-20251001-v1:0"
}
