#!/bin/bash

# Azure Agent Pro - GitHub Repository Setup Script
# Este script automatiza la creación y configuración del repositorio Azure Agent Pro

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables del proyecto
PROJECT_NAME="azure-agent-pro"
GITHUB_USERNAME="alejandrolmeida"
PROJECT_DESCRIPTION="🤖 Educational research project teaching GitHub Copilot enhanced Azure professional management"
PROJECT_DIR="/home/alejandrolmeida/source/github/alejandrolmeida/azure-agent"

# Función para logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Verificar prerrequisitos
check_prerequisites() {
    log "Verificando prerrequisitos..."
    
    # Verificar Git
    if ! command -v git &> /dev/null; then
        error "Git no está instalado. Por favor instala Git primero."
        exit 1
    fi
    
    # Verificar GitHub CLI
    if ! command -v gh &> /dev/null; then
        error "GitHub CLI no está instalado. Instalando..."
        
        # Detectar distribución e instalar GitHub CLI
        if command -v apt &> /dev/null; then
            sudo apt update
            sudo apt install -y gh
        elif command -v yum &> /dev/null; then
            sudo yum install -y gh
        elif command -v brew &> /dev/null; then
            brew install gh
        else
            error "No se puede instalar GitHub CLI automáticamente. Por favor instálalo manualmente: https://cli.github.com/"
            exit 1
        fi
    fi
    
    # Verificar autenticación con GitHub
    if ! gh auth status &> /dev/null; then
        warning "No estás autenticado con GitHub CLI."
        info "Ejecutando: gh auth login"
        gh auth login
    fi
    
    log "✅ Prerrequisitos verificados correctamente"
}

# Inicializar repositorio Git local
init_local_repository() {
    log "Inicializando repositorio Git local..."
    
    cd "$PROJECT_DIR"
    
    # Inicializar Git si no existe
    if [ ! -d ".git" ]; then
        git init
        log "✅ Repositorio Git inicializado"
    else
        log "✅ Repositorio Git ya existe"
    fi
    
    # Configurar rama principal como 'main'
    git branch -M main
    
    # Añadir todos los archivos
    git add .
    
    # Crear commit inicial si es necesario
    if ! git rev-parse --verify HEAD &> /dev/null; then
        git commit -m "🚀 Initial commit: Azure Agent Pro Educational Research Project

- Complete project structure with educational content
- GitHub Copilot integration guides and chat modes
- Bicep templates with enterprise patterns
- CI/CD workflows with security scanning
- Comprehensive learning paths for all skill levels
- Documentation and tutorials for professional Azure management

Ready for educational community collaboration! 🎓"
        log "✅ Commit inicial creado"
    else
        # Commit de los cambios actuales si hay modificaciones
        if ! git diff --staged --quiet; then
            git commit -m "📝 Update: Clean up documentation and prepare for GitHub publication

- Fixed duplicate content in markdown files
- Added cross-references between documents
- Optimized project structure
- Ready for public release"
            log "✅ Cambios actuales commiteados"
        else
            log "✅ No hay cambios para commitear"
        fi
    fi
}

# Crear repositorio en GitHub
create_github_repository() {
    log "Creando repositorio en GitHub..."
    
    # Verificar si el repositorio ya existe
    if gh repo view "$GITHUB_USERNAME/$PROJECT_NAME" &> /dev/null; then
        warning "El repositorio $GITHUB_USERNAME/$PROJECT_NAME ya existe"
        read -p "¿Quieres continuar y actualizar la configuración? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            error "Operación cancelada por el usuario"
            exit 1
        fi
    else
        # Crear el repositorio
        gh repo create "$PROJECT_NAME" \
            --description "$PROJECT_DESCRIPTION" \
            --public \
            --source=. \
            --remote=origin \
            --push
        
        log "✅ Repositorio $PROJECT_NAME creado en GitHub"
    fi
    
    # Configurar remote origin si no existe
    if ! git remote get-url origin &> /dev/null; then
        git remote add origin "https://github.com/$GITHUB_USERNAME/$PROJECT_NAME.git"
        log "✅ Remote origin configurado"
    fi
}

# Configurar características del repositorio
configure_repository_features() {
    log "Configurando características del repositorio..."
    
    # Habilitar características básicas
    gh repo edit "$GITHUB_USERNAME/$PROJECT_NAME" \
        --enable-issues \
        --enable-wiki \
        --enable-discussions \
        --enable-projects
    
    log "✅ Características básicas habilitadas (Issues, Wiki, Discussions, Projects)"
    
    # Configurar temas/topics
    local topics="azure github-copilot bicep infrastructure-as-code devops azure-cli automation ci-cd educational-project research-project cloud-computing azure-resource-manager github-actions professional-development learning-resources open-source-education enterprise-patterns security-best-practices cost-optimization azure-governance artificial-intelligence tutorial learning"
    
    gh repo edit "$GITHUB_USERNAME/$PROJECT_NAME" --add-topic "$topics"
    log "✅ Topics/tags configurados"
}

# Configurar branch protection
setup_branch_protection() {
    log "Configurando protección de la rama main..."
    
    # Esperar un momento para asegurar que el repositorio esté completamente configurado
    sleep 2
    
    # Configurar branch protection rules
    gh api repos/"$GITHUB_USERNAME"/"$PROJECT_NAME"/branches/main/protection \
        --method PUT \
        --field required_status_checks='{"strict":true,"contexts":["Bicep Validation","Code Quality","Security Scan"]}' \
        --field enforce_admins=true \
        --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true,"require_code_owner_reviews":true}' \
        --field restrictions=null \
        --field allow_force_pushes=false \
        --field allow_deletions=false \
        2>/dev/null || warning "No se pudo configurar branch protection (puede requerir workflows activos)"
    
    log "✅ Reglas de protección de rama configuradas"
}

# Crear labels personalizados
create_custom_labels() {
    log "Creando labels personalizados..."
    
    # Array de labels (nombre:color:descripción)
    local labels=(
        "tutorial:7057ff:Tutorial content"
        "learning-path:e99695:Learning path content"
        "bicep:fbca04:Bicep template related"
        "security:b60205:Security-related issue"
        "cost-optimization:f9d0c4:Cost optimization"
        "github-copilot:5319e7:GitHub Copilot related"
        "level-beginner:c2e0c6:Beginner level content"
        "level-intermediate:ffeaa7:Intermediate level content"
        "level-expert:ffb3ba:Expert level content"
        "priority-high:d93f0b:High priority"
        "priority-medium:fbca04:Medium priority"
        "priority-low:0e8a16:Low priority"
        "status-in-progress:fef2c0:Currently being worked on"
        "status-blocked:d4c5f9:Blocked by dependencies"
        "status-review:c2e0c6:Ready for review"
        "status-needs-info:ffeaa7:Needs more information"
    )
    
    for label in "${labels[@]}"; do
        IFS=':' read -r name color description <<< "$label"
        gh label create "$name" --color "$color" --description "$description" --repo "$GITHUB_USERNAME/$PROJECT_NAME" 2>/dev/null || true
    done
    
    log "✅ Labels personalizados creados"
}

# Crear discussion categories
setup_discussions() {
    log "Configurando categorías de discusión..."
    
    # Note: GitHub CLI no tiene comando directo para crear categorías de discusión
    # Estas se deben crear manualmente en la interfaz web
    info "📋 Categorías de discusión para crear manualmente en GitHub:"
    info "   🎓 Learning & Education (Q&A)"
    info "   💡 Ideas & Suggestions (Ideas)"
    info "   🛠️ Implementation Help (Q&A)"
    info "   📢 Announcements (Announcement)"
    info "   🤝 General Discussion (General)"
    info "   🔧 Technical Deep Dive (General)"
    
    info "👆 Estas categorías se pueden crear en: https://github.com/$GITHUB_USERNAME/$PROJECT_NAME/discussions"
}

# Push final y verificación
final_push_and_verify() {
    log "Realizando push final y verificación..."
    
    # Push de todos los cambios
    git push -u origin main
    log "✅ Código subido a GitHub"
    
    # Verificar que todo esté correcto
    if gh repo view "$GITHUB_USERNAME/$PROJECT_NAME" &> /dev/null; then
        log "✅ Repositorio verificado exitosamente"
        info "🌍 Repositorio disponible en: https://github.com/$GITHUB_USERNAME/$PROJECT_NAME"
    else
        error "❌ Error al verificar el repositorio"
        exit 1
    fi
}

# Mostrar resumen final
show_summary() {
    echo
    echo "🎉 ¡Azure Agent Pro configurado exitosamente!"
    echo "=================================================="
    echo
    echo "📍 Repositorio: https://github.com/$GITHUB_USERNAME/$PROJECT_NAME"
    echo "📊 Dashboard: https://github.com/$GITHUB_USERNAME/$PROJECT_NAME/pulse"
    echo "💬 Discussions: https://github.com/$GITHUB_USERNAME/$PROJECT_NAME/discussions"
    echo "📝 Issues: https://github.com/$GITHUB_USERNAME/$PROJECT_NAME/issues"
    echo "📚 Wiki: https://github.com/$GITHUB_USERNAME/$PROJECT_NAME/wiki"
    echo
    echo "📋 Próximos pasos manuales:"
    echo "1. Configurar categorías de discusión"
    echo "2. Revisar y ajustar branch protection rules"
    echo "3. Crear primer proyecto en Projects tab"
    echo "4. Activar GitHub Pages si es necesario"
    echo "5. Configurar secrets para Azure en Settings > Secrets"
    echo
    echo "🚀 ¡Tu proyecto educativo está listo para la comunidad!"
}

# Función principal
main() {
    echo "🚀 Iniciando configuración de Azure Agent Pro"
    echo "=============================================="
    
    check_prerequisites
    init_local_repository
    create_github_repository
    configure_repository_features
    setup_branch_protection
    create_custom_labels
    setup_discussions
    final_push_and_verify
    show_summary
}

# Ejecutar función principal con manejo de errores
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    trap 'error "Script interrumpido. Revisa los logs anteriores."' ERR
    main "$@"
fi