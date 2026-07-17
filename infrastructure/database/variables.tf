variable "aws_region" {
  default = "ap-southeast-2"
}

variable "vpc_id" {
  default = "vpc-063bc32cca63bb6c4"
}

variable "private_subnet_ids" {
  type = list(string)
  default = [
    "subnet-0aad841b732a53fdc", # ap-southeast-2a
    "subnet-01020213f0c52f4b5", # ap-southeast-2b
  ]
}

variable "lambda_sg_id" {
  description = "Output of vpc-endpoints layer (aws_security_group.lambda.id). Apply vpc-endpoints first."
  type        = string
}

variable "db_name" {
  default = "quizlab"
}

variable "db_username" {
  default = "quizlab_admin"
}

variable "instance_class" {
  description = "db.t3.micro is free-tier eligible for 12 months"
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  default = 20
}

variable "multi_az" {
  description = "Kept false for cost. Portfolio talking point: would flip true for prod HA."
  default     = false
}
