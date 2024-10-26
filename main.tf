data "aws_caller_identity" "current" {}

module "tags" {
  source  = "rhythmictech/tags/terraform"
  version = "~> 1.1"

  enforce_case = "UPPER"
  names        = [var.name]
  tags         = var.tags
}

locals {
  tags = module.tags.tags_no_name
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
  }
}

resource "aws_sns_topic" "admin_notifications" {
  count = var.enable_sns_notifications ? 1 : 0

  name_prefix = "config-remediation-rules"
  tags        = local.tags
}

data "aws_iam_policy_document" "publish_to_sns" {
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [try(aws_sns_topic.admin_notifications[0].arn, "arn:aws:sns:*:${data.aws_caller_identity.current.account_id}:nonexistent-topic")]
  }
}
