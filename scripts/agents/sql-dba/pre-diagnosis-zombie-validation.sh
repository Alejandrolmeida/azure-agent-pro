#!/bin/bash
# pre-diagnosis-zombie-validation.sh
# Checklist de validación OBLIGATORIO antes de diagnosticar "zombie transactions"
#
# Uso:
#   ./pre-diagnosis-zombie-validation.sh -s <server> -d <database> [-u <user> -p <password>]
#
# Ejecuta 5 checkpoints críticos para determinar si transacciones viejas son:
#   - Zombie transactions (usuario desconectado) → REQUIERE ACCIÓN
#   - System transactions (normal post-restart) → NO ACCIÓN

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
SERVER=""
DATABASE=""
USER=""
PASSWORD=""
AUTH_TYPE="aad"

# Función de ayuda
usage() {
    echo "Uso: $0 -s <server> -d <database> [-u <user> -p <password>]"
    echo ""
    echo "Opciones:"
    echo "  -s    Server (ej: myserver.database.windows.net)"
    echo "  -d    Database name"
    echo "  -u    Username (opcional, usa Azure AD si no se proporciona)"
    echo "  -p    Password (opcional, usa Azure AD si no se proporciona)"
    echo ""
    exit 1
}

# Parsear argumentos
while getopts "s:d:u:p:h" opt; do
    case $opt in
        s) SERVER="$OPTARG" ;;
        d) DATABASE="$OPTARG" ;;
        u) USER="$OPTARG" ;;
        p) PASSWORD="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Validar argumentos requeridos
if [[ -z "$SERVER" || -z "$DATABASE" ]]; then
    echo -e "${RED}❌ Error: Server y Database son requeridos${NC}"
    usage
fi

# Determinar tipo de autenticación
if [[ -n "$USER" && -n "$PASSWORD" ]]; then
    AUTH_TYPE="sql"
fi

# Función para ejecutar query
run_query() {
    local query="$1"
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    if [[ "$AUTH_TYPE" == "aad" ]]; then
        python3 "$script_dir/sql-query.py" \
            -s "$SERVER" \
            -d "$DATABASE" \
            --aad \
            -q "$query" \
            -o table
    else
        python3 "$script_dir/sql-query.py" \
            -s "$SERVER" \
            -d "$DATABASE" \
            --sql-auth \
            -u "$USER" \
            -p "$PASSWORD" \
            -q "$query" \
            -o table
    fi
}

echo -e "${BLUE}🔍 VALIDACIÓN DE DIAGNÓSTICO: ZOMBIE TRANSACTIONS${NC}"
echo "=================================================="
echo "Server: $SERVER"
echo "Database: $DATABASE"
echo "Auth: $AUTH_TYPE"
echo ""

# ============================================================================
# CHECKPOINT 1: SQL Server uptime
# ============================================================================
echo -e "${YELLOW}1️⃣  CHECKPOINT 1: SQL Server Uptime${NC}"
echo "-----------------------------------"

QUERY1="SELECT 
    sqlserver_start_time,
    DATEDIFF(DAY, sqlserver_start_time, GETUTCDATE()) AS uptime_days,
    DATEDIFF(HOUR, sqlserver_start_time, GETUTCDATE()) AS uptime_hours,
    DATEDIFF(MINUTE, sqlserver_start_time, GETUTCDATE()) AS uptime_minutes
FROM sys.dm_os_sys_info"

run_query "$QUERY1"
echo ""

# ============================================================================
# CHECKPOINT 2: Correlación temporal
# ============================================================================
echo -e "${YELLOW}2️⃣  CHECKPOINT 2: Correlación Temporal (Transacciones vs Restart)${NC}"
echo "----------------------------------------------------------------"

QUERY2="SELECT 
    (SELECT sqlserver_start_time FROM sys.dm_os_sys_info) AS server_start_time,
    MIN(at.transaction_begin_time) AS oldest_transaction_start,
    DATEDIFF(MINUTE, 
        (SELECT sqlserver_start_time FROM sys.dm_os_sys_info),
        MIN(at.transaction_begin_time)) AS minutes_after_restart,
    COUNT(*) AS old_transaction_count
FROM sys.dm_tran_active_transactions at
WHERE at.transaction_begin_time < DATEADD(DAY, -1, GETUTCDATE())"

run_query "$QUERY2"
echo ""

echo -e "${BLUE}📝 Interpretación:${NC}"
echo "   - Si minutes_after_restart < 10 → Transacciones de RECOVERY/SISTEMA"
echo "   - Si minutes_after_restart > 60 → Investigar más (posible zombie)"
echo ""

# ============================================================================
# CHECKPOINT 3: Session ownership
# ============================================================================
echo -e "${YELLOW}3️⃣  CHECKPOINT 3: Session Ownership (Usuario vs Sistema)${NC}"
echo "-------------------------------------------------------"

QUERY3="SELECT 
    at.transaction_id,
    at.name AS transaction_name,
    at.transaction_begin_time,
    DATEDIFF(DAY, at.transaction_begin_time, GETUTCDATE()) AS age_days,
    at.transaction_type,
    CASE at.transaction_type
        WHEN 1 THEN 'Read/write'
        WHEN 2 THEN 'Read-only'
        WHEN 3 THEN 'System'
        WHEN 4 THEN 'Distributed'
    END AS transaction_type_desc,
    at.transaction_state,
    CASE WHEN st.session_id IS NULL THEN 'SYSTEM (NULL)' ELSE CAST(st.session_id AS VARCHAR) END AS session_id,
    ISNULL(es.login_name, 'N/A') AS login_name,
    ISNULL(es.host_name, 'N/A') AS host_name,
    ISNULL(es.program_name, 'N/A') AS program_name
FROM sys.dm_tran_active_transactions at
LEFT JOIN sys.dm_tran_session_transactions st ON at.transaction_id = st.transaction_id
LEFT JOIN sys.dm_exec_sessions es ON st.session_id = es.session_id
WHERE at.transaction_begin_time < DATEADD(DAY, -1, GETUTCDATE())
ORDER BY at.transaction_begin_time"

run_query "$QUERY3"
echo ""

echo -e "${BLUE}📝 Interpretación:${NC}"
echo "   - session_id = 'SYSTEM (NULL)' → Transacción INTERNA (NO zombie)"
echo "   - session_id > 0 + login_name → Transacción de USUARIO (investigar)"
echo ""

# ============================================================================
# CHECKPOINT 4: PVS Stats (Aborted transactions)
# ============================================================================
echo -e "${YELLOW}4️⃣  CHECKPOINT 4: PVS Statistics (Bloqueadores Reales)${NC}"
echo "----------------------------------------------------"

QUERY4="SELECT 
    database_id,
    persistent_version_store_size_kb,
    CAST(persistent_version_store_size_kb / 1024.0 / 1024.0 AS DECIMAL(10,2)) AS pvs_gb,
    current_aborted_transaction_count,
    aborted_version_cleaner_start_time,
    aborted_version_cleaner_end_time,
    oldest_aborted_transaction_begin_time,
    CASE 
        WHEN oldest_aborted_transaction_begin_time IS NOT NULL 
        THEN DATEDIFF(MINUTE, oldest_aborted_transaction_begin_time, GETUTCDATE())
        ELSE NULL
    END AS oldest_aborted_age_minutes
FROM sys.dm_tran_persistent_version_store_stats
WHERE database_id = DB_ID()"

run_query "$QUERY4"
echo ""

echo -e "${BLUE}📝 Interpretación:${NC}"
echo "   - current_aborted_transaction_count = 0 → NO hay zombies bloqueando PVS"
echo "   - current_aborted_transaction_count > 0 → SÍ hay bloqueadores"
echo "   - pvs_gb alto + aborted_count = 0 → Cleanup lento pero funcional"
echo ""

# ============================================================================
# CHECKPOINT 5: Proporción PVS vs Duración
# ============================================================================
echo -e "${YELLOW}5️⃣  CHECKPOINT 5: Proporción PVS vs Duración Esperada${NC}"
echo "---------------------------------------------------"

QUERY5="WITH TransactionAge AS (
    SELECT 
        DATEDIFF(DAY, MIN(transaction_begin_time), GETUTCDATE()) AS oldest_transaction_days
    FROM sys.dm_tran_active_transactions
    WHERE transaction_begin_time < DATEADD(DAY, -1, GETUTCDATE())
),
PVSSize AS (
    SELECT 
        CAST(SUM(persistent_version_store_size_kb) / 1024.0 / 1024.0 AS DECIMAL(10,2)) AS pvs_gb
    FROM sys.dm_tran_persistent_version_store_stats
    WHERE database_id = DB_ID()
)
SELECT 
    ta.oldest_transaction_days,
    ps.pvs_gb AS current_pvs_gb,
    -- Asumiendo crecimiento típico de 150 GB/día cuando hay problema
    CAST(ta.oldest_transaction_days * 150 AS DECIMAL(10,2)) AS expected_pvs_if_blocked_gb,
    -- Ratio: si <0.1 (10%) entonces cleanup funciona, si >0.5 (50%) está bloqueado
    CAST(ps.pvs_gb / NULLIF((ta.oldest_transaction_days * 150), 0) AS DECIMAL(10,4)) AS pvs_ratio
FROM TransactionAge ta, PVSSize ps"

run_query "$QUERY5"
echo ""

echo -e "${BLUE}📝 Interpretación:${NC}"
echo "   - pvs_ratio < 0.1 (10%) → Cleanup funciona, NO está bloqueado"
echo "   - pvs_ratio 0.1-0.5 → Cleanup lento pero parcialmente funcional"
echo "   - pvs_ratio > 0.5 (50%) → Cleanup BLOQUEADO, investigar causa"
echo ""

# ============================================================================
# DECISIÓN DIAGNÓSTICA
# ============================================================================
echo -e "${GREEN}✅ VALIDACIÓN COMPLETA${NC}"
echo "======================================"
echo ""
echo -e "${BLUE}📋 DECISIÓN DIAGNÓSTICA:${NC}"
echo ""
echo -e "${GREEN}✓ Zombie Transactions → SÍ, si:${NC}"
echo "  - session_id ≠ NULL (número específico)"
echo "  - login_name = usuario aplicación (no 'sa' o 'system')"
echo "  - Inicio >> restart (ej: horas/días DESPUÉS del restart, o ANTES del último restart)"
echo "  - current_aborted_transaction_count > 0"
echo "  - pvs_ratio > 0.5 (PVS proporcional a duración)"
echo ""
echo -e "${YELLOW}⚠️  System/Recovery Transactions → SÍ, si:${NC}"
echo "  - session_id = NULL (SYSTEM)"
echo "  - Inicio ≈ restart (< 10 minutos después)"
echo "  - current_aborted_transaction_count = 0"
echo "  - pvs_ratio < 0.1 (PVS pequeño comparado con duración)"
echo ""
echo -e "${RED}🚨 CRÍTICO: NO diagnosticar zombie sin cumplir TODOS los criterios${NC}"
echo ""
echo "Próximos pasos:"
echo "  1. Si criterios de zombie: Solicitar aprobación para KILL"
echo "  2. Si criterios de sistema: Informar que es comportamiento normal"
echo "  3. Si ambiguo: Ejecutar monitoreo adicional (1-24 horas)"
echo ""
echo "======================================"
