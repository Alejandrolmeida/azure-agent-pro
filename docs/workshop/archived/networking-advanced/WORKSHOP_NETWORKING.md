# Workshop: Azure Networking Profesional con GitHub Copilot

**Duración:** 4 horas
**Nivel:** Intermedio-Avanzado
**Certificaciones:** AZ-104, AZ-700

---

## Requisitos Previos

### Conocimientos

- Fundamentos de redes (TCP/IP, DNS, routing)
- Experiencia básica con Azure Portal
- Conocimientos de Azure CLI o PowerShell
- Familiaridad con conceptos de IaC (Infrastructure as Code)

### Software

- Visual Studio Code
- GitHub Copilot (licencia activa)
- Azure CLI instalado
- Git
- Node.js 20+

### Cuenta de Azure

- Suscripción de Azure activa
- Permisos de Contributor o superior
- Límites de cuota suficientes para:
 - VNETs (mínimo 5)
 - VPN Gateways (mínimo 1)
 - Public IPs (mínimo 3)
 - Azure Firewall (opcional)

---

## 📖 Agenda del Workshop

### Módulo 1: Setup y Verificación de MCP Servers (30 min)

**Objetivo**: Configurar GitHub Copilot con MCP servers para acceso a recursos de Azure

#### 1.1 Verificación de Instalación (10 min)

**Ejercicio 1.1.1: Verificar Servidores MCP**

1. Abre VS Code en la raíz del proyecto
2. Presiona `Ctrl+Shift+I` para abrir GitHub Copilot Chat
3. Pregunta: `@workspace ¿Qué servidores MCP tienes disponibles?`

**Resultado esperado**: Deberías ver 6 servidores configurados:

- `azure-mcp` - Acceso a recursos de Azure
- `bicep-mcp` - Asistencia con plantillas Bicep
- `github-mcp` - Repositorios, issues, PRs
- `filesystem-mcp` - Navegación del proyecto
- `brave-search-mcp` - Búsqueda web
- `memory-mcp` - Contexto persistente

**Ejercicio 1.1.2: Probar Azure MCP**

Pregunta a Copilot:

```
@workspace Usando Azure MCP, lista las redes virtuales en mi suscripción
```

**Ejercicio 1.1.3: Probar Bicep MCP**

Pregunta a Copilot:

```
@workspace Usando Bicep MCP, explica la sintaxis para crear una VNET
con 3 subnets
```

#### 1.2 Exploración de Capacidades (20 min)

**Ejercicio 1.2.1: Azure Resource Explorer**

```
@workspace Lista todos los Network Security Groups en el resource group
y muestra sus reglas configuradas
```

**Ejercicio 1.2.2: Búsqueda de Documentación**

```
@workspace Busca las mejores prácticas de Microsoft para diseñar
arquitecturas hub-spoke en Azure
```

**Ejercicio 1.2.3: Context Awareness**

```
@workspace Analiza los archivos Bicep existentes en bicep/modules/
y sugiere mejoras según las mejores prácticas de Azure
```

** Checkpoint**: Al finalizar este módulo deberías tener todos los servidores MCP funcionando y comprender qué hace cada uno.

---

### Módulo 2: Diseño de Redes y Arquitecturas Hub-Spoke (60 min)

**Objetivo**: Diseñar e implementar una arquitectura de red hub-spoke con Bicep y GitHub Copilot

#### 2.1 Fundamentos de Hub-Spoke (15 min)

**Ejercicio 2.1.1: Diseño de Arquitectura**

Usa Copilot para generar un diseño:

```
@workspace Genera un diagrama en texto (ASCII art) de una arquitectura
hub-spoke con:
- 1 VNET hub (10.0.0.0/16) con subnets para:
 - AzureFirewallSubnet (10.0.0.0/24)
 - GatewaySubnet (10.0.1.0/24)
 - Management (10.0.2.0/24)
- 2 VNET spokes:
 - Spoke 1 (10.1.0.0/16) para aplicaciones web
 - Spoke 2 (10.2.0.0/16) para bases de datos
- Peering entre hub y cada spoke
```

**Ejercicio 2.1.2: Cálculo de Direccionamiento**

```
@workspace Calcula la distribución de direcciones IP para una red corporativa:
- Sede central: 2000 hosts
- 3 oficinas regionales: 500 hosts cada una
- 5 sucursales: 100 hosts cada una
Usa subnetting eficiente y sugiere los rangos CIDR
```

#### 2.2 Implementación con Bicep (30 min)

**Ejercicio 2.2.1: Crear Módulo de VNET Hub**

```
@workspace Crea un módulo Bicep (bicep/modules/vnet-hub.bicep) que:
1. Cree una VNET con parámetros configurables
2. Incluya subnets para Firewall, Gateway y Management
3. Tenga outputs para VNET ID y subnet IDs
4. Use nombres de recursos según convención de Azure
5. Incluya tags para governance
```

**Ejercicio 2.2.2: Crear Módulo de VNET Spoke**

```
@workspace Crea un módulo Bicep (bicep/modules/vnet-spoke.bicep) que:
1. Cree una VNET spoke parametrizable
2. Permita definir múltiples subnets
3. Configure peering automático con el hub
4. Incluya delegación de subnets (opcional)
```

**Ejercicio 2.2.3: Orquestación con Main Bicep**

```
@workspace Actualiza bicep/main.bicep para:
1. Importar los módulos de hub y spoke
2. Desplegar 1 hub y 2 spokes
3. Configurar peering bidireccional
4. Pasar parámetros desde bicep/parameters/dev.bicepparam
```

#### 2.3 Despliegue y Validación (15 min)

**Ejercicio 2.3.1: Desplegar Infraestructura**

```bash
# Usar Copilot para generar el comando
@workspace Genera el comando de Azure CLI para desplegar la plantilla
Bicep con los parámetros de desarrollo
```

**Ejercicio 2.3.2: Verificar Conectividad**

```
@workspace Genera un script Bash que:
1. Liste todas las VNETs creadas
2. Verifique el estado del peering
3. Muestre las subnets de cada VNET
4. Valide que no hay overlapping de rangos IP
```

** Checkpoint**: Deberías tener una arquitectura hub-spoke funcional desplegada en Azure.

---

### Módulo 3: Seguridad de Red (60 min)

**Objetivo**: Implementar seguridad de red con NSGs, Azure Firewall y Application Gateway

#### 3.1 Network Security Groups (20 min)

**Ejercicio 3.1.1: NSG para Aplicación de 3 Capas**

```
@workspace Crea un módulo Bicep (bicep/modules/nsg-3tier.bicep) que defina NSGs para:

Web Tier (permite):
- HTTP/HTTPS desde Internet
- SSH/RDP solo desde Management subnet
- Niega todo lo demás

App Tier (permite):
- Tráfico desde Web Tier solo en puertos 8080-8090
- SSH/RDP desde Management subnet
- Niega todo lo demás

DB Tier (permite):
- SQL Server (1433) solo desde App Tier
- PostgreSQL (5432) solo desde App Tier
- SSH/RDP desde Management subnet
- Niega todo lo demás

Usa el principio de mínimo privilegio y prioridades correctas
```

**Ejercicio 3.1.2: Reglas de Servicio**

```
@workspace Añade reglas NSG para permitir:
1. Azure Load Balancer health probes
2. Azure Monitor (Guest Agent)
3. Azure Backup
4. Azure Update Management
5. Bloqueo de tráfico entre spokes (security)
```

**Ejercicio 3.1.3: NSG Flow Logs**

```
@workspace Genera una plantilla Bicep que:
1. Cree un Storage Account para NSG Flow Logs
2. Habilite NSG Flow Logs versión 2
3. Configure Traffic Analytics
4. Envíe logs a Log Analytics Workspace
```

#### 3.2 Azure Firewall (25 min)

**Ejercicio 3.2.1: Desplegar Azure Firewall**

```
@workspace Crea un módulo Bicep (bicep/modules/azure-firewall.bicep) que:
1. Despliegue Azure Firewall en el hub
2. Cree una Public IP para el firewall
3. Configure Azure Firewall Policy
4. Habilite DNS Proxy
5. Configure Threat Intelligence
```

**Ejercicio 3.2.2: Reglas de Firewall**

```
@workspace Añade al Azure Firewall Policy:

Network Rules:
- Permite NTP (UDP 123) a time.windows.com
- Permite DNS (UDP/TCP 53) a Azure DNS
- Bloquea todo el tráfico entre spokes

Application Rules:
- Permite HTTPS a *.microsoft.com
- Permite HTTP/HTTPS a dominios de actualización de Windows
- Permite acceso a Azure Storage en la región
- Niega Facebook, Twitter, YouTube

DNAT Rules:
- Redirige puerto 443 público a app server interno
```

**Ejercicio 3.2.3: Route Tables**

```
@workspace Crea Route Tables para:
1. Spoke 1: forzar todo tráfico saliente por Azure Firewall
2. Spoke 2: forzar todo tráfico saliente por Azure Firewall
3. Management: ruta directa a Internet (bypass firewall)

Asocia las Route Tables a las subnets correspondientes
```

#### 3.3 DDoS Protection y Web Application Firewall (15 min)

**Ejercicio 3.3.1: Habilitar DDoS Protection**

```
@workspace Crea un módulo Bicep que:
1. Habilite DDoS Protection Standard en el hub VNET
2. Configure DDoS Protection Plan
3. Habilite alertas de DDoS en Azure Monitor
4. Configure metric alerts para ataques DDoS
```

**Ejercicio 3.3.2: Application Gateway con WAF**

```
@workspace Genera una plantilla Bicep para Application Gateway v2 que:
1. Despliegue en el hub VNET
2. Habilite WAF con OWASP 3.2
3. Configure backend pool apuntando a VMs en spoke 1
4. Configure health probes
5. Habilite logging a Log Analytics
6. Configure reglas custom para bloquear IPs específicas
```

** Checkpoint**: Deberías tener una infraestructura de seguridad multinivel implementada.

---

### 🌐 Módulo 4: Conectividad Híbrida (60 min)

**Objetivo**: Configurar conectividad híbrida con VPN Gateway y simular ExpressRoute

#### 4.1 Site-to-Site VPN (30 min)

**Ejercicio 4.1.1: VPN Gateway**

```
@workspace Crea un módulo Bicep (bicep/modules/vpn-gateway.bicep) que:
1. Despliegue VPN Gateway en el hub (SKU: VpnGw2)
2. Use Active-Active configuration
3. Configure BGP (ASN: 65515)
4. Cree 2 Public IPs para redundancia
5. Habilite VPN diagnostics
```

**Ejercicio 4.1.2: Local Network Gateway**

```
@workspace Crea un módulo para Local Network Gateway que represente:
- Oficina local con IP pública: 203.0.113.50
- Rango de red local: 192.168.0.0/16
- Subredes específicas:
 - 192.168.10.0/24 (Servidores)
 - 192.168.20.0/24 (Clientes)
 - 192.168.30.0/24 (DMZ)
- BGP: ASN 65001, BGP Peer IP: 192.168.255.254
```

**Ejercicio 4.1.3: VPN Connection**

```
@workspace Crea la conexión VPN con:
1. Shared key seguro (usa Azure Key Vault)
2. IKEv2 protocol
3. IPsec/IKE policy custom:
 - IKE Phase 1: AES256, SHA256, DHGroup14
 - IKE Phase 2: GCMAES256, PFS2048
4. Habilita BGP
5. Configure connection monitoring
```

**Ejercicio 4.1.4: Route Propagation**

```
@workspace Configura las Route Tables para:
1. Propagar rutas BGP del VPN Gateway
2. Permitir que los spokes aprendan rutas on-premises
3. Asegurar que el tráfico a on-premises pasa por el hub
4. Configurar user-defined routes para casos especiales
```

#### 4.2 Point-to-Site VPN (15 min)

**Ejercicio 4.2.1: P2S Configuration**

```
@workspace Añade configuración Point-to-Site al VPN Gateway:
1. Pool de direcciones: 172.16.0.0/24
2. Tipo de túnel: OpenVPN y IKEv2
3. Autenticación: Azure AD (native)
4. Genera certificados root y client (self-signed para demo)
5. Descarga el cliente VPN configuration
```

**Ejercicio 4.2.2: Conditional Access**

```
@workspace Genera una plantilla Bicep o script para configurar:
1. Azure AD Conditional Access policy para VPN
2. Requerir MFA para conexión VPN
3. Requerir dispositivo compliant
4. Limitar acceso por ubicación geográfica
5. Logging de eventos de autenticación
```

#### 4.3 ExpressRoute (Simulación) (15 min)

**Ejercicio 4.3.1: ExpressRoute Gateway**

```
@workspace Crea un módulo Bicep para ExpressRoute Gateway (sin desplegar):
1. SKU: ErGw2AZ (zone-redundant)
2. Desplegar en GatewaySubnet del hub
3. Configurar para coexistir con VPN Gateway
4. Habilitar FastPath (para tráfico de baja latencia)
```

**Ejercicio 4.3.2: ExpressRoute Circuit (Design)**

```
@workspace Documenta en Markdown el diseño de ExpressRoute:
1. Service Provider: Equinix
2. Peering Location: Amsterdam
3. Bandwidth: 1 Gbps
4. SKU: Premium (para global reach)
5. Private Peering configuration
6. Microsoft Peering (opcional, para Office 365)
7. Route filters para Microsoft Peering
8. Connection monitoring y alerting
```

** Checkpoint**: Deberías entender cómo configurar conectividad híbrida completa.

---

### Módulo 5: Monitorización y Troubleshooting (30 min)

**Objetivo**: Implementar monitorización completa con Network Watcher, Azure Monitor y Log Analytics

#### 5.1 Network Watcher (15 min)

**Ejercicio 5.1.1: Habilitar Network Watcher**

```
@workspace Genera un script de Azure CLI que:
1. Habilite Network Watcher en todas las regiones activas
2. Configure diagnostic settings
3. Cree un Storage Account para packet capture
4. Habilite Connection Monitor
```

**Ejercicio 5.1.2: Topology y Connectivity**

```
@workspace Usa Network Watcher para:
1. Generar diagrama de topología de red
2. Verificar conectividad entre VMs en diferentes spokes
3. Diagnosticar problemas de routing
4. Verificar effective routes en NICs
5. Verificar effective NSG rules
```

**Ejercicio 5.1.3: Traffic Analytics**

```
@workspace Configura Traffic Analytics para:
1. Analizar flujos de tráfico entre subnets
2. Identificar top talkers
3. Detectar anomalías de tráfico
4. Generar reportes de uso de bandwidth
5. Crear alertas para tráfico sospechoso
```

#### 5.2 Azure Monitor y Log Analytics (15 min)

**Ejercicio 5.2.1: Log Analytics Workspace**

```
@workspace Crea una plantilla Bicep para:
1. Log Analytics Workspace en la misma región que el hub
2. Retention: 90 días
3. Data Collection Rules para:
 - NSG Flow Logs
 - Azure Firewall Logs
 - VPN Gateway Diagnostics
 - Application Gateway Logs
4. Queries guardadas para análisis común
```

**Ejercicio 5.2.2: Workbooks y Dashboards**

```
@workspace Genera queries KQL para:
1. Top 10 IPs por tráfico denegado en NSG
2. Conexiones VPN activas y tiempo de actividad
3. Tráfico bloqueado por Azure Firewall por categoría
4. Latencia promedio entre spokes
5. Failed connection attempts por origen
```

**Ejercicio 5.2.3: Alertas Proactivas**

```
@workspace Crea Action Groups y Alert Rules para:
1. VPN Gateway down (critical)
2. Azure Firewall alta utilización (warning)
3. DDoS attack detected (critical)
4. NSG rule blocks > 1000/min (warning)
5. ExpressRoute BGP session down (critical)
```

** Checkpoint**: Deberías tener visibilidad completa de tu infraestructura de red.

---

## 🎁 Bonus: Automatización y CI/CD

### Ejercicio Bonus 1: GitHub Actions Workflow

```
@workspace Crea un workflow de GitHub Actions (.github/workflows/deploy-network.yml) que:
1. Trigger: Push a main en carpeta bicep/
2. Validate: bicep build y az deployment what-if
3. Deploy a Dev: si validation pasa
4. Manual approval para Prod
5. Deploy a Prod: después de approval
6. Post-deployment tests:
 - Verificar peering status
 - Verificar VPN connectivity
 - Verificar NSG rules aplicadas
7. Rollback automático si tests fallan
```

### Ejercicio Bonus 2: Política de Azure

```
@workspace Crea Azure Policy definitions para:
1. Requerir NSG en todas las subnets (except GatewaySubnet)
2. Denegar creación de Public IPs sin approval
3. Requerir encryption en tránsito para Storage Accounts
4. Requerir tags obligatorios: Environment, CostCenter, Owner
5. Denegar VM sizes costosos en Dev
6. Audit: VNETs sin Network Watcher habilitado
```

---

## Resumen y Próximos Pasos

### ¿Qué has aprendido?

 Configurar GitHub Copilot con MCP servers para Azure
 Diseñar arquitecturas hub-spoke con Bicep
 Implementar seguridad de red multinivel
 Configurar conectividad híbrida (VPN/ExpressRoute)
 Monitorizar y troubleshoot redes en Azure
 Automatizar despliegues con GitHub Actions

### Certificaciones

Este workshop te prepara para:

- **AZ-104**: Microsoft Azure Administrator
 - Módulo: Implement and manage virtual networking
- **AZ-700**: Designing and Implementing Microsoft Azure Networking Solutions
 - Todos los objetivos del examen

### Recursos para Continuar

- 📖 [Microsoft Learn: AZ-700](https://learn.microsoft.com/en-us/certifications/exams/az-700)
- 📖 [Azure Architecture Center](https://learn.microsoft.com/en-us/azure/architecture/)
- 📖 [Azure Networking Documentation](https://learn.microsoft.com/en-us/azure/networking/)
- 🎥 [John Savill's Azure Networking Videos](https://www.youtube.com/c/NTFAQGuy)

---

## 💬 Feedback

Por favor comparte tu feedback del workshop:

- ¿Qué te gustó más?
- ¿Qué mejorarías?
- ¿Qué temas adicionales te gustaría cubrir?

**¡Gracias por participar! **

