"""Flask application for OSQuery Dashboard."""
from flask import Flask, render_template, jsonify, request
from config import Config
from opensearch_client import OSQueryOpenSearchClient
from homebrew_client import HomebrewAPIClient
from vscode_marketplace_client import VSCodeMarketplaceClient

app = Flask(__name__)
app.config.from_object(Config)

# Initialize OpenSearch client
config = Config()
os_client = OSQueryOpenSearchClient(config)
brew_client = HomebrewAPIClient()
vscode_client = VSCodeMarketplaceClient()


@app.route('/')
def index():
    """Render the main dashboard."""
    return render_template('index.html')


@app.route('/api/health')
def health():
    """Health check endpoint."""
    opensearch_healthy = os_client.health_check()
    return jsonify({
        'status': 'healthy' if opensearch_healthy else 'unhealthy',
        'opensearch': opensearch_healthy
    }), 200 if opensearch_healthy else 503


@app.route('/api/stats')
def stats():
    """Get overall statistics."""
    return jsonify(os_client.get_stats())


@app.route('/api/indices')
def indices():
    """Get list of indices."""
    return jsonify({'indices': os_client.get_indices()})


@app.route('/api/hostnames')
def hostnames():
    """Get list of hostnames."""
    return jsonify({'hostnames': os_client.get_hostnames()})


@app.route('/api/environments')
def environments():
    """Get list of environments."""
    return jsonify({'environments': os_client.get_environments()})


@app.route('/api/search')
def search():
    """
    Search OSQuery logs.
    
    Query parameters:
        - query: Free text search
        - hostname: Filter by hostname
        - environment: Filter by environment
        - time_range: Time range (default: 1h)
        - size: Number of results (default: 100)
        - offset: Pagination offset (default: 0)
    """
    query = request.args.get('query')
    hostname = request.args.get('hostname')
    environment = request.args.get('environment')
    time_range = request.args.get('time_range', '1h')
    size = int(request.args.get('size', 100))
    offset = int(request.args.get('offset', 0))
    
    results = os_client.search_logs(
        query=query,
        hostname=hostname,
        environment=environment,
        time_range=time_range,
        size=size,
        offset=offset
    )
    
    return jsonify(results)


@app.route('/api/query-results')
def query_results():
    """
    Get OSQuery query results.
    
    Query parameters:
        - query_name: Name of the query
        - time_range: Time range (default: 1h)
        - size: Number of results (default: 100)
    """
    query_name = request.args.get('query_name')
    time_range = request.args.get('time_range', '1h')
    size = int(request.args.get('size', 100))
    
    results = os_client.get_query_results(
        query_name=query_name,
        time_range=time_range,
        size=size
    )
    
    return jsonify(results)


@app.route('/api/homebrew-packages')
def homebrew_packages():
    """
    Get Homebrew packages with enriched metadata from Homebrew API.
    
    Returns:
        List of packages grouped by hostname and name with Homebrew API data.
    """
    # Get packages from OpenSearch
    packages = os_client.get_homebrew_packages()
    
    # Enrich with Homebrew API data
    enriched_packages = []
    for pkg in packages:
        # Fetch data from Homebrew API
        brew_info = brew_client.get_package_info(pkg['name'])
        
        if brew_info:
            # Compare versions to determine if outdated
            outdated = brew_client.compare_versions(
                pkg.get('version', ''),
                brew_info.get('version', '')
            )
            
            enriched_packages.append({
                **pkg,  # hostname, name, version, path, last_seen
                'desc': brew_info.get('desc', ''),
                'homepage': brew_info.get('homepage', ''),
                'latest_version': brew_info.get('version', ''),
                'outdated': outdated,
                'license': brew_info.get('license'),
                'disabled': brew_info.get('disabled', False),
                'deprecated': brew_info.get('deprecated', False),
                'deprecation_reason': brew_info.get('deprecation_reason'),
                'disable_reason': brew_info.get('disable_reason'),
                'type': brew_info.get('type', 'unknown')
            })
        else:
            # Package not found in Homebrew API
            enriched_packages.append({
                **pkg,
                'desc': '',
                'homepage': '',
                'latest_version': '',
                'outdated': False,
                'license': None,
                'disabled': False,
                'deprecated': False,
                'type': 'unknown'
            })
    
    return jsonify({
        'total': len(enriched_packages),
        'packages': enriched_packages
    })


@app.route('/homebrew')
def homebrew_page():
    """Render the Homebrew packages page."""
    return render_template('homebrew.html')


@app.route('/vscode-extensions')
def vscode_extensions_page():
    """Render the VSCode extensions page."""
    return render_template('vscode_extensions.html')


@app.route('/vscode-extension/<name>')
def vscode_extension_detail_page(name: str):
    """Render the VSCode extension detail page."""
    return render_template('vscode_extension_detail.html')


@app.route('/api/vscode-extensions')
def get_vscode_extensions():
    """Get all VSCode extensions with marketplace metadata."""
    # Get summary from OpenSearch
    summary = os_client.get_vscode_extensions_summary()
    
    # Enrich each unique extension with marketplace data
    enriched_extensions = []
    for ext_id, ext_data in summary.items():
        publisher = ext_data['publisher']
        name = ext_data['name']
        
        # Get marketplace info
        marketplace_info = vscode_client.get_extension_info(name)
        
        extension_info = {
            'extension_id': ext_id,
            'publisher': publisher,
            'name': name,
            'installations_count': ext_data['total_hosts'],
            'versions_found': ext_data['versions'],
            'installations': ext_data['installations']
        }
        
        # Add marketplace data if available
        if marketplace_info:
            extension_info.update({
                'displayName': marketplace_info.get('displayName', name),
                'shortDescription': marketplace_info.get('shortDescription', ''),
                'isVerified': marketplace_info.get('isVerified', False),
                'latestVersion': marketplace_info.get('latestVersion', ''),
                'lastUpdated': marketplace_info.get('lastUpdated', ''),
                'marketplaceInstalls': marketplace_info.get('installCount', 0)
            })
        else:
            extension_info.update({
                'displayName': name,
                'shortDescription': 'Not found in marketplace',
                'isVerified': False,
                'latestVersion': 'Unknown',
                'lastUpdated': None,
                'marketplaceInstalls': 0
            })
        
        enriched_extensions.append(extension_info)
    
    return jsonify({
        'total': len(enriched_extensions),
        'extensions': enriched_extensions
    })


@app.route('/api/vscode-extension/<name>')
def get_vscode_extension_detail(name: str):
    """Get detailed information about a specific VSCode extension."""
    ext_id = name
    
    # Get all installations from OpenSearch
    all_extensions = os_client.get_vscode_extensions()
    print(all_extensions)
    matching_extensions = [ext for ext in all_extensions if ext['name'] == ext_id]
    
    if not matching_extensions:
        return jsonify({'error': 'Extension not found'}), 404
    
    # Get marketplace info
    marketplace_info = vscode_client.get_extension_info(name)
    
    # Group by version
    versions = {}
    for ext in matching_extensions:
        version = ext['version']
        if version not in versions:
            versions[version] = []
        versions[version].append({
            'hostname': ext['hostname'],
            'username': ext['username'],
            'path': ext['path'],
            'last_seen': ext['last_seen']
        })
    
    # Check if versions are latest
    latest_version = marketplace_info.get('latestVersion', '') if marketplace_info else ''
    version_details = []
    for version, installations in versions.items():
        version_details.append({
            'version': version,
            'is_latest': version == latest_version,
            'installation_count': len(installations),
            'installations': installations
        })
    
    # Sort versions (latest first)
    version_details.sort(key=lambda x: x['version'], reverse=True)
    
    result = {
        'extension_id': ext_id,
        'name': name,
        'total_installations': len(matching_extensions),
        'versions': version_details
    }
    
    # Add marketplace data
    if marketplace_info:
        result.update({
            'displayName': marketplace_info.get('displayName', name),
            'shortDescription': marketplace_info.get('shortDescription', ''),
            'isVerified': marketplace_info.get('isVerified', False),
            'latestVersion': marketplace_info.get('latestVersion', ''),
            'lastUpdated': marketplace_info.get('lastUpdated', ''),
            'marketplaceInstalls': marketplace_info.get('installCount', 0),
            'allVersions': marketplace_info.get('allVersions', []),
            'publisher': marketplace_info.get('publisher', ''),
        })
    
    return jsonify(result)


@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors."""
    return jsonify({'error': 'Not found'}), 404


@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors."""
    return jsonify({'error': 'Internal server error'}), 500


if __name__ == '__main__':
    app.run(
        host=config.HOST,
        port=config.PORT,
        debug=config.DEBUG
    )
