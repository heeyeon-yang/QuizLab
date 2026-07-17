variable "aws_region" {
  default = "ap-southeast-2"
}

variable "vpc_id" {
  default = "vpc-063bc32cca63bb6c4"
}

variable "private_subnet_ids" {
  type = list(string)
  default = [
    "subnet-0aad841b732a53fdc",
    "subnet-01020213f0c52f4b5",
  ]
}

variable "lambda_sg_id" {
  description = "Output of vpc-endpoints layer. Apply vpc-endpoints first."
  type        = string
}

variable "node_type" {
  description = "cache.t3.micro - smallest burstable Redis node"
  default     = "cache.t3.micro"
}
