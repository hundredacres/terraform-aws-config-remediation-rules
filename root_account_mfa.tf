resource "aws_config_config_rule" "root_account_mfa" {
  count       = var.enable_root_account_mfa ? 1 : 0
  name        = "root-account-mfa-enabled"
  description = "Checks whether users of your AWS account require a multi-factor authentication device to sign in with root credentials"

  tags = local.tags

  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }

  maximum_execution_frequency = "TwentyFour_Hours"
}

resource "aws_ssm_document" "notify_root_mfa_disabled" {
  count           = var.enable_root_account_mfa ? 1 : 0
  name            = "NotifyRootMFADisabled"
  document_type   = "Automation"
  document_format = "YAML"

  content = templatefile("${path.module}/ssm_documents/notify_root_mfa_disabled.yaml", {
    SNSTopicArn = try(aws_sns_topic.admin_notifications[0].arn, "")
  })

  tags = local.tags
}

resource "aws_config_remediation_configuration" "notify_root_mfa_disabled" {
  count            = var.enable_root_account_mfa ? 1 : 0
  config_rule_name = aws_config_config_rule.root_account_mfa[0].name
  target_type      = "SSM_DOCUMENT"
  target_id        = aws_ssm_document.notify_root_mfa_disabled[0].name

  parameter {
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.notify_root_mfa_disabled[0].arn
  }

  automatic = var.automatic_remediation
  # Higher retry count for notification-only (non-destructive) actions
  # See local.remediation_defaults_notifications for rationale
  maximum_automatic_attempts = 5
  retry_attempt_seconds      = 60
}

resource "aws_iam_role" "notify_root_mfa_disabled" {
  count = var.enable_root_account_mfa ? 1 : 0

  name               = "config-remediation-notify-root-mfa-disabled"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "notify_root_mfa_disabled_publish_to_sns" {
  count = var.enable_root_account_mfa && var.enable_sns_notifications ? 1 : 0
  name  = "config-remediation-notify-root-mfa-disabled-publish-to-sns-policy"
  role  = aws_iam_role.notify_root_mfa_disabled[0].id

  policy = data.aws_iam_policy_document.publish_to_sns.json
}
