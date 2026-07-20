output "lambda_security_group_id" {
  description = "Feed this into database/ and cache/ layers as lambda_sg_id"
  value       = aws_security_group.lambda.id
}


output "s3_endpoint_id" {
  value = aws_vpc_endpoint.s3.id
}


