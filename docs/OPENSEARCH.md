# Configuration AWS OpenSearch pour OSQuery

Ce guide explique comment configurer l'envoi des logs OSQuery vers AWS OpenSearch en utilisant Fluent Bit comme agent de forwarding.

## 📋 Architecture

```
OSQuery → Fichiers logs locaux → Fluent Bit → AWS OpenSearch
```

Fluent Bit lit les logs OSQuery en temps réel et les envoie directement à AWS OpenSearch avec authentification IAM.

## 🚀 Prérequis AWS

### 1. Domaine AWS OpenSearch

Créer un domaine OpenSearch dans AWS :

```bash
aws opensearch create-domain \
  --domain-name osquery-logs \
  --engine-version OpenSearch_2.11 \
  --cluster-config InstanceType=t3.small.search,InstanceCount=1 \
  --ebs-options EBSEnabled=true,VolumeType=gp3,VolumeSize=20 \
  --access-policies '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"AWS": "*"},
      "Action": "es:*",
      "Resource": "arn:aws:es:REGION:ACCOUNT_ID:domain/osquery-logs/*"
    }]
  }'
```

### 2. IAM Policy pour les Instances

Créer une politique IAM permettant l'écriture dans OpenSearch :

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "es:ESHttpPost",
        "es:ESHttpPut",
        "es:ESHttpGet"
      ],
      "Resource": "arn:aws:es:REGION:ACCOUNT_ID:domain/osquery-logs/*"
    }
  ]
}
```

Attacher cette politique au rôle IAM de vos instances EC2.

### 3. Security Group

Assurez-vous que le security group de votre domaine OpenSearch autorise le trafic depuis vos instances.

## ⚙️ Configuration Ansible

### 1. Activer OpenSearch Forwarding

Dans `group_vars/all.yaml` ou votre inventaire :

```yaml
enable_opensearch_forwarding: true

# Configuration AWS OpenSearch
opensearch_endpoint: "search-osquery-logs-abc123.us-east-1.es.amazonaws.com"
opensearch_region: "us-east-1"
opensearch_port: 443
opensearch_index_prefix: "osquery"
opensearch_environment: "production"
opensearch_tls_verify: "On"
```

### 2. Configuration par Environnement

Créer des fichiers de variables spécifiques :

**group_vars/production.yaml**
```yaml
enable_opensearch_forwarding: true
opensearch_endpoint: "search-prod-abc123.us-east-1.es.amazonaws.com"
opensearch_environment: "production"
opensearch_index_prefix: "osquery-prod"
```

**group_vars/staging.yaml**
```yaml
enable_opensearch_forwarding: true
opensearch_endpoint: "search-staging-xyz789.us-west-2.es.amazonaws.com"
opensearch_environment: "staging"
opensearch_index_prefix: "osquery-staging"
```

### 3. Configuration par Groupe d'Hôtes

Dans `group_vars/linux.yaml` :
```yaml
enable_opensearch_forwarding: true
opensearch_region: "us-east-1"
```

Dans `group_vars/windows.yaml` :
```yaml
enable_opensearch_forwarding: true
opensearch_region: "eu-west-1"
```

## 🎯 Déploiement

### Déployer avec OpenSearch activé

```bash
ansible-playbook playbook.yaml -e "enable_opensearch_forwarding=true"
```

### Déployer uniquement sur certains hôtes

```bash
ansible-playbook playbook.yaml \
  --limit production \
  -e "enable_opensearch_forwarding=true"
```

### Vérifier la configuration (dry-run)

```bash
ansible-playbook playbook.yaml --check \
  -e "enable_opensearch_forwarding=true"
```

## 🔍 Vérification

### 1. Vérifier Fluent Bit

**Linux:**
```bash
sudo systemctl status fluent-bit
sudo journalctl -u fluent-bit -f
```

**macOS:**
```bash
brew services list | grep fluent-bit
tail -f /usr/local/var/log/fluent-bit.log
```

**Windows:**
```powershell
Get-Service fluent-bit
Get-Content "C:\fluent-bit\fluent-bit.log" -Wait
```

### 2. Vérifier les Logs dans OpenSearch

Utiliser OpenSearch Dashboards ou l'API :

```bash
# Lister les indices
curl -XGET "https://YOUR_OPENSEARCH_ENDPOINT/_cat/indices/osquery*?v"

# Rechercher des documents récents
curl -XGET "https://YOUR_OPENSEARCH_ENDPOINT/osquery-*/_search?size=5&sort=@timestamp:desc&pretty"
```

### 3. Créer un Index Pattern dans OpenSearch Dashboards

1. Aller dans **Stack Management** → **Index Patterns**
2. Créer un pattern : `osquery-*`
3. Sélectionner `@timestamp` comme champ de temps
4. Aller dans **Discover** pour voir les logs

## 📊 Dashboards OpenSearch

### Requêtes Utiles

**Top 10 des processus les plus fréquents:**
```json
{
  "size": 0,
  "aggs": {
    "top_processes": {
      "terms": {
        "field": "name.keyword",
        "size": 10
      }
    }
  }
}
```

**Activité réseau par hôte:**
```json
{
  "size": 0,
  "aggs": {
    "by_host": {
      "terms": {
        "field": "hostname.keyword"
      },
      "aggs": {
        "network_connections": {
          "cardinality": {
            "field": "remote_address.keyword"
          }
        }
      }
    }
  }
}
```

## 🔧 OpenSearch Auto-hébergé (Non-AWS)

Pour un OpenSearch auto-hébergé, utiliser l'authentification basique :

```yaml
enable_opensearch_forwarding: true
opensearch_endpoint: "opensearch.mycompany.com"
opensearch_port: 9200
opensearch_region: "us-east-1"  # Requis même pour non-AWS
opensearch_use_basic_auth: true
opensearch_username: "admin"
opensearch_password: "{{ vault_opensearch_password }}"
opensearch_tls_verify: "On"
```

### Utiliser Ansible Vault pour les Secrets

```bash
# Créer un fichier vault
ansible-vault create group_vars/vault.yaml

# Contenu:
---
vault_opensearch_password: "mon_mot_de_passe_secret"

# Déployer avec le vault
ansible-playbook playbook.yaml --ask-vault-pass
```

## 🛠️ Dépannage

### Fluent Bit ne se connecte pas à OpenSearch

1. Vérifier les permissions IAM de l'instance
2. Vérifier le security group d'OpenSearch
3. Vérifier l'endpoint OpenSearch (pas de `https://`)

```bash
# Tester la connectivité
curl -v https://YOUR_OPENSEARCH_ENDPOINT

# Vérifier les logs Fluent Bit
sudo journalctl -u fluent-bit --no-pager | grep -i error
```

### Aucun log n'apparaît dans OpenSearch

Vérifier que :
- OSQuery génère des logs : `ls -lah /var/log/osquery/`
- Fluent Bit lit les fichiers : `sudo lsof | grep fluent-bit | grep osquery`
- Les indices sont créés : `curl -XGET "https://ENDPOINT/_cat/indices?v"`

### Erreur "403 Forbidden"

Les permissions IAM sont insuffisantes :
```bash
# Vérifier le rôle de l'instance
aws sts get-caller-identity

# Vérifier les politiques attachées
aws iam list-attached-role-policies --role-name YOUR_INSTANCE_ROLE
```

### Erreur "SSL certificate verify failed"

Désactiver temporairement la vérification TLS pour tester :
```yaml
opensearch_tls_verify: "Off"
```

## 📈 Optimisation

### Ajuster le Buffer Fluent Bit

Dans les templates Fluent Bit, augmenter `Mem_Buf_Limit` pour des environnements à fort volume :

```ini
[INPUT]
    Mem_Buf_Limit     50MB  # Au lieu de 5MB
```

### Rotation des Indices

Configurer des politiques ISM (Index State Management) dans OpenSearch :

```json
{
  "policy": {
    "policy_id": "osquery_policy",
    "description": "Policy for osquery indices",
    "default_state": "hot",
    "states": [
      {
        "name": "hot",
        "actions": [],
        "transitions": [
          {
            "state_name": "delete",
            "conditions": {
              "min_index_age": "30d"
            }
          }
        ]
      },
      {
        "name": "delete",
        "actions": [
          {
            "delete": {}
          }
        ],
        "transitions": []
      }
    ]
  }
}
```

## 📚 Ressources

- [AWS OpenSearch Documentation](https://docs.aws.amazon.com/opensearch-service/)
- [Fluent Bit OpenSearch Output](https://docs.fluentbit.io/manual/pipeline/outputs/opensearch)
- [OSQuery Logging](https://osquery.readthedocs.io/en/stable/deployment/logging/)
- [OpenSearch Dashboards](https://opensearch.org/docs/latest/dashboards/)

## 📝 Exemple Complet

Fichier `group_vars/all.yaml` :

```yaml
---
# OSQuery
osquery_log_dir: "/var/log/osquery"

# OpenSearch Forwarding
enable_opensearch_forwarding: true
opensearch_endpoint: "search-osquery-prod-abc123.us-east-1.es.amazonaws.com"
opensearch_region: "us-east-1"
opensearch_port: 443
opensearch_index_prefix: "osquery"
opensearch_environment: "production"
opensearch_tls_verify: "On"
```

Commande de déploiement :
```bash
ansible-playbook playbook.yaml -i inventory.ini
```
