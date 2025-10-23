resource "aws_config_config_rule" "public_subnet_resources" {
  count       = var.enable_public_subnet_resource_deletion ? 1 : 0
  name        = "detect-public-subnet-resources"
  description = "Detects resources created in public subnets (except load balancers)"

  tags = local.tags

  source {
    owner             = "AWS"
    source_identifier = "VPC_PUBLIC_SUBNET_INSTANCE"
  }

  scope {
    compliance_resource_types = ["AWS::EC2::Instance", "AWS::RDS::DBInstance", "AWS::ECS::Task"]
  }
}

resource "aws_ssm_document" "delete_public_subnet_resource" {
  count = var.enable_public_subnet_resource_deletion ? 1 : 0

  name            = "Remediations-DeletePublicSubnetResource"
  document_type   = "Automation"
  document_format = "YAML"

  content = templatefile("${path.module}/ssm_documents/delete_public_subnet_resource.yaml", {
    SNSTopicArn = try(aws_sns_topic.admin_notifications[0].arn, "")
  })
}

resource "aws_config_remediation_configuration" "delete_public_subnet_resource" {
  count = var.enable_public_subnet_resource_deletion ? 1 : 0

  config_rule_name           = aws_config_config_rule.public_subnet_resources[0].name
  automatic                  = var.automatic_remediation
  maximum_automatic_attempts = 1
  resource_type              = "AWS::EC2::Instance" # This will be overridden by the actual resource type
  target_type                = "SSM_DOCUMENT"
  target_id                  = aws_ssm_document.delete_public_subnet_resource[0].name

  parameter {
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.delete_public_subnet_resource[0].arn
  }

  parameter {
    name           = "ResourceId"
    resource_value = "RESOURCE_ID"
  }

  parameter {
    name         = "ResourceType"
    static_value = "RESOURCE_TYPE"
  }


}

resource "aws_iam_role" "delete_public_subnet_resource" {
  count = var.enable_public_subnet_resource_deletion ? 1 : 0

  name               = "config-remediation-delete-public-resource"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "delete_public_subnet_resource_policy" {
  count = var.enable_public_subnet_resource_deletion ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "ec2:TerminateInstances",
      "ec2:DescribeInstances",
      "rds:DeleteDBInstance",
      "rds:DescribeDBInstances",
      "ecs:StopTask",
      "ecs:DescribeTasks"
    ]
    # Wildcard required: Describe* actions across multiple services don't support resource-level permissions
    # Config remediation passes specific resource ID to limit scope
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "delete_public_subnet_resource" {
  count = var.enable_public_subnet_resource_deletion ? 1 : 0

  name_prefix = "config-remediation-delete-public-subnet-resource"
  role        = aws_iam_role.delete_public_subnet_resource[0].id
  policy      = data.aws_iam_policy_document.delete_public_subnet_resource_policy[0].json
}

resource "aws_iam_role_policy" "delete_public_subnet_resource_publish_to_sns" {
  count = var.enable_public_subnet_resource_deletion && var.enable_sns_notifications ? 1 : 0
  name  = "config-remediation-delete-public-subnet-resource-publish-to-sns-policy"
  role  = aws_iam_role.delete_public_subnet_resource[0].id

  policy = data.aws_iam_policy_document.publish_to_sns.json
}
