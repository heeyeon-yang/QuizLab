variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "ALB용 Public 서브넷"
  type        = list(string)
  default = [
    "subnet-0b5d354a4e06401d9",
    "subnet-04dda6e53cbecaa6a",
  ]
}

variable "private_subnet_ids" {
  description = "EC2 ASG용 Private 서브넷"
  type        = list(string)
  default = [
    "subnet-0aad841b732a53fdc",
    "subnet-01020213f0c52f4b5",
  ]
}
