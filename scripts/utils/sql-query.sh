#!/bin/bash
# SQL Query Executor for Azure SQL Databases
# Ejecuta consultas SQL contra bases de datos Azure SQL
# Author: Azure Architect Pro Agent
# Date: 2025-12-26

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Default values
OUTPUT_FORMAT="table"
TIMEOUT=30
QUERY_FILE=""
QUERY_STRING=""

# Help function
show_help() {
    cat << EOF
${BLUE}SQL Query Executor for Azure SQL Databases${NC}

${CYAN}Usage:${NC}
    $0 [OPTIONS]

${CYAN}Options:${NC}
    -s, --server SERVER         Azure SQL Server name (without .database.windows.net)
    -d, --database DATABASE     Database name
    -u, --username USERNAME     SQL authentication username (optional if using AAD)
    -p, --password PASSWORD     SQL authentication password (optional if using AAD)
    -q, --query QUERY           SQL query string
    -f, --file FILE             SQL query file
    -o, --output FORMAT         Output format: table, json, csv, tsv (default: table)
    -t, --timeout SECONDS       Query timeout in seconds (default: 30)
    --aad                       Use Azure AD authentication (recommended)
    --analytics                 Run query analytics (explain plan)
    -h, --help                  Show this help message

${CYAN}Examples:${NC}
    # Execute query with AAD authentication
    $0 --server myserver --database mydb --aad --query "SELECT TOP 10 * FROM Users"

    # Execute query from file
    $0 -s myserver -d mydb --aad -f query.sql -o json

    # Execute with SQL authentication
    $0 -s myserver -d mydb -u sqladmin -p 'MyPassword123!' -q "SELECT COUNT(*) FROM Orders"

    # Get query execution plan
    $0 -s myserver -d mydb --aad -q "SELECT * FROM Sales WHERE Date > '2024-01-01'" --analytics

${CYAN}Environment Variables:${NC}
    AZURE_SQL_SERVER            Default SQL server name
    AZURE_SQL_DATABASE          Default database name
    AZURE_SQL_USERNAME          Default SQL username
    AZURE_SQL_PASSWORD          Default SQL password

EOF
}

# Parse arguments
USE_AAD=false
RUN_ANALYTICS=false
SERVER="${AZURE_SQL_SERVER:-}"
DATABASE="${AZURE_SQL_DATABASE:-}"
USERNAME="${AZURE_SQL_USERNAME:-}"
PASSWORD="${AZURE_SQL_PASSWORD:-}"

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
        -u|--username)
            USERNAME="$2"
            shift 2
            ;;
        -p|--password)
            PASSWORD="$2"
            shift 2
            ;;
        -q|--query)
            QUERY_STRING="$2"
            shift 2
            ;;
        -f|--file)
            QUERY_FILE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --aad)
            USE_AAD=true
            shift
            ;;
        --analytics)
            RUN_ANALYTICS=true
            shift
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
if [[ -z "$SERVER" ]]; then
    echo -e "${RED}Error: Server name is required${NC}"
    show_help
    exit 1
fi

if [[ -z "$DATABASE" ]]; then
    echo -e "${RED}Error: Database name is required${NC}"
    show_help
    exit 1
fi

# Determine query source
if [[ -n "$QUERY_FILE" ]]; then
    if [[ ! -f "$QUERY_FILE" ]]; then
        echo -e "${RED}Error: Query file not found: $QUERY_FILE${NC}"
        exit 1
    fi
    QUERY_STRING=$(cat "$QUERY_FILE")
elif [[ -z "$QUERY_STRING" ]]; then
    echo -e "${RED}Error: Query is required (use -q or -f)${NC}"
    show_help
    exit 1
fi

# Build connection string
CONNECTION_STRING="${SERVER}.database.windows.net"

# Check if sqlcmd is installed
if ! command -v sqlcmd &> /dev/null; then
    echo -e "${YELLOW}⚠ sqlcmd not found. Installing mssql-tools...${NC}"
    
    # Add Microsoft repo
    curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
    curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
    sudo apt-get update
    sudo ACCEPT_EULA=Y apt-get install -y mssql-tools unixodbc-dev
    
    # Add to PATH
    export PATH="$PATH:/opt/mssql-tools/bin"
    echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
fi

# Prepare sqlcmd command
SQLCMD_ARGS="-S $CONNECTION_STRING -d $DATABASE -t $TIMEOUT"

if [[ "$USE_AAD" == true ]]; then
    # Use Azure AD authentication
    echo -e "${BLUE}🔐 Using Azure AD authentication...${NC}"
    
    # Get access token
    ACCESS_TOKEN=$(az account get-access-token --resource https://database.windows.net/ --query accessToken -o tsv)
    
    if [[ -z "$ACCESS_TOKEN" ]]; then
        echo -e "${RED}Error: Failed to get Azure AD access token${NC}"
        echo -e "${YELLOW}Make sure you're logged in: az login${NC}"
        exit 1
    fi
    
    SQLCMD_ARGS="$SQLCMD_ARGS -G -P $ACCESS_TOKEN"
else
    # Use SQL authentication
    if [[ -z "$USERNAME" ]] || [[ -z "$PASSWORD" ]]; then
        echo -e "${RED}Error: Username and password required for SQL authentication${NC}"
        echo -e "${YELLOW}Use --aad for Azure AD authentication (recommended)${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}🔐 Using SQL authentication...${NC}"
    SQLCMD_ARGS="$SQLCMD_ARGS -U $USERNAME -P $PASSWORD"
fi

# Set output format
case $OUTPUT_FORMAT in
    table)
        SQLCMD_ARGS="$SQLCMD_ARGS -Y 50"
        ;;
    json)
        QUERY_STRING="SELECT * FROM OPENJSON((SELECT ($QUERY_STRING) FOR JSON PATH))"
        ;;
    csv)
        SQLCMD_ARGS="$SQLCMD_ARGS -s, -W"
        ;;
    tsv)
        SQLCMD_ARGS="$SQLCMD_ARGS -s\t -W"
        ;;
esac

# Execute query
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}▶ Executing query on ${SERVER}.database.windows.net/${DATABASE}${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [[ "$RUN_ANALYTICS" == true ]]; then
    echo -e "${YELLOW}📊 Query Analytics Mode${NC}"
    echo ""
    
    # Get execution plan
    PLAN_QUERY="SET SHOWPLAN_XML ON; $QUERY_STRING"
    echo "$PLAN_QUERY" | sqlcmd $SQLCMD_ARGS -y 0 > /tmp/query_plan.xml 2>&1
    
    echo -e "${BLUE}Execution Plan:${NC}"
    cat /tmp/query_plan.xml | grep -v "^$"
    echo ""
    
    # Get statistics
    STATS_QUERY="SET STATISTICS TIME ON; SET STATISTICS IO ON; $QUERY_STRING"
    echo "$STATS_QUERY" | sqlcmd $SQLCMD_ARGS -y 0
else
    # Execute query
    echo "$QUERY_STRING" | sqlcmd $SQLCMD_ARGS -y 0
fi

EXIT_CODE=$?

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [[ $EXIT_CODE -eq 0 ]]; then
    echo -e "${GREEN}✓ Query executed successfully${NC}"
else
    echo -e "${RED}✗ Query execution failed with exit code $EXIT_CODE${NC}"
fi

exit $EXIT_CODE
