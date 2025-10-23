# Local configuration for S3 public access rules
locals {
  s3_public_access_rules = {
    read = {
      enabled             = var.enable_s3_bucket_public_read_prohibited
      name                = "s3-bucket-public-read-prohibited"
      description         = "Checks that your Amazon S3 buckets do not allow public read access"
      source_identifier   = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
    }
    write = {
      enabled             = var.enable_s3_bucket_public_write_prohibited
      name                = "s3-bucket-public-write-prohibited"
      description         = "Checks that your Amazon S3 buckets do not allow public write access"
      source_identifier   = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
    }
  }

  # Filter to only enabled rules
  enabled_s3_rules = {
    for key, rule in local.s3_public_access_rules : key => rule if rule.enabled
  }

  # Check if any S3 rule is enabled
  any_s3_rule_enabled = length(local.enabled_s3_rules) > 0
}

# Config rules for S3 public access (read and write)
resource "aws_config_config_rule" "s3_bucket_public_access" {
  for_each = local.enabled_s3_rules

  name        = each.value.name
  description = each.value.description
  tags        = local.tags

  source {
    owner             = "AWS"
    source_identifier = each.value.source_identifier
  }

  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
  }
}

# Single SSM document used by both rules
resource "aws_ssm_document" "remediate_s3_public_access" {
  count = local.any_s3_rule_enabled ? 1 : 0

  name            = "RemediateS3PublicAccess"
  document_type   = "Automation"
  document_format = "YAML"

  content = templatefile("${path.module}/ssm_documents/remediate_s3_public_access.yaml", {
    SNSTopicArn = try(aws_sns_topic.admin_notifications[0].arn, "")
  })

  tags = local.tags
}

# Remediation configurations for each enabled rule
resource "aws_config_remediation_configuration" "remediate_s3_public_access" {
  for_each = local.enabled_s3_rules

  config_rule_name = aws_config_config_rule.s3_bucket_public_access[each.key].name
  resource_type    = "AWS::S3::Bucket"
  target_type      = "SSM_DOCUMENT"
  target_id        = aws_ssm_document.remediate_s3_public_access[0].name

  parameter {
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.remediate_s3_public_access[0].arn
  }

  parameter {
    name           = "BucketName"
    resource_value = "RESOURCE_ID"
  }

  automatic                  = var.automatic_remediation
  maximum_automatic_attempts = 1
}

# Single IAM role for S3 public access remediation
resource "aws_iam_role" "remediate_s3_public_access" {
  count = local.any_s3_rule_enabled ? 1 : 0

  name               = "config-remediation-s3-public-access"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.tags
}

# IAM policy document with S3 permissions
data "aws_iam_policy_document" "remediate_s3_public_access_policy" {
  count = local.any_s3_rule_enabled ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketPolicy",
      "s3:GetBucketPolicyStatus",
      "s3:GetBucketAcl",
      "s3:PutBucketPolicy",
      "s3:DeleteBucketPolicy",
      "s3:PutBucketAcl",
      "s3:GetBucketPublicAccessBlock",
      "s3:PutBucketPublicAccessBlock"
    ]
    # Wildcard used for simplicity - could be scoped to: arn:aws:s3:::*
    # Config remediation passes specific bucket name to limit scope
    resources = ["*"]
  }
}

# Attach policy to IAM role
resource "aws_iam_role_policy" "remediate_s3_public_access" {
  count = local.any_s3_rule_enabled ? 1 : 0

  name   = "config-remediation-s3-public-access-policy"
  role   = aws_iam_role.remediate_s3_public_access[0].id
  policy = data.aws_iam_policy_document.remediate_s3_public_access_policy[0].json
}

# Attach SNS publishing policy if notifications are enabled
resource "aws_iam_role_policy" "remediate_s3_public_access_publish_to_sns" {
  count = local.any_s3_rule_enabled && var.enable_sns_notifications ? 1 : 0

  name   = "config-remediation-s3-public-access-publish-to-sns-policy"
  role   = aws_iam_role.remediate_s3_public_access[0].id
  policy = data.aws_iam_policy_document.publish_to_sns.json
}
