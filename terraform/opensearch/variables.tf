variable "domain_name" {
  description = "Name of the OpenSearch domain"
  type        = string
  default     = "osquery-logs"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,27}$", var.domain_name))
    error_message = "Domain name must start with a lowercase letter, contain only lowercase letters, numbers, and hyphens, and be between 3 and 28 characters."
  }
}

variable "opensearch_version" {
  description = "OpenSearch engine version"
  type        = string
  default     = "OpenSearch_2.11"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "production"
}

# Cluster Configuration
variable "instance_type" {
  description = "Instance type for OpenSearch data nodes"
  type        = string
  default     = "r6g.large.search"
}

variable "instance_count" {
  description = "Number of data nodes in the cluster"
  type        = number
  default     = 3

  validation {
    condition     = var.instance_count >= 2
    error_message = "Instance count must be at least 2 for high availability."
  }
}

variable "dedicated_master_enabled" {
  description = "Enable dedicated master nodes"
  type        = bool
  default     = true
}

variable "dedicated_master_type" {
  description = "Instance type for dedicated master nodes"
  type        = string
  default     = "r6g.large.search"
}

variable "dedicated_master_count" {
  description = "Number of dedicated master nodes"
  type        = number
  default     = 3

  validation {
    condition     = contains([3, 5], var.dedicated_master_count)
    error_message = "Dedicated master count must be 3 or 5."
  }
}

variable "zone_awareness_enabled" {
  description = "Enable zone awareness (multi-AZ)"
  type        = bool
  default     = true
}

variable "availability_zone_count" {
  description = "Number of availability zones"
  type        = number
  default     = 3

  validation {
    condition     = contains([2, 3], var.availability_zone_count)
    error_message = "Availability zone count must be 2 or 3."
  }
}

variable "warm_enabled" {
  description = "Enable UltraWarm storage"
  type        = bool
  default     = false
}

variable "warm_count" {
  description = "Number of warm nodes"
  type        = number
  default     = 2
}

variable "warm_type" {
  description = "Instance type for warm nodes"
  type        = string
  default     = "ultrawarm1.medium.search"
}

# EBS Configuration
variable "volume_type" {
  description = "EBS volume type (gp2, gp3, io1)"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1"], var.volume_type)
    error_message = "Volume type must be gp2, gp3, or io1."
  }
}

variable "volume_size" {
  description = "EBS volume size in GB per node"
  type        = number
  default     = 100

  validation {
    condition     = var.volume_size >= 10 && var.volume_size <= 16384
    error_message = "Volume size must be between 10 and 16384 GB."
  }
}

variable "iops" {
  description = "IOPS for gp3 or io1 volumes"
  type        = number
  default     = 3000
}

variable "throughput" {
  description = "Throughput in MB/s for gp3 volumes"
  type        = number
  default     = 125
}

# Encryption
variable "kms_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 30

  validation {
    condition     = var.kms_deletion_window >= 7 && var.kms_deletion_window <= 30
    error_message = "KMS deletion window must be between 7 and 30 days."
  }
}

variable "kms_multi_region" {
  description = "Enable multi-region KMS key"
  type        = bool
  default     = false
}

variable "tls_security_policy" {
  description = "TLS security policy"
  type        = string
  default     = "Policy-Min-TLS-1-2-2019-07"

  validation {
    condition = contains([
      "Policy-Min-TLS-1-0-2019-07",
      "Policy-Min-TLS-1-2-2019-07",
      "Policy-Min-TLS-1-2-PFS-2023-10"
    ], var.tls_security_policy)
    error_message = "Invalid TLS security policy."
  }
}

# Fine-Grained Access Control
variable "internal_user_database_enabled" {
  description = "Enable internal user database for fine-grained access control"
  type        = bool
  default     = false
}

variable "master_user_arn" {
  description = "ARN of IAM user or role for master user (used when internal_user_database_enabled = false)"
  type        = string
  default     = ""
}

variable "master_user_name" {
  description = "Master user name (used when internal_user_database_enabled = true)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "master_user_password" {
  description = "Master user password (used when internal_user_database_enabled = true)"
  type        = string
  default     = ""
  sensitive   = true

  validation {
    condition     = var.master_user_password == "" || can(regex("^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&#])[A-Za-z\\d@$!%*?&#]{8,}$", var.master_user_password))
    error_message = "Password must be at least 8 characters with uppercase, lowercase, number, and special character."
  }
}

# VPC Configuration
variable "vpc_enabled" {
  description = "Deploy OpenSearch in VPC"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID for OpenSearch deployment"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Subnet IDs for OpenSearch deployment (must match availability_zone_count)"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access OpenSearch when in VPC"
  type        = list(string)
  default     = []
}

# Access Control
variable "allowed_principals" {
  description = "IAM principals allowed to access OpenSearch"
  type        = list(string)
  default     = ["*"]
}

variable "fluent_bit_role_arns" {
  description = "IAM role ARNs for Fluent Bit instances (for KMS key access)"
  type        = list(string)
  default     = []
}

# CloudWatch Logs
variable "enable_slow_logs" {
  description = "Enable slow logs publishing to CloudWatch"
  type        = bool
  default     = true
}

variable "enable_application_logs" {
  description = "Enable application logs publishing to CloudWatch"
  type        = bool
  default     = true
}

variable "enable_audit_logs" {
  description = "Enable audit logs publishing to CloudWatch"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 90

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Invalid log retention value."
  }
}

# Snapshots
variable "snapshot_start_hour" {
  description = "Hour (UTC) when automated snapshots start"
  type        = number
  default     = 3

  validation {
    condition     = var.snapshot_start_hour >= 0 && var.snapshot_start_hour <= 23
    error_message = "Snapshot start hour must be between 0 and 23."
  }
}

# Auto-Tune
variable "auto_tune_enabled" {
  description = "Enable Auto-Tune for performance optimization"
  type        = bool
  default     = true
}

variable "auto_tune_maintenance_schedules" {
  description = "Auto-Tune maintenance schedules"
  type = list(object({
    start_at        = string
    duration_value  = number
    duration_unit   = string
    cron_expression = string
  }))
  default = [
    {
      start_at        = "2026-02-08T00:00:00Z"
      duration_value  = 2
      duration_unit   = "HOURS"
      cron_expression = "cron(0 3 ? * SUN *)"
    }
  ]
}

# Custom Endpoint
variable "custom_endpoint_enabled" {
  description = "Enable custom endpoint for the domain"
  type        = bool
  default     = false
}

variable "custom_endpoint" {
  description = "Custom endpoint for the domain"
  type        = string
  default     = ""
}

variable "custom_endpoint_certificate_arn" {
  description = "ACM certificate ARN for custom endpoint"
  type        = string
  default     = ""
}

# IAM Roles
variable "create_fluent_bit_role" {
  description = "Create IAM role for Fluent Bit instances"
  type        = bool
  default     = true
}

variable "create_dashboards_role" {
  description = "Create IAM role for OpenSearch Dashboards users"
  type        = bool
  default     = false
}

variable "dashboards_user_arns" {
  description = "IAM user/role ARNs allowed to assume dashboards role"
  type        = list(string)
  default     = []
}

variable "create_service_linked_role" {
  description = "Create service-linked role for OpenSearch (set to false if already exists)"
  type        = bool
  default     = false
}

# Tags
variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
