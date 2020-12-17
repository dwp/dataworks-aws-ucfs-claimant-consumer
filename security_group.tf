locals {
  egress_only_security_group_rules = [
    {
      name : "UCFS Kafka brokers"
      port : local.kafka_broker_port[local.environment]
      protocol : "tcp"
      destination : concat(local.ucfs_london_broker_cidr_blocks[local.environment], local.stub_ucfs_subnets.cidr_block)
    },
    {
      name : "UCFS DNS Name servers"
      port : 53
      protocol : "all"
      destination : distinct(local.ucfs_london_nameservers_cidr_blocks[local.environment]) # Using distinct as dev & QA have duplicate values
    },
    {
      name : "DKS"
      port : 8443
      protocol : "tcp"
      destination : local.dks_subnet_cidr
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

resource "aws_security_group_rule" "egress" {
  for_each          = { for security_group_rule in local.egress_only_security_group_rules : security_group_rule.name => security_group_rule }
  description       = "Allow outbound requests to ${each.value.name}"
  type              = "egress"
  from_port         = each.value.port
  to_port           = each.value.port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.destination
  security_group_id = aws_security_group.claimant_api_kafka_consumer.id
}

resource "aws_security_group_rule" "egress_rds" {
  description              = "Requests to RDS"
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = data.terraform_remote_state.ucfs_claimant.outputs.rds.sg_id
  security_group_id        = aws_security_group.claimant_api_kafka_consumer.id
}

resource "aws_security_group_rule" "remote_ingress_rds" {
  description              = "Requests from Claimant Kafka Consumer"
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.claimant_api_kafka_consumer.id
  security_group_id        = data.terraform_remote_state.ucfs_claimant.outputs.rds.sg_id
}
