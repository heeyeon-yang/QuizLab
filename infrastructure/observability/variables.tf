variable "alert_email" {
  description = "CloudWatch 알람 수신 이메일"
  type        = string
}

variable "aws_region" {
  default = "ap-southeast-2"
}
