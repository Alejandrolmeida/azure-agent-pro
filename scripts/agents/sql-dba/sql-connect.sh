#!/bin/bash
# Wrapper script for SQL queries with environment variables support
# Usage: 
#   export AZURE_SQL_SERVER=server.database.windows.net
#   export AZURE_SQL_DATABASE=mydb
#   export AZURE_SQL_USERNAME=user
#   export AZURE_SQL_PASSWORD=pass
#   ./sql-connect.sh -q "SELECT @@VERSION"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_QUERY_PY="${SCRIPT_DIR}/sql-query.py"

# Get credentials from environment or parameters
SERVER="${AZURE_SQL_SERVER:-}"
DATABASE="${AZURE_SQL_DATABASE:-}"
USERNAME="${AZURE_SQL_USERNAME:-}"
PASSWORD="${AZURE_SQL_PASSWORD:-}"
USE_AAD=false
OUTPUT_FORMAT="table"
QUERY=""

# Parse arguments
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
            QUERY="$2"
            shift 2
            ;;
        --aad)
            USE_AAD=true
            shift
            ;;
        -o|--output)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -h|--help)
            cat << EOF
SQL Query Wrapper Script

Usage: $0 [options]

Options:
  -s, --server <server>      SQL Server name (or use AZURE_SQL_SERVER env var)
  -d, --database <db>        Database name (or use AZURE_SQL_DATABASE env var)
  -u, --username <user>      SQL username (or use AZURE_SQL_USERNAME env var)
  -p, --password <pass>      SQL password (or use AZURE_SQL_PASSWORD env var)
  -q, --query <sql>          SQL query to execute
  --aad                      Use Azure AD authentication (requires az login)
  -o, --output <format>      Output format: table or json (default: table)
  -h, --help                 Show this help message

Environment Variables:
  AZURE_SQL_SERVER           Default SQL Server
  AZURE_SQL_DATABASE         Default database
  AZURE_SQL_USERNAME         Default username (for SQL auth)
  AZURE_SQL_PASSWORD         Default password (for SQL auth)

Examples:
  # SQL Authentication
  $0 -s server.database.windows.net -d mydb -u user -p pass -q "SELECT @@VERSION"
  
  # Azure AD Authentication
  $0 -s server.database.windows.net -d mydb --aad -q "SELECT @@VERSION"
  
  # Using environment variables
  export AZURE_SQL_SERVER=server.database.windows.net
  export AZURE_SQL_DATABASE=mydb
  export AZURE_SQL_USERNAME=user
  export AZURE_SQL_PASSWORD=pass
  $0 -q "SELECT * FROM sys.tables"
EOF
            exit 0
            ;;
        *)
            echo "Error: Unknown option $1"
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$SERVER" ]]; then
    echo "Error: Server is required (-s or AZURE_SQL_SERVER)"
    exit 1
fi

if [[ -z "$DATABASE" ]]; then
    echo "Error: Database is required (-d or AZURE_SQL_DATABASE)"
    exit 1
fi

if [[ -z "$QUERY" ]]; then
    echo "Error: Query is required (-q)"
    exit 1
fi

# Build Python command
CMD=(python3 "$SQL_QUERY_PY" -s "$SERVER" -d "$DATABASE" -q "$QUERY" -o "$OUTPUT_FORMAT")

if [[ "$USE_AAD" == true ]]; then
    CMD+=(--aad)
else
    if [[ -z "$USERNAME" ]] || [[ -z "$PASSWORD" ]]; then
        echo "Error: Username and password required for SQL authentication"
        echo "Use --aad for Azure AD authentication or set AZURE_SQL_USERNAME and AZURE_SQL_PASSWORD"
        exit 1
    fi
    CMD+=(-u "$USERNAME" -p "$PASSWORD")
fi

# Execute
exec "${CMD[@]}"
