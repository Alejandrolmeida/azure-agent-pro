#!/bin/bash
# ============================================
# Script: Detectar Transacciones Zombie
# Uso: ./detect-zombie-transactions.sh
# ============================================

set -euo pipefail

# Colores
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Query principal
QUERY='
SELECT 
    at.transaction_id,
    at.name AS TransactionName,
    at.transaction_begin_time AS StartTime,
    DATEDIFF(MINUTE, at.transaction_begin_time, GETUTCDATE()) AS DurationMinutes,
    DATEDIFF(HOUR, at.transaction_begin_time, GETUTCDATE()) AS DurationHours,
    DATEDIFF(DAY, at.transaction_begin_time, GETUTCDATE()) AS DurationDays,
    at.transaction_type AS TxType,
    at.transaction_state AS TxState,
    sess.session_id,
    sess.login_name,
    sess.host_name,
    sess.program_name
FROM sys.dm_tran_active_transactions at
LEFT JOIN sys.dm_tran_session_transactions st ON at.transaction_id = st.transaction_id
LEFT JOIN sys.dm_exec_sessions sess ON st.session_id = sess.session_id
WHERE at.transaction_begin_time < DATEADD(MINUTE, -5, GETUTCDATE())
ORDER BY at.transaction_begin_time;
'

# Verificar credenciales
if [[ -z "${AZURE_SQL_SERVER:-}" ]] || [[ -z "${AZURE_SQL_DATABASE:-}" ]]; then
    echo -e "${RED}❌ Error: Variables de entorno no configuradas${NC}"
    echo ""
    echo "Configura las siguientes variables:"
    echo "  export AZURE_SQL_SERVER='your-server.database.windows.net'"
    echo "  export AZURE_SQL_DATABASE='your-database'"
    echo "  export AZURE_SQL_USERNAME='your-username'"
    echo "  export AZURE_SQL_PASSWORD='your-password'"
    echo ""
    exit 1
fi

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Detección de Transacciones Zombie${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""
echo -e "Servidor: ${GREEN}${AZURE_SQL_SERVER}${NC}"
echo -e "Base de datos: ${GREEN}${AZURE_SQL_DATABASE}${NC}"
echo ""

# Ejecutar query
echo -e "${YELLOW}🔍 Buscando transacciones activas >5 minutos...${NC}"
echo ""

python3 "$PROJECT_ROOT/scripts/utils/sql-query.py" \
    -s "$AZURE_SQL_SERVER" \
    -d "$AZURE_SQL_DATABASE" \
    -u "${AZURE_SQL_USERNAME:-}" \
    -p "${AZURE_SQL_PASSWORD:-}" \
    -q "$QUERY" \
    -o table

RESULT=$?

echo ""
if [[ $RESULT -eq 0 ]]; then
    echo -e "${GREEN}✅ Query ejecutada correctamente${NC}"
    echo ""
    echo -e "${YELLOW}INTERPRETACIÓN DE RESULTADOS:${NC}"
    echo "  • session_id = NULL → 🚨 ZOMBIE (huérfana)"
    echo "  • DurationDays > 7 → 🔴 CRÍTICO (requiere failover)"
    echo "  • DurationDays > 1 → 🟡 URGENTE (investigar)"
    echo "  • TxType = 2 → Read-Only (menor impacto)"
    echo "  • TxState = 2 → Activa (bloqueando recursos)"
    echo ""
    echo -e "${BLUE}Para más análisis, consulta:${NC}"
    echo "  $PROJECT_ROOT/docs/queries/detect-zombie-transactions.sql"
else
    echo -e "${RED}❌ Error al ejecutar query${NC}"
    exit 1
fi

# Query adicional: impacto en espacio
echo ""
echo -e "${YELLOW}📊 Analizando impacto en espacio...${NC}"
echo ""

SPACE_QUERY='
SELECT 
    DB_NAME() AS DatabaseName,
    CAST(SUM(unallocated_extent_page_count) * 8.0 / 1024 / 1024 AS DECIMAL(10,2)) AS UnallocatedSpaceGB,
    (SELECT COUNT(*) 
     FROM sys.dm_tran_active_transactions 
     WHERE transaction_begin_time < DATEADD(HOUR, -1, GETUTCDATE())) AS ZombieTransactions
FROM sys.dm_db_file_space_usage;
'

python3 "$PROJECT_ROOT/scripts/utils/sql-query.py" \
    -s "$AZURE_SQL_SERVER" \
    -d "$AZURE_SQL_DATABASE" \
    -u "${AZURE_SQL_USERNAME:-}" \
    -p "${AZURE_SQL_PASSWORD:-}" \
    -q "$SPACE_QUERY" \
    -o table

echo ""
echo -e "${YELLOW}DIAGNÓSTICO:${NC}"
echo "  • UnallocatedSpaceGB > 500 GB → 🔴 Problema crítico"
echo "  • UnallocatedSpaceGB > 100 GB → 🟡 Requiere atención"
echo "  • ZombieTransactions > 0 → ⚠️  Limpieza bloqueada"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Análisis completado${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
