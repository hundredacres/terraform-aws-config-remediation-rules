variable "name" {
  description = "Moniker to apply to all resources in the module"
  type        = string
}

variable "tags" {
  default     = {}
  description = "User-Defined tags"
  type        = map(string)
}

variable "enable_sns_notifications" {
  description = "Enable SNS notifications for remediation actions"
  type        = bool
  default     = false
}

variable "sns_topic_arn" {
  description = "ARN of an existing SNS topic to use for notifications. If not provided and enable_sns_notifications is true, a new topic will be created."
  type        = string
  default     = ""
}

variable "automatic_remediation" {
  description = "Enable automatic remediation (true) or manual approval (false). IMPORTANT: When false, Config will detect issues but require manual approval before remediation."
  type        = bool
  default     = false
}

variable "enable_nat_gateway_deletion" {
  description = "Enable the rule to automatically delete NAT Gateways when created"
  type        = bool
  default     = false
}

variable "enable_public_subnet_resource_deletion" {
  description = "Enable the rule to automatically delete resources (except load balancers) created in public subnets"
  type        = bool
  default     = false
}

variable "enable_unencrypted_volume_shutdown" {
  description = "Enable the rule to automatically shut down EC2 instances created with unencrypted root volumes"
  type        = bool
  default     = false
}

variable "enable_non_vpc_lambda_deletion" {
  description = "Enable the rule to automatically delete Lambda functions not associated with a VPC"
  type        = bool
  default     = false
}

variable "enable_s3_public_access_block" {
  description = "Enable the rule to automatically enable public access block for S3 buckets created without it"
  type        = bool
  default     = false
}

variable "enable_sg_open_port_deletion" {
  description = "Enable the rule to automatically delete security group rules allowing 0.0.0.0/0 access to admin or database ports"
  type        = bool
  default     = false
}

# IAM Password Policy Variables
variable "enable_iam_password_policy" {
  description = "Enable the rule to automatically update IAM password policy to meet compliance requirements"
  type        = bool
  default     = false
}

variable "iam_password_require_uppercase" {
  description = "Require at least one uppercase character in password"
  type        = bool
  default     = true
}

variable "iam_password_require_lowercase" {
  description = "Require at least one lowercase character in password"
  type        = bool
  default     = true
}

variable "iam_password_require_symbols" {
  description = "Require at least one symbol in password"
  type        = bool
  default     = true
}

variable "iam_password_require_numbers" {
  description = "Require at least one number in password"
  type        = bool
  default     = true
}

variable "iam_password_minimum_length" {
  description = "Minimum length to require for IAM user passwords"
  type        = number
  default     = 16

  validation {
    condition     = var.iam_password_minimum_length >= 6 && var.iam_password_minimum_length <= 128
    error_message = "IAM password minimum length must be between 6 and 128 characters (AWS IAM limits)."
  }
}

variable "iam_password_reuse_prevention" {
  description = "Number of previous passwords to prevent reuse"
  type        = number
  default     = 24

  validation {
    condition     = var.iam_password_reuse_prevention >= 1 && var.iam_password_reuse_prevention <= 24
    error_message = "IAM password reuse prevention must be between 1 and 24 (AWS IAM limits)."
  }
}

variable "iam_password_max_age" {
  description = "Number of days before password expiration"
  type        = number
  default     = 90

  validation {
    condition     = var.iam_password_max_age >= 1 && var.iam_password_max_age <= 1095
    error_message = "IAM password max age must be between 1 and 1095 days (AWS IAM limits)."
  }
}

# IAM Unused Credentials Variables
variable "enable_iam_unused_credentials_check" {
  description = "Enable the rule to automatically deactivate unused IAM credentials"
  type        = bool
  default     = false
}

variable "iam_max_credential_usage_age" {
  description = "Maximum number of days credentials can remain unused before deactivation"
  type        = number
  default     = 90

  validation {
    condition     = var.iam_max_credential_usage_age >= 1 && var.iam_max_credential_usage_age <= 365
    error_message = "IAM max credential usage age must be between 1 and 365 days (recommended security practice)."
  }
}

# RDS Storage Encryption Variables
variable "enable_rds_storage_encrypted" {
  description = "Enable the rule to automatically delete RDS instances without storage encryption"
  type        = bool
  default     = false
}

# Root Account MFA Variables
variable "enable_root_account_mfa" {
  description = "Enable the rule to send notifications when root account MFA is not enabled"
  type        = bool
  default     = false
}

# S3 Bucket Public Access Variables
variable "enable_s3_bucket_public_read_prohibited" {
  description = "Enable the rule to automatically remediate S3 buckets that allow public read access"
  type        = bool
  default     = false
}

variable "enable_s3_bucket_public_write_prohibited" {
  description = "Enable the rule to automatically remediate S3 buckets that allow public write access"
  type        = bool
  default     = false
}

# VPC Flow Logs Variables
variable "enable_vpc_flow_logs" {
  description = "Enable the rule to automatically enable VPC Flow Logs for VPCs without them"
  type        = bool
  default     = false
}

variable "vpc_flow_logs_log_group_prefix" {
  description = "Prefix for CloudWatch Log Group names for VPC Flow Logs"
  type        = string
  default     = "/aws/vpc/flowlogs/"
}

variable "vpc_flow_logs_traffic_type" {
  description = "Type of traffic to log (ACCEPT, REJECT, or ALL)"
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.vpc_flow_logs_traffic_type)
    error_message = "VPC Flow Logs traffic type must be one of: ACCEPT, REJECT, or ALL."
  }
}

# AWS Config Aggregator Variables
variable "enable_config_aggregator" {
  description = "Enable AWS Config aggregator for AWS Organizations. Requires this account to be the delegated administrator for Config in the organization."
  type        = bool
  default     = false
}

variable "config_aggregator_name" {
  description = "Name of the AWS Config aggregator"
  type        = string
  default     = "organization-config-aggregator"
}

variable "config_aggregator_regions" {
  description = "List of regions to aggregate Config data from. If empty, aggregates from all enabled regions."
  type        = list(string)
  default     = []
}
