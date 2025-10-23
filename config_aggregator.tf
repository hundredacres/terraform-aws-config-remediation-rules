# AWS Config Aggregator for AWS Organizations
# This allows centralized viewing of Config data across all accounts in the organization

resource "aws_config_configuration_aggregator" "organization" {
  count = var.enable_config_aggregator ? 1 : 0

  name = var.config_aggregator_name
  tags = local.tags

  organization_aggregation_source {
    all_regions = length(var.config_aggregator_regions) == 0 ? true : false
    regions     = length(var.config_aggregator_regions) > 0 ? var.config_aggregator_regions : null
    role_arn    = aws_iam_role.config_aggregator[0].arn
  }

  depends_on = [
    aws_iam_role_policy_attachment.config_aggregator
  ]
}

# IAM role for Config aggregator
resource "aws_iam_role" "config_aggregator" {
  count = var.enable_config_aggregator ? 1 : 0

  name               = "config-aggregator-role"
  tags               = local.tags
  assume_role_policy = data.aws_iam_policy_document.config_aggregator_assume_role[0].json
}

# Assume role policy for Config service
data "aws_iam_policy_document" "config_aggregator_assume_role" {
  count = var.enable_config_aggregator ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Attach AWS managed policy for Config aggregator
resource "aws_iam_role_policy_attachment" "config_aggregator" {
  count = var.enable_config_aggregator ? 1 : 0

  role       = aws_iam_role.config_aggregator[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}

# Optional: Authorization for individual accounts (not needed for Organizations, but keeping as reference)
# If you need to authorize individual accounts instead of using Organizations:
#
# resource "aws_config_aggregate_authorization" "account" {
#   count = var.enable_config_aggregator && var.use_individual_accounts ? length(var.authorized_account_ids) : 0
#
#   account_id = var.authorized_account_ids[count.index]
#   region     = data.aws_region.current.name
#   tags       = local.tags
# }
