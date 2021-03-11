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

output "claimant_api_kafka_consumer" {
  value = {
    task_count   = aws_ecs_service.claimant_api_kafka_consumer.desired_count
    cluster_name = data.terraform_remote_state.dataworks_aws_ingestion_ecs_cluster.outputs.ingestion_ecs_cluster.name
    service_name = aws_ecs_service.claimant_api_kafka_consumer.name
  }
}

output "claimant_api_kafka_consumer_iam" {
  value = {
    role = aws_iam_role.claimant_api_kafka_consumer
  }
}
