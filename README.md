# OSQuery Ansible Deployment

Ce projet Ansible déploie et configure **OSQuery** sur plusieurs plateformes : Linux (Debian et RedHat), macOS et Windows. OSQuery collecte des informations système et peut envoyer les résultats des requêtes vers des fichiers de log locaux **ou vers AWS OpenSearch** pour une analyse centralisée.

## 📋 Fonctionnalités

- ✅ Installation automatique d'OSQuery sur :
  - **Linux Debian/Ubuntu** (via APT)
  - **Linux RedHat/CentOS/Rocky** (via YUM/DNF)
  - **macOS** (via Homebrew Cask)
  - **Windows** (via MSI)
- ✅ Configuration complète avec logging activé
- ✅ Requêtes planifiées pour la surveillance système
- ✅ Gestion des services OSQuery
- ✅ **Envoi des logs vers AWS OpenSearch** (via Fluent Bit)
- ✅ Support multi-environnements (production, staging, etc.)
- ✅ Authentification AWS IAM ou Basic Auth

## 📁 Structure du Projet

```
ansible/
├── playbook.yaml              # Playbook principal
├── inventory.ini              # Fichier d'inventaire exemple
├── ansible.cfg                # Configuration Ansible
└── modules/
    └── osquery/
        ├── tasks/
        │   ├── main.yaml               # Point d'entrée avec détection de l'OS
        │   ├── debian.yaml             # Installation Debian/Ubuntu
        │   ├── redhat.yaml             # Installation RedHat/CentOS
        │   ├── macos.yaml              # Installation macOS
        │   ├── windows.yaml            # Installation Windows
        │   ├── fluent-bit-debian.yaml  # Fluent Bit pour Debian
        │   ├── fluent-bit-redhat.yaml  # Fluent Bit pour RedHat
        │   ├── fluent-bit-macos.yaml   # Fluent Bit pour macOS
        │   └── fluent-bit-windows.yaml # Fluent Bit pour Windows
        ├── templates/
        │   ├── osquery-linux.conf.j2        # Config OSQuery Linux
        │   ├── osquery-macos.conf.j2        # Config OSQuery macOS
        │   ├── osquery-windows.conf.j2      # Config OSQuery Windows
        │   ├── fluent-bit-linux.conf.j2     # Config Fluent Bit Linux
        │   ├── fluent-bit-macos.conf.j2     # Config Fluent Bit macOS
        │   ├── fluent-bit-windows.conf.j2   # Config Fluent Bit Windows
        │   └── fluent-bit-parsers.conf.j2   # Parsers Fluent Bit
        ├── handlers/
        │   └── main.yaml      # Gestion des redémarrages
        ├── defaults/
        │   └── main.yaml      # Variables par défaut
        └── meta/
            └── main.yaml      # Métadonnées du rôle
```

## 🚀 Prérequis

### Contrôleur Ansible
- Ansible >= 2.9
- Python 3.x

### Collections Ansible
```bash
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.windows
```

### Hosts Cibles

**Linux:**
- SSH configuré
- Sudo/root access
- Python 3

**macOS:**
- SSH configuré
- Homebrew installé
- Sudo access

**Windows:**
- WinRM configuré
- Droits administrateur

## ⚙️ Configuration

### 1. Modifier l'inventaire

Éditez [inventory.ini](ansible/inventory.ini) avec vos serveurs :

```ini
[linux_debian]
server1 ansible_host=192.168.1.10 ansible_user=admin

[linux_redhat]
server2 ansible_host=192.168.1.20 ansible_user=admin

[macos]
mac1 ansible_host=192.168.1.30 ansible_user=admin

[windows]
win1 ansible_host=192.168.1.40 ansible_user=administrator ansible_connection=winrm
```

### 2. Variables personnalisables

Dans [modules/osquery/defaults/main.yaml](ansible/modules/osquery/defaults/main.yaml) :

```yaml
osquery_log_dir: "/var/log/osquery"  # Répertoire des logs
osquery_version: "5.11.0"            # Version (Windows)

# OpenSearch forwarding (optionnel)
enable_opensearch_forwarding: false  # Activé dans group_vars
opensearch_endpoint: "search-my-domain.us-east-1.es.amazonaws.com"
opensearch_region: "us-east-1"
opensearch_index_prefix: "osquery"
```

**Pour activer l'envoi vers AWS OpenSearch**, voir [docs/OPENSEARCH.md](docs/OPENSEARCH.md)

### 3. Configuration OSQuery

Les templates de configuration incluent :
- **Logging activé** vers fichiers locaux
- **Requêtes planifiées** :
  - Informations système (toutes les heures)
  - Surveillance des processus (toutes les 10 min)
  - Sessions utilisateur (toutes les 10 min)
  - Connexions réseau (toutes les 10 min)
  - Inventaire logiciels (VSCode, JetBrains, Homebrew, Chocolatey)
- **Packs de sécurité** configurés

## 🎯 Utilisation

### Déployer sur tous les serveurs

```bash
cd ansible
ansible-playbook playbook.yaml
```

### Déployer sur un groupe spécifique

```bash
# Seulement Linux
ansible-playbook playbook.yaml --limit linux

# Seulement Debian
ansible-playbook playbook.yaml --limit linux_debian

# Seulement macOS
ansible-playbook playbook.yaml --limit macos

# Seulement Windows
ansible-playbook playbook.yaml --limit windows
```

### Déployer sur un serveur spécifique

```bash
ansible-playbook playbook.yaml --limit server1
```

### Mode vérification (dry-run)

```bash
ansible-playbook playbook.yaml --check
```

## 📊 Vérification des Logs

### Logs Locaux

#### Linux (Debian/RedHat)
```bash
# Logs OSQuery
sudo tail -f /var/log/osquery/osqueryd.results.log

# Informations détaillées
sudo tail -f /var/log/osquery/osqueryd.INFO

# Status du service
sudo systemctl status osqueryd

# Fluent Bit (si OpenSearch activé)
sudo systemctl status fluent-bit
sudo journalctl -u fluent-bit -f
```

#### macOS
```bash
# Logs OSQuery
sudo tail -f /var/log/osquery/osqueryd.results.log

# Status du service
sudo launchctl list | grep osquery

# Fluent Bit (si OpenSearch activé)
brew services list | grep fluent-bit
```

#### Windows
```powershell
# Logs OSQuery
Get-Content "C:\ProgramData\osquery\log\osqueryd.results.log" -Wait

# Status du service
Get-Service osqueryd

# Fluent Bit (si OpenSearch activé)
Get-Service fluent-bit
```

### Logs dans AWS OpenSearch

Si OpenSearch est activé, vérifier dans OpenSearch Dashboards :

```bash
# Lister les indices
curl -XGET "https://YOUR_ENDPOINT/_cat/indices/osquery*?v"

# Rechercher les logs récents
curl -XGET "https://YOUR_ENDPOINT/osquery-*/_search?size=5&sort=@timestamp:desc"
```

Accédez à **OpenSearch Dashboards** → **Discover** → Index pattern `osquery-*`

## 🔍 Requêtes Planifiées

Les configurations incluent ces requêtes par défaut :

| Requête | Intervalle | Description |
|---------|-----------|-------------|
| system_info | 1h | Informations matérielles système |
| process_monitor | 10min | Liste des processus actifs |
| user_sessions | 10min | Utilisateurs connectés |
| network_connections | 10min | Connexions réseau ouvertes |
| file_events | 5min | Événements filesystem (Linux) |

## 🔧 Personnalisation

### Ajouter des requêtes personnalisées

Modifiez les templates de configuration et ajoutez vos requêtes dans la section `schedule` :

```json
"ma_requete": {
  "query": "SELECT * FROM ma_table;",
  "interval": 600,
  "description": "Description de ma requête"
}
```

### Changer le répertoire de logs

Dans votre playbook ou inventaire :

```yaml
vars:
  osquery_log_dir: "/custom/path/to/logs"
```

## ☁️ Envoi des Logs vers AWS OpenSearch

Ce projet supporte l'envoi automatique des logs OSQuery vers **AWS OpenSearch** via **Fluent Bit**.

### Activation Rapide

Dans `group_vars/all.yaml` :

```yaml
enable_opensearch_forwarding: true
opensearch_endpoint: "search-my-domain-abc123.us-east-1.es.amazonaws.com"
opensearch_region: "us-east-1"
opensearch_index_prefix: "osquery"
opensearch_environment: "production"
```

### Prérequis AWS

1. **Domaine AWS OpenSearch** créé
2. **Politique IAM** attachée aux instances :
```json
{
  "Effect": "Allow",
  "Action": ["es:ESHttpPost", "es:ESHttpPut"],
  "Resource": "arn:aws:es:REGION:ACCOUNT:domain/NAME/*"
}
```
3. **Security Group** autorisant le trafic des instances

### Déploiement avec OpenSearch

```bash
# Déployer avec OpenSearch activé
ansible-playbook playbook.yaml -e "enable_opensearch_forwarding=true"

# Vérifier Fluent Bit
ansible all -m shell -a "systemctl status fluent-bit"
```

### Documentation Complète

Pour une configuration détaillée, dépannage et exemples :
👉 **[Voir docs/OPENSEARCH.md](docs/OPENSEARCH.md)**

Inclut :
- Configuration AWS OpenSearch
- Authentification IAM vs Basic Auth
- Dashboards et requêtes
- Optimisations et rotation d'indices
- Dépannage complet

## 🛠️ Dépannage

### Vérifier la connectivité Ansible

```bash
ansible all -m ping
```

### Voir les détails d'exécution

```bash
ansible-playbook playbook.yaml -vvv
```

### Problèmes Windows WinRM

```bash
# Tester WinRM
ansible windows -m win_ping
```

### OSQuery ne démarre pas

```bash
# Linux
sudo journalctl -u osqueryd -f

# macOS
sudo log stream --predicate 'processImagePath contains "osquery"'

# Windows
Get-EventLog -LogName Application -Source osqueryd -Newest 20
```

## 📚 Ressources

- [Documentation OSQuery](https://osquery.io/docs/)
- [OSQuery Schema](https://osquery.io/schema/)
- [Documentation Ansible](https://docs.ansible.com/)
- [OSQuery Packs](https://github.com/osquery/osquery/tree/master/packs)
- [AWS OpenSearch Service](https://docs.aws.amazon.com/opensearch-service/)
- [Fluent Bit Documentation](https://docs.fluentbit.io/)
- [Fluent Bit OpenSearch Output](https://docs.fluentbit.io/manual/pipeline/outputs/opensearch)

## 📝 License

MIT

## 👤 Auteur

Project OSQuery Ansible Deployment
