#!/bin/bash
# Quick setup script for OSQuery Ansible deployment

set -e

echo "🚀 OSQuery Ansible Deployment - Setup"
echo "======================================"
echo ""

# Check if Ansible is installed
if ! command -v ansible &> /dev/null; then
    echo "❌ Ansible is not installed."
    echo "Please install Ansible first: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html"
    exit 1
fi

echo "✅ Ansible found: $(ansible --version | head -n1)"
echo ""

# Install required collections
echo "📦 Installing required Ansible collections..."
ansible-galaxy collection install -r requirements.yaml

echo ""
echo "✅ Collections installed successfully!"
echo ""

# Check if inventory has been customized
if grep -q "192.168.1.10" inventory.ini; then
    echo "⚠️  WARNING: You're using the example inventory!"
    echo "Please edit inventory.ini with your actual server information."
    echo ""
fi

# Check if group_vars exists
if [ ! -f "group_vars/all.yaml" ]; then
    echo "📝 Creating group_vars directory..."
    mkdir -p group_vars
    if [ -f "group_vars/all.yaml.example" ]; then
        echo "You may want to copy group_vars/all.yaml.example to group_vars/all.yaml"
    fi
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit inventory.ini with your servers"
echo "2. Configure OpenSearch (optional): edit group_vars/all.yaml"
echo "3. Run: ansible-playbook playbook.yaml --check (dry-run)"
echo "4. Run: ansible-playbook playbook.yaml (actual deployment)"
echo ""
echo "For OpenSearch integration:"
echo "- Quick start: docs/QUICKSTART-OPENSEARCH.md"
echo "- Full guide: docs/OPENSEARCH.md"
echo ""
echo "For more information, see README.md"
