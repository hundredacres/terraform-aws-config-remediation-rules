
resource "aws_config_config_rule" "sg_open_admin_db_ports" {
  count       = var.enable_sg_open_port_deletion ? 1 : 0
  name        = "restrict-sg-open-admin-db-ports"
  description = "Detects security groups with rules allowing 0.0.0.0/0 access to admin or database ports"

  tags = local.tags

  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }

  scope {
    compliance_resource_types = ["AWS::EC2::SecurityGroup"]
  }
}

resource "aws_ssm_document" "delete_open_admin_db_ports" {
  count           = var.enable_sg_open_port_deletion ? 1 : 0
  name            = "DeleteOpenAdminDBPorts"
  document_type   = "Automation"
  document_format = "YAML"

  content = templatefile("${path.module}/ssm_documents/delete_open_admin_db_ports.yaml", {
    SNSTopicArn = try(aws_sns_topic.admin_notifications[0].arn, "")
  })
}

resource "aws_config_remediation_configuration" "delete_open_admin_db_ports" {
  count            = var.enable_sg_open_port_deletion ? 1 : 0
  config_rule_name = aws_config_config_rule.sg_open_admin_db_ports[0].name
  resource_type    = "AWS::EC2::SecurityGroup"
  target_type      = "SSM_DOCUMENT"
  target_id        = aws_ssm_document.delete_open_admin_db_ports[0].name

  parameter {
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.delete_open_admin_db_ports[0].arn
  }

  parameter {
    name           = "SecurityGroupId"
    resource_value = "RESOURCE_ID"
  }

  automatic                  = var.automatic_remediation
  maximum_automatic_attempts = 1
}

resource "aws_iam_role" "delete_open_admin_db_ports" {
  count = var.enable_sg_open_port_deletion ? 1 : 0

  name               = "config-remediation-delete-open-admin-db-ports"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "delete_open_admin_db_ports_policy" {
  count = var.enable_sg_open_port_deletion ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeSecurityGroups",
      "ec2:RevokeSecurityGroupIngress"
    ]
    # Wildcard required: EC2 Describe* actions don't support resource-level permissions
    # Config remediation passes specific security group ID to limit scope
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "delete_open_admin_db_ports" {
  count = var.enable_sg_open_port_deletion ? 1 : 0
  name  = "config-remediation-delete-open-admin-db-ports-policy"
  role  = aws_iam_role.delete_open_admin_db_ports[0].id

  policy = data.aws_iam_policy_document.delete_open_admin_db_ports_policy[0].json
}

resource "aws_iam_role_policy" "delete_open_admin_db_ports_publish_to_sns" {
  count = var.enable_sg_open_port_deletion && var.enable_sns_notifications ? 1 : 0
  name  = "config-remediation-delete-open-admin-db-ports-publish-to-sns-policy"
  role  = aws_iam_role.delete_open_admin_db_ports[0].id

  policy = data.aws_iam_policy_document.publish_to_sns.json

}
