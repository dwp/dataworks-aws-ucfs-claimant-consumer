resource "aws_cloudwatch_log_group" "claimant_api_kafka_consumer" {
  name              = "/aws/ecs/${data.terraform_remote_state.ingestion.outputs.ingestion_ecs_cluster.name}/${var.friendly_name}" //TODO: get cluster name from remote state and rename it to `ingest`
  retention_in_days = "180"
  tags = merge(
    local.common_tags,
    {
      Name = var.friendly_name
    }
  )
}

resource "aws_ecs_task_definition" "claimant_api_kafka_consumer" {
  family                   = var.friendly_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = var.task_config.cpu
  memory                   = var.task_config.memory
  task_role_arn            = aws_iam_role.claimant_api_kafka_consumer.arn
  execution_role_arn       = data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn

  tags = merge(
    local.common_tags,
    {
      Name         = var.friendly_name
      Family       = var.friendly_name
      image_digest = var.ucfs_claimant_kafka_consumer_version
    }
  )

  container_definitions = <<DEFINITION
[
  {
    "image": "${local.account.management}.${data.terraform_remote_state.ingestion.outputs.vpc.vpc.ecr_dkr_domain_name}/${var.ucfs_claimant_kafka_consumer}${var.ucfs_claimant_kafka_consumer_version}",
    "name": "${var.friendly_name}",
    "networkMode": "awsvpc",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.claimant_api_kafka_consumer.name}",
        "awslogs-region": "${var.region}"
      }
    },
    "placementStrategy": [
      {
        "field": "attribute:ecs.availability-zone",
        "type": "spread"
      }
    ],
    "environment": [
      {
        "name": "CONTAINER_VERSION",
        "value": "${var.ucfs_claimant_kafka_consumer_version}"
      },
      {
        "name": "LOG_LEVEL",
        "value": "${local.claimant_api_kafka_consumer_task_configs.log_level[local.environment]}"
      },
      {
        "name": "RETRIEVER_ACM_CERT_ARN",
        "value": "${var.retriever_acm_cert_arn}"
      },
      {
        "name": "KAFKA_BOOTSTRAP_SERVERS",
        "value": "${local.claimant_api_kafka_consumer_task_configs.kafka_bootstrap_servers}"
      },
      {
        "name": "KAFKA_CONSUMER_GROUP",
        "value": "${local.claimant_api_kafka_consumer_task_configs.kafka_consumer_group}"
      },
      {
        "name": "KAFKA_FETCH_MAX_BYTES",
        "value": "${local.claimant_api_kafka_consumer_task_configs.kafka_fetch_max_bytes[local.environment]}"
      },
      {
        "name": "KAFKA_KEY_PASSWORD",
        "value": "${local.claimant_api_kafka_consumer_task_configs.kafka_key_password[local.environment]}"
      },
      {
        "name": "KAFKA_KEYSTORE",
        "value": "${local.claimant_api_kafka_consumer_task_configs.kafka_keystore[local.environment]}"
      },
      {
        "name": "KAFKA_KEYSTORE_PASSWORD",
        "value": "${local.claimant_api_kafka_consumer_task_configs.kafka_keystore_password[local.environment]}"
      },
      {
        "name": "KAFKA_MAX_PARTITION_FETCH_BYTES",
        "value": "${local.claimant_api_kafka_consumer_task_configs.kafka_max_partition_fetch_bytes[local.environment]}"
      },
      {
        "name": "KAFKA_MAX_POLL_INTERVAL_MS",
        "value": "${local.claimant_api_kafka_consumer_task_configs.kafka_max_poll_interval_ms[local.environment]}"
      },
      {
        "name": "KAFKA_MAX_POLL_RECORDS",
        "value": "${local.claimant_api_kafka_consumer_task_configs.kafka_max_poll_records[local.environment]}"
      },
      {
        "name": "KAFKA_POLL_DURATION_SECONDS",
        "value": "${local.claimant_api_kafka_consumer_task_configs.kafka_poll_duration_seconds[local.environment]}"
      },
      {
        "name": "KAFKA_TOPIC_REGEX",
        "value": "${local.claimant_api_kafka_consumer_task_configs.kafka_topic_regex[local.environment]}"
      },
      {
        "name": "KAFKA_TRUSTSTORE",
        "value": "${local.claimant_api_kafka_consumer_task_configs.kafka_truststore[local.environment]}"
      },
      {
        "name": "KAFKA_TRUSTSTORE_PASSWORD",
        "value": "${local.claimant_api_kafka_consumer_task_configs.kafka_truststore_password[local.environment]}"
      },
      {
        "name": "KAFKA_USE_SSL",
        "value": "${local.claimant_api_kafka_consumer_task_configs.kafka_use_ssl[local.environment]}"
      }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_service" "claimant_api_kafka_consumer" {
  name            = "claimant-api-kafka-consumer"
  cluster         = data.terraform_remote_state.ingestion.outputs.ingestion_ecs_cluster.id
  task_definition = aws_ecs_task_definition.claimant_api_kafka_consumer.arn
  desired_count   = 3
  launch_type     = "EC2"

  network_configuration {
    security_groups = [data.terraform_remote_state.ingestion.outputs.ingestion_ecs_cluster_security_group.id]
    subnets         = data.terraform_remote_state.ingestion.outputs.ingestion_subnets.id
  }
}
