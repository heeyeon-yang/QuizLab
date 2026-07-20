terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
variable "aws_region" {
  default = "ap-southeast-2"
}
provider "aws" {
  region = var.aws_region
}
data "aws_caller_identity" "current" {}
