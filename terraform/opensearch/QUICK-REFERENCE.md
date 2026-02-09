# Quick Reference - Terraform OpenSearch

Commandes essentielles pour gérer l'infrastructure OpenSearch.

## 🚀 Déploiement Initial

```bash
cd terraform/opensearch

# 1. Initialiser
terraform init

# 2. Copier et éditer les variables
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

# 3. Planifier
terraform plan -out=tfplan

# 4. Déployer
terraform apply tfplan
```

**Durée** : ~20 minutes

## 📤 Récupérer les Outputs

```bash
# Tous les outputs
terraform output

# Output spécifique
terraform output endpoint
terraform output fluent_bit_role_arn
terraform output kms_key_id

# Format JSON
terraform output -json > outputs.json

# Pour Ansible
terraform output ansible_group_vars
```

## 🔍 Inspection

```bash
# État actuel
terraform show

# Liste des ressources
terraform state list

# Détails d'une ressource
terraform state show aws_opensearch_domain.osquery

# Vérifier la configuration
terraform validate
terraform fmt -check
```

## 🔄 Mises à Jour

```bash
# Modifier terraform.tfvars
vim terraform.tfvars

# Voir les changements
terraform plan

# Appliquer
terraform apply
```

### Exemples de Mises à Jour Courantes

#### Augmenter le Stockage

```hcl
# terraform.tfvars
volume_size = 200  # Augmenter de 100 à 200 GB
```

```bash
terraform apply
```

#### Scaler Horizontalement

```hcl
# terraform.tfvars
instance_count = 6  # Augmenter de 3 à 6 nodes
```

```bash
terraform apply  # Blue-green deployment automatique
```

#### Upgrader OpenSearch

```hcl
# terraform.tfvars
opensearch_version = "OpenSearch_2.13"
```

```bash
terraform apply  # Test préalable recommandé
```

## 🧪 Tests

### Test de Connectivité

```bash
# Récupérer l'endpoint
ENDPOINT=$(terraform output -raw endpoint)

# Test avec AWS CLI
aws opensearch describe-domain \
  --domain-name $(terraform output -raw domain_name)

# Test avec curl + AWS SigV4
curl -X GET "https://$ENDPOINT" \
  --aws-sigv4 "aws:amz:$(terraform output -raw region):es"
```

### Vérifier la Santé

```bash
# Cluster health
curl -X GET "https://$ENDPOINT/_cluster/health?pretty" \
  --aws-sigv4 "aws:amz:$(terraform output -raw region):es"

# Node info
curl -X GET "https://$ENDPOINT/_cat/nodes?v" \
  --aws-sigv4 "aws:amz:$(terraform output -raw region):es"
```

### Test d'Indexation

```bash
# Envoyer un document test
curl -X POST "https://$ENDPOINT/test-index/_doc" \
  --aws-sigv4 "aws:amz:$(terraform output -raw region):es" \
  -H 'Content-Type: application/json' \
  -d '{"message": "Hello from Terraform!", "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}'

# Vérifier
curl -X GET "https://$ENDPOINT/test-index/_search?pretty" \
  --aws-sigv4 "aws:amz:$(terraform output -raw region):es"

# Nettoyer
curl -X DELETE "https://$ENDPOINT/test-index" \
  --aws-sigv4 "aws:amz:$(terraform output -raw region):es"
```

## 📊 Monitoring

### CloudWatch Logs

```bash
DOMAIN=$(terraform output -raw domain_name)

# Application logs
aws logs tail /aws/opensearch/$DOMAIN/application-logs --follow

# Audit logs
aws logs tail /aws/opensearch/$DOMAIN/audit-logs --follow
```

### CloudWatch Metrics

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

# Free storage
aws cloudwatch get-metric-statistics \
  --namespace AWS/ES \
  --metric-name FreeStorageSpace \
  --dimensions Name=DomainName,Value=$(terraform output -raw domain_name) \
  --statistics Average \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300

# Cluster status
aws cloudwatch get-metric-statistics \
  --namespace AWS/ES \
  --metric-name "ClusterStatus.green" \
  --dimensions Name=DomainName,Value=$(terraform output -raw domain_name) \
  --statistics Maximum \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300
```

## 🔗 Intégration Ansible

### Configuration Automatique

```bash
# Option 1 : Afficher les valeurs
terraform output ansible_group_vars

# Option 2 : Export JSON pour parsing
terraform output -json | jq -r '.ansible_group_vars.value'

# Option 3 : Mise à jour directe (attention à la syntaxe YAML)
cat >> ../../ansible/group_vars/all.yaml <<EOF
# Terraform-managed OpenSearch (generated $(date))
opensearch_endpoint: $(terraform output -raw endpoint)
opensearch_region: $(terraform output -raw region)
opensearch_use_aws_auth: true
enable_opensearch_forwarding: true
EOF
```

### Attacher le Rôle IAM aux Instances

```bash
# Récupérer le nom du profile
PROFILE=$(terraform output -raw fluent_bit_instance_profile_name)

# Lister les instances EC2
aws ec2 describe-instances \
  --filters "Name=tag:Role,Values=osquery" \
  --query 'Reservations[].Instances[].InstanceId' \
  --output text

# Attacher le profile
aws ec2 associate-iam-instance-profile \
  --instance-id i-1234567890abcdef0 \
  --iam-instance-profile Name=$PROFILE

# Vérifier
aws ec2 describe-iam-instance-profile-associations \
  --filters "Name=instance-id,Values=i-1234567890abcdef0"
```

## 🔒 Sécurité

### Rotation de la Clé KMS

```bash
# La rotation automatique est activée par défaut
# Vérifier le statut
aws kms get-key-rotation-status \
  --key-id $(terraform output -raw kms_key_id)
```

### Audit des Accès

```bash
# Voir la policy du domaine
aws opensearch describe-domain \
  --domain-name $(terraform output -raw domain_name) \
  --query 'DomainStatus.AccessPolicies' | jq -r . | jq .

# CloudTrail events pour OpenSearch
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceType,AttributeValue=AWS::OpenSearch::Domain \
  --max-items 50
```

### Vérifier le Chiffrement

```bash
# Encryption at rest
aws opensearch describe-domain \
  --domain-name $(terraform output -raw domain_name) \
  --query 'DomainStatus.EncryptionAtRestOptions'

# Node-to-node encryption
aws opensearch describe-domain \
  --domain-name $(terraform output -raw domain_name) \
  --query 'DomainStatus.NodeToNodeEncryptionOptions'
```

## 💾 Backup & Restore

### Créer un Snapshot Manuel

```bash
# 1. Créer un bucket S3 pour les snapshots
aws s3 mb s3://my-opensearch-snapshots-$(date +%Y%m%d)

# 2. Enregistrer le repository
curl -X PUT "https://$ENDPOINT/_snapshot/manual-backups" \
  --aws-sigv4 "aws:amz:$(terraform output -raw region):es" \
  -H 'Content-Type: application/json' \
  -d '{
    "type": "s3",
    "settings": {
      "bucket": "my-opensearch-snapshots-'$(date +%Y%m%d)'",
      "region": "'$(terraform output -raw region)'"
    }
  }'

# 3. Créer un snapshot
curl -X PUT "https://$ENDPOINT/_snapshot/manual-backups/backup-$(date +%Y%m%d-%H%M%S)" \
  --aws-sigv4 "aws:amz:$(terraform output -raw region):es"

# 4. Vérifier le statut
curl -X GET "https://$ENDPOINT/_snapshot/manual-backups/_all?pretty" \
  --aws-sigv4 "aws:amz:$(terraform output -raw region):es"
```

### Restaurer depuis Snapshot

```bash
# Lister les snapshots
curl -X GET "https://$ENDPOINT/_snapshot/manual-backups/_all?pretty" \
  --aws-sigv4 "aws:amz:$(terraform output -raw region):es"

# Restaurer
curl -X POST "https://$ENDPOINT/_snapshot/manual-backups/SNAPSHOT_NAME/_restore" \
  --aws-sigv4 "aws:amz:$(terraform output -raw region):es" \
  -H 'Content-Type: application/json' \
  -d '{
    "indices": "osquery-*",
    "ignore_unavailable": true,
    "include_global_state": false
  }'
```

## 🧹 Maintenance

### Nettoyage des Anciens Index

```bash
# Lister les index par taille
curl -X GET "https://$ENDPOINT/_cat/indices/osquery-*?v&s=store.size:desc" \
  --aws-sigv4 "aws:amz:$(terraform output -raw region):es"

# Supprimer les index de plus de 90 jours
curl -X DELETE "https://$ENDPOINT/osquery-2023.*" \
  --aws-sigv4 "aws:amz:$(terraform output -raw region):es"
```

### Optimisation des Shards

```bash
# Vérifier le nombre de shards
curl -X GET "https://$ENDPOINT/_cat/shards?v" \
  --aws-sigv4 "aws:amz:$(terraform output -raw region):es"

# Forcer merge des segments (off-peak hours)
curl -X POST "https://$ENDPOINT/osquery-*/_forcemerge?max_num_segments=1" \
  --aws-sigv4 "aws:amz:$(terraform output -raw region):es"
```

## 🗑️ Destruction

### Avant de Détruire

```bash
# 1. Créer un snapshot final
curl -X PUT "https://$ENDPOINT/_snapshot/final-backup/final-$(date +%Y%m%d)" \
  --aws-sigv4 "aws:amz:$(terraform output -raw region):es"

# 2. Sauvegarder les outputs
terraform output -json > outputs-backup-$(date +%Y%m%d).json
cp terraform.tfvars terraform.tfvars.backup-$(date +%Y%m%d)

# 3. Exporter les dashboards depuis OpenSearch Dashboards
# (Manuellement via UI)
```

### Détruire l'Infrastructure

```bash
# Planifier la destruction
terraform plan -destroy

# Confirmer et détruire
terraform destroy

# Ou approuver automatiquement (dangereux!)
terraform destroy -auto-approve
```

**⚠️ Attention** : Cette action supprime définitivement toutes les données !

## 🐛 Dépannage

### État Terraform Corrompu

```bash
# Sauvegarder l'état
cp terraform.tfstate terraform.tfstate.backup

# Actualiser l'état
terraform refresh

# Si nécessaire, importer manuellement
terraform import aws_opensearch_domain.osquery arn:aws:es:us-east-1:123456789012:domain/osquery-logs
```

### Changement Requiert Remplacement

```bash
# Voir exactement ce qui sera remplacé
terraform plan | grep -A 5 "must be replaced"

# Pour éviter le downtime, créer un nouveau domaine
# puis migrer les données avec reindex
```

### Erreur de Verrouillage (State Lock)

```bash
# Forcer le déverrouillage (si vous êtes sûr)
terraform force-unlock LOCK_ID

# Ou utiliser un lock DynamoDB pour remote state
```

## 📚 Ressources Utiles

### AWS CLI OpenSearch

```bash
# Toutes les commandes disponibles
aws opensearch help

# Lister tous les domaines
aws opensearch list-domain-names

# Détails complets d'un domaine
aws opensearch describe-domain \
  --domain-name $(terraform output -raw domain_name) \
  | jq .
```

### Terraform State Management

```bash
# Voir l'état complet
terraform show

# Lister toutes les ressources
terraform state list

# Détails d'une ressource spécifique
terraform state show aws_opensearch_domain.osquery
terraform state show aws_kms_key.opensearch

# Déplacer une ressource dans l'état
terraform state mv aws_opensearch_domain.osquery aws_opensearch_domain.osquery_new
```

### Calcul de Coût

```bash
# Utiliser l'API AWS Pricing
aws pricing get-products \
  --service-code AmazonES \
  --filters "Type=TERM_MATCH,Field=instanceType,Value=r6g.large.search" \
  --region us-east-1

# Ou utiliser infracost (outil tiers)
# https://www.infracost.io/
infracost breakdown --path .
```

## 🔄 Workflows Recommandés

### Workflow de Dev

```bash
# 1. Modifier dans une branche
git checkout -b feature/increase-storage

# 2. Modifier terraform.tfvars
vim terraform.tfvars

# 3. Tester localement
terraform plan

# 4. Commit et push
git add terraform.tfvars
git commit -m "Increase storage to 200GB"
git push origin feature/increase-storage

# 5. Review + Apply après merge
```

### Workflow de Production

```bash
# 1. Toujours utiliser remote state
# (configuré dans versions.tf)

# 2. Planifier avec output sauvegardé
terraform plan -out=prod-$(date +%Y%m%d-%H%M%S).tfplan

# 3. Review manuel du plan

# 4. Apply pendant une fenêtre de maintenance
terraform apply prod-YYYYMMDD-HHMMSS.tfplan

# 5. Vérifier post-déploiement
./verify-deployment.sh  # Script custom
```

---

**Note** : Pour une documentation complète, voir [README.md](README.md) et [DEPLOYMENT.md](DEPLOYMENT.md).
