# 🍺 Homebrew Package Viewer - Documentation

## Vue d'ensemble

Le dashboard OSQuery dispose maintenant d'une page dédiée pour visualiser tous les packages Homebrew installés sur vos hôtes macOS, avec des informations enrichies provenant de l'API officielle de Homebrew.

## Fonctionnalités

### 📊 Données affichées

Pour chaque package, vous pouvez voir :

**Depuis OSQuery (OpenSearch) :**
- Nom du package
- Version installée
- Hôte où il est installé
- Chemin d'installation
- Dernière observation

**Depuis l'API Homebrew :**
- Description du package
- Page d'accueil du projet
- Version disponible la plus récente
- Licence (pour les formules)
- Statut outdated (comparaison versions)
- Statut deprecated
- Statut disabled
- Type (formula ou cask)

### 🔍 Filtres disponibles

1. **Recherche textuelle** : Recherche dans le nom et la description des packages
2. **Filtre par hôte** : Affiche les packages d'un hôte spécifique
3. **Filtre par statut** :
   - Outdated : Packages avec une version plus récente disponible
   - Up-to-date : Packages à jour
   - Deprecated : Packages dépréciés
   - Disabled : Packages désactivés

### 📈 Statistiques

En haut de la page, des statistiques globales affichent :
- Nombre total de packages
- Nombre de packages outdated
- Nombre de packages dépréciés
- Nombre d'hôtes surveillés

## Accès

### Via l'interface web

1. Ouvrez le dashboard principal : http://localhost:5000
2. Cliquez sur le lien "🍺 Voir les packages Homebrew →"
3. Ou accédez directement : http://localhost:5000/homebrew

### Via l'API

#### GET /api/homebrew-packages

Récupère la liste complète des packages avec métadonnées.

**Exemple de réponse :**

```json
{
  "total": 42,
  "packages": [
    {
      "hostname": "macbook-pro",
      "name": "git",
      "version": "2.43.0",
      "path": "/opt/homebrew/Cellar/git/2.43.0",
      "last_seen": "2024-02-08T10:00:00Z",
      "desc": "Distributed revision control system",
      "homepage": "https://git-scm.com",
      "latest_version": "2.44.0",
      "outdated": true,
      "license": "GPL-2.0-only",
      "disabled": false,
      "deprecated": false,
      "type": "formula"
    }
  ]
}
```

## Configuration OSQuery

Pour que cette fonctionnalité fonctionne, votre configuration OSQuery doit inclure la requête `homebrew_packages` dans le pack `software-inventory`.

### Exemple de configuration

Dans votre fichier `osquery.conf` :

```json
{
  "packs": {
    "software-inventory": {
      "queries": {
        "homebrew_packages": {
          "query": "SELECT * FROM homebrew_packages;",
          "interval": 3600,
          "description": "Retrieves all Homebrew packages installed"
        }
      }
    }
  }
}
```

Ou dans le fichier Ansible template `osquery-macos.conf.j2` :

```json
"homebrew_packages": {
  "query": "SELECT name, version, path FROM homebrew_packages;",
  "interval": 3600,
  "description": "Homebrew packages inventory"
}
```

## Structure des données dans OpenSearch

Les données Homebrew sont stockées dans OpenSearch avec la structure suivante :

```json
{
  "name": "pack_software-inventory_homebrew_packages",
  "decorations": {
    "hostname": "macbook-pro"
  },
  "columns": {
    "name": "git",
    "version": "2.43.0",
    "path": "/opt/homebrew/Cellar/git/2.43.0"
  },
  "@timestamp": "2024-02-08T10:00:00Z"
}
```

## Architecture technique

### Composants créés

1. **homebrew_client.py** : Client pour interroger l'API Homebrew
   - Cache LRU pour optimiser les performances (1000 entrées)
   - Gestion automatique des formulas et casks
   - Comparaison de versions

2. **opensearch_client.py** : Nouvelle méthode `get_homebrew_packages()`
   - Agrégation par hostname et package name
   - Récupération de la dernière version vue pour chaque package

3. **app.py** : Nouveaux endpoints
   - `/homebrew` : Page web
   - `/api/homebrew-packages` : API REST

4. **templates/homebrew.html** : Interface utilisateur
   - Table responsive et triable
   - Filtres interactifs
   - Badges de statut

5. **static/homebrew.js** : Logique frontend
   - Chargement asynchrone des données
   - Filtrage côté client
   - Mise à jour des statistiques

## Performance

### Optimisations

- **Cache API Homebrew** : Les résultats des requêtes API sont mis en cache avec LRU cache (1000 entrées)
- **Agrégations OpenSearch** : Utilisation d'agrégations pour grouper efficacement les données
- **Top hits** : Récupération uniquement du dernier document par groupe
- **Filtrage client** : Les filtres sont appliqués côté client pour une réactivité immédiate

### Considérations

- Le premier chargement peut prendre quelques secondes selon le nombre de packages
- L'API Homebrew a une limite de taux (rate limiting)
- Le cache est stocké en mémoire et sera vidé au redémarrage de l'application

## Dépannage

### Aucun package n'apparaît

**Vérifications :**

1. OSQuery collecte les données :
   ```bash
   osqueryi "SELECT * FROM homebrew_packages;"
   ```

2. Les données sont dans OpenSearch :
   ```bash
   curl http://localhost:5000/api/search?query=homebrew_packages
   ```

3. L'endpoint API fonctionne :
   ```bash
   curl http://localhost:5000/api/homebrew-packages
   ```

### Erreur "Package not found in Homebrew API"

Certains packages peuvent ne pas être trouvés dans l'API Homebrew :
- Packages installés manuellement
- Old taps non officiels
- Packages renommés ou supprimés

Le système affiche quand même le package avec les données d'OSQuery.

### Performances lentes

Si le chargement est lent :

1. **Réduire la taille du cache** dans `homebrew_client.py` :
   ```python
   @lru_cache(maxsize=500)  # Au lieu de 1000
   ```

2. **Augmenter l'intervalle OSQuery** pour réduire le volume de données

3. **Filtrer par hôte** pour limiter les résultats

## Évolutions futures

### Améliorations possibles

- [ ] Export CSV/JSON des packages
- [ ] Graphiques de répartition par version
- [ ] Alertes pour packages outdated critiques
- [ ] Historique des versions par package
- [ ] Comparaison entre hôtes
- [ ] Suggestions de mises à jour groupées
- [ ] Intégration avec `brew outdated` en temps réel
- [ ] Détection de vulnérabilités connues

### Idées d'extension

- **Autres gestionnaires de paquets** : apt, yum, pip, npm
- **Analyse de dépendances** : Graphe des dépendances
- **Compliance** : Vérification des licences autorisées
- **Rapports automatisés** : Envoi de rapports hebdomadaires

## Exemples d'utilisation

### Identifier les packages outdated

1. Accédez à http://localhost:5000/homebrew
2. Sélectionnez le filtre "Outdated"
3. Exportez ou notez les packages à mettre à jour

### Audit de sécurité

1. Filtrez par statut "Deprecated" ou "Disabled"
2. Vérifiez les raisons de dépréciation
3. Planifiez la migration vers des alternatives

### Inventaire par hôte

1. Sélectionnez un hôte dans le filtre
2. Consultez tous les packages installés
3. Comparez avec d'autres hôtes

## Support

Pour toute question ou problème :

1. Consultez les logs de l'application
2. Vérifiez la configuration OSQuery
3. Testez les endpoints API individuellement
4. Consultez la documentation Homebrew API : https://formulae.brew.sh/docs/api/

## Références

- [Homebrew Formula API](https://formulae.brew.sh/docs/api/)
- [OSQuery homebrew_packages table](https://osquery.io/schema/current/#homebrew_packages)
- [OpenSearch Aggregations](https://opensearch.org/docs/latest/aggregations/)
