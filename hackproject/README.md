# BiciMAD Low Emission Router - Hackathon Project

🚴 **Sistema inteligente de routing para ciclistas que minimiza exposición a contaminación atmosférica**

## 📊 Estado del Proyecto

### ✅ Completado (Tareas 1-20)

#### Infraestructura (Bicep IaC)
- ✅ Estructura de carpetas completa (`hackproject/`)
- ✅ `bicep/main.bicep` - Orquestador principal
- ✅ Módulos Bicep:
  - `static-web-app.bicep` - Frontend hosting
  - `function-app.bicep` - Backend APIs
  - `storage-account.bicep` - Cache y logs
  - `app-insights.bicep` - Monitoring
  - `key-vault.bicep` - Secrets management
  - `azure-maps.bicep` - Routing service
- ✅ Parámetros: `dev.bicepparam`, `prod.bicepparam`

#### Backend (Azure Functions - Python 3.11)
- ✅ `function_app.py` - Entry point con endpoints:
  - `GET /api/health` - Health check
  - `GET /api/stations` - Disponibilidad BiciMAD
  - `GET /api/air-quality` - Calidad del aire
  - `POST /api/calculate-route` - Calcular rutas
  - Timer trigger para ingesta de datos cada 20 min
- ✅ `requirements.txt` - Dependencias Python
- ✅ `host.json` - Configuración runtime

### 🚧 Pendiente (Tareas 21-50)

#### Críticas para MVP
1. **Backend Utils** (Tareas 21-23)
   - `data_providers.py` - Clientes APIs externas
   - `scoring_engine.py` - Algoritmo de scoring
   - `cache_manager.py` - Gestión de cache

2. **Frontend** (Tareas 24-30)
   - `index.html` - Página principal
   - `styles.css` - Estilos responsive
   - `app.js`, `map.js`, `api-client.js`, `ui-controller.js`
   - `staticwebapp.config.json`

3. **CI/CD** (Tareas 32-34)
   - `deploy-infrastructure.yml`
   - `deploy-backend.yml`
   - `deploy-frontend.yml`

4. **Documentación** (Tareas 36-40)
   - `ARCHITECTURE.md`
   - `API.md`
   - `DEPLOYMENT.md`
   - `README.md`

#### Opcionales (Post-MVP)
- Tests unitarios (Tarea 43)
- Mock data (Tarea 44)
- Security scan pipeline (Tarea 35)
- Dashboard monitoring (Tarea 48)
- Budget alerts (Tarea 49)

## 🚀 Próximos Pasos Inmediatos

1. Crear módulos utils del backend
2. Implementar frontend completo con Leaflet.js
3. Configurar pipelines CI/CD
4. Documentar arquitectura y despliegue
5. Crear `.gitignore`

## 📂 Estructura Actual

```
hackproject/
├── docs/
│   ├── LOW_EMISSION_BICIMAD_ROUTER.md
│   └── Pack_OpenData_Madrid_DS2025.html
├── bicep/
│   ├── main.bicep
│   ├── modules/ (8 módulos)
│   └── parameters/ (dev, prod)
├── src/
│   ├── api/
│   │   ├── function_app.py
│   │   ├── requirements.txt
│   │   ├── host.json
│   │   └── utils/ (vacío, pendiente)
│   ├── frontend/ (vacío, pendiente)
│   └── jobs/ (vacío, pendiente)
└── README.md (este archivo)
```

## 🎯 Hackathon: DataSaturday Madrid 2025

**Categoría**: Movilidad Sostenible + Open Data  
**Tecnologías**: Azure Functions, Static Web Apps, Bicep, Python, Leaflet.js  
**Datos**: BiciMAD API + Calidad del Aire Madrid + Azure Maps

---

**Rama de desarrollo**: `datahack4good`  
**Última actualización**: 2025-11-30
