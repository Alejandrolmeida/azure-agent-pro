#!/bin/bash
# ========================================
# Setup User Configuration
# ========================================
# Creates user-config.sh from template with your credentials
# This file is protected by .gitignore
# ========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$SCRIPT_DIR/config/user-config.sh.template"
CONFIG="$SCRIPT_DIR/config/user-config.sh"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  User Configuration Setup                             ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

if [ -f "$CONFIG" ]; then
    echo -e "${YELLOW}⚠️  Configuration file already exists!${NC}"
    echo -e "   File: ${GREEN}$CONFIG${NC}"
    echo ""
    read -p "Do you want to recreate it? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing configuration."
        exit 0
    fi
fi

echo -e "${YELLOW}📝 Please provide your configuration:${NC}"
echo ""

# User Email
read -p "Your Azure AD email (e.g., user@domain.com): " USER_EMAIL
if [ -z "$USER_EMAIL" ]; then
    echo "Email cannot be empty!"
    exit 1
fi

# Admin Username
read -p "VM admin username [azureuser]: " ADMIN_USERNAME
ADMIN_USERNAME=${ADMIN_USERNAME:-azureuser}

# Admin Password
while true; do
    read -s -p "VM admin password: " ADMIN_PASSWORD
    echo ""
    read -s -p "Confirm password: " ADMIN_PASSWORD_CONFIRM
    echo ""
    
    if [ "$ADMIN_PASSWORD" = "$ADMIN_PASSWORD_CONFIRM" ]; then
        if [ ${#ADMIN_PASSWORD} -lt 12 ]; then
            echo "❌ Password must be at least 12 characters!"
            continue
        fi
        break
    else
        echo "❌ Passwords don't match!"
    fi
done

# Location
read -p "Azure region [northeurope]: " LOCATION
LOCATION=${LOCATION:-northeurope}

# VM SKU
read -p "VM SKU [Standard_NV4as_v4]: " VM_SKU
VM_SKU=${VM_SKU:-Standard_NV4as_v4}

# Project Name
read -p "Project name [pix4d]: " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-pix4d}

# Environment
read -p "Environment [lab]: " ENVIRONMENT
ENVIRONMENT=${ENVIRONMENT:-lab}

# Create config file
cat > "$CONFIG" << EOF
#!/bin/bash
# ========================================
# User Configuration
# ========================================
# ⚠️  THIS FILE CONTAINS SENSITIVE DATA
# ⚠️  DO NOT COMMIT TO GIT (protected by .gitignore)
# ========================================
# Created: $(date)
# ========================================

# Azure Account
export USER_EMAIL="$USER_EMAIL"

# VM Admin Credentials (local fallback)
export ADMIN_USERNAME="$ADMIN_USERNAME"
export ADMIN_PASSWORD="$ADMIN_PASSWORD"

# Deployment Configuration
export LOCATION="$LOCATION"
export VM_SKU="$VM_SKU"
export PROJECT_NAME="$PROJECT_NAME"
export ENVIRONMENT="$ENVIRONMENT"
EOF

chmod 600 "$CONFIG"

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ Configuration Created Successfully!               ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}📁 File location:${NC}"
echo -e "   ${GREEN}$CONFIG${NC}"
echo ""
echo -e "${YELLOW}🔒 Security:${NC}"
echo -e "   ✅ File permissions: 600 (owner read/write only)"
echo -e "   ✅ Protected by .gitignore"
echo -e "   ✅ Will NOT be committed to Git"
echo ""
echo -e "${YELLOW}📋 Next steps:${NC}"
echo -e "   1. Review the configuration:"
echo -e "      ${GREEN}cat $CONFIG${NC}"
echo ""
echo -e "   2. Run the deployment:"
echo -e "      ${GREEN}./deploy.sh${NC}"
echo ""
