#!/bin/bash
# MCP Server Setup and Configuration for Azure Agent Project
# Configures Azure, GitHub, and Azure DevOps MCP Servers with latest best practices

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration directories
MCP_DIR="$HOME/.config/mcp"
AZURE_MCP_DIR="$MCP_DIR/azure"
GITHUB_MCP_DIR="$MCP_DIR/github"
AZDO_MCP_DIR="$MCP_DIR/azuredevops"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing_tools=()
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        missing_tools+=("node")
    else
        local node_version=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [[ $node_version -lt 18 ]]; then
            log_warning "Node.js version $node_version detected. Recommended: 18+"
        fi
    fi
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        missing_tools+=("npm")
    fi
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        missing_tools+=("azure-cli")
    else
        local az_version=$(az version --query '"azure-cli"' -o tsv | cut -d'.' -f1)
        if [[ $az_version -lt 2 ]]; then
            log_warning "Azure CLI version $az_version detected. Recommended: 2.50+"
        fi
    fi
    
    # Check GitHub CLI
    if ! command -v gh &> /dev/null; then
        missing_tools+=("github-cli")
    fi
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        missing_tools+=("python3")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Please install missing tools and run again"
        return 1
    fi
    
    log_success "All prerequisites met"
}

# Create directory structure
setup_directories() {
    log_info "Setting up MCP directories..."
    
    mkdir -p "$AZURE_MCP_DIR"
    mkdir -p "$GITHUB_MCP_DIR"
    mkdir -p "$AZDO_MCP_DIR"
    mkdir -p "$MCP_DIR/logs"
    mkdir -p "$MCP_DIR/backup"
    
    log_success "Directory structure created"
}

# Install MCP CLI and servers
install_mcp_components() {
    log_info "Installing MCP components..."
    
    # Install MCP CLI globally
    if ! command -v mcp &> /dev/null; then
        log_info "Installing MCP CLI..."
        npm install -g @modelcontextprotocol/cli
    else
        log_info "MCP CLI already installed"
    fi
    
    # Install Azure MCP Server
    log_info "Installing Azure MCP Server..."
    if [[ ! -d "$MCP_DIR/servers/azure" ]]; then
        mkdir -p "$MCP_DIR/servers"
        cd "$MCP_DIR/servers"
        git clone https://github.com/microsoft/mcp-server-azure.git azure
        cd azure
        npm install
        npm run build
    else
        log_info "Updating Azure MCP Server..."
        cd "$MCP_DIR/servers/azure"
        git pull
        npm install
        npm run build
    fi
    
    # Install GitHub MCP Server
    log_info "Installing GitHub MCP Server..."
    if [[ ! -d "$MCP_DIR/servers/github" ]]; then
        cd "$MCP_DIR/servers"
        git clone https://github.com/github/mcp-server-github.git github
        cd github
        npm install
        npm run build
    else
        log_info "Updating GitHub MCP Server..."
        cd "$MCP_DIR/servers/github"
        git pull
        npm install
        npm run build
    fi
    
    # Install Azure DevOps MCP Server
    log_info "Installing Azure DevOps MCP Server..."
    if [[ ! -d "$MCP_DIR/servers/azuredevops" ]]; then
        cd "$MCP_DIR/servers"
        git clone https://github.com/microsoft/mcp-server-azuredevops.git azuredevops
        cd azuredevops
        npm install
        npm run build
    else
        log_info "Updating Azure DevOps MCP Server..."
        cd "$MCP_DIR/servers/azuredevops"
        git pull
        npm install
        npm run build
    fi
    
    log_success "MCP components installed/updated"
}

# Configure Azure MCP Server
configure_azure_mcp() {
    log_info "Configuring Azure MCP Server..."
    
    # Check Azure CLI login
    if ! az account show &>/dev/null; then
        log_error "Not logged into Azure CLI. Please run 'az login' first"
        return 1
    fi
    
    # Get Azure information
    local subscription_id=$(az account show --query id -o tsv)
    local tenant_id=$(az account show --query tenantId -o tsv)
    local subscription_name=$(az account show --query name -o tsv)
    
    log_info "Current Azure context:"
    log_info "  Subscription: $subscription_name"
    log_info "  Subscription ID: $subscription_id"
    log_info "  Tenant ID: $tenant_id"
    
    # Create or update service principal for MCP
    local sp_name="mcp-azure-agent-$(date +%s)"
    log_info "Creating service principal: $sp_name"
    
    local sp_info=$(az ad sp create-for-rbac \
        --name "$sp_name" \
        --role "Contributor" \
        --scopes "/subscriptions/$subscription_id" \
        --output json)
    
    local client_id=$(echo "$sp_info" | jq -r '.appId')
    local client_secret=$(echo "$sp_info" | jq -r '.password')
    
    # Create secure configuration
    cat > "$AZURE_MCP_DIR/config.json" << EOF
{
  "tenantId": "$tenant_id",
  "clientId": "$client_id",
  "clientSecret": "$client_secret",
  "subscriptionId": "$subscription_id",
  "defaultResourceGroup": "rg-mcp-azure-agent",
  "defaultLocation": "eastus",
  "enableLogging": true,
  "logLevel": "info"
}
EOF
    
    # Set secure permissions
    chmod 600 "$AZURE_MCP_DIR/config.json"
    
    log_success "Azure MCP Server configured"
    log_info "Service Principal created: $client_id"
}

# Configure GitHub MCP Server
configure_github_mcp() {
    log_info "Configuring GitHub MCP Server..."
    
    # Check GitHub CLI login
    if ! gh auth status &>/dev/null; then
        log_warning "Not logged into GitHub CLI. Please run 'gh auth login' first"
        read -p "Do you want to configure GitHub MCP manually? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    # Get current GitHub user
    local github_user
    if gh auth status &>/dev/null; then
        github_user=$(gh api user --jq '.login')
        log_info "GitHub user: $github_user"
    else
        read -p "Enter your GitHub username: " github_user
    fi
    
    # Get or create GitHub token
    local github_token
    if gh auth status &>/dev/null; then
        github_token=$(gh auth token)
    else
        echo "Please create a Personal Access Token at: https://github.com/settings/tokens"
        echo "Required scopes: repo, workflow, admin:org, admin:public_key, admin:repo_hook"
        read -s -p "Enter your GitHub Personal Access Token: " github_token
        echo
    fi
    
    # Create GitHub MCP configuration
    cat > "$GITHUB_MCP_DIR/config.json" << EOF
{
  "token": "$github_token",
  "username": "$github_user",
  "apiUrl": "https://api.github.com",
  "enableWebhooks": true,
  "defaultOrg": "$github_user",
  "enableLogging": true,
  "logLevel": "info"
}
EOF
    
    # Set secure permissions
    chmod 600 "$GITHUB_MCP_DIR/config.json"
    
    log_success "GitHub MCP Server configured"
}

# Configure Azure DevOps MCP Server
configure_azuredevops_mcp() {
    log_info "Configuring Azure DevOps MCP Server..."
    
    # Install Azure DevOps CLI extension if not present
    if ! az extension list | grep -q azure-devops; then
        log_info "Installing Azure DevOps CLI extension..."
        az extension add --name azure-devops
    fi
    
    # Get Azure DevOps organization URL
    read -p "Enter your Azure DevOps organization URL (e.g., https://dev.azure.com/myorg): " org_url
    
    # Create or get Personal Access Token
    echo "Please create a Personal Access Token at: ${org_url}/_usersSettings/tokens"
    echo "Required scopes: Build (read & execute), Code (read & write), Work Items (read & write)"
    read -s -p "Enter your Azure DevOps Personal Access Token: " azdo_pat
    echo
    
    # Configure Azure DevOps CLI defaults
    az devops configure --defaults organization="$org_url"
    
    # Test connection
    if echo "$azdo_pat" | az devops login --organization "$org_url"; then
        log_success "Azure DevOps connection successful"
    else
        log_error "Failed to connect to Azure DevOps"
        return 1
    fi
    
    # Create Azure DevOps MCP configuration
    cat > "$AZDO_MCP_DIR/config.json" << EOF
{
  "organizationUrl": "$org_url",
  "personalAccessToken": "$azdo_pat",
  "defaultProject": "",
  "enableLogging": true,
  "logLevel": "info"
}
EOF
    
    # Set secure permissions
    chmod 600 "$AZDO_MCP_DIR/config.json"
    
    log_success "Azure DevOps MCP Server configured"
}

# Create centralized MCP configuration
create_mcp_config() {
    log_info "Creating centralized MCP configuration..."
    
    cat > "$MCP_DIR/servers.json" << EOF
{
  "mcpVersion": "2024-11-05",
  "servers": {
    "azure": {
      "command": "node",
      "args": ["$MCP_DIR/servers/azure/dist/index.js"],
      "env": {
        "AZURE_CONFIG_FILE": "$AZURE_MCP_DIR/config.json",
        "NODE_ENV": "production"
      }
    },
    "github": {
      "command": "node",
      "args": ["$MCP_DIR/servers/github/dist/index.js"],
      "env": {
        "GITHUB_CONFIG_FILE": "$GITHUB_MCP_DIR/config.json",
        "NODE_ENV": "production"
      }
    },
    "azuredevops": {
      "command": "node",
      "args": ["$MCP_DIR/servers/azuredevops/dist/index.js"],
      "env": {
        "AZDO_CONFIG_FILE": "$AZDO_MCP_DIR/config.json",
        "NODE_ENV": "production"
      }
    }
  },
  "logging": {
    "level": "info",
    "file": "$MCP_DIR/logs/mcp-servers.log"
  }
}
EOF
    
    log_success "Centralized MCP configuration created"
}

# Create VS Code integration
create_vscode_integration() {
    log_info "Creating VS Code MCP integration..."
    
    local vscode_settings="$PROJECT_ROOT/.vscode/settings.json"
    
    # Read current settings if they exist
    local current_settings="{}"
    if [[ -f "$vscode_settings" ]]; then
        current_settings=$(cat "$vscode_settings")
    fi
    
    # Add MCP configuration to VS Code settings
    local updated_settings=$(echo "$current_settings" | jq '. + {
      "mcp.servers": {
        "azure": {
          "command": "node",
          "args": ["'"$MCP_DIR/servers/azure/dist/index.js"'"],
          "env": {
            "AZURE_CONFIG_FILE": "'"$AZURE_MCP_DIR/config.json"'"
          }
        },
        "github": {
          "command": "node", 
          "args": ["'"$MCP_DIR/servers/github/dist/index.js"'"],
          "env": {
            "GITHUB_CONFIG_FILE": "'"$GITHUB_MCP_DIR/config.json"'"
          }
        },
        "azuredevops": {
          "command": "node",
          "args": ["'"$MCP_DIR/servers/azuredevops/dist/index.js"'"],
          "env": {
            "AZDO_CONFIG_FILE": "'"$AZDO_MCP_DIR/config.json"'"
          }
        }
      },
      "mcp.enableLogging": true,
      "mcp.logLevel": "info"
    }')
    
    echo "$updated_settings" > "$vscode_settings"
    
    log_success "VS Code MCP integration configured"
}

# Create backup and restore scripts
create_backup_scripts() {
    log_info "Creating backup and restore scripts..."
    
    # Backup script
    cat > "$MCP_DIR/backup-mcp-config.sh" << 'EOF'
#!/bin/bash
# Backup MCP configuration

BACKUP_DIR="$HOME/.config/mcp/backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/mcp-backup-$TIMESTAMP.tar.gz"

mkdir -p "$BACKUP_DIR"

tar -czf "$BACKUP_FILE" \
    -C "$HOME/.config/mcp" \
    --exclude='logs/*' \
    --exclude='backup/*' \
    .

echo "MCP configuration backed up to: $BACKUP_FILE"
EOF
    
    # Restore script
    cat > "$MCP_DIR/restore-mcp-config.sh" << 'EOF'
#!/bin/bash
# Restore MCP configuration

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <backup-file>"
    exit 1
fi

BACKUP_FILE="$1"
MCP_DIR="$HOME/.config/mcp"

if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "Restoring MCP configuration from: $BACKUP_FILE"
tar -xzf "$BACKUP_FILE" -C "$MCP_DIR"
echo "MCP configuration restored"
EOF
    
    chmod +x "$MCP_DIR/backup-mcp-config.sh"
    chmod +x "$MCP_DIR/restore-mcp-config.sh"
    
    log_success "Backup and restore scripts created"
}

# Test MCP servers
test_mcp_servers() {
    log_info "Testing MCP server connections..."
    
    # Test Azure MCP
    if [[ -f "$AZURE_MCP_DIR/config.json" ]]; then
        log_info "Testing Azure MCP Server..."
        if timeout 10 node "$MCP_DIR/servers/azure/dist/index.js" --test &>/dev/null; then
            log_success "Azure MCP Server: OK"
        else
            log_warning "Azure MCP Server: Connection issues"
        fi
    fi
    
    # Test GitHub MCP
    if [[ -f "$GITHUB_MCP_DIR/config.json" ]]; then
        log_info "Testing GitHub MCP Server..."
        if timeout 10 node "$MCP_DIR/servers/github/dist/index.js" --test &>/dev/null; then
            log_success "GitHub MCP Server: OK"
        else
            log_warning "GitHub MCP Server: Connection issues"
        fi
    fi
    
    # Test Azure DevOps MCP
    if [[ -f "$AZDO_MCP_DIR/config.json" ]]; then
        log_info "Testing Azure DevOps MCP Server..."
        if timeout 10 node "$MCP_DIR/servers/azuredevops/dist/index.js" --test &>/dev/null; then
            log_success "Azure DevOps MCP Server: OK"
        else
            log_warning "Azure DevOps MCP Server: Connection issues"
        fi
    fi
}

# Main setup function
main() {
    log_info "Starting MCP Server setup for Azure Agent Project"
    log_info "================================================"
    
    check_prerequisites || exit 1
    setup_directories
    install_mcp_components
    
    # Configure servers (interactive)
    echo
    read -p "Configure Azure MCP Server? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        configure_azure_mcp
    fi
    
    echo
    read -p "Configure GitHub MCP Server? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        configure_github_mcp
    fi
    
    echo
    read -p "Configure Azure DevOps MCP Server? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        configure_azuredevops_mcp
    fi
    
    create_mcp_config
    create_vscode_integration
    create_backup_scripts
    test_mcp_servers
    
    log_success "MCP Server setup completed!"
    log_info "Configuration location: $MCP_DIR"
    log_info "VS Code integration: Updated"
    log_info "Backup scripts: $MCP_DIR/backup-mcp-config.sh"
    
    echo
    log_info "Next steps:"
    log_info "1. Restart VS Code to load MCP integration"
    log_info "2. Install MCP VS Code extension if not already installed"
    log_info "3. Test MCP servers: mcp test"
    log_info "4. Check logs: $MCP_DIR/logs/mcp-servers.log"
}

# Run main function
main "$@"