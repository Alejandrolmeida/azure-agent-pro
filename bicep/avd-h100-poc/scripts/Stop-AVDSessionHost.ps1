<#
.SYNOPSIS
    Detiene y desasigna VMs AVD sin sesiones activas durante un período específico
    
.DESCRIPTION
    Este runbook verifica el estado de sesiones AVD en un Host Pool.
    Si no hay sesiones activas durante X minutos (configurable), detiene y desasigna la VM.
    Utiliza tags en la VM para rastrear el último tiempo de actividad.
    
.PARAMETER ResourceGroupName
    Nombre del Resource Group que contiene los recursos AVD
    
.PARAMETER HostPoolName
    Nombre del Host Pool AVD a monitorear
    
.PARAMETER IdleMinutesThreshold
    Minutos sin sesión activa antes de detener la VM (por defecto: 15)
    
.NOTES
    Autor: Azure Agent Pro
    Versión: 1.0
    Fecha: 2025-10-28
    
.EXAMPLE
    .\Stop-AVDSessionHost.ps1 -ResourceGroupName "rg-avd-h100-poc" -HostPoolName "hp-avdh100-personal" -IdleMinutesThreshold 15
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$HostPoolName,
    
    [Parameter(Mandatory = $false)]
    [int]$IdleMinutesThreshold = 15
)

# ============================================================================
# FUNCTIONS
# ============================================================================

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        'Info' { Write-Output $logMessage }
        'Warning' { Write-Warning $logMessage }
        'Error' { Write-Error $logMessage }
    }
}

# ============================================================================
# AUTHENTICATION
# ============================================================================

try {
    Write-Log "Conectando con Managed Identity..."
    
    # Conectar usando Managed Identity de la Automation Account
    Connect-AzAccount -Identity -ErrorAction Stop | Out-Null
    
    Write-Log "Autenticación exitosa con Managed Identity"
}
catch {
    Write-Log "Error al autenticar con Managed Identity: $_" -Level Error
    throw
}

# ============================================================================
# MAIN LOGIC
# ============================================================================

try {
    Write-Log "Iniciando verificación de sesiones AVD..."
    Write-Log "Resource Group: $ResourceGroupName"
    Write-Log "Host Pool: $HostPoolName"
    Write-Log "Idle Threshold: $IdleMinutesThreshold minutos"
    
    # Obtener todas las sesiones activas del host pool
    Write-Log "Obteniendo sesiones AVD del Host Pool..."
    
    $sessions = Get-AzWvdUserSession -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName -ErrorAction SilentlyContinue
    
    if ($null -eq $sessions) {
        Write-Log "No se encontraron sesiones en el Host Pool" -Level Warning
        $activeSessions = @()
    }
    else {
        $activeSessions = $sessions | Where-Object { $_.SessionState -eq 'Active' }
        Write-Log "Sesiones totales: $($sessions.Count) | Sesiones activas: $($activeSessions.Count)"
    }
    
    # Obtener session hosts del pool
    Write-Log "Obteniendo Session Hosts del pool..."
    $sessionHosts = Get-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName
    
    if ($null -eq $sessionHosts -or $sessionHosts.Count -eq 0) {
        Write-Log "No se encontraron Session Hosts en el Host Pool" -Level Warning
        return
    }
    
    Write-Log "Session Hosts encontrados: $($sessionHosts.Count)"
    
    # Procesar cada Session Host
    foreach ($sessionHost in $sessionHosts) {
        # Extraer nombre de VM del nombre completo del session host
        # Formato: hostpool/vm-name.domain
        $vmName = ($sessionHost.Name -split '/')[1] -replace '\..*$'
        
        Write-Log "Procesando VM: $vmName"
        
        # Verificar si hay sesiones activas en esta VM
        $vmActiveSessions = $activeSessions | Where-Object { $_.Name -like "*$vmName*" }
        
        if ($vmActiveSessions.Count -gt 0) {
            Write-Log "VM $vmName tiene $($vmActiveSessions.Count) sesión(es) activa(s). Actualizando timestamp..."
            
            # Hay sesiones activas, actualizar timestamp
            try {
                $vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $vmName -ErrorAction Stop
                
                # Actualizar tag de última actividad
                $vm.Tags['LastActivity'] = (Get-Date).ToString('o')
                
                Update-AzVM -ResourceGroupName $ResourceGroupName -VM $vm -Tag $vm.Tags -ErrorAction Stop | Out-Null
                
                Write-Log "Timestamp actualizado para VM $vmName"
            }
            catch {
                Write-Log "Error al actualizar tags de VM $vmName: $_" -Level Error
            }
        }
        else {
            Write-Log "VM $vmName NO tiene sesiones activas. Verificando tiempo de inactividad..."
            
            try {
                # Obtener estado actual de la VM
                $vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $vmName -Status -ErrorAction Stop
                
                # Verificar si VM ya está detenida
                $powerState = ($vm.Statuses | Where-Object { $_.Code -like 'PowerState/*' }).Code
                
                if ($powerState -eq 'PowerState/deallocated' -or $powerState -eq 'PowerState/stopped') {
                    Write-Log "VM $vmName ya está detenida/desasignada ($powerState). Saltando..."
                    continue
                }
                
                Write-Log "VM $vmName está en estado: $powerState"
                
                # Obtener tags de la VM
                $lastActivityTag = $vm.Tags['LastActivity']
                
                if ([string]::IsNullOrEmpty($lastActivityTag)) {
                    # Primera vez sin sesión, marcar timestamp inicial
                    Write-Log "Primera detección de inactividad en VM $vmName. Marcando timestamp inicial..."
                    
                    $vm.Tags['LastActivity'] = (Get-Date).ToString('o')
                    Update-AzVM -ResourceGroupName $ResourceGroupName -VM $vm -Tag $vm.Tags -ErrorAction Stop | Out-Null
                    
                    Write-Log "Timestamp inicial establecido para VM $vmName"
                }
                else {
                    # Ya existe timestamp, calcular tiempo de inactividad
                    try {
                        $lastActivity = [DateTime]::Parse($lastActivityTag)
                        $minutesIdle = ((Get-Date) - $lastActivity).TotalMinutes
                        
                        Write-Log "VM $vmName lleva $([Math]::Round($minutesIdle, 2)) minutos sin sesiones activas"
                        
                        if ($minutesIdle -ge $IdleMinutesThreshold) {
                            Write-Log "Umbral de $IdleMinutesThreshold minutos alcanzado. Deteniendo VM $vmName..."
                            
                            # Detener y desasignar la VM
                            Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $vmName -Force -ErrorAction Stop | Out-Null
                            
                            Write-Log "VM $vmName detenida y desasignada exitosamente" -Level Warning
                            
                            # Actualizar tags
                            $vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $vmName -ErrorAction Stop
                            $vm.Tags['LastActivity'] = ''
                            $vm.Tags['LastShutdown'] = (Get-Date).ToString('o')
                            
                            Update-AzVM -ResourceGroupName $ResourceGroupName -VM $vm -Tag $vm.Tags -ErrorAction Stop | Out-Null
                            
                            Write-Log "Tags actualizados para VM $vmName (LastShutdown registrado)"
                        }
                        else {
                            $remainingMinutes = [Math]::Ceiling($IdleMinutesThreshold - $minutesIdle)
                            Write-Log "VM $vmName aún no alcanza el umbral. Faltan ~$remainingMinutes minutos."
                        }
                    }
                    catch {
                        Write-Log "Error al parsear LastActivity tag de VM $vmName. Restableciendo timestamp..." -Level Warning
                        
                        # Resetear timestamp en caso de error
                        $vm.Tags['LastActivity'] = (Get-Date).ToString('o')
                        Update-AzVM -ResourceGroupName $ResourceGroupName -VM $vm -Tag $vm.Tags -ErrorAction Stop | Out-Null
                    }
                }
            }
            catch {
                Write-Log "Error al procesar VM $vmName: $_" -Level Error
            }
        }
        
        Write-Log "--- Fin procesamiento VM $vmName ---`n"
    }
    
    Write-Log "Verificación completada exitosamente"
}
catch {
    Write-Log "Error crítico en el runbook: $_" -Level Error
    throw
}
finally {
    # Desconectar sesión de Azure
    Disconnect-AzAccount -ErrorAction SilentlyContinue | Out-Null
}
