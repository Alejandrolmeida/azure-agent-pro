#!/bin/bash
# SQL Performance Analyzer for Azure SQL Databases
# Analiza el rendimiento y proporciona recomendaciones de optimización
# Author: Azure Architect Pro Agent
# Date: 2025-12-26

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Help function
show_help() {
    cat << EOF
${BLUE}SQL Performance Analyzer for Azure SQL Databases${NC}

${CYAN}Usage:${NC}
    $0 [OPTIONS]

${CYAN}Options:${NC}
    -s, --server SERVER         Azure SQL Server name
    -d, --database DATABASE     Database name
    -a, --action ACTION         Analysis action to perform
    -o, --output FILE           Output file for report (default: stdout)
    -h, --help                  Show this help message

${CYAN}Available Actions:${NC}
    slow-queries               Find slow running queries
    missing-indexes            Identify missing indexes
    index-usage                Analyze index usage statistics
    table-sizes                Show table sizes and row counts
    blocking                   Detect blocking sessions
    statistics                 Show database statistics
    fragmentation              Check index fragmentation
    recommendations            Get Azure SQL recommendations
    all                        Run all analyses (comprehensive report)

${CYAN}Examples:${NC}
    # Find slow queries
    $0 --server myserver --database mydb --action slow-queries

    # Comprehensive analysis report
    $0 -s myserver -d mydb -a all -o report.md

    # Check missing indexes
    $0 -s myserver -d mydb -a missing-indexes

${CYAN}Environment Variables:${NC}
    AZURE_SQL_SERVER            Default SQL server name
    AZURE_SQL_DATABASE          Default database name

EOF
}

# Parse arguments
SERVER="${AZURE_SQL_SERVER:-}"
DATABASE="${AZURE_SQL_DATABASE:-}"
ACTION=""
OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--server)
            SERVER="$2"
            shift 2
            ;;
        -d|--database)
            DATABASE="$2"
            shift 2
            ;;
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$SERVER" ]] || [[ -z "$DATABASE" ]] || [[ -z "$ACTION" ]]; then
    echo -e "${RED}Error: Server, database, and action are required${NC}"
    show_help
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_QUERY_SCRIPT="$SCRIPT_DIR/sql-query.sh"

if [[ ! -f "$SQL_QUERY_SCRIPT" ]]; then
    echo -e "${RED}Error: sql-query.sh not found at $SQL_QUERY_SCRIPT${NC}"
    exit 1
fi

# Output redirect
if [[ -n "$OUTPUT_FILE" ]]; then
    exec > >(tee "$OUTPUT_FILE")
fi

# Print header
print_header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Execute SQL query
execute_query() {
    local query="$1"
    "$SQL_QUERY_SCRIPT" --server "$SERVER" --database "$DATABASE" --aad --query "$query"
}

# Analyze slow queries
analyze_slow_queries() {
    print_header "📊 Slow Running Queries (Last 24 Hours)"
    
    local query="
SELECT TOP 20
    qs.execution_count AS [Executions],
    qs.total_worker_time / qs.execution_count AS [Avg CPU Time (µs)],
    qs.total_elapsed_time / qs.execution_count AS [Avg Duration (µs)],
    qs.total_logical_reads / qs.execution_count AS [Avg Logical Reads],
    qs.total_physical_reads / qs.execution_count AS [Avg Physical Reads],
    SUBSTRING(qt.text, (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(qt.text)
            ELSE qs.statement_end_offset
        END - qs.statement_start_offset)/2) + 1) AS [Query Text]
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
WHERE qs.creation_time >= DATEADD(day, -1, GETDATE())
ORDER BY qs.total_elapsed_time / qs.execution_count DESC
"
    
    execute_query "$query"
    
    echo -e "${YELLOW}💡 Recommendation:${NC} Review queries with high avg duration or logical reads"
}

# Analyze missing indexes
analyze_missing_indexes() {
    print_header "🔍 Missing Index Recommendations"
    
    local query="
SELECT TOP 20
    CONVERT(decimal(18,2), migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans)) AS [Improvement Measure],
    mid.statement AS [Table],
    mid.equality_columns AS [Equality Columns],
    mid.inequality_columns AS [Inequality Columns],
    mid.included_columns AS [Included Columns],
    migs.unique_compiles AS [Unique Compiles],
    migs.user_seeks AS [User Seeks],
    migs.user_scans AS [User Scans],
    migs.avg_total_user_cost AS [Avg Total User Cost],
    migs.avg_user_impact AS [Avg User Impact %]
FROM sys.dm_db_missing_index_group_stats migs
INNER JOIN sys.dm_db_missing_index_groups mig ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) > 10
ORDER BY [Improvement Measure] DESC
"
    
    execute_query "$query"
    
    echo -e "${YELLOW}💡 Recommendation:${NC} Create indexes with highest improvement measure first"
}

# Analyze index usage
analyze_index_usage() {
    print_header "📈 Index Usage Statistics"
    
    local query="
SELECT 
    OBJECT_NAME(ius.object_id) AS [Table],
    i.name AS [Index],
    i.type_desc AS [Index Type],
    ius.user_seeks AS [User Seeks],
    ius.user_scans AS [User Scans],
    ius.user_lookups AS [User Lookups],
    ius.user_updates AS [User Updates],
    CASE 
        WHEN ius.user_seeks + ius.user_scans + ius.user_lookups = 0 THEN 'Unused'
        WHEN ius.user_updates > (ius.user_seeks + ius.user_scans + ius.user_lookups) * 2 THEN 'High Update/Read Ratio'
        ELSE 'Active'
    END AS [Status]
FROM sys.dm_db_index_usage_stats ius
INNER JOIN sys.indexes i ON ius.object_id = i.object_id AND ius.index_id = i.index_id
WHERE OBJECTPROPERTY(ius.object_id, 'IsUserTable') = 1
ORDER BY ius.user_seeks + ius.user_scans + ius.user_lookups DESC
"
    
    execute_query "$query"
    
    echo -e "${YELLOW}💡 Recommendation:${NC} Consider dropping unused indexes or those with high update/read ratio"
}

# Analyze table sizes
analyze_table_sizes() {
    print_header "📦 Table Sizes and Row Counts"
    
    local query="
SELECT 
    t.name AS [Table],
    SUM(p.rows) AS [Row Count],
    SUM(a.total_pages) * 8 / 1024 AS [Total Space (MB)],
    SUM(a.used_pages) * 8 / 1024 AS [Used Space (MB)],
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 / 1024 AS [Unused Space (MB)]
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.is_ms_shipped = 0 AND i.object_id > 255
GROUP BY t.name
ORDER BY SUM(a.total_pages) DESC
"
    
    execute_query "$query"
    
    echo -e "${YELLOW}💡 Recommendation:${NC} Review large tables for partitioning opportunities"
}

# Check blocking sessions
check_blocking() {
    print_header "🔒 Blocking Sessions Analysis"
    
    local query="
SELECT 
    blocking.session_id AS [Blocking Session],
    blocked.session_id AS [Blocked Session],
    waitstats.wait_type AS [Wait Type],
    waitstats.wait_duration_ms AS [Wait Duration (ms)],
    blockingtxt.text AS [Blocking Query],
    blockedtxt.text AS [Blocked Query]
FROM sys.dm_exec_requests blocked
INNER JOIN sys.dm_exec_requests blocking ON blocked.blocking_session_id = blocking.session_id
INNER JOIN sys.dm_os_waiting_tasks waitstats ON blocked.session_id = waitstats.session_id
CROSS APPLY sys.dm_exec_sql_text(blocking.sql_handle) blockingtxt
CROSS APPLY sys.dm_exec_sql_text(blocked.sql_handle) blockedtxt
WHERE blocked.blocking_session_id <> 0
"
    
    execute_query "$query"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${YELLOW}💡 Recommendation:${NC} Review blocking queries and consider transaction optimization"
    else
        echo -e "${GREEN}✓ No blocking detected${NC}"
    fi
}

# Get database statistics
get_database_statistics() {
    print_header "📊 Database Statistics"
    
    local query="
SELECT 
    'Database' AS [Metric],
    DB_NAME() AS [Value]
UNION ALL
SELECT 
    'Size (MB)',
    CAST(SUM(size) * 8.0 / 1024 AS VARCHAR(20))
FROM sys.database_files
UNION ALL
SELECT 
    'Tables',
    CAST(COUNT(*) AS VARCHAR(20))
FROM sys.tables
UNION ALL
SELECT 
    'Indexes',
    CAST(COUNT(*) AS VARCHAR(20))
FROM sys.indexes
WHERE type > 0
UNION ALL
SELECT 
    'Compatibility Level',
    CAST(compatibility_level AS VARCHAR(20))
FROM sys.databases
WHERE name = DB_NAME()
"
    
    execute_query "$query"
}

# Check index fragmentation
check_fragmentation() {
    print_header "🔧 Index Fragmentation Analysis"
    
    local query="
SELECT 
    OBJECT_NAME(ips.object_id) AS [Table],
    i.name AS [Index],
    ips.index_type_desc AS [Index Type],
    ips.avg_fragmentation_in_percent AS [Fragmentation %],
    ips.page_count AS [Page Count],
    CASE 
        WHEN ips.avg_fragmentation_in_percent > 30 THEN 'Rebuild recommended'
        WHEN ips.avg_fragmentation_in_percent > 10 THEN 'Reorganize recommended'
        ELSE 'OK'
    END AS [Recommendation]
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 5
    AND ips.page_count > 100
ORDER BY ips.avg_fragmentation_in_percent DESC
"
    
    execute_query "$query"
    
    echo -e "${YELLOW}💡 Recommendation:${NC} Rebuild indexes >30% fragmentation, reorganize 10-30%"
}

# Get Azure recommendations
get_azure_recommendations() {
    print_header "☁️ Azure SQL Recommendations"
    
    echo -e "${BLUE}Fetching recommendations from Azure Advisor...${NC}"
    echo ""
    
    # Get resource ID
    RESOURCE_ID=$(az sql db show \
        --server "$SERVER" \
        --name "$DATABASE" \
        --resource-group "$(az sql server show --name "$SERVER" --query resourceGroup -o tsv)" \
        --query id -o tsv)
    
    # Get recommendations
    az advisor recommendation list \
        --query "[?contains(properties.resourceMetadata.resourceId, '$DATABASE')].{Category:properties.category, Impact:properties.impact, Problem:properties.shortDescription.problem, Solution:properties.shortDescription.solution}" \
        -o table
    
    echo ""
    echo -e "${YELLOW}💡 Recommendation:${NC} Review and apply Azure Advisor recommendations"
}

# Main execution
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   SQL Performance Analyzer${NC}"
echo -e "${BLUE}   Server: ${SERVER}.database.windows.net${NC}"
echo -e "${BLUE}   Database: ${DATABASE}${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

case "$ACTION" in
    slow-queries)
        analyze_slow_queries
        ;;
    missing-indexes)
        analyze_missing_indexes
        ;;
    index-usage)
        analyze_index_usage
        ;;
    table-sizes)
        analyze_table_sizes
        ;;
    blocking)
        check_blocking
        ;;
    statistics)
        get_database_statistics
        ;;
    fragmentation)
        check_fragmentation
        ;;
    recommendations)
        get_azure_recommendations
        ;;
    all)
        get_database_statistics
        analyze_slow_queries
        analyze_missing_indexes
        analyze_index_usage
        analyze_table_sizes
        check_fragmentation
        check_blocking
        get_azure_recommendations
        ;;
    *)
        echo -e "${RED}Error: Unknown action '$ACTION'${NC}"
        show_help
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}   Analysis complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [[ -n "$OUTPUT_FILE" ]]; then
    echo -e "${CYAN}Report saved to: $OUTPUT_FILE${NC}"
fi
