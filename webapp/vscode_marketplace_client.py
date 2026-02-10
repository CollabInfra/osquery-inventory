"""VSCode Marketplace API client for extension metadata."""
import requests
from functools import lru_cache
from typing import Dict, List, Any, Optional
from datetime import datetime
import logging

logger = logging.getLogger(__name__)


class VSCodeMarketplaceClient:
    """Client for interacting with VSCode Marketplace API."""
    
    BASE_URL = "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery"
    API_VERSION = "7.2-preview.1"
    
    def __init__(self):
        """Initialize the marketplace client."""
        self.session = requests.Session()
        self.session.headers.update({
            'Accept': 'application/json;api-version=' + self.API_VERSION,
            'Content-Type': 'application/json'
        })
    
    @lru_cache(maxsize=1000)
    def get_extension_info(self, extension_name: str) -> Optional[Dict[str, Any]]:
        """
        Get extension information from VSCode Marketplace.
        
        Args:
            publisher: Publisher name
            extension_name: Extension name
            
        Returns:
            Dictionary with extension info or None if not found
        """
        try:
            # Build the query payload
            payload = {
                "filters": [{
                    "criteria": [
                        {"filterType": 7, "value": f"{extension_name}"}
                    ],
                    "pageNumber": 1,
                    "pageSize": 1,
                    "sortBy": 0,
                    "sortOrder": 0
                }],
                "assetTypes": [],
                "flags": 914
            }
        

            response = self.session.post(self.BASE_URL, json=payload, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            
            # Extract extension from results
            if not data.get('results') or not data['results'][0].get('extensions'):
                logger.warning(f"Extension not found in marketplace: {extension_name}")
                return None
            
            extension = data['results'][0]['extensions'][0]
            
            # Extract relevant information
            return self._parse_extension_data(extension)
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Error fetching extension {extension_name}: {e}")
            return None
        except (KeyError, IndexError) as e:
            logger.error(f"Error parsing extension data for {extension_name}: {e}")
            return None
    
    def _parse_extension_data(self, extension: Dict[str, Any]) -> Dict[str, Any]:
        """Parse raw extension data from marketplace API."""
        try:
            # Get publisher info
            publisher = extension.get('publisher', {})
            publisher_name = publisher.get('publisherName', '')
            is_verified = publisher.get('isDomainVerified', False)
            
            # Get extension info
            display_name = extension.get('displayName', '')
            extension_name = extension.get('extensionName', '')
            
            # Get versions
            versions = extension.get('versions', [])
            latest_version = versions[0] if versions else {}
            version_number = latest_version.get('version', 'Unknown')
            last_updated = latest_version.get('lastUpdated', '')
            
            # Parse last updated date
            last_updated_date = None
            if last_updated:
                try:
                    last_updated_date = datetime.fromisoformat(last_updated.replace('Z', '+00:00')).isoformat()
                except Exception:
                    last_updated_date = last_updated
            
            # Get statistics
            statistics = extension.get('statistics', [])
            install_count = 0
            for stat in statistics:
                if stat.get('statisticName') == 'install':
                    install_count = stat.get('value', 0)
                    break
            
            # Get description
            short_description = extension.get('shortDescription', '')
            
            # Get all versions
            all_versions = []
            for version in versions[:10]:  # Limit to 10 most recent versions
                all_versions.append({
                    'version': version.get('version', ''),
                    'lastUpdated': version.get('lastUpdated', ''),
                    'flags': version.get('flags', '')
                })
            
            return {
                'publisher': publisher_name,
                'extensionName': extension_name,
                'displayName': display_name,
                'shortDescription': short_description,
                'isVerified': is_verified,
                'latestVersion': version_number,
                'lastUpdated': last_updated_date,
                'installCount': install_count,
                'allVersions': all_versions,
                'extensionId': f"{publisher_name}.{extension_name}"
            }
            
        except Exception as e:
            logger.error(f"Error parsing extension data: {e}")
            return {}
    
    def get_multiple_extensions(self, extensions: List[Dict[str, str]]) -> Dict[str, Dict[str, Any]]:
        """
        Get information for multiple extensions.
        
        Args:
            extensions: List of dicts with 'publisher' and 'name' keys
            
        Returns:
            Dictionary mapping extension_id to extension info
        """
        results = {}
        for ext in extensions:
            publisher = ext.get('publisher', '')
            name = ext.get('name', '')
            if publisher and name:
                ext_id = f"{publisher}.{name}"
                info = self.get_extension_info(publisher, name)
                if info:
                    results[ext_id] = info
        
        return results
