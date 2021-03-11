locals {
  crypto_workspace = {
    management-dev = "management-dev"
    management     = "management"
  }

  management_account = {
    development = "management-dev"
    qa          = "management-dev"
    integration = "management-dev"
    preprod     = "management"
    production  = "management"
  }

  task_count = {
    development = 3
    qa          = 3
    integration = 3
    preprod     = 3
    production  = 6
  }

  certificate_auth_public_cert_bucket      = data.terraform_remote_state.certificate_authority.outputs.public_cert_bucket
  certificate_auth_mgmt_public_cert_bucket = data.terraform_remote_state.mgmt_certificate_authority.outputs.public_cert_bucket
  k2hb_data_source_is_ucfs                 = data.terraform_remote_state.ingestion.outputs.locals.k2hb_data_source_is_ucfs

  dks_subnet_cidr          = data.terraform_remote_state.crypto.outputs.dks_subnet.cidr_blocks
  dks_endpoint_url         = data.terraform_remote_state.crypto.outputs.dks_endpoint[local.environment]
  dlq_kafka_consumer_topic = data.terraform_remote_state.ingestion.outputs.locals.dlq_kafka_consumer_topic // must match what k2s3 uses

  stub_bootstrap_servers       = data.terraform_remote_state.ingestion.outputs.locals.stub_bootstrap_servers
  stub_ucfs_subnets            = data.terraform_remote_state.ingestion.outputs.stub_ucfs_subnets
  stub_kafka_broker_port_https = data.terraform_remote_state.ingestion.outputs.locals.stub_kafka_broker_port_https

  kafka_data_source_is_ucfs = data.terraform_remote_state.ingestion.outputs.locals.k2hb_data_source_is_ucfs

  ucfs_ha_broker_prefix               = data.terraform_remote_state.ingestion.outputs.locals.ucfs_ha_broker_prefix
  ucfs_london_domains                 = data.terraform_remote_state.ingestion.outputs.locals.ucfs_london_domains
  ucfs_london_current_domain          = local.ucfs_london_domains[local.environment]
  uc_kafka_broker_port_https          = data.terraform_remote_state.ingestion.outputs.locals.uc_kafka_broker_port_https
  ucfs_broker_cidr_blocks             = data.terraform_remote_state.ingestion.outputs.locals.ucfs_broker_cidr_blocks
  ucfs_london_broker_cidr_blocks      = data.terraform_remote_state.ingestion.outputs.locals.ucfs_london_broker_cidr_blocks
  ucfs_nameservers_cidr_blocks        = data.terraform_remote_state.ingestion.outputs.locals.ucfs_nameservers_cidr_blocks
  ucfs_london_nameservers_cidr_blocks = data.terraform_remote_state.ingestion.outputs.locals.ucfs_london_nameservers_cidr_blocks

  ingest_internet_proxy = data.terraform_remote_state.ingestion.outputs.internet_proxy
  ingest_no_proxy_list  = data.terraform_remote_state.ingestion.outputs.vpc.vpc.no_proxy_list
  internet_proxy        = local.ingest_internet_proxy.host
  non_proxied_endpoints = join(",", local.ingest_no_proxy_list)


  ucfs_london_ha_broker_list = [
    "${local.ucfs_ha_broker_prefix}00.${local.ucfs_london_current_domain}",
    "${local.ucfs_ha_broker_prefix}01.${local.ucfs_london_current_domain}",
    "${local.ucfs_ha_broker_prefix}02.${local.ucfs_london_current_domain}"
  ]

  ucfs_london_bootstrap_servers = {
    development = ["n/a"]                          // stubbed only
    qa          = ["n/a"]                          // stubbed only
    integration = local.ucfs_london_ha_broker_list //this exists on UC's end, but we do not use it as the env is stubbed as at Oct 2020
    preprod     = local.ucfs_london_ha_broker_list
    production  = local.ucfs_london_ha_broker_list
  }

  kafka_london_bootstrap_servers = {
    development = local.stub_bootstrap_servers[local.environment] // stubbed
    qa          = local.stub_bootstrap_servers[local.environment] // stubbed
    integration = local.k2hb_data_source_is_ucfs[local.environment] ? local.ucfs_london_bootstrap_servers[local.environment] : local.stub_bootstrap_servers[local.environment]
    preprod     = local.ucfs_london_bootstrap_servers[local.environment] // now on UCFS Staging HA
    production  = local.ucfs_london_bootstrap_servers[local.environment] // now on UCFS Production HA
  }

  kafka_broker_port = {
    development = local.stub_kafka_broker_port_https
    qa          = local.stub_kafka_broker_port_https
    integration = local.k2hb_data_source_is_ucfs[local.environment] ? local.uc_kafka_broker_port_https : local.stub_kafka_broker_port_https
    preprod     = local.uc_kafka_broker_port_https
    production  = local.uc_kafka_broker_port_https
  }

  kafka_consumer_truststore_aliases = "ucfs_ca,dataworks_mgt_root_ca"

  kafka_consumer_truststore_certs = "s3://${local.certificate_auth_public_cert_bucket.id}/ca_certificates/ucfs/root_ca.pem,s3://${local.certificate_auth_mgmt_public_cert_bucket.id}/ca_certificates/dataworks/dataworks_root_ca.pem"

  log_level = {
    development = "INFO"
    qa          = "INFO"
    integration = "INFO"
    preprod     = "INFO"
    production  = "INFO"
  }

  kafka_bootstrap_servers = join(
    ",",
    formatlist(
      "%s:%s",
      local.kafka_london_bootstrap_servers[local.environment],
      local.kafka_broker_port[local.environment],
    ),
  )

  kafka_consumer_group = "dataworks-ucfs-claimant-ingest-${local.environment}"

  kafka_fetch_max_bytes = {
    development = 20000000
    qa          = 20000000
    integration = 20000000
    preprod     = 20000000
    production  = 20000000
  }

  kafka_max_partition_fetch_bytes = {
    development = 20000000
    qa          = 20000000
    integration = 20000000
    preprod     = 20000000
    production  = 20000000
  }

  kafka_max_poll_interval_ms = {
    development = 600000
    qa          = 600000
    integration = 600000
    preprod     = 600000
    production  = 1800000
  }

  kafka_max_poll_records = {
    development = 25
    qa          = 50
    integration = 50
    preprod     = 25
    production  = 5000
  }

  kafka_poll_duration_seconds = {
    development = 10
    qa          = 10
    integration = 60
    preprod     = 60
    production  = 120
  }

  kafka_topic_regex = {
    development = "^(db[.])core[.](claimant|contract|statement)$"
    qa          = "^(db[.])core[.](claimant|contract|statement)$"
    integration = "^(db[.])core[.](claimant|contract|statement)$"
    preprod     = "^(db[.])core[.](claimant|contract|statement)$"
    production  = "^(db[.])core[.](claimant|contract|statement)$"
  }

  monitoring_topic_arn = data.terraform_remote_state.security-tools.outputs.sns_topic_london_monitoring.arn

  claimant_api_consumer_metrics_namespace             = "/app/claimant-api-kafka-consumer"

  claimant_api_consumer_processed_batch = "The number of batches successfully processed into the Claimant RDS"
  claimant_api_consumer_failed_batches  = "The number of batches which have failed to be processed into the Claimant RDS"
  claimant_api_consumer_running_tasks_less_than_desired = "Claimant API Kafka Consumer - Running tasks less than desired for more than 5 minutes"

  claimant_api_consumer_alert_on_lack_of_processed_batches = {
    development   = false
    qa            = false
    integraton    = false
    preproduction = false
    production    = true
  }

  claimant_api_consumer_alert_on_failed_batches = {
    development   = false
    qa            = false
    integraton    = false
    preproduction = false
    production    = true
  }

  claimant_api_consumer_running_tasks_less_than_desired = {
    development   = true
    qa            = true
    integraton    = true
    preproduction = true
    production    = true
  }
}
