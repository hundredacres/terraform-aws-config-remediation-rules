resource "aws_config_config_rule" "unencrypted_root_volume" {
  count = var.enable_unencrypted_volume_shutdown ? 1 : 0

  name        = "detect-unencrypted-root-volume"
  description = "Detects EC2 instances created with unencrypted root volumes"

  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }

  scope {
    compliance_resource_types = ["AWS::EC2::Instance"]
  }
}

resource "aws_ssm_document" "shutdown_unencrypted_instance" {
  count = var.enable_unencrypted_volume_shutdown ? 1 : 0

  name            = "Remediations-ShutdownUnencryptedInstance"
  document_type   = "Automation"
  document_format = "YAML"

  content = templatefile("${path.module}/ssm_documents/shutdown_unencrypted_instance.yaml", {
    SNSTopicArn = try(aws_sns_topic.admin_notifications[0].arn, "")
  })
}

resource "aws_config_remediation_configuration" "shutdown_unencrypted_instance" {
  count = var.enable_unencrypted_volume_shutdown ? 1 : 0

  config_rule_name           = aws_config_config_rule.unencrypted_root_volume[0].name
  automatic                  = true
  maximum_automatic_attempts = 1
  resource_type              = "AWS::EC2::Instance"
  target_type                = "SSM_DOCUMENT"
  target_id                  = aws_ssm_document.shutdown_unencrypted_instance[0].name

  parameter {
    name           = "InstanceId"
    resource_value = "RESOURCE_ID"
  }
}

resource "aws_iam_role" "shutdown_unencrypted_instance" {
  count = var.enable_unencrypted_volume_shutdown ? 1 : 0

  name               = "config-remediation-shutdown-unencrypted-instance"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "shutdown_unencrypted_instance" {
  count = var.enable_unencrypted_volume_shutdown ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "ec2:StopInstances",
      "ec2:DescribeInstances",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "shutdown_unencrypted_instance" {
  count = var.enable_unencrypted_volume_shutdown ? 1 : 0
  name  = "config-remediation-shutdown-unencrypted-instance-policy"
  role  = aws_iam_role.shutdown_unencrypted_instance[0].id

  policy = data.aws_iam_policy_document.shutdown_unencrypted_instance[0].json
}

resource "aws_iam_role_policy" "shutdown_unencrypted_instance_publish_to_sns" {
  count = var.enable_sns_notifications ? 1 : 0
  name  = "config-remediation-shutdown-unencrypted-instance-publish-to-sns-policy"
  role  = aws_iam_role.shutdown_unencrypted_instance[0].id

  policy = data.aws_iam_policy_document.publish_to_sns.json
}
