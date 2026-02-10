# Déploiement en Production

Ce guide explique comment déployer l'application OSQuery Dashboard en production.

## 📦 Options de déploiement

### Option 1 : Docker (Recommandé)

Le déploiement Docker est la méthode la plus simple et portable.

#### 1. Build l'image Docker

```bash
cd webapp
docker build -t osquery-dashboard:latest .
```

#### 2. Configurer les variables d'environnement

Éditez le fichier `.env` avec vos paramètres de production.

#### 3. Démarrer avec Docker Compose

```bash
docker-compose up -d
```

#### 4. Vérifier le statut

```bash
docker-compose ps
docker-compose logs -f osquery-dashboard
```

#### 5. Arrêter l'application

```bash
docker-compose down
```

### Option 2 : Systemd (Linux servers)

Pour un déploiement direct sur un serveur Linux.

#### 1. Installer l'application

```bash
# Créer le répertoire d'installation
sudo mkdir -p /opt/osquery-dashboard
sudo cp -r webapp/* /opt/osquery-dashboard/

# Créer l'environnement virtuel
cd /opt/osquery-dashboard
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

#### 2. Configurer les permissions

```bash
# Créer un utilisateur dédié (si nécessaire)
sudo useradd -r -s /bin/false osquery-dashboard

# Définir les permissions
sudo chown -R osquery-dashboard:osquery-dashboard /opt/osquery-dashboard
sudo chmod 600 /opt/osquery-dashboard/.env
```

#### 3. Installer le service systemd

```bash
# Copier le fichier de service
sudo cp osquery-dashboard.service /etc/systemd/system/

# Éditer le service si nécessaire
sudo nano /etc/systemd/system/osquery-dashboard.service

# Recharger systemd
sudo systemctl daemon-reload

# Démarrer le service
sudo systemctl start osquery-dashboard

# Activer au démarrage
sudo systemctl enable osquery-dashboard
```

#### 4. Gérer le service

```bash
# Vérifier le statut
sudo systemctl status osquery-dashboard

# Voir les logs
sudo journalctl -u osquery-dashboard -f

# Redémarrer
sudo systemctl restart osquery-dashboard

# Arrêter
sudo systemctl stop osquery-dashboard
```

### Option 3 : Reverse Proxy avec Nginx

Pour exposer l'application avec HTTPS.

#### 1. Installer Nginx

```bash
sudo apt update
sudo apt install nginx
```

#### 2. Configurer Nginx

Créer `/etc/nginx/sites-available/osquery-dashboard` :

```nginx
server {
    listen 80;
    server_name dashboard.example.com;

    # Redirection HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name dashboard.example.com;

    # Certificats SSL (Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/dashboard.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/dashboard.example.com/privkey.pem;

    # Configuration SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Logs
    access_log /var/log/nginx/osquery-dashboard-access.log;
    error_log /var/log/nginx/osquery-dashboard-error.log;

    # Proxy vers l'application Flask
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Cache des fichiers statiques
    location /static {
        proxy_pass http://127.0.0.1:5000/static;
        expires 1d;
        add_header Cache-Control "public, immutable";
    }
}
```

#### 3. Activer le site

```bash
sudo ln -s /etc/nginx/sites-available/osquery-dashboard /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

#### 4. Obtenir un certificat SSL (Let's Encrypt)

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d dashboard.example.com
```

## 🔐 Sécurité en Production

### 1. Variables d'environnement sensibles

Ne jamais committer le fichier `.env`. Utiliser un gestionnaire de secrets :

**AWS Secrets Manager :**
```python
import boto3
import json

secret_name = "osquery-dashboard-secrets"
region_name = "us-east-1"

client = boto3.client('secretsmanager', region_name=region_name)
response = client.get_secret_value(SecretId=secret_name)
secrets = json.loads(response['SecretString'])
```

**HashiCorp Vault :**
```bash
vault kv get -field=opensearch_password secret/osquery-dashboard
```

### 2. Authentification utilisateur

Ajouter une authentification pour protéger l'accès au dashboard. Exemple avec Flask-Login :

```python
from flask_login import LoginManager, login_required

login_manager = LoginManager()
login_manager.init_app(app)

@app.route('/')
@login_required
def index():
    return render_template('index.html')
```

### 3. Rate Limiting

Limiter les requêtes API pour éviter les abus :

```python
from flask_limiter import Limiter

limiter = Limiter(
    app,
    key_func=lambda: request.remote_addr,
    default_limits=["200 per day", "50 per hour"]
)

@app.route('/api/search')
@limiter.limit("10 per minute")
def search():
    # ...
```

### 4. CORS (si nécessaire)

Pour permettre les requêtes cross-origin :

```python
from flask_cors import CORS

CORS(app, resources={
    r"/api/*": {
        "origins": ["https://your-domain.com"]
    }
})
```

## 📊 Monitoring

### Health Checks

L'endpoint `/api/health` peut être utilisé pour le monitoring :

```bash
# Nagios/Icinga
/usr/lib/nagios/plugins/check_http -H localhost -p 5000 -u /api/health

# Prometheus
curl http://localhost:5000/api/health
```

### Logs

Les logs sont envoyés vers stdout/stderr et peuvent être récupérés :

```bash
# Docker
docker-compose logs -f osquery-dashboard

# Systemd
journalctl -u osquery-dashboard -f

# Intégration avec un système de logs centralisé (ELK, Splunk, etc.)
```

## 🚀 Scaling

### Scaling horizontal

Utiliser plusieurs instances derrière un load balancer :

```yaml
# docker-compose.yml avec scaling
services:
  osquery-dashboard:
    # ...
    deploy:
      replicas: 3
```

### Load Balancer (HAProxy example)

```
frontend osquery_dashboard
    bind *:80
    default_backend dashboard_servers

backend dashboard_servers
    balance roundrobin
    server dash1 10.0.1.10:5000 check
    server dash2 10.0.1.11:5000 check
    server dash3 10.0.1.12:5000 check
```

## 🔧 Maintenance

### Mises à jour

```bash
# Docker
docker-compose pull
docker-compose up -d

# Systemd
cd /opt/osquery-dashboard
git pull
source venv/bin/activate
pip install -r requirements.txt
sudo systemctl restart osquery-dashboard
```

### Backup

Sauvegarder uniquement la configuration `.env` car l'application est stateless.

### Troubleshooting

```bash
# Vérifier les logs
docker-compose logs --tail=100 osquery-dashboard

# Tester la connexion OpenSearch
curl -X GET "http://localhost:5000/api/health"

# Vérifier les ressources
docker stats osquery-dashboard
```

## 📝 Checklist de déploiement

- [ ] Configuration `.env` complétée avec les bons paramètres
- [ ] SECRET_KEY généré aléatoirement
- [ ] SSL/TLS configuré (HTTPS)
- [ ] Authentification utilisateur activée
- [ ] Rate limiting configuré
- [ ] Monitoring et alertes mis en place
- [ ] Backup de la configuration
- [ ] Documentation de la procédure de mise à jour
- [ ] Tests de charge effectués
- [ ] Plan de rollback défini
