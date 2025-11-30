#!/bin/bash
# ============================================================================
# Script de Inicialización del Proyecto Hackathon
# ============================================================================
# BiciMAD Low Emission Router - DataSaturday Madrid 2025
# Este script completa la estructura del proyecto creando todos los archivos
# necesarios que aún no existen
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 Inicializando proyecto BiciMAD Low Emission Router..."
echo "📂 Directorio del proyecto: $PROJECT_ROOT"

# ============================================================================
# Colores para output
# ============================================================================
GREEN='\033[0.32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Función helper para crear archivos
# ============================================================================
create_file_if_not_exists() {
    local file_path="$1"
    local content="$2"
    
    if [ ! -f "$file_path" ]; then
        echo -e "${BLUE}📝 Creando: $file_path${NC}"
        echo "$content" > "$file_path"
    else
        echo -e "${YELLOW}⏭️  Ya existe: $file_path${NC}"
    fi
}

# ============================================================================
# Crear .gitignore
# ============================================================================
echo -e "\n${GREEN}## Creando .gitignore${NC}"
create_file_if_not_exists "$PROJECT_ROOT/.gitignore" "# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual environments
venv/
ENV/
env/
.venv

# Azure Functions
local.settings.json
__blobstorage__/
__queuestorage__/
__azurite_db*__.json
.python_packages/

# IDEs
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Environment variables
.env
.env.local

# Build outputs
dist/
build/
*.zip

# Azure
*.publishsettings
.azure/

# Node
node_modules/
package-lock.json
yarn.lock
"

# ============================================================================
# Crear archivos restantes del frontend
# ============================================================================
echo -e "\n${GREEN}## Creando archivos CSS${NC}"
mkdir -p "$PROJECT_ROOT/src/frontend/css"
create_file_if_not_exists "$PROJECT_ROOT/src/frontend/css/styles.css" "/* CSS TO BE CREATED */
/* Ver issue o crear manualmente */"

echo -e "\n${GREEN}## Creando archivos JavaScript${NC}"
mkdir -p "$PROJECT_ROOT/src/frontend/js"

create_file_if_not_exists "$PROJECT_ROOT/src/frontend/js/app.js" "// App initialization
// TO BE IMPLEMENTED"

create_file_if_not_exists "$PROJECT_ROOT/src/frontend/js/map.js" "// Map management with Leaflet
// TO BE IMPLEMENTED"

create_file_if_not_exists "$PROJECT_ROOT/src/frontend/js/api-client.js" "// API client for backend
// TO BE IMPLEMENTED"

create_file_if_not_exists "$PROJECT_ROOT/src/frontend/js/ui-controller.js" "// UI Controller
// TO BE IMPLEMENTED"

create_file_if_not_exists "$PROJECT_ROOT/src/frontend/staticwebapp.config.json" '{
  "routes": [],
  "navigationFallback": {
    "rewrite": "/index.html"
  },
  "responseOverrides": {
    "404": {
      "rewrite": "/index.html"
    }
  },
  "globalHeaders": {
    "content-security-policy": "default-src https: '\''unsafe-eval'\'' '\''unsafe-inline'\''; object-src '\''none'\''"
  },
  "mimeTypes": {
    ".json": "application/json"
  }
}'

# ============================================================================
# Crear módulos utils del backend
# ============================================================================
echo -e "\n${GREEN}## Creando módulos utils del backend${NC}"
mkdir -p "$PROJECT_ROOT/src/api/utils"

create_file_if_not_exists "$PROJECT_ROOT/src/api/utils/__init__.py" "# Utils package"

create_file_if_not_exists "$PROJECT_ROOT/src/api/utils/data_providers.py" "\"\"\"
Data Providers Module
Clientes para APIs externas
\"\"\"
# TO BE IMPLEMENTED"

create_file_if_not_exists "$PROJECT_ROOT/src/api/utils/scoring_engine.py" "\"\"\"
Scoring Engine Module
Algoritmo de cálculo de score de emisiones
\"\"\"
# TO BE IMPLEMENTED"

create_file_if_not_exists "$PROJECT_ROOT/src/api/utils/cache_manager.py" "\"\"\"
Cache Manager Module
Gestión de cache en Azure Blob Storage
\"\"\"
# TO BE IMPLEMENTED"

# ============================================================================
# Crear documentación
# ============================================================================
echo -e "\n${GREEN}## Creando documentación${NC}"
mkdir -p "$PROJECT_ROOT/docs"

create_file_if_not_exists "$PROJECT_ROOT/docs/ARCHITECTURE.md" "# Arquitectura del Sistema
TO BE DOCUMENTED"

create_file_if_not_exists "$PROJECT_ROOT/docs/API.md" "# Documentación de API
TO BE DOCUMENTED"

create_file_if_not_exists "$PROJECT_ROOT/docs/DEPLOYMENT.md" "# Guía de Despliegue
TO BE DOCUMENTED"

echo -e "\n${GREEN}✅ Inicialización completada!${NC}"
echo -e "${YELLOW}📋 Revisa los archivos marcados como 'TO BE IMPLEMENTED'${NC}"
echo -e "${YELLOW}📋 Completa la implementación según la documentación del proyecto${NC}"
