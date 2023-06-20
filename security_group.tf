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

locals {
  security_group_rules = [
    {
      name : "RDS"
      port : 3306
      destination : sort(data.terraform_remote_state.ucfs_claimant.outputs.rds.vpc_security_group_ids)[0] # sort() used to convert set to indexed list
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

resource "aws_security_group_rule" "egress_only" {
  for_each          = { for security_group_rule in local.egress_only_security_group_rules : security_group_rule.name => security_group_rule }
  description       = "Allow outbound requests to ${each.value.name}"
  type              = "egress"
  from_port         = each.value.port
  to_port           = each.value.port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.destination
  security_group_id = aws_security_group.claimant_api_kafka_consumer.id
}

resource "aws_security_group_rule" "ingress" {
  for_each                 = { for security_group_rule in local.security_group_rules : security_group_rule.name => security_group_rule }
  description              = "Allow inbound requests from ${each.value.name}"
  type                     = "ingress"
  from_port                = each.value.port
  to_port                  = each.value.port
  protocol                 = "tcp"
  security_group_id        = each.value.destination
  source_security_group_id = aws_security_group.claimant_api_kafka_consumer.id
}

resource "aws_security_group_rule" "egress" {
  for_each                 = { for security_group_rule in local.security_group_rules : security_group_rule.port => security_group_rule }
  description              = "Allow outbound requests to ${each.value.name}"
  type                     = "egress"
  from_port                = each.value.port
  to_port                  = each.value.port
  protocol                 = "tcp"
  source_security_group_id = each.value.destination
  security_group_id        = aws_security_group.claimant_api_kafka_consumer.id
}

resource "aws_security_group_rule" "ucfs_claimant_consumer_to_stub_ucfs_kafka" {
  count                    = local.claimant_api_consumer_use_kafka_stub[local.environment] ? length(data.terraform_remote_state.ingestion.outputs.stub_ucfs.stub_ucfs_kafka_ports) : 0
  description              = "UCFS claimaint consumer to stub broker"
  type                     = "ingress"
  source_security_group_id = aws_security_group.claimant_api_kafka_consumer.id
  protocol                 = "tcp"
  from_port                = data.terraform_remote_state.ingestion.outputs.stub_ucfs.stub_ucfs_kafka_ports[count.index]
  to_port                  = data.terraform_remote_state.ingestion.outputs.stub_ucfs.stub_ucfs_kafka_ports[count.index]
  security_group_id        = data.terraform_remote_state.ingestion.outputs.stub_ucfs.sg_id
}

resource "aws_security_group_rule" "ucfs_claimant_consumer_to_dks" {
  provider          = aws.management-crypto
  description       = "UCFS claimant consumer to DKS"
  type              = "ingress"
  from_port         = 8443
  to_port           = 8443
  protocol          = "tcp"
  cidr_blocks       = data.terraform_remote_state.ingest.outputs.ingestion_subnets.cidr_block
  security_group_id = data.terraform_remote_state.crypto.outputs.dks_sg_id[local.environment]
}