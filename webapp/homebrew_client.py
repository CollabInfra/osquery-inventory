"""Homebrew API client for fetching package metadata."""
import requests
from typing import Dict, Any, Optional
from functools import lru_cache


class HomebrewAPIClient:
    """Client for interacting with Homebrew API."""
    
    FORMULA_API_URL = "https://formulae.brew.sh/api/formula/{}.json"
    CASK_API_URL = "https://formulae.brew.sh/api/cask/{}.json"
    
    @staticmethod
    @lru_cache(maxsize=1000)
    def get_package_info(package_name: str, is_cask: bool = False) -> Optional[Dict[str, Any]]:
        """
        Fetch package information from Homebrew API.
        
        Args:
            package_name: Name of the package
            is_cask: True if it's a cask, False if it's a formula
        
        Returns:
            Package information dictionary or None if not found
        """
        try:
            # Try as formula first, then as cask
            urls_to_try = []
            if is_cask:
                urls_to_try = [
                    HomebrewAPIClient.CASK_API_URL.format(package_name),
                    HomebrewAPIClient.FORMULA_API_URL.format(package_name)
                ]
            else:
                urls_to_try = [
                    HomebrewAPIClient.FORMULA_API_URL.format(package_name),
                    HomebrewAPIClient.CASK_API_URL.format(package_name)
                ]
            
            for url in urls_to_try:
                response = requests.get(url, timeout=5)
                if response.status_code == 200:
                    data = response.json()
                    return {
                        'name': data.get('name', package_name),
                        'desc': data.get('desc', ''),
                        'homepage': data.get('homepage', ''),
                        'version': data.get('version') or data.get('versions', {}).get('stable', ''),
                        'license': data.get('license'),
                        'disabled': data.get('disabled', False),
                        'deprecated': data.get('deprecated', False),
                        'deprecation_reason': data.get('deprecation_reason'),
                        'disable_reason': data.get('disable_reason'),
                        'type': 'cask' if 'cask' in url else 'formula'
                    }
            
            return None
            
        except Exception as e:
            print(f"Error fetching Homebrew info for {package_name}: {e}")
            return None
    
    @staticmethod
    def compare_versions(installed_version: str, latest_version: str) -> bool:
        """
        Compare versions to determine if package is outdated.
        
        Args:
            installed_version: Version installed on the system
            latest_version: Latest version from Homebrew API
        
        Returns:
            True if outdated, False otherwise
        """
        if not installed_version or not latest_version:
            return False
        
        # Simple string comparison (could be improved with proper version parsing)
        return installed_version != latest_version
