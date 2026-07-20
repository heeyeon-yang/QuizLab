output "uploads_bucket_name" {
  value = aws_s3_bucket.uploads.bucket
}
output "uploads_bucket_arn" {
  value = aws_s3_bucket.uploads.arn
}
output "quizzes_bucket_name" {
  value = aws_s3_bucket.quizzes.bucket
}
output "quizzes_bucket_arn" {
  value = aws_s3_bucket.quizzes.arn
}
