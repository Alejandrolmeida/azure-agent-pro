// ============================================================================
// Cost Management Module - Budgets y Alertas
// ============================================================================
// Control presupuestario con alertas automáticas
// Infraestructura: €20/mes | Workload: €50/día (€1,500/mes)
// ============================================================================

@description('Presupuesto mensual para infraestructura (€)')
param infrastructureBudgetAmount int

@description('Presupuesto mensual para workload (€)')
param workloadBudgetAmount int

@description('Email para alertas presupuestarias')
param alertEmailAddress string

@description('Fecha de inicio del presupuesto (formato yyyy-MM-dd)')
param budgetStartDate string = '${utcNow('yyyy-MM')}-01'

// ============================================================================
// VARIABLES
// ============================================================================

var infrastructureBudgetName = 'budget-infrastructure-monthly'
var workloadBudgetName = 'budget-workload-monthly'

// Action Group para notificaciones
var actionGroupName = 'ag-cost-alerts'

// ============================================================================
// ACTION GROUP - Email Notifications
// ============================================================================

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: 'Global'
  properties: {
    groupShortName: 'CostAlerts'
    enabled: true
    emailReceivers: [
      {
        name: 'EmailAdmin'
        emailAddress: alertEmailAddress
        useCommonAlertSchema: true
      }
    ]
  }
}

// ============================================================================
// BUDGET - Infrastructure (Tag: workload-type=infrastructure)
// ============================================================================

resource infrastructureBudget 'Microsoft.Consumption/budgets@2023-11-01' = {
  name: infrastructureBudgetName
  properties: {
    timePeriod: {
      startDate: budgetStartDate
    }
    timeGrain: 'Monthly'
    amount: infrastructureBudgetAmount
    category: 'Cost'
    filter: {
      and: [
        {
          dimensions: {
            name: 'ResourceGroupName'
            operator: 'In'
            values: [
              resourceGroup().name
            ]
          }
        }
        {
          tags: {
            name: 'workload-type'
            operator: 'In'
            values: [
              'infrastructure'
            ]
          }
        }
      ]
    }
    notifications: {
      Actual_80_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        contactEmails: [
          alertEmailAddress
        ]
        thresholdType: 'Actual'
      }
      Actual_90_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 90
        contactEmails: [
          alertEmailAddress
        ]
        thresholdType: 'Actual'
      }
      Actual_100_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        contactEmails: [
          alertEmailAddress
        ]
        thresholdType: 'Actual'
      }
      Forecasted_100_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        contactEmails: [
          alertEmailAddress
        ]
        thresholdType: 'Forecasted'
      }
    }
  }
}

// ============================================================================
// BUDGET - Workload (Tag: workload-type=session-host)
// ============================================================================

resource workloadBudget 'Microsoft.Consumption/budgets@2023-11-01' = {
  name: workloadBudgetName
  properties: {
    timePeriod: {
      startDate: budgetStartDate
    }
    timeGrain: 'Monthly'
    amount: workloadBudgetAmount
    category: 'Cost'
    filter: {
      and: [
        {
          dimensions: {
            name: 'ResourceGroupName'
            operator: 'In'
            values: [
              resourceGroup().name
            ]
          }
        }
        {
          tags: {
            name: 'workload-type'
            operator: 'In'
            values: [
              'session-host'
            ]
          }
        }
      ]
    }
    notifications: {
      Actual_80_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        contactEmails: [
          alertEmailAddress
        ]
        thresholdType: 'Actual'
      }
      Actual_90_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 90
        contactEmails: [
          alertEmailAddress
        ]
        thresholdType: 'Actual'
      }
      Actual_100_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        contactEmails: [
          alertEmailAddress
        ]
        thresholdType: 'Actual'
      }
      Forecasted_100_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        contactEmails: [
          alertEmailAddress
        ]
        thresholdType: 'Forecasted'
      }
    }
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output infrastructureBudgetId string = infrastructureBudget.id
output workloadBudgetId string = workloadBudget.id
output actionGroupId string = actionGroup.id
