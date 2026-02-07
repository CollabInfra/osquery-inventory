# Architecture Système OSQuery + AWS OpenSearch

## 📐 Diagramme d'Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         Serveurs Monitorés                               │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │
│  │   Linux     │  │   Linux     │  │   macOS     │  │   Windows   │   │
│  │   Debian    │  │   RedHat    │  │             │  │             │   │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘   │
│         │                │                │                │           │
│         └────────────────┴────────────────┴────────────────┘           │
│                              │                                         │
│                              ↓                                         │
│                    ┌──────────────────┐                                │
│                    │     OSQuery      │                                │
│                    │  (osqueryd)      │                                │
│                    │                  │                                │
│                    │ - Tables SQL     │                                │
│                    │ - Requêtes       │                                │
│                    │ - Scheduling     │                                │
│                    │ - Events         │                                │
│                    └────────┬─────────┘                                │
│                             │                                          │
│                             ↓                                          │
│                    ┌──────────────────┐                                │
│                    │  Logs Locaux     │                                │
│                    │  /var/log/       │                                │
│                    │  osquery/        │                                │
│                    │                  │                                │
│                    │ - results.log    │                                │
│                    │ - INFO           │                                │
│                    └────────┬─────────┘                                │
│                             │                                          │
│              [SI OpenSearch activé]                                     │
│                             │                                          │
│                             ↓                                          │
│                    ┌──────────────────┐                                │
│                    │   Fluent Bit     │                                │
│                    │                  │                                │
│                    │ - Tail logs      │                                │
│                    │ - Parse JSON     │                                │
│                    │ - Enrich AWS     │                                │
│                    │ - Buffer         │                                │
│                    └────────┬─────────┘                                │
│                             │                                          │
└─────────────────────────────┼──────────────────────────────────────────┘
                              │
                              │ HTTPS + IAM Auth
                              │ (ou Basic Auth)
                              ↓
┌──────────────────────────────────────────────────────────────────────────┐
│                          AWS Cloud                                       │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│                    ┌──────────────────┐                                │
│                    │  AWS OpenSearch  │                                │
│                    │   Service        │                                │
│                    │                  │                                │
│                    │ - Indices        │                                │
│                    │ - Search API     │                                │
│                    │ - Aggregations   │                                │
│                    └────────┬─────────┘                                │
│                             │                                          │
│                             ↓                                          │
│                    ┌──────────────────┐                                │
│                    │   OpenSearch     │                                │
│                    │   Dashboards     │                                │
│                    │                  │                                │
│                    │ - Visualizations │                                │
│                    │ - Dashboards     │                                │
│                    │ - Alerting       │                                │
│                    │ - Discover       │                                │
│                    └──────────────────┘                                │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────────────┐
│                      Utilisateurs / Equipes                              │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  👤 Security Team    →  Monitoring des menaces                          │
│  👤 Ops Team         →  Inventaire & Performance                        │
│  👤 Compliance Team  →  Audit & Rapports                                │
│  👤 DevOps Team      →  Automatisation & CI/CD                          │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

## 🔄 Flux de Données Détaillé

### 1. Collecte (OSQuery)
```
┌──────────────────────────────────────────────┐
│ OSQuery Tables (Virtual)                     │
├──────────────────────────────────────────────┤
│ - system_info                                │
│ - processes                                  │
│ - users                                      │
│ - logged_in_users                            │
│ - listening_ports                            │
│ - file_events                                │
│ - etc_hosts                                  │
│ - [300+ tables disponibles]                  │
└──────────────────┬───────────────────────────┘
                   │ SQL Queries (scheduled)
                   ↓
         Résultats en JSON
```

### 2. Stockage Local
```
/var/log/osquery/
├── osqueryd.results.log    ← JSON structured logs
│   {
│     "name": "process_monitor",
│     "hostIdentifier": "server1",
│     "unixTime": 1707311234,
│     "columns": {
│       "pid": "1234",
│       "name": "nginx",
│       "path": "/usr/sbin/nginx"
│     }
│   }
│
├── osqueryd.INFO           ← Text logs (debug)
└── osqueryd.WARNING        ← Error logs
```

### 3. Forwarding (Fluent Bit)
```
┌─────────────────────────────────────────────┐
│ Fluent Bit Pipeline                         │
├─────────────────────────────────────────────┤
│                                             │
│  [INPUT]                                    │
│   tail → /var/log/osquery/*.log             │
│                                             │
│  [PARSER]                                   │
│   json → Parse structured data              │
│                                             │
│  [FILTER]                                   │
│   record_modifier → Add hostname, env       │
│   aws → Add EC2 metadata                    │
│                                             │
│  [OUTPUT]                                   │
│   es → Send to OpenSearch                   │
│     - Format: Logstash                      │
│     - Index: osquery-YYYY.MM.DD             │
│     - Auth: AWS IAM                         │
│                                             │
└─────────────────────────────────────────────┘
```

### 4. Indexation (OpenSearch)
```
OpenSearch Indices Pattern:
osquery-2026.02.07
osquery-2026.02.08
osquery-2026.02.09
...

Document Structure:
{
  "@timestamp": "2026-02-07T10:30:45.123Z",
  "hostname": "server1",
  "environment": "production",
  "name": "process_monitor",
  "columns": {
    "pid": "1234",
    "name": "nginx",
    ...
  },
  "ec2_instance_id": "i-0123456789abcdef",
  "ec2_instance_type": "t3.medium",
  "az": "us-east-1a"
}
```

## 🎯 Flux de Déploiement Ansible

```
┌────────────────────┐
│  Ansible Control   │
│     Machine        │
│                    │
│ - playbook.yaml    │
│ - inventory.ini    │
│ - group_vars/      │
└─────────┬──────────┘
          │
          │ SSH / WinRM
          ↓
┌──────────────────────────────────────────────┐
│         Serveurs Cibles                      │
├──────────────────────────────────────────────┤
│                                              │
│  1️⃣ Détection OS                            │
│     ansible_os_family → Darwin/Debian/etc    │
│          ↓                                   │
│  2️⃣ Installation OSQuery                    │
│     - apt/yum/homebrew/msi                   │
│     - osquery package                        │
│          ↓                                   │
│  3️⃣ Configuration OSQuery                   │
│     - Deploy template                        │
│     - /etc/osquery/osquery.conf              │
│          ↓                                   │
│  4️⃣ Start OSQuery Service                   │
│     - systemd/launchd/Windows Service        │
│          ↓                                   │
│  [SI enable_opensearch_forwarding=true]      │
│          ↓                                   │
│  5️⃣ Installation Fluent Bit                 │
│     - apt/yum/homebrew/exe                   │
│          ↓                                   │
│  6️⃣ Configuration Fluent Bit                │
│     - Deploy templates                       │
│     - fluent-bit.conf                        │
│     - parsers.conf                           │
│          ↓                                   │
│  7️⃣ Start Fluent Bit Service                │
│     - systemd/brew services/Windows Service  │
│          ↓                                   │
│  ✅ Déploiement Terminé                     │
│                                              │
└──────────────────────────────────────────────┘
```

## 🔐 Flux d'Authentification AWS

```
┌────────────────────────────────────────────┐
│  Instance EC2                               │
│  avec IAM Role                              │
├────────────────────────────────────────────┤
│                                            │
│  Fluent Bit                                │
│    ↓                                       │
│  1. Récupère les credentials IAM           │
│     via Instance Metadata Service          │
│     (IMDS v2)                              │
│                                            │
│  2. Signe les requêtes HTTP avec           │
│     AWS Signature V4                       │
│                                            │
│  3. Envoie vers OpenSearch                 │
│     Header: Authorization: AWS4-...        │
│                                            │
└─────────────────┬──────────────────────────┘
                  │
                  │ HTTPS Port 443
                  ↓
┌────────────────────────────────────────────┐
│  AWS OpenSearch Service                    │
├────────────────────────────────────────────┤
│                                            │
│  1. Vérifie la signature AWS               │
│  2. Vérifie les permissions IAM            │
│  3. Autorise ou refuse l'accès             │
│  4. Indexe les documents                   │
│                                            │
└────────────────────────────────────────────┘
```

## 📊 Exemple de Données dans OpenSearch

### Requête Discover
```
GET /osquery-*/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "name": "process_monitor" }},
        { "range": { "@timestamp": { "gte": "now-1h" }}}
      ]
    }
  }
}
```

### Résultat
```json
{
  "hits": {
    "total": { "value": 1523 },
    "hits": [
      {
        "_index": "osquery-2026.02.07",
        "_source": {
          "@timestamp": "2026-02-07T10:30:45Z",
          "hostname": "web-server-01",
          "environment": "production",
          "name": "process_monitor",
          "columns": {
            "pid": "1234",
            "name": "nginx",
            "path": "/usr/sbin/nginx",
            "cmdline": "nginx: worker process",
            "state": "R"
          },
          "ec2_instance_id": "i-0a1b2c3d4e5f6g7h8",
          "ec2_instance_type": "t3.medium",
          "az": "us-east-1a"
        }
      }
    ]
  }
}
```

## 🎨 Dashboards Typiques

### Dashboard Sécurité
```
┌──────────────────────────────────────────┐
│  Processus Suspects (24h)                │
│  ████████████░░░░ 142 détections         │
├──────────────────────────────────────────┤
│  Connexions Réseau Anormales             │
│  ██████░░░░░░░░░░  67 alertes            │
├──────────────────────────────────────────┤
│  Modifications Fichiers Critiques        │
│  ████░░░░░░░░░░░░  23 événements         │
└──────────────────────────────────────────┘
```

### Dashboard Inventaire
```
┌──────────────────────────────────────────┐
│  Serveurs par Type                       │
│  Linux:    45 │████████████████████      │
│  Windows:  23 │██████████░              │
│  macOS:    12 │█████░                   │
├──────────────────────────────────────────┤
│  Distribution Linux                      │
│  Ubuntu:   32 │████████████████░        │
│  CentOS:   13 │██████░                  │
└──────────────────────────────────────────┘
```

---

**Ce document décrit l'architecture complète du système OSQuery + OpenSearch**

Pour plus de détails :
- Architecture Ansible : voir [ansible/](../ansible/)
- Configuration : voir [docs/OPENSEARCH.md](OPENSEARCH.md)
- Démarrage rapide : voir [docs/QUICKSTART-OPENSEARCH.md](QUICKSTART-OPENSEARCH.md)
