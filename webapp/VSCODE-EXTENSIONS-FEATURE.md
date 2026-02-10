# 📦 VSCode Extensions Viewer - Documentation

## Vue d'ensemble

Le dashboard OSQuery dispose maintenant d'une page dédiée pour visualiser toutes les extensions Visual Studio Code installées sur vos machines, avec des informations enrichies provenant de l'API officielle du VSCode Marketplace.

## Fonctionnalités

### 📊 Données affichées

Pour chaque extension, vous pouvez voir :

**Depuis OSQuery (OpenSearch) :**
- Nom de l'extension
- Publisher
- Version installée
- Username qui a installé l'extension
- Chemin d'installation
- Hostname où elle est installée
- Dernière observation

**Depuis l'API VSCode Marketplace :**
- Nom complet (displayName)
- Description de l'extension
- Publisher vérifié (badge)
- Version disponible la plus récente
- Date de dernière mise à jour
- Nombre d'installations sur le Marketplace
- Statut (à jour / outdated)
- Historique des versions disponibles

### 🔍 Filtres disponibles

1. **Recherche textuelle** : Recherche dans le nom, description, publisher
2. **Filtre par publisher** : Affiche les extensions d'un publisher spécifique
3. **Filtre par statut** :
   - Vérifiés uniquement : Publishers avec badge vérifié
   - Outdated uniquement : Extensions avec version plus récente disponible
   - À jour uniquement : Extensions installées à la dernière version

### 📈 Statistiques

En haut de la page, des statistiques globales affichent :
- Nombre total d'extensions uniques
- Nombre d'extensions de publishers vérifiés
- Nombre total d'installations trouvées
- Nombre d'extensions outdated

### 🔗 Page de détails

En cliquant sur le nom d'une extension, vous accédez à une page détaillée qui montre :

- **Informations générales** : nom complet, description, publisher
- **Métadonnées Marketplace** : badge vérifié, installations, dernière mise à jour
- **Versions installées** : Pour chaque version trouvée :
  - Badge indiquant si c'est la dernière version
  - Liste des machines où elle est installée
  - Username et chemin d'installation
  - Date de dernière observation
- **Versions disponibles** : Historique des 10 dernières versions sur le Marketplace

## Accès

### Via l'interface web

1. Ouvrez le dashboard principal : http://localhost:5000
2. Cliquez sur le lien "📦 Voir les extensions VSCode →"
3. Ou accédez directement : http://localhost:5000/vscode-extensions

### Via l'API

#### GET /api/vscode-extensions

Récupère la liste complète des extensions avec métadonnées enrichies.

**Exemple de réponse :**

```json
{
  "total": 125,
  "extensions": [
    {
      "extension_id": "ms-python.python",
      "publisher": "ms-python",
      "name": "python",
      "displayName": "Python",
      "shortDescription": "Python language support",
      "isVerified": true,
      "latestVersion": "2024.0.0",
      "lastUpdated": "2024-01-15T10:00:00.000Z",
      "marketplaceInstalls": 65000000,
      "installations_count": 5,
      "versions_found": ["2023.22.0", "2024.0.0"]
    }
  ]
}
```

#### GET /api/vscode-extension/{publisher}/{name}

Récupère les détails d'une extension spécifique avec toutes ses installations.

**Exemple de requête :**
```
GET /api/vscode-extension/ms-python/python
```

**Exemple de réponse :**

```json
{
  "extension_id": "ms-python.python",
  "publisher": "ms-python",
  "name": "python",
  "displayName": "Python",
  "shortDescription": "Python language support",
  "isVerified": true,
  "latestVersion": "2024.0.0",
  "lastUpdated": "2024-01-15T10:00:00.000Z",
  "marketplaceInstalls": 65000000,
  "total_installations": 8,
  "versions": [
    {
      "version": "2024.0.0",
      "is_latest": true,
      "installation_count": 5,
      "installations": [
        {
          "hostname": "dev-mac-01",
          "username": "john",
          "path": "/Users/john/.vscode/extensions/ms-python.python-2024.0.0",
          "last_seen": "2024-02-08T10:00:00Z"
        }
      ]
    },
    {
      "version": "2023.22.0",
      "is_latest": false,
      "installation_count": 3,
      "installations": [...]
    }
  ],
  "allVersions": [
    {
      "version": "2024.0.0",
      "lastUpdated": "2024-01-15T10:00:00.000Z"
    }
  ]
}
```

## Configuration OSQuery

Pour que cette fonctionnalité fonctionne, votre configuration OSQuery doit inclure la requête `vscode_extensions` dans le pack `software-inventory`.

### Configuration macOS

Dans le fichier `osquery-macos.conf.j2` :

```json
{
  "packs": {
    "software-inventory": {
      "queries": {
        "vscode_extensions": {
          "query": "SELECT u.username, vsc.vscode_edition, vsc.path, vsc.name AS extension_name, vsc.version AS version, vsc.publisher AS publisher, vsc.installed_at FROM users u CROSS JOIN vscode_extensions vsc ON u.uid = vsc.uid;",
          "interval": 3600,
          "description": "VSCode extensions installed per user"
        }
      }
    }
  }
}
```

### Configuration Linux

Pour Linux, OSQuery n'a pas de table native `vscode_extensions`, donc on utilise une requête JSON :

```json
"vscode_extensions": {
  "query": "SELECT u.username, f.path, f.filename, json_extract(fc.data, '$.name') AS extension_name, json_extract(fc.data, '$.version') AS version, json_extract(fc.data, '$.publisher') AS publisher FROM users u CROSS JOIN file f ON f.path LIKE '/home/' || u.username || '/.vscode/extensions/%/package.json' CROSS JOIN file fc ON fc.path = f.path WHERE f.filename = 'package.json';",
  "interval": 3600,
  "description": "VSCode extensions installed per user"
}
```

### Configuration Windows

Pour Windows :

```json
"vscode_extensions": {
  "query": "SELECT u.username, f.path, f.filename, json_extract(fc.data, '$.name') AS extension_name, json_extract(fc.data, '$.version') AS version, json_extract(fc.data, '$.publisher') AS publisher FROM users u CROSS JOIN file f ON f.path LIKE 'C:\\Users\\' || u.username || '\\.vscode\\extensions\\%\\package.json' CROSS JOIN file fc ON fc.path = f.path WHERE f.filename = 'package.json';",
  "interval": 3600,
  "description": "VSCode extensions installed per user"
}
```

## Structure des données dans OpenSearch

Les données des extensions VSCode sont stockées dans OpenSearch avec la structure suivante :

```json
{
  "name": "pack_software-inventory_vscode_extensions",
  "decorations": {
    "hostname": "dev-mac-01"
  },
  "columns": {
    "extension_name": "python",
    "publisher": "ms-python",
    "version": "2024.0.0",
    "username": "john",
    "path": "/Users/john/.vscode/extensions/ms-python.python-2024.0.0",
    "installed_at": "1707350400"
  },
  "@timestamp": "2024-02-08T10:00:00Z"
}
```

## Architecture technique

### Composants créés

1. **vscode_marketplace_client.py** : Client pour interroger l'API VSCode Marketplace
   - Cache LRU pour optimiser les performances (1000 entrées)
   - Gestion des requêtes POST vers l'API
   - Parsing des réponses JSON complexes
   - Extraction des métadonnées (displayName, description, versions, etc.)

2. **opensearch_client.py** : Nouvelles méthodes
   - `get_vscode_extensions()` : Récupère toutes les extensions avec agrégations
   - `get_vscode_extensions_summary()` : Résumé groupé par extension unique
   - Agrégation par hostname → publisher → extension_name

3. **app.py** : Nouveaux endpoints
   - `/vscode-extensions` : Page principale
   - `/vscode-extension/<publisher>/<name>` : Page de détails
   - `/api/vscode-extensions` : API liste complète avec enrichissement
   - `/api/vscode-extension/<publisher>/<name>` : API détails d'une extension

4. **templates/vscode_extensions.html** : Interface liste
   - Table interactive et responsive
   - Filtres multiples
   - Badges de statut
   - Liens vers pages de détails

5. **templates/vscode_extension_detail.html** : Interface détails
   - Informations complètes de l'extension
   - Versions installées avec groupement
   - Liste des machines et utilisateurs
   - Historique des versions Marketplace

6. **static/vscode_extensions.js** : Logique frontend
   - Chargement asynchrone des données
   - Filtrage côté client
   - Détection des versions outdated
   - Mise à jour des statistiques

## API VSCode Marketplace

### Endpoint utilisé

```
POST https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery
```

### Format de la requête

```json
{
  "filters": [{
    "criteria": [
      {"filterType": 7, "value": "publisher.extensionName"}
    ],
    "pageNumber": 1,
    "pageSize": 1,
    "sortBy": 0,
    "sortOrder": 0
  }],
  "assetTypes": [],
  "flags": 914
}
```

### Headers requis

```
Accept: application/json;api-version=3.0-preview.1
Content-Type: application/json
```

## Performance

### Optimisations

- **Cache API Marketplace** : Les résultats sont mis en cache avec LRU cache (1000 entrées)
- **Agrégations OpenSearch** : Utilisation d'agrégations imbriquées pour grouper efficacement
- **Top hits** : Récupération uniquement du dernier document par groupe
- **Filtrage client** : Filtres appliqués côté client pour réactivité immédiate

### Considérations

- Le premier chargement peut prendre quelques secondes selon le nombre d'extensions
- L'API Marketplace n'a pas de limite de taux documentée, mais le cache limite les requêtes
- Le cache est en mémoire et sera vidé au redémarrage

## Dépannage

### Aucune extension n'apparaît

**Vérifications :**

1. OSQuery collecte les données (macOS) :
   ```bash
   osqueryi "SELECT * FROM vscode_extensions LIMIT 5;"
   ```

2. Vérifier les données dans OpenSearch :
   ```bash
   curl http://localhost:5000/api/search?query=vscode_extensions
   ```

3. Tester l'endpoint API :
   ```bash
   curl http://localhost:5000/api/vscode-extensions
   ```

### Erreur "Extension not found in marketplace"

Certaines extensions peuvent ne pas être trouvées :
- Extensions privées ou d'entreprise
- Extensions installées depuis VSIX local
- Extensions dépubliées
- Erreur dans le nom du publisher

Le système affiche quand même l'extension avec les données d'OSQuery.

### Performances lentes

Si le chargement est lent :

1. **Réduire la taille du cache** dans `vscode_marketplace_client.py` :
   ```python
   @lru_cache(maxsize=500)  # Au lieu de 1000
   ```

2. **Augmenter l'intervalle OSQuery** pour réduire le volume de données

3. **Utiliser les filtres** pour limiter l'affichage

## Évolutions futures

### Améliorations possibles

- [ ] Export CSV/JSON des extensions
- [ ] Graphiques de répartition par publisher
- [ ] Alertes pour extensions outdated critiques
- [ ] Historique des versions par extension
- [ ] Comparaison entre machines
- [ ] Suggestions de mises à jour groupées
- [ ] Détection d'extensions malveillantes connues
- [ ] Vérification de compatibilité avec la version VSCode

### Idées d'extension

- **Autres éditeurs** : IntelliJ IDEA plugins, Sublime Text packages
- **Analyse de popularité** : Extensions populaires vs peu utilisées
- **Conformité** : Vérification des extensions autorisées
- **Rapports automatisés** : Envoi de rapports hebdomadaires

## Exemples d'utilisation

### Identifier les extensions outdated

1. Accédez à http://localhost:5000/vscode-extensions
2. Sélectionnez le filtre "Outdated uniquement"
3. Notez les extensions à mettre à jour
4. Cliquez sur une extension pour voir quelles machines sont concernées

### Audit de sécurité

1. Filtrez par "Non vérifié" pour trouver les publishers non vérifiés
2. Vérifiez les extensions installées
3. Planifiez le remplacement par des alternatives vérifiées

### Inventaire par publisher

1. Sélectionnez un publisher dans le filtre
2. Consultez toutes ses extensions installées
3. Vérifiez les versions et le nombre d'installations

### Standardisation des extensions

1. Consultez la page de détails d'une extension critique
2. Identifiez les machines qui n'ont pas la dernière version
3. Planifiez un rollout de mise à jour

## Support

Pour toute question ou problème :

1. Consultez les logs de l'application
2. Vérifiez la configuration OSQuery
3. Testez les endpoints API individuellement
4. Consultez la documentation VSCode Marketplace API

## Références

- [VSCode Marketplace API](https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery)
- [OSQuery vscode_extensions table](https://osquery.io/schema/current/#vscode_extensions) (macOS uniquement)
- [VSCode Extension Manifest](https://code.visualstudio.com/api/references/extension-manifest)
- [OpenSearch Aggregations](https://opensearch.org/docs/latest/aggregations/)
