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
  # Only create a new topic if SNS is enabled AND no existing topic ARN is provided
  count = var.enable_sns_notifications && var.sns_topic_arn == "" ? 1 : 0

  name_prefix = "config-remediation-rules"
  tags        = local.tags
}

# Local to determine the SNS topic ARN to use (provided or created)
locals {
  sns_topic_arn_final = var.enable_sns_notifications ? (
    var.sns_topic_arn != "" ? var.sns_topic_arn : try(aws_sns_topic.admin_notifications[0].arn, "")
  ) : ""
}

data "aws_iam_policy_document" "publish_to_sns" {
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [local.sns_topic_arn_final != "" ? local.sns_topic_arn_final : "arn:aws:sns:*:${data.aws_caller_identity.current.account_id}:nonexistent-topic"]
  }
}
