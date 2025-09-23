# Azure Agent Pro - Plantillas Bicep Modernizadas 2025

## 🚀 Características Modernizadas

Este proyecto ha sido completamente modernizado para seguir las mejores prácticas de Bicep 2025, utilizando las capacidades más avanzadas de Azure MCP Server para acceso en tiempo real a esquemas de recursos y APIs.

### ✨ Mejoras Implementadas

#### **User-Defined Types (UDT)**
- Reemplazo de tipos básicos (`array`, `object`) con tipos definidos por el usuario
- Validación mejorada de parámetros con IntelliSense
- Documentación integrada con decoradores `@description()`

#### **APIs Más Recientes**
- **Storage Account**: API 2025-01-01 con características premium
- **Key Vault**: API 2024-12-01-preview con autorización RBAC
- **Virtual Network**: API 2024-05-01 con seguridad moderna

#### **Configuración de Seguridad Moderna**
- Autenticación RBAC habilitada por defecto
- Políticas de red para endpoints privados
- Cifrado de red virtual disponible
- NSG con reglas de seguridad optimizadas

## 📁 Estructura del Proyecto

```
bicep/
├── main.bicep                     # Plantilla principal modernizada
├── modules/
│   ├── storage-account.bicep      # API 2025-01-01 + UDT
│   ├── key-vault.bicep           # API 2024-12-01-preview + RBAC
│   └── virtual-network.bicep     # API 2024-05-01 + Seguridad
└── parameters/
    ├── dev.bicepparam            # Parámetros modernos (no JSON)
    └── prod.bicepparam           # Parámetros modernos (no JSON)
```

## 🔧 Tecnologías Utilizadas

### **Azure MCP Server Integration**
- Acceso en tiempo real a esquemas de recursos de Azure
- APIs y versiones más recientes disponibles
- Mejores prácticas actualizadas para 2025

### **Bicep Features 2025**
- **User-Defined Types**: Validación estricta de tipos
- **Archivos .bicepparam**: Reemplazan JSON con type safety
- **Safe Dereference Operator** (`.?`): Manejo seguro de nulos
- **Resource-derived Types**: Tipos automáticos desde recursos

## 🏗️ Recursos Implementados

### **Storage Account**
```bicep
// Características 2025
- Minimum TLS 1.2 habilitado
- Public blob access deshabilitado
- Shared key access restringido
- Network ACLs configuradas
- Lifecycle management incluido
```

### **Key Vault**
```bicep
// Características 2025
- Autorización RBAC (no access policies)
- Premium SKU por defecto en producción
- Purge protection habilitada
- Diagnostic settings avanzados
- Network isolation configurada
```

### **Virtual Network**
```bicep
// Características 2025
- Default outbound access deshabilitado
- Private endpoint policies habilitadas
- Flow timeout configurable
- BGP communities para ExpressRoute
- VM protection disponible
```

## 🚀 Despliegue

### **Desarrollo**
```bash
az deployment group create \
  --resource-group rg-azure-agent-dev \
  --template-file main.bicep \
  --parameters dev.bicepparam
```

### **Producción**
```bash
az deployment group create \
  --resource-group rg-azure-agent-prod \
  --template-file main.bicep \
  --parameters prod.bicepparam
```

## 📊 Diferencias por Entorno

| Característica | Desarrollo | Producción |
|----------------|------------|------------|
| Storage SKU | Standard_LRS | Standard_GRS |
| Key Vault SKU | Standard | Premium |
| DDoS Protection | Deshabilitado | Habilitado |
| VM Protection | Deshabilitado | Habilitado |
| Purge Protection | Deshabilitado | Habilitado |

## 🛡️ Seguridad

### **Configuraciones de Seguridad por Defecto**
- ✅ TLS 1.2 mínimo en Storage Account
- ✅ RBAC en Key Vault (no access policies)
- ✅ Network Security Groups con reglas restrictivas
- ✅ Private endpoints policies habilitadas
- ✅ Default outbound access deshabilitado
- ✅ Shared key access restringido

### **Características Premium**
- 🔐 Hardware Security Module (HSM) en producción
- 🛡️ DDoS Protection Standard en producción
- 🔄 Geo-redundant storage en producción
- 📊 Advanced threat protection disponible

## 🎯 Outputs Estructurados

Todos los módulos proporcionan outputs estructurados con información completa:

```bicep
// Ejemplo de output de Storage Account
output storageAccountDetails object = {
  id: string
  name: string
  primaryBlobEndpoint: string
  minimumTlsVersion: string
  allowBlobPublicAccess: bool
  // ... más propiedades
}
```

## 📝 Notas de Desarrollo

### **Validaciones Implementadas**
- Longitud de nombres de recursos
- Formatos CIDR para redes
- Valores permitidos para SKUs
- Configuraciones de entorno válidas

### **IntelliSense Mejorado**
Gracias a los User-Defined Types, obtienes:
- Autocompletado de propiedades
- Validación en tiempo de escritura
- Documentación contextual
- Detección temprana de errores

## 🔮 Roadmap Futuro

- [ ] Implementación de Private Endpoints
- [ ] Azure Monitor integration
- [ ] Backup configurations
- [ ] Disaster recovery setup
- [ ] Multi-region deployment

---

**Desarrollado con Azure MCP Server y mejores prácticas Bicep 2025** 🚀