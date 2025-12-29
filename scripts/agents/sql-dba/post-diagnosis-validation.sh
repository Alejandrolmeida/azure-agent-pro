#!/bin/bash
# post-diagnosis-validation.sh
# Auto-validación después de dar diagnóstico
# Asegura que el diagnóstico está respaldado por evidencia completa

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Recibir diagnóstico como argumento
DIAGNOSIS="${1:-Unknown}"

echo -e "${BLUE}🔬 AUTO-VALIDACIÓN DE DIAGNÓSTICO${NC}"
echo "================================="
echo ""
echo -e "${YELLOW}Diagnóstico dado:${NC} $DIAGNOSIS"
echo ""

# ============================================================================
# Checklist de validación
# ============================================================================

echo -e "${BLUE}📋 CHECKLIST DE VALIDACIÓN (marcar cada item):${NC}"
echo ""

echo "1️⃣  ${GREEN}Recopilación de Datos${NC}"
echo "   [ ] sys.dm_os_sys_info (SQL Server uptime)"
echo "   [ ] sys.dm_tran_active_transactions (transacciones viejas)"
echo "   [ ] Correlación temporal (restart vs transaction begin)"
echo "   [ ] sys.dm_exec_sessions (session ownership)"
echo "   [ ] sys.dm_tran_persistent_version_store_stats (PVS status)"
echo "   [ ] Proporción PVS vs duración esperada"
echo ""

echo "2️⃣  ${GREEN}Evidencia de Causalidad${NC}"
echo "   [ ] Tengo evidencia DIRECTA (no solo correlación temporal)"
echo "   [ ] Puedo explicar el mecanismo de causa → efecto"
echo "   [ ] Los datos confirman la hipótesis de manera inequívoca"
echo ""

echo "3️⃣  ${GREEN}Hipótesis Alternativas${NC}"
echo "   [ ] Consideré: System/Recovery transactions"
echo "   [ ] Consideré: Cleanup lento pero funcional"
echo "   [ ] Consideré: Crecimiento normal de workload activo"
echo "   [ ] Consideré: Comportamiento específico de Azure SQL"
echo "   [ ] Puedo explicar por qué cada alternativa NO aplica"
echo ""

echo "4️⃣  ${GREEN}Contexto de Plataforma${NC}"
echo "   [ ] Verifiqué si es Azure SQL Database o SQL Server on-prem"
echo "   [ ] Consideré reinicios automáticos de mantenimiento Azure"
echo "   [ ] Consideré transacciones internas específicas de la plataforma"
echo "   [ ] Revisé documentación oficial de Microsoft sobre el comportamiento"
echo ""

echo "5️⃣  ${GREEN}Checklist Específico del Problema${NC}"
if [[ "$DIAGNOSIS" == *"zombie"* ]] || [[ "$DIAGNOSIS" == *"Zombie"* ]]; then
    echo "   ${YELLOW}(Diagnóstico de Zombie Transactions)${NC}"
    echo "   [ ] Ejecuté: pre-diagnosis-zombie-validation.sh"
    echo "   [ ] Confirmé: session_id ≠ NULL"
    echo "   [ ] Confirmé: current_aborted_transaction_count > 0"
    echo "   [ ] Confirmé: pvs_ratio > 0.5"
    echo "   [ ] Confirmé: Transacción NO inició post-restart inmediato"
elif [[ "$DIAGNOSIS" == *"blocking"* ]] || [[ "$DIAGNOSIS" == *"Blocking"* ]]; then
    echo "   ${YELLOW}(Diagnóstico de Blocking)${NC}"
    echo "   [ ] Identifiqué blocker root (head of blocking chain)"
    echo "   [ ] Verifiqué query del blocker"
    echo "   [ ] Calculé duración del bloqueo"
    echo "   [ ] Conté sesiones impactadas"
elif [[ "$DIAGNOSIS" == *"performance"* ]] || [[ "$DIAGNOSIS" == *"Performance"* ]]; then
    echo "   ${YELLOW}(Diagnóstico de Performance)${NC}"
    echo "   [ ] Ejecuté wait stats analysis"
    echo "   [ ] Identifiqué top queries por CPU/IO"
    echo "   [ ] Revisé índices faltantes/sin usar"
    echo "   [ ] Revisé Query Store para regresiones"
else
    echo "   ${YELLOW}(Diagnóstico General)${NC}"
    echo "   [ ] Ejecuté queries diagnósticas relevantes"
    echo "   [ ] Capturé métricas antes/durante el problema"
    echo "   [ ] Verifiqué timeline de eventos"
fi
echo ""

# ============================================================================
# Preguntas críticas
# ============================================================================

echo -e "${RED}🚨 PREGUNTAS CRÍTICAS (responder honestamente):${NC}"
echo ""

echo "Q1: ¿Ejecuté TODAS las queries del checklist?"
echo "    → Si NO: Ejecutar ahora antes de comunicar diagnóstico"
echo ""

echo "Q2: ¿Tengo EVIDENCIA DIRECTA de causalidad?"
echo "    → Si NO: Marcar como 'hipótesis que requiere validación'"
echo ""

echo "Q3: ¿Consideré al menos 3 hipótesis alternativas?"
echo "    → Si NO: Listar alternativas y descartarlas con evidencia"
echo ""

echo "Q4: ¿Puedo explicar por qué las alternativas NO aplican?"
echo "    → Si NO: Investigar más antes de descartar"
echo ""

echo "Q5: ¿El diagnóstico considera la plataforma específica?"
echo "    → Azure SQL ≠ SQL Server on-prem"
echo "    → Si NO: Revisar documentación de Azure SQL"
echo ""

echo "Q6: Si hay duda, ¿la comuniqué claramente?"
echo "    → Mejor: 'Hipótesis que requiere validación adicional'"
echo "    → Peor: Presentar como diagnóstico definitivo"
echo ""

# ============================================================================
# Red Flags
# ============================================================================

echo -e "${YELLOW}⚠️  RED FLAGS de Diagnóstico Prematuro:${NC}"
echo ""
echo "  🚩 Falta contexto temporal (uptime, restart history)"
echo "  🚩 Solo tengo correlación, no causalidad"
echo "  🚩 No descarté alternativas obvias"
echo "  🚩 Patrón parece conocido pero contexto es diferente"
echo "  🚩 No ejecuté checklist específico del problema"
echo "  🚩 Asumí comportamiento sin consultar documentación"
echo ""

# ============================================================================
# Decisión final
# ============================================================================

echo -e "${GREEN}✅ DECISIÓN FINAL:${NC}"
echo "================"
echo ""
echo "Si TODOS los checkpoints están marcados → COMUNICAR diagnóstico"
echo "Si ALGÚN checkpoint falta → INVESTIGAR más antes de comunicar"
echo "Si HAY DUDA → Marcar como 'hipótesis' y solicitar validación"
echo ""
echo -e "${BLUE}Recuerda: ${NC}"
echo "  ✓ Mejor decir 'necesito más datos' que dar diagnóstico incorrecto"
echo "  ✓ Las correcciones externas son valiosas (Microsoft, comunidad)"
echo "  ✓ La metodología evidence-first protege credibilidad profesional"
echo ""
echo "================================="
