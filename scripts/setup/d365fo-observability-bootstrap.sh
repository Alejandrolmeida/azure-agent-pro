#!/usr/bin/env bash
# Bootstrap for D365 F&O Observability notebook project

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OBS_ROOT="$PROJECT_ROOT/observability/d365-fo-observability"
CONDA_ENV_NAME="${CONDA_ENV_NAME:-aifoundry}"
PYTHON_VERSION="${PYTHON_VERSION:-3.11}"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_ok() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_err() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_conda() {
    if ! command -v conda >/dev/null 2>&1; then
        log_err "No se encontro conda. Instala Miniconda o Anaconda antes de continuar"
        exit 1
    fi
}

check_requirements() {
    log_info "Validando prerequisitos"
    check_conda

    if ! conda env list | awk '{print $1}' | grep -qx "$CONDA_ENV_NAME"; then
        log_warn "No existe el entorno conda '$CONDA_ENV_NAME'; se creara automaticamente"
    fi

    if ! command -v az >/dev/null 2>&1; then
        log_warn "Azure CLI no esta instalado. Instalalo antes de ejecutar consultas reales"
    fi
}

create_or_reuse_conda_env() {
    if conda env list | awk '{print $1}' | grep -qx "$CONDA_ENV_NAME"; then
        log_info "Usando entorno conda existente: $CONDA_ENV_NAME"
        return
    fi

    log_info "Creando entorno conda '$CONDA_ENV_NAME' con Python $PYTHON_VERSION"
    conda create -n "$CONDA_ENV_NAME" "python=$PYTHON_VERSION" -y
}

install_deps() {
    log_info "Instalando dependencias en conda:$CONDA_ENV_NAME"
    conda run -n "$CONDA_ENV_NAME" python -m pip install --upgrade pip
    conda run -n "$CONDA_ENV_NAME" python -m pip install -r "$OBS_ROOT/requirements.txt"
}

register_kernel() {
    local kernel_name="d365-fo-observability"
    local kernel_display="Python (conda:$CONDA_ENV_NAME) - D365 F&O Observability"

    log_info "Registrando kernel Jupyter"
    conda run -n "$CONDA_ENV_NAME" python -m ipykernel install --user --name "$kernel_name" --display-name "$kernel_display"
}

prepare_env() {
    if [[ ! -f "$OBS_ROOT/.env" ]]; then
        cp "$OBS_ROOT/.env.example" "$OBS_ROOT/.env"
        log_ok "Se creo .env desde .env.example"
        log_warn "Completa LAW_WORKSPACE_ID en $OBS_ROOT/.env"
    else
        log_info "Archivo .env ya existe; no se modifica"
    fi
}

summary() {
    cat <<EOF

Bootstrap completado.

Siguientes pasos:
1. Edita $OBS_ROOT/.env y define LAW_WORKSPACE_ID.
2. Ejecuta: az login
3. Abre VS Code en: $OBS_ROOT
4. Abre notebooks/d365_fo_observability.ipynb y selecciona el kernel "Python (conda:$CONDA_ENV_NAME) - D365 F&O Observability"
EOF
}

main() {
    if [[ ! -d "$OBS_ROOT" ]]; then
        log_err "No existe la carpeta de observabilidad: $OBS_ROOT"
        exit 1
    fi

    check_requirements
    create_or_reuse_conda_env
    install_deps
    register_kernel
    prepare_env
    summary
    log_ok "Entorno listo"
}

main "$@"
