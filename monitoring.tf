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
  pattern        = "{$.message = \"Batch failed, not committing offset, resetting position to last commit\"}"

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

resource "aws_cloudwatch_metric_alarm" "running_tasks_less_than_desired" {
  count               = local.claimant_api_consumer_alert_on_running_tasks_less_than_desired[local.environment] ? 1 : 0
  alarm_name          = local.claimant_api_consumer_running_tasks_less_than_desired
  alarm_description   = "Managed by ${local.common_tags.Application} repository"
  alarm_actions       = [local.monitoring_topic_arn]
  treat_missing_data  = "breaching"
  evaluation_periods  = 5
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"

  metric_query {
    id          = "e1"
    expression  = "IF(m1 < m2, 1, 0)"
    label       = "DesiredCountNotMet"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "RunningTaskCount"
      namespace   = "ECS/ContainerInsights"
      period      = "60"
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        ServiceName = "claimant-api-kafka-consumer"
        ClusterName = "ingestion"
      }
    }
  }

  metric_query {
    id = "m2"

    metric {
      metric_name = "DesiredTaskCount"
      namespace   = "ECS/ContainerInsights"
      period      = "60"
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        ServiceName = "claimant-api-kafka-consumer"
        ClusterName = "ingestion"
      }
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name              = "claimant-api-kafka-consumer-failed-processing-batch",
      notification_type = "Warning",
      severity          = "High"
    },
  )
}
