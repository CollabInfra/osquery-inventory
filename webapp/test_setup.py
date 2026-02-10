#!/usr/bin/env python3
"""
Test script to verify OpenSearch connection and basic functionality.
Run this before starting the application.
"""

import sys
import os

def check_requirements():
    """Check if all required packages are installed."""
    print("🔍 Vérification des dépendances...")
    try:
        import flask
        import opensearchpy
        import dotenv
        import boto3
        import requests_aws4auth
        print("✅ Toutes les dépendances sont installées")
        return True
    except ImportError as e:
        print(f"❌ Dépendance manquante: {e}")
        print("   Exécutez: pip install -r requirements.txt")
        return False

def check_env_file():
    """Check if .env file exists."""
    print("\n🔍 Vérification du fichier .env...")
    if os.path.exists('.env'):
        print("✅ Fichier .env trouvé")
        return True
    else:
        print("❌ Fichier .env non trouvé")
        print("   Exécutez: cp .env.example .env")
        print("   Puis éditez .env avec vos paramètres")
        return False

def test_opensearch_connection():
    """Test connection to OpenSearch."""
    print("\n🔍 Test de connexion OpenSearch...")
    try:
        from config import Config
        from opensearch_client import OSQueryOpenSearchClient
        
        config = Config()
        print(f"   Endpoint: {config.opensearch_url}")
        print(f"   Index prefix: {config.OPENSEARCH_INDEX_PREFIX}")
        
        client = OSQueryOpenSearchClient(config)
        
        if client.health_check():
            print("✅ Connexion OpenSearch réussie")
            
            # Get indices
            indices = client.get_indices()
            print(f"   Indices trouvés: {len(indices)}")
            if indices:
                for idx in indices[:5]:  # Show first 5
                    print(f"     - {idx}")
                if len(indices) > 5:
                    print(f"     ... et {len(indices) - 5} autres")
            
            # Get stats
            stats = client.get_stats()
            if stats:
                print(f"   Événements (24h): {stats.get('total_last_24h', 'N/A')}")
                print(f"   Hôtes actifs: {stats.get('hostnames_count', 'N/A')}")
                print(f"   Environnements: {stats.get('environments_count', 'N/A')}")
            
            return True
        else:
            print("❌ Impossible de se connecter à OpenSearch")
            print("   Vérifiez vos paramètres dans .env")
            return False
            
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return False

def test_basic_search():
    """Test basic search functionality."""
    print("\n🔍 Test de recherche basique...")
    try:
        from config import Config
        from opensearch_client import OSQueryOpenSearchClient
        
        config = Config()
        client = OSQueryOpenSearchClient(config)
        
        # Search last hour
        results = client.search_logs(time_range="1h", size=5)
        
        if results and results.get('total', 0) > 0:
            print(f"✅ Recherche réussie: {results['total']} résultats trouvés")
            print(f"   Affichage des {len(results['hits'])} premiers résultats")
            return True
        else:
            print("⚠️  Aucun résultat trouvé (pas forcément une erreur)")
            print("   Vérifiez que des données sont présentes dans OpenSearch")
            return True  # Not a failure, just no data
            
    except Exception as e:
        print(f"❌ Erreur lors de la recherche: {e}")
        return False

def main():
    """Run all tests."""
    print("=" * 60)
    print("🧪 OSQuery Dashboard - Tests de Pré-démarrage")
    print("=" * 60)
    
    results = []
    
    # Run tests
    results.append(("Dépendances", check_requirements()))
    results.append(("Fichier .env", check_env_file()))
    
    # Only test OpenSearch if previous tests passed
    if all(r[1] for r in results):
        results.append(("Connexion OpenSearch", test_opensearch_connection()))
        if results[-1][1]:  # If connection succeeded
            results.append(("Recherche", test_basic_search()))
    
    # Summary
    print("\n" + "=" * 60)
    print("📊 Résumé des Tests")
    print("=" * 60)
    
    for test_name, passed in results:
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status} - {test_name}")
    
    print("\n" + "=" * 60)
    
    # Final verdict
    if all(r[1] for r in results):
        print("✅ Tous les tests sont passés!")
        print("   Vous pouvez démarrer l'application:")
        print("   python app.py")
        print("   ou: ./start.sh")
        return 0
    else:
        print("❌ Certains tests ont échoué")
        print("   Corrigez les problèmes avant de démarrer l'application")
        return 1

if __name__ == "__main__":
    sys.exit(main())
