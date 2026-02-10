// Global state
let allPackages = [];
let filteredPackages = [];

// Initialize the page
document.addEventListener('DOMContentLoaded', function() {
    checkHealth();
    loadPackages();
    
    // Add event listeners for filters
    document.getElementById('searchFilter').addEventListener('input', applyFilters);
    document.getElementById('hostFilter').addEventListener('change', applyFilters);
    document.getElementById('statusFilter').addEventListener('change', applyFilters);
});

// Check OpenSearch health
async function checkHealth() {
    try {
        const response = await fetch('/api/health');
        const data = await response.json();
        
        const indicator = document.getElementById('statusIndicator');
        const statusText = document.getElementById('statusText');
        
        if (data.opensearch) {
            indicator.className = 'status-indicator healthy';
            statusText.textContent = 'Connecté';
        } else {
            indicator.className = 'status-indicator unhealthy';
            statusText.textContent = 'Déconnecté';
        }
    } catch (error) {
        console.error('Erreur lors de la vérification de santé:', error);
        document.getElementById('statusIndicator').className = 'status-indicator unhealthy';
        document.getElementById('statusText').textContent = 'Erreur';
    }
}

// Load packages from API
async function loadPackages() {
    const loadingIndicator = document.getElementById('loadingIndicator');
    const tableContainer = document.getElementById('tableContainer');
    const errorContainer = document.getElementById('errorContainer');
    
    loadingIndicator.style.display = 'block';
    tableContainer.style.display = 'none';
    errorContainer.style.display = 'none';
    
    try {
        const response = await fetch('/api/homebrew-packages');
        const data = await response.json();
        
        allPackages = data.packages || [];
        filteredPackages = [...allPackages];
        
        // Populate host filter
        populateHostFilter();
        
        // Update statistics
        updateStatistics();
        
        // Display packages
        displayPackages();
        
        loadingIndicator.style.display = 'none';
        tableContainer.style.display = 'block';
        
    } catch (error) {
        console.error('Erreur lors du chargement des packages:', error);
        loadingIndicator.style.display = 'none';
        errorContainer.style.display = 'block';
        errorContainer.textContent = 'Erreur lors du chargement des packages Homebrew. Vérifiez que les données sont disponibles dans OpenSearch.';
    }
}

// Populate host filter dropdown
function populateHostFilter() {
    const hostFilter = document.getElementById('hostFilter');
    const hosts = [...new Set(allPackages.map(pkg => pkg.hostname))].sort();
    
    // Clear existing options except first one
    hostFilter.innerHTML = '<option value="">Tous les hôtes</option>';
    
    hosts.forEach(host => {
        const option = document.createElement('option');
        option.value = host;
        option.textContent = host;
        hostFilter.appendChild(option);
    });
}

// Update statistics
function updateStatistics() {
    const total = allPackages.length;
    const outdated = allPackages.filter(pkg => pkg.outdated).length;
    const deprecated = allPackages.filter(pkg => pkg.deprecated).length;
    const hosts = new Set(allPackages.map(pkg => pkg.hostname)).size;
    
    document.getElementById('totalPackages').textContent = total.toLocaleString();
    document.getElementById('outdatedCount').textContent = outdated.toLocaleString();
    document.getElementById('deprecatedCount').textContent = deprecated.toLocaleString();
    document.getElementById('hostsCount').textContent = hosts.toLocaleString();
}

// Apply filters
function applyFilters() {
    const searchText = document.getElementById('searchFilter').value.toLowerCase();
    const hostFilter = document.getElementById('hostFilter').value;
    const statusFilter = document.getElementById('statusFilter').value;
    
    filteredPackages = allPackages.filter(pkg => {
        // Search filter
        const matchesSearch = !searchText || 
            pkg.name.toLowerCase().includes(searchText) ||
            (pkg.desc && pkg.desc.toLowerCase().includes(searchText));
        
        // Host filter
        const matchesHost = !hostFilter || pkg.hostname === hostFilter;
        
        // Status filter
        let matchesStatus = true;
        if (statusFilter === 'outdated') {
            matchesStatus = pkg.outdated === true;
        } else if (statusFilter === 'uptodate') {
            matchesStatus = pkg.outdated === false && !pkg.deprecated && !pkg.disabled;
        } else if (statusFilter === 'deprecated') {
            matchesStatus = pkg.deprecated === true;
        } else if (statusFilter === 'disabled') {
            matchesStatus = pkg.disabled === true;
        }
        
        return matchesSearch && matchesHost && matchesStatus;
    });
    
    displayPackages();
}

// Display packages in table
function displayPackages() {
    const tbody = document.getElementById('packagesTableBody');
    const displayCount = document.getElementById('displayCount');
    
    tbody.innerHTML = '';
    displayCount.textContent = `${filteredPackages.length} package(s)`;
    
    if (filteredPackages.length === 0) {
        const row = tbody.insertRow();
        const cell = row.insertCell(0);
        cell.colSpan = 8;
        cell.style.textAlign = 'center';
        cell.style.padding = '40px';
        cell.style.color = 'var(--text-secondary)';
        cell.textContent = 'Aucun package trouvé';
        return;
    }
    
    filteredPackages.forEach(pkg => {
        const row = tbody.insertRow();
        
        // Hostname
        const cellHost = row.insertCell(0);
        cellHost.textContent = pkg.hostname;
        
        // Package name
        const cellName = row.insertCell(1);
        cellName.innerHTML = `<span class="package-name">${escapeHtml(pkg.name)}</span>`;
        
        // Description
        const cellDesc = row.insertCell(2);
        cellDesc.innerHTML = `<span class="package-desc">${escapeHtml(pkg.desc || '-')}</span>`;
        cellDesc.style.maxWidth = '300px';
        
        // Installed version
        const cellInstalled = row.insertCell(3);
        cellInstalled.innerHTML = `<span class="version-installed">${escapeHtml(pkg.version || '-')}</span>`;
        
        // Latest version
        const cellLatest = row.insertCell(4);
        cellLatest.innerHTML = `<span class="version-latest">${escapeHtml(pkg.latest_version || '-')}</span>`;
        
        // Status badges
        const cellStatus = row.insertCell(5);
        const badges = [];
        
        if (pkg.outdated) {
            badges.push('<span class="badge badge-outdated">Outdated</span>');
        } else if (pkg.latest_version && !pkg.deprecated && !pkg.disabled) {
            badges.push('<span class="badge badge-uptodate">Up-to-date</span>');
        }
        
        if (pkg.deprecated) {
            badges.push('<span class="badge badge-deprecated">Deprecated</span>');
        }
        
        if (pkg.disabled) {
            badges.push('<span class="badge badge-disabled">Disabled</span>');
        }
        
        cellStatus.innerHTML = badges.join(' ') || '-';
        
        // License
        const cellLicense = row.insertCell(6);
        cellLicense.textContent = pkg.license || '-';
        cellLicense.style.fontSize = '0.875rem';
        
        // Homepage
        const cellHomepage = row.insertCell(7);
        if (pkg.homepage) {
            cellHomepage.innerHTML = `<a href="${escapeHtml(pkg.homepage)}" target="_blank" rel="noopener noreferrer" class="nav-link">🔗</a>`;
        } else {
            cellHomepage.textContent = '-';
        }
    });
}

// Escape HTML to prevent XSS
function escapeHtml(text) {
    if (!text) return '';
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return String(text).replace(/[&<>"']/g, m => map[m]);
}
