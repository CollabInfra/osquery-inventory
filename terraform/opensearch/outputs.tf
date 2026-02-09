output "domain_id" {
  description = "Unique identifier for the OpenSearch domain"
  value       = aws_opensearch_domain.osquery.domain_id
}

output "domain_name" {
  description = "Name of the OpenSearch domain"
  value       = aws_opensearch_domain.osquery.domain_name
}

output "domain_arn" {
  description = "ARN of the OpenSearch domain"
  value       = aws_opensearch_domain.osquery.arn
}

output "endpoint" {
  description = "Domain-specific endpoint for OpenSearch API requests"
  value       = aws_opensearch_domain.osquery.endpoint
}

output "dashboard_endpoint" {
  description = "Domain-specific endpoint for OpenSearch Dashboards"
  value       = aws_opensearch_domain.osquery.dashboard_endpoint
}

output "domain_endpoint_options" {
  description = "Domain endpoint options"
  value = {
    enforce_https       = aws_opensearch_domain.osquery.domain_endpoint_options[0].enforce_https
    tls_security_policy = aws_opensearch_domain.osquery.domain_endpoint_options[0].tls_security_policy
    custom_endpoint     = try(aws_opensearch_domain.osquery.domain_endpoint_options[0].custom_endpoint, null)
  }
}

output "kms_key_id" {
  description = "KMS key ID used for encryption at rest"
  value       = aws_kms_key.opensearch.key_id
}

output "kms_key_arn" {
  description = "KMS key ARN used for encryption at rest"
  value       = aws_kms_key.opensearch.arn
}

output "kms_key_alias" {
  description = "KMS key alias"
  value       = aws_kms_alias.opensearch.name
}

output "fluent_bit_role_arn" {
  description = "IAM role ARN for Fluent Bit instances"
  value       = var.create_fluent_bit_role ? aws_iam_role.fluent_bit[0].arn : null
}

output "fluent_bit_instance_profile_name" {
  description = "Instance profile name for EC2 instances running Fluent Bit"
  value       = var.create_fluent_bit_role ? aws_iam_instance_profile.fluent_bit[0].name : null
}

output "fluent_bit_instance_profile_arn" {
  description = "Instance profile ARN for EC2 instances running Fluent Bit"
  value       = var.create_fluent_bit_role ? aws_iam_instance_profile.fluent_bit[0].arn : null
}

output "dashboards_role_arn" {
  description = "IAM role ARN for OpenSearch Dashboards access"
  value       = var.create_dashboards_role ? aws_iam_role.opensearch_dashboards[0].arn : null
}

output "security_group_id" {
  description = "Security group ID for VPC-based OpenSearch (null if not in VPC)"
  value       = var.vpc_enabled ? aws_security_group.opensearch[0].id : null
}

output "cloudwatch_log_groups" {
  description = "CloudWatch log group names"
  value = {
    index_slow_logs  = aws_cloudwatch_log_group.opensearch_index_slow_logs.name
    search_slow_logs = aws_cloudwatch_log_group.opensearch_search_slow_logs.name
    application_logs = aws_cloudwatch_log_group.opensearch_application_logs.name
    audit_logs       = aws_cloudwatch_log_group.opensearch_audit_logs.name
  }
}

output "region" {
  description = "AWS region where OpenSearch is deployed"
  value       = data.aws_region.current.name
}

output "fluent_bit_config_snippet" {
  description = "Configuration snippet for Ansible Fluent Bit templates"
  value = {
    opensearch_endpoint = aws_opensearch_domain.osquery.endpoint
    opensearch_region   = data.aws_region.current.name
    index_pattern       = "osquery-%Y.%m.%d"
  }
}

output "ansible_group_vars" {
  description = "Suggested values for Ansible group_vars/all.yaml"
  value = {
    opensearch_endpoint          = aws_opensearch_domain.osquery.endpoint
    opensearch_region            = data.aws_region.current.name
    opensearch_use_aws_auth      = true
    enable_opensearch_forwarding = true
    fluent_bit_instance_profile  = var.create_fluent_bit_role ? aws_iam_instance_profile.fluent_bit[0].name : "UPDATE_ME"
  }
}

# Security information
output "encryption_status" {
  description = "Encryption configuration status"
  value = {
    at_rest_enabled      = true
    in_transit_enabled   = true
    node_to_node_enabled = true
    kms_key_id           = aws_kms_key.opensearch.key_id
    kms_rotation_enabled = true
  }
}

output "cluster_config" {
  description = "Cluster configuration summary"
  value = {
    instance_type      = var.instance_type
    instance_count     = var.instance_count
    dedicated_master   = var.dedicated_master_enabled
    zone_awareness     = var.zone_awareness_enabled
    availability_zones = var.zone_awareness_enabled ? var.availability_zone_count : 1
    warm_storage       = var.warm_enabled
  }
}
