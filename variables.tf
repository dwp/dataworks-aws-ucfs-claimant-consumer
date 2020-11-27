variable "costcode" {
  type    = string
  default = ""
}

variable "assume_role" {
  type        = string
  default     = "ci"
  description = "IAM role assumed by Concourse when running Terraform"
}

variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "friendly_name" {
  type        = string
  description = "Friendly name used in ECS service and task definition"
  default     = "claimant-api-kafka-consumer"
}

variable "task_config" {
  type = object({
    cpu    = string
    memory = string
  })
}

variable "ucfs_claimant_kafka_consumer" {
  type        = string
  description = "Name of container repository"
  default     = "ucfs-claimant-kafka-consumer"
}

variable "ucfs_claimant_kafka_consumer_version" {
  # To use digest, prepend with @sha256:, eg  development = "@sha256:fb42d3f6a865aad8e9c139bc25b493b418e9ba792134bb280e7633625361d1bc"
  # To use a tag prepend with colon, eg       development = ":latest"
  description = "Tag or SHA of container to be deployed"
  type        = string
  default     = ":latest"
}

variable "retriever_acm_cert_arn" {
  description = "Arn for retriever ACM cert"
  type        = string
  default     = "NOT_SET"
}

variable "claimant_api_kafka_consumer_container_version" {
  description = "Claimant API Kafka consumer container version SHA"
  type        = string
  default     = "NOT_SET"
}
