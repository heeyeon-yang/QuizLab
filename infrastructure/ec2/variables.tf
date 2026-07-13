variable "vpc_id" {
  description = "QuizLab VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "ALB용 Public 서브넷"
  type        = list(string)
  default = [
    "subnet-0d3ed431132b908c0",
    "subnet-05b63c8dfa6b06fed",
    "subnet-05ed81f65b88328a2",
  ]
}

variable "private_subnet_ids" {
  description = "EC2 ASG용 Private 서브넷"
  type        = list(string)
  default = [
    "subnet-0b5d354a4e06401d9",
    "subnet-01020213f0c52f4b5",
  ]
}
