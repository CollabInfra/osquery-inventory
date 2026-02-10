# Guide de Test - OSQuery Dashboard

Ce guide explique comment tester l'application avant et après le déploiement.

## 🧪 Tests Locaux

### 1. Installation et Configuration

#### Avec Poetry (Recommandé)

```bash
cd webapp

# Installer Poetry si nécessaire
curl -sSL https://install.python-poetry.org | python3 -

# Installer les dépendances
poetry install

# Copier et configurer .env
cp .env.example .env
# Éditer .env avec vos paramètres
```

#### Avec pip (Legacy)

```bash
cd webapp

# Créer l'environnement virtuel
python3 -m venv venv
source venv/bin/activate  # Sur Windows: venv\Scripts\activate

# Installer les dépendances
pip install -r requirements.txt

# Copier et configurer .env
cp .env.example .env
# Éditer .env avec vos paramètres
```

### 2. Vérifier la connexion OpenSearch

Tester la connexion avant de lancer l'application :

```python
# test_connection.py
from config import Config
from opensearch_client import OSQueryOpenSearchClient

config = Config()
client = OSQueryOpenSearchClient(config)

# Test de santé
if client.health_check():
    print("✅ Connexion OpenSearch réussie")
    
    # Lister les indices
    indices = client.get_indices()
    print(f"📊 Indices trouvés: {len(indices)}")
    for idx in indices:
        print(f"  - {idx}")
    
    # Obtenir les statistiques
    stats = client.get_stats()
    print(f"📈 Événements (24h): {stats.get('total_last_24h', 'N/A')}")
    print(f"🖥️  Hôtes: {stats.get('hostnames_count', 'N/A')}")
else:
    print("❌ Impossible de se connecter à OpenSearch")
```

Exécuter :
```bash
# Avec Poetry
poetry run python test_connection.py

# Avec pip
python test_connection.py
#### Avec Poetry
```bash
poetry run python app.py
```

#### Avec pip
```

### 3. Démarrer l'application

```bash
python app.py
```

L'application devrait démarrer sur http://localhost:5000

### 4. Tests API avec curl

#### Health Check
```bash
curl http://localhost:5000/api/health
# Résultat attendu: {"status": "healthy", "opensearch": true}
```

#### Statistiques
```bash
curl http://localhost:5000/api/stats | jq
```

#### Liste des hôtes
```bash
curl http://localhost:5000/api/hostnames | jq
```

#### Liste des environnements
```bash
curl http://localhost:5000/api/environments | jq
```

#### Recherche de logs
```bash
# Recherche simple (dernière heure)
curl "http://localhost:5000/api/search?time_range=1h" | jq

# Recherche avec filtres
curl "http://localhost:5000/api/search?hostname=server01&time_range=24h&size=10" | jq

# Recherche par mot-clé
curl "http://localhost:5000/api/search?query=error&time_range=6h" | jq
```

## 🌐 Tests Interface Web

### 1. Accéder au Dashboard

Ouvrir http://localhost:5000 dans un navigateur.

### 2. Vérifier les Sections

- [ ] **Header** : Logo et statut de connexion (vert = connecté)
- [ ] **Statistiques** : 4 cartes avec les chiffres
- [ ] **Graphique** : Graphique linéaire des événements par heure
- [ ] **Filtres** : Dropdowns avec les hôtes et environnements
- [ ] **Recherche** : Champ de recherche fonctionnel

### 3. Tester les Fonctionnalités

#### Test 1 : Recherche basique
1. Cliquer sur "Rechercher" sans aucun filtre
2. Vérifier que des résultats s'affichent
3. Vérifier la pagination si > 50 résultats

#### Test 2 : Filtrage par hôte
1. Sélectionner un hôte dans le dropdown
2. Cliquer sur "Rechercher"
3. Vérifier que tous les résultats concernent cet hôte

#### Test 3 : Filtrage par période
1. Changer la période (1h, 6h, 24h, 7d)
2. Cliquer sur "Rechercher"
3. Vérifier que les résultats correspondent à la période

#### Test 4 : Recherche texte libre
1. Entrer un mot-clé (ex: "process", "error")
2. Cliquer sur "Rechercher"
3. Vérifier que les résultats contiennent le mot-clé

#### Test 5 : Navigation
1. Faire une recherche avec beaucoup de résultats
2. Tester la pagination (Suivant, Précédent)
3. Tester les numéros de page

### 4. Tests de Performance

```bash
# Installer Apache Bench
sudo apt install apache2-utils  # Debian/Ubuntu
brew install ab                  # macOS

# Test de charge simple
ab -n 100 -c 10 http://localhost:5000/api/health

# Test de l'API de recherche
ab -n 50 -c 5 "http://localhost:5000/api/search?time_range=1h"
```

## 🐳 Tests Docker

### 1. Build et Run

```bash
cd webapp

# Build
docker build -t osquery-dashboard:test .

# Run
docker run -d \
  --name osquery-dashboard-test \
  -p 5000:5000 \
  --env-file .env \
  osquery-dashboard:test

# Vérifier les logs
docker logs -f osquery-dashboard-test

# Tester
curl http://localhost:5000/api/health

# Nettoyer
docker stop osquery-dashboard-test
docker rm osquery-dashboard-test
```

### 2. Docker Compose

```bash
# Démarrer
docker-compose up -d

# Vérifier le statut
docker-compose ps

# Voir les logs
docker-compose logs -f

# Tester
curl http://localhost:5000/api/health

# Arrêter
docker-compose down
```

## 🔍 Tests de Régression

### Scénarios de test complets

#### Scénario 1 : Workflow complet utilisateur
1. Ouvrir le dashboard
2. Vérifier que les stats se chargent (< 3 secondes)
3. Effectuer une recherche sans filtre
4. Affiner avec un filtre hôte
5. Changer la période
6. Naviguer entre les pages
7. Vérifier qu'aucune erreur n'apparaît dans la console

#### Scénario 2 : Gestion des erreurs
1. Arrêter OpenSearch (si possible en test)
2. Vérifier que le statut passe à "Déconnecté"
3. Tenter une recherche
4. Vérifier qu'un message d'erreur approprié s'affiche

#### Scénario 3 : Performance
1. Lancer une recherche sur 7 jours avec beaucoup de données
2. Vérifier que la page reste responsive
3. Mesurer le temps de réponse
4. Vérifier que la pagination fonctionne correctement

## 📊 Tests de Production

### Avant le déploiement

- [ ] Tous les tests locaux passent
- [ ] Tests Docker réussis
- [ ] Configuration `.env` validée pour la production
- [ ] SECRET_KEY changé (pas la valeur par défaut)
- [ ] SSL/TLS configuré et testé
- [ ] Authentification testée (si activée)

### Après le déploiement

```bash
# Remplacer par votre URL de production
PROD_URL="https://dashboard.example.com"

# Health check
curl -f $PROD_URL/api/health || echo "❌ Health check failed"

# Test HTTPS
curl -I $PROD_URL | grep "HTTP/2 200" || echo "❌ HTTPS failed"

# Test de l'API
curl "$PROD_URL/api/stats" | jq '.total_last_24h' || echo "❌ API failed"

# Test de charge léger
ab -n 100 -c 10 $PROD_URL/api/health
```

### Monitoring continu

Configurer des checks réguliers :

```bash
# Cron job (checks toutes les 5 minutes)
*/5 * * * * curl -f https://dashboard.example.com/api/health || mail -s "Dashboard down" admin@example.com
```

Ou utiliser un service de monitoring :
- UptimeRobot
- Pingdom
- StatusCake
- AWS CloudWatch
- Datadog

## 🐛 Dépannage des Tests

### Problème : Connexion OpenSearch échoue

```bash
# Vérifier la résolution DNS
nslookup your-opensearch-endpoint.com

# Vérifier la connectivité réseau
nc -zv your-opensearch-endpoint.com 443

# Tester avec curl
curl -k https://your-opensearch-endpoint.com

# Vérifier les credentials AWS
aws sts get-caller-identity
```

### Problème : Pas de données retournées

```bash
# Vérifier les indices
curl http://localhost:5000/api/indices

# Vérifier directement dans OpenSearch
curl -X GET "https://opensearch-endpoint/_cat/indices?v"

# Vérifier que Fluent Bit envoie des données
tail -f /var/log/fluent-bit/fluent-bit.log
```

### Problème : Erreur 500 sur l'API

```bash
# Vérifier les logs de l'application
# Docker:
docker logs osquery-dashboard

# Systemd:
journalctl -u osquery-dashboard -n 100

# Mode debug local:
FLASK_DEBUG=true python app.py
```

### Problème : Performance lente

```python
# Ajouter du timing dans opensearch_client.py
import time

def search_logs(self, ...):
    start = time.time()
    # ... code existant ...
    elapsed = time.time() - start
    print(f"Search took {elapsed:.2f}s")
```

## ✅ Checklist de Test Complète

### Tests Fonctionnels
- [ ] Health check retourne 200
- [ ] Statistiques se chargent correctement
- [ ] Graphique s'affiche avec des données
- [ ] Filtres sont populés avec des valeurs
- [ ] Recherche sans filtre fonctionne
- [ ] Recherche avec filtres fonctionne
- [ ] Recherche texte libre fonctionne
- [ ] Pagination fonctionne
- [ ] Affichage des logs est correct

### Tests Techniques
- [ ] Connexion OpenSearch stable
- [ ] Authentification valide (IAM ou Basic)
- [ ] Temps de réponse < 3s pour les recherches
- [ ] Pas d'erreurs dans les logs
- [ ] Pas d'erreurs JavaScript dans la console

### Tests de Sécurité
- [ ] HTTPS actif en production
- [ ] Certificat SSL valide
- [ ] Pas de secrets exposés dans le code
- [ ] Authentification requise (si configurée)
- [ ] Rate limiting actif (si configuré)

### Tests de Déploiement
- [ ] Build Docker réussi
- [ ] Container démarre sans erreur
- [ ] Health check Docker fonctionne
- [ ] Variables d'environnement correctes
- [ ] Logs accessibles

## 📝 Rapport de Test

Créer un rapport après les tests :

```markdown
# Rapport de Test - OSQuery Dashboard

**Date**: 2024-XX-XX
**Version**: 1.0.0
**Testé par**: [Votre nom]

## Environnement
- OS: macOS / Linux / Windows
- Python: 3.11
- OpenSearch: Version X.X

## Résultats

### Tests Fonctionnels
| Test | Statut | Notes |
|------|--------|-------|
| Health check | ✅ | OK |
| Statistiques | ✅ | OK |
| Recherche | ✅ | OK |
| ... | ... | ... |

### Performance
- Temps de réponse moyen: XXms
- Charge testée: XX req/s
- Pics de mémoire: XXX MB

### Problèmes Identifiés
1. [Description du problème]
2. ...

### Recommandations
1. [Recommandation]
2. ...
```
