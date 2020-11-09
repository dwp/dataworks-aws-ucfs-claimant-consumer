resource "aws_acm_certificate" "ucfs_claimant_kafka_consumer" {
  certificate_authority_arn = data.terraform_remote_state.certificate_authority.outputs.root_ca.arn
  domain_name               = "consumer.ucfs.${local.env_prefix[local.environment]}dataworks.dwp.gov.uk"

  options {
    certificate_transparency_logging_preference = "DISABLED"
  }
}
