# Azure SQL Database Connection Guide

## Overview

This guide explains how to connect and query Azure SQL Database using the provided Python and Bash scripts with support for both **Azure AD authentication** and **SQL authentication**.

## Connection Prerequisites

**Required:**
- Azure SQL Database (Single DB, Elastic Pool, or Managed Instance)
- ODBC Driver 18 for SQL Server installed
- Python 3.8+ with pyodbc module
- Azure CLI (for Azure AD authentication)
- Firewall rule configured for your IP

## Tools Available

### 1. Python Script: `sql-query.py`
**Location**: `scripts/utils/sql-query.py`

Full-featured Python script with support for:
- ✅ Azure AD authentication (via Azure CLI tokens)
- ✅ SQL authentication (username/password)
- ✅ Multiple output formats (table, json)
- ✅ Proper ODBC Driver 18 integration
- ✅ Handles long Azure AD tokens correctly

**Usage:**

```bash
# SQL Authentication
python3 scripts/utils/sql-query.py \
  -s server.database.windows.net \
  -d database_name \
  -u username \
  -p password \
  -q "SELECT @@VERSION" \
  -o table

# Azure AD Authentication
python3 scripts/utils/sql-query.py \
  -s server.database.windows.net \
  -d database_name \
  --aad \
  -q "SELECT @@VERSION" \
  -o json
```

**Parameters:**
- `-s, --server`: Server name (e.g., server.database.windows.net)
- `-d, --database`: Database name
- `-q, --query`: SQL query to execute
- `-u, --username`: SQL username (for SQL auth)
- `-p, --password`: SQL password (for SQL auth)
- `--aad`: Use Azure AD authentication (requires `az login`)
- `-o, --output`: Output format (`table` or `json`)

### 2. Bash Wrapper: `sql-connect.sh`
**Location**: `scripts/utils/sql-connect.sh`

Convenient wrapper that supports environment variables.

**Usage with Environment Variables:**

```bash
# Set environment variables (recommended for security)
export AZURE_SQL_SERVER="your-server.database.windows.net"
export AZURE_SQL_DATABASE="your-database"
export AZURE_SQL_USERNAME="your-username"
export AZURE_SQL_PASSWORD="your-password"

# Execute queries
./scripts/utils/sql-connect.sh -q "SELECT TOP 10 * FROM sys.tables"
```

**Usage with Parameters:**

```bash
./scripts/utils/sql-connect.sh \
  -s server.database.windows.net \
  -d database_name \
  -u username \
  -p password \
  -q "SELECT @@VERSION"
```

## Prerequisites

### Required Software
1. **Python 3** (already installed)
2. **pyodbc** (auto-installed by scripts)
3. **ODBC Driver 18 for SQL Server** (✅ installed)
4. **Azure CLI** (for Azure AD auth only)

### Verify Installation

```bash
# Check ODBC Driver
odbcinst -q -d | grep "ODBC Driver 18"

# Check Azure CLI (for Azure AD auth)
az --version
```

## Authentication Methods

### Method 1: SQL Authentication
**Usage:**
- Username: SQL login user
- Password: SQL password

**Pros:**
- ✅ Simple and direct
- ✅ No Azure CLI required
- ✅ Works everywhere

**Cons:**
- ⚠️ Password management required
- ⚠️ Password visible in process list if not using env vars

### Method 2: Azure AD Authentication
**Prerequisites:**
```bash
az login --tenant d47ea4c6-fea4-4acb-9353-8680f2f157d6
```

**Pros:**
- ✅ No password storage
- ✅ Uses Azure AD identity
- ✅ Supports MFA
- ✅ Audit trail via Azure AD

**Cons:**
- ⚠️ User must exist in database with proper permissions
- ⚠️ Requires Azure CLI authentication

## Security Best Practices

### 1. Use Environment Variables
**Never hardcode credentials in scripts:**

```bash
# Create a .env file (add to .gitignore!)
cat > ~/.azure-sql-env << 'EOF'
export AZURE_SQL_SERVER="your-server.database.windows.net"
export AZURE_SQL_DATABASE="your-database"
export AZURE_SQL_USERNAME="your-username"
export AZURE_SQL_PASSWORD="your-password"
EOF

# Source it before use
source ~/.azure-sql-env
```

### 2. File Permissions
```bash
chmod 600 ~/.azure-sql-env
```

### 3. Azure Key Vault (Recommended)
For production environments, store credentials in Azure Key Vault:

```bash
# Store password in Key Vault
az keyvault secret set \
  --vault-name your-keyvault \
  --name sql-password \
  --value "your-password"

# Retrieve in script
PASSWORD=$(az keyvault secret show \
  --vault-name your-keyvault \
  --name sql-password \
  --query value -o tsv)
```

## Common Queries

### Database Information
```bash
./scripts/utils/sql-connect.sh -q "
SELECT 
    DB_NAME() as DatabaseName,
    CAST(SUM(CAST(FILEPROPERTY(name, 'SpaceUsed') AS bigint) * 8192. / 1024 / 1024 / 1024) AS DECIMAL(10,2)) as UsedSpaceGB,
    CAST(SUM(CAST(size AS bigint) * 8192. / 1024 / 1024 / 1024) AS DECIMAL(10,2)) as AllocatedSpaceGB
FROM sys.database_files WHERE type = 0
"
```

### Top 10 Largest Tables
```bash
./scripts/utils/sql-connect.sh -q "
SELECT TOP 10
    SCHEMA_NAME(t.schema_id) + '.' + t.name as TableName,
    CAST(SUM(p.rows) AS DECIMAL(18,0)) as TotalRows,
    CAST(SUM(a.total_pages) * 8 / 1024.0 / 1024.0 AS DECIMAL(10,2)) as SizeGB
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
GROUP BY t.schema_id, t.name
ORDER BY SUM(a.total_pages) DESC
"
```

### Active Connections
```bash
./scripts/utils/sql-connect.sh -q "
SELECT 
    COUNT(*) as TotalConnections,
    COUNT(CASE WHEN status = 'running' THEN 1 END) as ActiveQueries
FROM sys.dm_exec_sessions
WHERE is_user_process = 1
"
```

## Troubleshooting

### Issue: Firewall Blocked
**Error**: `Client with IP address 'x.x.x.x' is not allowed to access the server`

**Solution:**
```bash
# Add your IP to firewall
az sql server firewall-rule create \
  --resource-group your-resource-group \
  --server your-server \
  --name "AllowMyIP-$(date +%Y%m%d)" \
  --start-ip-address YOUR_IP \
  --end-ip-address YOUR_IP
```

### Issue: Login Failed (Azure AD)
**Error**: `Login failed for user '<token-identified principal>'`

**Solution**: User needs to be created in database:
```sql
-- Connect as admin and run:
CREATE USER [user@domain.com] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [user@domain.com];
```

### Issue: ODBC Driver Not Found
**Error**: `Data source name not found`

**Solution:**
```bash
# Install ODBC Driver 18
curl https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
sudo apt-get update
sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18
```

## Integration with GitHub Copilot Agents

### Azure_SQL_DBA Agent
The `Azure_SQL_DBA.agent.md` can now use these tools for:

1. **Performance Analysis**
   ```bash
   python3 scripts/utils/sql-query.py -s ... -d ... -u ... -p ... \
     -q "SELECT * FROM sys.dm_exec_query_stats ORDER BY total_elapsed_time DESC"
   ```

2. **Index Recommendations**
3. **Blocking Detection**
4. **Space Management**
5. **FinOps Analysis**

### Environment Setup for Agents
Create a secure environment file that agents can source:

```bash
# ~/.azure-sql-dba.env
export AZURE_SQL_SERVER="your-server.database.windows.net"
export AZURE_SQL_DATABASE="your-database"
export AZURE_SQL_USERNAME="your-username"
export AZURE_SQL_PASSWORD="<from-keyvault>"
```

## Performance Considerations

### Connection Pooling
For multiple queries, consider using a connection pool:

```python
import pyodbc
conn = pyodbc.connect(connection_string, autocommit=True)
# Reuse connection for multiple queries
```

### Query Timeouts
Default timeout is 30 seconds. For long-running queries:

```python
cursor.execute(query)
cursor.connection.timeout = 300  # 5 minutes
```

### Output Limits
For large result sets, use pagination:

```sql
SELECT * FROM large_table
ORDER BY id
OFFSET 0 ROWS FETCH NEXT 1000 ROWS ONLY
```

## Next Steps

1. ✅ Connection established and verified
2. ✅ Firewall rule configured
3. ✅ Python and Bash scripts ready
4. ⏭️ Integrate with sql-analyzer.sh for automated diagnostics
5. ⏭️ Create saved query templates for common DBA tasks
6. ⏭️ Set up automated monitoring queries
7. ⏭️ Configure alerts for performance issues

## Additional Resources

- [Azure SQL Database Documentation](https://docs.microsoft.com/azure/azure-sql/)
- [ODBC Driver for SQL Server](https://docs.microsoft.com/sql/connect/odbc/)
- [Azure SQL Performance Best Practices](https://docs.microsoft.com/azure/azure-sql/database/performance-guidance)
- [DMVs Reference](https://docs.microsoft.com/sql/relational-databases/system-dynamic-management-views/)
