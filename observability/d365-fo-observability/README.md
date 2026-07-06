# D365 F&O Observability Starter

Plantilla lista para ejecutar consultas KQL desde Jupyter Notebook contra Log Analytics/Application Insights de Dynamics 365 Finance & Operations.

## Estructura

- notebooks/d365_fo_observability.ipynb
- notebooks/01_discovery_analyst.ipynb
- notebooks/02_sli_analyst.ipynb
- notebooks/03_forms_analyst.ipynb
- notebooks/04_queries_analyst.ipynb
- notebooks/05_exceptions_analyst.ipynb
- notebooks/06_batch_analyst.ipynb
- notebooks/07_availability_analyst.ipynb
- notebooks/08_dashboard_candidates_analyst.ipynb
- notebooks/README.md
- queries/*.kql
- exports/
- src/kql_runner.py
- requirements.txt
- .env.example

## Inicio rapido

1. Ejecuta el bootstrap:

```bash
bash scripts/setup/d365fo-observability-bootstrap.sh
```

2. Copia y configura variables:

```bash
cd observability/d365-fo-observability
cp .env.example .env
# Edita LAW_WORKSPACE_ID con tu Workspace ID real
```

Para cambiar de cliente, modifica `LAW_WORKSPACE_ID` en `.env` con el workspace correspondiente.
`APPINSIGHTS_CONNECTION_STRING` es opcional y solo aplica si vas a instrumentar una app que emite telemetria.

3. Inicia sesion en Azure CLI:

```bash
az login
az account show --output table
```

4. Abre el notebook y selecciona el kernel:

- Python (conda:aifoundry) - D365 F&O Observability

El bootstrap usa Miniconda/Conda por defecto. Puedes cambiar el entorno con:

```bash
CONDA_ENV_NAME=mi-entorno bash scripts/setup/d365fo-observability-bootstrap.sh
```

## Notas

- No subas `.env` ni `exports/` al repositorio.
- Usa las consultas de `queries/` como fuente versionada y mantenible.
- Para exploracion funcional y diseno de dashboards, usa los notebooks por categoria dentro de `notebooks/`.
- El notebook `d365_fo_observability.ipynb` queda como smoke test tecnico y exportacion consolidada.
