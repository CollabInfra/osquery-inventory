# 🎉 OSQuery Web Dashboard - Création Terminée

## ✅ Application Complète

Une application web Python/Flask complète a été créée pour interroger et visualiser les données OSQuery stockées dans OpenSearch.

## 📦 Contenu Créé

### 📁 Structure du Projet
```
webapp/
├── 📄 Application
│   ├── app.py                    # Application Flask principale
│   ├── config.py                 # Gestion de la configuration
│   └── opensearch_client.py      # Client OpenSearch
│
├── 🎨 Frontend
│   ├── templates/
│   │   └── index.html           # Interface web responsive
│   └── static/
│       ├── style.css            # Styles modernes
│       └── app.js               # Logique frontend
│
├── ⚙️ Configuration
│   ├── requirements.txt         # Dépendances Python
│   ├── .env.example             # Template de configuration
│   ├── .env                     # Configuration actuelle
│   └── .gitignore              # Exclusions Git
│
├── 🐳 Déploiement
│   ├── Dockerfile               # Image Docker
│   ├── docker-compose.yml       # Orchestration
│   ├── start.sh                 # Script de démarrage rapide
│   └── osquery-dashboard.service # Service systemd
│
├── 🧪 Tests
│   ├── test_setup.py            # Tests de pré-démarrage
│   └── TESTING.md               # Guide de tests complet
│
└── 📖 Documentation
    ├── README.md                # Documentation principale
    └── DEPLOYMENT.md            # Guide de déploiement
```

## 🚀 Démarrage Rapide

### Option 1: Script automatique (Rapide ⚡)

```bash
cd webapp
./start.sh
```

### Option 2: Manuelle

```bash
cd webapp

# 1. Installer les dépendances
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 2. Tester la configuration
python test_setup.py

# 3. Démarrer l'application
python app.py
```

### Option 3: Docker

```bash
cd webapp
docker-compose up -d
```

## 🌟 Fonctionnalités

### 📊 Dashboard
- **Statistiques en temps réel**: Événements 24h, hôtes actifs, environnements
- **Graphiques interactifs**: Visualisation temporelle avec Chart.js
- **Indicateur de santé**: Status de connexion OpenSearch

### 🔍 Recherche Avancée
- **Recherche libre**: Query string sur tous les champs
- **Filtres multiples**: Par hôte, environnement, période
- **Périodes flexibles**: 1h, 6h, 24h, 7 jours
- **Pagination**: Navigation facile dans les résultats

### 🎯 API REST

| Endpoint | Description |
|----------|-------------|
| `GET /api/health` | Status de santé |
| `GET /api/stats` | Statistiques globales |
| `GET /api/search` | Recherche de logs |
| `GET /api/hostnames` | Liste des hôtes |
| `GET /api/environments` | Liste des environnements |
| `GET /api/indices` | Liste des index |

### 🔒 Authentification
- Support **AWS IAM** pour AWS OpenSearch
- Support **Basic Auth** pour OpenSearch self-hosted
- Configuration via variables d'environnement

## 📋 Configuration

Le fichier `.env` a été créé avec les paramètres de votre infrastructure:

```bash
# OpenSearch (LocalStack pour tests)
OPENSEARCH_HOST=osquery-logs-prod.us-east-1.opensearch.localhost.localstack.cloud
OPENSEARCH_PORT=4566
OPENSEARCH_USE_SSL=false
OPENSEARCH_VERIFY_CERTS=false
OPENSEARCH_INDEX_PREFIX=osquery

# Flask
FLASK_ENV=development
FLASK_DEBUG=true
SECRET_KEY=change-this-to-a-random-secret-key
```

⚠️ **Important**: Modifiez `SECRET_KEY` avant le déploiement en production!

## 🧪 Tests

### Test de pré-démarrage
```bash
python test_setup.py
```

Vérifie:
- ✅ Dépendances installées
- ✅ Fichier .env présent
- ✅ Connexion OpenSearch
- ✅ Données disponibles

### Tests API
```bash
# Health check
curl http://localhost:5000/api/health

# Statistiques
curl http://localhost:5000/api/stats | jq

# Recherche
curl "http://localhost:5000/api/search?time_range=1h" | jq
```

## 🎨 Interface Utilisateur

L'interface web comprend:

1. **Header** avec statut de connexion en temps réel
2. **Dashboard** avec 4 cartes de statistiques
3. **Graphique** des événements par heure (24h)
4. **Formulaire de recherche** avec filtres avancés
5. **Résultats** avec affichage détaillé et pagination

### Design
- Interface **responsive** (desktop & mobile)
- Design **moderne** avec CSS personnalisé
- **Animations** fluides
- **Dark accents** pour une meilleure lisibilité
- **Charts interactifs** avec Chart.js

## 🐳 Déploiement

### Développement
```bash
python app.py
# → http://localhost:5000
```

### Production avec Gunicorn
```bash
gunicorn -w 4 -b 0.0.0.0:5000 app:app
```

### Docker
```bash
docker-compose up -d
```

### Systemd (Linux)
```bash
sudo cp osquery-dashboard.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl start osquery-dashboard
sudo systemctl enable osquery-dashboard
```

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [README.md](README.md) | Documentation complète |
| [DEPLOYMENT.md](DEPLOYMENT.md) | Guide de déploiement production |
| [TESTING.md](TESTING.md) | Guide de tests |

## 🔧 Technologies Utilisées

### Backend
- **Flask 3.0**: Framework web Python
- **opensearch-py 2.4**: Client OpenSearch
- **boto3**: SDK AWS pour authentification IAM
- **python-dotenv**: Gestion des variables d'environnement
- **gunicorn**: Serveur WSGI production

### Frontend
- **HTML5/CSS3**: Interface responsive
- **JavaScript**: Interactions dynamiques
- **Chart.js**: Graphiques interactifs
- **Fetch API**: Requêtes asynchrones

### Déploiement
- **Docker**: Containerisation
- **Docker Compose**: Orchestration
- **Systemd**: Service Linux
- **Nginx**: Reverse proxy (optionnel)

## 📊 Exemple d'Utilisation

### Scénario 1: Surveillance de sécurité
```bash
# Rechercher tous les événements de sécurité sur les dernières 24h
curl "http://localhost:5000/api/search?query=security&time_range=24h"
```

### Scénario 2: Audit d'un serveur
```bash
# Voir tous les événements d'un serveur spécifique
curl "http://localhost:5000/api/search?hostname=prod-server-01&time_range=7d"
```

### Scénario 3: Analyse d'environnement
```bash
# Comparer les événements entre environnements
curl "http://localhost:5000/api/search?environment=production"
curl "http://localhost:5000/api/search?environment=staging"
```

## 🎯 Prochaines Étapes

### Pour commencer:
1. ✅ Tester la connexion: `python test_setup.py`
2. ✅ Démarrer l'application: `./start.sh`
3. ✅ Ouvrir le navigateur: http://localhost:5000
4. ✅ Effectuer des recherches

### Pour la production:
1. 📝 Modifier `SECRET_KEY` dans `.env`
2. 🔒 Configurer HTTPS avec Nginx
3. 👤 Ajouter l'authentification utilisateur
4. 📊 Configurer le monitoring
5. 🚀 Déployer avec Docker ou systemd

## 💡 Conseils

### Performance
- Utiliser **plusieurs workers Gunicorn** (4-8 selon les CPU)
- Activer le **cache** pour les agrégations fréquentes
- Configurer des **index patterns** optimisés dans OpenSearch

### Sécurité
- **Ne jamais** committer le fichier `.env`
- Utiliser **AWS Secrets Manager** ou **HashiCorp Vault** en production
- Activer le **rate limiting** pour les API
- Implémenter une **authentification** utilisateur

### Monitoring
- Configurer des **health checks** réguliers
- Surveiller les **temps de réponse** API
- Logger les **erreurs** dans un système centralisé
- Configurer des **alertes** pour les pannes

## 🐛 Dépannage

### Problème: "Cannot connect to OpenSearch"
```bash
# Vérifier la connexion
python test_setup.py

# Vérifier les logs
python app.py  # Mode debug
```

### Problème: "No data found"
```bash
# Lister les indices
curl http://localhost:5000/api/indices

# Vérifier que Fluent Bit envoie des données
tail -f /var/log/fluent-bit/fluent-bit.log
```

### Problème: Port déjà utilisé
```bash
# Changer le port dans .env
PORT=8080

# Ou spécifier au lancement
PORT=8080 python app.py
```

## 📞 Support

Pour toute question:
1. Consulter la [documentation](README.md)
2. Vérifier le [guide de tests](TESTING.md)
3. Lire le [guide de déploiement](DEPLOYMENT.md)

## ✨ Félicitations!

Votre dashboard OSQuery est prêt à l'emploi! 🎉

```
     ┌─────────────────────────────────────┐
     │  🎯 OSQuery Dashboard est prêt!    │
     │                                     │
     │  📊 Visualisation: ✅              │
     │  🔍 Recherche: ✅                  │
     │  📡 API: ✅                        │
     │  🐳 Docker: ✅                     │
     │  📖 Documentation: ✅              │
     │                                     │
     │  🚀 Démarrez avec: ./start.sh      │
     │  🌐 Ouvrez: http://localhost:5000  │
     └─────────────────────────────────────┘
```
