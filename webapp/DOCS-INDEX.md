# OSQuery Dashboard - Index de Documentation

## 📚 Documentation Principale

| Document | Description |
|----------|-------------|
| [README.md](README.md) | Documentation complète de l'application |
| [QUICKSTART.md](QUICKSTART.md) | Guide de démarrage rapide |
| [DEPLOYMENT.md](DEPLOYMENT.md) | Guide de déploiement en production |
| [TESTING.md](TESTING.md) | Guide de tests et validation |

## 🔄 Migration Poetry

| Document | Description |
|----------|-------------|
| [POETRY-MIGRATION.md](POETRY-MIGRATION.md) | Guide complet de la migration vers Poetry |
| [MIGRATION-SUMMARY.md](MIGRATION-SUMMARY.md) | Résumé rapide de la migration |

## ⚙️ Configuration

| Fichier | Description |
|---------|-------------|
| [pyproject.toml](pyproject.toml) | Configuration Poetry (dépendances, métadonnées) |
| [requirements.txt](requirements.txt) | Dépendances pip (conservé pour compatibilité) |
| [.env.example](.env.example) | Template de configuration |
| [.env](.env) | Configuration actuelle (ne pas committer) |

## 🐳 Docker

| Fichier | Description |
|---------|-------------|
| [Dockerfile](Dockerfile) | Image Docker avec Poetry |
| [Dockerfile.legacy](Dockerfile.legacy) | Image Docker avec pip |
| [docker-compose.yml](docker-compose.yml) | Orchestration Docker (Poetry) |
| [docker-compose.legacy.yml](docker-compose.legacy.yml) | Orchestration Docker (pip) |

## 🚀 Scripts de Démarrage

| Script | Description |
|--------|-------------|
| [start.sh](start.sh) | Démarrage avec Poetry (recommandé) |
| [start-legacy.sh](start-legacy.sh) | Démarrage avec pip |
| [test_setup.py](test_setup.py) | Tests de pré-démarrage |

## 📁 Structure du Code

| Répertoire/Fichier | Description |
|-------------------|-------------|
| [app.py](app.py) | Application Flask principale |
| [config.py](config.py) | Gestion de la configuration |
| [opensearch_client.py](opensearch_client.py) | Client OpenSearch |
| [templates/](templates/) | Templates HTML |
| [static/](static/) | CSS, JavaScript, images |

## 🔧 Déploiement Production

| Fichier | Description |
|---------|-------------|
| [osquery-dashboard.service](osquery-dashboard.service) | Service systemd Linux |

## 🎯 Guides par Tâche

### Je veux démarrer rapidement
1. Lire [QUICKSTART.md](QUICKSTART.md)
2. Exécuter `./start.sh`

### Je veux déployer en production
1. Lire [DEPLOYMENT.md](DEPLOYMENT.md)
2. Configurer `.env` avec les vrais paramètres
3. Utiliser Docker ou systemd

### Je veux comprendre Poetry
1. Lire [MIGRATION-SUMMARY.md](MIGRATION-SUMMARY.md) pour un aperçu
2. Lire [POETRY-MIGRATION.md](POETRY-MIGRATION.md) pour tous les détails

### Je préfère utiliser pip
1. Utiliser `./start-legacy.sh`
2. Ou `docker-compose -f docker-compose.legacy.yml up -d`

### Je veux tester l'application
1. Lire [TESTING.md](TESTING.md)
2. Exécuter `python test_setup.py`

### Je veux contribuer
1. Lire [README.md](README.md) section "Développement"
2. Installer Poetry : `poetry install`
3. Utiliser les outils de qualité : `poetry run black .`, `poetry run flake8`

## 🆘 Aide Rapide

### Commandes Poetry Essentielles
```bash
poetry install              # Installer les dépendances
poetry run python app.py    # Lancer l'application
poetry add package          # Ajouter une dépendance
poetry show                 # Lister les dépendances
```

### Commandes pip (Legacy)
```bash
pip install -r requirements.txt
python app.py
```

### Docker
```bash
# Poetry
docker-compose up -d

# pip
docker-compose -f docker-compose.legacy.yml up -d
```

## 📊 Arborescence Complète

```
webapp/
├── 📖 Documentation
│   ├── README.md
│   ├── QUICKSTART.md
│   ├── DEPLOYMENT.md
│   ├── TESTING.md
│   ├── POETRY-MIGRATION.md
│   ├── MIGRATION-SUMMARY.md
│   └── DOCS-INDEX.md (ce fichier)
│
├── ⚙️ Configuration
│   ├── pyproject.toml
│   ├── requirements.txt
│   ├── .env.example
│   ├── .env
│   └── .gitignore
│
├── 🐳 Docker
│   ├── Dockerfile
│   ├── Dockerfile.legacy
│   ├── docker-compose.yml
│   └── docker-compose.legacy.yml
│
├── 🚀 Scripts
│   ├── start.sh
│   ├── start-legacy.sh
│   └── test_setup.py
│
├── 💻 Code
│   ├── app.py
│   ├── config.py
│   ├── opensearch_client.py
│   ├── templates/
│   │   └── index.html
│   └── static/
│       ├── style.css
│       └── app.js
│
└── 🔧 Déploiement
    └── osquery-dashboard.service
```

## 🎯 Checklist de Démarrage

- [ ] Lire [QUICKSTART.md](QUICKSTART.md)
- [ ] Copier `.env.example` vers `.env`
- [ ] Éditer `.env` avec vos paramètres OpenSearch
- [ ] Exécuter `./start.sh` ou `./start-legacy.sh`
- [ ] Ouvrir http://localhost:5001
- [ ] Vérifier que les données s'affichent

## 📝 Notes

- Tous les fichiers `.md` utilisent le format Markdown
- La documentation est en français
- Poetry est recommandé mais pip reste supporté
- Docker fonctionne avec les deux (Poetry par défaut)
