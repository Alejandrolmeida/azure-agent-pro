// ============================================================================
// Azure Maps Module
// ============================================================================
// Servicios de mapas y routing para calcular rutas ciclables
// ============================================================================

@description('Región de Azure')
param location string

@description('Nombre de la cuenta de Azure Maps')
param mapsAccountName string

@description('Tags para el recurso')
param tags object = {}

@description('SKU de Azure Maps')
@allowed(['S0', 'S1', 'G2'])
param sku string = 'G2'

@description('Deshabilitar acceso de clave local (usar solo Azure AD)')
param disableLocalAuth bool = false

// ============================================================================
// AZURE MAPS ACCOUNT
// ============================================================================

resource mapsAccount 'Microsoft.Maps/accounts@2023-06-01' = {
  name: mapsAccountName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: 'Gen2'
  properties: {
    disableLocalAuth: disableLocalAuth
    // CORS configuration
    cors: {
      corsRules: [
        {
          allowedOrigins: ['*']
        }
      ]
    }
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output mapsAccountId string = mapsAccount.id
output mapsAccountName string = mapsAccount.name
output primaryKey string = mapsAccount.listKeys().primaryKey
output secondaryKey string = mapsAccount.listKeys().secondaryKey
