resource "aws_config_config_rule" "nat_gateway_created" {
  count = var.enable_nat_gateway_deletion ? 1 : 0

  name        = "detect-nat-gateway-created"
  description = "Detects when a NAT Gateway is created"
  tags        = local.tags

  source {
    owner             = "AWS"
    source_identifier = "EC2_NATGATEWAY_RESOURCE_CHECK"
  }

  scope {
    compliance_resource_types = ["AWS::EC2::NatGateway"]
  }
}

resource "aws_ssm_document" "delete_nat_gateway" {
  count = var.enable_nat_gateway_deletion ? 1 : 0

  name            = "Remediations-DeleteNATGateway"
  document_type   = "Automation"
  document_format = "YAML"

  content = templatefile("${path.module}/ssm_documents/delete_nat_gateway.yaml", {
    SNSTopicArn = try(aws_sns_topic.admin_notifications[0].arn, "")
  })
}

resource "aws_config_remediation_configuration" "delete_nat_gateway" {
  count = var.enable_nat_gateway_deletion ? 1 : 0

  config_rule_name           = aws_config_config_rule.nat_gateway_created[0].name
  automatic                  = true
  maximum_automatic_attempts = 1
  resource_type              = "AWS::EC2::NatGateway"
  target_type                = "SSM_DOCUMENT"
  target_id                  = aws_ssm_document.delete_nat_gateway[0].name

  parameter {
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.delete_nat_gateway[0].arn
  }

  parameter {
    name           = "NatGatewayId"
    resource_value = "RESOURCE_ID"
  }
}

resource "aws_iam_role" "delete_nat_gateway" {
  count = var.enable_nat_gateway_deletion ? 1 : 0

  name               = "config-remediation-delete-nat-gateway"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "delete_nat_gateway" {
  count = var.enable_nat_gateway_deletion ? 1 : 0

  name = "config-remediation-delete-nat-gateway-policy"
  role = aws_iam_role.delete_nat_gateway[0].id

  policy = data.aws_iam_policy_document.remediation_policy.json
}

data "aws_iam_policy_document" "remediation_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DeleteNatGateway",
      "ec2:DescribeNatGateways"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "delete_nat_gateway_publish_to_sns" {
  count = var.enable_sns_notifications ? 1 : 0
  name  = "config-remediation-delete-nat-gateway-publish-to-sns-policy"
  role  = aws_iam_role.delete_nat_gateway[0].id

  policy = data.aws_iam_policy_document.publish_to_sns.json
}
