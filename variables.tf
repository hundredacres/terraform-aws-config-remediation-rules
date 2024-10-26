variable "name" {
  description = "Moniker to apply to all resources in the module"
  type        = string
}

variable "tags" {
  default     = {}
  description = "User-Defined tags"
  type        = map(string)
}

variable "enable_sns_notifications" {
  description = "Enable SNS notifications for remediation actions"
  type        = bool
  default     = false
}

variable "enable_nat_gateway_deletion" {
  description = "Enable the rule to automatically delete NAT Gateways when created"
  type        = bool
  default     = false
}

variable "enable_public_subnet_resource_deletion" {
  description = "Enable the rule to automatically delete resources (except load balancers) created in public subnets"
  type        = bool
  default     = false
}

variable "enable_unencrypted_volume_shutdown" {
  description = "Enable the rule to automatically shut down EC2 instances created with unencrypted root volumes"
  type        = bool
  default     = false
}

variable "enable_non_vpc_lambda_deletion" {
  description = "Enable the rule to automatically delete Lambda functions not associated with a VPC"
  type        = bool
  default     = false
}

variable "enable_s3_public_access_block" {
  description = "Enable the rule to automatically enable public access block for S3 buckets created without it"
  type        = bool
  default     = false
}

variable "enable_sg_open_port_deletion" {
  description = "Enable the rule to automatically delete security group rules allowing 0.0.0.0/0 access to admin or database ports"
  type        = bool
  default     = false
}
