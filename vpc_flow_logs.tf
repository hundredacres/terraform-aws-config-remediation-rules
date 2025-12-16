# Account-level Config rule (when create_organization_rules = false)
resource "aws_config_config_rule" "vpc_flow_logs_enabled" {
  count       = var.enable_vpc_flow_logs && !var.create_organization_rules ? 1 : 0
  name        = "vpc-flow-logs-enabled"
  description = "Checks whether Amazon VPC Flow Logs are enabled for VPCs"

  tags = local.tags

  source {
    owner             = "AWS"
    source_identifier = "VPC_FLOW_LOGS_ENABLED"
  }

  scope {
    compliance_resource_types = ["AWS::EC2::VPC"]
  }
}

# Organization-level Config rule (when create_organization_rules = true)
resource "aws_config_organization_managed_rule" "vpc_flow_logs_enabled" {
  count             = var.enable_vpc_flow_logs && var.create_organization_rules ? 1 : 0
  name              = "vpc-flow-logs-enabled"
  description       = "Checks whether Amazon VPC Flow Logs are enabled for VPCs"
  rule_identifier   = "VPC_FLOW_LOGS_ENABLED"
  excluded_accounts = var.excluded_accounts

  resource_types_scope = ["AWS::EC2::VPC"]
}

resource "aws_ssm_document" "enable_vpc_flow_logs" {
  count           = var.enable_vpc_flow_logs ? 1 : 0
  name            = "EnableVPCFlowLogs"
  document_type   = "Automation"
  document_format = "YAML"

  content = templatefile("${path.module}/ssm_documents/enable_vpc_flow_logs.yaml", {
    SNSTopicArn        = try(aws_sns_topic.admin_notifications[0].arn, "")
    FlowLogsRoleArn    = try(aws_iam_role.vpc_flow_logs[0].arn, "")
    LogGroupNamePrefix = var.vpc_flow_logs_log_group_prefix
    TrafficType        = var.vpc_flow_logs_traffic_type
  })

  tags = local.tags
}

# Local to get the rule name regardless of which type was created
locals {
  vpc_flow_logs_rule_name = var.create_organization_rules ? (
    length(aws_config_organization_managed_rule.vpc_flow_logs_enabled) > 0 ? aws_config_organization_managed_rule.vpc_flow_logs_enabled[0].name : ""
    ) : (
    length(aws_config_config_rule.vpc_flow_logs_enabled) > 0 ? aws_config_config_rule.vpc_flow_logs_enabled[0].name : ""
  )
}

# Remediation configuration (works with both account and organization rules)
# Note: For organization rules, remediation must be configured separately in each account
# This remediation only works in the management account
resource "aws_config_remediation_configuration" "enable_vpc_flow_logs" {
  count            = var.enable_vpc_flow_logs && !var.create_organization_rules ? 1 : 0
  config_rule_name = aws_config_config_rule.vpc_flow_logs_enabled[0].name
  resource_type    = "AWS::EC2::VPC"
  target_type      = "SSM_DOCUMENT"
  target_id        = aws_ssm_document.enable_vpc_flow_logs[0].name

  parameter {
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.enable_vpc_flow_logs_automation[0].arn
  }

  parameter {
    name           = "VpcId"
    resource_value = "RESOURCE_ID"
  }

  automatic                  = coalesce(var.vpc_flow_logs_automatic_remediation, var.automatic_remediation)
  maximum_automatic_attempts = 5
  retry_attempt_seconds      = 60
}

# IAM role for SSM automation
resource "aws_iam_role" "enable_vpc_flow_logs_automation" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  name               = "config-remediation-enable-vpc-flow-logs"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "enable_vpc_flow_logs_automation_policy" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateFlowLogs",
      "ec2:DescribeFlowLogs",
      "ec2:DescribeVpcs",
      "logs:CreateLogGroup",
      "logs:DescribeLogGroups",
      "iam:PassRole"
    ]
    # Wildcard required: EC2/CloudWatch Describe* actions don't support resource-level permissions
    # iam:PassRole needs wildcard for the flow logs service role
    # Config remediation passes specific VPC ID to limit scope
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "enable_vpc_flow_logs_automation" {
  count = var.enable_vpc_flow_logs ? 1 : 0
  name  = "config-remediation-enable-vpc-flow-logs-policy"
  role  = aws_iam_role.enable_vpc_flow_logs_automation[0].id

  policy = data.aws_iam_policy_document.enable_vpc_flow_logs_automation_policy[0].json
}

resource "aws_iam_role_policy" "enable_vpc_flow_logs_automation_publish_to_sns" {
  count = var.enable_vpc_flow_logs && var.enable_sns_notifications ? 1 : 0
  name  = "config-remediation-enable-vpc-flow-logs-publish-to-sns-policy"
  role  = aws_iam_role.enable_vpc_flow_logs_automation[0].id

  policy = data.aws_iam_policy_document.publish_to_sns.json
}

# IAM role for VPC Flow Logs to write to CloudWatch Logs
resource "aws_iam_role" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  name = "vpc-flow-logs-role"
  tags = local.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

data "aws_iam_policy_document" "vpc_flow_logs_policy" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    # Wildcard required: CloudWatch Logs actions for VPC Flow Logs service role
    # Flow logs are created dynamically per VPC with specific log group names
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0
  name  = "vpc-flow-logs-policy"
  role  = aws_iam_role.vpc_flow_logs[0].id

  policy = data.aws_iam_policy_document.vpc_flow_logs_policy[0].json
}
