# Quick Start: Jupyter + KQL para D365 F&O

Guia practica para ejecutar consultas KQL desde Jupyter Notebook usando Python sobre Log Analytics/Application Insights de Dynamics 365 Finance & Operations.

## Que incluye este repositorio

Este proyecto ya trae un starter listo en:

- observability/d365-fo-observability

Contenido:

- notebooks/d365_fo_observability.ipynb
- queries/ con consultas KQL base
- src/kql_runner.py
- requirements.txt
- .env.example
- script de bootstrap

## Bootstrap en un comando

Desde la raiz del repositorio:

```bash
bash scripts/setup/d365fo-observability-bootstrap.sh
```

El script:

1. Usa (o crea) un entorno Miniconda llamado `aifoundry`.
2. Instala dependencias de requirements.txt.
3. Registra kernel Jupyter en tu usuario.
4. Crea .env si no existe.

Si quieres otro entorno:

```bash
CONDA_ENV_NAME=mi-entorno bash scripts/setup/d365fo-observability-bootstrap.sh
```

## Configuracion minima

1. Edita observability/d365-fo-observability/.env
2. Define LAW_WORKSPACE_ID con el Workspace ID real.
3. Ajusta QUERY_DAYS si quieres otro horizonte de analisis.
4. Opcional: define CLIENT_NAME para identificar exportaciones por cliente.

Ejemplo:

```env
LAW_WORKSPACE_ID=00000000-0000-0000-0000-000000000000
QUERY_DAYS=7
CLIENT_NAME=cliente-demo
APPINSIGHTS_CONNECTION_STRING=
```

## Donde configurar AppInsights del cliente

Hay dos escenarios diferentes:

1. Consultar telemetria existente (este starter):
	- Configura el Workspace ID del cliente en observability/d365-fo-observability/.env.
	- Variable usada: LAW_WORKSPACE_ID.
	- No necesitas APPINSIGHTS_CONNECTION_STRING para consultas KQL con azure-monitor-query.

2. Instrumentar una aplicacion para enviar telemetria:
	- Configura la cadena en APPINSIGHTS_CONNECTION_STRING (por ejemplo en .env o en App Settings del servicio).
	- Esa variable no cambia las consultas KQL del notebook; solo aplica al emisor de telemetria.

## Autenticacion Azure

```bash
az login
az account show --output table
```

Si manejas varias subscriptions:

```bash
az account list --output table
az account set --subscription "NOMBRE_O_ID"
```

## Ejecutar notebook

1. Abre observability/d365-fo-observability/notebooks/d365_fo_observability.ipynb
2. Selecciona kernel: Python (conda:aifoundry) - D365 F&O Observability
3. Ejecuta primero la celda de configuracion y luego discovery.

## Flujo recomendado

1. 00_discovery_tables.kql
2. 01_discovery_events.kql
3. 10_sli_executive_summary.kql
4. 20_slow_forms.kql
5. 30_slow_queries.kql
6. 40_exceptions.kql

## Troubleshooting rapido

No module named azure.monitor.query:

- Verifica kernel correcto.
- Reinstala dependencias con el bootstrap.

AuthorizationFailed:

- Solicita uno de estos roles en el workspace:
- Log Analytics Reader
- Log Analytics Data Reader
- Monitoring Reader

No devuelve datos:

- Revisa LAW_WORKSPACE_ID.
- Reduce QUERY_DAYS a 1 para validar ventana.
- Ejecuta consultas de discovery primero.

## Referencias

- docs/getting-started/mcp-quickstart.md
- docs/reference/sql-tools-guide.md
- docs/reference/azure-sql-connection-guide.md
