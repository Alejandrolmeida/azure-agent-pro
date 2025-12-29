# 🚨 Guía Rápida: Detección de Transacciones Zombie

## ¿Qué son las Transacciones Zombie?

Transacciones activas que han perdido su conexión (`session_id = NULL`) pero permanecen en el sistema bloqueando recursos y limpieza de version store, causando crecimiento anómalo de espacio.

---

## ⚡ Detección Rápida

### Opción 1: Script Bash Automatizado

```bash
# Configurar credenciales
export AZURE_SQL_SERVER="your-server.database.windows.net"
export AZURE_SQL_DATABASE="your-database"
export AZURE_SQL_USERNAME="your-username"
export AZURE_SQL_PASSWORD="your-password"

# Ejecutar detección
./scripts/agents/sql-dba/detect-zombie-transactions.sh
```

### Opción 2: Python Script Directo

```bash
python3 scripts/agents/sql-dba/sql-query.py \
  -s your-server.database.windows.net \
  -d your-database \
  -u your-username \
  -p 'your-password' \
  -q "SELECT at.transaction_id, at.name, at.transaction_begin_time,
      DATEDIFF(DAY, at.transaction_begin_time, GETUTCDATE()) AS DurationDays,
      sess.session_id
      FROM sys.dm_tran_active_transactions at
      LEFT JOIN sys.dm_tran_session_transactions st ON at.transaction_id = st.transaction_id
      LEFT JOIN sys.dm_exec_sessions sess ON st.session_id = sess.session_id
      WHERE at.transaction_begin_time < DATEADD(HOUR, -1, GETUTCDATE())
      ORDER BY at.transaction_begin_time" \
  -o table
```

### Opción 3: SQL Directo (SSMS, Azure Data Studio)

```sql
SELECT 
    at.transaction_id,
    at.name AS TransactionName,
    at.transaction_begin_time AS StartTime,
    DATEDIFF(DAY, at.transaction_begin_time, GETUTCDATE()) AS DurationDays,
    sess.session_id,
    sess.login_name,
    CASE 
        WHEN sess.session_id IS NULL THEN 'ZOMBIE'
        ELSE 'ACTIVA'
    END AS Status
FROM sys.dm_tran_active_transactions at
LEFT JOIN sys.dm_tran_session_transactions st ON at.transaction_id = st.transaction_id
LEFT JOIN sys.dm_exec_sessions sess ON st.session_id = sess.session_id
WHERE at.transaction_begin_time < DATEADD(HOUR, -1, GETUTCDATE())
ORDER BY at.transaction_begin_time;
```

---

## 📋 Interpretación de Resultados

| Campo | Valor Problemático | Significado |
|-------|-------------------|-------------|
| `session_id` | **NULL** | 🚨 **ZOMBIE** - Transacción huérfana |
| `DurationDays` | **> 7** | 🔴 **CRÍTICO** - Requiere failover |
| `DurationDays` | **> 1** | 🟡 **URGENTE** - Investigar |
| `DurationHours` | **> 1** | 🟠 **ADVERTENCIA** - Monitorear |
| `TransactionName` | **worktable** | Operación interna (no KILL-able) |
| `TxType` | **2** | Read-Only (menor impacto) |
| `TxState` | **2** | Activa (bloqueando recursos) |

---

## 🔍 Análisis de Impacto

### Query de Espacio Bloqueado

```sql
SELECT 
    DB_NAME() AS DatabaseName,
    CAST(SUM(unallocated_extent_page_count) * 8.0 / 1024 / 1024 AS DECIMAL(10,2)) AS UnallocatedSpaceGB,
    (SELECT COUNT(*) 
     FROM sys.dm_tran_active_transactions 
     WHERE transaction_begin_time < DATEADD(HOUR, -1, GETUTCDATE())) AS ZombieCount
FROM sys.dm_db_file_space_usage;
```

**Interpretación**:
- `UnallocatedSpaceGB > 500 GB` → 🔴 Problema crítico
- `UnallocatedSpaceGB > 100 GB` → 🟡 Requiere atención
- `ZombieCount > 0` → ⚠️ Limpieza bloqueada

---

## 🛠️ Solución

### ⚠️ NO intentar KILL manual

Las transacciones zombie con `session_id = NULL` **NO** son terminables con `KILL`.

### ✅ Solución: Failover Manual

```bash
# Reemplazar con tus valores
az sql db failover \
  --resource-group <your-resource-group> \
  --server <your-server> \
  --name <your-database>
```

**Impacto**:
- ⏱️ Downtime: 30-60 segundos
- 🔄 Todas las conexiones se reinician
- ✅ Transacciones zombie se limpian
- ✅ Espacio comienza a recuperarse en 24-48h

---

## 📊 Monitoreo Post-Solución

### 1. Verificar que zombies desaparecieron

```sql
SELECT COUNT(*) AS RemainingZombies
FROM sys.dm_tran_active_transactions
WHERE transaction_begin_time < DATEADD(HOUR, -1, GETUTCDATE());
```

### 2. Monitorear recuperación de espacio

```sql
SELECT 
    GETUTCDATE() AS CheckTime,
    CAST(SUM(unallocated_extent_page_count) * 8.0 / 1024 / 1024 AS DECIMAL(10,2)) AS UnallocatedGB
FROM sys.dm_db_file_space_usage;
```

### 3. Verificar crecimiento normalizado

```sql
SELECT 
    GETUTCDATE() AS CheckTime,
    CAST(SUM(CAST(size AS BIGINT)) * 8.0 / 1024 / 1024 AS DECIMAL(10,2)) AS TotalGB
FROM sys.database_files WHERE type = 0;
```

---

## 🚨 Alertas Proactivas

### Query para Azure Monitor

```sql
-- Ejecutar cada hora, alertar si devuelve filas
SELECT 
    COUNT(*) AS ZombieCount,
    MAX(DATEDIFF(HOUR, transaction_begin_time, GETUTCDATE())) AS OldestHours
FROM sys.dm_tran_active_transactions
WHERE transaction_begin_time < DATEADD(HOUR, -24, GETUTCDATE())
HAVING COUNT(*) > 0;
```

---

## 📁 Archivos de Referencia

- **Queries completas**: `docs/queries/detect-zombie-transactions.sql`
- **Script automatizado**: `scripts/agents/sql-dba/detect-zombie-transactions.sh`
- **Python tool**: `scripts/agents/sql-dba/sql-query.py`

---

## ℹ️ Información Adicional

**Causas comunes**:
- Crash/failover durante operaciones largas
- Desconexiones abruptas de red
- Aplicaciones que no cierran transacciones

**Prevención**:
- Failovers preventivos mensuales
- Monitoreo continuo de transacciones >1h
- Timeouts de aplicación configurados
- Alertas automáticas

**Documentación**:
- [Azure SQL ADR](https://docs.microsoft.com/sql/relational-databases/accelerated-database-recovery-concepts)
- [DMVs Transacciones](https://docs.microsoft.com/sql/relational-databases/system-dynamic-management-views/transaction-related-dynamic-management-views-and-functions-transact-sql)
