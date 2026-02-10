# OSQuery Web Dashboard

Application web pour visualiser et interroger les données OSQuery collectées dans OpenSearch.

## 📋 Fonctionnalités

> **Note** : Ce projet utilise maintenant **Poetry** pour la gestion des dépendances. Voir [POETRY-MIGRATION.md](POETRY-MIGRATION.md) pour tous les détails. Le support pip via `requirements.txt` est conservé pour compatibilité.

- **Tableau de bord en temps réel** : Statistiques et visualisations des événements OSQuery
- **Recherche avancée** : Filtrage par hôte, environnement et période
- **Graphiques interactifs** : Visualisation temporelle des événements
- **API REST** : Endpoints pour interroger les données programmatiquement
- **Interface responsive** : Fonctionne sur desktop et mobile

## 🚀 Installation

### Prérequis

- Python 3.8+
- Poetry (recommandé) ou pip
- Accès à un cluster OpenSearch avec les données OSQuery
- (Optionnel) Credentials AWS pour l'authentification IAM

### Installation des dépendances

#### Avec Poetry (Recommandé)

```bash
cd webapp

# Installer Poetry si nécessaire
curl -sSL https://install.python-poetry.org | python3 -

# Installer les dépendances
poetry install
```

#### Avec pip (Legacy)

```bash
cd webapp
pip install -r requirements.txt
```

### Configuration

1. Copier le fichier d'exemple de configuration :

```bash
cp .env.example .env
```

2. Éditer le fichier `.env` avec vos paramètres :

```bash
# Configuration OpenSearch
OPENSEARCH_HOST=your-opensearch-endpoint.com
OPENSEARCH_PORT=443
OPENSEARCH_USE_SSL=true
OPENSEARCH_VERIFY_CERTS=true
OPENSEARCH_INDEX_PREFIX=osquery-

# AWS (pour authentification IAM)
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key

# Ou Basic Auth
# OPENSEARCH_USERNAME=admin
# OPENSEARCH_PASSWORD=changeme

# Flask
SECRET_KEY=votre-clé-secrète-aléatoire
```

## 🎯 Utilisation

### Démarrage rapide avec script

```bash
# Avec Poetry (recommandé)
./start.sh

# Avec pip (legacy)
./start-legacy.sh
```

### Démarrage en mode développement

#### Avec Poetry
```bash
poetry run python app.py
```

#### Avec pip
```bash
python app.py
```

L'application sera accessible sur http://localhost:5000

### Démarrage en mode production

#### Avec Poetry
```bash
poetry run gunicorn -w 4 -b 0.0.0.0:5000 app:app
```

#### Avec pip
```bash
gunicorn -w 4 -b 0.0.0.0:5000 app:app
```

### Variables d'environnement importantes

| Variable | Description | Défaut |
|----------|-------------|--------|
| `OPENSEARCH_HOST` | Endpoint OpenSearch | `localhost` |
| `OPENSEARCH_PORT` | Port OpenSearch | `9200` |
| `OPENSEARCH_USE_SSL` | Utiliser HTTPS | `true` |
| `OPENSEARCH_INDEX_PREFIX` | Préfixe des index | `osquery-` |
| `AWS_REGION` | Région AWS | `us-east-1` |

## 📡 API Endpoints

### GET /api/health
Vérifier l'état de santé de l'application et de la connexion OpenSearch.

**Réponse :**
```json
{
  "status": "healthy",
  "opensearch": true
}
```

### GET /api/stats
Obtenir les statistiques globales.

**Réponse :**
```json
{
  "total_last_24h": 15420,
  "hostnames_count": 25,
  "environments_count": 3,
  "by_hour": [...]
}
```

### GET /api/search
Rechercher dans les logs OSQuery.

**Paramètres :**
- `query` (optionnel) : Recherche libre
- `hostname` (optionnel) : Filtrer par hôte
- `environment` (optionnel) : Filtrer par environnement
- `time_range` (défaut: `1h`) : Plage temporelle (`1h`, `6h`, `24h`, `7d`)
- `size` (défaut: `100`) : Nombre de résultats
- `offset` (défaut: `0`) : Position pour la pagination

**Exemple :**
```bash
curl "http://localhost:5000/api/search?hostname=server01&time_range=24h&size=50"
```

**Réponse :**
```json
{
  "total": 1245,
  "hits": [...]
}
```

### GET /api/hostnames
Liste des hôtes uniques.

**Réponse :**
```json
{
  "hostnames": ["server01", "server02", ...]
}
```

### GET /api/environments
Liste des environnements uniques.

**Réponse :**
```json
{
  "environments": ["production", "staging", ...]
}
```

### GET /api/indices
Liste des index OpenSearch.

**Réponse :**
```json
{
  "indices": ["osquery-2024.01.01", ...]
}
```

## 🐳 Déploiement Docker

### Avec Poetry (par défaut)

Créer un `Dockerfile` (déjà inclus avec support Poetry):

```dockerfile
FROM python:3.12-slim
WORKDIR /app
RUN pip install --no-cache-dir poetry==1.7.1
COPY pyproject.toml poetry.lock* ./
RUN poetry config virtualenvs.create false
RUN poetry install --no-dev --no-interaction --no-ansi
COPY . .
CMD ["poetry", "run", "gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "app:app"]
```

Build et run :

```bash
docker build -t osquery-dashboard .
docker run -p 5000:5000 --env-file .env osquery-dashboard
```

Ou avec Docker Compose :

```bash
docker-compose up -d
```

### Avec pip (legacy)

Pour utiliser pip au lieu de Poetry :

```bash
# Avec Docker
docker build -f Dockerfile.legacy -t osquery-dashboard .

# Avec Docker Compose
docker-compose -f docker-compose.legacy.yml up -d
```

## 🔒 Sécurité

### Authentification IAM (Recommandé pour AWS)

Pour utiliser l'authentification IAM avec AWS OpenSearch :

1. Configurer les variables AWS dans `.env`
2. S'assurer que le rôle IAM a les permissions nécessaires :

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "es:ESHttpGet",
        "es:ESHttpPost"
      ],
      "Resource": "arn:aws:es:region:account:domain/domain-name/*"
    }
  ]
}
```

### Basic Auth

Pour un OpenSearch self-hosted avec Basic Auth :

```bash
OPENSEARCH_USERNAME=admin
OPENSEARCH_PASSWORD=votre-mot-de-passe
```

### Recommandations

- **Ne jamais committer** le fichier `.env` dans Git
- Utiliser des **secrets managers** en production (AWS Secrets Manager, HashiCorp Vault, etc.)
- Activer **HTTPS** en production
- Implémenter une **authentification utilisateur** pour l'accès au dashboard

## 📊 Structure du projet

```
webapp/
├── app.py                 # Application Flask principale
├── config.py             # Gestion de la configuration
├── opensearch_client.py  # Client OpenSearch
├── requirements.txt      # Dépendances Python
├── .env.example         # Exemple de configuration
├── templates/
│   └── index.html       # Interface web
└── static/
    ├── style.css        # Styles CSS
    └── app.js          # JavaScript frontend
```

## 🛠️ Développement

### Ajouter de nouvelles fonctionnalités

1. **Nouveaux endpoints API** : Modifier `app.py`
2. **Nouvelles requêtes OpenSearch** : Modifier `opensearch_client.py`
3. **Interface utilisateur** : Modifier `templates/index.html` et `static/`

### Tests

```bash
# Tester la connexion OpenSearch
curl http://localhost:5000/api/health

# Tester les statistiques
curl http://localhost:5000/api/stats

# Tester la recherche
curl "http://localhost:5000/api/search?time_range=1h"
```

## 🐛 Dépannage

### Problème : "Cannot connect to OpenSearch"

- Vérifier que `OPENSEARCH_HOST` et `OPENSEARCH_PORT` sont corrects
- Vérifier les credentials AWS ou Basic Auth
- Vérifier les règles de sécurité/firewall

### Problème : "No data found"

- Vérifier que Fluent Bit envoie bien les données à OpenSearch
- Vérifier le préfixe d'index `OPENSEARCH_INDEX_PREFIX`
- Consulter les logs de l'application

### Problème : SSL Certificate error

```bash
OPENSEARCH_VERIFY_CERTS=false
```

⚠️ À utiliser uniquement en développement

## 📝 Licence

Ce projet fait partie du système de monitoring OSQuery.

## 🤝 Contribution

Pour contribuer :

1. Fork le projet
2. Créer une branche (`git checkout -b feature/nouvelle-fonctionnalite`)
3. Commit les changements (`git commit -m 'Ajout nouvelle fonctionnalité'`)
4. Push vers la branche (`git push origin feature/nouvelle-fonctionnalite`)
5. Créer une Pull Request
