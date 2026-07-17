output "cache_endpoint" {
  value = aws_elasticache_cluster.quizlab.cache_nodes[0].address
}

output "cache_security_group_id" {
  value = aws_security_group.cache.id
}
