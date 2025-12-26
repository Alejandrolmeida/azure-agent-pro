# SQL Analysis Tools

Herramientas para ejecutar y analizar consultas SQL en Azure SQL Databases.

## 🛠️ Herramientas Disponibles

### 1. sql-query.sh - Ejecutor de Consultas SQL

Ejecuta consultas SQL contra Azure SQL Databases con autenticación Azure AD.

**Ubicación**: `scripts/utils/sql-query.sh`

#### Uso

```bash
# Con Azure AD (recomendado)
./scripts/utils/sql-query.sh --server myserver --database mydb --aad --query "SELECT TOP 10 * FROM Users"

# Desde archivo
./scripts/utils/sql-query.sh -s myserver -d mydb --aad -f query.sql -o json

# Con plan de ejecución
./scripts/utils/sql-query.sh -s myserver -d mydb --aad --analytics -q "SELECT * FROM Orders"
```

### 2. sql-analyzer.sh - Analizador de Rendimiento

Analiza rendimiento y proporciona recomendaciones de optimización.

**Ubicación**: `scripts/utils/sql-analyzer.sh`

#### Análisis Disponibles

- `slow-queries`: Queries más lentas
- `missing-indexes`: Índices faltantes
- `index-usage`: Uso de índices
- `table-sizes`: Tamaños de tablas
- `blocking`: Sesiones bloqueadas
- `fragmentation`: Fragmentación de índices
- `all`: Análisis completo

#### Uso

```bash
# Análisis completo
./scripts/utils/sql-analyzer.sh -s myserver -d mydb -a all -o report.md

# Queries lentas
./scripts/utils/sql-analyzer.sh -s myserver -d mydb -a slow-queries
```

## 📦 Módulo Bicep

**Ubicación**: `bicep/modules/sql-database.bicep`

Despliega Azure SQL con seguridad y monitoreo avanzado.

```bicep
module sqlDb './modules/sql-database.bicep' = {
  name: 'sql-deployment'
  params: {
    sqlServerName: 'sql-prod'
    databaseName: 'orders'
    databaseSku: 'GP_Gen5_2'
    enableAzureADAuth: true
    enablePrivateEndpoint: true
    logAnalyticsWorkspaceId: logAnalytics.id
  }
}
```

## 🔐 Seguridad

- Usar Azure AD authentication (`--aad`)
- Private endpoints en producción
- No passwords en plaintext
- Variables de entorno para credenciales

## 📊 Casos de Uso con Copilot

El agente puede:
1. Analizar performance automáticamente
2. Identificar queries lentas y sugerir optimizaciones
3. Detectar índices faltantes
4. Diagnosticar bloqueos
5. Generar reportes de rendimiento

Ver guía completa en: [sql-tools-guide.md](./sql-tools-guide.md)
