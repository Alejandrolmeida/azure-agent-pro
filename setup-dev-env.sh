#!/bin/bash
#
# Development Tools Setup Script for AVD PIX4D Project
# This script sets up all necessary tools in the current conda environment

set -e

echo "=========================================="
echo "AVD PIX4D - Development Environment Setup"
echo "=========================================="
echo ""

# Check if we're in a conda environment
if [ -z "$CONDA_DEFAULT_ENV" ]; then
    echo "⚠️  Warning: No conda environment detected!"
    echo "   It's recommended to create a dedicated environment:"
    echo "   conda create -n avd-pix4d python=3.11"
    echo "   conda activate avd-pix4d"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Install Azure CLI
echo "📦 Installing Azure CLI..."
if ! command -v az &> /dev/null; then
    conda install -c conda-forge azure-cli -y
    echo "✅ Azure CLI installed"
else
    echo "✅ Azure CLI already installed ($(az version --output tsv 2>&1 | head -1))"
fi

# Install jq
echo ""
echo "📦 Installing jq (JSON processor)..."
if ! command -v jq &> /dev/null; then
    conda install -c conda-forge jq -y
    echo "✅ jq installed"
else
    echo "✅ jq already installed ($(jq --version))"
fi

# Install Git
echo ""
echo "📦 Checking Git..."
if ! command -v git &> /dev/null; then
    conda install -c conda-forge git -y
    echo "✅ Git installed"
else
    echo "✅ Git already installed ($(git --version))"
fi

# Install Bicep CLI
echo ""
echo "📦 Installing Bicep CLI..."
az bicep install 2>/dev/null || echo "Bicep already at latest version"
echo "✅ Bicep installed ($(az bicep version))"

# Install Azure Desktop Virtualization extension
echo ""
echo "📦 Installing Azure Desktop Virtualization extension..."
az extension add --name desktopvirtualization --upgrade 2>/dev/null || echo "✅ Extension already installed"

# Optional: Install PowerShell
echo ""
read -p "📦 Install PowerShell? (optional, for .ps1 scripts) (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "Installing PowerShell for Linux..."
        conda install -c conda-forge powershell -y || {
            echo "⚠️  Conda installation failed, trying manual installation..."
            wget -q https://github.com/PowerShell/PowerShell/releases/download/v7.4.0/powershell-7.4.0-linux-x64.tar.gz
            mkdir -p ~/.local/share/powershell
            tar -xzf powershell-7.4.0-linux-x64.tar.gz -C ~/.local/share/powershell
            rm powershell-7.4.0-linux-x64.tar.gz
            ln -sf ~/.local/share/powershell/pwsh ~/.local/bin/pwsh
        }
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Installing PowerShell for macOS..."
        if command -v brew &> /dev/null; then
            brew install --cask powershell
        else
            conda install -c conda-forge powershell -y
        fi
    fi
    echo "✅ PowerShell installed"
else
    echo "⏭️  Skipping PowerShell installation"
    echo "   (You can use the Bash scripts in tests/ instead)"
fi

# Make scripts executable
echo ""
echo "📝 Setting execute permissions on scripts..."
chmod +x tests/smoke/*.sh tests/e2e/*.sh 2>/dev/null || true
echo "✅ Script permissions set"

# Summary
echo ""
echo "=========================================="
echo "✨ Setup Complete!"
echo "=========================================="
echo ""
echo "Installed tools:"
echo "  ✅ Azure CLI: $(az version --output json 2>/dev/null | jq -r '.\"azure-cli\"' 2>/dev/null || echo 'installed')"
echo "  ✅ Bicep: $(az bicep version)"
echo "  ✅ jq: $(jq --version)"
echo "  ✅ Git: $(git --version | cut -d' ' -f3)"
if command -v pwsh &> /dev/null; then
    echo "  ✅ PowerShell: $(pwsh --version | head -1)"
fi

echo ""
echo "Next steps:"
echo "1. Login to Azure: az login"
echo "2. Set subscription: az account set --subscription YOUR-SUB-ID"
echo "3. Run tests: ./tests/smoke/az-smoke.sh lab westeurope"
echo "4. Deploy: See infra/README.md for deployment instructions"
echo ""
echo "For more information, see docs/ENVIRONMENT_SETUP.md"
