#!/usr/bin/env python3
"""
Azure SQL Database connection script supporting both Azure AD and SQL authentication.
Uses pyodbc with Azure CLI access tokens or SQL credentials.
"""

import argparse
import os
import struct
import subprocess
import sys
import json

def install_pyodbc():
    """Install pyodbc if not available."""
    try:
        import pyodbc
        return pyodbc
    except ImportError:
        print('📦 Installing pyodbc...')
        subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'pyodbc', '--quiet'])
        import pyodbc
        return pyodbc

def get_azure_token():
    """Get Azure AD access token from Azure CLI."""
    try:
        result = subprocess.run(
            ['az', 'account', 'get-access-token', '--resource', 'https://database.windows.net/', '--query', 'accessToken', '-o', 'tsv'],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f'❌ Error getting Azure AD token: {e}')
        sys.exit(1)

def connect_and_query(server, database, query, use_aad=False, username=None, password=None, output_format='table'):
    """Connect to Azure SQL Database and execute query."""
    pyodbc = install_pyodbc()
    
    driver = '{ODBC Driver 18 for SQL Server}'
    
    if use_aad:
        # Azure AD authentication
        print('🔐 Using Azure AD authentication...')
        token = get_azure_token()
        
        # Encode token correctly for ODBC (SQL_COPT_SS_ACCESS_TOKEN=1256)
        token_bytes = token.encode('UTF-16-LE')
        token_struct = struct.pack('<I', len(token_bytes)) + token_bytes
        
        conn_str = f'DRIVER={driver};SERVER={server};DATABASE={database};Encrypt=yes;TrustServerCertificate=no'
        
        try:
            print(f'🔗 Connecting to {server}/{database}...')
            conn = pyodbc.connect(conn_str, attrs_before={1256: token_struct})
        except Exception as e:
            print(f'❌ Connection error: {e}')
            sys.exit(1)
    else:
        # SQL authentication
        if not username or not password:
            print('❌ Error: Username and password required for SQL authentication')
            print('Use --aad for Azure AD authentication or provide -u/--username and -p/--password')
            sys.exit(1)
        
        print('🔐 Using SQL authentication...')
        conn_str = f'DRIVER={driver};SERVER={server};DATABASE={database};UID={username};PWD={password};Encrypt=yes;TrustServerCertificate=no'
        
        try:
            print(f'🔗 Connecting to {server}/{database}...')
            conn = pyodbc.connect(conn_str)
        except Exception as e:
            print(f'❌ Connection error: {e}')
            sys.exit(1)
    
    # Execute query
    try:
        cursor = conn.cursor()
        print(f'✅ Connected! Executing query...\n')
        cursor.execute(query)
        
        # Format output
        if output_format == 'json':
            # JSON output
            columns = [column[0] for column in cursor.description]
            rows = []
            for row in cursor.fetchall():
                row_dict = {}
                for i, val in enumerate(row):
                    row_dict[columns[i]] = str(val) if val is not None else None
                rows.append(row_dict)
            print(json.dumps(rows, indent=2))
        else:
            # Table output (default)
            columns = [column[0] for column in cursor.description]
            print(' | '.join(columns))
            print('-' * (sum(len(col) for col in columns) + len(columns) * 3 - 2))
            
            for row in cursor.fetchall():
                values = [str(val)[:50] if val is not None else 'NULL' for val in row]
                print(' | '.join(values))
        
        cursor.close()
        conn.close()
        print('\n✅ Query executed successfully!')
        
    except Exception as e:
        print(f'❌ Query execution error: {e}')
        sys.exit(1)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Execute SQL queries on Azure SQL Database with Azure AD or SQL authentication'
    )
    parser.add_argument('-s', '--server', required=True, help='Server name (e.g., server.database.windows.net)')
    parser.add_argument('-d', '--database', required=True, help='Database name')
    parser.add_argument('-q', '--query', required=True, help='SQL query to execute')
    parser.add_argument('--aad', action='store_true', help='Use Azure AD authentication (requires az login)')
    parser.add_argument('-u', '--username', help='SQL username (for SQL auth)')
    parser.add_argument('-p', '--password', help='SQL password (for SQL auth)')
    parser.add_argument('-o', '--output', choices=['table', 'json'], default='table', help='Output format')
    
    args = parser.parse_args()
    
    connect_and_query(
        args.server,
        args.database,
        args.query,
        use_aad=args.aad,
        username=args.username,
        password=args.password,
        output_format=args.output
    )
