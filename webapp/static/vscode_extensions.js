// VSCode Extensions page JavaScript

let allExtensions = [];

// Load extensions on page load
document.addEventListener('DOMContentLoaded', () => {
    loadExtensions();
    setupFilters();
});

async function loadExtensions() {
    try {
        const response = await fetch('/api/vscode-extensions');
        
        if (!response.ok) {
            throw new Error('Erreur lors du chargement des extensions');
        }
        
        const data = await response.json();
        allExtensions = data.extensions;
        
        // Hide loading
        document.getElementById('loading').style.display = 'none';
        document.getElementById('extensions-table').style.display = 'table';
        
        // Populate filters
        populatePublisherFilter();
        
        // Display extensions
        displayExtensions(allExtensions);
        
        // Update statistics
        updateStatistics(allExtensions);
        
    } catch (error) {
        document.getElementById('loading').style.display = 'none';
        const errorDiv = document.getElementById('error-message');
        errorDiv.textContent = `Erreur: ${error.message}`;
        errorDiv.style.display = 'block';
    }
}

function populatePublisherFilter() {
    const publishers = [...new Set(allExtensions.map(ext => ext.publisher))].sort();
    const select = document.getElementById('publisher-filter');
    
    publishers.forEach(publisher => {
        const option = document.createElement('option');
        option.value = publisher;
        option.textContent = publisher;
        select.appendChild(option);
    });
}

function setupFilters() {
    const searchInput = document.getElementById('search-input');
    const publisherFilter = document.getElementById('publisher-filter');
    const statusFilter = document.getElementById('status-filter');
    
    searchInput.addEventListener('input', applyFilters);
    publisherFilter.addEventListener('change', applyFilters);
    statusFilter.addEventListener('change', applyFilters);
}

function applyFilters() {
    const searchTerm = document.getElementById('search-input').value.toLowerCase();
    const publisherFilter = document.getElementById('publisher-filter').value;
    const statusFilter = document.getElementById('status-filter').value;
    
    let filtered = allExtensions.filter(ext => {
        // Search filter
        const matchesSearch = !searchTerm || 
            ext.name.toLowerCase().includes(searchTerm) ||
            ext.displayName.toLowerCase().includes(searchTerm) ||
            ext.shortDescription.toLowerCase().includes(searchTerm) ||
            ext.publisher.toLowerCase().includes(searchTerm);
        
        // Publisher filter
        const matchesPublisher = !publisherFilter || ext.publisher === publisherFilter;
        
        // Status filter
        let matchesStatus = true;
        if (statusFilter === 'verified') {
            matchesStatus = ext.isVerified;
        } else if (statusFilter === 'outdated') {
            matchesStatus = isExtensionOutdated(ext);
        } else if (statusFilter === 'uptodate') {
            matchesStatus = !isExtensionOutdated(ext);
        }
        
        return matchesSearch && matchesPublisher && matchesStatus;
    });
    
    displayExtensions(filtered);
}

function isExtensionOutdated(ext) {
    if (!ext.latestVersion || !ext.versions_found || ext.versions_found.length === 0) {
        return false;
    }
    
    // Check if any installed version is different from latest
    return ext.versions_found.some(version => version !== ext.latestVersion);
}

function displayExtensions(extensions) {
    const tbody = document.getElementById('extensions-tbody');
    tbody.innerHTML = '';
    
    if (extensions.length === 0) {
        tbody.innerHTML = '<tr><td colspan="8" style="text-align: center; padding: 40px; color: var(--text-light);">Aucune extension trouvée</td></tr>';
        return;
    }
    
    extensions.forEach(ext => {
        const row = document.createElement('tr');
        
        // Verified badge
        const verifiedBadge = ext.isVerified ? 
            '<span class="badge verified">✓ Vérifié</span>' : 
            '<span class="badge unverified">Non vérifié</span>';
        
        // Status badge
        let statusBadge = '';
        if (isExtensionOutdated(ext)) {
            statusBadge = '<span class="badge outdated">⚠ Outdated</span>';
        } else if (ext.latestVersion) {
            statusBadge = '<span class="badge uptodate">✓ À jour</span>';
        }
        
        // Versions list
        const versionsText = ext.versions_found && ext.versions_found.length > 0 ? 
            ext.versions_found.join(', ') : 'Unknown';
        
        // Extension link
        const extensionLink = `/vscode-extension/${ext.name}`;
        
        row.innerHTML = `
            <td>
                <a href="${extensionLink}" class="extension-link">${ext.displayName}</a><br>
            </td>
            <td>${ext.publisher}</td>
            <td>
                <div style="max-width: 300px; overflow: hidden; text-overflow: ellipsis;">
                    ${ext.shortDescription || '-'}
                </div>
            </td>
            <td style="text-align: center;">${ext.installations_count}</td>
            <td>
                <span class="version-list">${versionsText}</span>
            </td>
            <td>${ext.latestVersion || 'Unknown'}</td>
            <td>
                ${verifiedBadge}
                ${statusBadge}
            </td>
            <td style="text-align: right;">
                <span class="marketplace-stats">
                    ${ext.marketplaceInstalls ? ext.marketplaceInstalls.toLocaleString('fr-FR') : '0'}
                </span>
            </td>
        `;
        
        tbody.appendChild(row);
    });
}

function updateStatistics(extensions) {
    // Total extensions
    document.getElementById('total-extensions').textContent = extensions.length;
    
    // Verified count
    const verifiedCount = extensions.filter(ext => ext.isVerified).length;
    document.getElementById('verified-count').textContent = verifiedCount;
    
    // Total installations
    const totalInstalls = extensions.reduce((sum, ext) => sum + ext.installations_count, 0);
    document.getElementById('total-installations').textContent = totalInstalls;
    
    // Outdated count
    const outdatedCount = extensions.filter(ext => isExtensionOutdated(ext)).length;
    document.getElementById('outdated-count').textContent = outdatedCount;
}
