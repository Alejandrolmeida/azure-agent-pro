#!/usr/bin/env node

/**
 * Azure SQL Database MCP Server
 * Provides SQL query execution and performance analysis capabilities
 * through Model Context Protocol
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  Tool,
} from '@modelcontextprotocol/sdk/types.js';
import sql from 'mssql';
import { DefaultAzureCredential } from '@azure/identity';
import * as dotenv from 'dotenv';

dotenv.config();

// Configuration interface
interface AzureSqlConfig {
  server: string;
  database: string;
  authentication: {
    type: 'azure-ad' | 'sql';
    username?: string;
    password?: string;
  };
  options: {
    encrypt: boolean;
    trustServerCertificate: boolean;
  };
}

// Connection pool
let pool: sql.ConnectionPool | null = null;

// MCP Server instance
const server = new Server(
  {
    name: 'azure-sql-server',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

/**
 * Get connection configuration from environment
 */
function getConfig(): AzureSqlConfig {
  const server = process.env.AZURE_SQL_SERVER;
  const database = process.env.AZURE_SQL_DATABASE;
  const authType = process.env.AZURE_SQL_AUTH_TYPE || 'azure-ad';

  if (!server || !database) {
    throw new Error('AZURE_SQL_SERVER and AZURE_SQL_DATABASE must be set');
  }

  return {
    server: server.endsWith('.database.windows.net') ? server : `${server}.database.windows.net`,
    database,
    authentication: {
      type: authType as 'azure-ad' | 'sql',
      username: process.env.AZURE_SQL_USERNAME,
      password: process.env.AZURE_SQL_PASSWORD,
    },
    options: {
      encrypt: true,
      trustServerCertificate: false,
    },
  };
}

/**
 * Get or create connection pool
 */
async function getPool(): Promise<sql.ConnectionPool> {
  if (pool && pool.connected) {
    return pool;
  }

  const config = getConfig();
  
  let sqlConfig: sql.config;

  if (config.authentication.type === 'azure-ad') {
    // Azure AD authentication
    const credential = new DefaultAzureCredential();
    const tokenResponse = await credential.getToken('https://database.windows.net/');

    sqlConfig = {
      server: config.server,
      database: config.database,
      authentication: {
        type: 'azure-active-directory-access-token',
        options: {
          token: tokenResponse.token,
        },
      },
      options: config.options,
    };
  } else {
    // SQL authentication
    if (!config.authentication.username || !config.authentication.password) {
      throw new Error('AZURE_SQL_USERNAME and AZURE_SQL_PASSWORD required for SQL auth');
    }

    sqlConfig = {
      server: config.server,
      database: config.database,
      user: config.authentication.username,
      password: config.authentication.password,
      options: config.options,
    };
  }

  pool = await sql.connect(sqlConfig);
  return pool;
}

/**
 * Execute SQL query
 */
async function executeQuery(query: string, timeout: number = 30): Promise<any> {
  const pool = await getPool();
  const request = pool.request();
  request.timeout = timeout * 1000;

  const result = await request.query(query);
  return {
    recordset: result.recordset,
    rowsAffected: result.rowsAffected,
    columns: result.recordset?.columns || {},
  };
}

/**
 * Analyze query performance
 */
async function analyzePerformance(query: string): Promise<any> {
  const pool = await getPool();
  
  // Enable statistics
  await pool.request().query('SET STATISTICS TIME ON');
  await pool.request().query('SET STATISTICS IO ON');
  
  // Get execution plan
  const planResult = await pool.request().query(`SET SHOWPLAN_XML ON; ${query}`);
  
  // Execute actual query
  const execResult = await executeQuery(query);
  
  // Disable statistics
  await pool.request().query('SET STATISTICS TIME OFF');
  await pool.request().query('SET STATISTICS IO OFF');
  
  return {
    executionPlan: planResult.recordset,
    queryResult: execResult,
    timestamp: new Date().toISOString(),
  };
}

/**
 * Get slow queries from last 24 hours
 */
async function getSlowQueries(topN: number = 20): Promise<any> {
  const query = `
    SELECT TOP ${topN}
      qs.execution_count AS executionCount,
      qs.total_worker_time / qs.execution_count AS avgCpuTime,
      qs.total_elapsed_time / qs.execution_count AS avgDuration,
      qs.total_logical_reads / qs.execution_count AS avgLogicalReads,
      SUBSTRING(qt.text, (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(qt.text)
            ELSE qs.statement_end_offset
        END - qs.statement_start_offset)/2) + 1) AS queryText
    FROM sys.dm_exec_query_stats qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
    WHERE qs.creation_time >= DATEADD(day, -1, GETDATE())
    ORDER BY qs.total_elapsed_time / qs.execution_count DESC
  `;
  
  return await executeQuery(query);
}

/**
 * Get missing indexes
 */
async function getMissingIndexes(minImpact: number = 10): Promise<any> {
  const query = `
    SELECT TOP 20
      CONVERT(decimal(18,2), migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans)) AS improvementMeasure,
      mid.statement AS tableName,
      mid.equality_columns AS equalityColumns,
      mid.inequality_columns AS inequalityColumns,
      mid.included_columns AS includedColumns,
      migs.unique_compiles AS uniqueCompiles,
      migs.user_seeks AS userSeeks,
      migs.user_scans AS userScans
    FROM sys.dm_db_missing_index_group_stats migs
    INNER JOIN sys.dm_db_missing_index_groups mig ON migs.group_handle = mig.index_group_handle
    INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
    WHERE migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) > ${minImpact}
    ORDER BY improvementMeasure DESC
  `;
  
  return await executeQuery(query);
}

/**
 * Check for blocking sessions
 */
async function getBlockingSessions(): Promise<any> {
  const query = `
    SELECT 
      blocking.session_id AS blockingSession,
      blocked.session_id AS blockedSession,
      waitstats.wait_type AS waitType,
      waitstats.wait_duration_ms AS waitDurationMs,
      blockingtxt.text AS blockingQuery,
      blockedtxt.text AS blockedQuery
    FROM sys.dm_exec_requests blocked
    INNER JOIN sys.dm_exec_requests blocking ON blocked.blocking_session_id = blocking.session_id
    INNER JOIN sys.dm_os_waiting_tasks waitstats ON blocked.session_id = waitstats.session_id
    CROSS APPLY sys.dm_exec_sql_text(blocking.sql_handle) blockingtxt
    CROSS APPLY sys.dm_exec_sql_text(blocked.sql_handle) blockedtxt
    WHERE blocked.blocking_session_id <> 0
  `;
  
  return await executeQuery(query);
}

// Define available tools
const tools: Tool[] = [
  {
    name: 'execute_sql_query',
    description: 'Execute a SQL query on Azure SQL Database and return results',
    inputSchema: {
      type: 'object',
      properties: {
        query: {
          type: 'string',
          description: 'The SQL query to execute (SELECT, INSERT, UPDATE, DELETE, etc.)',
        },
        timeout: {
          type: 'number',
          description: 'Query timeout in seconds (default: 30)',
          default: 30,
        },
      },
      required: ['query'],
    },
  },
  {
    name: 'analyze_query_performance',
    description: 'Analyze SQL query performance with execution plan and statistics',
    inputSchema: {
      type: 'object',
      properties: {
        query: {
          type: 'string',
          description: 'The SQL query to analyze',
        },
      },
      required: ['query'],
    },
  },
  {
    name: 'get_slow_queries',
    description: 'Get the slowest queries from the last 24 hours',
    inputSchema: {
      type: 'object',
      properties: {
        topN: {
          type: 'number',
          description: 'Number of slow queries to return (default: 20)',
          default: 20,
        },
      },
    },
  },
  {
    name: 'get_missing_indexes',
    description: 'Identify missing indexes that could improve performance',
    inputSchema: {
      type: 'object',
      properties: {
        minImpact: {
          type: 'number',
          description: 'Minimum improvement measure threshold (default: 10)',
          default: 10,
        },
      },
    },
  },
  {
    name: 'check_blocking_sessions',
    description: 'Check for blocked database sessions and identify blocking queries',
    inputSchema: {
      type: 'object',
      properties: {},
    },
  },
];

// Handle tool list requests
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return { tools };
});

// Handle tool execution requests
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case 'execute_sql_query': {
        const { query, timeout = 30 } = args as { query: string; timeout?: number };
        const result = await executeQuery(query, timeout);
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case 'analyze_query_performance': {
        const { query } = args as { query: string };
        const result = await analyzePerformance(query);
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case 'get_slow_queries': {
        const { topN = 20 } = args as { topN?: number };
        const result = await getSlowQueries(topN);
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case 'get_missing_indexes': {
        const { minImpact = 10 } = args as { minImpact?: number };
        const result = await getMissingIndexes(minImpact);
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case 'check_blocking_sessions': {
        const result = await getBlockingSessions();
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    return {
      content: [
        {
          type: 'text',
          text: `Error executing ${name}: ${errorMessage}`,
        },
      ],
      isError: true,
    };
  }
});

// Start the server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  
  console.error('Azure SQL MCP Server running on stdio');
  console.error(`Server: ${process.env.AZURE_SQL_SERVER}`);
  console.error(`Database: ${process.env.AZURE_SQL_DATABASE}`);
}

main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
