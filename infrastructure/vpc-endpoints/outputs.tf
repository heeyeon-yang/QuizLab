output "lambda_security_group_id" {
  description = "Feed this into database/ and cache/ layers as lambda_sg_id"
  value       = aws_security_group.lambda.id
}

output "vpc_endpoints_security_group_id" {
  value = aws_security_group.vpc_endpoints.id
}

output "s3_endpoint_id" {
  value = aws_vpc_endpoint.s3.id
}

output "interface_endpoint_ids" {
  value = { for k, v in aws_vpc_endpoint.interface : k => v.id }
}
