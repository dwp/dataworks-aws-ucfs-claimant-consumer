# UCFS Claimant Consumer Infrastructure

## Description

The terraform infrastructure code present in this repo, raises an ECS service and task for [ucfs-claimant-kafka-consumer](https://github.com/dwp/ucfs-claimant-kafka-consumer)

## Local apply
After cloning this repo, please generate `terraform.tf` and `terraform.tfvars` files by running:
`make bootstrap`

These files are generated via their jinja2 counter parts to protect account information and other secrets.

## Cloudwatch logs

The ECS task claimant_api_kafka_consumer runs on the Ingestion ECS cluster. Container logs are therefore available here:
`/aws/ecs/ingestion/claimant-api-kafka-consumer`

## Concourse Pipelines

A Concourse pipeline exists for this repo. So that it is seperated from other infrastructure. It is called `ucfs-claimant-consumer`.
Is is in the main AWS Concourse `dataworks` team. The files for this pipeline are in the `/ci` folder.

The pipeline doesn't self update, so be sure to manually update from the repo, when making changes, the following commands can be executed:

```
make concourse-login
make update-pipeline
```
