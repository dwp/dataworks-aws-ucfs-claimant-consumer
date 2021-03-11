resource "aws_cloudwatch_log_metric_filter" "successfully_processed_batch" {
  log_group_name = aws_cloudwatch_log_group.claimant_api_kafka_consumer.name
  name           = local.claimant_api_consumer_processed_batch
  pattern        = "{$.message = \"Processed batch, committing offset\"}"

  metric_transformation {
    name      = local.claimant_api_consumer_processed_batch
    namespace = local.claimant_api_consumer_metrics_namespace
    value     = 1
  }
}

resource "aws_cloudwatch_metric_alarm" "successfully_processed_batch" {
  count       = local.claimant_api_consumer_alert_on_lack_of_processed_batches[local.environment] ? 1 : 0
  metric_name = aws_cloudwatch_log_metric_filter.successfully_processed_batch.name

  namespace           = local.claimant_api_consumer_metrics_namespace
  alarm_name          = "Claimant API Kafka Consumer - Lack of processed batches in the last 3 hours"
  alarm_description   = "Managed by ${local.common_tags.Application} repository"
  alarm_actions       = [local.monitoring_topic_arn]
  evaluation_periods  = 3
  period              = 3600
  threshold           = 1
  statistic           = "Sum"
  comparison_operator = "LessThanThreshold"

  tags = merge(
    local.common_tags,
    {
      Name              = "claimant-api-kafka-consumer-processed-batches",
      notification_type = "Warning",
      severity          = "High"
    },
  )
}


resource "aws_cloudwatch_log_metric_filter" "failed_processing_batch" {
  log_group_name = aws_cloudwatch_log_group.claimant_api_kafka_consumer.name
  name           = local.claimant_api_consumer_failed_batches
  pattern        = "{$.message = \"Inserted record\" || $.message = \"Updated record\"}"

  metric_transformation {
    name      = local.claimant_api_consumer_failed_batches
    namespace = local.claimant_api_consumer_metrics_namespace
    value     = 1
  }
}

resource "aws_cloudwatch_metric_alarm" "failed_processing_batch" {
  count       = local.claimant_api_consumer_alert_on_failed_batches[local.environment] ? 1 : 0
  metric_name = aws_cloudwatch_log_metric_filter.failed_processing_batch.name

  namespace           = local.claimant_api_consumer_metrics_namespace
  alarm_name          = "Claimant API Kafka Consumer - Failed to process batch"
  alarm_description   = "Managed by ${local.common_tags.Application} repository"
  alarm_actions       = [local.monitoring_topic_arn]
  evaluation_periods  = 1
  period              = 300
  threshold           = 1
  statistic           = "Sum"
  comparison_operator = "GreaterThanThreshold"

  tags = merge(
  local.common_tags,
  {
    Name              = "claimant-api-kafka-consumer-failed-processing-batch",
    notification_type = "Warning",
    severity          = "High"
  },
  )
}

