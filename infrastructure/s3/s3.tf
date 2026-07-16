# ==========================================
# S3 - PDF 업로드 버킷
# ==========================================
resource "aws_s3_bucket" "uploads" {
  bucket = "quizlab-uploads-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name    = "quizlab-uploads"
    Project = "quizlab"
  }
}

# 퍼블릭 접근 완전 차단 (presigned URL로만 접근)
resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 기본 암호화 (SSE-S3)
resource "aws_s3_bucket_server_side_encryption_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 업로드된 원본 PDF는 7일 후 자동 삭제 (비용 절감 + 포트폴리오 talking point)
resource "aws_s3_bucket_lifecycle_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    id     = "expire-uploads"
    status = "Enabled"

    filter {}

    expiration {
      days = 7
    }
  }
}

# CORS: 프론트엔드에서 presigned URL로 직접 업로드하려면 필요
resource "aws_s3_bucket_cors_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "GET"]
    allowed_origins = ["*"] # TODO: CloudFront 도메인 확정되면 제한할 것
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# ==========================================
# S3 - 퀴즈 결과(JSON) 저장 버킷
# ==========================================
resource "aws_s3_bucket" "quizzes" {
  bucket = "quizlab-quizzes-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name    = "quizlab-quizzes"
    Project = "quizlab"
  }
}

resource "aws_s3_bucket_public_access_block" "quizzes" {
  bucket = aws_s3_bucket.quizzes.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "quizzes" {
  bucket = aws_s3_bucket.quizzes.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_notification" "uploads_trigger" {
  bucket = aws_s3_bucket.uploads.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.quiz_generator.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".pdf"
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}
