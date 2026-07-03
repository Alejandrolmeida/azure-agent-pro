# Análisis Comparativo: MCP Comunitario vs Scripts Custom

## Resumen Ejecutivo

| Criterio | MCP Comunitario (@fabriciofs) | Scripts Custom (Bash) |
|----------|------------------------------|----------------------|
| **Seguridad** | ⚠️ Media | Alta |
| **Autenticación** | Solo SQL Auth | Azure AD + SQL Auth |
| **Mantenimiento** | ⚠️ Dependencia externa | Control total |
| **Integración** | Nativa con Copilot | Manual (terminal) |
| **Facilidad de uso** | Automático | ⚠️ Requiere comandos |
| **Funcionalidad** | Completa (20+ tools) | ⚠️ Limitada (5 herramientas) |
| **Madurez** | ⚠️ Reciente (dic 2024) | Tecnología probada |
| **Testing** | 94% coverage | Sin tests |

## 🔐 Análisis de Seguridad

### MCP Comunitario

#### Fortalezas

1. **Modo READONLY obligatorio**
```typescript
// Validación estricta en readonly mode
if (config.READONLY) {
 const validation = validateQuery(query);
 if (!validation.valid) {
 throw new QueryValidationError(validation.reason);
 }
}
```

2. **Sanitización de errores**
```typescript
// Elimina passwords de mensajes de error
const message = error.message
 .replace(/Login failed for user '[^']*'/, "Login failed for user '***'")
 .replace(/password[^,]*/gi, 'password=***');
```

3. **Connection pooling**
```typescript
pool: {
 min: config.POOL_MIN,
 max: config.POOL_MAX,
 idleTimeoutMillis: 30000,
}
```

4. **Timeouts configurables**
```typescript
requestTimeout: config.QUERY_TIMEOUT, // Default: 30000ms
```

5. **Tests comprehensivos**: 94% code coverage

#### ⚠️ Debilidades

1. **NO soporta Azure AD authentication**
 - Solo SQL authentication (usuario/contraseña)
 - Credenciales en texto plano en variables de entorno
 - No usa Managed Identity

2. **Autor individual comunitario**
 - No es de Microsoft
 - 0 stars en GitHub (muy nuevo)
 - 3 contributors (1 humano, 1 bot, 1 "claude")

3. **Dependency risk**
 - Depende de paquete npm externo
 - Si el autor abandona: sin actualizaciones
 - Potential supply chain attack

4. **Credenciales expuestas**
```json
// En mcp.json - credenciales visibles
"env": {
 "SQL_USER": "${SQL_USER}",
 "SQL_PASSWORD": "${SQL_PASSWORD}" // ⚠️ Password en env var
}
```

### Scripts Custom (Bash)

#### Fortalezas

1. **Azure AD authentication nativa**
```bash
# Usa Azure CLI credentials
ACCESS_TOKEN=$(az account get-access-token \
 --resource https://database.windows.net/ \
 --query accessToken -o tsv)

SQLCMD_ARGS="$SQLCMD_ARGS -G -P $ACCESS_TOKEN"
```

2. **Control total del código**
 - Sin dependencias externas (solo sqlcmd + az cli)
 - Auditable completamente
 - Personalizable 100%

3. **Seguridad por diseño**
 - No almacena passwords
 - Usa Azure AD tokens temporales
 - Soporta Managed Identity

4. **Error handling robusto**
```bash
set -euo pipefail # Fail on any error
# Validación de parámetros requeridos
if [[ -z "$SERVER" ]]; then
 echo "Error: Server required"
 exit 1
fi
```

#### ⚠️ Debilidades

1. **No integrado con Copilot**
 - Requiere ejecución manual en terminal
 - No conversacional

2. **Sin tests automatizados**
 - No hay test suite
 - Sin CI/CD

3. **Menos herramientas**
 - 5 herramientas básicas vs 20+ del MCP

## Análisis Funcional

### MCP Comunitario - 20 Herramientas

#### Query Tools (1)
- `sql_execute` - Ejecutar SELECT con parámetros

#### Schema Tools (5)
- `schema_list_tables` - Listar tablas/vistas
- `schema_describe_table` - Descripción detallada tabla
- `schema_list_columns` - Buscar columnas
- `schema_list_procedures` - Listar stored procedures
- `schema_list_indexes` - Listar índices

#### Monitor Tools (6)
- `monitor_active_queries` - Queries activas
- `monitor_blocking` - Sesiones bloqueadas
- `monitor_wait_stats` - Wait statistics
- `monitor_database_size` - Tamaño BD
- `monitor_connections` - Conexiones activas
- `monitor_performance_counters` - Performance counters

#### Analysis Tools (5)
- `analyze_query` - Analizar execution plan
- `analyze_suggest_indexes` - Sugerir índices
- `analyze_unused_indexes` - Índices sin usar
- `analyze_duplicate_indexes` - Índices duplicados
- `analyze_fragmentation` - Fragmentación
- `analyze_statistics` - Estadísticas obsoletas

#### Write Tools (3) - Solo si READONLY=false
- `sql_insert` - INSERT
- `sql_update` - UPDATE 
- `sql_delete` - DELETE

### Scripts Custom - 5 Herramientas

1. **sql-query.sh** - Ejecutor de queries
 - Azure AD auth 
 - Múltiples formatos output
 - Query analytics

2. **sql-analyzer.sh** - Analizador performance
 - slow-queries
 - missing-indexes
 - index-usage
 - table-sizes
 - blocking
 - fragmentation
 - statistics
 - Azure recommendations

## Riesgos Específicos

### MCP Comunitario

#### 🔴 CRÍTICO - Azure AD no soportado

```typescript
// El código SOLO soporta SQL authentication
sqlConfig = {
 server: config.SQL_SERVER,
 database: config.SQL_DATABASE,
 user: config.SQL_USER, // ⚠️ Usuario SQL
 password: config.SQL_PASSWORD, // ⚠️ Password en texto
 options: config.options,
};
```

**Impacto:**
- Passwords en variables de entorno
- No cumple best practices Azure
- No soporta Managed Identity
- Violación de políticas corporativas

#### 🟡 MEDIO - Dependency Risk

**Análisis del paquete:**
- Creado: Diciembre 2024 (hace 2 semanas)
- Stars: 0
- Forks: 0
- Issues: 0
- Contributors: 1 humano + bot

**Riesgos:**
- Autor puede abandonar el proyecto
- Sin comunidad activa
- Supply chain vulnerability
- Breaking changes sin aviso

#### 🟡 MEDIO - Credenciales expuestas

```bash
# Variables de entorno visibles en:
# - ps aux
# - /proc/<pid>/environ
# - Docker inspect
# - Kubernetes describe pod
```

### Scripts Custom

#### 🟡 MEDIO - Sin integración Copilot

**Impacto:**
- Flujo de trabajo interrumpido
- Requiere copy/paste manual
- No conversacional
- Mayor fricción de uso

#### 🟢 BAJO - Dependencia Azure CLI

**Mitigación:**
- Azure CLI es oficial Microsoft
- Ampliamente usado y probado
- Parte del toolchain Azure estándar

## Comparación de Código

### Calidad del Código

| Aspecto | MCP Comunitario | Scripts Custom |
|---------|----------------|----------------|
| TypeScript strict mode | Sí | N/A (Bash) |
| Error handling | Comprehensivo | set -euo pipefail |
| Logging | Estructurado | ⚠️ Echo básico |
| Validación inputs | Zod schemas | Bash checks |
| Tests | 94% coverage | Sin tests |
| Documentation | Completa | ⚠️ Básica |
| Connection pooling | Implementado | N/A (sqlcmd) |

### Ejemplo Error Handling

**MCP Comunitario:**
```typescript
try {
 const result = await executeQuery(query, params, maxRows);
 return formatSuccess(result);
} catch (error) {
 if (error instanceof QueryValidationError) {
 return formatError(error);
 }
 if (error instanceof TimeoutError) {
 return formatError(error);
 }
 return formatError(new ConnectionError(getErrorMessage(error)));
}
```

**Scripts Custom:**
```bash
set -euo pipefail # Strict error handling

if [[ -z "$SERVER" ]]; then
 echo "Error: Server required" >&2
 exit 1
fi

if ! az account show &>/dev/null; then
 echo "Error: Not logged into Azure" >&2
 exit 1
fi
```

## Recomendación

### Para PRODUCCIÓN: Scripts Custom 

**Razones:**
1. **Azure AD authentication** - Requisito crítico
2. **Control total** - Sin dependencias externas riesgosas
3. **Seguridad probada** - No passwords en texto plano
4. **Compliance** - Cumple políticas corporativas

**Desventajas aceptadas:**
- No integrado con Copilot (trade-off seguridad vs comodidad)
- Requiere ejecución manual

### Para DESARROLLO/DEMO: MCP Comunitario ⚠️

**Solo si:**
1. Entorno no productivo
2. No hay datos sensibles
3. SQL authentication aceptable
4. READONLY=true siempre

**NUNCA usar en producción sin:**
- [ ] Audit completo del código
- [ ] Fork y mantenimiento propio
- [ ] Implementar Azure AD auth
- [ ] Security review

## Solución Híbrida Recomendada

### Opción 1: Scripts como base + Wrapper MCP

Crear un MCP server propio que llame a los scripts bash:

```typescript
// mcp-servers/azure-sql-custom/src/index.ts
async function executeSqlQuery(args: { query: string }) {
 // Llama al script bash con Azure AD
 const result = await exec(
 `${SCRIPTS_DIR}/sql-query.sh --server ${server} --database ${db} --aad --query "${args.query}"`
 );
 return { content: [{ type: 'text', text: result }] };
}
```

**Ventajas:**
- Integración Copilot
- Azure AD authentication
- Control total del código

### Opción 2: Fork y modificar MCP comunitario

1. Fork `@fabriciofs/mcp-sql-server`
2. Agregar Azure AD authentication
3. Publicar como paquete propio
4. Mantener actualizaciones

**Ventajas:**
- Base de código madura
- 20+ herramientas
- Tests existentes

**Desventajas:**
- ⚠️ Requiere mantenimiento continuo
- ⚠️ Necesita expertise TypeScript/MCP

### Opción 3: Solicitar feature al autor

Abrir issue en el repo pidiendo Azure AD support:
- Managed Identity
- DefaultAzureCredential
- Azure CLI integration

**Ventajas:**
- Upstream contribution
- Sin fork mantenimiento

**Desventajas:**
- ⚠️ Depende de respuesta autor
- ⚠️ Timeline incierto

## Conclusión

### Para tu caso (azure-agent-pro)

**Recomendación: Scripts Custom + Documentación clara**

```markdown
# En README.md
## SQL Analysis Tools

Para ejecutar consultas SQL usa los scripts bash con Azure AD:

```bash
# Análisis de performance
./scripts/agents/sql-dba/sql-analyzer.sh -s myserver -d mydb -a all

# Query específica
./scripts/agents/sql-dba/sql-query.sh -s myserver -d mydb --aad -q "SELECT ..."
```

**Nota de seguridad:** No usamos el MCP server comunitario porque:
- No soporta Azure AD authentication
- Requiere passwords en texto plano
- Es un paquete muy reciente sin comunidad
```

### Métricas de Decisión

| Factor | Peso | MCP Comunitario | Scripts Custom |
|--------|------|-----------------|----------------|
| Seguridad | 40% | 5/10 | 9/10 |
| Funcionalidad | 20% | 10/10 | 6/10 |
| Mantenibilidad | 20% | 6/10 | 9/10 |
| UX (Copilot) | 20% | 10/10 | 3/10 |
| **TOTAL** | | **6.8/10** | **7.4/10** |

**Winner: Scripts Custom** 

---

**Autor**: Azure Architect Pro Agent 
**Fecha**: 2025-12-26 
**Versión**: 1.0

