# OSQuery + OpenSearch Cheat Sheet

Commandes rapides pour le déploiement et la gestion d'OSQuery avec AWS OpenSearch.

## 🚀 Déploiement

### Installation Initiale
```bash
cd ansible
./setup.sh
```

### Déploiement Standard
```bash
# Dry-run (test)
ansible-playbook playbook.yaml --check

# Déploiement réel
ansible-playbook playbook.yaml

# Avec OpenSearch
ansible-playbook playbook-opensearch.yaml
```

### Déploiement Sélectif
```bash
# Par groupe
ansible-playbook playbook.yaml --limit linux_debian
ansible-playbook playbook.yaml --limit windows

# Par serveur
ansible-playbook playbook.yaml --limit server1

# Par environnement
ansible-playbook playbook.yaml --limit production
```

### Mode Verbose
```bash
ansible-playbook playbook.yaml -v    # verbose
ansible-playbook playbook.yaml -vv   # plus de détails
ansible-playbook playbook.yaml -vvv  # debug complet
```

## 🔍 Vérification

### Tester la Connectivité
```bash
# Tous les serveurs
ansible all -m ping

# Par groupe
ansible linux_debian -m ping
ansible windows -m win_ping
```

### Vérifier les Services
```bash
# OSQuery
ansible all -m shell -a "systemctl status osqueryd" --become

# Fluent Bit
ansible all -m shell -a "systemctl status fluent-bit" --become

# Les deux
ansible all -m shell -a "systemctl status osqueryd fluent-bit" --become
```

### Voir les Logs
```bash
# Logs OSQuery
ansible all -m shell -a "tail -20 /var/log/osquery/osqueryd.results.log" --become

# Logs Fluent Bit
ansible all -m shell -a "journalctl -u fluent-bit -n 50" --become

# Logs en temps réel (sur un serveur)
ssh server1
sudo tail -f /var/log/osquery/osqueryd.results.log
```

## 📊 OpenSearch

### Vérifier les Indices
```bash
# Lister tous les indices
curl -XGET "https://YOUR_ENDPOINT/_cat/indices/osquery*?v"

# Compter les documents
curl -XGET "https://YOUR_ENDPOINT/osquery-*/_count?pretty"

# Voir les derniers logs
curl -XGET "https://YOUR_ENDPOINT/osquery-*/_search?size=5&sort=@timestamp:desc&pretty"
```

### Recherches Utiles
```bash
# Rechercher par hostname
curl -XGET "https://YOUR_ENDPOINT/osquery-*/_search?q=hostname:server1&pretty"

# Rechercher dans les dernières 24h
curl -XGET "https://YOUR_ENDPOINT/osquery-*/_search" -H 'Content-Type: application/json' -d'
{
  "query": {
    "range": {
      "@timestamp": {
        "gte": "now-24h"
      }
    }
  }
}'
```

### Gestion des Indices
```bash
# Supprimer les indices de plus de 30 jours
curl -XDELETE "https://YOUR_ENDPOINT/osquery-$(date -d '30 days ago' +%Y.%m.%d)"

# Fermer un indice
curl -XPOST "https://YOUR_ENDPOINT/osquery-2026.01.01/_close"

# Rouvrir un indice
curl -XPOST "https://YOUR_ENDPOINT/osquery-2026.01.01/_open"
```

## 🔧 Gestion des Configurations

### Variables
```bash
# Voir les variables d'un host
ansible server1 -m debug -a "var=hostvars[inventory_hostname]"

# Voir une variable spécifique
ansible all -m debug -a "var=opensearch_endpoint"
```

### Redéployer Uniquement les Configurations
```bash
# Forcer le redéploiement des templates
ansible-playbook playbook.yaml --tags config

# Uniquement OSQuery
ansible all -m template \
  -a "src=templates/osquery-linux.conf.j2 dest=/etc/osquery/osquery.conf" \
  --become

# Uniquement Fluent Bit
ansible all -m template \
  -a "src=templates/fluent-bit-linux.conf.j2 dest=/etc/fluent-bit/fluent-bit.conf" \
  --become
```

### Redémarrer les Services
```bash
# OSQuery
ansible all -m systemd -a "name=osqueryd state=restarted" --become

# Fluent Bit
ansible all -m systemd -a "name=fluent-bit state=restarted" --become

# Les deux
ansible all -m shell -a "systemctl restart osqueryd fluent-bit" --become
```

## 🛠️ Dépannage

### Diagnostics OSQuery
```bash
# Version installée
ansible all -m shell -a "osqueryi --version"

# Test de requête
ansible all -m shell -a 'osqueryi "SELECT * FROM system_info;"' --become

# Vérifier la configuration
ansible all -m shell -a "osqueryi --config_check /etc/osquery/osquery.conf" --become
```

### Diagnostics Fluent Bit
```bash
# Version
ansible all -m shell -a "fluent-bit --version"

# Test de configuration
ansible all -m shell -a "fluent-bit -c /etc/fluent-bit/fluent-bit.conf --dry-run" --become

# Logs d'erreurs
ansible all -m shell -a "journalctl -u fluent-bit --no-pager | grep -i error" --become
```

### Diagnostics Réseau
```bash
# Tester la connexion à OpenSearch
ansible all -m shell -a "curl -v https://YOUR_ENDPOINT"

# Vérifier DNS
ansible all -m shell -a "nslookup YOUR_ENDPOINT"

# Ports ouverts
ansible all -m shell -a "ss -tulpn | grep -E '(osquery|fluent)'" --become
```

### Diagnostics AWS
```bash
# Identité IAM
ansible all -m shell -a "aws sts get-caller-identity"

# Région
ansible all -m shell -a "curl -s http://169.254.169.254/latest/meta-data/placement/region"

# Instance ID
ansible all -m shell -a "curl -s http://169.254.169.254/latest/meta-data/instance-id"
```

## 📦 Gestion des Packages

### Mettre à Jour OSQuery
```bash
# Debian/Ubuntu
ansible linux_debian -m apt -a "name=osquery state=latest" --become

# RedHat/CentOS
ansible linux_redhat -m yum -a "name=osquery state=latest" --become
```

### Mettre à Jour Fluent Bit
```bash
# Debian/Ubuntu
ansible linux_debian -m apt -a "name=fluent-bit state=latest" --become

# RedHat/CentOS
ansible linux_redhat -m yum -a "name=fluent-bit state=latest" --become
```

## 🔐 Sécurité

### Avec Ansible Vault
```bash
# Créer un vault
ansible-vault create group_vars/vault.yaml

# Éditer le vault
ansible-vault edit group_vars/vault.yaml

# Déployer avec vault
ansible-playbook playbook.yaml --ask-vault-pass

# Avec fichier de password
ansible-playbook playbook.yaml --vault-password-file ~/.vault_pass
```

### Contenu du Vault (exemple)
```yaml
---
vault_opensearch_password: "mon_secret"
vault_opensearch_username: "admin"
```

### Utiliser dans group_vars/all.yaml
```yaml
opensearch_username: "{{ vault_opensearch_username }}"
opensearch_password: "{{ vault_opensearch_password }}"
```

## 📈 Performance

### Métriques Système
```bash
# CPU et Mémoire OSQuery
ansible all -m shell -a "ps aux | grep osquery" --become

# CPU et Mémoire Fluent Bit
ansible all -m shell -a "ps aux | grep fluent-bit" --become

# Taille des logs
ansible all -m shell -a "du -sh /var/log/osquery/*" --become
```

### Métriques OpenSearch
```bash
# Statistiques du cluster
curl -XGET "https://YOUR_ENDPOINT/_cluster/stats?pretty"

# Santé du cluster
curl -XGET "https://YOUR_ENDPOINT/_cluster/health?pretty"

# Taille des indices
curl -XGET "https://YOUR_ENDPOINT/_cat/indices/osquery*?v&s=store.size:desc"
```

## 🔄 Maintenance

### Rotation des Logs Locaux
```bash
# Vérifier logrotate
ansible all -m shell -a "cat /etc/logrotate.d/osquery" --become

# Forcer la rotation
ansible all -m shell -a "logrotate -f /etc/logrotate.d/osquery" --become
```

### Nettoyage
```bash
# Nettoyer les anciens logs
ansible all -m shell -a "find /var/log/osquery -type f -mtime +30 -delete" --become

# Vider le cache apt/yum
ansible linux_debian -m apt -a "autoclean=yes" --become
ansible linux_redhat -m shell -a "yum clean all" --become
```

## 📝 Exemples de Requêtes OSQuery

### Interactives
```bash
# Se connecter à osqueryi
ssh server1
sudo osqueryi

# Exemples de requêtes
SELECT * FROM system_info;
SELECT * FROM processes WHERE name LIKE '%python%';
SELECT * FROM logged_in_users;
SELECT * FROM listening_ports;
```

### Via Ansible
```bash
# Exécuter une requête sur tous les serveurs
ansible all -m shell -a 'osqueryi "SELECT hostname, cpu_brand FROM system_info;"' --become

# Trouver les processus Python
ansible all -m shell -a 'osqueryi "SELECT pid, name, path FROM processes WHERE name LIKE '\''%python%'\'';"' --become
```

## 🎯 Raccourcis Utiles

### Alias à Ajouter
```bash
# Ajouter à ~/.bashrc ou ~/.zshrc
alias ap='ansible-playbook'
alias apd='ansible-playbook --check'  # dry-run
alias apo='ansible-playbook playbook-opensearch.yaml'
alias av='ansible all -m'
alias avp='ansible all -m ping'
```

### Avec ces Alias
```bash
apd playbook.yaml          # dry-run
ap playbook.yaml           # déployer
apo                        # déployer avec OpenSearch
avp                        # ping tous les serveurs
av shell -a "uptime"       # uptime de tous les serveurs
```

---

**Astuce** : Sauvegardez cette cheat sheet et personnalisez-la selon vos besoins!
