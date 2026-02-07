#!/usr/bin/env pwsh
# Quick setup script for OSQuery Ansible deployment (Windows)

Write-Host "🚀 OSQuery Ansible Deployment - Setup" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check if Ansible is installed
try {
    $ansibleVersion = ansible --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Ansible found" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Ansible is not installed." -ForegroundColor Red
    Write-Host "Please install Ansible first: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html"
    exit 1
}

Write-Host ""

# Install required collections
Write-Host "📦 Installing required Ansible collections..." -ForegroundColor Yellow
ansible-galaxy collection install -r requirements.yaml

Write-Host ""
Write-Host "✅ Collections installed successfully!" -ForegroundColor Green
Write-Host ""

# Check if inventory has been customized
$inventoryContent = Get-Content inventory.ini -Raw
if ($inventoryContent -match "192.168.1.10") {
    Write-Host "⚠️  WARNING: You're using the example inventory!" -ForegroundColor Yellow
    Write-Host "Please edit inventory.ini with your actual server information."
    Write-Host ""
}

# Check if group_vars exists
if (-not (Test-Path "group_vars/all.yaml")) {
    Write-Host "📝 Creating group_vars directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path "group_vars" | Out-Null
    if (Test-Path "group_vars/all.yaml.example") {
        Write-Host "You may want to copy group_vars/all.yaml.example to group_vars/all.yaml"
    }
}

Write-Host ""
Write-Host "✅ Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Edit inventory.ini with your servers"
Write-Host "2. Configure OpenSearch (optional): edit group_vars/all.yaml"
Write-Host "3. Run: ansible-playbook playbook.yaml --check (dry-run)"
Write-Host "4. Run: ansible-playbook playbook.yaml (actual deployment)"
Write-Host ""
Write-Host "For OpenSearch integration:" -ForegroundColor Cyan
Write-Host "- Quick start: docs/QUICKSTART-OPENSEARCH.md"
Write-Host "- Full guide: docs/OPENSEARCH.md"
Write-Host ""
Write-Host "For more information, see README.md"

