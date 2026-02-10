"""OpenSearch client for querying OSQuery data."""
from opensearchpy import OpenSearch
from requests_aws4auth import AWS4Auth
import boto3
from typing import Dict, List, Any, Optional
from config import Config


class OSQueryOpenSearchClient:
    """Client for interacting with OpenSearch to query OSQuery data."""
    
    def __init__(self, config: Config):
        """Initialize the OpenSearch client."""
        self.config = config
        self.client = self._create_client()
    
    def _create_client(self) -> OpenSearch:
        """Create and configure the OpenSearch client."""
        # Prepare auth
        auth = None
        if self.config.use_basic_auth:
            auth = (self.config.OPENSEARCH_USERNAME, self.config.OPENSEARCH_PASSWORD)
        elif self.config.use_aws_auth:
            credentials = boto3.Session(
                aws_access_key_id=self.config.AWS_ACCESS_KEY_ID,
                aws_secret_access_key=self.config.AWS_SECRET_ACCESS_KEY,
                region_name=self.config.AWS_REGION
            ).get_credentials()
            auth = AWS4Auth(
                credentials.access_key,
                credentials.secret_key,
                self.config.AWS_REGION,
                'es'            )
        
        # Create client
        return OpenSearch(
            hosts=[{
                'host': self.config.OPENSEARCH_HOST,
                'port': self.config.OPENSEARCH_PORT
            }],
            http_auth=auth,
            use_ssl=self.config.OPENSEARCH_USE_SSL,
            verify_certs=self.config.OPENSEARCH_VERIFY_CERTS,
            ssl_show_warn=False
        )
    
    def get_indices(self) -> List[str]:
        """Get list of all OSQuery indices."""
        try:
            indices = self.client.indices.get_alias(
                index=f"{self.config.OPENSEARCH_INDEX_PREFIX}*"
            )
            return sorted(indices.keys())
        except Exception as e:
            print(f"Error getting indices: {e}")
            return []
    
    def search_logs(
        self,
        query: Optional[str] = None,
        hostname: Optional[str] = None,
        environment: Optional[str] = None,
        time_range: str = "1h",
        size: int = 100,
        offset: int = 0
    ) -> Dict[str, Any]:
        """
        Search OSQuery logs with filters.
        
        Args:
            query: Free text search query
            hostname: Filter by hostname
            environment: Filter by environment
            time_range: Time range (e.g., '1h', '24h', '7d')
            size: Number of results to return
            offset: Pagination offset
        
        Returns:
            Dictionary with hits and total count
        """
        # Build query
        must_clauses = []
        
        # Time range filter
        time_filter = self._parse_time_range(time_range)
        must_clauses.append({
            "range": {
                "@timestamp": time_filter
            }
        })
        
        # Hostname filter
        if hostname:
            must_clauses.append({
                "term": {"hostname.keyword": hostname}
            })
        
        # Environment filter
        if environment:
            must_clauses.append({
                "term": {"environment.keyword": environment}
            })
        
        # Free text search
        if query:
            must_clauses.append({
                "query_string": {
                    "query": query,
                    "default_field": "*"
                }
            })
        
        # Build search body
        search_body = {
            "query": {
                "bool": {
                    "must": must_clauses
                }
            },
            "sort": [
                {"@timestamp": {"order": "desc"}}
            ],
            "from": offset,
            "size": size
        }
        
        try:
            response = self.client.search(
                index=f"{self.config.OPENSEARCH_INDEX_PREFIX}*",
                body=search_body
            )
            
            return {
                "total": response["hits"]["total"]["value"],
                "hits": [hit["_source"] for hit in response["hits"]["hits"]]
            }
        except Exception as e:
            print(f"Error searching logs: {e}")
            return {"total": 0, "hits": []}
    
    def get_hostnames(self) -> List[str]:
        """Get list of unique hostnames."""
        try:
            response = self.client.search(
                index=f"{self.config.OPENSEARCH_INDEX_PREFIX}*",
                body={
                    "size": 0,
                    "aggs": {
                        "hostnames": {
                            "terms": {
                                "field": "hostname.keyword",
                                "size": 1000
                            }
                        }
                    }
                }
            )
            
            buckets = response["aggregations"]["hostnames"]["buckets"]
            return [bucket["key"] for bucket in buckets]
        except Exception as e:
            print(f"Error getting hostnames: {e}")
            return []
    
    def get_environments(self) -> List[str]:
        """Get list of unique environments."""
        try:
            response = self.client.search(
                index=f"{self.config.OPENSEARCH_INDEX_PREFIX}*",
                body={
                    "size": 0,
                    "aggs": {
                        "environments": {
                            "terms": {
                                "field": "environment.keyword",
                                "size": 100
                            }
                        }
                    }
                }
            )
            
            buckets = response["aggregations"]["environments"]["buckets"]
            return [bucket["key"] for bucket in buckets]
        except Exception as e:
            print(f"Error getting environments: {e}")
            return []
    
    def get_stats(self) -> Dict[str, Any]:
        """Get overall statistics."""
        try:
            # Count documents in last 24h
            response = self.client.search(
                index=f"{self.config.OPENSEARCH_INDEX_PREFIX}*",
                body={
                    "size": 0,
                    "query": {
                        "range": {
                            "@timestamp": {
                                "gte": "now-24h"
                            }
                        }
                    },
                    "aggs": {
                        "by_hour": {
                            "date_histogram": {
                                "field": "@timestamp",
                                "fixed_interval": "1h"
                            }
                        }
                    }
                }
            )
            
            return {
                "total_last_24h": response["hits"]["total"]["value"],
                "by_hour": [
                    {
                        "timestamp": bucket["key_as_string"],
                        "count": bucket["doc_count"]
                    }
                    for bucket in response["aggregations"]["by_hour"]["buckets"]
                ],
                "hostnames_count": len(self.get_hostnames()),
                "environments_count": len(self.get_environments())
            }
        except Exception as e:
            print(f"Error getting stats: {e}")
            return {}
    
    def get_query_results(
        self,
        query_name: Optional[str] = None,
        time_range: str = "1h",
        size: int = 100
    ) -> Dict[str, Any]:
        """
        Get results from specific OSQuery queries.
        
        Args:
            query_name: Name of the query (e.g., 'processes', 'listening_ports')
            time_range: Time range
            size: Number of results
        
        Returns:
            Query results
        """
        must_clauses = [
            {
                "range": {
                    "@timestamp": self._parse_time_range(time_range)
                }
            }
        ]
        
        if query_name:
            must_clauses.append({
                "term": {"name.keyword": query_name}
            })
        
        try:
            response = self.client.search(
                index=f"{self.config.OPENSEARCH_INDEX_PREFIX}*",
                body={
                    "query": {
                        "bool": {
                            "must": must_clauses
                        }
                    },
                    "sort": [{"@timestamp": {"order": "desc"}}],
                    "size": size
                }
            )
            
            return {
                "total": response["hits"]["total"]["value"],
                "results": [hit["_source"] for hit in response["hits"]["hits"]]
            }
        except Exception as e:
            print(f"Error getting query results: {e}")
            return {"total": 0, "results": []}
    
    def _parse_time_range(self, time_range: str) -> Dict[str, str]:
        """Parse time range string to OpenSearch format."""
        return {"gte": f"now-{time_range}"}
    
    def get_homebrew_packages(self) -> List[Dict[str, Any]]:
        """
        Get all Homebrew packages grouped by hostname and package name,
        showing only the latest version per host/package combination.
        
        Returns:
            List of packages with structure:
            [
                {
                    "hostname": "server01",
                    "name": "git",
                    "version": "2.43.0",
                    "path": "/opt/homebrew/Cellar/git/2.43.0",
                    "last_seen": "2024-02-08T10:00:00Z"
                },
                ...
            ]
        """
        try:
            # Query to get latest packages grouped by hostname and name
            response = self.client.search(
                index=f"{self.config.OPENSEARCH_INDEX_PREFIX}*",
                body={
                    "size": 0,
                    "query": {
                        "bool": {
                            "must": [
                                {
                                    "exists": {
                                        "field": "decorations.name"
                                    }
                                },
                                {
                                    "term": {
                                        "name.keyword": "pack_software-inventory_homebrew_packages"
                                    }
                                }
                            ]
                        }
                    },
                    "aggs": {
                        "by_hostname": {
                            "terms": {
                                "field": "decorations.hostname.keyword",
                                "size": 1000
                            },
                            "aggs": {
                                "by_package": {
                                    "terms": {
                                        "field": "columns.name.keyword",
                                        "size": 10000
                                    },
                                    "aggs": {
                                        "latest": {
                                            "top_hits": {
                                                "size": 1,
                                                "sort": [
                                                    {
                                                        "@timestamp": {
                                                            "order": "desc"
                                                        }
                                                    }
                                                ],
                                                "_source": [
                                                    "columns.name",
                                                    "columns.version",
                                                    "columns.path",
                                                    "@timestamp",
                                                    "decorations.hostname"
                                                ]
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            )
            
            # Process aggregations
            packages = []
            for host_bucket in response["aggregations"]["by_hostname"]["buckets"]:
                hostname = host_bucket["key"]
                
                for pkg_bucket in host_bucket["by_package"]["buckets"]:
                    pkg_name = pkg_bucket["key"]
                    latest_hit = pkg_bucket["latest"]["hits"]["hits"][0]["_source"]
                    
                    packages.append({
                        "hostname": hostname,
                        "name": pkg_name,
                        "version": latest_hit.get("columns", {}).get("version", ""),
                        "path": latest_hit.get("columns", {}).get("path", ""),
                        "last_seen": latest_hit.get("@timestamp", "")
                    })
            
            return sorted(packages, key=lambda x: (x["hostname"], x["name"]))
            
        except Exception as e:
            print(f"Error getting Homebrew packages: {e}")
            return []
    
    def get_vscode_extensions(self) -> List[Dict[str, Any]]:
        """
        Get all VSCode extensions from OSQuery data.
        Groups by hostname, publisher, and extension name, returning only the latest version.
        
        Returns:
            List of extension dictionaries with hostname, publisher, name, version, etc.
        """
        try:
            # Search for VSCode extensions data
            response = self.client.search(
                index=f"{self.config.OPENSEARCH_INDEX_PREFIX}*",
                body={
                    "size": 0,
                    "query": {
                        "match": {
                            "name": "vscode_extensions"
                        }
                    },
                    "aggs": {
                        "by_hostname": {
                            "terms": {
                                "field": "decorations.host_uuid.keyword",
                                "size": 10000
                            },
                            "aggs": {
                                "by_publisher": {
                                    "terms": {
                                        "field": "columns.publisher.keyword",
                                        "size": 10000
                                    },
                                    "aggs": {
                                        "by_extension": {
                                            "terms": {
                                                "field": "columns.extension_name.keyword",
                                                "size": 10000
                                            },
                                            "aggs": {
                                                "latest": {
                                                    "top_hits": {
                                                        "size": 1,
                                                        "sort": [
                                                            {
                                                                "@timestamp": {
                                                                    "order": "desc"
                                                                }
                                                            }
                                                        ],
                                                        "_source": [
                                                            "columns.extension_name",
                                                            "columns.version",
                                                            "columns.publisher",
                                                            "columns.username",
                                                            "columns.path",
                                                            "columns.publisher_id",
                                                            "columns.installed_at",
                                                            "@timestamp",
                                                            "decorations.hostname"
                                                        ]
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            )
            
            # Process aggregations
            extensions = []
            for host_bucket in response["aggregations"]["by_hostname"]["buckets"]:
                hostname = host_bucket["key"]
                
                for pub_bucket in host_bucket["by_publisher"]["buckets"]:
                    publisher = pub_bucket["key"]
                    
                    for ext_bucket in pub_bucket["by_extension"]["buckets"]:
                        extension_name = ext_bucket["key"]
                        latest_hit = ext_bucket["latest"]["hits"]["hits"][0]["_source"]
                        columns = latest_hit.get("columns", {})
                        
                        extensions.append({
                            "hostname": hostname,
                            "publisher": publisher,
                            "name": extension_name,
                            "version": columns.get("version", ""),
                            "username": columns.get("username", ""),
                            "path": columns.get("path", ""),
                            "installed_at": columns.get("installed_at", ""),
                            "last_seen": latest_hit.get("@timestamp", ""),
                            "extension_id": f"{publisher}.{extension_name}"
                        })
            
            return sorted(extensions, key=lambda x: (x["hostname"], x["publisher"], x["name"]))
            
        except Exception as e:
            print(f"Error getting VSCode extensions: {e}")
            return []
    
    def get_vscode_extensions_summary(self) -> Dict[str, Any]:
        """
        Get summary of VSCode extensions grouped by unique extension (publisher.name).
        
        Returns:
            Dictionary with unique extensions and their installation counts per host.
        """
        try:
            all_extensions = self.get_vscode_extensions()
            
            # Group by extension_id
            summary = {}
            for ext in all_extensions:
                ext_id = ext["extension_id"]
                
                if ext_id not in summary:
                    summary[ext_id] = {
                        "extension_id": ext_id,
                        "publisher": ext["publisher"],
                        "publisher_id": ext.get("publisher_id", ""),
                        "name": ext["name"],
                        "installations": [],
                        "total_hosts": 0,
                        "versions": set()
                    }
                
                summary[ext_id]["installations"].append({
                    "hostname": ext["hostname"],
                    "version": ext["version"],
                    "username": ext["username"],
                    "path": ext["path"],
                    "last_seen": ext["last_seen"]
                })
                summary[ext_id]["versions"].add(ext["version"])
            
            # Convert sets to lists and count hosts
            for ext_id in summary:
                summary[ext_id]["versions"] = sorted(list(summary[ext_id]["versions"]))
                summary[ext_id]["total_hosts"] = len(set(inst["hostname"] for inst in summary[ext_id]["installations"]))
            
            return summary
            
        except Exception as e:
            print(f"Error getting VSCode extensions summary: {e}")
            return {}
    
    def health_check(self) -> bool:
        """Check if OpenSearch is accessible."""
        try:
            self.client.cluster.health()
            return True
        except Exception:
            return False
