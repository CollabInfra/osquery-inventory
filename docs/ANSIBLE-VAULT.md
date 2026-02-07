# Exemple de Configuration avec Ansible Vault

Ce guide montre comment utiliser Ansible Vault pour sécuriser les secrets comme les mots de passe OpenSearch.

## 📁 Structure Recommandée

```
ansible/
├── group_vars/
│   ├── all.yaml              # Variables non sensibles
│   └── vault.yaml            # Variables sensibles (chiffré)
└── playbook.yaml
```

## 🔐 1. Créer le Fichier Vault

### Créer un Nouveau Vault
```bash
cd ansible
ansible-vault create group_vars/vault.yaml
```

Vous serez invité à créer un mot de passe pour le vault.

### Contenu du Vault
```yaml
---
# Variables sensibles chiffrées
vault_opensearch_password: "SuperSecretPassword123!"
vault_opensearch_username: "admin"

# Autres secrets si nécessaire
vault_aws_access_key: "AKIAIOSFODNN7EXAMPLE"
vault_aws_secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
```

## 📝 2. Référencer les Variables du Vault

### Dans group_vars/all.yaml
```yaml
---
# OSQuery Configuration
osquery_log_dir: "/var/log/osquery"
osquery_version: "5.11.0"

# OpenSearch Configuration
enable_opensearch_forwarding: true
opensearch_endpoint: "search-my-domain-abc123.us-east-1.es.amazonaws.com"
opensearch_region: "us-east-1"
opensearch_port: 443
opensearch_index_prefix: "osquery"
opensearch_environment: "production"

# Authentification (référence vers vault)
opensearch_use_basic_auth: true
opensearch_username: "{{ vault_opensearch_username }}"
opensearch_password: "{{ vault_opensearch_password }}"
```

## 🎯 3. Utiliser avec les Playbooks

### Méthode 1: Prompt Interactif
```bash
ansible-playbook playbook.yaml --ask-vault-pass
```

### Méthode 2: Fichier de Mot de Passe
```bash
# Créer le fichier
echo "mon_mot_de_passe_vault" > ~/.vault_pass
chmod 600 ~/.vault_pass

# Utiliser
ansible-playbook playbook.yaml --vault-password-file ~/.vault_pass
```

### Méthode 3: Variable d'Environnement
```bash
export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass
ansible-playbook playbook.yaml
```

### Méthode 4: Dans ansible.cfg
```ini
[defaults]
vault_password_file = ~/.vault_pass
```

Puis simplement:
```bash
ansible-playbook playbook.yaml
```

## 🔧 4. Gestion du Vault

### Voir le Contenu
```bash
ansible-vault view group_vars/vault.yaml
```

### Éditer le Vault
```bash
ansible-vault edit group_vars/vault.yaml
```

### Changer le Mot de Passe
```bash
ansible-vault rekey group_vars/vault.yaml
```

### Chiffrer un Fichier Existant
```bash
ansible-vault encrypt group_vars/secrets.yaml
```

### Déchiffrer un Fichier
```bash
ansible-vault decrypt group_vars/vault.yaml
```

## 🏢 5. Vaults Multiples (Multi-Environnements)

### Structure
```
ansible/
├── group_vars/
│   ├── production/
│   │   ├── vars.yaml
│   │   └── vault.yaml
│   ├── staging/
│   │   ├── vars.yaml
│   │   └── vault.yaml
│   └── development/
│       ├── vars.yaml
│       └── vault.yaml
```

### Créer les Vaults
```bash
# Production
ansible-vault create group_vars/production/vault.yaml

# Staging
ansible-vault create group_vars/staging/vault.yaml

# Development
ansible-vault create group_vars/development/vault.yaml
```

### Utiliser avec Différents Mots de Passe

**Fichier vault-passwords.yaml:**
```yaml
production: ~/.vault_pass_prod
staging: ~/.vault_pass_staging
development: ~/.vault_pass_dev
```

**Utilisation:**
```bash
# Déployer en production
ansible-playbook playbook.yaml --limit production \
  --vault-id production@~/.vault_pass_prod

# Déployer en staging
ansible-playbook playbook.yaml --limit staging \
  --vault-id staging@~/.vault_pass_staging
```

## 🔍 6. Vérifier les Variables

### Sans Exécuter le Playbook
```bash
# Voir toutes les variables
ansible all -m debug -a "var=hostvars[inventory_hostname]" --ask-vault-pass

# Voir une variable spécifique
ansible all -m debug -a "var=opensearch_password" --ask-vault-pass
```

### Mode Dry-Run
```bash
ansible-playbook playbook.yaml --check --ask-vault-pass
```

## 🎨 7. Exemple Complet

### group_vars/production/vars.yaml
```yaml
---
# Configuration Production
opensearch_endpoint: "search-prod-abc123.us-east-1.es.amazonaws.com"
opensearch_region: "us-east-1"
opensearch_environment: "production"
opensearch_index_prefix: "osquery-prod"

# Référence au vault
opensearch_use_basic_auth: true
opensearch_username: "{{ vault_opensearch_username }}"
opensearch_password: "{{ vault_opensearch_password }}"
```

### group_vars/production/vault.yaml (chiffré)
```yaml
---
vault_opensearch_username: "prod_admin"
vault_opensearch_password: "ProductionSecretPassword123!"
```

### Déploiement
```bash
ansible-playbook playbook.yaml \
  --limit production \
  --vault-password-file ~/.vault_pass_prod
```

## 🔒 8. Best Practices Sécurité

### ✅ À Faire
- ✅ Toujours chiffrer les mots de passe et clés
- ✅ Utiliser des mots de passe vault forts
- ✅ Garder les fichiers vault_pass en dehors du repo
- ✅ Utiliser `chmod 600` sur les fichiers de mots de passe
- ✅ Versionner les fichiers vault.yaml (chiffrés)
- ✅ Documenter quelles variables sont dans le vault

### ❌ À Éviter
- ❌ Ne jamais commiter les fichiers vault_pass
- ❌ Ne jamais déchiffrer et commiter un vault
- ❌ Ne pas partager les mots de passe vault par email
- ❌ Ne pas utiliser le même mot de passe pour tous les environnements
- ❌ Ne pas stocker les secrets en clair

### .gitignore
```gitignore
# Ansible Vault passwords
.vault_pass*
*vault_pass*
vault-passwords.yaml

# Secrets temporaires
*.secret
*.password
.secrets/
```

## 🚨 9. Rotation des Secrets

### Changer un Mot de Passe OpenSearch
```bash
# 1. Éditer le vault
ansible-vault edit group_vars/vault.yaml

# 2. Changer le mot de passe
vault_opensearch_password: "NewSecretPassword456!"

# 3. Redéployer les configurations
ansible-playbook playbook.yaml -e "update_config_only=true"

# 4. Redémarrer Fluent Bit
ansible all -m systemd -a "name=fluent-bit state=restarted" --become
```

### Changer le Mot de Passe du Vault
```bash
ansible-vault rekey group_vars/vault.yaml
```

## 📊 10. Debugging

### Voir les Variables Déchiffrées (Attention!)
```bash
# Uniquement pour debug en développement
ansible-playbook playbook.yaml --ask-vault-pass -e "debug_mode=true" --tags debug
```

### Tester Sans Déployer
```bash
# Vérifier que le vault est accessible
ansible-playbook playbook.yaml --ask-vault-pass --syntax-check

# Lister les tâches
ansible-playbook playbook.yaml --ask-vault-pass --list-tasks
```

## 💡 11. Alternatives et Intégrations

### AWS Secrets Manager (Alternative)
```bash
# Installer boto3
pip install boto3

# Dans le playbook
- name: Get secret from AWS Secrets Manager
  set_fact:
    opensearch_password: "{{ lookup('aws_secret', 'opensearch/password', region='us-east-1') }}"
```

### HashiCorp Vault (Alternative)
```bash
# Plugins disponibles
ansible-galaxy collection install community.hashi_vault

# Dans le playbook
- name: Get secret from Vault
  set_fact:
    opensearch_password: "{{ lookup('hashi_vault', 'secret/opensearch:password') }}"
```

## 📖 Ressources

- [Ansible Vault Documentation](https://docs.ansible.com/ansible/latest/user_guide/vault.html)
- [Best Practices for Variable Management](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html#variables-and-vaults)

---

**Note importante** : Ce fichier contient des exemples de mots de passe. **Ne l'utilisez jamais en production tel quel!**
