# Configuration Template for Azure Agent

This file contains the configuration values you need to set up for your Azure Agent deployment.

## GitHub Repository Settings

### Repository Variables
Configure these in: `Settings → Secrets and variables → Actions → Variables`

```bash
# Project Configuration
PROJECT_NAME=your-project-name # Replace with your project name

# Azure Locations
DEFAULT_LOCATION=eastus # Default Azure region
PROD_LOCATION=eastus # Production Azure region 
TEST_LOCATION=westus2 # Test Azure region
STAGE_LOCATION=westeurope # Staging Azure region

# Resource Groups
CI_RESOURCE_GROUP=your-ci-rg # CI/CD resource group name
```

### Repository Secrets
Configure these in: `Settings → Secrets and variables → Actions → Secrets`

```bash
# Azure Service Principal for OIDC (Required)
AZURE_CLIENT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
AZURE_TENANT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx 
AZURE_SUBSCRIPTION_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Optional: Notification integrations
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
TEAMS_WEBHOOK_URL=https://outlook.office.com/webhook/...
```

## Azure Service Principal Setup

### Option 1: Using Azure CLI (Recommended)

```bash
# Login to Azure
az login

# Create service principal with OIDC
az ad sp create-for-rbac \
 --name "azure-agent-github-actions" \
 --role "Contributor" \
 --scopes "/subscriptions/YOUR_SUBSCRIPTION_ID" \
 --create-cert \
 --cert @~/.azure/azure-agent-cert.pem

# Configure federated identity credential
az ad app federated-credential create \
 --id YOUR_CLIENT_ID \
 --parameters '{
 "name": "github-actions-main", 
 "issuer": "https://token.actions.githubusercontent.com",
 "subject": "repo:YOUR_USERNAME/azure-agent:ref:refs/heads/main",
 "audiences": ["api://AzureADTokenExchange"]
 }'
```

### Option 2: Using the setup script

```bash
# Run the automated setup script
./scripts/setup/mcp-setup.sh --github-integration
```

## 🌍 Environment Configuration

### Development Environment
- **Resource Group**: `{PROJECT_NAME}-dev-rg`
- **Location**: `{DEFAULT_LOCATION}`
- **Auto-deploy**: On push to main
- **Required secrets**: Basic Azure credentials

### Test Environment 
- **Resource Group**: `{PROJECT_NAME}-test-rg`
- **Location**: `{TEST_LOCATION}`
- **Deploy**: Manual approval required
- **Required secrets**: Same as dev + test-specific configs

### Staging Environment
- **Resource Group**: `{PROJECT_NAME}-stage-rg` 
- **Location**: `{STAGE_LOCATION}`
- **Deploy**: Manual approval + wait time
- **Required secrets**: Production-like configuration

### Production Environment
- **Resource Group**: `{PROJECT_NAME}-prod-rg`
- **Location**: `{PROD_LOCATION}`
- **Deploy**: Multiple approvals + confirmation required
- **Required secrets**: Full production configuration

## Required Permissions

### Azure RBAC Roles
The service principal needs these roles:

```bash
# Minimum required roles
Contributor # Create/manage resources
User Access Administrator # Manage Key Vault access policies
```

### Optional Roles for Enhanced Features
```bash
Key Vault Administrator # Full Key Vault management
Network Contributor # VNet management 
Storage Account Contributor # Storage management
```

## Security Considerations

### Secrets Management
- **Never commit secrets** to the repository
- **Use OIDC authentication** instead of service principal secrets
- **Rotate credentials** regularly
- **Use Key Vault** for application secrets
- **Enable audit logging** for all resources

### Network Security
- **Use private endpoints** for production
- **Enable NSGs** for network segmentation
- **Disable public access** where possible
- **Use HTTPS/TLS 1.3** everywhere

### Access Control
- **Implement RBAC** with least privilege
- **Use managed identities** for Azure services
- **Enable MFA** for all human accounts
- **Regular access reviews**

## Quick Setup Checklist

- [ ] Fork/clone the repository
- [ ] Update `PROJECT_NAME` in workflow files
- [ ] Create Azure Service Principal
- [ ] Configure repository secrets
- [ ] Set up branch protection rules
- [ ] Test deployment to dev environment
- [ ] Configure production approvers
- [ ] Document any custom configurations

## 📞 Support

If you need help with configuration:
1. Check the [documentation](../README.md)
2. Review [troubleshooting guide](../docs/TROUBLESHOOTING.md) 
3. Open an [issue](../../issues/new/choose)
4. Join [discussions](../../discussions)

---

**Note**: Replace all placeholder values (`YOUR_*`, `{PROJECT_NAME}`, etc.) with your actual values before using.
