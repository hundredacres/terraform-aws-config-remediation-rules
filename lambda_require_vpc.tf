resource "aws_config_config_rule" "lambda_in_vpc" {
  count = var.enable_non_vpc_lambda_deletion ? 1 : 0

  name        = "ensure-lambda-in-vpc"
  description = "Ensures Lambda functions are associated with a VPC"

  source {
    owner             = "AWS"
    source_identifier = "LAMBDA_INSIDE_VPC"
  }

  scope {
    compliance_resource_types = ["AWS::Lambda::Function"]
  }
}

resource "aws_ssm_document" "delete_non_vpc_lambda" {
  count = var.enable_non_vpc_lambda_deletion ? 1 : 0

  name            = "Remediations-DeleteNonVPCLambda"
  document_type   = "Automation"
  document_format = "YAML"

  content = templatefile("${path.module}/ssm_documents/delete_non_vpc_lambda.yaml", {
    SNSTopicArn = try(aws_sns_topic.admin_notifications[0].arn, "")
  })
}

resource "aws_config_remediation_configuration" "delete_non_vpc_lambda" {
  count = var.enable_non_vpc_lambda_deletion ? 1 : 0

  config_rule_name           = aws_config_config_rule.lambda_in_vpc[0].name
  automatic                  = true
  maximum_automatic_attempts = 1
  resource_type              = "AWS::Lambda::Function"
  target_type                = "SSM_DOCUMENT"
  target_id                  = aws_ssm_document.delete_non_vpc_lambda[0].name

  parameter {
    name           = "FunctionName"
    resource_value = "RESOURCE_ID"
  }
}

resource "aws_iam_role" "delete_non_vpc_lambda" {
  count = var.enable_non_vpc_lambda_deletion ? 1 : 0

  name               = "config-remediation-delete-non-vpc-lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "delete_non_vpc_lambda_publish_to_sns" {
  count = var.enable_sns_notifications ? 1 : 0

  name = "config-remediation-delete-non-vpc-lambda-publish-to-sns-policy"
  role = aws_iam_role.delete_non_vpc_lambda[0].id

  policy = data.aws_iam_policy_document.publish_to_sns.json
}

data "aws_iam_policy_document" "non_vpc_lambda_remediation_policy" {
  statement {
    effect = "Allow"
    actions = [
      "lambda:DeleteFunction",
      "lambda:GetFunction",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "non_vpc_lambda_remediation_policy" {
  count = var.enable_non_vpc_lambda_deletion ? 1 : 0

  name_prefix = "config-remediation-delete-non-vpc-lambda-policy"
  role        = aws_iam_role.delete_non_vpc_lambda[0].id
  policy      = data.aws_iam_policy_document.non_vpc_lambda_remediation_policy.json
}
