# VPC Default Security Group Restriction
# This rule ensures that the default security group in every VPC
# restricts all inbound and outbound traffic.

# Account-level Config rule (when create_organization_rules = false)
resource "aws_config_config_rule" "vpc_default_security_group_closed" {
  count       = var.enable_vpc_default_security_group_closed && !var.create_organization_rules ? 1 : 0
  name        = "vpc-default-security-group-closed"
  description = "Checks whether the default security group for VPC restricts all inbound and outbound traffic"

  tags = local.tags

  source {
    owner             = "AWS"
    source_identifier = "VPC_DEFAULT_SECURITY_GROUP_CLOSED"
  }

  scope {
    compliance_resource_types = ["AWS::EC2::SecurityGroup"]
  }
}

# Organization-level Config rule (when create_organization_rules = true)
resource "aws_config_organization_managed_rule" "vpc_default_security_group_closed" {
  count             = var.enable_vpc_default_security_group_closed && var.create_organization_rules ? 1 : 0
  name              = "vpc-default-security-group-closed"
  description       = "Checks whether the default security group for VPC restricts all inbound and outbound traffic"
  rule_identifier   = "VPC_DEFAULT_SECURITY_GROUP_CLOSED"
  excluded_accounts = var.excluded_accounts

  resource_types_scope = ["AWS::EC2::SecurityGroup"]
}

# SSM Automation Document for restricting default security groups
resource "aws_ssm_document" "restrict_default_security_group" {
  count           = var.enable_vpc_default_security_group_closed ? 1 : 0
  name            = "RestrictDefaultSecurityGroup"
  document_type   = "Automation"
  document_format = "YAML"

  content = templatefile("${path.module}/ssm_documents/restrict_default_security_group.yaml", {
    SNSTopicArn = try(aws_sns_topic.admin_notifications[0].arn, "")
  })

  tags = local.tags
}

# Local to get the rule name regardless of which type was created
locals {
  vpc_default_sg_rule_name = var.create_organization_rules ? (
    length(aws_config_organization_managed_rule.vpc_default_security_group_closed) > 0 ? aws_config_organization_managed_rule.vpc_default_security_group_closed[0].name : ""
    ) : (
    length(aws_config_config_rule.vpc_default_security_group_closed) > 0 ? aws_config_config_rule.vpc_default_security_group_closed[0].name : ""
  )
}

# Remediation configuration (works with account-level rules only)
# Note: For organization rules, remediation must be configured separately in each account
resource "aws_config_remediation_configuration" "restrict_default_security_group" {
  count            = var.enable_vpc_default_security_group_closed && !var.create_organization_rules ? 1 : 0
  config_rule_name = aws_config_config_rule.vpc_default_security_group_closed[0].name
  resource_type    = "AWS::EC2::SecurityGroup"
  target_type      = "SSM_DOCUMENT"
  target_id        = aws_ssm_document.restrict_default_security_group[0].name

  parameter {
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.restrict_default_security_group[0].arn
  }

  parameter {
    name           = "GroupId"
    resource_value = "RESOURCE_ID"
  }

  automatic                  = coalesce(var.vpc_default_security_group_automatic_remediation, var.automatic_remediation)
  maximum_automatic_attempts = 5
  retry_attempt_seconds      = 60
}

# IAM role for SSM automation
resource "aws_iam_role" "restrict_default_security_group" {
  count = var.enable_vpc_default_security_group_closed ? 1 : 0

  name               = "config-remediation-restrict-default-sg"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.tags
}

# IAM policy for the automation role
data "aws_iam_policy_document" "restrict_default_security_group_policy" {
  count = var.enable_vpc_default_security_group_closed ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeSecurityGroups",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress"
    ]
    # Wildcard required: ec2:DescribeSecurityGroups doesn't support resource-level permissions
    # Config remediation passes specific GroupId to limit scope of revoke operations
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "restrict_default_security_group" {
  count = var.enable_vpc_default_security_group_closed ? 1 : 0
  name  = "config-remediation-restrict-default-sg-policy"
  role  = aws_iam_role.restrict_default_security_group[0].id

  policy = data.aws_iam_policy_document.restrict_default_security_group_policy[0].json
}

# SNS publish policy (if notifications are enabled)
resource "aws_iam_role_policy" "restrict_default_security_group_sns" {
  count = var.enable_vpc_default_security_group_closed && var.enable_sns_notifications ? 1 : 0
  name  = "config-remediation-restrict-default-sg-sns-policy"
  role  = aws_iam_role.restrict_default_security_group[0].id

  policy = data.aws_iam_policy_document.publish_to_sns.json
}
