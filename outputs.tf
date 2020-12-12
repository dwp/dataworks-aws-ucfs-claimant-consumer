output "claimant_api_kafka_consumer_sg" {
  value = {
    id   = aws_security_group.claimant_api_kafka_consumer.id
    name = aws_security_group.claimant_api_kafka_consumer.name
    arn  = aws_security_group.claimant_api_kafka_consumer.arn
  }
}

output "secretsmanager_ucfs_claimant_api_kafka_consumer" {
  value = aws_secretsmanager_secret.claimant_api_kafka_consumer
}
