locals {
  # Enabled rules summary for easy reference
  enabled_rules = {
    nat_gateway_deletion              = var.enable_nat_gateway_deletion
    public_subnet_resource_deletion   = var.enable_public_subnet_resource_deletion
    unencrypted_volume_shutdown       = var.enable_unencrypted_volume_shutdown
    non_vpc_lambda_deletion           = var.enable_non_vpc_lambda_deletion
    s3_public_access_block            = var.enable_s3_public_access_block
    sg_open_port_deletion             = var.enable_sg_open_port_deletion
    iam_password_policy               = var.enable_iam_password_policy
    iam_unused_credentials_check      = var.enable_iam_unused_credentials_check
    rds_storage_encrypted             = var.enable_rds_storage_encrypted
    root_account_mfa                  = var.enable_root_account_mfa
    s3_bucket_public_read_prohibited  = var.enable_s3_bucket_public_read_prohibited
    s3_bucket_public_write_prohibited = var.enable_s3_bucket_public_write_prohibited
    vpc_flow_logs                     = var.enable_vpc_flow_logs
  }

  # Common remediation configuration defaults
  remediation_defaults = {
    automatic                  = var.automatic_remediation
    maximum_automatic_attempts = 1
    retry_attempt_seconds      = 60
  }

  # Remediation defaults for notification-based rules (higher retry count)
  # Used for: IAM password policy (account-level) and root MFA (notification-only)
  # Rationale: Non-destructive actions that benefit from retry logic
  remediation_defaults_notifications = {
    automatic                  = var.automatic_remediation
    maximum_automatic_attempts = 5
    retry_attempt_seconds      = 60
  }

  # SNS topic ARN (used across multiple SSM documents)
  # Uses provided ARN if available, otherwise uses created topic, otherwise empty
  sns_topic_arn = local.sns_topic_arn_final

  # Common IAM assume role policy for SSM (already defined in main.tf but referenced here for clarity)
  ssm_assume_role_policy = data.aws_iam_policy_document.assume_role.json

  # Count of enabled rules (useful for monitoring)
  enabled_rules_count = length([for k, v in local.enabled_rules : k if v])
}
