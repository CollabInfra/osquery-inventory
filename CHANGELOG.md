# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/lang/fr/).

## [1.0.0] - 2026-02-07

### Ajouté - Version Initiale Complète

#### Installation OSQuery
- Support multi-plateformes : Linux (Debian/Ubuntu, RedHat/CentOS), macOS, Windows
- Détection automatique de l'OS avec include_tasks conditionnel
- Installation via gestionnaires de paquets natifs (apt, yum, homebrew, msi)
- Configuration automatique avec templates Jinja2

#### Configuration OSQuery
- Templates de configuration pour chaque plateforme :
  - `osquery-linux.conf.j2` : Configuration Linux complète
  - `osquery-macos.conf.j2` : Configuration macOS optimisée
  - `osquery-windows.conf.j2` : Configuration Windows
- Requêtes planifiées pré-configurées :
  - Informations système (toutes les heures)
  - Surveillance des processus (toutes les 10 minutes)
  - Sessions utilisateurs (toutes les 10 minutes)
  - Connexions réseau (toutes les 10 minutes)
  - Événements fichiers système (toutes les 5 minutes - Linux)
- Support des packs de sécurité OSQuery
- Decorators pour enrichissement automatique des logs

#### Intégration AWS OpenSearch
- Installation automatique de Fluent Bit sur toutes les plateformes
- Tâches d'installation Fluent Bit :
  - `fluent-bit-debian.yaml` : Installation pour Debian/Ubuntu
  - `fluent-bit-redhat.yaml` : Installation pour RedHat/CentOS
  - `fluent-bit-macos.yaml` : Installation pour macOS
  - `fluent-bit-windows.yaml` : Installation pour Windows
- Templates de configuration Fluent Bit :
  - `fluent-bit-linux.conf.j2` : Configuration Linux
  - `fluent-bit-macos.conf.j2` : Configuration macOS
  - `fluent-bit-windows.conf.j2` : Configuration Windows
  - `fluent-bit-parsers.conf.j2` : Parsers JSON et logs OSQuery
- Support authentification AWS IAM pour OpenSearch
- Support authentification Basic Auth pour OpenSearch auto-hébergé
- Parsing automatique des logs JSON
- Enrichissement avec métadonnées AWS EC2
- Format Logstash avec rotation quotidienne des indices
- Variables configurables pour endpoint, région, index prefix, etc.

#### Gestion des Services
- Handlers pour redémarrage automatique :
  - OSQuery (systemd, launchd, Windows Service)
  - Fluent Bit (systemd, homebrew services, Windows Service)
- Démarrage automatique au boot du système
- Support multi-plateformes pour les gestionnaires de services

#### Configuration et Variables
- `defaults/main.yaml` : Variables par défaut avec documentation
- `group_vars/all.yaml.example` : Exemple de configuration complète
- Support variables d'environnement (production, staging, development)
- Variables conditionnelles pour OpenSearch forwarding

#### Playbooks et Automation
- `playbook.yaml` : Playbook principal standard
- `playbook-opensearch.yaml` : Playbook avec vérifications OpenSearch
- Pré-tâches pour validation des variables requises
- Post-tâches pour vérification des services
- Support mode dry-run (--check)

#### Inventaires
- `inventory.ini` : Inventaire exemple multi-plateformes
- `inventory-opensearch.ini.example` : Inventaire avec OpenSearch activé
- `inventory-multi-env.ini.example` : Inventaire multi-environnements
- Support groupes d'hôtes et variables par groupe

#### Scripts d'Installation
- `setup.sh` : Script d'installation pour Linux/macOS
- `setup.ps1` : Script d'installation pour Windows
- `preflight-check.sh` : Script de vérification pré-déploiement
- Installation automatique des collections Ansible requises

#### Documentation Complète
- `README.md` : Documentation principale avec guide complet
- `PROJECT-SUMMARY.md` : Résumé technique du projet
- `CHANGELOG.md` : Ce fichier
- `docs/README.md` : Index de la documentation
- `docs/QUICKSTART-OPENSEARCH.md` : Guide démarrage rapide (5 minutes)
- `docs/OPENSEARCH.md` : Guide complet AWS OpenSearch (30+ pages)
- `docs/CHEATSHEET.md` : Aide-mémoire des commandes
- `docs/ANSIBLE-VAULT.md` : Guide sécurité et gestion des secrets

#### Sécurité
- Support Ansible Vault pour secrets
- Documentation complète sur l'utilisation du Vault
- TLS/SSL activé par défaut pour OpenSearch
- Permissions appropriées sur tous les fichiers de configuration
- Exemples de configuration sécurisée multi-environnements

#### Fichiers Supports
- `requirements.yaml` : Collections Ansible requises
- `ansible.cfg` : Configuration Ansible optimisée
- `.gitignore` : Exclusions appropriées pour Git
- `meta/main.yaml` : Métadonnées du rôle Ansible

#### Features Additionnelles
- Support multi-environnements (production, staging, development)
- Configuration par groupe d'hôtes
- Variables conditionnelles pour activation/désactivation d'OpenSearch
- Tags pour filtrage des tâches
- Idempotence complète de toutes les tâches
- Messages d'information et de debug
- Gestion d'erreurs appropriée

### Documentation

#### Guides Utilisateur
- Guide de démarrage rapide pour déploiement en moins de 5 minutes
- Guide complet AWS OpenSearch avec architecture, configuration, monitoring
- Aide-mémoire avec commandes fréquentes pour opérations quotidiennes
- Guide Ansible Vault avec exemples et best practices

#### Exemples et Cas d'Usage
- Surveillance de sécurité
- Conformité IT
- Inventaire dynamique
- Détection d'incidents
- Configuration multi-régions AWS

#### Troubleshooting
- Section dépannage complète dans OPENSEARCH.md
- Diagnostics pour OSQuery, Fluent Bit, OpenSearch
- Vérifications réseau et AWS
- Solutions aux erreurs courantes

### Infrastructure as Code

#### Best Practices Implémentées
- ✅ Idempotence Ansible stricte
- ✅ Templates réutilisables
- ✅ Variables paramétrables
- ✅ Handlers pour changements
- ✅ Tests avec --check
- ✅ Documentation inline
- ✅ Gestion des erreurs
- ✅ Multi-plateformes

### Métriques

#### Couverture
- 4 systèmes d'exploitation supportés
- 8 tâches d'installation (OSQuery + Fluent Bit)
- 7 templates de configuration
- 2 playbooks principaux
- 5 guides de documentation
- 3 inventaires d'exemple

#### Performance
- Déploiement : ~5-10 minutes par serveur
- Ressources OSQuery : ~50-100 MB RAM
- Ressources Fluent Bit : ~20-50 MB RAM
- Latence logs → OpenSearch : <30 secondes

---

## Format des Versions Futures

### [X.Y.Z] - YYYY-MM-DD

#### Ajouté
- Nouvelles fonctionnalités

#### Modifié
- Changements dans les fonctionnalités existantes

#### Déprécié
- Fonctionnalités bientôt supprimées

#### Supprimé
- Fonctionnalités retirées

#### Corrigé
- Corrections de bugs

#### Sécurité
- Changements liés à la sécurité

---

## Roadmap Future (À Venir)

### Version 1.1.0 (Prévue)
- [ ] Support Elasticsearch (en plus d'OpenSearch)
- [ ] Dashboards OpenSearch pré-configurés
- [ ] Alerting automatique (PagerDuty, Slack)
- [ ] Tests automatisés avec Molecule
- [ ] CI/CD avec GitHub Actions

### Version 1.2.0 (Prévue)
- [ ] Support Kubernetes/containers
- [ ] Métriques Prometheus pour OSQuery
- [ ] Support Splunk/Datadog
- [ ] Packs OSQuery personnalisés supplémentaires
- [ ] Documentation vidéo

### Version 2.0.0 (Future)
- [ ] Interface web de gestion
- [ ] API REST pour configuration
- [ ] Gestion centralisée des configs
- [ ] Marketplace de packs OSQuery
- [ ] Support Terraform

---

**Note** : Les versions suivent le Semantic Versioning :
- **MAJOR** : Changements incompatibles avec versions précédentes
- **MINOR** : Ajout de fonctionnalités rétro-compatibles
- **PATCH** : Corrections de bugs rétro-compatibles

[1.0.0]: https://github.com/your-org/osquery-ansible/releases/tag/v1.0.0
