# Notebooks didacticos de observabilidad

Estos cuadernos estan pensados para analistas funcionales y de operaciones, no solo para validar que las consultas KQL responden.

Orden recomendado:

- 01_discovery_analyst.ipynb: entender cobertura de tablas y eventos disponibles
- 02_sli_analyst.ipynb: revisar KPIs de experiencia y cumplimiento de objetivo
- 03_forms_analyst.ipynb: explorar uso y rendimiento de formularios
- 04_queries_analyst.ipynb: analizar consultas lentas y su evolucion temporal
- 05_exceptions_analyst.ipynb: priorizar errores y ver su tendencia
- 06_batch_analyst.ipynb: descubrir eventos batch y fallos operativos
- 07_availability_analyst.ipynb: validar disponibilidad sintetica y latencia
- 08_dashboard_candidates_analyst.ipynb: comparar visualizaciones candidatas para el dashboard final

El notebook d365_fo_observability.ipynb se mantiene como cuaderno tecnico de smoke test y exportacion masiva.

Como usar estos cuadernos:

- Ajusta la ventana de dias al principio de cada notebook antes de sacar conclusiones.
- Empieza por discovery si no conoces la telemetria real del cliente.
- Usa los graficos para decidir formato de visualizacion, no solo para validar la consulta.
- Reserva el notebook tecnico para smoke test, exportacion a Excel y ejecuciones masivas.

Pregunta guia para analistas:

- Esta consulta mide volumen, severidad, tendencia o detalle?
- La visualizacion es mejor como KPI, serie temporal, ranking o tabla de detalle?
- El dato es suficientemente estable para vivir en un dashboard permanente?