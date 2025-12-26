# Configuración SQL Server MCP

El agente ahora puede ejecutar consultas SQL directamente usando el servidor MCP oficial `@fabriciofs/mcp-sql-server`.

## ✅ Ventajas

- **Sin instalación manual**: Se instala automáticamente con `npx` al usarse
- **Sin compilación**: No requiere `npm install` ni `npm build`
- **Igual que los otros servidores**: Funciona como azure-mcp, github-mcp, etc.

## 🔧 Configuración

### 1. Variables de Entorno

Añade estas variables a tu archivo `.env` o configúralas en tu sistema:

```bash
# Azure SQL Database
SQL_SERVER=tu-servidor.database.windows.net
SQL_DATABASE=tu-base-de-datos
SQL_USER=tu-usuario
SQL_PASSWORD=tu-password

# O para SQL Server local
SQL_SERVER=localhost
SQL_DATABASE=AdventureWorks
SQL_USER=sa
SQL_PASSWORD=YourPassword123
```

### 2. El servidor ya está registrado en `mcp.json`

```json
{
  "sql-server-mcp": {
    "command": "npx",
    "args": ["-y", "@fabriciofs/mcp-sql-server"],
    "env": {
      "SQL_SERVER": "${SQL_SERVER}",
      "SQL_DATABASE": "${SQL_DATABASE}",
      "SQL_USER": "${SQL_USER}",
      "SQL_PASSWORD": "${SQL_PASSWORD}"
    }
  }
}
```

## 🚀 Uso con Copilot

Una vez configuradas las variables de entorno, simplemente habla con Copilot:

```
Usuario: "Muéstrame los 10 clientes más recientes"
Copilot: [Ejecuta automáticamente la consulta SQL]

Usuario: "¿Cuántos pedidos hay por estado?"  
Copilot: [Ejecuta SELECT Status, COUNT(*) FROM Orders GROUP BY Status]

Usuario: "Analiza las ventas del último mes"
Copilot: [Ejecuta consultas y proporciona análisis]
```

## 🔍 Capacidades del Servidor

El servidor MCP oficial incluye:
- ✅ Ejecutar consultas SQL (SELECT, INSERT, UPDATE, DELETE)
- ✅ Obtener schema de tablas
- ✅ Listar tablas y vistas
- ✅ Análisis de resultados
- ✅ Manejo de errores

## 🐛 Troubleshooting

### Error: Cannot connect to SQL Server

**Verifica:**
1. Variables de entorno configuradas correctamente
2. Firewall permite conexión al servidor
3. Credenciales son correctas
4. SQL Server está accesible desde tu red

```bash
# Probar conexión con Azure SQL
az sql db show --server tu-servidor --name tu-bd

# O con sqlcmd
sqlcmd -S tu-servidor.database.windows.net -d tu-bd -U tu-usuario -P tu-password -Q "SELECT @@VERSION"
```

### El servidor no aparece en Copilot

1. Verifica que las variables de entorno estén configuradas
2. Reinicia VS Code
3. Verifica que `mcp.json` esté en la raíz del workspace

### Azure SQL requiere autenticación adicional

Si usas Azure SQL con autenticación Azure AD, configura tu cadena de conexión en las variables:

```bash
SQL_SERVER=tu-servidor.database.windows.net
SQL_DATABASE=tu-bd
# Para Azure AD, el servidor puede requerir configuración adicional
```

## 📚 Alternativas

Si necesitas características específicas de Azure AD o análisis avanzado, puedes usar los scripts bash que también están disponibles:

```bash
# Para queries con Azure AD auth
./scripts/utils/sql-query.sh --server myserver --database mydb --aad --query "SELECT ..."

# Para análisis de rendimiento
./scripts/utils/sql-analyzer.sh -s myserver -d mydb -a all
```

## 🔗 Referencias

- [Servidor MCP SQL Server](https://www.npmjs.com/package/@fabriciofs/mcp-sql-server)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [Azure SQL Database](https://docs.microsoft.com/azure/sql-database/)
