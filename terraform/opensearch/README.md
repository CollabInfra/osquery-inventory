# Terraform OpenSearch Infrastructure

This Terraform configuration provisions an AWS OpenSearch cluster for storing OSQuery logs with enterprise-grade security features.

## 🔒 Security Features

✅ **Encryption at Rest** - All data encrypted using AWS KMS with automatic key rotation  
✅ **Encryption in Transit** - TLS 1.2+ for all communications (node-to-node and HTTPS)  
✅ **Fine-Grained Access Control** - IAM-based or internal user authentication  
✅ **Audit Logging** - Complete audit trail to CloudWatch Logs  
✅ **VPC Deployment** - Optional VPC isolation for network-level security  
✅ **KMS Key Management** - Dedicated KMS key with granular policies

## 📋 Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with appropriate credentials
- AWS account with permissions to create:
  - OpenSearch domains
  - KMS keys
  - IAM roles and policies
  - CloudWatch log groups
  - VPC resources (if using VPC mode)

## 🚀 Quick Start

### 1. Initialize Terraform

```bash
cd terraform/opensearch
terraform init
```

### 2. Configure Variables

Copy the example and customize:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your settings:

```hcl
aws_region  = "us-east-1"
domain_name = "osquery-logs-prod"
environment = "production"

# Use IAM authentication (recommended)
internal_user_database_enabled = false
master_user_arn                = "arn:aws:iam::YOUR_ACCOUNT:role/OpenSearchAdmin"

# Or use internal user database
# internal_user_database_enabled = true
# master_user_name               = "admin"
# master_user_password           = "SecurePassword123!"
```

### 3. Review the Plan

```bash
terraform plan
```

### 4. Deploy

```bash
terraform apply
```

**Deployment time**: ~15-20 minutes

### 5. Get Outputs

```bash
terraform output
```

Key outputs:
- `endpoint` - OpenSearch API endpoint
- `dashboard_endpoint` - OpenSearch Dashboards URL
- `fluent_bit_role_arn` - IAM role for Fluent Bit
- `kms_key_id` - KMS key for encryption

## 📐 Architecture

### Public Access Mode (Default)

```
┌─────────────────┐
│  Fluent Bit     │
│  (EC2/On-prem)  │
└────────┬────────┘
         │ HTTPS + AWS SigV4
         ▼
┌─────────────────────────────────┐
│  AWS OpenSearch Domain          │
│  ┌──────────────────────────┐   │
│  │ Data Nodes (3x r6g.large)│   │
│  └──────────────────────────┘   │
│  ┌──────────────────────────┐   │
│  │ Master Nodes (3x)        │   │
│  └──────────────────────────┘   │
│  ┌──────────────────────────┐   │
│  │ KMS Encrypted Storage    │   │
│  └──────────────────────────┘   │
└─────────────────────────────────┘
```

### VPC Mode (Production Recommended)

```
┌────────────────────────────────────────┐
│  VPC (10.0.0.0/16)                     │
│  ┌──────────────────────────────────┐  │
│  │  Private Subnet 1 (AZ-a)         │  │
│  │  ┌────────────────────────────┐  │  │
│  │  │  OpenSearch Node           │  │  │
│  │  └────────────────────────────┘  │  │
│  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │  Private Subnet 2 (AZ-b)         │  │
│  │  ┌────────────────────────────┐  │  │
│  │  │  OpenSearch Node           │  │  │
│  │  └────────────────────────────┘  │  │
│  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │  Private Subnet 3 (AZ-c)         │  │
│  │  ┌────────────────────────────┐  │  │
│  │  │  OpenSearch Node           │  │  │
│  │  └────────────────────────────┘  │  │
│  └──────────────────────────────────┘  │
└────────────────────────────────────────┘
```

## 🔧 Configuration Options

### Sizing Guide

| Environment | Instance Type | Node Count | Storage per Node | Total Storage | Estimated Cost/Month |
|-------------|---------------|------------|------------------|---------------|---------------------|
| Dev/Test    | t3.small      | 2          | 50 GB            | 100 GB        | ~$150               |
| Staging     | r6g.large     | 2          | 100 GB           | 200 GB        | ~$400               |
| Production  | r6g.large     | 3          | 100 GB           | 300 GB        | ~$600               |
| Enterprise  | r6g.xlarge    | 3-6        | 200-500 GB       | 600-3000 GB   | ~$1,200-3,000       |

### Authentication Methods

#### Option 1: IAM Authentication (Recommended)

```hcl
internal_user_database_enabled = false
master_user_arn                = "arn:aws:iam::123456789012:role/OpenSearchAdmin"
allowed_principals = [
  "arn:aws:iam::123456789012:role/FluentBitRole"
]
```

**Pros**: No password management, AWS-native, audit trail  
**Cons**: Requires AWS credentials setup

#### Option 2: Internal User Database

```hcl
internal_user_database_enabled = true
master_user_name               = "admin"
master_user_password           = "SecurePassword123!"
```

**Pros**: Simple setup, works without AWS credentials  
**Cons**: Password management required

⚠️ **Security Warning**: Never commit passwords to version control. Use:
- AWS Secrets Manager
- HashiCorp Vault
- Environment variables
- Terraform Cloud/Enterprise workspace variables

### VPC vs Public Access

#### VPC Mode (Recommended for Production)

```hcl
vpc_enabled         = true
vpc_id              = "vpc-0123456789abcdef0"
subnet_ids          = ["subnet-abc", "subnet-def", "subnet-ghi"]
allowed_cidr_blocks = ["10.0.0.0/16"]
```

**Benefits**:
- Network isolation
- No public internet exposure
- VPC Flow Logs integration
- PrivateLink support

**Requirements**:
- Existing VPC with subnets in multiple AZs
- VPN or Direct Connect for remote access
- NAT Gateway for updates (or VPC endpoints)

#### Public Access Mode

```hcl
vpc_enabled = false
allowed_principals = ["arn:aws:iam::123456789012:role/FluentBit"]
```

**Benefits**:
- Simpler setup
- Access from anywhere with IAM credentials
- No VPC management

**Considerations**:
- Public endpoint (protected by IAM/auth)
- Requires proper IAM policies
- Rate limiting recommended

## 🔗 Integration with Ansible

After deployment, update your Ansible inventory:

```bash
# Get Terraform outputs
terraform output -json > outputs.json

# Update Ansible group_vars
cat >> ../../ansible/group_vars/all.yaml <<EOF
# Generated from Terraform
opensearch_endpoint: $(terraform output -raw endpoint)
opensearch_region: $(terraform output -raw region)
opensearch_use_aws_auth: true
enable_opensearch_forwarding: true
EOF
```

Or use the provided output:

```bash
terraform output ansible_group_vars
```

### Configure Fluent Bit IAM Role

If your OSQuery hosts are EC2 instances:

```bash
# Get the instance profile name
INSTANCE_PROFILE=$(terraform output -raw fluent_bit_instance_profile_name)

# Attach to EC2 instances via AWS CLI
aws ec2 associate-iam-instance-profile \
  --instance-id i-1234567890abcdef0 \
  --iam-instance-profile Name=$INSTANCE_PROFILE
```

For on-premises hosts, use IAM access keys (less secure) or AWS IAM Roles Anywhere.

## 📊 Monitoring

### CloudWatch Logs

Four log groups are automatically created:

- `/aws/opensearch/DOMAIN_NAME/index-slow-logs`
- `/aws/opensearch/DOMAIN_NAME/search-slow-logs`
- `/aws/opensearch/DOMAIN_NAME/application-logs`
- `/aws/opensearch/DOMAIN_NAME/audit-logs`

View logs:

```bash
DOMAIN_NAME=$(terraform output -raw domain_name)
aws logs tail /aws/opensearch/$DOMAIN_NAME/application-logs --follow
```

### CloudWatch Metrics

Key metrics to monitor:

- `ClusterStatus.green` - Should be 1
- `FreeStorageSpace` - Alert if < 20%
- `CPUUtilization` - Alert if > 80%
- `JVMMemoryPressure` - Alert if > 85%
- `MasterCPUUtilization` - Monitor master node health

Create CloudWatch Dashboard:

```bash
# Example CloudWatch Dashboard creation
aws cloudwatch put-dashboard --dashboard-name osquery-opensearch \
  --dashboard-body file://cloudwatch-dashboard.json
```

### OpenSearch Dashboards

Access the Dashboards:

```bash
DASHBOARD_URL=$(terraform output -raw dashboard_endpoint)
echo "https://$DASHBOARD_URL/_dashboards"
```

Sign in with:
- **IAM auth**: Use AWS console federation or temporary credentials
- **Internal auth**: Use master_user_name and master_user_password

## 🛠️ Operations

### Scaling the Cluster

#### Scale Data Nodes

```hcl
# terraform.tfvars
instance_count = 6  # Increase from 3 to 6
```

```bash
terraform apply
```

**Blue-green deployment**: New nodes added first, then old ones removed. Zero downtime.

#### Scale Storage

```hcl
# terraform.tfvars
volume_size = 200  # Increase from 100 to 200 GB
```

⚠️ **Note**: Storage can only be increased, not decreased.

#### Vertical Scaling

```hcl
# terraform.tfvars
instance_type = "r6g.xlarge.search"  # Upgrade from r6g.large
```

⚠️ **Requires**: Blue-green deployment (brief downtime possible).

### Backup and Restore

#### Automated Snapshots

Configured automatically:

```hcl
snapshot_start_hour = 3  # Daily at 3 AM UTC
```

Snapshots retained for 14 days (AWS managed).

#### Manual Snapshots (S3)

1. Create S3 bucket and IAM role
2. Register snapshot repository:

```bash
curl -XPUT "https://OPENSEARCH_ENDPOINT/_snapshot/osquery-backups" \
  -H 'Content-Type: application/json' \
  -d '{
    "type": "s3",
    "settings": {
      "bucket": "my-opensearch-snapshots",
      "region": "us-east-1",
      "role_arn": "arn:aws:iam::123456789012:role/OpenSearchSnapshotRole"
    }
  }'
```

3. Create snapshot:

```bash
curl -XPUT "https://OPENSEARCH_ENDPOINT/_snapshot/osquery-backups/snapshot_1"
```

### Disaster Recovery

#### Restore from Snapshot

```bash
# List snapshots
curl -XGET "https://OPENSEARCH_ENDPOINT/_snapshot/osquery-backups/_all"

# Restore
curl -XPOST "https://OPENSEARCH_ENDPOINT/_snapshot/osquery-backups/snapshot_1/_restore"
```

#### Multi-Region Replication

Enable multi-region KMS key:

```hcl
kms_multi_region = true
```

Deploy in secondary region with cross-region replication (requires OpenSearch 2.x+).

## 🔐 Security Best Practices

### 1. Use VPC Deployment

```hcl
vpc_enabled = true
```

### 2. Enable All Audit Logs

```hcl
enable_audit_logs = true
```

### 3. Restrict IAM Principals

```hcl
allowed_principals = [
  "arn:aws:iam::123456789012:role/FluentBitRole"  # Only specific roles
]
```

### 4. Use Strong TLS Policy

```hcl
tls_security_policy = "Policy-Min-TLS-1-2-PFS-2023-10"  # Latest policy
```

### 5. Enable KMS Key Rotation

```hcl
# Automatically enabled in kms.tf
enable_key_rotation = true
```

### 6. Implement Network Controls

For VPC deployments:

```hcl
allowed_cidr_blocks = ["10.0.0.0/8"]  # Only internal network
```

### 7. Use Secrets Manager

```bash
# Store admin password in Secrets Manager
aws secretsmanager create-secret \
  --name opensearch-admin-password \
  --secret-string "YourSecurePassword123!"

# Reference in Terraform
data "aws_secretsmanager_secret_version" "admin_password" {
  secret_id = "opensearch-admin-password"
}
```

## 💰 Cost Optimization

### 1. Use Graviton Instances

```hcl
instance_type = "r6g.large.search"  # 20% cheaper than r5.large
```

### 2. Enable UltraWarm for Old Data

```hcl
warm_enabled = true
warm_count   = 2
warm_type    = "ultrawarm1.medium.search"
```

UltraWarm costs ~$0.024/GB/month vs ~$0.135/GB/month for hot storage.

### 3. Use gp3 Volumes

```hcl
volume_type = "gp3"  # 20% cheaper than gp2
```

### 4. Right-Size Instance Count

Development: 2 nodes  
Production: 3+ nodes

### 5. Set Appropriate Retention

```hcl
log_retention_days = 30  # vs 90 for non-critical logs
```

## 🧪 Testing

### Validate Configuration

```bash
terraform validate
terraform fmt -check
```

### Test Connectivity

```bash
ENDPOINT=$(terraform output -raw endpoint)
curl -XGET "https://$ENDPOINT" --aws-sigv4 "aws:amz:us-east-1:es"
```

### Load Test Data

```bash
# Send sample document
curl -XPOST "https://$ENDPOINT/osquery-test/_doc" \
  --aws-sigv4 "aws:amz:us-east-1:es" \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "system_info",
    "action": "added",
    "columns": {
      "hostname": "test-host",
      "uuid": "12345"
    }
  }'
```

## 🔄 Updates and Maintenance

### Update OpenSearch Version

```hcl
opensearch_version = "OpenSearch_2.13"  # Update to newer version
```

```bash
terraform plan  # Review upgrade impact
terraform apply
```

⚠️ **Note**: In-place upgrade supported for minor versions. Major versions may require snapshots.

### Update Terraform Modules

```bash
terraform init -upgrade
```

## 🐛 Troubleshooting

### Cluster Status Red

```bash
# Check cluster health
curl -XGET "https://ENDPOINT/_cluster/health?pretty"

# Check for unassigned shards
curl -XGET "https://ENDPOINT/_cat/shards?v&h=index,shard,prirep,state,unassigned.reason"
```

**Common causes**:
- Insufficient disk space
- Node failure
- Incorrect replica settings

### High Memory Pressure

```bash
# Check heap usage
curl -XGET "https://ENDPOINT/_nodes/stats?pretty" | grep -A 3 jvm
```

**Solutions**:
- Reduce field count
- Use doc_values
- Scale vertically (larger instance type)

### Connection Timeouts

**IAM auth**: Verify IAM role has permissions:

```bash
aws opensearch describe-domain --domain-name $(terraform output -raw domain_name)
```

**VPC**: Check security group rules and network ACLs.

## 📚 Additional Resources

- [AWS OpenSearch Documentation](https://docs.aws.amazon.com/opensearch-service/)
- [OpenSearch Documentation](https://opensearch.org/docs/latest/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [OSQuery OpenSearch Integration](../../docs/OPENSEARCH.md)

## 🤝 Support

For issues related to:
- AWS OpenSearch: AWS Support
- Terraform: HashiCorp Support
- This configuration: Create an issue in the project repository

---

**Last Updated**: February 7, 2026  
**Terraform Version**: >= 1.5.0  
**AWS Provider Version**: ~> 5.0
