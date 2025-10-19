// Data Collection Endpoint and Rules for Windows GPU VMs
// Collects performance counters (GPU, CPU, RAM, Disk) and event logs

@description('Name of the Data Collection Endpoint')
param dceName string

@description('Name of the Data Collection Rule')
param dcrName string

@description('Azure region for the resource')
param location string = resourceGroup().location

@description('Log Analytics Workspace ID')
param lawResourceId string

@description('Resource tags')
param tags object = {}

@description('Performance counter collection frequency (seconds)')
@minValue(10)
@maxValue(900)
param counterFrequency int = 60

// Data Collection Endpoint
resource dce 'Microsoft.Insights/dataCollectionEndpoints@2022-06-01' = {
  name: dceName
  location: location
  tags: tags
  properties: {
    networkAcls: {
      publicNetworkAccess: 'Enabled'
    }
  }
}

// Data Collection Rule for Windows GPU VMs
resource dcr 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: dcrName
  location: location
  tags: tags
  properties: {
    dataCollectionEndpointId: dce.id
    streamDeclarations: {
      'Microsoft-Perf': {
        columns: [
          { name: 'TimeGenerated', type: 'datetime' }
          { name: 'Computer', type: 'string' }
          { name: 'ObjectName', type: 'string' }
          { name: 'CounterName', type: 'string' }
          { name: 'InstanceName', type: 'string' }
          { name: 'CounterValue', type: 'real' }
        ]
      }
      'Microsoft-Event': {
        columns: [
          { name: 'TimeGenerated', type: 'datetime' }
          { name: 'Computer', type: 'string' }
          { name: 'EventID', type: 'int' }
          { name: 'EventLevel', type: 'int' }
          { name: 'EventLevelName', type: 'string' }
          { name: 'EventData', type: 'string' }
          { name: 'Source', type: 'string' }
        ]
      }
    }
    dataSources: {
      performanceCounters: [
        {
          name: 'perfCounterDataSource'
          streams: [ 'Microsoft-Perf' ]
          samplingFrequencyInSeconds: counterFrequency
          counterSpecifiers: [
            // CPU Counters
            '\\Processor(_Total)\\% Processor Time'
            '\\Processor Information(_Total)\\% Processor Time'
            '\\Processor Information(_Total)\\% Privileged Time'
            '\\Processor Information(_Total)\\% User Time'
            '\\Processor Information(_Total)\\Processor Frequency'
            
            // Memory Counters
            '\\Memory\\Available Bytes'
            '\\Memory\\Available MBytes'
            '\\Memory\\% Committed Bytes In Use'
            '\\Memory\\Committed Bytes'
            '\\Memory\\Page Faults/sec'
            '\\Memory\\Pages/sec'
            '\\Memory\\Pool Nonpaged Bytes'
            '\\Memory\\Pool Paged Bytes'
            
            // Disk Counters
            '\\LogicalDisk(_Total)\\% Free Space'
            '\\LogicalDisk(_Total)\\Free Megabytes'
            '\\LogicalDisk(C:)\\% Free Space'
            '\\LogicalDisk(C:)\\Free Megabytes'
            '\\PhysicalDisk(_Total)\\Avg. Disk sec/Read'
            '\\PhysicalDisk(_Total)\\Avg. Disk sec/Write'
            '\\PhysicalDisk(_Total)\\Avg. Disk Queue Length'
            '\\PhysicalDisk(_Total)\\Disk Reads/sec'
            '\\PhysicalDisk(_Total)\\Disk Writes/sec'
            '\\PhysicalDisk(_Total)\\Disk Bytes/sec'
            
            // Network Counters
            '\\Network Interface(*)\\Bytes Total/sec'
            '\\Network Interface(*)\\Bytes Sent/sec'
            '\\Network Interface(*)\\Bytes Received/sec'
            '\\Network Interface(*)\\Packets/sec'
            
            // GPU Counters (NVIDIA A10)
            '\\GPU Engine(*)\\Utilization Percentage'
            '\\GPU Adapter Memory(*)\\Dedicated Usage'
            '\\GPU Adapter Memory(*)\\Shared Usage'
            '\\GPU Adapter Memory(*)\\Total Committed'
            '\\GPU Process Memory(*)\\Dedicated Usage'
            '\\GPU Process Memory(*)\\Shared Usage'
            
            // AVD-specific Counters
            '\\RemoteFX Network(*)\\Current TCP RTT'
            '\\RemoteFX Network(*)\\Current UDP Bandwidth'
            '\\User Input Delay per Process(*)\\Max Input Delay'
            '\\User Input Delay per Session(*)\\Max Input Delay'
            '\\RemoteFX Graphics(*)\\Average Encoding Time'
            '\\RemoteFX Graphics(*)\\Frame Quality'
          ]
        }
      ]
      windowsEventLogs: [
        {
          name: 'eventLogsDataSource'
          streams: [ 'Microsoft-Event' ]
          xPathQueries: [
            // AVD Session Events
            'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational!*[System[(Level=1 or Level=2 or Level=3 or Level=4)]]'
            'Microsoft-Windows-TerminalServices-RemoteConnectionManager/Admin!*[System[(Level=1 or Level=2 or Level=3)]]'
            
            // FSLogix Events
            'Microsoft-FSLogix-Apps/Operational!*[System[(Level=1 or Level=2 or Level=3)]]'
            'Microsoft-FSLogix-Apps/Admin!*[System[(Level=1 or Level=2 or Level=3)]]'
            
            // System Events
            'System!*[System[(Level=1 or Level=2 or Level=3)]]'
            'Application!*[System[(Level=1 or Level=2 or Level=3)]]'
            
            // Security Events (failed logins)
            'Security!*[System[(EventID=4625)]]'
          ]
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: lawResourceId
          name: 'avd-law-destination'
        }
      ]
    }
    dataFlows: [
      {
        streams: [ 'Microsoft-Perf' ]
        destinations: [ 'avd-law-destination' ]
      }
      {
        streams: [ 'Microsoft-Event' ]
        destinations: [ 'avd-law-destination' ]
      }
    ]
  }
}

// Outputs
output dceId string = dce.id
output dceName string = dce.name
output dcrId string = dcr.id
output dcrName string = dcr.name
output dceEndpoint string = dce.properties.logsIngestion.endpoint

