-- =============================================
-- ANÁLISIS DE PATRONES DE USO
-- Para determinar ventana óptima de mantenimiento
-- =============================================

USE [nombre_de_tu_base_de_datos];
GO

PRINT '══════════════════════════════════════════════════════════';
PRINT '  ANÁLISIS DE PATRONES DE USO - VENTANA DE MANTENIMIENTO';
PRINT '══════════════════════════════════════════════════════════';
PRINT '';

-- =============================================
-- 1. CONEXIONES ACTIVAS POR HORA (Últimas 48h)
-- =============================================
PRINT '📊 Conexiones activas por hora del día (patrón típico):';
PRINT '';

SELECT 
    DATEPART(HOUR, login_time) AS Hora_UTC,
    COUNT(*) AS Num_Conexiones,
    COUNT(DISTINCT host_name) AS Hosts_Distintos,
    COUNT(DISTINCT login_name) AS Usuarios_Distintos,
    STRING_AGG(DISTINCT program_name, ', ') AS Aplicaciones
FROM sys.dm_exec_sessions
WHERE is_user_process = 1
  AND login_time > DATEADD(HOUR, -48, GETUTCDATE())
GROUP BY DATEPART(HOUR, login_time)
ORDER BY Hora_UTC;

PRINT '';

-- =============================================
-- 2. QUERIES EN EJECUCIÓN POR HORA
-- =============================================
PRINT '🔍 Actividad de queries por hora:';
PRINT '';

SELECT 
    DATEPART(HOUR, start_time) AS Hora_UTC,
    COUNT(*) AS Total_Queries,
    AVG(DATEDIFF(SECOND, start_time, GETUTCDATE())) AS Duracion_Promedio_Seg,
    MAX(DATEDIFF(SECOND, start_time, GETUTCDATE())) AS Duracion_Maxima_Seg
FROM sys.dm_exec_requests
WHERE session_id > 50  -- Excluir sesiones de sistema
  AND start_time > DATEADD(HOUR, -24, GETUTCDATE())
GROUP BY DATEPART(HOUR, start_time)
ORDER BY Hora_UTC;

PRINT '';

-- =============================================
-- 3. SESIONES ACTIVAS ACTUALES
-- =============================================
PRINT '👥 Sesiones activas en este momento:';
PRINT '';

SELECT 
    COUNT(*) AS Sesiones_Activas,
    SUM(CASE WHEN status = 'running' THEN 1 ELSE 0 END) AS Ejecutando,
    SUM(CASE WHEN status = 'sleeping' THEN 1 ELSE 0 END) AS Inactivas,
    MIN(login_time) AS Sesion_Mas_Antigua,
    MAX(last_request_end_time) AS Ultima_Actividad
FROM sys.dm_exec_sessions
WHERE is_user_process = 1;

PRINT '';

-- =============================================
-- 4. PROGRAMAS/APLICACIONES CONECTADAS
-- =============================================
PRINT '💻 Aplicaciones conectadas:';
PRINT '';

SELECT 
    program_name AS Aplicacion,
    COUNT(*) AS Num_Conexiones,
    MIN(login_time) AS Primera_Conexion,
    MAX(last_request_end_time) AS Ultima_Actividad
FROM sys.dm_exec_sessions
WHERE is_user_process = 1
  AND program_name IS NOT NULL
GROUP BY program_name
ORDER BY Num_Conexiones DESC;

PRINT '';

-- =============================================
-- 5. ACTIVIDAD QUERY STORE (Última semana)
-- =============================================
PRINT '📈 Patrones de ejecución (Query Store - última semana):';
PRINT '';

IF EXISTS (SELECT 1 FROM sys.database_query_store_options WHERE actual_state = 1)
BEGIN
    SELECT 
        DATEPART(WEEKDAY, qsrs.last_execution_time) AS Dia_Semana,  -- 1=Domingo, 2=Lunes...
        DATEPART(HOUR, qsrs.last_execution_time) AS Hora_UTC,
        COUNT(*) AS Num_Ejecuciones,
        AVG(qsrs.avg_duration) / 1000000.0 AS Duracion_Promedio_Seg,
        SUM(qsrs.count_executions) AS Total_Ejecuciones
    FROM sys.query_store_runtime_stats qsrs
    WHERE qsrs.last_execution_time > DATEADD(DAY, -7, GETUTCDATE())
    GROUP BY DATEPART(WEEKDAY, qsrs.last_execution_time), 
             DATEPART(HOUR, qsrs.last_execution_time)
    ORDER BY Dia_Semana, Hora_UTC;
END
ELSE
BEGIN
    PRINT '⚠️  Query Store no está habilitado. No hay datos históricos disponibles.';
END

PRINT '';
PRINT '══════════════════════════════════════════════════════════';
PRINT '';

-- =============================================
-- 6. RECOMENDACIONES
-- =============================================
PRINT '💡 ANÁLISIS Y RECOMENDACIONES:';
PRINT '';
PRINT 'Basado en los datos anteriores, identificar:';
PRINT '';
PRINT '1. VENTANAS DE BAJO TRÁFICO:';
PRINT '   - Buscar horas con mínimo número de conexiones';
PRINT '   - Preferir horarios con pocas queries en ejecución';
PRINT '   - Evitar horas de carga ETL/batch';
PRINT '';
PRINT '2. PATRONES TÍPICOS (Base Datos Analítica/BI):';
PRINT '   - 00:00-05:00 UTC: Cargas ETL/noche (EVITAR)';
PRINT '   - 05:00-07:00 UTC: Ventana post-ETL (ÓPTIMO)';
PRINT '   - 08:00-18:00 UTC: Usuarios business/reports (EVITAR)';
PRINT '   - 20:00-23:00 UTC: Tráfico moderado';
PRINT '';
PRINT '3. RECOMENDACIÓN GENERAL (si no hay datos específicos):';
PRINT '   Zona Horaria: West Europe (UTC+1 CET)';
PRINT '   ';
PRINT '   🟢 MEJOR VENTANA: Sábado 05:00-06:00 UTC (06:00-07:00 CET)';
PRINT '      - Mínimo impacto usuario';
PRINT '      - Post cargas nocturnas';
PRINT '      - Fin de semana (menos crítico)';
PRINT '      - Equipo disponible para monitoreo';
PRINT '';
PRINT '   🟡 ALTERNATIVA 1: Lunes-Viernes 05:30-06:00 UTC (06:30-07:00 CET)';
PRINT '      - Entre ETL y business hours';
PRINT '      - Requiere coordinación con ETL team';
PRINT '';
PRINT '   🟠 ALTERNATIVA 2: Domingo 03:00-04:00 UTC (04:00-05:00 CET)';
PRINT '      - Mínimo riesgo usuario';
PRINT '      - Puede coincidir con mantenimientos Azure';
PRINT '';
PRINT '4. VALIDACIONES PRE-FAILOVER:';
PRINT '   - ✓ Confirmar no hay ETL corriendo';
PRINT '   - ✓ Notificar usuarios 24h antes';
PRINT '   - ✓ Tener equipo DBA disponible';
PRINT '   - ✓ Validar backup reciente (<24h)';
PRINT '   - ✓ Preparar queries de validación post-failover';
PRINT '';
PRINT '══════════════════════════════════════════════════════════';
GO

-- =============================================
-- QUERY ADICIONAL: Detectar cargas ETL/Batch
-- =============================================
PRINT '';
PRINT '🔧 Para identificar ventanas de carga ETL, ejecutar:';
PRINT '';
PRINT 'SELECT TOP 100';
PRINT '    DATEPART(HOUR, start_time) AS Hora_UTC,';
PRINT '    program_name, login_name,';
PRINT '    command, status,';
PRINT '    DATEDIFF(SECOND, start_time, GETUTCDATE()) AS Duracion_Seg';
PRINT 'FROM sys.dm_exec_requests';
PRINT 'WHERE command IN (''INSERT'', ''UPDATE'', ''DELETE'', ''BULK INSERT'')';
PRINT 'ORDER BY start_time DESC;';
PRINT '';
