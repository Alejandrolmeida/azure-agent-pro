// ========================================
// PRODUCTION ENVIRONMENT PARAMETERS - 2025 MODERNIZED
// ========================================
// Modern .bicepparam file for production environment
// Replaces traditional JSON parameter files with type safety
// ========================================

using '../main.bicep'

// Basic configuration
param location = 'East US'
param environment = 'prod'
param projectName = 'azure-agent'

// Production-specific configuration (performance and security optimized)
// Storage: Geo-redundant storage (GRS) for disaster recovery
// Key Vault: Premium SKU with HSM support and purge protection
// Virtual Network: Standard DDoS protection enabled
// VM Protection: Enabled for enhanced security
// Flow timeout: Default 4 minutes for optimal performance

// Tags are automatically generated in main.bicep with environment-specific values
