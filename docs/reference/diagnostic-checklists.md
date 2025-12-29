# Diagnostic Checklists - Azure SQL DBA

Checklists de validación obligatorios antes de comunicar diagnósticos definitivos.

## Propósito

Estos checklists aseguran que los diagnósticos están respaldados por evidencia completa y consideran contexto de plataforma, evitando errores de interpretación que puedan dañar credibilidad profesional.

---

## 🚨 Protocolo General de Validación

### Pre-Diagnóstico (OBLIGATORIO)

Antes de comunicar CUALQUIER diagnóstico de causa raíz:

1. **Recopilación de datos**: ✅ Completa
2. **Correlación temporal**: ✅ Verificada
3. **Contexto de plataforma**: ✅ Considerado (Azure SQL vs on-prem)
4. **Hipótesis alternativas**: ✅ Listadas y descartadas con evidencia
5. **Causalidad directa**: ✅ Demostrada (no solo correlación)
6. **Checklist específico del tipo**: ✅ Ejecutado

### Red Flags de Diagnóstico Prematuro

⚠️ **NO comunicar diagnóstico si:**
- Falta contexto temporal (uptime, restart history)
- Solo tienes correlación, no causalidad
- No descartaste alternativas obvias
- Patrón parece conocido pero contexto es diferente
- No ejecutaste checklist específico del problema

### Cuando Hay Duda

Si tienes dudas sobre el diagnóstico:
1. Marca como "Hipótesis de trabajo (requiere validación)"
2. Lista evidencia que confirmaría/descartaría
3. Ejecuta pruebas adicionales ANTES de comunicar
4. Solicita al usuario ejecutar monitoreo más largo

**Mejor decir "Necesito más datos" que dar diagnóstico incorrecto.**

---

## 1️⃣ Zombie Transactions Checklist

**Script**: `scripts/agents/sql-dba/pre-diagnosis-zombie-validation.sh`

### Checkpoints Obligatorios

#### ✅ Checkpoint 1: SQL Server Uptime

```sql
SELECT sqlserver_start_time,
       DATEDIFF(DAY, sqlserver_start_time, GETUTCDATE()) AS uptime_days,
       DATEDIFF(MINUTE, sqlserver_start_time, GETUTCDATE()) AS uptime_minutes
FROM sys.dm_os_sys_info
```

**Propósito**: Establecer línea base temporal del servidor.

#### ✅ Checkpoint 2: Correlación Temporal

```sql
SELECT 
    (SELECT sqlserver_start_time FROM sys.dm_os_sys_info) AS server_start,
    MIN(transaction_begin_time) AS oldest_transaction,
    DATEDIFF(MINUTE, 
        (SELECT sqlserver_start_time FROM sys.dm_os_sys_info),
        MIN(transaction_begin_time)) AS minutes_after_restart
FROM sys.dm_tran_active_transactions
WHERE transaction_begin_time < DATEADD(DAY, -1, GETUTCDATE())
```

**Interpretación**:
- `minutes_after_restart < 10` → Transacciones de RECOVERY/SISTEMA
- `minutes_after_restart > 60` → Investigar más (posible zombie)

#### ✅ Checkpoint 3: Session Ownership

```sql
SELECT at.transaction_id, at.name, at.transaction_begin_time,
       at.transaction_type, at.transaction_state,
       st.session_id, es.login_name, es.host_name, es.program_name
FROM sys.dm_tran_active_transactions at
LEFT JOIN sys.dm_tran_session_transactions st ON at.transaction_id = st.transaction_id
LEFT JOIN sys.dm_exec_sessions es ON st.session_id = es.session_id
WHERE at.transaction_begin_time < DATEADD(DAY, -1, GETUTCDATE())
```

**Interpretación**:
- `session_id = NULL` → Transacción INTERNA (NO zombie)
- `session_id > 0 + login_name` → Transacción de USUARIO (investigar)

#### ✅ Checkpoint 4: PVS Stats

```sql
SELECT database_id, 
       persistent_version_store_size_kb / 1024 / 1024 AS pvs_gb,
       current_aborted_transaction_count,
       oldest_aborted_transaction_begin_time
FROM sys.dm_tran_persistent_version_store_stats
WHERE database_id = DB_ID()
```

**Interpretación**:
- `current_aborted_transaction_count = 0` → NO hay zombies bloqueando PVS
- `current_aborted_transaction_count > 0` → SÍ hay bloqueadores

#### ✅ Checkpoint 5: Proporción PVS vs Duración

```sql
-- Calcular ratio: actual PVS / esperado si bloqueado
-- Si ratio < 0.1 → Cleanup funciona
-- Si ratio > 0.5 → Cleanup bloqueado
```

### Criterios de Decisión

#### ✅ Zombie Transactions → SÍ, si:
- session_id ≠ NULL (número específico)
- login_name = usuario aplicación (no 'sa' o 'system')
- Inicio >> restart (horas/días DESPUÉS del restart)
- current_aborted_transaction_count > 0
- pvs_ratio > 0.5 (PVS proporcional a duración)

#### ⚠️ System/Recovery Transactions → SÍ, si:
- session_id = NULL (SYSTEM)
- Inicio ≈ restart (< 10 minutos después)
- current_aborted_transaction_count = 0
- pvs_ratio < 0.1 (PVS pequeño comparado con duración)

### Lecciones de Incidente Real (Caso 2025-12)

**Síntoma observado**: 8 transacciones de 47 días, session_id=NULL, type=2

**Diagnóstico inicial ERRÓNEO**: "Zombie transactions bloqueando PVS"

**Realidad**: Transacciones internas de PVS post-restart (Azure SQL Database)

**Error cometido**:
1. ❌ No verifiqué SQL Server uptime
2. ❌ No correlacioné inicio de transacciones con restart (3 minutos después)
3. ❌ No interpreté session_id=NULL como indicador de sistema
4. ❌ No validé proporción PVS vs duración (246 GB << 7,050 GB esperados)

**Aprendizaje**:
- **session_id = NULL es clear indicator de transacción de SISTEMA**
- **Correlación temporal restart vs transacciones es CRÍTICA**
- **Proporción PVS vs duración debe tener sentido matemático**
- **Azure SQL tiene comportamientos únicos** (reinicios automáticos, recovery)

---

## 2️⃣ Blocking & Deadlocks Checklist

### Checkpoints Obligatorios

#### ✅ Checkpoint 1: Blocking Chain

```sql
WITH BlockingChain AS (
    SELECT session_id, blocking_session_id, wait_type, wait_time,
           CAST(1 AS INT) AS level
    FROM sys.dm_exec_requests WHERE blocking_session_id <> 0
    UNION ALL
    SELECT r.session_id, r.blocking_session_id, r.wait_type, r.wait_time, bc.level + 1
    FROM sys.dm_exec_requests r
    INNER JOIN BlockingChain bc ON r.session_id = bc.blocking_session_id
)
SELECT bc.*, s.login_name, s.host_name, st.text
FROM BlockingChain bc
INNER JOIN sys.dm_exec_sessions s ON bc.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(s.most_recent_sql_handle) st
ORDER BY bc.level, bc.wait_time DESC
```

**Propósito**: Identificar blocker root (head of blocking chain).

#### ✅ Checkpoint 2: Duración del Bloqueo

- Evaluar `wait_time` del blocked session
- Determinar si es temporal (<1 min) o persistente (>5 min)

#### ✅ Checkpoint 3: Impacto

- Contar sesiones bloqueadas
- Identificar usuarios/aplicaciones afectadas
- Estimar SLA impact

### Criterios de Decisión para KILL

**KILL session solo si:**
- Transacción lleva >30 min bloqueando
- Impacto en producción crítico (SLA violated)
- NO es proceso sistema/replicación/backup
- Usuario notificado (si posible)
- Plan de rollback documentado

**⚠️ REQUIERE APROBACIÓN EXPLÍCITA**

---

## 3️⃣ Storage Growth Checklist

### Checkpoints Obligatorios

#### ✅ Checkpoint 1: Tipo de Crecimiento

```sql
-- Data vs Log vs TempDB vs PVS
SELECT name, type_desc, 
       size * 8 / 1024 AS size_mb,
       CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT) * 8 / 1024 AS used_mb
FROM sys.database_files
```

#### ✅ Checkpoint 2: PVS Investigation

```sql
SELECT database_id,
       persistent_version_store_size_kb / 1024 / 1024 AS pvs_gb,
       current_aborted_transaction_count,
       oldest_aborted_transaction_begin_time
FROM sys.dm_tran_persistent_version_store_stats
```

**Interpretación**:
- `pvs_gb > 50% storage` → Problema PVS
- `oldest_aborted_age_min > 60` → Transacciones reteniendo PVS

#### ✅ Checkpoint 3: Unallocated Space

```sql
SELECT SUM(unallocated_extent_page_count) * 8 / 1024 / 1024 AS unallocated_gb
FROM sys.dm_db_file_space_usage
```

#### ✅ Checkpoint 4: Growth Rate

- Ejecutar monitoreo de 1 hora (mínimo)
- Calcular GB/día actual
- Comparar con histórico

### Criterios de Decisión

- `pvs_gb > 50% storage + current_aborted_count > 0` → PVS bloqueado
- `pvs_gb = 0 + unallocated_gb alto` → Cleanup completó, espacio no consolidado
- `growth_rate > 50 GB/día` → Problema activo
- `growth_rate < 10 GB/día` → Normal/resuelto

---

## 4️⃣ Performance Degradation Checklist

### Checkpoints Obligatorios

#### ✅ Checkpoint 1: Wait Stats

```sql
SELECT TOP 50 wait_type, wait_time_ms, waiting_tasks_count
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN ('CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'SLEEP_TASK')
ORDER BY wait_time_ms DESC
```

**Interpretación**:
- `PAGEIOLATCH_*` → IO disk reads
- `WRITELOG` → Log writes
- `LCK_*` → Blocking locks
- `CXPACKET` → Paralelismo
- `SOS_SCHEDULER_YIELD` → CPU pressure

#### ✅ Checkpoint 2: Top Queries

```sql
SELECT TOP 20 
    qs.execution_count,
    qs.total_worker_time / qs.execution_count AS avg_cpu,
    SUBSTRING(st.text, (qs.statement_start_offset/2)+1,
      ((CASE qs.statement_end_offset WHEN -1 THEN DATALENGTH(st.text)
        ELSE qs.statement_end_offset END - qs.statement_start_offset)/2) + 1) AS query_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
ORDER BY qs.total_worker_time DESC
```

#### ✅ Checkpoint 3: Query Store Regressions

```sql
-- Buscar queries con plan changes recientes
SELECT TOP 20 qsq.query_id, qsqt.query_sql_text,
       qsrs.count_executions, qsrs.avg_duration
FROM sys.query_store_query qsq
INNER JOIN sys.query_store_query_text qsqt ON qsq.query_text_id = qsqt.query_text_id
INNER JOIN sys.query_store_plan qsp ON qsq.query_id = qsp.query_id
INNER JOIN sys.query_store_runtime_stats qsrs ON qsp.plan_id = qsrs.plan_id
WHERE qsrs.last_execution_time > DATEADD(HOUR, -24, GETUTCDATE())
ORDER BY qsrs.avg_duration DESC
```

#### ✅ Checkpoint 4: Index Analysis

- Missing indexes (DMVs)
- Unused indexes
- Fragmentation levels

### Criterios de Decisión

- Wait stats apuntan a IO → Índices/query tuning/tier upgrade
- Wait stats apuntan a CPU → Query optimization/scale up
- Query regressions identificadas → Force plan (con aprobación)
- Missing indexes críticos → Create index (con aprobación)

---

## 5️⃣ Post-Diagnosis Validation

**Script**: `scripts/agents/sql-dba/post-diagnosis-validation.sh`

### Auto-Validación (después de dar diagnóstico)

Ejecutar checklist de auto-validación que verifica:

1. ✅ Todas las queries diagnósticas ejecutadas
2. ✅ Evidencia directa de causalidad (no solo correlación)
3. ✅ Hipótesis alternativas consideradas y descartadas
4. ✅ Contexto de plataforma verificado
5. ✅ Checklist específico del problema completado

### Preguntas Críticas

- Q1: ¿Ejecuté TODAS las queries del checklist?
- Q2: ¿Tengo EVIDENCIA DIRECTA de causalidad?
- Q3: ¿Consideré al menos 3 hipótesis alternativas?
- Q4: ¿Puedo explicar por qué las alternativas NO aplican?
- Q5: ¿El diagnóstico considera la plataforma específica?
- Q6: Si hay duda, ¿la comuniqué claramente?

---

## Uso de Scripts

### Ejecutar Pre-Diagnosis Validation

```bash
# Con Azure AD authentication
./scripts/agents/sql-dba/pre-diagnosis-zombie-validation.sh \
  -s myserver.database.windows.net \
  -d mydb

# Con SQL authentication
./scripts/agents/sql-dba/pre-diagnosis-zombie-validation.sh \
  -s myserver.database.windows.net \
  -d mydb \
  -u myuser \
  -p mypassword
```

### Ejecutar Post-Diagnosis Validation

```bash
./scripts/agents/sql-dba/post-diagnosis-validation.sh "Zombie Transactions"
```

---

## Referencias

- [Microsoft: Accelerated Database Recovery](https://learn.microsoft.com/en-us/sql/relational-databases/accelerated-database-recovery-concepts)
- [Microsoft: sys.dm_tran_persistent_version_store_stats](https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-tran-persistent-version-store-stats-transact-sql)
- [Microsoft: Troubleshoot blocking](https://learn.microsoft.com/en-us/troubleshoot/sql/database-engine/performance/understand-resolve-blocking)
- [Post-Mortem: Caso 2025-12](../../work/microsoft-support/POST-MORTEM-DIAGNOSTIC-ERROR.md) (si disponible en tu workspace)

---

## Contribuciones

Para agregar nuevos checklists o mejorar existentes, seguir estructura:

1. Checkpoints obligatorios (queries SQL específicos)
2. Interpretación de resultados
3. Criterios de decisión claros
4. Lecciones de incidentes reales (si aplica)
5. Referencias a documentación oficial

**La calidad de los diagnósticos depende de la rigurosidad de estos checklists.**
