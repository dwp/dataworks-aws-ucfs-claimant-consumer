locals {
  iam_name = replace(title(var.friendly_name), "-", "")
}

resource "aws_iam_role" "claimant_api_kafka_consumer" {
  name               = local.iam_name
  assume_role_policy = data.terraform_remote_state.common.outputs.ecs_assume_role_policy_json

  tags = merge(
    local.common_tags,
    {
      Name = local.iam_name
    }
  )
}

resource "aws_iam_role_policy" "claimant_api_kafka_consumer" {
  policy = data.aws_iam_policy_document.claimant_api_kafka_consumer.json
  role   = aws_iam_role.claimant_api_kafka_consumer.id
}

data "aws_iam_policy_document" "claimant_api_kafka_consumer" {

  statement {
    sid       = "${local.iam_name}ExportCertACM"
    effect    = "Allow"
    actions   = ["acm:ExportCertificate"]
    resources = [aws_acm_certificate.ucfs_claimant_kafka_consumer.arn]
  }

  statement {
    sid       = "${local.iam_name}GetCACertS3"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${data.terraform_remote_state.certificate_authority.outputs.public_cert_bucket.arn}/*"]
  }

  statement {
    sid    = "${local.iam_name}WriteLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = [aws_cloudwatch_log_group.claimant_api_kafka_consumer.arn]
  }
}
