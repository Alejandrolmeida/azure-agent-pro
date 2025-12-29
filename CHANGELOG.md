# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [v1.1.0] - 2025-12-29

### 🎯 Highlights
- Azure SQL DBA Agent completo con metodología evidence-first
- Herramientas SQL avanzadas (sql-query.py, sql-analyzer.sh, detect-zombie-transactions.sh)
- Detección de transacciones zombie (ADR/PVS-aware)
- Reorganización completa de scripts por agente
- 12 nuevos archivos de documentación
- 7 scripts SQL/Bash/Python nuevos

### Added
- Azure SQL DBA Agent con 6 playbooks completos
- SQL query execution tools (Python + Bash)
- SQL performance analyzer con 8 análisis automatizados
- Zombie transaction detection tools
- Interactive SQL diagnosis scripts for SSMS
- Azure SQL connection guide (327 líneas)
- Microsoft Support email templates
- Usage pattern analysis for maintenance windows
- WSL quick setup script

### Changed
- **BREAKING**: Scripts reorganizados en estructura por agente
  - `scripts/common/` - Scripts compartidos
  - `scripts/agents/architect/` - Azure Architect Agent
  - `scripts/agents/sql-dba/` - Azure SQL DBA Agent
- 87+ referencias actualizadas en documentación

### Fixed
- SQL Server Bicep module corregido
- Workflows de calidad configurados para ejecución manual

### Security
- Repository sanitizado (sin datos reales en commits)
- Ejemplos anonymizados en toda la documentación
- Azure AD authentication preferido sobre SQL auth

**📄 Full Release Notes**: [docs/releases/v1.1.0.md](docs/releases/v1.1.0.md)  
**📦 Commits**: 18 commits | **📊 Files**: +12 | **📝 Lines**: +5,000

---

## [v1.0.0] - 2025-12-09

### Initial Release
- Azure Architect Agent completo
- Bicep modules para infraestructura Azure
- MCP servers integration (Bicep experimental, Pylance)
- GitHub Actions workflows
- Complete documentation structure
- Kitten Space Missions workshop

**📄 Full Release Notes**: [docs/releases/v1.0.0.md](docs/releases/v1.0.0.md)

---

## Release Links

- **Latest**: [v1.1.0](https://github.com/Alejandrolmeida/azure-agent-pro/releases/tag/v1.1.0)
- **Previous**: [v1.0.0](https://github.com/Alejandrolmeida/azure-agent-pro/releases/tag/v1.0.0)
- **All Releases**: [GitHub Releases](https://github.com/Alejandrolmeida/azure-agent-pro/releases)

---

## Migration Guides

### From v1.0.0 to v1.1.0

**Scripts Path Changes:**

| Old Path | New Path |
|----------|----------|
| `scripts/utils/sql-*.sh` | `scripts/agents/sql-dba/sql-*.sh` |
| `scripts/deploy/bicep-deploy.sh` | `scripts/agents/architect/bicep-deploy.sh` |
| `scripts/config/azure-config.sh` | `scripts/common/azure-config.sh` |
| `scripts/login/azure-login.sh` | `scripts/common/azure-login.sh` |

**Action Required**: Update any scripts or CI/CD pipelines that reference old paths.

---

[v1.1.0]: https://github.com/Alejandrolmeida/azure-agent-pro/compare/v1.0.0...v1.1.0
[v1.0.0]: https://github.com/Alejandrolmeida/azure-agent-pro/releases/tag/v1.0.0
