---
name: Azure Infrastructure Issue
about: Problemas específicos con la infraestructura de Azure o plantillas Bicep
title: '[AZURE] '
labels: ['azure', 'infrastructure', 'needs-investigation']
assignees: ''
---

## Tipo de Problema Azure

- [ ] Error en plantilla Bicep
- [ ] Problema de deployment
- [ ] Configuración de recursos
- [ ] Permisos/RBAC
- [ ] Networking
- [ ] Seguridad
- [ ] Cost optimization
- [ ] Otro: ___________

## 🌍 Ambiente Afectado

- [ ] Desarrollo (dev)
- [ ] Testing (test)
- [ ] Staging (stage)
- [ ] Producción (prod)
- [ ] Todos los ambientes

## 📍 Recursos Azure Involucrados

**Tipo de recursos:**
- [ ] Storage Account
- [ ] Key Vault
- [ ] Virtual Network
- [ ] Resource Group
- [ ] Otro: ___________

**Nombres de recursos (si aplica):**
```
Resource Group: 
Storage Account: 
Key Vault: 
Otros: 
```

## 🐛 Descripción del Problema

Una descripción clara del problema con la infraestructura Azure.

## 🔄 Pasos para Reproducir

1. Ejecutar comando/script: `...`
2. En el ambiente: `...`
3. Observar error: `...`

## Error/Resultado Actual

```bash
# Pega aquí el error completo de Azure CLI o el deployment
```

## Resultado Esperado

Describe qué debería suceder en lugar del error.

## Plantilla Bicep Relacionada

**Archivo:** `bicep/...`

```bicep
// Si es relevante, pega aquí la sección problemática de la plantilla Bicep
```

## Configuración Azure

**Suscripción:** `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` (solo últimos 4 dígitos)
**Región:** `[ej. East US]`
**Tenant:** `[si es relevante]`

```bash
# Output de az account show (sin información sensible)
```

## Logs y Diagnostics

**Azure CLI output:**
```bash
# Pega aquí el output relevante de az cli con --debug si es necesario
```

**Azure Portal errors (si aplica):**
```
# Cualquier error visible en el portal de Azure
```

## Investigación Realizada

- [ ] Verificado permisos en Azure
- [ ] Revisado logs en Azure Portal
- [ ] Comparado con otros ambientes
- [ ] Consultado documentación de Azure
- [ ] Verificado quotas y límites
- [ ] Otro: ___________

## Solución Propuesta

Si tienes una idea de cómo solucionarlo:

```bicep
// Código Bicep propuesto
```

o

```bash
# Comandos Azure CLI propuestos
```

## Checklist

- [ ] He verificado que los permisos son correctos
- [ ] He revisado los logs de deployment en Azure
- [ ] He validado la sintaxis Bicep localmente
- [ ] He comparado con configuraciones que funcionan
- [ ] He incluido toda la información relevante sin datos sensibles
