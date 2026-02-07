#!/bin/bash
# Pre-deployment verification script for OSQuery Ansible project

set -e

echo "🔍 OSQuery Ansible Deployment - Pre-flight Check"
echo "================================================"
echo ""

ERRORS=0
WARNINGS=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

error() {
    echo -e "${RED}❌ $1${NC}"
    ((ERRORS++))
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((WARNINGS++))
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

info() {
    echo "ℹ️  $1"
}

# Check Ansible installation
echo "1. Checking Ansible installation..."
if command -v ansible &> /dev/null; then
    ANSIBLE_VERSION=$(ansible --version | head -n1)
    success "Ansible is installed: $ANSIBLE_VERSION"
else
    error "Ansible is not installed"
fi
echo ""

# Check Python version
echo "2. Checking Python version..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    success "Python 3 is installed: $PYTHON_VERSION"
else
    error "Python 3 is not installed"
fi
echo ""

# Check required Ansible collections
echo "3. Checking Ansible collections..."
if ansible-galaxy collection list | grep -q "community.general"; then
    success "community.general collection is installed"
else
    warning "community.general collection not found - run: ./setup.sh"
fi

if ansible-galaxy collection list | grep -q "ansible.windows"; then
    success "ansible.windows collection is installed"
else
    warning "ansible.windows collection not found - run: ./setup.sh"
fi
echo ""

# Check inventory file
echo "4. Checking inventory file..."
if [ -f "inventory.ini" ]; then
    success "inventory.ini exists"
    
    if grep -q "192.168.1.10" inventory.ini; then
        warning "inventory.ini appears to be using example IPs - please customize"
    else
        success "inventory.ini appears to be customized"
    fi
else
    error "inventory.ini not found"
fi
echo ""

# Check for group_vars
echo "5. Checking group_vars configuration..."
if [ -f "group_vars/all.yaml" ]; then
    success "group_vars/all.yaml exists"
    
    # Check for OpenSearch configuration
    if grep -q "enable_opensearch_forwarding: true" group_vars/all.yaml 2>/dev/null; then
        info "OpenSearch forwarding is enabled"
        
        # Verify required OpenSearch variables
        if grep -q "opensearch_endpoint:" group_vars/all.yaml; then
            success "opensearch_endpoint is configured"
        else
            error "opensearch_endpoint not found in group_vars/all.yaml"
        fi
        
        if grep -q "opensearch_region:" group_vars/all.yaml; then
            success "opensearch_region is configured"
        else
            error "opensearch_region not found in group_vars/all.yaml"
        fi
    else
        info "OpenSearch forwarding is disabled (logs stay local)"
    fi
else
    warning "group_vars/all.yaml not found - using defaults"
    info "Copy group_vars/all.yaml.example to group_vars/all.yaml to customize"
fi
echo ""

# Check file structure
echo "6. Checking file structure..."
REQUIRED_FILES=(
    "playbook.yaml"
    "ansible.cfg"
    "modules/osquery/tasks/main.yaml"
    "modules/osquery/tasks/debian.yaml"
    "modules/osquery/tasks/redhat.yaml"
    "modules/osquery/tasks/macos.yaml"
    "modules/osquery/tasks/windows.yaml"
    "modules/osquery/templates/osquery-linux.conf.j2"
    "modules/osquery/templates/osquery-macos.conf.j2"
    "modules/osquery/templates/osquery-windows.conf.j2"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        success "$file exists"
    else
        error "$file not found"
    fi
done
echo ""

# Check Fluent Bit files if OpenSearch is enabled
if [ -f "group_vars/all.yaml" ] && grep -q "enable_opensearch_forwarding: true" group_vars/all.yaml 2>/dev/null; then
    echo "7. Checking Fluent Bit configuration (OpenSearch enabled)..."
    FLUENT_FILES=(
        "modules/osquery/tasks/fluent-bit-debian.yaml"
        "modules/osquery/tasks/fluent-bit-redhat.yaml"
        "modules/osquery/tasks/fluent-bit-macos.yaml"
        "modules/osquery/tasks/fluent-bit-windows.yaml"
        "modules/osquery/templates/fluent-bit-linux.conf.j2"
        "modules/osquery/templates/fluent-bit-macos.conf.j2"
        "modules/osquery/templates/fluent-bit-windows.conf.j2"
        "modules/osquery/templates/fluent-bit-parsers.conf.j2"
    )
    
    for file in "${FLUENT_FILES[@]}"; do
        if [ -f "$file" ]; then
            success "$file exists"
        else
            error "$file not found"
        fi
    done
    echo ""
fi

# Test inventory connectivity (if requested)
if [ "$1" == "--test-connection" ]; then
    echo "8. Testing connectivity to hosts..."
    info "Running: ansible all -m ping"
    if ansible all -m ping > /dev/null 2>&1; then
        success "All hosts are reachable"
    else
        warning "Some hosts are not reachable - check inventory and SSH access"
    fi
    echo ""
fi

# Test playbook syntax
echo "9. Validating playbook syntax..."
if ansible-playbook playbook.yaml --syntax-check > /dev/null 2>&1; then
    success "Playbook syntax is valid"
else
    error "Playbook syntax check failed"
fi
echo ""

# Summary
echo "================================================"
echo "Summary:"
echo ""
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    success "All checks passed! Ready to deploy."
    echo ""
    echo "Next steps:"
    echo "  1. Review your configuration in group_vars/all.yaml"
    echo "  2. Test deployment: ansible-playbook playbook.yaml --check"
    echo "  3. Deploy: ansible-playbook playbook.yaml"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}✓ Checks passed with $WARNINGS warning(s)${NC}"
    echo ""
    echo "You can proceed, but please review the warnings above."
    exit 0
else
    echo -e "${RED}✗ Checks failed with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    echo ""
    echo "Please fix the errors above before deploying."
    echo ""
    echo "Run './setup.sh' to install missing dependencies."
    exit 1
fi
