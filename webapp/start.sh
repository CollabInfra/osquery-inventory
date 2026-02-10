#!/bin/bash

# Quick start script for OSQuery Dashboard

set -e

echo "🚀 OSQuery Dashboard - Quick Start"
echo "=================================="

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 n'est pas installé. Veuillez installer Python 3.8 ou supérieur."
    exit 1
fi

echo "✅ Python trouvé: $(python3 --version)"

# Check if Poetry is installed
if ! command -v poetry &> /dev/null; then
    echo "⚠️  Poetry n'est pas installé."
    echo "📦 Installation de Poetry..."
    curl -sSL https://install.python-poetry.org | python3 -
    
    # Add Poetry to PATH for current session
    export PATH="$HOME/.local/bin:$PATH"
    
    if ! command -v poetry &> /dev/null; then
        echo "❌ Installation de Poetry échouée."
        echo "   Veuillez installer Poetry manuellement: https://python-poetry.org/docs/#installation"
        echo "   Ou utilisez pip: pip install -r requirements.txt"
        exit 1
    fi
fi

echo "✅ Poetry trouvé: $(poetry --version)"

# Check if .env file exists
if [ ! -f .env ]; then
    echo "📝 Création du fichier .env à partir de .env.example..."
    cp .env.example .env
    echo "⚠️  Veuillez éditer le fichier .env avec vos paramètres OpenSearch!"
    echo "   Puis relancez ce script."
    exit 0
fi

# Install dependencies with Poetry
echo "📥 Installation des dépendances avec Poetry..."
poetry install --without=dev

echo ""
echo "✅ Installation terminée!"
echo ""
echo "🌐 Démarrage de l'application..."
echo "   L'application sera accessible sur http://localhost:5001"
echo ""
echo "   Appuyez sur Ctrl+C pour arrêter"
echo ""

# Start the application
poetry run python app.py
