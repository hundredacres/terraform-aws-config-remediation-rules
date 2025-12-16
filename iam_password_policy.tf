# Account-level Config rule (when create_organization_rules = false)
resource "aws_config_config_rule" "iam_password_policy" {
  count       = var.enable_iam_password_policy && !var.create_organization_rules ? 1 : 0
  name        = "iam-password-policy"
  description = "Checks whether the account password policy for IAM users meets the specified requirements"

  tags = local.tags

  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }

  input_parameters = jsonencode({
    RequireUppercaseCharacters = tostring(var.iam_password_require_uppercase)
    RequireLowercaseCharacters = tostring(var.iam_password_require_lowercase)
    RequireSymbols             = tostring(var.iam_password_require_symbols)
    RequireNumbers             = tostring(var.iam_password_require_numbers)
    MinimumPasswordLength      = tostring(var.iam_password_minimum_length)
    PasswordReusePrevention    = tostring(var.iam_password_reuse_prevention)
    MaxPasswordAge             = tostring(var.iam_password_max_age)
  })
}

# Organization-level Config rule (when create_organization_rules = true)
resource "aws_config_organization_managed_rule" "iam_password_policy" {
  count             = var.enable_iam_password_policy && var.create_organization_rules ? 1 : 0
  name              = "iam-password-policy"
  description       = "Checks whether the account password policy for IAM users meets the specified requirements"
  rule_identifier   = "IAM_PASSWORD_POLICY"
  excluded_accounts = var.excluded_accounts

  input_parameters = jsonencode({
    RequireUppercaseCharacters = tostring(var.iam_password_require_uppercase)
    RequireLowercaseCharacters = tostring(var.iam_password_require_lowercase)
    RequireSymbols             = tostring(var.iam_password_require_symbols)
    RequireNumbers             = tostring(var.iam_password_require_numbers)
    MinimumPasswordLength      = tostring(var.iam_password_minimum_length)
    PasswordReusePrevention    = tostring(var.iam_password_reuse_prevention)
    MaxPasswordAge             = tostring(var.iam_password_max_age)
  })
}

# Local to get the rule name regardless of which type was created
locals {
  iam_password_policy_rule_name = var.create_organization_rules ? (
    length(aws_config_organization_managed_rule.iam_password_policy) > 0 ? aws_config_organization_managed_rule.iam_password_policy[0].name : ""
    ) : (
    length(aws_config_config_rule.iam_password_policy) > 0 ? aws_config_config_rule.iam_password_policy[0].name : ""
  )
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

# Remediation configuration (only works with account-level rules)
# Note: For organization rules, remediation must be configured separately in each member account
# via the config-recorder module
resource "aws_config_remediation_configuration" "update_iam_password_policy" {
  count            = var.enable_iam_password_policy && !var.create_organization_rules ? 1 : 0
  config_rule_name = aws_config_config_rule.iam_password_policy[0].name
  target_type      = "SSM_DOCUMENT"
  target_id        = aws_ssm_document.update_iam_password_policy[0].name

  parameter {
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.update_iam_password_policy[0].arn
  }

  automatic = var.automatic_remediation
  # Higher retry count for non-destructive account-level policy updates
  maximum_automatic_attempts = 5
  retry_attempt_seconds      = 60

  # Required for account-level rules without specific resource types
  execution_controls {
    ssm_controls {
      concurrent_execution_rate_percentage = 25
      error_percentage                     = 25
    }
  }
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
