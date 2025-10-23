output "tags_module" {
  description = "Tags Module in it's entirety"
  value       = module.tags
}

output "enabled_rules" {
  description = "Map of enabled remediation rules"
  value       = local.enabled_rules
}

output "enabled_rules_count" {
  description = "Number of enabled remediation rules"
  value       = local.enabled_rules_count
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for notifications (provided or created, if enabled)"
  value       = local.sns_topic_arn_final != "" ? local.sns_topic_arn_final : null
}

output "config_rule_arns" {
  description = "Map of Config rule names to their ARNs"
  value = merge(
    var.enable_nat_gateway_deletion ? { nat_gateway = try(aws_config_config_rule.nat_gateway_created[0].arn, null) } : {},
    var.enable_public_subnet_resource_deletion ? { public_subnet_resources = try(aws_config_config_rule.public_subnet_resources[0].arn, null) } : {},
    var.enable_unencrypted_volume_shutdown ? { unencrypted_root_volume = try(aws_config_config_rule.unencrypted_root_volume[0].arn, null) } : {},
    var.enable_non_vpc_lambda_deletion ? { lambda_in_vpc = try(aws_config_config_rule.lambda_in_vpc[0].arn, null) } : {},
    var.enable_s3_public_access_block ? { s3_public_access_block = try(aws_config_config_rule.s3_public_access_block[0].arn, null) } : {},
    var.enable_sg_open_port_deletion ? { sg_open_admin_db_ports = try(aws_config_config_rule.sg_open_admin_db_ports[0].arn, null) } : {},
    var.enable_iam_password_policy ? { iam_password_policy = try(aws_config_config_rule.iam_password_policy[0].arn, null) } : {},
    var.enable_iam_unused_credentials_check ? { iam_unused_credentials = try(aws_config_config_rule.iam_unused_credentials[0].arn, null) } : {},
    var.enable_rds_storage_encrypted ? { rds_storage_encrypted = try(aws_config_config_rule.rds_storage_encrypted[0].arn, null) } : {},
    var.enable_root_account_mfa ? { root_account_mfa = try(aws_config_config_rule.root_account_mfa[0].arn, null) } : {},
    var.enable_s3_bucket_public_read_prohibited ? { s3_bucket_public_read_prohibited = try(aws_config_config_rule.s3_bucket_public_access["read"].arn, null) } : {},
    var.enable_s3_bucket_public_write_prohibited ? { s3_bucket_public_write_prohibited = try(aws_config_config_rule.s3_bucket_public_access["write"].arn, null) } : {},
    var.enable_vpc_flow_logs ? { vpc_flow_logs_enabled = try(aws_config_config_rule.vpc_flow_logs_enabled[0].arn, null) } : {}
  )
}

output "iam_role_arns" {
  description = "Map of remediation IAM role names to their ARNs"
  value = merge(
    var.enable_nat_gateway_deletion ? { delete_nat_gateway = try(aws_iam_role.delete_nat_gateway[0].arn, null) } : {},
    var.enable_public_subnet_resource_deletion ? { delete_public_subnet_resource = try(aws_iam_role.delete_public_subnet_resource[0].arn, null) } : {},
    var.enable_unencrypted_volume_shutdown ? { shutdown_unencrypted_instance = try(aws_iam_role.shutdown_unencrypted_instance[0].arn, null) } : {},
    var.enable_non_vpc_lambda_deletion ? { delete_non_vpc_lambda = try(aws_iam_role.delete_non_vpc_lambda[0].arn, null) } : {},
    var.enable_s3_public_access_block ? { enable_s3_public_access_block = try(aws_iam_role.enable_s3_public_access_block[0].arn, null) } : {},
    var.enable_sg_open_port_deletion ? { delete_open_admin_db_ports = try(aws_iam_role.delete_open_admin_db_ports[0].arn, null) } : {},
    var.enable_iam_password_policy ? { update_iam_password_policy = try(aws_iam_role.update_iam_password_policy[0].arn, null) } : {},
    var.enable_iam_unused_credentials_check ? { deactivate_unused_credentials = try(aws_iam_role.deactivate_unused_credentials[0].arn, null) } : {},
    var.enable_rds_storage_encrypted ? { delete_unencrypted_rds = try(aws_iam_role.delete_unencrypted_rds[0].arn, null) } : {},
    var.enable_root_account_mfa ? { notify_root_mfa_disabled = try(aws_iam_role.notify_root_mfa_disabled[0].arn, null) } : {},
    (var.enable_s3_bucket_public_read_prohibited || var.enable_s3_bucket_public_write_prohibited) ? { remediate_s3_public_access = try(aws_iam_role.remediate_s3_public_access[0].arn, null) } : {},
    var.enable_vpc_flow_logs ? { enable_vpc_flow_logs_automation = try(aws_iam_role.enable_vpc_flow_logs_automation[0].arn, null) } : {},
    var.enable_vpc_flow_logs ? { vpc_flow_logs = try(aws_iam_role.vpc_flow_logs[0].arn, null) } : {}
  )
}

output "ssm_document_names" {
  description = "Map of SSM automation document names"
  value = merge(
    var.enable_nat_gateway_deletion ? { delete_nat_gateway = try(aws_ssm_document.delete_nat_gateway[0].name, null) } : {},
    var.enable_public_subnet_resource_deletion ? { delete_public_subnet_resource = try(aws_ssm_document.delete_public_subnet_resource[0].name, null) } : {},
    var.enable_unencrypted_volume_shutdown ? { shutdown_unencrypted_instance = try(aws_ssm_document.shutdown_unencrypted_instance[0].name, null) } : {},
    var.enable_non_vpc_lambda_deletion ? { delete_non_vpc_lambda = try(aws_ssm_document.delete_non_vpc_lambda[0].name, null) } : {},
    var.enable_s3_public_access_block ? { enable_s3_public_access_block = try(aws_ssm_document.enable_s3_public_access_block[0].name, null) } : {},
    var.enable_sg_open_port_deletion ? { delete_open_admin_db_ports = try(aws_ssm_document.delete_open_admin_db_ports[0].name, null) } : {},
    var.enable_iam_password_policy ? { update_iam_password_policy = try(aws_ssm_document.update_iam_password_policy[0].name, null) } : {},
    var.enable_iam_unused_credentials_check ? { deactivate_unused_credentials = try(aws_ssm_document.deactivate_unused_credentials[0].name, null) } : {},
    var.enable_rds_storage_encrypted ? { delete_unencrypted_rds = try(aws_ssm_document.delete_unencrypted_rds[0].name, null) } : {},
    var.enable_root_account_mfa ? { notify_root_mfa_disabled = try(aws_ssm_document.notify_root_mfa_disabled[0].name, null) } : {},
    (var.enable_s3_bucket_public_read_prohibited || var.enable_s3_bucket_public_write_prohibited) ? { remediate_s3_public_access = try(aws_ssm_document.remediate_s3_public_access[0].name, null) } : {},
    var.enable_vpc_flow_logs ? { enable_vpc_flow_logs = try(aws_ssm_document.enable_vpc_flow_logs[0].name, null) } : {}
  )
}

output "config_aggregator_arn" {
  description = "ARN of the Config aggregator (if enabled)"
  value       = var.enable_config_aggregator ? try(aws_config_configuration_aggregator.organization[0].arn, null) : null
}

output "config_aggregator_name" {
  description = "Name of the Config aggregator (if enabled)"
  value       = var.enable_config_aggregator ? var.config_aggregator_name : null
}
