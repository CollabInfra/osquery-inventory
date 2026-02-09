# Guide de Déploiement OpenSearch avec Terraform

Ce guide vous accompagne dans le déploiement d'un cluster AWS OpenSearch sécurisé pour vos logs OSQuery.

## 📋 Prérequis

### 1. Outils Requis

```bash
# Vérifier Terraform
terraform version  # >= 1.5.0 requis

# Vérifier AWS CLI
aws --version      # >= 2.0 recommandé

# Vérifier les credentials AWS
aws sts get-caller-identity
```

### 2. Permissions IAM Requises

Votre utilisateur/role AWS doit avoir les permissions pour créer :

- ✅ OpenSearch domains (`es:*`)
- ✅ KMS keys (`kms:*`)
- ✅ IAM roles et policies (`iam:CreateRole`, `iam:PutRolePolicy`, etc.)
- ✅ CloudWatch log groups (`logs:CreateLogGroup`, etc.)
- ✅ VPC resources (si mode VPC activé)

**Policy managed recommandée** : `AdministratorAccess` (dev/test) ou créez une policy custom.

### 3. Compte AWS

- Compte AWS avec billing activé
- Quota suffisant pour OpenSearch (vérifier Service Quotas)
- Budget défini (estimez ~$600/mois pour production)

## 🚀 Déploiement Étape par Étape

### Étape 1 : Configuration Initiale

```bash
# Naviguer vers le répertoire Terraform
cd terraform/opensearch

# Initialiser Terraform
terraform init
```

**Sortie attendue** :
```
Terraform has been successfully initialized!
```

### Étape 2 : Configurer les Variables

```bash
# Copier le fichier exemple
cp terraform.tfvars.example terraform.tfvars

# Éditer avec vos valeurs
nano terraform.tfvars  # ou vim, code, etc.
```

#### Configuration Minimale (Dev/Test)

```hcl
# terraform.tfvars
aws_region  = "us-east-1"
environment = "development"
domain_name = "osquery-logs-dev"

# Cluster small pour dev
instance_type              = "t3.small.search"
instance_count             = 2
dedicated_master_enabled   = false
zone_awareness_enabled     = false

# Storage minimal
volume_size = 50

# Auth simple
internal_user_database_enabled = true
master_user_name               = "admin"
master_user_password           = "DevPassword123!"  # Changer!

# Pas de VPC
vpc_enabled = false

# IAM role Fluent Bit
create_fluent_bit_role = true

tags = {
  Environment = "Development"
  CostCenter  = "Engineering"
}
```

**Coût estimé** : ~$150/mois

#### Configuration Production (Recommandée)

```hcl
# terraform.tfvars
aws_region  = "us-east-1"
environment = "production"
domain_name = "osquery-logs-prod"

# Cluster haute disponibilité
instance_type              = "r6g.large.search"
instance_count             = 3
dedicated_master_enabled   = true
dedicated_master_type      = "r6g.large.search"
dedicated_master_count     = 3
zone_awareness_enabled     = true
availability_zone_count    = 3

# Storage production
volume_type = "gp3"
volume_size = 200
iops        = 3000
throughput  = 125

# Auth IAM (sécurisé)
internal_user_database_enabled = false
master_user_arn                = "arn:aws:iam::YOUR_ACCOUNT_ID:role/OpenSearchAdmin"

# VPC (recommandé)
vpc_enabled         = true
vpc_id              = "vpc-0123456789abcdef0"
subnet_ids          = [
  "subnet-0a1b2c3d4e5f6g7h8",  # us-east-1a
  "subnet-1a2b3c4d5e6f7g8h9",  # us-east-1b
  "subnet-2a3b4c5d6e7f8g9h0"   # us-east-1c
]
allowed_cidr_blocks = ["10.0.0.0/8"]

# Principals autorisés (ajustez selon vos ARNs)
allowed_principals = [
  "arn:aws:iam::YOUR_ACCOUNT_ID:role/FluentBitRole"
]

# Fluent Bit
create_fluent_bit_role = true
fluent_bit_role_arns   = [
  "arn:aws:iam::YOUR_ACCOUNT_ID:role/EC2-Instance-Role"
]

# Logs
enable_slow_logs        = true
enable_application_logs = true
enable_audit_logs       = true
log_retention_days      = 90

# Auto-tune
auto_tune_enabled = true

tags = {
  Environment = "Production"
  CostCenter  = "Security"
  Compliance  = "SOC2"
  Owner       = "security-team@example.com"
}
```

**Coût estimé** : ~$600-800/mois

### Étape 3 : Obtenir les ARNs Nécessaires

#### ARN de votre compte

```bash
aws sts get-caller-identity --query Account --output text
# Résultat : 123456789012
```

#### Créer le role OpenSearch Admin (pour IAM auth)

```bash
# Créer le role
aws iam create-role \
  --role-name OpenSearchAdminRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:root"
      },
      "Action": "sts:AssumeRole"
    }]
  }'

# Obtenir l'ARN
aws iam get-role --role-name OpenSearchAdminRole --query 'Role.Arn' --output text
```

Utilisez cet ARN dans `master_user_arn`.

#### VPC et Subnets (si mode VPC)

```bash
# Lister les VPCs
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,CidrBlock,Tags[?Key==`Name`].Value|[0]]' --output table

# Lister les subnets dans un VPC
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=vpc-YOUR_VPC_ID" \
  --query 'Subnets[*].[SubnetId,AvailabilityZone,CidrBlock]' \
  --output table
```

Choisissez **3 subnets dans différentes AZs**.

### Étape 4 : Planifier le Déploiement

```bash
# Créer le plan d'exécution
terraform plan -out=tfplan

# Examiner le plan
terraform show tfplan
```

**Vérifications** :
- ✅ Nombre de ressources : ~15-20
- ✅ OpenSearch domain avec encryption
- ✅ KMS key avec rotation
- ✅ CloudWatch log groups (4)
- ✅ IAM roles si activés
- ✅ Security group si VPC

### Étape 5 : Déployer

```bash
# Appliquer la configuration
terraform apply tfplan

# Ou directement (demande confirmation)
terraform apply
```

**Durée** : 15-20 minutes

**Sortie attendue** :
```
Apply complete! Resources: 18 added, 0 changed, 0 destroyed.

Outputs:

endpoint = "vpc-osquery-logs-prod-abc123.us-east-1.es.amazonaws.com"
dashboard_endpoint = "vpc-osquery-logs-prod-abc123.us-east-1.es.amazonaws.com/_dashboards"
fluent_bit_role_arn = "arn:aws:iam::123456789012:role/osquery-logs-prod-fluent-bit-role"
kms_key_id = "12345678-1234-1234-1234-123456789012"
...
```

### Étape 6 : Sauvegarder les Outputs

```bash
# Exporter tous les outputs en JSON
terraform output -json > opensearch-outputs.json

# Outputs spécifiques
terraform output endpoint
terraform output fluent_bit_role_arn
terraform output kms_key_id
```

### Étape 7 : Vérifier le Déploiement

#### Test de connectivité

```bash
ENDPOINT=$(terraform output -raw endpoint)

# Test avec IAM auth
curl -X GET "https://$ENDPOINT" \
  --aws-sigv4 "aws:amz:us-east-1:es" \
  --user "$AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY"

# Ou avec AWS CLI v4 signing
aws opensearch describe-domain \
  --domain-name $(terraform output -raw domain_name)
```

**Réponse attendue** :
```json
{
  "name": "osquery-logs-prod",
  "cluster_name": "123456789012:osquery-logs-prod",
  "version": {
    "number": "7.10.2",
    "distribution": "opensearch"
  }
}
```

#### Vérifier la santé du cluster

```bash
# Via API
curl -X GET "https://$ENDPOINT/_cluster/health?pretty" \
  --aws-sigv4 "aws:amz:us-east-1:es"

# Via AWS CLI
aws opensearch describe-domain \
  --domain-name $(terraform output -raw domain_name) \
  --query 'DomainStatus.ClusterConfig' \
  --output table
```

**Status attendu** : `"status": "green"`

#### Accéder aux Dashboards

```bash
DASHBOARD_URL=$(terraform output -raw dashboard_endpoint)
echo "https://$DASHBOARD_URL"
```

Ouvrez dans votre navigateur :
- **IAM auth** : Utilisez AWS console federation
- **Internal auth** : Utilisez username/password

## 🔗 Intégration avec Ansible

### Méthode Automatique

```bash
# Générer les variables Ansible
terraform output ansible_group_vars

# Ajouter au fichier Ansible
terraform output ansible_group_vars | yq -P >> ../../ansible/group_vars/all.yaml
```

### Méthode Manuelle

Éditez `ansible/group_vars/all.yaml` :

```yaml
# OpenSearch Configuration (from Terraform)
opensearch_endpoint: "vpc-osquery-logs-prod-abc123.us-east-1.es.amazonaws.com"
opensearch_region: "us-east-1"
opensearch_use_aws_auth: true
enable_opensearch_forwarding: true

# Debug (optionnel)
opensearch_debug_mode: false
```

### Attacher le Role IAM aux Instances EC2

```bash
# Obtenir le nom du profile
PROFILE_NAME=$(terraform output -raw fluent_bit_instance_profile_name)

# Attacher aux instances EC2 existantes
aws ec2 associate-iam-instance-profile \
  --instance-id i-0123456789abcdef0 \
  --iam-instance-profile Name=$PROFILE_NAME

# Ou lors du lancement d'instances
aws ec2 run-instances \
  --image-id ami-12345678 \
  --instance-type t3.medium \
  --iam-instance-profile Name=$PROFILE_NAME \
  ...
```

### Tester Fluent Bit

```bash
# Déployer Fluent Bit via Ansible
cd ../../ansible
ansible-playbook -i inventory.ini playbook-opensearch.yaml \
  --limit "test-host" \
  --tags "fluent-bit"

# Vérifier les logs
ssh test-host
sudo journalctl -u fluent-bit -f
```

## 🎯 Scénarios de Déploiement

### Scénario 1 : Dev/Test Simple (Non-VPC)

**Cas d'usage** : Tests locaux, POC, développement

```hcl
# terraform.tfvars
domain_name                    = "osquery-dev"
instance_type                  = "t3.small.search"
instance_count                 = 2
dedicated_master_enabled       = false
zone_awareness_enabled         = false
vpc_enabled                    = false
internal_user_database_enabled = true
master_user_name               = "admin"
master_user_password           = "TempPassword123!"
```

**Budget** : ~$150/mois  
**Déploiement** : 10 minutes  
**Sécurité** : ⚠️ Endpoint public (protégé par auth)

### Scénario 2 : Staging (VPC, Petite Taille)

**Cas d'usage** : Tests pré-production, QA

```hcl
domain_name                    = "osquery-staging"
instance_type                  = "r6g.large.search"
instance_count                 = 2
dedicated_master_enabled       = false
zone_awareness_enabled         = true
availability_zone_count        = 2
vpc_enabled                    = true
internal_user_database_enabled = false
master_user_arn                = "arn:aws:iam::...:role/OpenSearchAdmin"
```

**Budget** : ~$400/mois  
**Déploiement** : 15 minutes  
**Sécurité** : ✅ VPC isolé

### Scénario 3 : Production (HA, Multi-AZ, VPC)

**Cas d'usage** : Production avec SLA

```hcl
domain_name                  = "osquery-prod"
instance_type                = "r6g.large.search"
instance_count               = 3
dedicated_master_enabled     = true
dedicated_master_count       = 3
zone_awareness_enabled       = true
availability_zone_count      = 3
vpc_enabled                  = true
enable_audit_logs            = true
auto_tune_enabled            = true
```

**Budget** : ~$600-800/mois  
**Déploiement** : 20 minutes  
**Sécurité** : ✅ Production-grade  
**SLA** : 99.9% (multi-AZ)

### Scénario 4 : Enterprise (+ UltraWarm)

**Cas d'usage** : Rétention longue durée (> 30 jours)

```hcl
# Configuration production +
warm_enabled = true
warm_count   = 2
warm_type    = "ultrawarm1.medium.search"
volume_size  = 500  # Hot storage
```

**Budget** : ~$1,200-1,500/mois  
**Rétention** : Hot (30j) + Warm (90j+)  
**Économies** : ~50% sur stockage ancien

## 🛡️ Sécurisation Post-Déploiement

### 1. Configurer les Rôles Fine-Grained Access Control

Si vous utilisez `internal_user_database_enabled = true` :

```bash
# Accéder aux Dashboards
DASHBOARD_URL=$(terraform output -raw dashboard_endpoint)

# Se connecter avec master_user_name/password
# Aller à : Security > Roles > Create role
```

**Rôles recommandés** :
- `osquery_write` : Permissions PUT/POST sur index `osquery-*`
- `osquery_read` : Permissions GET sur index `osquery-*`
- `analyst` : Read-only sur dashboards

### 2. Créer des Index Templates

```bash
# Template pour indices OSQuery
curl -X PUT "https://$ENDPOINT/_index_template/osquery-template" \
  --aws-sigv4 "aws:amz:us-east-1:es" \
  -H 'Content-Type: application/json' \
  -d '{
    "index_patterns": ["osquery-*"],
    "template": {
      "settings": {
        "number_of_shards": 3,
        "number_of_replicas": 2,
        "refresh_interval": "30s"
      },
      "mappings": {
        "properties": {
          "@timestamp": { "type": "date" },
          "name": { "type": "keyword" },
          "hostname": { "type": "keyword" },
          "action": { "type": "keyword" }
        }
      }
    }
  }'
```

### 3. Configurer Index Lifecycle Management (ILM)

```bash
# Politique de rétention
curl -X PUT "https://$ENDPOINT/_plugins/_ism/policies/osquery-ilm" \
  --aws-sigv4 "aws:amz:us-east-1:es" \
  -H 'Content-Type: application/json' \
  -d '{
    "policy": {
      "description": "OSQuery logs lifecycle",
      "default_state": "hot",
      "states": [
        {
          "name": "hot",
          "transitions": [
            {
              "state_name": "warm",
              "conditions": {
                "min_index_age": "7d"
              }
            }
          ]
        },
        {
          "name": "warm",
          "transitions": [
            {
              "state_name": "delete",
              "conditions": {
                "min_index_age": "90d"
              }
            }
          ]
        },
        {
          "name": "delete",
          "actions": [
            { "delete": {} }
          ]
        }
      ]
    }
  }'
```

### 4. Activer les Alertes CloudWatch

```bash
# Alerte sur cluster health
aws cloudwatch put-metric-alarm \
  --alarm-name osquery-cluster-red \
  --alarm-description "OpenSearch cluster status is RED" \
  --metric-name "ClusterStatus.red" \
  --namespace "AWS/ES" \
  --statistic Maximum \
  --period 300 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --evaluation-periods 1 \
  --dimensions Name=DomainName,Value=$(terraform output -raw domain_name) \
  --alarm-actions arn:aws:sns:us-east-1:123456789012:alerts
```

## 📊 Monitoring et Validation

### Vérifier les Métriques CloudWatch

```bash
# CPU utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/ES \
  --metric-name CPUUtilization \
  --dimensions Name=DomainName,Value=$(terraform output -raw domain_name) \
  --statistics Average \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300

# Free storage space
aws cloudwatch get-metric-statistics \
  --namespace AWS/ES \
  --metric-name FreeStorageSpace \
  --dimensions Name=DomainName,Value=$(terraform output -raw domain_name) \
  --statistics Average \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300
```

### Consulter les Index

```bash
# Lister les indices
curl -X GET "https://$ENDPOINT/_cat/indices?v" \
  --aws-sigv4 "aws:amz:us-east-1:es"

# Compter les documents
curl -X GET "https://$ENDPOINT/osquery-*/_count" \
  --aws-sigv4 "aws:amz:us-east-1:es"
```

### Tester une Requête

```bash
# Rechercher les dernières entrées
curl -X GET "https://$ENDPOINT/osquery-*/_search?pretty" \
  --aws-sigv4 "aws:amz:us-east-1:es" \
  -H 'Content-Type: application/json' \
  -d '{
    "size": 5,
    "sort": [{ "@timestamp": "desc" }],
    "query": { "match_all": {} }
  }'
```

## 🔄 Mises à Jour

### Mettre à Jour la Configuration

```bash
# Modifier terraform.tfvars
vim terraform.tfvars

# Planifier
terraform plan

# Appliquer
terraform apply
```

### Mettre à Jour la Version OpenSearch

```hcl
# terraform.tfvars
opensearch_version = "OpenSearch_2.13"  # Nouvelle version
```

```bash
terraform apply
```

⚠️ **Attention** : Les upgrades majeures peuvent nécessiter un snapshot.

## 🗑️ Destruction

### Avant de Détruire

```bash
# 1. Créer un snapshot final
curl -X PUT "https://$ENDPOINT/_snapshot/final-backup/$(date +%Y%m%d)" \
  --aws-sigv4 "aws:amz:us-east-1:es"

# 2. Exporter les dashboards
# Via UI: Stack Management > Saved Objects > Export

# 3. Sauvegarder la configuration
cp terraform.tfvars terraform.tfvars.backup
terraform output -json > outputs-backup.json
```

### Détruire les Ressources

```bash
# Plan de destruction
terraform plan -destroy

# Détruire
terraform destroy
```

⚠️ **Avertissement** : Cette action est **irréversible**. Toutes les données seront perdues.

## ❓ Dépannage

### Erreur : "Service-linked role already exists"

```bash
# Mettre à jour terraform.tfvars
create_service_linked_role = false

# Réappliquer
terraform apply
```

### Erreur : "Insufficient permissions"

Vérifiez les permissions IAM :

```bash
aws iam get-user-policy --user-name YOUR_USER --policy-name YOUR_POLICY
```

Ajoutez les permissions manquantes.

### OpenSearch ne démarre pas (Status Yellow/Red)

```bash
# Vérifier les logs CloudWatch
aws logs tail /aws/opensearch/$(terraform output -raw domain_name)/application-logs

# Vérifier la configuration
aws opensearch describe-domain --domain-name $(terraform output -raw domain_name)
```

### Connexion refusée (VPC mode)

Vérifiez :
1. Security group autorise le port 443 depuis votre CIDR
2. Vous êtes dans le bon VPC/subnet
3. Route tables configurées correctement

## 📞 Support

- **AWS Support** : Pour problèmes OpenSearch spécifiques
- **Terraform** : `terraform show` et logs CloudWatch
- **Documentation** : Voir [README.md](README.md)

---

**Durée totale estimée** : 30-45 minutes (première fois)  
**Durée déploiements suivants** : 15-20 minutes
