output "claimant_api_kafka_consumer_sg" {
  value = {
    id   = aws_security_group.claimant_api_kafka_consumer.id
    name = aws_security_group.claimant_api_kafka_consumer.name
    arn  = aws_security_group.claimant_api_kafka_consumer.arn
  }
}
