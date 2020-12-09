resource "aws_cloudwatch_log_group" "claimant_api_kafka_consumer" {
  name              = "/aws/ecs/${data.terraform_remote_state.dataworks_aws_ingestion_ecs_cluster.outputs.ingestion_ecs_cluster.name}/${var.friendly_name}"
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
        "value": "${local.log_level[local.environment]}"
      },
      {
        "name": "RETRIEVER_ACM_CERT_ARN",
        "value": "${aws_acm_certificate.ucfs_claimant_kafka_consumer.arn}"
      },
      {
        "name": "RETRIEVER_PRIVATE_KEY_ALIAS",
        "value": "${var.friendly_name}"
      },
      {
        "name": "KAFKA_BOOTSTRAP_SERVERS",
        "value": "${local.kafka_bootstrap_servers}"
      },
      {
        "name": "KAFKA_CONSUMER_GROUP",
        "value": "${local.kafka_consumer_group}"
      },
      {
        "name": "KAFKA_DLQ_TOPIC",
        "value": "${local.dlq_kafka_consumer_topic}"
      },
      {
        "name": "KAFKA_FETCH_MAX_BYTES",
        "value": "${local.kafka_fetch_max_bytes[local.environment]}"
      },
      {
        "name": "KAFKA_MAX_PARTITION_FETCH_BYTES",
        "value": "${local.kafka_max_partition_fetch_bytes[local.environment]}"
      },
      {
        "name": "KAFKA_MAX_POLL_INTERVAL_MS",
        "value": "${local.kafka_max_poll_interval_ms[local.environment]}"
      },
      {
        "name": "KAFKA_MAX_POLL_RECORDS",
        "value": "${local.kafka_max_poll_records[local.environment]}"
      },
      {
        "name": "KAFKA_POLL_DURATION_SECONDS",
        "value": "${local.kafka_poll_duration_seconds[local.environment]}"
      },
      {
        "name": "KAFKA_TOPIC_REGEX",
        "value": "${local.kafka_topic_regex[local.environment]}"
      },
      {
        "name": "KAFKA_INSECURE",
        "value": "false"
      },
      {
        "name": "KAFKA_USE_SSL",
        "value": "false"
      },
      {
        "name": "KAFKA_CERT_MODE",
        "value": "RETRIEVE"
      },
      {
        "name": "KAFKA_CONSUMER_TRUSTSTORE_ALIASES",
        "value": "${local.kafka_consumer_truststore_aliases[local.environment]}"
      },
      {
        "name": "KAFKA_CONSUMER_TRUSTSTORE_CERTS",
        "value": "${local.kafka_consumer_truststore_certs[local.environment]}"
      },
      {
        "name": "DKS_URL",
        "value": "${local.dks_endpoint_url}"
      },
      {
        "name": "AWS_REGION",
        "value": "${var.region}"
      },
      {
        "name": "AWS_DEFAULT_REGION",
        "value": "${var.region}"
      },
      {
        "name": "INTERNET_PROXY",
        "value": "${local.internet_proxy}"
      },
      {
        "name": "NON_PROXIED_ENDPOINTS",
        "value": "${local.non_proxied_endpoints}"
      },
      {
        "name": "KAFKA_MAX_MEMORY_ALLOCATION",
        "value": "${var.kafka_max_memory_allocation}"
      }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_service" "claimant_api_kafka_consumer" {
  name            = var.friendly_name
  cluster         = data.terraform_remote_state.dataworks_aws_ingestion_ecs_cluster.outputs.ingestion_ecs_cluster.id
  task_definition = aws_ecs_task_definition.claimant_api_kafka_consumer.arn
  desired_count   = 0
  launch_type     = "EC2"

  network_configuration {
    security_groups = [data.terraform_remote_state.dataworks_aws_ingestion_ecs_cluster.outputs.ingestion_ecs_cluster_security_group.id, aws_security_group.claimant_api_kafka_consumer.id]
    subnets         = data.terraform_remote_state.ingestion.outputs.ingestion_subnets.id
  }
}
