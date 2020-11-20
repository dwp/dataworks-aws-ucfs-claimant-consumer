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

  //  TODO: Fill container env var values
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
        "value": "INFO"
      },
      {
        "name": "RETRIEVER_ACM_CERT_ARN",
        "value": "${aws_service_not_defined.needs_replacing}"
      },
      {
        "name": "KAFKA_BOOTSTRAP_SERVERS",
        "value": "${aws_service_not_defined.needs_replacing}"
      },
      {
        "name": "KAFKA_CONSUMER_GROUP",
        "value": "${aws_service_not_defined.needs_replacing}"
      },
      {
        "name": "KAFKA_FETCH_MAX_BYTES",
        "value": "${aws_service_not_defined.needs_replacing}"
      },
      {
        "name": "KAFKA_KEY_PASSWORD",
        "value": "${aws_service_not_defined.needs_replacing}"
      },
      {
        "name": "KAFKA_KEYSTORE",
        "value": "${aws_service_not_defined.needs_replacing}"
      },
      {
        "name": "KAFKA_KEYSTORE_PASSWORD",
        "value": "${aws_service_not_defined.needs_replacing}"
      },
      {
        "name": "KAFKA_MAX_PARTITION_FETCH_BYTES",
        "value": "${aws_service_not_defined.needs_replacing}"
      },
      {
        "name": "KAFKA_MAX_POLL_INTERVAL_MS",
        "value": "${aws_service_not_defined.needs_replacing}"
      },
      {
        "name": "KAFKA_MAX_POLL_RECORDS",
        "value": "${aws_service_not_defined.needs_replacing}"
      },
      {
        "name": "KAFKA_POLL_DURATION_SECONDS",
        "value": "${aws_service_not_defined.needs_replacing}"
      },
      {
        "name": "KAFKA_TOPIC_REGEX",
        "value": "${aws_service_not_defined.needs_replacing}"
      },
      {
        "name": "KAFKA_TRUSTSTORE",
        "value": "${aws_service_not_defined.needs_replacing}"
      },
      {
        "name": "KAFKA_TRUSTSTORE_PASSWORD",
        "value": "${aws_service_not_defined.needs_replacing}"
      },
      {
        "name": "KAFKA_USE_SSL",
        "value": "${aws_service_not_defined.needs_replacing}"
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
