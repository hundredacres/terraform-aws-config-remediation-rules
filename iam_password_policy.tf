resource "aws_config_config_rule" "iam_password_policy" {
  count       = var.enable_iam_password_policy ? 1 : 0
  name        = "iam-password-policy"
  description = "Checks whether the account password policy for IAM users meets the specified requirements"

  tags = local.tags

  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }

  input_parameters = jsonencode({
    RequireUppercaseCharacters = var.iam_password_require_uppercase
    RequireLowercaseCharacters = var.iam_password_require_lowercase
    RequireSymbols             = var.iam_password_require_symbols
    RequireNumbers             = var.iam_password_require_numbers
    MinimumPasswordLength      = var.iam_password_minimum_length
    PasswordReusePrevention    = var.iam_password_reuse_prevention
    MaxPasswordAge             = var.iam_password_max_age
  })
}

resource "aws_ssm_document" "update_iam_password_policy" {
  count           = var.enable_iam_password_policy ? 1 : 0
  name            = "UpdateIAMPasswordPolicy"
  document_type   = "Automation"
  document_format = "YAML"

  content = templatefile("${path.module}/ssm_documents/update_iam_password_policy.yaml", {
    SNSTopicArn                = try(aws_sns_topic.admin_notifications[0].arn, "")
    RequireUppercaseCharacters = var.iam_password_require_uppercase
    RequireLowercaseCharacters = var.iam_password_require_lowercase
    RequireSymbols             = var.iam_password_require_symbols
    RequireNumbers             = var.iam_password_require_numbers
    MinimumPasswordLength      = var.iam_password_minimum_length
    PasswordReusePrevention    = var.iam_password_reuse_prevention
    MaxPasswordAge             = var.iam_password_max_age
  })

  tags = local.tags
}

resource "aws_config_remediation_configuration" "update_iam_password_policy" {
  count            = var.enable_iam_password_policy ? 1 : 0
  config_rule_name = aws_config_config_rule.iam_password_policy[0].name
  target_type      = "SSM_DOCUMENT"
  target_id        = aws_ssm_document.update_iam_password_policy[0].name

  parameter {
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.update_iam_password_policy[0].arn
  }

  automatic = var.automatic_remediation
  # Higher retry count for non-destructive account-level policy updates
  # See local.remediation_defaults_notifications for rationale
  maximum_automatic_attempts = 5
  retry_attempt_seconds      = 60
}

resource "aws_iam_role" "update_iam_password_policy" {
  count = var.enable_iam_password_policy ? 1 : 0

  name               = "config-remediation-update-iam-password-policy"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "update_iam_password_policy_policy" {
  count = var.enable_iam_password_policy ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "iam:GetAccountPasswordPolicy",
      "iam:UpdateAccountPasswordPolicy"
    ]
    # Wildcard required: Account password policy is an account-level resource, not user-specific
    # These actions inherently apply only to the AWS account where executed
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "update_iam_password_policy" {
  count = var.enable_iam_password_policy ? 1 : 0
  name  = "config-remediation-update-iam-password-policy-policy"
  role  = aws_iam_role.update_iam_password_policy[0].id

  policy = data.aws_iam_policy_document.update_iam_password_policy_policy[0].json
}

resource "aws_iam_role_policy" "update_iam_password_policy_publish_to_sns" {
  count = var.enable_iam_password_policy && var.enable_sns_notifications ? 1 : 0
  name  = "config-remediation-update-iam-password-policy-publish-to-sns-policy"
  role  = aws_iam_role.update_iam_password_policy[0].id

  policy = data.aws_iam_policy_document.publish_to_sns.json
}
