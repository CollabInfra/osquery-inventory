# IAM Role for Fluent Bit instances to write to OpenSearch
resource "aws_iam_role" "fluent_bit" {
  count = var.create_fluent_bit_role ? 1 : 0
  name  = "${var.domain_name}-fluent-bit-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name    = "${var.domain_name}-fluent-bit-role"
      Purpose = "Fluent Bit OpenSearch Access"
    }
  )
}

# IAM Policy for Fluent Bit to write to OpenSearch
resource "aws_iam_role_policy" "fluent_bit_opensearch" {
  count = var.create_fluent_bit_role ? 1 : 0
  name  = "${var.domain_name}-fluent-bit-opensearch-policy"
  role  = aws_iam_role.fluent_bit[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "es:ESHttpPost",
          "es:ESHttpPut",
          "es:ESHttpGet"
        ]
        Resource = [
          "${aws_opensearch_domain.osquery.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "es:DescribeElasticsearchDomain",
          "es:DescribeElasticsearchDomainConfig",
          "es:ESHttpHead"
        ]
        Resource = aws_opensearch_domain.osquery.arn
      }
    ]
  })
}

# Instance Profile for EC2 instances running Fluent Bit
resource "aws_iam_instance_profile" "fluent_bit" {
  count = var.create_fluent_bit_role ? 1 : 0
  name  = "${var.domain_name}-fluent-bit-profile"
  role  = aws_iam_role.fluent_bit[0].name

  tags = var.tags
}

# IAM Role for OpenSearch Dashboards access (optional)
resource "aws_iam_role" "opensearch_dashboards" {
  count = var.create_dashboards_role ? 1 : 0
  name  = "${var.domain_name}-dashboards-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.dashboards_user_arns
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name    = "${var.domain_name}-dashboards-role"
      Purpose = "OpenSearch Dashboards Access"
    }
  )
}

# Policy for read-only access to OpenSearch Dashboards
resource "aws_iam_role_policy" "opensearch_dashboards_readonly" {
  count = var.create_dashboards_role ? 1 : 0
  name  = "${var.domain_name}-dashboards-readonly-policy"
  role  = aws_iam_role.opensearch_dashboards[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "es:ESHttpGet",
          "es:ESHttpHead"
        ]
        Resource = [
          "${aws_opensearch_domain.osquery.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "es:DescribeElasticsearchDomain",
          "es:DescribeElasticsearchDomainConfig"
        ]
        Resource = aws_opensearch_domain.osquery.arn
      }
    ]
  })
}
