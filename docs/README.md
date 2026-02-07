# Documentation OSQuery Ansible Deployment

Ce répertoire contient la documentation complète pour le déploiement d'OSQuery avec Ansible.

## 📚 Guides Disponibles

### [QUICKSTART-OPENSEARCH.md](QUICKSTART-OPENSEARCH.md)
**Guide de démarrage rapide - 5 minutes**

Déploiement express d'OSQuery avec envoi des logs vers AWS OpenSearch.

- ✅ Instructions pas à pas
- ✅ Configuration minimale requise
- ✅ Vérifications et tests
- ✅ Commandes essentielles

**Idéal pour** : Premier déploiement, proof of concept, tests rapides

---

### [OPENSEARCH.md](OPENSEARCH.md)
**Guide complet AWS OpenSearch**

Documentation détaillée sur l'intégration OpenSearch, incluant :

- 📋 Architecture et fonctionnement
- 🚀 Configuration AWS (domaine, IAM, security groups)
- ⚙️ Configuration Ansible avancée
- 🔍 Vérification et monitoring
- 📊 Dashboards et visualisations
- 🔧 OpenSearch auto-hébergé (Basic Auth)
- 🛠️ Dépannage approfondi
- 📈 Optimisations et best practices
- 📝 Exemples de requêtes

**Idéal pour** : Configuration de production, troubleshooting, optimisations

---

### [ARCHITECTURE.md](ARCHITECTURE.md)
**Architecture système complète**

Diagrammes et explications détaillées de l'architecture :

- 📐 Diagramme d'architecture global
- 🔄 Flux de données détaillé (OSQuery → Fluent Bit → OpenSearch)
- 🎯 Flux de déploiement Ansible
- 🔐 Flux d'authentification AWS
- 📊 Structure des données dans OpenSearch
- 🎨 Exemples de dashboards

**Idéal pour** : Compréhension système, onboarding équipe, documentation architecture

---

### [CHEATSHEET.md](CHEATSHEET.md)
**Aide-mémoire des commandes**

Référence rapide des commandes les plus utilisées :

- 🚀 Déploiement et gestion
- 🔍 Vérifications et diagnostics
- 📊 Requêtes OpenSearch
- 🛠️ Dépannage
- 📦 Gestion des packages
- 🔐 Sécurité et Vault
- 📈 Performance et métriques

**Idéal pour** : Référence quotidienne, rappels rapides

---

### [ANSIBLE-VAULT.md](ANSIBLE-VAULT.md)
**Guide Ansible Vault pour les secrets**

Sécurisation des mots de passe et credentials :

- 🔐 Création et gestion des vaults
- 📝 Structure recommandée
- 🏢ARCHITECTURE.md               # Diagrammes d'architecture système
├──  Vaults multi-environnements
- 🔒 Best practices de sécurité
- 🚨 Rotation des secrets
- 💡 Alternatives (AWS Secrets Manager, HashiCorp Vault)

**Idéal pour** : Sécurisation de production, gestion des secrets

---

## 🗂️ Organisation de la Documentation

```
docs/
├── README.md                      # Ce fichier - index de la documentation
├── QUICKSTART-OPENSEARCH.md      # Démarrage rapide OpenSearch (5 min)
├── OPENSEARCH.md                 # Guide complet OpenSearch
├── CHEATSHEET.md                 # Aide-mémoire des commandes
└── ANSIBLE-VAULT.md              # Guide sécurité avec Ansible Vault
```

## 🔗 Documentation Externe

### OSQuery
- [Documentation officielle OSQuery](https://osquery.io/docs/)
- [Schéma des tables OSQuery](https://osquery.io/schema/)
- [Packs OSQuery](https://github.com/osquery/osquery/tree/master/packs)

### Ansible
- [Documentation Ansible](https://docs.ansible.com/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Collection community.general](https://docs.ansible.com/ansible/latest/collections/community/general/)
- [Collection ansible.windows](https://docs.ansible.com/ansible/latest/collections/ansible/windows/)

### AWS OpenSearch
- [AWS OpenSearch Service](https://docs.aws.amazon.com/opensearch-service/)
- [OpenSearch Documentation](https://opensearch.org/docs/latest/)
- [OpenSearch Dashboards](https://opensearch.org/docs/latest/dashboards/)

### Fluent Bit
- [Documentation Fluent Bit](https://docs.fluentbit.io/)
- [Fluent Bit OpenSearch Output](https://docs.fluentbit.io/manual/pipeline/outputs/opensearch)
- [Fluent Bit Parsers](https://docs.fluentbit.io/manual/pipeline/parsers)

## 📖 Parcours d'Apprentissage Recommandé

### Niveau Débutant
1. Lire le [README principal](../README.md)
2. Suivre [QUICKSTART-OPENSEARCH.md](QUICKSTART-OPENSEARCH.md)
3. Effectuer un déploiement de test

### Niveau Intermédiaire
1. Lire [OPENSEARCH.md](OPENSEARCH.md) en entier
2. Configurer l'authentification IAM
3. Créer des dashboards personnalisés
4. Implémenter la rotation des indices

### Niveau Avancé
1. Optimiser les performances Fluent Bit
2. Configurer des alertes complexes
3. Créer des packs OSQuery personnalisés
4. Implémenter le multi-régions
5. Sécuriser avec Ansible Vault

## 🎯 Cas d'Usage Principaux

### Surveillance de Sécurité
- Monitoring des processus suspects
- Détection d'intrusions
- Audit des connexions réseau
- Surveillance des modifications de fichiers

### Conformité IT
- Inventaire des logiciels installés
- Vérification des configurations
- Audit des accès utilisateurs
- Rapports de conformité

### Gestion d'Infrastructure
- Inventaire matériel
- Monitoring des performances
- Détection de déviations de configuration
- Gestion des patches

## 💡 Conseils et Best Practices

### Planification
- ✅ Commencer petit (quelques serveurs)
- ✅ Tester en staging avant production
- ✅ Documenter vos personnalisations
- ✅ Utiliser Ansible Vault pour les secrets

### Monitoring
- ✅ Configurer des alertes dans OpenSearch
- ✅ Monitorer l'utilisation des ressources
- ✅ Vérifier régulièrement les logs Fluent Bit
- ✅ Surveiller la taille des indices OpenSearch

### Sécurité
- ✅ Utiliser l'authentification IAM (AWS)
- ✅ Chiffrer les communications (TLS)
- ✅ Restreindre les accès réseau
- ✅ Auditer régulièrement les configurations

### Performance
- ✅ Ajuster les intervalles de requêtes OSQuery
- ✅ Optimiser les buffers Fluent Bit
- ✅ Implémenter la rotation des indices
- ✅ Utiliser des instances appropriées pour OpenSearch

## 🤝 Contribution

Des questions ? Des améliorations à suggérer ?

1. Consultez d'abord la documentation existante
2. Vérifiez les exemples dans `ansible/`
3. Testez vos modifications en local
4. Documentez vos changements

## 📞 Support

Pour obtenir de l'aide :

1. **Documentation** : Consultez les guides ci-dessus
2. **Exemples** : Voir `ansible/inventory-*.ini.example`
3. **Logs** : Vérifiez les logs des services
4. **Dépannage** : Section troubleshooting dans [OPENSEARCH.md](OPENSEARCH.md)

---

**Dernière mise à jour** : Février 2026
