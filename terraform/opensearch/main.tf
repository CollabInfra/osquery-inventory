# OpenSearch Domain for OSQuery Logs
resource "aws_opensearch_domain" "osquery" {
  domain_name    = var.domain_name
  engine_version = var.opensearch_version

  cluster_config {
    instance_type            = var.instance_type
    instance_count           = var.instance_count
    dedicated_master_enabled = var.dedicated_master_enabled
    dedicated_master_type    = var.dedicated_master_enabled ? var.dedicated_master_type : null
    dedicated_master_count   = var.dedicated_master_enabled ? var.dedicated_master_count : null
    zone_awareness_enabled   = var.zone_awareness_enabled

    dynamic "zone_awareness_config" {
      for_each = var.zone_awareness_enabled ? [1] : []
      content {
        availability_zone_count = var.availability_zone_count
      }
    }

    warm_enabled = var.warm_enabled
    warm_count   = var.warm_enabled ? var.warm_count : null
    warm_type    = var.warm_enabled ? var.warm_type : null
  }

  # EBS configuration for data storage
  ebs_options {
    ebs_enabled = true
    volume_type = var.volume_type
    volume_size = var.volume_size
    iops        = contains(["gp3", "io1"], var.volume_type) ? var.iops : null
    throughput  = var.volume_type == "gp3" ? var.throughput : null
  }

  # Encryption at rest using KMS
  encrypt_at_rest {
    enabled    = true
    kms_key_id = aws_kms_key.opensearch.arn
  }

  # Encryption in transit (node-to-node and HTTPS)
  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https                   = true
    tls_security_policy             = var.tls_security_policy
    custom_endpoint_enabled         = var.custom_endpoint_enabled
    custom_endpoint                 = var.custom_endpoint_enabled ? var.custom_endpoint : null
    custom_endpoint_certificate_arn = var.custom_endpoint_enabled ? var.custom_endpoint_certificate_arn : null
  }

  # Fine-grained access control
  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = var.internal_user_database_enabled
    anonymous_auth_enabled         = false

    master_user_options {
      master_user_arn      = var.internal_user_database_enabled ? null : var.master_user_arn
      master_user_name     = var.internal_user_database_enabled ? var.master_user_name : null
      master_user_password = var.internal_user_database_enabled ? var.master_user_password : null
    }
  }

  # VPC configuration (optional but recommended for production)
  dynamic "vpc_options" {
    for_each = var.vpc_enabled ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = [aws_security_group.opensearch[0].id]
    }
  }

  # CloudWatch log publishing
  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_index_slow_logs.arn
    log_type                 = "INDEX_SLOW_LOGS"
    enabled                  = var.enable_slow_logs
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_search_slow_logs.arn
    log_type                 = "SEARCH_SLOW_LOGS"
    enabled                  = var.enable_slow_logs
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_application_logs.arn
    log_type                 = "ES_APPLICATION_LOGS"
    enabled                  = var.enable_application_logs
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_audit_logs.arn
    log_type                 = "AUDIT_LOGS"
    enabled                  = var.enable_audit_logs
  }

  # Advanced options
  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
    "override_main_response_version"         = "false"
  }

  # Automated snapshot configuration
  snapshot_options {
    automated_snapshot_start_hour = var.snapshot_start_hour
  }

  # Auto-tune recommendations
  auto_tune_options {
    desired_state       = var.auto_tune_enabled ? "ENABLED" : "DISABLED"
    rollback_on_disable = "NO_ROLLBACK"

    dynamic "maintenance_schedule" {
      for_each = var.auto_tune_enabled ? var.auto_tune_maintenance_schedules : []
      content {
        start_at = maintenance_schedule.value.start_at
        duration {
          value = maintenance_schedule.value.duration_value
          unit  = maintenance_schedule.value.duration_unit
        }
        cron_expression_for_recurrence = maintenance_schedule.value.cron_expression
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = var.domain_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Purpose     = "OSQuery Log Storage"
    }
  )

  depends_on = [
    aws_iam_service_linked_role.opensearch,
    aws_cloudwatch_log_resource_policy.opensearch
  ]
}

# OpenSearch domain access policy
resource "aws_opensearch_domain_policy" "osquery" {
  domain_name = aws_opensearch_domain.osquery.domain_name

  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.allowed_principals
        }
        Action = [
          "es:ESHttpGet",
          "es:ESHttpPut",
          "es:ESHttpPost",
          "es:ESHttpHead",
          "es:ESHttpDelete"
        ]
        Resource = "${aws_opensearch_domain.osquery.arn}/*"
      }
    ]
  })
}

# Security group for VPC-based OpenSearch
resource "aws_security_group" "opensearch" {
  count       = var.vpc_enabled ? 1 : 0
  name        = "${var.domain_name}-sg"
  description = "Security group for OpenSearch domain ${var.domain_name}"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from allowed CIDR blocks"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.domain_name}-sg"
    }
  )
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "opensearch_index_slow_logs" {
  name              = "/aws/opensearch/${var.domain_name}/index-slow-logs"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.opensearch.arn

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "opensearch_search_slow_logs" {
  name              = "/aws/opensearch/${var.domain_name}/search-slow-logs"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.opensearch.arn

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "opensearch_application_logs" {
  name              = "/aws/opensearch/${var.domain_name}/application-logs"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.opensearch.arn

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "opensearch_audit_logs" {
  name              = "/aws/opensearch/${var.domain_name}/audit-logs"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.opensearch.arn

  tags = var.tags
}

# CloudWatch Log Resource Policy for OpenSearch
resource "aws_cloudwatch_log_resource_policy" "opensearch" {
  policy_name = "${var.domain_name}-logs-policy"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "es.amazonaws.com"
        }
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.opensearch_index_slow_logs.arn}:*",
          "${aws_cloudwatch_log_group.opensearch_search_slow_logs.arn}:*",
          "${aws_cloudwatch_log_group.opensearch_application_logs.arn}:*",
          "${aws_cloudwatch_log_group.opensearch_audit_logs.arn}:*"
        ]
      }
    ]
  })
}

# Service-linked role for OpenSearch
resource "aws_iam_service_linked_role" "opensearch" {
  count            = var.create_service_linked_role ? 1 : 0
  aws_service_name = "opensearchservice.amazonaws.com"
  description      = "Service-linked role for Amazon OpenSearch Service"
}
