# Guide de Démarrage Rapide - OSQuery avec AWS OpenSearch

Ce guide vous permet de déployer rapidement OSQuery avec envoi des logs vers AWS OpenSearch.

## 🚀 Démarrage en 5 Minutes

### 1. Prérequis

```bash
# Installer Ansible
pip install ansible

# Installer les collections requises
cd ansible
ansible-galaxy collection install -r requirements.yaml
```

### 2. Créer votre Domaine AWS OpenSearch

```bash
# Via AWS CLI
aws opensearch create-domain \
  --domain-name osquery-logs \
  --engine-version OpenSearch_2.11 \
  --cluster-config InstanceType=t3.small.search,InstanceCount=1 \
  --ebs-options EBSEnabled=true,VolumeType=gp3,VolumeSize=20
```

Ou via la Console AWS : Services → OpenSearch Service → Create domain

### 3. Configurer les Permissions IAM

Attacher cette politique au rôle IAM de vos instances EC2:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "es:ESHttpPost",
      "es:ESHttpPut",
      "es:ESHttpGet"
    ],
    "Resource": "arn:aws:es:REGION:ACCOUNT:domain/osquery-logs/*"
  }]
}
```

### 4. Configurer Ansible

Copier et éditer le fichier de variables :

```bash
cd ansible
cp group_vars/all.yaml.example group_vars/all.yaml
```

Éditer `group_vars/all.yaml` :

```yaml
enable_opensearch_forwarding: true
opensearch_endpoint: "search-osquery-logs-abc123.us-east-1.es.amazonaws.com"
opensearch_region: "us-east-1"
opensearch_index_prefix: "osquery"
opensearch_environment: "production"
```

### 5. Configurer l'Inventaire

Éditer `inventory.ini` avec vos serveurs :

```ini
[linux_debian]
server1 ansible_host=10.0.1.10 ansible_user=ubuntu

[linux_redhat]
server2 ansible_host=10.0.2.10 ansible_user=ec2-user
```

### 6. Tester la Connectivité

```bash
ansible all -m ping
```

### 7. Déployer!

```bash
# Dry-run d'abord
ansible-playbook playbook-opensearch.yaml --check

# Déploiement réel
ansible-playbook playbook-opensearch.yaml
```

### 8. Vérifier les Logs dans OpenSearch

Accéder à OpenSearch Dashboards :

```
https://VOTRE_ENDPOINT/_dashboards
```

Créer un index pattern : `osquery-*`

Aller dans **Discover** pour voir les logs en temps réel!

## 📊 Commandes Utiles

### Vérifier les Services

```bash
# OSQuery
ansible all -m shell -a "systemctl status osqueryd" --become

# Fluent Bit
ansible all -m shell -a "systemctl status fluent-bit" --become
```

### Vérifier les Logs Locaux

```bash
ansible all -m shell -a "tail -20 /var/log/osquery/osqueryd.results.log" --become
```

### Vérifier la Connexion OpenSearch

```bash
# Lister les indices
curl -XGET "https://VOTRE_ENDPOINT/_cat/indices/osquery*?v"

# Compter les documents
curl -XGET "https://VOTRE_ENDPOINT/osquery-*/_count"

# Voir les derniers logs
curl -XGET "https://VOTRE_ENDPOINT/osquery-*/_search?size=5&sort=@timestamp:desc&pretty"
```

## 🔧 Déploiements par Environnement

### Production

```bash
ansible-playbook playbook-opensearch.yaml \
  --limit production \
  -e "opensearch_environment=production"
```

### Staging

```bash
ansible-playbook playbook-opensearch.yaml \
  --limit staging \
  -e "opensearch_environment=staging" \
  -e "opensearch_index_prefix=osquery-staging"
```

## 🛠️ Dépannage Rapide

### Fluent Bit ne démarre pas

```bash
# Vérifier les logs
ansible all -m shell -a "journalctl -u fluent-bit -n 50" --become

# Tester la configuration
ansible all -m shell -a "fluent-bit -c /etc/fluent-bit/fluent-bit.conf --dry-run" --become
```

### Pas de logs dans OpenSearch

1. Vérifier que OSQuery génère des logs :
   ```bash
   ls -lh /var/log/osquery/
   ```

2. Vérifier que Fluent Bit lit les fichiers :
   ```bash
   sudo lsof | grep fluent-bit | grep osquery
   ```

3. Vérifier les permissions IAM :
   ```bash
   aws sts get-caller-identity
   ```

### Erreur 403 Forbidden

Les permissions IAM sont insuffisantes. Vérifier:
- Le rôle IAM de l'instance a bien la politique
- Le domaine OpenSearch autorise l'accès depuis le VPC/IP

## 📖 Documentation Complète

Pour plus de détails :
- Configuration avancée : [docs/OPENSEARCH.md](../docs/OPENSEARCH.md)
- Guide général : [README.md](../README.md)

## 💡 Exemples de Requêtes OpenSearch

### Top 10 des processus

```json
GET /osquery-*/_search
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

### Activité réseau par hôte

```json
GET /osquery-*/_search
{
  "size": 0,
  "aggs": {
    "by_host": {
      "terms": {
        "field": "hostname.keyword"
      }
    }
  }
}
```

## 🎯 Prochaines Étapes

1. ✅ Créer des dashboards dans OpenSearch Dashboards
2. ✅ Configurer des alertes pour les événements suspects
3. ✅ Ajouter des packs OSQuery personnalisés
4. ✅ Configurer la rotation des indices (ISM Policy)
5. ✅ Mettre en place une rétention des données

Bon monitoring! 🎉
