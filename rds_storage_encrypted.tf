resource "aws_config_config_rule" "rds_storage_encrypted" {
  count       = var.enable_rds_storage_encrypted ? 1 : 0
  name        = "rds-storage-encrypted"
  description = "Checks whether storage encryption is enabled for RDS DB instances"

  tags = local.tags

  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }

  scope {
    compliance_resource_types = ["AWS::RDS::DBInstance"]
  }
}

resource "aws_ssm_document" "delete_unencrypted_rds" {
  count           = var.enable_rds_storage_encrypted ? 1 : 0
  name            = "DeleteUnencryptedRDSInstance"
  document_type   = "Automation"
  document_format = "YAML"

  content = templatefile("${path.module}/ssm_documents/delete_unencrypted_rds.yaml", {
    SNSTopicArn = try(aws_sns_topic.admin_notifications[0].arn, "")
  })

  tags = local.tags
}

resource "aws_config_remediation_configuration" "delete_unencrypted_rds" {
  count            = var.enable_rds_storage_encrypted ? 1 : 0
  config_rule_name = aws_config_config_rule.rds_storage_encrypted[0].name
  resource_type    = "AWS::RDS::DBInstance"
  target_type      = "SSM_DOCUMENT"
  target_id        = aws_ssm_document.delete_unencrypted_rds[0].name

  parameter {
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.delete_unencrypted_rds[0].arn
  }

  parameter {
    name           = "DBInstanceIdentifier"
    resource_value = "RESOURCE_ID"
  }

  automatic                  = var.automatic_remediation
  maximum_automatic_attempts = 1
}

resource "aws_iam_role" "delete_unencrypted_rds" {
  count = var.enable_rds_storage_encrypted ? 1 : 0

  name               = "config-remediation-delete-unencrypted-rds"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "delete_unencrypted_rds_policy" {
  count = var.enable_rds_storage_encrypted ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "rds:DescribeDBInstances",
      "rds:DeleteDBInstance",
      "rds:ModifyDBInstance"
    ]
    # Wildcard required: rds:Describe* actions don't support resource-level permissions
    # Config remediation passes specific DB instance identifier to limit scope
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "delete_unencrypted_rds" {
  count = var.enable_rds_storage_encrypted ? 1 : 0
  name  = "config-remediation-delete-unencrypted-rds-policy"
  role  = aws_iam_role.delete_unencrypted_rds[0].id

  policy = data.aws_iam_policy_document.delete_unencrypted_rds_policy[0].json
}

resource "aws_iam_role_policy" "delete_unencrypted_rds_publish_to_sns" {
  count = var.enable_rds_storage_encrypted && var.enable_sns_notifications ? 1 : 0
  name  = "config-remediation-delete-unencrypted-rds-publish-to-sns-policy"
  role  = aws_iam_role.delete_unencrypted_rds[0].id

  policy = data.aws_iam_policy_document.publish_to_sns.json
}
