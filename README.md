# terraform-aws-config-remediation-rules

[![tflint](https://github.com/rhythmictech/terraform-aws-config-remediation-rules/actions/workflows/tflint.yaml/badge.svg?branch=master&event=push)](https://github.com/rhythmictech/terraform-aws-config-remediation-rules/actions/workflows/tflint.yaml)
[![trivy](https://github.com/rhythmictech/terraform-aws-config-remediation-rules/actions/workflows/trivy.yaml/badge.svg?branch=master&event=push)](https://github.com/rhythmictech/terraform-aws-config-remediation-rules/actions/workflows/trivy.yaml)
[![yamllint](https://github.com/rhythmictech/terraform-aws-config-remediation-rules/actions/workflows/yamllint.yaml/badge.svg?branch=master&event=push)](https://github.com/rhythmictech/terraform-aws-config-remediation-rules/actions/workflows/yamllint.yaml)
[![misspell](https://github.com/rhythmictech/terraform-aws-config-remediation-rules/actions/workflows/misspell.yaml/badge.svg?branch=master&event=push)](https://github.com/rhythmictech/terraform-aws-config-remediation-rules/actions/workflows/misspell.yaml)
[![pre-commit-check](https://github.com/rhythmictech/terraform-aws-config-remediation-rules/actions/workflows/pre-commit.yaml/badge.svg?branch=master&event=push)](https://github.com/rhythmictech/terraform-aws-config-remediation-rules/actions/workflows/pre-commit.yaml)
<a href="https://twitter.com/intent/follow?screen_name=RhythmicTech"><img src="https://img.shields.io/twitter/follow/RhythmicTech?style=social&logo=twitter" alt="follow on Twitter"></a>

## Example
Here's what using the module will look like
```hcl
module "config_remediation_rules" {
  source = "rhythmictech/config-remediation-rules/aws"

  name = "example-remediation-rules"

  # Enable specific remediation rules
  enable_nat_gateway_deletion = true
  enable_s3_bucket_public_read_prohibited = true
  enable_iam_password_policy = true

  # Configure IAM password policy requirements
  iam_password_minimum_length = 16
  iam_password_max_age = 90

  # IMPORTANT: Enable automatic remediation (defaults to false for safety)
  # When false, Config detects issues but requires manual approval
  # When true, Config automatically remediates without approval
  automatic_remediation = true

  # Enable SNS notifications for remediation actions
  enable_sns_notifications = true

  # Optional: Use an existing SNS topic instead of creating a new one
  # sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:existing-topic"

  tags = {
    Environment = "Production"
    Project     = "ExampleProject"
  }
}

# Access outputs for integration with other modules
output "enabled_rules_count" {
  value = module.config_remediation_rules.enabled_rules_count
}

output "config_rule_arns" {
  value = module.config_remediation_rules.config_rule_arns
}
```

## About
This module provides AWS Config remediation rules tied to automations in SSM. These are meant to be a starting point for automated remediations.

**Key Features:**
- **12 Gruntwork-compatible rules** covering IAM, S3, EC2, RDS, Lambda, and network security
- **Automatic remediation** via AWS Config + SSM Automation
- **SNS notifications** for all remediation actions (optional)
- **Variable validation** prevents misconfigurations
- **Comprehensive outputs** for monitoring and integration

### Gruntwork Compatibility

This module provides automatic remediation capabilities for all default rules from [Gruntwork's aws-config-rules module](https://docs.gruntwork.io/reference/modules/terraform-aws-security/aws-config-rules/). While Gruntwork's module focuses on **detection**, this module adds **automatic remediation**:

| Gruntwork Rule | This Module | Remediation Action |
|----------------|-------------|-------------------|
| `enable_encrypted_volumes` | ✅ Covered | Shuts down non-compliant instances |
| `enable_iam_password_policy` | ✅ Covered | Updates password policy automatically |
| `enable_iam_user_unused_credentials_check` | ✅ Covered | Deactivates unused credentials |
| `enable_insecure_sg_rules` | ✅ Covered | Deletes insecure rules |
| `enable_rds_storage_encrypted` | ✅ Covered | Deletes unencrypted instances |
| `enable_root_account_mfa` | ✅ Covered | Sends critical notifications |
| `enable_s3_bucket_public_read_prohibited` | ✅ Covered | Removes public access |
| `enable_s3_bucket_public_write_prohibited` | ✅ Covered | Removes public access |

**Plus additional rules:**
- NAT Gateway deletion
- Public subnet resource management
- Lambda VPC enforcement
- S3 public access blocks

### Features

**Network Security:**
- Automatic deletion of NAT Gateways upon creation (optional)
- Automatic deletion of resources (except load balancers) created in public subnets (optional)
- Automatic deletion of security group rules allowing 0.0.0.0/0 access to admin or database ports (optional)
- Automatic enablement of VPC Flow Logs for VPCs without them (optional)

**Compute & Application Security:**
- Automatic shutdown of EC2 instances created with unencrypted root volumes (optional)
- Automatic deletion of Lambda functions not associated with a VPC (optional)

**Data Security:**
- Automatic deletion of RDS instances without storage encryption (optional)
- Automatic enabling of S3 bucket public access block for newly created buckets (optional)
- Automatic remediation of S3 buckets that allow public read access (optional)
- Automatic remediation of S3 buckets that allow public write access (optional)

**Identity & Access Management:**
- Automatic update of IAM password policy to meet compliance requirements (optional)
- Automatic deactivation of unused IAM user credentials (optional)
- Automatic notification when root account MFA is not enabled (optional)


## NAT Gateway Deletion Feature
When enabled, this module creates an AWS Config rule that detects the creation of NAT Gateways. Upon detection, it triggers an SSM Automation document to delete the NAT Gateway. This feature is disabled by default and can be enabled by setting `enable_nat_gateway_deletion = true`.

**Note:** Use this feature with caution, as it will delete all newly created NAT Gateways in the AWS account where it's deployed.

## Public Subnet Resource Deletion Feature
When enabled, this module creates an AWS Config rule that detects the creation of resources in public subnets, except for load balancers. Upon detection, it triggers an SSM Automation document to delete or stop the resource. This feature is disabled by default and can be enabled by setting `enable_public_subnet_resource_deletion = true`.

Supported resource types:
- EC2 Instances (terminated)
- RDS Instances (deleted)
- ECS Tasks (stopped)

**Note:** Use this feature with caution, as it will delete or stop all newly created resources of the supported types (except load balancers) in public subnets in the AWS account where it's deployed.

## Unencrypted Root Volume Shutdown Feature
When enabled, this module creates an AWS Config rule that detects the creation of EC2 instances with unencrypted root volumes. Upon detection, it triggers an SSM Automation document to shut down the instance and send a notification to an SNS topic. This feature is disabled by default and can be enabled by setting `enable_unencrypted_volume_shutdown = true`.

**Note:** Use this feature with caution, as it will shut down all newly created EC2 instances with unencrypted root volumes in the AWS account where it's deployed.

## Non-VPC Lambda Function Deletion Feature
When enabled, this module creates an AWS Config rule that detects the creation of Lambda functions not associated with a VPC. Upon detection, it triggers an SSM Automation document to delete the Lambda function and send a notification to an SNS topic. This feature is disabled by default and can be enabled by setting `enable_non_vpc_lambda_deletion = true`.

**Note:** Use this feature with caution, as it will delete all newly created Lambda functions not associated with a VPC in the AWS account where it's deployed.

## S3 Public Access Block Feature
When enabled, this module creates an AWS Config rule that detects the creation of S3 buckets without public access block enabled. Upon detection, it triggers an SSM Automation document to enable the public access block for the bucket and send a notification to an SNS topic. This feature is disabled by default and can be enabled by setting `enable_s3_public_access_block = true`.

**Note:** This feature will only affect newly created S3 buckets that don't have a public access block configured. It will not modify existing buckets or buckets that already have a public access block policy.

## Security Group Open Port Deletion Feature
When enabled, this module creates an AWS Config rule that detects security group rules allowing 0.0.0.0/0 access to admin or database ports (SSH, RDP, MSSQL, MySQL, PostgreSQL). Upon detection, it triggers an SSM Automation document to delete the offending rules and send a notification to an SNS topic. This feature is disabled by default and can be enabled by setting `enable_sg_open_port_deletion = true`.

**Note:** Use this feature with caution, as it will delete all security group rules allowing 0.0.0.0/0 access to the specified ports in the AWS account where it's deployed.

## IAM Password Policy Feature
When enabled, this module creates an AWS Config rule that checks whether the account password policy for IAM users meets the specified requirements. Upon detection of non-compliance, it triggers an SSM Automation document to update the password policy. This feature is disabled by default and can be enabled by setting `enable_iam_password_policy = true`.

**Configurable parameters:**
- `iam_password_require_uppercase` (default: true)
- `iam_password_require_lowercase` (default: true)
- `iam_password_require_symbols` (default: true)
- `iam_password_require_numbers` (default: true)
- `iam_password_minimum_length` (default: 16)
- `iam_password_reuse_prevention` (default: 24)
- `iam_password_max_age` (default: 90 days)

## IAM Unused Credentials Check Feature
When enabled, this module creates an AWS Config rule that checks whether IAM users have passwords or active access keys that have not been used within the specified number of days. Upon detection, it triggers an SSM Automation document to deactivate unused credentials and send a notification to an SNS topic. This feature is disabled by default and can be enabled by setting `enable_iam_unused_credentials_check = true`.

**Default:** Credentials unused for 90 days will be deactivated (configurable via `iam_max_credential_usage_age`).

**Note:** This feature deactivates access keys and removes console passwords for IAM users with unused credentials. Use with caution.

## RDS Storage Encryption Feature
When enabled, this module creates an AWS Config rule that checks whether storage encryption is enabled for RDS DB instances. Upon detection of an unencrypted instance, it triggers an SSM Automation document to delete the instance and send a notification to an SNS topic. This feature is disabled by default and can be enabled by setting `enable_rds_storage_encrypted = true`.

**Note:** Use this feature with extreme caution, as it will delete RDS instances without encryption. The deletion skips final snapshots.

## Root Account MFA Feature
When enabled, this module creates an AWS Config rule that checks whether the root account has MFA enabled. Upon detection of MFA not being enabled, it triggers an SSM Automation document to send a critical notification to an SNS topic. This feature is disabled by default and can be enabled by setting `enable_root_account_mfa = true`.

**Note:** Root account MFA cannot be automatically enabled and requires manual intervention. This rule only sends notifications.

## S3 Bucket Public Read/Write Prohibited Features
When enabled, these modules create AWS Config rules that check whether S3 buckets allow public read or write access. Upon detection, they trigger an SSM Automation document to remove public access by:
- Removing public ACL grants
- Deleting bucket policies that allow public access
- Enabling S3 bucket public access block

These features are disabled by default and can be enabled by setting:
- `enable_s3_bucket_public_read_prohibited = true`
- `enable_s3_bucket_public_write_prohibited = true`

**Note:** This feature will modify bucket ACLs, policies, and public access block settings to prevent public access.

## VPC Flow Logs Feature
When enabled, this module creates an AWS Config rule that checks whether VPC Flow Logs are enabled for VPCs. Upon detection of a VPC without flow logs, it triggers an SSM Automation document to enable flow logs and send a notification to an SNS topic. This feature is disabled by default and can be enabled by setting `enable_vpc_flow_logs = true`.

**Configuration:**
- `vpc_flow_logs_log_group_prefix` - CloudWatch Log Group prefix (default: `/aws/vpc/flowlogs/`)
- `vpc_flow_logs_traffic_type` - Traffic type to log: `ACCEPT`, `REJECT`, or `ALL` (default: `ALL`)

**What it does:**
1. Creates a CloudWatch Log Group for each VPC (e.g., `/aws/vpc/flowlogs/vpc-abc123`)
2. Enables VPC Flow Logs to capture network traffic
3. Creates necessary IAM roles for Flow Logs to write to CloudWatch

**Note:** This feature helps with security monitoring, troubleshooting, and compliance. Flow logs incur CloudWatch Logs storage costs.

## Configuration

### Automatic vs Manual Remediation

**IMPORTANT SAFETY FEATURE:** By default, `automatic_remediation = false`, which means:
- ✅ AWS Config **detects** non-compliant resources
- ✅ Remediation actions are **defined** but not executed
- ⚠️ You must **manually approve** each remediation in the AWS Console

To enable automatic remediation (use with caution):
```hcl
automatic_remediation = true
```

**Why this is safer:**
- Test remediation actions before enabling automatic mode
- Review what would be remediated first
- Prevent accidental deletion of critical resources
- Gradual rollout: detect first, remediate later

**Manual Approval Process:**
1. Config detects non-compliant resource
2. You receive SNS notification (if enabled)
3. Review the resource in AWS Config Console
4. Click "Remediate" to manually trigger the action

### SNS Notifications

This module supports SNS notifications for remediation actions. You have two options:

**Option 1: Create a new SNS topic (default)**
```hcl
module "config_remediation_rules" {
  source = "rhythmictech/config-remediation-rules/aws"

  enable_sns_notifications = true
  # Module will create a new SNS topic named "config-remediation-rules-*"
}
```

**Option 2: Use an existing SNS topic**
```hcl
module "config_remediation_rules" {
  source = "rhythmictech/config-remediation-rules/aws"

  enable_sns_notifications = true
  sns_topic_arn           = "arn:aws:sns:us-east-1:123456789012:my-existing-topic"
  # Module will use your existing topic instead of creating a new one
}
```

**Benefits of using an existing topic:**
- Centralized notification management across multiple modules
- Pre-configured subscriptions (email, Lambda, etc.)
- Consistent alert routing to existing monitoring systems
- Reduced resource creation overhead

**Note:** When using an existing topic, ensure the remediation IAM roles have `sns:Publish` permissions to your topic.

### Variable Validation

This module includes built-in validation for IAM-related variables to prevent misconfigurations:

| Variable | Valid Range | AWS Limit |
|----------|-------------|-----------|
| `iam_password_minimum_length` | 6-128 | AWS IAM limit |
| `iam_password_reuse_prevention` | 1-24 | AWS IAM limit |
| `iam_password_max_age` | 1-1095 days | AWS IAM limit |
| `iam_max_credential_usage_age` | 1-365 days | Security best practice |

If you provide invalid values, Terraform will fail at plan time with a clear error message:

```
Error: Invalid value for variable

IAM password minimum length must be between 6 and 128 characters (AWS IAM limits).
```

### Module Outputs

The module provides comprehensive outputs for monitoring and integration:

```hcl
# Summary outputs
enabled_rules          # Map of all enabled rules
enabled_rules_count    # Count of enabled rules
sns_topic_arn         # SNS topic ARN (if enabled)

# Resource outputs
config_rule_arns      # ARNs of all Config rules
iam_role_arns         # ARNs of all IAM roles
ssm_document_names    # Names of all SSM documents
```

**Example usage:**
```hcl
# Monitor which rules are active
output "active_remediations" {
  value = module.config_remediation_rules.enabled_rules
}

# Use in CloudWatch alarms
resource "aws_cloudwatch_metric_alarm" "config_compliance" {
  alarm_name = "config-compliance-check"
  # Reference specific rule ARN
  dimensions = {
    ConfigRuleName = module.config_remediation_rules.config_rule_arns["nat_gateway"]
  }
}
```

## Architecture

This architecture diagram illustrates the flow of the AWS Config Remediation Rules module:

![AWS Config Remediation Rules Architecture](docs/aws-config-remediation-rules-architecture.png)

1. **AWS Config Rules**: The module creates several AWS Config rules to detect non-compliant resources

2. **AWS Config Remediation**: When a non-compliant resource is detected, AWS Config triggers the corresponding remediation action.

3. **SSM Automation Documents**: The module creates SSM Automation documents for each remediation action

4. **IAM Roles**: Each remediation action has an associated IAM role with the necessary permissions to perform the remediation.

5. **SNS Topic**: If enabled, an SNS topic is created to send notifications about remediation actions.

## Recent Improvements

### Code Quality & Maintainability
- ✅ **Safety by Default**: `automatic_remediation` defaults to `false` - requires manual approval
- ✅ **Variable Validation**: All IAM-related variables now have built-in validation to prevent invalid configurations
- ✅ **Consolidated S3 Rules**: S3 public read/write rules use `for_each` to eliminate duplication (58% reduction)
- ✅ **Consistent SNS Logic**: All rules now properly check both rule-enabled and SNS-enabled conditions
- ✅ **Comprehensive Outputs**: Added outputs for rule ARNs, role ARNs, and SSM document names
- ✅ **Centralized Configuration**: New `locals.tf` provides common patterns and enabled rules summary

### Breaking Changes
⚠️ **Important:** `automatic_remediation` now defaults to `false` for safety.

**If you were relying on automatic remediation**, add this to your module call:
```hcl
automatic_remediation = true
```

This change prevents accidental automatic remediation and gives you a chance to test first.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.73.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_tags"></a> [tags](#module\_tags) | rhythmictech/tags/terraform | ~> 1.1 |

## Resources

| Name | Type |
|------|------|
| [aws_config_config_rule.lambda_in_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_config_rule) | resource |
| [aws_config_config_rule.nat_gateway_created](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_config_rule) | resource |
| [aws_config_config_rule.public_subnet_resources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_config_rule) | resource |
| [aws_config_config_rule.s3_public_access_block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_config_rule) | resource |
| [aws_config_config_rule.sg_open_admin_db_ports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_config_rule) | resource |
| [aws_config_config_rule.unencrypted_root_volume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_config_rule) | resource |
| [aws_config_remediation_configuration.delete_nat_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_remediation_configuration) | resource |
| [aws_config_remediation_configuration.delete_non_vpc_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_remediation_configuration) | resource |
| [aws_config_remediation_configuration.delete_open_admin_db_ports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_remediation_configuration) | resource |
| [aws_config_remediation_configuration.delete_public_subnet_resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_remediation_configuration) | resource |
| [aws_config_remediation_configuration.enable_s3_public_access_block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_remediation_configuration) | resource |
| [aws_config_remediation_configuration.shutdown_unencrypted_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_remediation_configuration) | resource |
| [aws_iam_role.delete_nat_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.delete_non_vpc_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.delete_open_admin_db_ports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.delete_public_subnet_resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.enable_s3_public_access_block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.shutdown_unencrypted_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.delete_nat_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.delete_nat_gateway_publish_to_sns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.delete_non_vpc_lambda_publish_to_sns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.delete_open_admin_db_ports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.delete_open_admin_db_ports_publish_to_sns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.delete_public_subnet_resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.delete_public_subnet_resource_publish_to_sns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.enable_s3_public_access_block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.enable_s3_public_access_block_publish_to_sns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.non_vpc_lambda_remediation_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.shutdown_unencrypted_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.shutdown_unencrypted_instance_publish_to_sns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_sns_topic.admin_notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_ssm_document.delete_nat_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |
| [aws_ssm_document.delete_non_vpc_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |
| [aws_ssm_document.delete_open_admin_db_ports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |
| [aws_ssm_document.delete_public_subnet_resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |
| [aws_ssm_document.enable_s3_public_access_block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |
| [aws_ssm_document.shutdown_unencrypted_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.delete_open_admin_db_ports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.delete_public_subnet_resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.enable_s3_public_access_block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.non_vpc_lambda_remediation_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.publish_to_sns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.remediation_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.shutdown_unencrypted_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_nat_gateway_deletion"></a> [enable\_nat\_gateway\_deletion](#input\_enable\_nat\_gateway\_deletion) | Enable the rule to automatically delete NAT Gateways when created | `bool` | `false` | no |
| <a name="input_enable_non_vpc_lambda_deletion"></a> [enable\_non\_vpc\_lambda\_deletion](#input\_enable\_non\_vpc\_lambda\_deletion) | Enable the rule to automatically delete Lambda functions not associated with a VPC | `bool` | `false` | no |
| <a name="input_enable_public_subnet_resource_deletion"></a> [enable\_public\_subnet\_resource\_deletion](#input\_enable\_public\_subnet\_resource\_deletion) | Enable the rule to automatically delete resources (except load balancers) created in public subnets | `bool` | `false` | no |
| <a name="input_enable_s3_public_access_block"></a> [enable\_s3\_public\_access\_block](#input\_enable\_s3\_public\_access\_block) | Enable the rule to automatically enable public access block for S3 buckets created without it | `bool` | `false` | no |
| <a name="input_enable_sg_open_port_deletion"></a> [enable\_sg\_open\_port\_deletion](#input\_enable\_sg\_open\_port\_deletion) | Enable the rule to automatically delete security group rules allowing 0.0.0.0/0 access to admin or database ports | `bool` | `false` | no |
| <a name="input_enable_sns_notifications"></a> [enable\_sns\_notifications](#input\_enable\_sns\_notifications) | Enable SNS notifications for remediation actions | `bool` | `false` | no |
| <a name="input_enable_unencrypted_volume_shutdown"></a> [enable\_unencrypted\_volume\_shutdown](#input\_enable\_unencrypted\_volume\_shutdown) | Enable the rule to automatically shut down EC2 instances created with unencrypted root volumes | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | Moniker to apply to all resources in the module | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | User-Defined tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_tags_module"></a> [tags\_module](#output\_tags\_module) | Tags Module in it's entirety |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
