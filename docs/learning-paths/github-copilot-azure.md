# 🤖 GitHub Copilot for Azure - Advanced Configuration Guide

## 🎯 Overview

This guide teaches you how to configure GitHub Copilot for optimal Azure development productivity. You'll learn to create custom chat modes, optimize prompts, and leverage AI assistance for complex Azure tasks.

## 📋 Prerequisites

- GitHub Copilot subscription (Individual or Business)
- VS Code with GitHub Copilot extension
- Basic knowledge of Azure services
- Azure CLI installed and configured

## 🚀 Quick Start

### 1. Install Required Extensions

```bash
# Required VS Code extensions
code --install-extension GitHub.copilot
code --install-extension GitHub.copilot-chat
code --install-extension ms-azuretools.vscode-bicep
code --install-extension ms-azuretools.vscode-azureresourcemanager-tools
```

### 2. Configure VS Code Settings

Add these settings to your VS Code configuration:

```json
{
  "github.copilot.enable": {
    "*": true,
    "bicep": true,
    "shellscript": true,
    "yaml": true,
    "json": true
  },
  "github.copilot.advanced": {
    "length": 500,
    "temperature": 0.3,
    "top_p": 1,
    "frequency_penalty": 0,
    "presence_penalty": 0
  },
  "github.copilot.editor.enableAutoCompletions": true,
  "bicep.experimental.deploymentPaneEnabled": true
}
```

## 🎭 Custom Chat Modes for Azure

### 📁 Chat Mode Files Location

Create these files in `.github/chatmodes/` directory:

### 1. Azure Infrastructure Agent

**File**: `.github/chatmodes/azure-infrastructure-agent.md`

```markdown
# Azure Infrastructure Agent

You are an expert Azure Infrastructure specialist with deep knowledge of:

## Core Expertise
- Azure Resource Manager (ARM) and Bicep templates
- Azure security best practices and compliance
- Cost optimization strategies
- High availability and disaster recovery patterns
- Azure networking and hybrid connectivity

## Communication Style
- Provide practical, actionable solutions
- Always consider security implications
- Include cost optimization recommendations
- Reference official Azure documentation
- Suggest testing and validation approaches

## Response Format
When helping with infrastructure:
1. **Assessment**: Analyze the current situation
2. **Recommendation**: Provide best practice solution
3. **Implementation**: Give step-by-step instructions
4. **Validation**: Suggest testing methods
5. **Optimization**: Identify improvement opportunities

## Azure Services Focus
Prioritize expertise in: Compute, Storage, Networking, Security, Monitoring, Cost Management, Governance, Identity & Access Management.

Always ensure solutions are production-ready, secure, and cost-effective.
```

### 2. Azure Security Agent

**File**: `.github/chatmodes/azure-security-agent.md`

```markdown
# Azure Security Agent

You are an expert Azure Security architect specializing in:

## Security Domains
- Identity and Access Management (Azure AD, RBAC, PIM)
- Network Security (NSGs, Firewalls, Private Endpoints)
- Data Protection (Encryption, Key Vault, Information Protection)
- Threat Detection (Security Center, Sentinel, Advanced Threat Protection)
- Compliance (Azure Policy, Blueprints, Regulatory Standards)

## Security-First Approach
- Apply Zero Trust principles
- Implement defense in depth
- Follow least privilege access
- Enable continuous monitoring
- Automate security responses

## Response Guidelines
1. **Risk Assessment**: Identify potential threats
2. **Security Controls**: Recommend appropriate safeguards
3. **Implementation**: Provide secure configuration steps
4. **Monitoring**: Suggest detection and alerting
5. **Compliance**: Ensure regulatory requirements

Focus on practical security implementations that don't compromise usability while maintaining strong security posture.
```

### 3. Azure DevOps Pipeline Agent

**File**: `.github/chatmodes/azure-devops-pipeline-agent.md`

```markdown
# Azure DevOps Pipeline Agent

You are an expert in Azure DevOps and CI/CD automation specializing in:

## Pipeline Expertise
- Azure DevOps Pipelines (YAML and Classic)
- GitHub Actions for Azure deployments
- Infrastructure as Code deployments
- Multi-stage deployment strategies
- Testing automation and quality gates

## Best Practices Focus
- GitOps workflows
- Environment promotion strategies
- Automated testing (unit, integration, infrastructure)
- Security scanning integration
- Performance and load testing

## Response Structure
1. **Pipeline Design**: Recommend optimal workflow structure
2. **Implementation**: Provide YAML/configuration examples
3. **Testing Strategy**: Include quality assurance steps
4. **Security Integration**: Add security scanning and validation
5. **Monitoring**: Include deployment tracking and alerts

Always include error handling, rollback strategies, and approval processes for production deployments.
```

## 🎯 Optimized Prompts for Azure Tasks

### 📝 Bicep Template Generation

**Prompt Template:**
```
Create a Bicep template for [AZURE_SERVICE] with the following requirements:
- Security: [SECURITY_REQUIREMENTS]
- Environment: [DEV/TEST/PROD]
- Compliance: [COMPLIANCE_STANDARDS]
- Cost optimization: [BUDGET_CONSTRAINTS]

Include:
- Parameter validation
- Resource naming conventions
- Output values
- Security best practices
- Comments explaining decisions

Use enterprise-grade patterns and follow Azure Well-Architected Framework principles.
```

**Example Usage:**
```
Create a Bicep template for Azure Storage Account with the following requirements:
- Security: Private endpoints, encryption at rest, no public access
- Environment: Production
- Compliance: SOC 2, GDPR
- Cost optimization: Standard LRS, lifecycle management

Include parameter validation, resource naming conventions, output values, security best practices, and comments explaining decisions.
```

### 🔒 Security Configuration

**Prompt Template:**
```
Help me secure [AZURE_RESOURCE] following these requirements:
- Security framework: [ZERO_TRUST/CIS/NIST]
- Compliance needs: [REGULATIONS]
- Integration with: [OTHER_SERVICES]
- Monitoring requirements: [ALERTING_NEEDS]

Provide:
- Security configuration steps
- Network security rules
- Access control setup
- Monitoring and alerting
- Compliance validation

Focus on defense in depth and automation.
```

### 🔄 CI/CD Pipeline Creation

**Prompt Template:**
```
Create a CI/CD pipeline for deploying [INFRASTRUCTURE/APPLICATION] to Azure with:
- Source: [GITHUB/AZURE_REPOS]
- Target environments: [DEV/TEST/PROD]
- Deployment strategy: [BLUE_GREEN/CANARY/ROLLING]
- Testing requirements: [UNIT/INTEGRATION/E2E]
- Security scanning: [ENABLED/DISABLED]

Include:
- Pipeline YAML/configuration
- Environment-specific parameters
- Approval processes
- Rollback strategies
- Monitoring integration
```

## 🛠️ Advanced Copilot Techniques

### 1. Context-Aware Development

**Before asking Copilot:**
1. Open relevant files in your workspace
2. Include resource naming conventions in comments
3. Add environment context (dev/test/prod)
4. Reference related Azure services

**Example:**
```bicep
// Context: Production environment
// Naming convention: company-env-location-service-purpose
// Related services: Key Vault, App Service, SQL Database
// Compliance: SOC 2, HIPAA

param storageAccountName string = 'contosoprodeuststorage'
```

### 2. Incremental Refinement

Start with basic prompts and refine:

**Initial:**
```
Create a storage account in Bicep
```

**Refined:**
```
Create a production-ready storage account Bicep template with:
- GPv2 with hot/cool tiers
- Private endpoints
- Lifecycle management
- Encryption with customer-managed keys
- Diagnostic logging
- RBAC assignments
```

### 3. Documentation-Driven Development

Include documentation requirements in prompts:
```
Generate a Bicep module with comprehensive documentation including:
- Parameter descriptions
- Usage examples
- Security considerations
- Cost implications
- Troubleshooting guide
```

## 📊 Productivity Metrics

Track your Copilot productivity:

- **Lines of code generated**: Monitor daily/weekly output
- **Time saved**: Estimate time reduction on common tasks
- **Quality improvements**: Track deployment success rates
- **Learning acceleration**: Measure knowledge acquisition

### Recommended Tools

- **GitHub Copilot Metrics**: Built-in usage analytics
- **Custom scripts**: Track template generation efficiency
- **Deployment monitoring**: Success/failure rates
- **Code review feedback**: Quality assessments

## 🎓 Learning Exercises

### Exercise 1: Basic Infrastructure
Create a complete web application infrastructure using only Copilot assistance:
- App Service Plan
- Web App
- SQL Database
- Storage Account
- Key Vault

### Exercise 2: Security Hardening
Take a basic deployment and secure it using Copilot suggestions:
- Add network restrictions
- Implement managed identities
- Configure monitoring
- Add compliance policies

### Exercise 3: CI/CD Automation
Build a complete deployment pipeline with:
- Bicep validation
- Security scanning
- Multi-environment deployment
- Rollback capabilities

## 🔗 Additional Resources

- [GitHub Copilot Documentation](https://docs.github.com/en/copilot)
- [Azure Bicep Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure Well-Architected Framework](https://docs.microsoft.com/en-us/azure/architecture/framework/)
- [Azure Security Best Practices](https://docs.microsoft.com/en-us/azure/security/)

## 🆘 Troubleshooting

### Common Issues

**Copilot not suggesting Azure-specific code:**
- Ensure Azure extensions are installed
- Open Azure-related files for context
- Use specific Azure terminology in prompts

**Suggestions not following best practices:**
- Include security requirements in prompts
- Reference compliance frameworks
- Ask for production-ready implementations

**Inconsistent naming conventions:**
- Define naming standards in comments
- Include examples in your prompts
- Create reusable prompt templates

---

**Next Steps**: Practice with the exercises above and gradually increase complexity. Join our [discussions](https://github.com/alejandrolmeida/azure-agent-pro/discussions) to share your experiences and learn from others!