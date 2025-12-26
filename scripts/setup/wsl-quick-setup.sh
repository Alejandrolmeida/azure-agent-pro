#!/bin/bash
# WSL Quick Setup Script
# Configures WSL with Miniconda, Azure CLI environment, and productivity tools
# Author: Alejandro Almeida
# Date: 2025-12-26

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   WSL Quick Setup - Azure Development Environment${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Function to print section headers
print_section() {
    echo ""
    echo -e "${GREEN}▶ $1${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update system packages
print_section "Updating system packages"
sudo apt-get update
sudo apt-get upgrade -y

# Install essential dependencies
print_section "Installing essential dependencies"
sudo apt-get install -y \
    wget \
    curl \
    git \
    unzip \
    build-essential \
    ca-certificates \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libffi-dev \
    liblzma-dev

# Install Miniconda if not already installed
print_section "Installing Miniconda"
if ! command_exists conda; then
    echo "Downloading Miniconda..."
    cd ~
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
    
    echo "Installing Miniconda..."
    bash miniconda.sh -b -p $HOME/miniconda3
    rm miniconda.sh
    
    echo "Initializing conda..."
    eval "$($HOME/miniconda3/bin/conda shell.bash hook)"
    conda init bash
    
    echo -e "${GREEN}✓ Miniconda installed successfully${NC}"
else
    echo -e "${YELLOW}⚠ Miniconda already installed, skipping...${NC}"
fi

# Ensure conda is available in current session
if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
    source "$HOME/miniconda3/etc/profile.d/conda.sh"
fi

# Create Azure CLI environment
print_section "Creating 'azurecli' conda environment"
if conda env list | grep -q "^azurecli "; then
    echo -e "${YELLOW}⚠ Environment 'azurecli' already exists, skipping creation...${NC}"
else
    echo "Creating conda environment with Python 3.11..."
    conda create -n azurecli python=3.11 -y
    echo -e "${GREEN}✓ Environment 'azurecli' created${NC}"
fi

# Activate environment and install Azure CLI
print_section "Installing Azure CLI and tools"
echo "Activating azurecli environment..."
conda activate azurecli

# Install Azure CLI
if ! command_exists az; then
    echo "Installing Azure CLI..."
    pip install azure-cli
    echo -e "${GREEN}✓ Azure CLI installed${NC}"
else
    echo -e "${YELLOW}⚠ Azure CLI already installed${NC}"
fi

# Install additional Azure tools
echo "Installing additional Azure tools..."
pip install --upgrade \
    azure-identity \
    azure-mgmt-resource \
    azure-mgmt-compute \
    azure-mgmt-network \
    azure-mgmt-storage \
    azure-storage-blob \
    azure-keyvault-secrets \
    azqr

echo -e "${GREEN}✓ Azure tools installed${NC}"

# Install CaskaydiaCove Nerd Font
print_section "Installing CaskaydiaCove Nerd Font"
mkdir -p $HOME/.local/share/fonts
cd /tmp
if [ ! -f "$HOME/.local/share/fonts/CaskaydiaCoveNerdFont-Regular.ttf" ]; then
    echo "Downloading CaskaydiaCove Nerd Font..."
    wget https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip
    unzip -o CascadiaCode.zip -d $HOME/.local/share/fonts/
    rm CascadiaCode.zip
    fc-cache -fv
    echo -e "${GREEN}✓ CaskaydiaCove Nerd Font installed${NC}"
else
    echo -e "${YELLOW}⚠ Font already installed${NC}"
fi

# Install Oh-my-posh
print_section "Installing Oh-my-posh"
if ! command_exists oh-my-posh; then
    echo "Installing Oh-my-posh..."
    sudo curl -s https://ohmyposh.dev/install.sh | sudo bash -s
    echo -e "${GREEN}✓ Oh-my-posh installed${NC}"
else
    echo -e "${YELLOW}⚠ Oh-my-posh already installed${NC}"
fi

# Create Oh-my-posh theme directory
sudo mkdir -p /usr/local/share/omp-templates

# Create custom Oh-my-posh theme
print_section "Creating custom Oh-my-posh theme"
sudo tee /usr/local/share/omp-templates/almeida.omp.json > /dev/null << 'EOF'
{
  "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
  "blocks": [
    {
      "alignment": "left",
      "segments": [
        {
          "background": "#0077c2",
          "foreground": "#ffffff",
          "leading_diamond": "\ue0b6",
          "style": "diamond",
          "template": " {{ .UserName }} ",
          "trailing_diamond": "\ue0b0",
          "type": "session"
        },
        {
          "background": "#ef5350",
          "foreground": "#ffffff",
          "leading_diamond": "\ue0b0",
          "properties": {
            "folder_icon": " \uf07c ",
            "folder_separator_icon": " \ue0b1 ",
            "style": "folder"
          },
          "style": "diamond",
          "template": " {{ .Path }} ",
          "trailing_diamond": "\ue0b0",
          "type": "path"
        },
        {
          "background": "#95ffa4",
          "foreground": "#193549",
          "leading_diamond": "\ue0b0",
          "properties": {
            "branch_icon": "\ue725 ",
            "fetch_stash_count": true,
            "fetch_status": true,
            "fetch_upstream_icon": true
          },
          "style": "diamond",
          "template": " {{ .HEAD }}{{if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Working.Changed }} \uf044 {{ .Working.String }}{{ end }}{{ if and (.Working.Changed) (.Staging.Changed) }} |{{ end }}{{ if .Staging.Changed }} \uf046 {{ .Staging.String }}{{ end }} ",
          "trailing_diamond": "\ue0b0",
          "type": "git"
        },
        {
          "background": "#44475a",
          "foreground": "#ffffff",
          "leading_diamond": "\ue0b0",
          "style": "diamond",
          "template": " \ue235 {{ if .Error }}{{ .Error }}{{ else }}{{ if .Venv }}{{ .Venv }} {{ end }}{{ .Full }}{{ end }} ",
          "trailing_diamond": "\ue0b0",
          "type": "python"
        },
        {
          "background": "#0078d4",
          "foreground": "#ffffff",
          "leading_diamond": "\ue0b0",
          "style": "diamond",
          "template": " \ufd03 {{ if .EnvironmentName }}{{ .EnvironmentName }}{{ end }} ",
          "trailing_diamond": "\ue0b0",
          "type": "az"
        }
      ],
      "type": "prompt"
    },
    {
      "alignment": "right",
      "segments": [
        {
          "background": "#689f63",
          "foreground": "#ffffff",
          "leading_diamond": "\ue0b2",
          "style": "diamond",
          "template": " \ue718 {{ if .PackageManagerIcon }}{{ .PackageManagerIcon }} {{ end }}{{ .Full }} ",
          "trailing_diamond": "\ue0b4",
          "type": "node"
        },
        {
          "background": "#00acd7",
          "foreground": "#ffffff",
          "leading_diamond": "\ue0b2",
          "style": "diamond",
          "template": " \ue626 {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ",
          "trailing_diamond": "\ue0b4",
          "type": "go"
        },
        {
          "background": "#4063D8",
          "foreground": "#ffffff",
          "leading_diamond": "\ue0b2",
          "style": "diamond",
          "template": " \ue624 {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ",
          "trailing_diamond": "\ue0b4",
          "type": "julia"
        },
        {
          "background": "#f3f0ec",
          "foreground": "#925837",
          "leading_diamond": "\ue0b2",
          "properties": {
            "display_mode": "files",
            "fetch_version": true
          },
          "style": "diamond",
          "template": " \ue7a8 {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ",
          "trailing_diamond": "\ue0b4",
          "type": "rust"
        }
      ],
      "type": "prompt"
    },
    {
      "alignment": "left",
      "newline": true,
      "segments": [
        {
          "foreground": "#21c7c7",
          "style": "plain",
          "template": "\u2570\u2500",
          "type": "text"
        },
        {
          "foreground": "#e0f8ff",
          "foreground_templates": [
            "{{if gt .Code 0}}#ff0000{{end}}"
          ],
          "properties": {
            "always_enabled": true
          },
          "style": "plain",
          "template": "\u276f ",
          "type": "exit"
        }
      ],
      "type": "prompt"
    }
  ],
  "final_space": true,
  "version": 2
}
EOF

echo -e "${GREEN}✓ Custom theme created${NC}"

# Configure .bashrc
print_section "Configuring .bashrc"

# Backup existing .bashrc
cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d_%H%M%S)

# Add configurations to .bashrc if not already present
if ! grep -q "# Azure WSL Quick Setup" ~/.bashrc; then
    cat >> ~/.bashrc << 'EOF'

# Azure WSL Quick Setup - Auto-generated configuration
# Generated on 2025-12-26

# Useful aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias cls='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Azure CLI aliases
alias azlogin='az login --use-device-code'
alias azaccount='az account show'
alias azlist='az account list --output table'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'

# Oh-my-posh initialization
eval "$(oh-my-posh init bash --config /usr/local/share/omp-templates/almeida.omp.json)"

EOF
    echo -e "${GREEN}✓ .bashrc configured${NC}"
else
    echo -e "${YELLOW}⚠ .bashrc already configured${NC}"
fi

# Configure .bash_profile for conda activation
print_section "Configuring .bash_profile"
if [ ! -f ~/.bash_profile ]; then
    touch ~/.bash_profile
fi

if ! grep -q "conda activate azurecli" ~/.bash_profile; then
    echo 'conda activate azurecli' >> ~/.bash_profile
    echo -e "${GREEN}✓ .bash_profile configured to auto-activate azurecli environment${NC}"
else
    echo -e "${YELLOW}⚠ .bash_profile already configured${NC}"
fi

# Install Azure CLI extensions
print_section "Installing useful Azure CLI extensions"
conda activate azurecli
az extension add --name azure-devops --only-show-errors || true
az extension add --name containerapp --only-show-errors || true
az extension add --name aks-preview --only-show-errors || true
echo -e "${GREEN}✓ Azure CLI extensions installed${NC}"

# Final message
print_section "Setup Complete!"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}   WSL is now configured for Azure Development!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}What was installed:${NC}"
echo -e "  ✓ Miniconda3"
echo -e "  ✓ Conda environment 'azurecli' with Python 3.11"
echo -e "  ✓ Azure CLI and management libraries"
echo -e "  ✓ AZQR (Azure Quick Review)"
echo -e "  ✓ CaskaydiaCove Nerd Font"
echo -e "  ✓ Oh-my-posh with custom theme"
echo -e "  ✓ Useful aliases and configurations"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Close and reopen your terminal (or run: source ~/.bashrc)"
echo -e "  2. Set your terminal font to 'CaskaydiaCove Nerd Font'"
echo -e "  3. Login to Azure: ${BLUE}az login${NC}"
echo -e "  4. Start developing! 🚀"
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo -e "  ${GREEN}conda activate azurecli${NC}  - Activate Azure environment"
echo -e "  ${GREEN}az login${NC}                 - Login to Azure"
echo -e "  ${GREEN}az account list${NC}          - List Azure subscriptions"
echo -e "  ${GREEN}azqr scan${NC}                - Scan Azure resources"
echo ""
echo -e "${YELLOW}Note: Your original .bashrc has been backed up${NC}"
echo ""
