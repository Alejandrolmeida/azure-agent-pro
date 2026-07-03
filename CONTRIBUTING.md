# 🤝 Guía de Contribución - Azure Agent

¡Gracias por tu interés en contribuir al proyecto Azure Agent! Esta guía te ayudará a entender cómo puedes contribuir de manera efectiva.

## Tabla de Contenidos

- [ Cómo Contribuir](#-cómo-contribuir)
- [ Configuración del Entorno](#-configuración-del-entorno)
- [ Convenciones de Código](#-convenciones-de-código)
- [🔄 Proceso de Pull Request](#-proceso-de-pull-request)
- [🐛 Reportar Bugs](#-reportar-bugs)
- [ Sugerir Funcionalidades](#-sugerir-funcionalidades)
- [ Mejoras de Documentación](#-mejoras-de-documentación)
- [🌍 Ambientes y Testing](#-ambientes-y-testing)

## Cómo Contribuir

Hay varias formas de contribuir al proyecto:

### 🐛 Reportar Issues
- Usa las plantillas de issues disponibles
- Incluye toda la información solicitada
- Busca issues existentes antes de crear uno nuevo

### Contribuir Código
- Fix de bugs
- Nuevas funcionalidades
- Mejoras de performance
- Refactoring de código existente

### Documentación
- Mejorar documentación existente
- Añadir nuevos ejemplos
- Corregir errores de documentación
- Traducir contenido

### Testing
- Añadir nuevos tests
- Mejorar cobertura de tests
- Reportar bugs encontrados durante testing

## Configuración del Entorno

### Prerequisitos

```bash
# Azure CLI (versión 2.55.0 o superior)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Bicep CLI
az bicep install

# Herramientas de desarrollo
sudo apt-get install shellcheck # Para validación de scripts bash
npm install -g markdownlint-cli # Para validación de markdown
```

### Setup del Proyecto

1. **Fork del repositorio**
 ```bash
 # Haz fork del repositorio en GitHub, luego:
 git clone https://github.com/tu-usuario/azure-agent.git
 cd azure-agent
 ```

2. **Configurar upstream**
 ```bash
 git remote add upstream https://github.com/alejandrolmeida/azure-agent.git
 ```

3. **Configurar Azure CLI**
 ```bash
 az login
 az account set --subscription "tu-subscription-id"
 ```

4. **Verificar setup**
 ```bash
 # Ejecutar validaciones básicas
 ./scripts/common/azure-utils.sh --verify
 az bicep version
 shellcheck --version
 ```

## Convenciones de Código

### Bicep Templates

```bicep
// Buenas prácticas
@description('Nombre del storage account')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Configuración de red para el storage account')
@allowed([
 'Allow'
 'Deny'
])
param publicNetworkAccess string = 'Deny'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
 name: storageAccountName
 location: resourceGroup().location
 kind: 'StorageV2'
 sku: {
 name: 'Standard_LRS'
 }
 properties: {
 publicNetworkAccess: publicNetworkAccess
 supportsHttpsTrafficOnly: true
 encryption: {
 services: {
 blob: {
 enabled: true
 }
 file: {
 enabled: true
 }
 }
 keySource: 'Microsoft.Storage'
 }
 }
}
```

### 📜 Bash Scripts

```bash
#!/bin/bash
# Header estándar para todos los scripts

# Configuración estricta de bash
set -euo pipefail
IFS=$'\n\t'

# Variables globales en MAYÚSCULAS
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Funciones con snake_case
function validate_azure_login() {
 local current_account
 
 if ! current_account=$(az account show --output tsv --query name 2>/dev/null); then
 echo " Error: No hay sesión activa de Azure CLI"
 echo "Ejecuta: az login"
 return 1
 fi
 
 echo " Azure CLI configurado: ${current_account}"
 return 0
}

# Main function
function main() {
 validate_azure_login
 # ... resto de la lógica
}

# Ejecutar main si es llamado directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
 main "$@"
fi
```

### Estructura de Archivos

```
scripts/
├── category/
│ ├── script-name.sh # Script principal
│ ├── script-name.config # Configuración (si aplica)
│ └── README.md # Documentación específica
```

### 🏷️ Naming Conventions

- **Archivos**: `kebab-case.sh`, `kebab-case.bicep`
- **Variables Bash**: `snake_case` (locales), `UPPER_CASE` (globales/constantes)
- **Variables Bicep**: `camelCase`
- **Funciones**: `snake_case`
- **Recursos Azure**: `prefix-environment-location-type-purpose`

## 🔄 Proceso de Pull Request

### 1. Crear Feature Branch

```bash
# Sincronizar con upstream
git fetch upstream
git checkout main
git merge upstream/main

# Crear nueva branch
git checkout -b feature/descripcion-corta
# o
git checkout -b fix/numero-issue-descripcion
```

### 2. Desarrollo

```bash
# Hacer cambios
# Ejecutar tests localmente
./scripts/test/run-local-tests.sh

# Validar Bicep
az bicep build --file bicep/main.bicep

# Validar scripts
find scripts/ -name "*.sh" -exec shellcheck {} \;
```

### 3. Commits

```bash
# Commits descriptivos siguiendo conventional commits
git commit -m "feat: añadir validación de parámetros en azure-login.sh"
git commit -m "fix: corregir error en deployment de storage account"
git commit -m "docs: actualizar README con nuevos comandos"
```

### 4. Push y PR

```bash
git push origin feature/descripcion-corta
# Crear PR en GitHub usando la plantilla
```

### 5. Review Process

- Los PRs requieren al menos 1 review
- Todos los checks de CI/CD deben pasar
- La documentación debe estar actualizada
- No debe haber merge conflicts

## 🐛 Reportar Bugs

1. **Verificar** que el bug no ha sido reportado antes
2. **Usar** la plantilla de bug report
3. **Incluir**:
 - Pasos para reproducir
 - Comportamiento esperado vs actual
 - Información del entorno
 - Logs completos
 - Capturas de pantalla si aplica

## Sugerir Funcionalidades

1. **Crear** un issue usando la plantilla de feature request
2. **Describir** el problema que resuelve
3. **Proponer** una solución específica
4. **Considerar** alternativas
5. **Discutir** en el issue antes de implementar

## Mejoras de Documentación

- Usa la plantilla de documentation issue
- Verifica que la información es precisa
- Incluye ejemplos cuando sea apropiado
- Mantén consistencia en el estilo

## 🌍 Ambientes y Testing

### Ambiente de Desarrollo

```bash
# Crear recursos de testing
az group create --name azure-agent-dev-test --location eastus

# Ejecutar deployment de prueba
az deployment group create \
 --resource-group azure-agent-dev-test \
 --template-file bicep/main.bicep \
 --parameters @bicep/parameters/dev.parameters.json
```

### Testing Local

```bash
# Validar todos los scripts
./scripts/test/validate-all-scripts.sh

# Validar plantillas Bicep
./scripts/test/validate-bicep-templates.sh

# Ejecutar tests de documentación
markdownlint "**/*.md" --ignore node_modules
```

### CI/CD Testing

- Todos los PRs ejecutan validación automática
- Los deployments a development son automáticos en merge a main
- Los deployments a otros ambientes requieren aprobación manual

## 🏷️ Labels y Project Management

### Labels para Issues
- `bug` - Errores confirmados
- `enhancement` - Nuevas funcionalidades
- `documentation` - Mejoras de documentación
- `azure` - Específico de Azure/infraestructura
- `scripts` - Related to bash scripts
- `bicep` - Related to Bicep templates
- `ci-cd` - Related to GitHub Actions
- `needs-triage` - Requiere revisión inicial
- `good-first-issue` - Bueno para nuevos contribuidores
- `help-wanted` - Se busca ayuda de la comunidad

### Priority Labels
- `priority-high` - Crítico, necesita atención inmediata
- `priority-medium` - Importante, pero no urgente
- `priority-low` - Nice to have

## 📞 Comunicación

- **Issues**: Para bugs, features y discusiones técnicas
- **Discussions**: Para preguntas generales y ideas
- **PR Comments**: Para feedback específico de código
- **Discord/Slack**: [Incluir si aplica]

## 📄 Código de Conducta

Este proyecto sigue el [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/). Al participar, se espera que mantengas este código.

## 🙏 Reconocimientos

¡Todos los contribuidores serán reconocidos! Las contribuciones se rastrean automáticamente y se muestran en el README.

---

¿Tienes preguntas? ¡Abre un issue o inicia una discusión! 
