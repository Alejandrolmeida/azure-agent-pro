# Release v1.1.0 - Azure SQL DBA Agent & Infrastructure Reorganization

**Release Date:** December 29, 2025  
**Type:** Minor Release (Feature Addition)

---

## 🎯 Highlights

Esta release introduce el **Azure SQL DBA Agent** completo, una herramienta profesional de élite para troubleshooting, performance tuning y gestión de bases de datos Azure SQL. Además, reorganiza completamente la estructura de scripts para mejor mantenibilidad.

### 🌟 Nuevas Características Principales

1. **🔧 Azure SQL DBA Agent Completo**
   - Agente especializado con metodología evidence-first
   - Troubleshooting avanzado de performance, bloqueos y crecimiento
   - Herramientas automatizadas con Azure AD authentication
   - Playbooks completos para escenarios comunes

2. **📦 Scripts Organizados por Agente**
   - Nueva estructura: `scripts/common/`, `scripts/agents/architect/`, `scripts/agents/sql-dba/`
   - 87+ referencias actualizadas automáticamente
   - Historia de Git preservada con `git mv`

3. **🔍 Herramientas SQL Avanzadas**
   - Scripts Python y Bash para ejecutar queries
   - Analizador de performance automatizado
   - Detección de transacciones zombie (ADR/PVS-aware)
   - Soporte completo para SQL auth y Azure AD auth

---

## 📋 Changelog Detallado

### ✨ Features

#### Azure SQL DBA Agent
- **NEW**: Agente Azure_SQL_DBA con 1000+ líneas de documentación
- **NEW**: Metodología evidence-first con 6 playbooks completos
- **NEW**: Sistema de aprobación para operaciones de escritura
- **NEW**: Checklist ADR/PVS para troubleshooting storage
- **NEW**: Scripts de diagnóstico interactivos para SSMS
- **NEW**: Templates de email para Microsoft Support

#### SQL Tools & Automation
- **NEW**: `sql-query.py` - Ejecutor Python con Azure AD + SQL auth
- **NEW**: `sql-analyzer.sh` - 8 análisis de performance automatizados
- **NEW**: `sql-connect.sh` - Wrapper bash con variables de entorno
- **NEW**: `detect-zombie-transactions.sh` - Detección automatizada
- **NEW**: `zombie-diagnosis-interactive.sql` - Script para SSMS con 5 pasos

#### Documentation
- **NEW**: `azure-sql-connection-guide.md` - Guía completa de conexión (327 líneas)
- **NEW**: `zombie-transactions-quickstart.md` - Quick reference para DBAs
- **NEW**: `sql-tools-guide.md` - Referencia de herramientas SQL
- **NEW**: `sql-solution-comparison.md` - Análisis de seguridad (400+ líneas)
- **NEW**: Templates para Microsoft Support (email-brief.txt)
- **NEW**: Análisis de patrones de uso para ventanas de mantenimiento

### 🔧 Improvements

#### Infrastructure
- **IMPROVED**: Reorganización completa de `scripts/` por agente
- **IMPROVED**: Bicep module `sql-database.bicep` con security baseline
- **IMPROVED**: WSL quick setup script con Miniconda y Azure CLI

#### Agente Capabilities
- **IMPROVED**: Azure Architect Agent con SQL tools integrados
- **IMPROVED**: Permisos de ejecución SQL documentados (READ-ONLY vs WRITE)
- **IMPROVED**: Workflow de aprobación para operaciones críticas

### 🐛 Bug Fixes

- **FIX**: SQL Server Bicep module corregido
- **FIX**: Workflows de calidad deshabilitados (ejecución manual)
- **FIX**: Backup files removidos del repositorio

### 🔐 Security

- **SECURITY**: Todos los ejemplos usan credenciales anonymizadas
- **SECURITY**: Soporte Azure AD authentication preferido
- **SECURITY**: Guías de Key Vault para credenciales en producción
- **SECURITY**: Private endpoints en módulos Bicep
- **SECURITY**: Repository sanitizado (sin datos reales en commits)

---

## 📊 Statistics

- **Commits desde v1.0.0**: 18
- **Archivos añadidos**: 12
- **Archivos modificados**: 25+
- **Líneas de código añadidas**: 5,000+
- **Documentación**: 2,500+ líneas
- **Scripts**: 7 nuevos scripts SQL/Bash/Python

---

## 🗂️ Nueva Estructura de Scripts

```
scripts/
├── common/              # Scripts compartidos
│   ├── azure-config.sh
│   ├── azure-login.sh
│   └── azure-utils.sh
├── agents/
│   ├── architect/       # Azure Architect Agent
│   │   ├── bicep-deploy.sh
│   │   └── bicep-utils.sh
│   └── sql-dba/        # Azure SQL DBA Agent
│       ├── detect-zombie-transactions.sh
│       ├── sql-analyzer.sh
│       ├── sql-connect.sh
│       ├── sql-query.py
│       └── sql-query.sh
└── setup/              # Setup & maintenance
    ├── github-repository-setup.sh
    ├── mcp-setup.sh
    ├── mcp-simple-setup.sh
    ├── project-updater.sh
    └── wsl-quick-setup.sh
```

---

## 🚀 Getting Started

### Para DBAs

1. **Configurar credenciales:**
   ```bash
   export AZURE_SQL_SERVER="your-server.database.windows.net"
   export AZURE_SQL_DATABASE="your-database"
   ```

2. **Ejecutar análisis completo:**
   ```bash
   ./scripts/agents/sql-dba/sql-analyzer.sh \
     --server $AZURE_SQL_SERVER \
     --database $AZURE_SQL_DATABASE \
     --aad \
     --analysis all
   ```

3. **Detectar problemas:**
   ```bash
   # Transacciones zombie
   ./scripts/agents/sql-dba/detect-zombie-transactions.sh
   
   # O usar script interactivo en SSMS
   # docs/queries/zombie-diagnosis-interactive.sql
   ```

### Para Architects

1. **Desplegar Azure SQL con security baseline:**
   ```bash
   ./scripts/agents/architect/bicep-deploy.sh \
     --resource-group rg-prod \
     --template bicep/modules/sql-database.bicep \
     --parameters bicep/parameters/prod.json \
     --what-if
   ```

---

## 📚 Documentation

### Nuevas Guías

- **SQL Connection Guide**: `docs/reference/azure-sql-connection-guide.md`
- **SQL Tools Reference**: `docs/reference/sql-tools-guide.md`
- **Zombie Transactions Quickstart**: `docs/reference/zombie-transactions-quickstart.md`
- **SQL Security Comparison**: `docs/reference/sql-solution-comparison.md`

### Scripts de Ejemplo

- **Diagnóstico SSMS**: `docs/queries/zombie-diagnosis-interactive.sql`
- **Detección SQL**: `docs/queries/detect-zombie-transactions.sql`
- **Análisis de uso**: `docs/queries/analyze-usage-patterns.sql`

### Templates

- **Microsoft Support Email**: `docs/templates/email-brief.txt`
- **Email completo**: `docs/templates/microsoft-support-email-zombie-transactions.md`

---

## 🎓 Playbooks Incluidos

1. **Performance Degradation** - Análisis de CPU/IO/Memory
2. **Blocking & Deadlocks** - Detección y prevención
3. **Storage Growth (ADR/PVS)** - Troubleshooting específico
4. **Architecture Design** - IaC con Bicep
5. **FinOps** - Optimización de costos
6. **Security & Compliance** - Zero Trust patterns

---

## ⚙️ Technical Details

### Azure SQL DBA Agent Capabilities

- **Evidence-First Methodology**: No especulación, solo datos confirmados
- **ADR/PVS Awareness**: Detección avanzada de problemas storage
- **Approval Workflow**: Sistema de permisos para operaciones críticas
- **Multi-Auth Support**: SQL auth + Azure AD authentication
- **Production Safety**: Blast radius analysis antes de cambios

### Tools Features

- **sql-query.py**:
  - Azure AD token encoding (struct.pack para >2000 chars)
  - SQL authentication
  - Output formats: table, json
  - Auto-instala pyodbc

- **sql-analyzer.sh**:
  - 8 análisis automatizados
  - slow-queries, missing-indexes, index-usage
  - table-sizes, blocking, fragmentation
  - statistics, Azure recommendations

- **detect-zombie-transactions.sh**:
  - Detección con colores
  - Análisis de impacto en espacio
  - Recomendaciones automáticas

---

## 🔄 Migration Guide

### Actualizar Referencias de Scripts

Si tienes scripts o documentación que referencian las rutas antiguas:

```bash
# Antiguo
./scripts/utils/sql-query.sh
./scripts/deploy/bicep-deploy.sh
./scripts/config/azure-config.sh

# Nuevo (desde v1.1.0)
./scripts/agents/sql-dba/sql-query.sh
./scripts/agents/architect/bicep-deploy.sh
./scripts/common/azure-config.sh
```

**Nota**: Si clonaste el repo después del 29/12/2025, ya tienes la nueva estructura.

---

## 🐛 Known Issues

- **MCP SQL Server**: Configuración manual requerida en mcp.json
- **ODBC Driver 18**: Debe instalarse manualmente en Linux
- **Azure AD Tokens**: Requiere `az login` previo

---

## 📦 Dependencies

### Nuevas Dependencias Opcionales

- **Python 3.8+**: Para sql-query.py
- **pyodbc**: Auto-instalado por scripts
- **ODBC Driver 18 for SQL Server**: Para conexiones SQL
- **Azure CLI**: Para Azure AD authentication

### Instalación Rápida

```bash
# Ubuntu/Debian
curl https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
sudo apt-get update
sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18
```

---

## 🙏 Contributors

- **alejandrolmeida** - 18 commits
  - Azure SQL DBA Agent development
  - SQL tools implementation
  - Documentation & guides
  - Infrastructure reorganization

---

## 📝 Breaking Changes

### ⚠️ IMPORTANTE: Cambios en Rutas de Scripts

La reorganización de scripts es un **breaking change menor**. Si tienes:

- **Scripts personalizados** que llaman a scripts del repo
- **CI/CD pipelines** con rutas hardcodeadas
- **Documentación externa** que referencia scripts

**Debes actualizar las rutas** según la tabla de migración arriba.

**Impacto**: Bajo (solo paths cambiaron, funcionalidad idéntica)

---

## 🔗 Links

- **Repository**: https://github.com/Alejandrolmeida/azure-agent-pro
- **v1.0.0 Release**: https://github.com/Alejandrolmeida/azure-agent-pro/releases/tag/v1.0.0
- **v1.1.0 Tag**: https://github.com/Alejandrolmeida/azure-agent-pro/releases/tag/v1.1.0
- **Issues**: https://github.com/Alejandrolmeida/azure-agent-pro/issues

---

## 🎯 Next Steps (v1.2.0 Roadmap)

- [ ] Azure Container Apps agent
- [ ] Azure API Management agent
- [ ] Advanced networking patterns
- [ ] Multi-cloud integration (AWS/GCP)
- [ ] Industry-specific templates (Healthcare, Finance)

---

## 📄 License

MIT License - See LICENSE file for details

---

**Full Changelog**: https://github.com/Alejandrolmeida/azure-agent-pro/compare/v1.0.0...v1.1.0
