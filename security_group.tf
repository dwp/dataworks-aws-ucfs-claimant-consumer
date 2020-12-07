locals {
  security_group_rules = [
    {
      name : "STUB Kafka brokers"
      port : local.kafka_broker_port[local.environment]
      protocol : "tcp"
      destination : local.stub_ucfs_subnets.cidr_block
    },
    {
      name : "UCFS Kafka brokers"
      port : local.kafka_broker_port[local.environment]
      protocol : "tcp"
      destination : local.ucfs_broker_cidr_blocks[local.environment]
    },
    {
      name : "London UCFS Kafka brokers"
      port : local.kafka_broker_port[local.environment]
      protocol : "tcp"
      destination : local.ucfs_london_broker_cidr_blocks[local.environment]
    },
    {
      name : "UCFS DNS Name servers in Ireland"
      port : 53
      protocol : "all"
      destination : local.ucfs_nameservers_cidr_blocks[local.environment]
    },
    {
      name : "UCFS DNS Name servers in London"
      port : 53
      protocol : "all"
      destination : local.ucfs_london_nameservers_cidr_blocks[local.environment]
    },
  ]
}

resource "aws_security_group" "claimant_api_kafka_consumer" {
  name                   = var.friendly_name
  description            = "Claimant API Kafka Consumer"
  revoke_rules_on_delete = true
  vpc_id                 = data.terraform_remote_state.ingestion.outputs.vpc.vpc.vpc.id

  tags = merge(
    local.common_tags,
    {
      Name = var.friendly_name
    }
  )
}

resource "aws_security_group_rule" "ingress" {
  for_each                 = { for security_group_rule in local.security_group_rules : security_group_rule.port => security_group_rule }
  description              = "Allow inbound requests from ${each.value.name}"
  type                     = "ingress"
  from_port                = each.value.port
  to_port                  = each.value.port
  protocol                 = each.value.protocol
  security_group_id        = each.value.destination
  source_security_group_id = aws_security_group.claimant_api_kafka_consumer.id
}

resource "aws_security_group_rule" "egress" {
  for_each                 = { for security_group_rule in local.security_group_rules : security_group_rule.port => security_group_rule }
  description              = "Allow outbound requests to ${each.value.name}"
  type                     = "egress"
  from_port                = each.value.port
  to_port                  = each.value.port
  protocol                 = each.value.protocol
  source_security_group_id = each.value.destination
  security_group_id        = aws_security_group.claimant_api_kafka_consumer.id
}
