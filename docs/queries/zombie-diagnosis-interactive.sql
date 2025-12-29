-- =============================================
-- DIAGNÓSTICO: Transacciones Zombie
-- Para ejecutar en: SSMS, Azure Data Studio
-- =============================================

USE [nombre_de_tu_base_de_datos];  -- ⚠️ CAMBIAR por tu base de datos
GO

PRINT '══════════════════════════════════════════════════════════';
PRINT '  ANÁLISIS DE TRANSACCIONES ZOMBIE';
PRINT '  Fecha: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '══════════════════════════════════════════════════════════';
PRINT '';

-- =============================================
-- PASO 1: DETECCIÓN DE TRANSACCIONES ZOMBIES
-- =============================================
PRINT '📋 PASO 1: Detectando transacciones de larga duración...';
PRINT '';

SELECT 
    '🚨 ZOMBIE' AS Alerta,
    at.transaction_id AS ID_Transaccion,
    at.name AS Nombre,
    at.transaction_begin_time AS Inicio,
    DATEDIFF(DAY, at.transaction_begin_time, GETUTCDATE()) AS Dias,
    DATEDIFF(HOUR, at.transaction_begin_time, GETUTCDATE()) AS Horas,
    CASE 
        WHEN sess.session_id IS NULL THEN '❌ HUÉRFANA'
        ELSE '✅ CON SESIÓN'
    END AS Estado_Sesion,
    CASE at.transaction_type
        WHEN 1 THEN 'Read/Write'
        WHEN 2 THEN 'Read-Only'
        WHEN 3 THEN 'Sistema'
        WHEN 4 THEN 'Distribuida'
    END AS Tipo,
    sess.session_id AS ID_Sesion,
    sess.login_name AS Usuario,
    sess.host_name AS Host,
    sess.program_name AS Programa,
    CASE 
        WHEN DATEDIFF(DAY, at.transaction_begin_time, GETUTCDATE()) > 7 
        THEN '🔴 CRÍTICO'
        WHEN DATEDIFF(HOUR, at.transaction_begin_time, GETUTCDATE()) > 24 
        THEN '🟡 URGENTE'
        WHEN DATEDIFF(HOUR, at.transaction_begin_time, GETUTCDATE()) > 1 
        THEN '🟠 ADVERTENCIA'
        ELSE '🟢 Normal'
    END AS Severidad
FROM sys.dm_tran_active_transactions at
LEFT JOIN sys.dm_tran_session_transactions st ON at.transaction_id = st.transaction_id
LEFT JOIN sys.dm_exec_sessions sess ON st.session_id = sess.session_id
WHERE at.transaction_begin_time < DATEADD(MINUTE, -5, GETUTCDATE())
ORDER BY at.transaction_begin_time;

PRINT '';
PRINT '══════════════════════════════════════════════════════════';
PRINT '';

-- =============================================
-- PASO 2: RESUMEN EJECUTIVO
-- =============================================
PRINT '📊 PASO 2: Resumen de transacciones zombies...';
PRINT '';

DECLARE @TotalZombies INT;
DECLARE @Huerfanas INT;
DECLARE @DiasMax INT;
DECLARE @HorasMax INT;
DECLARE @Estado NVARCHAR(20);

SELECT 
    @TotalZombies = COUNT(*),
    @Huerfanas = COUNT(CASE WHEN sess.session_id IS NULL THEN 1 END),
    @DiasMax = MAX(DATEDIFF(DAY, at.transaction_begin_time, GETUTCDATE())),
    @HorasMax = MAX(DATEDIFF(HOUR, at.transaction_begin_time, GETUTCDATE()))
FROM sys.dm_tran_active_transactions at
LEFT JOIN sys.dm_tran_session_transactions st ON at.transaction_id = st.transaction_id
LEFT JOIN sys.dm_exec_sessions sess ON st.session_id = sess.session_id
WHERE at.transaction_begin_time < DATEADD(MINUTE, -5, GETUTCDATE());

SET @Estado = CASE 
    WHEN @DiasMax > 7 THEN '🔴 CRÍTICO'
    WHEN @HorasMax > 24 THEN '🟡 URGENTE'
    WHEN @TotalZombies > 0 THEN '🟠 ADVERTENCIA'
    ELSE '🟢 OK'
END;

SELECT 
    @TotalZombies AS Total_Zombies,
    @Huerfanas AS Transacciones_Huerfanas,
    @DiasMax AS Antiguedad_Dias,
    @HorasMax AS Antiguedad_Horas,
    @Estado AS Estado_General;

PRINT '';
PRINT 'Total de transacciones zombie: ' + CAST(@TotalZombies AS VARCHAR);
PRINT 'Transacciones huérfanas (sin sesión): ' + CAST(@Huerfanas AS VARCHAR);
PRINT 'Transacción más antigua: ' + CAST(@DiasMax AS VARCHAR) + ' días (' + CAST(@HorasMax AS VARCHAR) + ' horas)';
PRINT 'Estado: ' + @Estado;
PRINT '';
PRINT '══════════════════════════════════════════════════════════';
PRINT '';

-- =============================================
-- PASO 3: IMPACTO EN ESPACIO
-- =============================================
PRINT '💾 PASO 3: Analizando impacto en espacio...';
PRINT '';

DECLARE @EspacioBloqueadoGB DECIMAL(10,2);
DECLARE @EstadoEspacio NVARCHAR(100);

SELECT 
    @EspacioBloqueadoGB = CAST(SUM(unallocated_extent_page_count) * 8.0 / 1024 / 1024 AS DECIMAL(10,2))
FROM sys.dm_db_file_space_usage;

SET @EstadoEspacio = CASE 
    WHEN @EspacioBloqueadoGB > 500 THEN '🔴 CRÍTICO: Más de 500 GB bloqueados'
    WHEN @EspacioBloqueadoGB > 100 THEN '🟡 ADVERTENCIA: Más de 100 GB bloqueados'
    WHEN @EspacioBloqueadoGB > 10 THEN '🟠 ATENCIÓN: ' + CAST(@EspacioBloqueadoGB AS VARCHAR) + ' GB bloqueados'
    ELSE '🟢 NORMAL: Espacio bajo control'
END;

SELECT 
    DB_NAME() AS Base_Datos,
    @EspacioBloqueadoGB AS Espacio_Bloqueado_GB,
    @TotalZombies AS Transacciones_Zombie,
    @EstadoEspacio AS Diagnostico;

PRINT '';
PRINT 'Espacio no reclaimable: ' + CAST(@EspacioBloqueadoGB AS VARCHAR) + ' GB';
PRINT 'Diagnóstico: ' + @EstadoEspacio;
PRINT '';
PRINT '══════════════════════════════════════════════════════════';
PRINT '';

-- =============================================
-- PASO 4: DESGLOSE DE ESPACIO DETALLADO
-- =============================================
PRINT '📈 PASO 4: Desglose detallado de uso de espacio...';
PRINT '';

SELECT 
    name AS Archivo,
    type_desc AS Tipo,
    CAST(size * 8.0 / 1024 / 1024 AS DECIMAL(10,2)) AS Tamano_Asignado_GB,
    CAST(FILEPROPERTY(name, 'SpaceUsed') * 8.0 / 1024 / 1024 AS DECIMAL(10,2)) AS Tamano_Usado_GB,
    CAST((size - FILEPROPERTY(name, 'SpaceUsed')) * 8.0 / 1024 / 1024 AS DECIMAL(10,2)) AS Tamano_Libre_GB,
    CAST(FILEPROPERTY(name, 'SpaceUsed') * 100.0 / size AS DECIMAL(5,2)) AS Porcentaje_Usado
FROM sys.database_files
ORDER BY type, name;

PRINT '';
PRINT '══════════════════════════════════════════════════════════';
PRINT '';

-- =============================================
-- PASO 5: RECOMENDACIONES
-- =============================================
PRINT '💡 PASO 5: Recomendaciones de acción...';
PRINT '';

IF @TotalZombies = 0
BEGIN
    PRINT '✅ RESULTADO: No se detectaron transacciones zombie.';
    PRINT '   La base de datos está funcionando correctamente.';
    PRINT '';
END
ELSE IF @Huerfanas > 0 AND @DiasMax > 7
BEGIN
    PRINT '🔴 ACCIÓN URGENTE REQUERIDA:';
    PRINT '   - Se detectaron ' + CAST(@Huerfanas AS VARCHAR) + ' transacciones huérfanas';
    PRINT '   - La más antigua tiene ' + CAST(@DiasMax AS VARCHAR) + ' días';
    PRINT '   - Espacio bloqueado: ' + CAST(@EspacioBloqueadoGB AS VARCHAR) + ' GB';
    PRINT '';
    PRINT '   SOLUCIÓN:';
    PRINT '   1. Las transacciones sin session_id NO se pueden terminar con KILL';
    PRINT '   2. Requiere FAILOVER MANUAL de la base de datos';
    PRINT '   3. Comando Azure CLI:';
    PRINT '      az sql db failover \';
    PRINT '        --resource-group <tu-resource-group> \';
    PRINT '        --server <tu-servidor> \';
    PRINT '        --name <tu-base-de-datos>';
    PRINT '';
    PRINT '   IMPACTO DEL FAILOVER:';
    PRINT '   - Downtime: 30-60 segundos';
    PRINT '   - Todas las conexiones se reiniciarán';
    PRINT '   - Las transacciones zombie se limpiarán automáticamente';
    PRINT '   - Recuperación de espacio: 24-48 horas';
    PRINT '';
END
ELSE IF @HorasMax > 24
BEGIN
    PRINT '🟡 ADVERTENCIA:';
    PRINT '   - Se detectaron transacciones de más de 24 horas';
    PRINT '   - Pueden estar bloqueando recursos';
    PRINT '';
    PRINT '   ACCIONES:';
    PRINT '   1. Revisar queries activas en las sesiones identificadas';
    PRINT '   2. Contactar a los usuarios/aplicaciones propietarias';
    PRINT '   3. Planificar terminación si es seguro (KILL <session_id>)';
    PRINT '   4. Si no mejora en 48h, considerar failover';
    PRINT '';
END
ELSE
BEGIN
    PRINT '🟠 MONITOREO:';
    PRINT '   - Transacciones detectadas pero no críticas aún';
    PRINT '   - Ejecutar este diagnóstico cada 6 horas';
    PRINT '   - Si superan 24 horas, tomar acción';
    PRINT '';
END

PRINT '══════════════════════════════════════════════════════════';
PRINT '';
PRINT '📚 DOCUMENTACIÓN ADICIONAL:';
PRINT '   - Queries detalladas: docs/queries/detect-zombie-transactions.sql';
PRINT '   - Guía rápida: docs/reference/zombie-transactions-quickstart.md';
PRINT '';
PRINT '✅ DIAGNÓSTICO COMPLETADO';
PRINT '══════════════════════════════════════════════════════════';
GO
