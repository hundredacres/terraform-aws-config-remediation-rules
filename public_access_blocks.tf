resource "aws_config_config_rule" "s3_public_access_block" {
  count = var.enable_s3_public_access_block ? 1 : 0

  name        = "ensure-s3-public-access-block"
  description = "Ensures S3 buckets have public access block enabled"

  tags = local.tags

  source {
    owner             = "AWS"
    source_identifier = "S3_ACCOUNT_LEVEL_PUBLIC_ACCESS_BLOCKS"
  }

  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
  }
}

resource "aws_ssm_document" "enable_s3_public_access_block" {
  count           = var.enable_s3_public_access_block ? 1 : 0
  name            = "Remediations-EnableS3PublicAccessBlock"
  document_type   = "Automation"
  document_format = "YAML"

  content = templatefile("${path.module}/ssm_documents/enable_s3_public_access_block.yaml", {
    SNSTopicArn = try(aws_sns_topic.admin_notifications[0].arn, "")
  })
}

resource "aws_config_remediation_configuration" "enable_s3_public_access_block" {
  count            = var.enable_s3_public_access_block ? 1 : 0
  config_rule_name = aws_config_config_rule.s3_public_access_block[0].name
  resource_type    = "AWS::S3::Bucket"
  target_type      = "SSM_DOCUMENT"
  target_id        = aws_ssm_document.enable_s3_public_access_block[0].name

  parameter {
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.enable_s3_public_access_block[0].arn
  }

  parameter {
    name           = "BucketName"
    resource_value = "RESOURCE_ID"
  }

  automatic                  = var.automatic_remediation
  maximum_automatic_attempts = 1
}


resource "aws_iam_role" "enable_s3_public_access_block" {
  count = var.enable_s3_public_access_block ? 1 : 0

  name               = "config-remediation-enable-s3-public-access-block"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "enable_s3_public_access_block_policy" {
  count = var.enable_s3_public_access_block ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "s3:PutBucketPublicAccessBlock",
      "s3:GetBucketPublicAccessBlock"
    ]
    # Wildcard used for simplicity - could be scoped to: arn:aws:s3:::*
    # Config remediation passes specific bucket name to limit scope
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "enable_s3_public_access_block" {
  count = var.enable_s3_public_access_block ? 1 : 0

  name_prefix = "config-remediation-enable-s3-public-access-block-policy"
  role        = aws_iam_role.enable_s3_public_access_block[0].id
  policy      = data.aws_iam_policy_document.enable_s3_public_access_block_policy[0].json
}

resource "aws_iam_role_policy" "enable_s3_public_access_block_publish_to_sns" {
  count = var.enable_s3_public_access_block && var.enable_sns_notifications ? 1 : 0
  name  = "config-remediation-enable-s3-public-access-block-publish-to-sns-policy"
  role  = aws_iam_role.enable_s3_public_access_block[0].id

  policy = data.aws_iam_policy_document.publish_to_sns.json
}
