// Global state
let currentPage = 0;
let currentFilters = {};
let eventsChart = null;

// Initialize the dashboard
document.addEventListener('DOMContentLoaded', function() {
    checkHealth();
    loadStats();
    loadFilters();
    
    // Refresh stats every 30 seconds
    setInterval(loadStats, 30000);
    setInterval(checkHealth, 10000);
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

// Load statistics
async function loadStats() {
    try {
        const [statsResponse, indicesResponse] = await Promise.all([
            fetch('/api/stats'),
            fetch('/api/indices')
        ]);
        
        const stats = await statsResponse.json();
        const indices = await indicesResponse.json();
        
        // Update stat cards
        document.getElementById('total24h').textContent = 
            stats.total_last_24h?.toLocaleString() || '-';
        document.getElementById('hostnameCount').textContent = 
            stats.hostnames_count || '-';
        document.getElementById('environmentCount').textContent = 
            stats.environments_count || '-';
        document.getElementById('indexCount').textContent = 
            indices.indices?.length || '-';
        
        // Update chart
        if (stats.by_hour && stats.by_hour.length > 0) {
            updateChart(stats.by_hour);
        }
    } catch (error) {
        console.error('Erreur lors du chargement des statistiques:', error);
    }
}

// Load filter options
async function loadFilters() {
    try {
        const [hostnamesResponse, environmentsResponse] = await Promise.all([
            fetch('/api/hostnames'),
            fetch('/api/environments')
        ]);
        
        const hostnames = await hostnamesResponse.json();
        const environments = await environmentsResponse.json();
        
        // Populate hostname filter
        const hostnameSelect = document.getElementById('hostnameFilter');
        hostnames.hostnames.forEach(hostname => {
            const option = document.createElement('option');
            option.value = hostname;
            option.textContent = hostname;
            hostnameSelect.appendChild(option);
        });
        
        // Populate environment filter
        const envSelect = document.getElementById('environmentFilter');
        environments.environments.forEach(env => {
            const option = document.createElement('option');
            option.value = env;
            option.textContent = env;
            envSelect.appendChild(option);
        });
    } catch (error) {
        console.error('Erreur lors du chargement des filtres:', error);
    }
}

// Update events chart
function updateChart(data) {
    const ctx = document.getElementById('eventsChart').getContext('2d');
    
    const labels = data.map(item => {
        const date = new Date(item.timestamp);
        return date.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
    });
    
    const values = data.map(item => item.count);
    
    if (eventsChart) {
        eventsChart.destroy();
    }
    
    eventsChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [{
                label: 'Événements',
                data: values,
                borderColor: '#2563eb',
                backgroundColor: 'rgba(37, 99, 235, 0.1)',
                tension: 0.4,
                fill: true
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: true,
            plugins: {
                legend: {
                    display: false
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        precision: 0
                    }
                }
            }
        }
    });
}

// Search logs
async function searchLogs(page = 0) {
    const query = document.getElementById('searchQuery').value;
    const hostname = document.getElementById('hostnameFilter').value;
    const environment = document.getElementById('environmentFilter').value;
    const timeRange = document.getElementById('timeRange').value;
    
    currentPage = page;
    currentFilters = { query, hostname, environment, timeRange };
    
    const resultsContainer = document.getElementById('resultsContainer');
    resultsContainer.innerHTML = '<div class="loading">Chargement...</div>';
    
    try {
        const params = new URLSearchParams({
            size: 50,
            offset: page * 50,
            time_range: timeRange
        });
        
        if (query) params.append('query', query);
        if (hostname) params.append('hostname', hostname);
        if (environment) params.append('environment', environment);
        
        const response = await fetch(`/api/search?${params}`);
        const data = await response.json();
        
        displayResults(data);
    } catch (error) {
        console.error('Erreur lors de la recherche:', error);
        resultsContainer.innerHTML = 
            '<div class="error">Erreur lors de la recherche des logs</div>';
    }
}

// Display search results
function displayResults(data) {
    const resultsContainer = document.getElementById('resultsContainer');
    const resultsCount = document.getElementById('resultsCount');
    
    resultsCount.textContent = `${data.total.toLocaleString()} résultats`;
    
    if (data.hits.length === 0) {
        resultsContainer.innerHTML = 
            '<p class="placeholder">Aucun résultat trouvé</p>';
        return;
    }
    
    resultsContainer.innerHTML = '';
    
    data.hits.forEach(hit => {
        const entry = createLogEntry(hit);
        resultsContainer.appendChild(entry);
    });
    
    // Update pagination
    updatePagination(data.total, currentPage);
}

// Create log entry element
function createLogEntry(log) {
    const entry = document.createElement('div');
    entry.className = 'log-entry';
    
    const timestamp = log['@timestamp'] || log.timestamp || 'N/A';
    const hostname = log.hostname || 'N/A';
    const environment = log.environment || 'N/A';
    
    entry.innerHTML = `
        <div class="log-header">
            <div>
                <span class="log-hostname">${escapeHtml(hostname)}</span>
                <span class="log-environment">${escapeHtml(environment)}</span>
            </div>
            <span class="log-timestamp">${formatTimestamp(timestamp)}</span>
        </div>
        <div class="log-content">
            <pre>${escapeHtml(JSON.stringify(log, null, 2))}</pre>
        </div>
    `;
    
    return entry;
}

// Update pagination
function updatePagination(total, currentPage) {
    const pagination = document.getElementById('pagination');
    const totalPages = Math.ceil(total / 50);
    
    if (totalPages <= 1) {
        pagination.innerHTML = '';
        return;
    }
    
    let html = '';
    
    // Previous button
    html += `<button onclick="searchLogs(${currentPage - 1})" 
        ${currentPage === 0 ? 'disabled' : ''}>← Précédent</button>`;
    
    // Page numbers
    const startPage = Math.max(0, currentPage - 2);
    const endPage = Math.min(totalPages - 1, currentPage + 2);
    
    if (startPage > 0) {
        html += `<button onclick="searchLogs(0)">1</button>`;
        if (startPage > 1) html += '<span>...</span>';
    }
    
    for (let i = startPage; i <= endPage; i++) {
        html += `<button onclick="searchLogs(${i})" 
            ${i === currentPage ? 'class="active"' : ''}>${i + 1}</button>`;
    }
    
    if (endPage < totalPages - 1) {
        if (endPage < totalPages - 2) html += '<span>...</span>';
        html += `<button onclick="searchLogs(${totalPages - 1})">${totalPages}</button>`;
    }
    
    // Next button
    html += `<button onclick="searchLogs(${currentPage + 1})" 
        ${currentPage >= totalPages - 1 ? 'disabled' : ''}>Suivant →</button>`;
    
    pagination.innerHTML = html;
}

// Format timestamp
function formatTimestamp(timestamp) {
    const date = new Date(timestamp);
    return date.toLocaleString('fr-FR', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
    });
}

// Escape HTML to prevent XSS
function escapeHtml(text) {
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return String(text).replace(/[&<>"']/g, m => map[m]);
}

// Allow search on Enter key
document.addEventListener('DOMContentLoaded', function() {
    document.getElementById('searchQuery').addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
            searchLogs();
        }
    });
});
