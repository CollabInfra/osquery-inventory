"""Configuration management for the OSQuery Dashboard."""
import os
from dotenv import load_dotenv

load_dotenv()


class Config:
    """Application configuration."""
    
    # Flask
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')
    FLASK_ENV = os.getenv('FLASK_ENV', 'development')
    DEBUG = os.getenv('FLASK_DEBUG', 'false').lower() == 'true'
    
    # Server
    HOST = os.getenv('HOST', '0.0.0.0')
    PORT = int(os.getenv('PORT', '5001'))
    
    # OpenSearch
    OPENSEARCH_HOST = os.getenv('OPENSEARCH_HOST', 'localhost')
    OPENSEARCH_PORT = int(os.getenv('OPENSEARCH_PORT', '9200'))
    OPENSEARCH_USE_SSL = os.getenv('OPENSEARCH_USE_SSL', 'true').lower() == 'true'
    OPENSEARCH_VERIFY_CERTS = os.getenv('OPENSEARCH_VERIFY_CERTS', 'true').lower() == 'true'
    OPENSEARCH_INDEX_PREFIX = os.getenv('OPENSEARCH_INDEX_PREFIX', 'osquery-')
    
    # AWS Configuration
    AWS_REGION = os.getenv('AWS_REGION', 'us-east-1')
    AWS_ACCESS_KEY_ID = os.getenv('AWS_ACCESS_KEY_ID')
    AWS_SECRET_ACCESS_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')
    
    # Basic Auth (alternative to IAM)
    OPENSEARCH_USERNAME = os.getenv('OPENSEARCH_USERNAME')
    OPENSEARCH_PASSWORD = os.getenv('OPENSEARCH_PASSWORD')
    
    @property
    def opensearch_url(self):
        """Get the full OpenSearch URL."""
        protocol = 'https' if self.OPENSEARCH_USE_SSL else 'http'
        return f"{protocol}://{self.OPENSEARCH_HOST}:{self.OPENSEARCH_PORT}"
    
    @property
    def use_basic_auth(self):
        """Check if basic auth is configured."""
        return bool(self.OPENSEARCH_USERNAME and self.OPENSEARCH_PASSWORD)
    
    @property
    def use_aws_auth(self):
        """Check if AWS IAM auth should be used."""
        return bool(self.AWS_ACCESS_KEY_ID and self.AWS_SECRET_ACCESS_KEY)
