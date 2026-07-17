variable "aws_region" {
  default = "ap-southeast-2"
}

variable "vpc_id" {
  description = "QuizLab VPC"
  default     = "vpc-063bc32cca63bb6c4"
}

variable "private_subnet_ids" {
  description = "Private subnets (ap-southeast-2a, ap-southeast-2b)"
  type        = list(string)
  default = [
    "subnet-0aad841b732a53fdc", # ap-southeast-2a
    "subnet-01020213f0c52f4b5", # ap-southeast-2b
  ]
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}
