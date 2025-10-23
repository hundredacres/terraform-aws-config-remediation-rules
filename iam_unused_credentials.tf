resource "aws_config_config_rule" "iam_unused_credentials" {
  count       = var.enable_iam_unused_credentials_check ? 1 : 0
  name        = "iam-user-unused-credentials-check"
  description = "Checks whether IAM users have passwords or active access keys that have not been used within the specified number of days"

  tags = local.tags

  source {
    owner             = "AWS"
    source_identifier = "IAM_USER_UNUSED_CREDENTIALS_CHECK"
  }

  input_parameters = jsonencode({
    maxCredentialUsageAge = tostring(var.iam_max_credential_usage_age)
  })
}

resource "aws_ssm_document" "deactivate_unused_credentials" {
  count           = var.enable_iam_unused_credentials_check ? 1 : 0
  name            = "DeactivateUnusedIAMCredentials"
  document_type   = "Automation"
  document_format = "YAML"

  content = templatefile("${path.module}/ssm_documents/deactivate_unused_credentials.yaml", {
    SNSTopicArn           = try(aws_sns_topic.admin_notifications[0].arn, "")
    MaxCredentialUsageAge = var.iam_max_credential_usage_age
  })

  tags = local.tags
}

resource "aws_config_remediation_configuration" "deactivate_unused_credentials" {
  count            = var.enable_iam_unused_credentials_check ? 1 : 0
  config_rule_name = aws_config_config_rule.iam_unused_credentials[0].name
  target_type      = "SSM_DOCUMENT"
  target_id        = aws_ssm_document.deactivate_unused_credentials[0].name
  resource_type    = "AWS::IAM::User"

  parameter {
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.deactivate_unused_credentials[0].arn
  }

  parameter {
    name           = "IAMUser"
    resource_value = "RESOURCE_ID"
  }

  automatic                  = var.automatic_remediation
  maximum_automatic_attempts = 1
  retry_attempt_seconds      = 60
}

resource "aws_iam_role" "deactivate_unused_credentials" {
  count = var.enable_iam_unused_credentials_check ? 1 : 0

  name               = "config-remediation-deactivate-unused-credentials"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "deactivate_unused_credentials_policy" {
  count = var.enable_iam_unused_credentials_check ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "iam:GetUser",
      "iam:ListAccessKeys",
      "iam:GetAccessKeyLastUsed",
      "iam:GetLoginProfile",
      "iam:UpdateAccessKey",
      "iam:DeleteLoginProfile"
    ]
    # Wildcard used for simplicity - could be scoped to: arn:aws:iam::${account_id}:user/*
    # Config remediation passes specific IAM username to limit scope
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "deactivate_unused_credentials" {
  count = var.enable_iam_unused_credentials_check ? 1 : 0
  name  = "config-remediation-deactivate-unused-credentials-policy"
  role  = aws_iam_role.deactivate_unused_credentials[0].id

  policy = data.aws_iam_policy_document.deactivate_unused_credentials_policy[0].json
}

resource "aws_iam_role_policy" "deactivate_unused_credentials_publish_to_sns" {
  count = var.enable_iam_unused_credentials_check && var.enable_sns_notifications ? 1 : 0
  name  = "config-remediation-deactivate-unused-credentials-publish-to-sns-policy"
  role  = aws_iam_role.deactivate_unused_credentials[0].id

  policy = data.aws_iam_policy_document.publish_to_sns.json
}
