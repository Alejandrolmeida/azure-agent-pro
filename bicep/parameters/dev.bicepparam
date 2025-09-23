// ========================================
// DEVELOPMENT ENVIRONMENT PARAMETERS - 2025 MODERNIZED
// ========================================
// Modern .bicepparam file for development environment
// Replaces traditional JSON parameter files with type safety
// ========================================

using '../main.bicep'

// Basic configuration
param location = 'East US'
param environment = 'dev'
param projectName = 'azure-agent'

// Development-specific overrides (cost-optimized)
// Storage: Standard LRS for development
// Key Vault: Standard SKU (Premium features not needed in dev)
// Virtual Network: Basic DDoS protection (Standard protection disabled)
// VM Protection: Disabled for cost savings

// Tags are automatically generated in main.bicep with environment-specific values