-- ============================================
-- CONSULTA: Detectar Transacciones Zombie/Huérfanas
-- Propósito: Identificar transacciones activas que están bloqueando limpieza
-- ============================================
-- 
-- INSTRUCCIONES DE USO:
-- 1. Abrir SQL Server Management Studio (SSMS) o Azure Data Studio
-- 2. Conectarse a la base de datos problemática
-- 3. Seleccionar el query deseado (Opción 1, 2, 3 o 4)
-- 4. Ejecutar con F5 o botón "Execute"
-- 5. Revisar resultados según la guía de interpretación
--
-- SÍNTOMAS DE TRANSACCIONES ZOMBIE:
-- - Transacciones con más de 24 horas activas
-- - session_id = NULL (huérfanas, sin conexión)
-- - Bloquean limpieza de version store
-- - Causan crecimiento continuo de espacio "unallocated"
-- ============================================


-- ============================================
-- OPCIÓN 1: DETECCIÓN SIMPLE (RECOMENDADA)
-- ============================================
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
    sess.program_name,
    req.status AS RequestStatus,
    req.command AS CurrentCommand,
    SUBSTRING(txt.text, (req.statement_start_offset/2)+1,
        ((CASE req.statement_end_offset
            WHEN -1 THEN DATALENGTH(txt.text)
            ELSE req.statement_end_offset
        END - req.statement_start_offset)/2) + 1) AS CurrentQuery
FROM sys.dm_tran_active_transactions at
LEFT JOIN sys.dm_tran_session_transactions st ON at.transaction_id = st.transaction_id
LEFT JOIN sys.dm_exec_sessions sess ON st.session_id = sess.session_id
LEFT JOIN sys.dm_exec_requests req ON sess.session_id = req.session_id
OUTER APPLY sys.dm_exec_sql_text(req.sql_handle) txt
WHERE at.transaction_begin_time < DATEADD(MINUTE, -5, GETUTCDATE())
ORDER BY at.transaction_begin_time;


-- ============================================
-- OPCIÓN 2: DETECCIÓN CON ANÁLISIS DE SEVERIDAD
-- ============================================
SELECT 
    at.transaction_id,
    at.name AS TransactionName,
    at.transaction_begin_time AS StartTime,
    CONCAT(DATEDIFF(DAY, at.transaction_begin_time, GETUTCDATE()), ' días, ',
           DATEDIFF(HOUR, at.transaction_begin_time, GETUTCDATE()) % 24, ' horas') AS Duration,
    CASE 
        WHEN sess.session_id IS NULL THEN 'HUÉRFANA (sin sesión)'
        ELSE 'Con sesión activa'
    END AS SessionStatus,
    CASE at.transaction_type
        WHEN 1 THEN 'Read/Write'
        WHEN 2 THEN 'Read-Only'
        WHEN 3 THEN 'System'
        WHEN 4 THEN 'Distributed'
    END AS TransactionType,
    CASE at.transaction_state
        WHEN 2 THEN 'Activa'
        WHEN 7 THEN 'Rolling back'
        WHEN 8 THEN 'Rolled back'
        ELSE CAST(at.transaction_state AS VARCHAR)
    END AS TransactionState,
    sess.session_id,
    sess.login_name,
    sess.host_name,
    sess.program_name,
    CASE 
        WHEN DATEDIFF(DAY, at.transaction_begin_time, GETUTCDATE()) > 7 
        THEN 'CRÍTICO: >7 días - Requiere failover'
        WHEN DATEDIFF(HOUR, at.transaction_begin_time, GETUTCDATE()) > 24 
        THEN 'URGENTE: >24 horas'
        WHEN DATEDIFF(HOUR, at.transaction_begin_time, GETUTCDATE()) > 1 
        THEN 'ADVERTENCIA: >1 hora'
        ELSE 'Normal'
    END AS Severity
FROM sys.dm_tran_active_transactions at
LEFT JOIN sys.dm_tran_session_transactions st ON at.transaction_id = st.transaction_id
LEFT JOIN sys.dm_exec_sessions sess ON st.session_id = sess.session_id
WHERE at.transaction_begin_time < DATEADD(MINUTE, -5, GETUTCDATE())
ORDER BY at.transaction_begin_time;


-- ============================================
-- OPCIÓN 3: CONTEO RÁPIDO
-- ============================================
SELECT 
    COUNT(*) AS TotalZombieTransactions,
    COUNT(CASE WHEN sess.session_id IS NULL THEN 1 END) AS OrphanedTransactions,
    MAX(DATEDIFF(DAY, at.transaction_begin_time, GETUTCDATE())) AS OldestTransactionDays,
    MAX(DATEDIFF(HOUR, at.transaction_begin_time, GETUTCDATE())) AS OldestTransactionHours,
    CASE 
        WHEN MAX(DATEDIFF(DAY, at.transaction_begin_time, GETUTCDATE())) > 7 THEN 'CRÍTICO'
        WHEN MAX(DATEDIFF(HOUR, at.transaction_begin_time, GETUTCDATE())) > 24 THEN 'URGENTE'
        WHEN COUNT(*) > 0 THEN 'ADVERTENCIA'
        ELSE 'OK'
    END AS OverallStatus
FROM sys.dm_tran_active_transactions at
LEFT JOIN sys.dm_tran_session_transactions st ON at.transaction_id = st.transaction_id
LEFT JOIN sys.dm_exec_sessions sess ON st.session_id = sess.session_id
WHERE at.transaction_begin_time < DATEADD(MINUTE, -5, GETUTCDATE());


-- ============================================
-- OPCIÓN 4: IMPACTO EN ESPACIO
-- ============================================
SELECT 
    DB_NAME() AS DatabaseName,
    CAST(SUM(unallocated_extent_page_count) * 8.0 / 1024 / 1024 AS DECIMAL(10,2)) AS UnallocatedSpaceGB,
    CAST(SUM(version_store_reserved_page_count) * 8.0 / 1024 / 1024 AS DECIMAL(10,2)) AS VersionStoreGB,
    CAST(SUM(internal_object_reserved_page_count) * 8.0 / 1024 / 1024 AS DECIMAL(10,2)) AS InternalObjectsGB,
    (SELECT COUNT(*) 
     FROM sys.dm_tran_active_transactions 
     WHERE transaction_begin_time < DATEADD(HOUR, -1, GETUTCDATE())) AS LongRunningTransactions,
    (SELECT COUNT(*) 
     FROM sys.dm_tran_active_transactions at
     LEFT JOIN sys.dm_tran_session_transactions st ON at.transaction_id = st.transaction_id
     LEFT JOIN sys.dm_exec_sessions sess ON st.session_id = sess.session_id
     WHERE at.transaction_begin_time < DATEADD(HOUR, -1, GETUTCDATE())
       AND sess.session_id IS NULL) AS OrphanedTransactions
FROM sys.dm_db_file_space_usage;


-- ============================================
-- QUERIES DE SEGUIMIENTO POST-RESOLUCIÓN
-- ============================================

-- 1. Verificar que transacciones zombie se eliminaron
SELECT COUNT(*) AS RemainingZombies
FROM sys.dm_tran_active_transactions
WHERE transaction_begin_time < DATEADD(HOUR, -1, GETUTCDATE());


-- 2. Monitorear recuperación de espacio
SELECT 
    GETUTCDATE() AS CheckTime,
    CAST(SUM(unallocated_extent_page_count) * 8.0 / 1024 / 1024 AS DECIMAL(10,2)) AS UnallocatedGB
FROM sys.dm_db_file_space_usage;


-- 3. Historial de crecimiento
SELECT 
    GETUTCDATE() AS CheckTime,
    DB_NAME() AS DatabaseName,
    CAST(SUM(CAST(size AS BIGINT)) * 8.0 / 1024 / 1024 AS DECIMAL(10,2)) AS TotalAllocatedGB,
    CAST(SUM(CAST(FILEPROPERTY(name, 'SpaceUsed') AS BIGINT)) * 8.0 / 1024 / 1024 AS DECIMAL(10,2)) AS UsedSpaceGB,
    CAST((SUM(CAST(size AS BIGINT)) - SUM(CAST(FILEPROPERTY(name, 'SpaceUsed') AS BIGINT))) * 8.0 / 1024 / 1024 AS DECIMAL(10,2)) AS WastedSpaceGB
FROM sys.database_files
WHERE type = 0;


-- ============================================
-- INTERPRETACIÓN DE RESULTADOS
-- ============================================
/*
CAMPOS IMPORTANTES:
- session_id = NULL → Transacción ZOMBIE (huérfana)
- DurationDays > 7 → CRÍTICO (requiere failover)
- DurationDays > 1 → URGENTE (investigar)
- TxType = 2 → Read-Only (menor impacto)
- TxState = 2 → Activa (bloqueando recursos)
- TransactionName = 'worktable' → Operación interna

IMPACTO EN ESPACIO:
- UnallocatedSpaceGB > 500 GB → Problema crítico
- UnallocatedSpaceGB > 100 GB → Requiere atención
- OrphanedTransactions > 0 → Limpieza bloqueada

ACCIÓN REQUERIDA:
Si se detectan transacciones zombie de >7 días sin session_id:
1. NO intentar KILL (no funcionará sin sesión)
2. Planificar failover manual de la base de datos
3. Comando: az sql db failover --resource-group <rg> --server <server> --name <db>
4. Downtime estimado: 30-60 segundos
5. Recuperación de espacio: 24-48 horas post-failover
*/
