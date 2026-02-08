# Inventaire Logiciel avec OSQuery

Ce guide explique les requêtes OSQuery configurées pour inventorier les logiciels de développement et les gestionnaires de paquets.

## 📋 Requêtes Configurées

### 🔷 VSCode Extensions (Toutes plateformes)

**Intervalle** : Toutes les heures (3600s)

**Description** : Récupère la liste des extensions VSCode installées par utilisateur

**Requête** :
```sql
-- Linux
SELECT 
  u.username,
  f.path,
  f.filename,
  json_extract(fc.data, '$.name') AS extension_name,
  json_extract(fc.data, '$.version') AS version,
  json_extract(fc.data, '$.publisher') AS publisher
FROM users u
CROSS JOIN file f ON f.path LIKE '/home/' || u.username || '/.vscode/extensions/%/package.json'
CROSS JOIN file fc ON fc.path = f.path
WHERE f.filename = 'package.json';

-- macOS
... LIKE '/Users/' || u.username || '/.vscode/extensions/%/package.json' ...

-- Windows
... LIKE 'C:\\Users\\' || u.username || '\\.vscode\\extensions\\%\\package.json' ...
```

**Colonnes retournées** :
- `username` : Nom d'utilisateur
- `path` : Chemin complet du package.json
- `extension_name` : Nom de l'extension
- `version` : Version installée
- `publisher` : Éditeur de l'extension

**Exemple de résultat** :
```json
{
  "username": "developer",
  "path": "/home/developer/.vscode/extensions/ms-python.python-2024.1.0/package.json",
  "extension_name": "python",
  "version": "2024.1.0",
  "publisher": "ms-python"
}
```

---

### 🔷 JetBrains Plugins (Toutes plateformes)

**Intervalle** : Toutes les heures (3600s)

**Description** : Liste les plugins installés pour les IDEs JetBrains (IntelliJ, PyCharm, WebStorm, etc.)

**Requête** :
```sql
-- Linux
SELECT 
  u.username,
  f.directory,
  f.filename
FROM users u
CROSS JOIN file f ON 
  f.directory LIKE '/home/' || u.username || '/.local/share/JetBrains/%/plugins/%' OR
  f.directory LIKE '/home/' || u.username || '/.config/JetBrains/%/plugins/%'
WHERE f.filename LIKE '%.jar' OR f.filename = 'plugin.xml';

-- macOS
... LIKE '/Users/' || u.username || '/Library/Application Support/JetBrains/%/plugins/%' ...

-- Windows
... LIKE 'C:\\Users\\' || u.username || '\\AppData\\Roaming\\JetBrains\\%\\plugins\\%' ...
```

**Colonnes retournées** :
- `username` : Nom d'utilisateur
- `directory` : Répertoire du plugin
- `filename` : Fichier JAR ou XML du plugin

**Exemple de résultat** :
```json
{
  "username": "developer",
  "directory": "/home/developer/.local/share/JetBrains/IntelliJIdea2023.3/plugins/python",
  "filename": "python.jar"
}
```

---

### 🍺 Homebrew Packages (macOS uniquement)

**Intervalle** : Toutes les heures (3600s)

**Description** : Liste toutes les formules Homebrew installées

**Requête** :
```sql
SELECT 
  name,
  version,
  source
FROM homebrew_packages;
```

**Colonnes retournées** :
- `name` : Nom du package
- `version` : Version installée
- `source` : Source (core, cask, tap)

**Exemple de résultat** :
```json
{
  "name": "python@3.11",
  "version": "3.11.7",
  "source": "core"
}
```

---

### 🍺 Homebrew Casks (macOS uniquement)

**Intervalle** : Toutes les heures (3600s)

**Description** : Liste toutes les applications installées via Homebrew Cask

**Requête** :
```sql
SELECT 
  name,
  version
FROM homebrew_casks;
```

**Colonnes retournées** :
- `name` : Nom du cask
- `version` : Version installée

**Exemple de résultat** :
```json
{
  "name": "visual-studio-code",
  "version": "1.85.1"
}
```

---

### 🍫 Chocolatey Packages (Windows uniquement)

**Intervalle** : Toutes les heures (3600s)

**Description** : Liste tous les packages installés via Chocolatey

**Requête** :
```sql
SELECT 
  name,
  version,
  summary
FROM chocolatey_packages;
```

**Colonnes retournées** :
- `name` : Nom du package
- `version` : Version installée
- `summary` : Description courte

**Exemple de résultat** :
```json
{
  "name": "git",
  "version": "2.43.0",
  "summary": "Git for Windows"
}
```

---

## 🔍 Utilisation dans OpenSearch

### Rechercher les Extensions VSCode

```json
GET /osquery-*/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "name": "vscode_extensions" }},
        { "range": { "@timestamp": { "gte": "now-24h" }}}
      ]
    }
  },
  "aggs": {
    "top_extensions": {
      "terms": {
        "field": "columns.extension_name.keyword",
        "size": 20
      }
    }
  }
}
```

### Compter les Packages Homebrew par Serveur

```json
GET /osquery-*/_search
{
  "query": {
    "match": { "name": "homebrew_packages" }
  },
  "aggs": {
    "by_host": {
      "terms": {
        "field": "hostname.keyword"
      },
      "aggs": {
        "package_count": {
          "cardinality": {
            "field": "columns.name.keyword"
          }
        }
      }
    }
  }
}
```

### Trouver les Machines avec un Plugin spécifique

```json
GET /osquery-*/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "name": "jetbrains_plugins" }},
        { "wildcard": { "columns.filename": "*lombok*" }}
      ]
    }
  }
}
```

---

## 📊 Dashboards Recommandés

### Dashboard Inventaire Développement

**Visualisations** :
1. **Tableau des Extensions VSCode**
   - Top 20 extensions les plus utilisées
   - Nombre d'installations par extension

2. **Distribution des Packages**
   - Homebrew packages par serveur (macOS)
   - Chocolatey packages par serveur (Windows)

3. **Plugins JetBrains**
   - IDEs utilisés (détectés par le chemin)
   - Plugins les plus courants

4. **Timeline**
   - Évolution du nombre de packages dans le temps
   - Détection des nouvelles installations

---

## 🎯 Cas d'Usage

### 1. Audit de Licence VSCode

Identifier toutes les extensions commerciales installées :

```bash
# Via osqueryi
osqueryi --json "SELECT DISTINCT extension_name, publisher FROM file WHERE path LIKE '%/.vscode/extensions/%/package.json'"
```

### 2. Conformité des Outils de Développement

Vérifier que tous les développeurs utilisent les mêmes versions d'outils :

```sql
-- Trouver les versions divergentes de Git
SELECT DISTINCT version 
FROM chocolatey_packages 
WHERE name = 'git';
```

### 3. Détection d'Outils Non Autorisés

Alerter sur l'installation d'outils spécifiques :

```sql
-- Détecter des extensions de cryptomining
SELECT * FROM file 
WHERE path LIKE '%/.vscode/extensions/%' 
AND data LIKE '%crypto%miner%';
```

### 4. Inventaire Automatique

Générer un rapport d'inventaire complet :

```bash
# Toutes les extensions VSCode
ansible all -m shell -a 'osqueryi "SELECT * FROM file WHERE filename = \"package.json\" AND path LIKE \"%/.vscode/extensions/%\""' --become
```

---

## 🛠️ Requêtes Manuelles Utiles

### Lister les Extensions VSCode Localement

```bash
# Linux/macOS
osqueryi "SELECT json_extract(data, '$.name') AS name, json_extract(data, '$.version') AS version FROM file WHERE path LIKE '/home/%/.vscode/extensions/%/package.json' OR path LIKE '/Users/%/.vscode/extensions/%/package.json'"

# Windows (PowerShell)
osqueryi "SELECT json_extract(data, '$.name') AS name FROM file WHERE path LIKE 'C:\Users\%\.vscode\extensions\%\package.json'"
```

### Compter les Packages Homebrew

```bash
# macOS
osqueryi "SELECT COUNT(*) as total FROM homebrew_packages"
osqueryi "SELECT COUNT(*) as total_casks FROM homebrew_casks"
```

### Lister les Packages Chocolatey

```powershell
# Windows
osqueryi "SELECT name, version FROM chocolatey_packages ORDER BY name"
```

### Trouver les Plugins JetBrains par IDE

```bash
# Extraire l'IDE du chemin
osqueryi "SELECT 
  SUBSTRING(directory, 
    INSTR(directory, 'JetBrains/') + 10,
    INSTR(SUBSTRING(directory, INSTR(directory, 'JetBrains/') + 10), '/') - 1
  ) AS ide,
  COUNT(*) as plugin_count
FROM file 
WHERE directory LIKE '%/JetBrains/%/plugins/%'
GROUP BY ide"
```

---

## 📈 Optimisations

### Réduire la Fréquence

Si l'inventaire génère trop de données, augmenter l'intervalle :

```json
"vscode_extensions": {
  "interval": 86400,  // Une fois par jour
  ...
}
```

### Filtrer les Résultats

Ajouter des conditions WHERE pour limiter les résultats :

```sql
-- Ne récupérer que les extensions Microsoft
... WHERE json_extract(fc.data, '$.publisher') LIKE 'ms-%'
```

### Créer des Index Pattern

Dans OpenSearch Dashboards :
- Index pattern : `osquery-*`
- Filter par `name.keyword` : `vscode_extensions`, `homebrew_packages`, etc.

---

## 🚨 Alertes Recommandées

### Extension VSCode Suspecte

```json
{
  "trigger": {
    "schedule": { "interval": "1h" }
  },
  "input": {
    "search": {
      "request": {
        "indices": ["osquery-*"],
        "body": {
          "query": {
            "bool": {
              "must": [
                { "match": { "name": "vscode_extensions" }},
                { "wildcard": { "columns.extension_name": "*miner*" }}
              ]
            }
          }
        }
      }
    }
  }
}
```

### Package Non Autorisé

Créer une liste blanche et alerter sur les déviations.

---

## 📖 Ressources

- [OSQuery Schema - file](https://osquery.io/schema/5.11.0/#file)
- [OSQuery Schema - users](https://osquery.io/schema/5.11.0/#users)
- [OSQuery Schema - homebrew_packages](https://osquery.io/schema/5.11.0/#homebrew_packages)
- [OSQuery Schema - chocolatey_packages](https://osquery.io/schema/5.11.0/#chocolatey_packages)
- [VSCode Extension API](https://code.visualstudio.com/api)
- [JetBrains Plugin Structure](https://plugins.jetbrains.com/docs/intellij/plugin-structure.html)

---

**Note** : Ces requêtes sont exécutées automatiquement toutes les heures. Les résultats sont disponibles dans `/var/log/osquery/osqueryd.results.log` localement et dans OpenSearch si activé.
