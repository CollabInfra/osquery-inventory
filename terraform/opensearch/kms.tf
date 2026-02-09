# KMS Key for OpenSearch encryption at rest
resource "aws_kms_key" "opensearch" {
  description             = "KMS key for ${var.domain_name} OpenSearch domain encryption"
  deletion_window_in_days = var.kms_deletion_window
  enable_key_rotation     = true
  multi_region            = var.kms_multi_region

  tags = merge(
    var.tags,
    {
      Name    = "${var.domain_name}-kms-key"
      Purpose = "OpenSearch Encryption"
    }
  )

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow OpenSearch to use the key"
        Effect = "Allow"
        Principal = {
          Service = "es.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "es.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      },
      {
        Sid    = "Allow CloudWatch Logs to use the key"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/opensearch/${var.domain_name}/*"
          }
        }
      },
      {
        Sid    = "Allow Fluent Bit instances to use the key"
        Effect = "Allow"
        Principal = {
          AWS = var.fluent_bit_role_arns
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

# KMS Key Alias
resource "aws_kms_alias" "opensearch" {
  name          = "alias/${var.domain_name}-opensearch"
  target_key_id = aws_kms_key.opensearch.key_id
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
