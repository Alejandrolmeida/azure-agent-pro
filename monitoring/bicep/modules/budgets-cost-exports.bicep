// Budgets and cost exports for cost control and showback
// Monitors monthly and daily spending with automated alerts

@description('Subscription ID for budget scope')
param subscriptionId string = subscription().subscriptionId

@description('Action Group ID for budget alerts')
param actionGroupId string

@description('Storage Account ID for cost exports')
param storageAccountId string

@description('Storage container name for cost exports')
param exportContainerName string = 'costexports'

@description('Resource tags')
param tags object = {}

@description('Monthly budget amount in EUR')
param monthlyBudgetAmount int = 300

@description('Daily budget amount in EUR')
param dailyBudgetAmount int = 15

@description('Budget start date (YYYY-MM-01 format)')
param budgetStartDate string = utcNow('yyyy-MM-01')

@description('Alert thresholds (percentages)')
param alertThresholds array = [ 50, 80, 90, 100, 110 ]

@description('Enable cost exports')
param enableCostExports bool = true

@description('Filter by tag - environment')
param tagFilterEnv string = 'lab'

@description('Filter by tag - project')
param tagFilterProject string = 'fotogrametria-azure-ia'

// Monthly Budget at subscription scope
resource monthlyBudget 'Microsoft.Consumption/budgets@2023-05-01' = {
  name: 'avd-lab-monthly-budget'
  scope: subscription()
  properties: {
    category: 'Cost'
    amount: monthlyBudgetAmount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: budgetStartDate
      endDate: dateTimeAdd(budgetStartDate, 'P3Y')
    }
    filter: {
      tags: {
        name: 'env'
        operator: 'In'
        values: [ tagFilterEnv ]
      }
    }
    notifications: {
      NotificationAt50: {
        enabled: true
        operator: 'GreaterThan'
        threshold: alertThresholds[0]
        contactGroups: [ actionGroupId ]
        thresholdType: 'Actual'
        locale: 'en-us'
      }
      NotificationAt80: {
        enabled: true
        operator: 'GreaterThan'
        threshold: alertThresholds[1]
        contactGroups: [ actionGroupId ]
        thresholdType: 'Actual'
        locale: 'en-us'
      }
      NotificationAt90: {
        enabled: true
        operator: 'GreaterThan'
        threshold: alertThresholds[2]
        contactGroups: [ actionGroupId ]
        thresholdType: 'Actual'
        locale: 'en-us'
      }
      NotificationAt100Actual: {
        enabled: true
        operator: 'GreaterThan'
        threshold: alertThresholds[3]
        contactGroups: [ actionGroupId ]
        thresholdType: 'Actual'
        locale: 'en-us'
      }
      NotificationAt100Forecasted: {
        enabled: true
        operator: 'GreaterThan'
        threshold: alertThresholds[3]
        contactGroups: [ actionGroupId ]
        thresholdType: 'Forecasted'
        locale: 'en-us'
      }
      NotificationAt110: {
        enabled: true
        operator: 'GreaterThan'
        threshold: alertThresholds[4]
        contactGroups: [ actionGroupId ]
        thresholdType: 'Actual'
        locale: 'en-us'
      }
    }
  }
}

// Daily Budget at subscription scope (controls runaway costs)
resource dailyBudget 'Microsoft.Consumption/budgets@2023-05-01' = {
  name: 'avd-lab-daily-budget'
  scope: subscription()
  properties: {
    category: 'Cost'
    amount: dailyBudgetAmount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: budgetStartDate
      endDate: dateTimeAdd(budgetStartDate, 'P3Y')
    }
    filter: {
      tags: {
        name: 'env'
        operator: 'In'
        values: [ tagFilterEnv ]
      }
    }
    notifications: {
      DailyAt80: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        contactGroups: [ actionGroupId ]
        thresholdType: 'Actual'
        locale: 'en-us'
      }
      DailyAt100: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        contactGroups: [ actionGroupId ]
        thresholdType: 'Actual'
        locale: 'en-us'
      }
    }
  }
}

// Budget by Resource Group (for multi-RG scenarios)
resource rgBudget 'Microsoft.Consumption/budgets@2023-05-01' = {
  name: 'avd-lab-rg-budget'
  scope: resourceGroup()
  properties: {
    category: 'Cost'
    amount: monthlyBudgetAmount / 2  // Half of total budget per RG
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: budgetStartDate
      endDate: dateTimeAdd(budgetStartDate, 'P3Y')
    }
    notifications: {
      RgAt80: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        contactGroups: [ actionGroupId ]
        thresholdType: 'Actual'
        locale: 'en-us'
      }
      RgAt100: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        contactGroups: [ actionGroupId ]
        thresholdType: 'Actual'
        locale: 'en-us'
      }
    }
  }
}

// Budget by Tag (Owner) - for showback per student
resource ownerBudget 'Microsoft.Consumption/budgets@2023-05-01' = {
  name: 'avd-lab-owner-budget'
  scope: subscription()
  properties: {
    category: 'Cost'
    amount: 50  // Per-student budget
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: budgetStartDate
      endDate: dateTimeAdd(budgetStartDate, 'P3Y')
    }
    filter: {
      tags: {
        name: 'owner'
        operator: 'In'
        values: [ '*' ]  // Will alert for any owner tag
      }
    }
    notifications: {
      OwnerAt100: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        contactGroups: [ actionGroupId ]
        thresholdType: 'Actual'
        locale: 'en-us'
      }
    }
  }
}

// Cost Export - Daily actual costs
resource costExportDaily 'Microsoft.CostManagement/exports@2023-03-01' = if (enableCostExports) {
  name: 'avd-lab-cost-export-daily'
  scope: subscription()
  properties: {
    schedule: {
      status: 'Active'
      recurrence: 'Daily'
      recurrencePeriod: {
        from: budgetStartDate
        to: dateTimeAdd(budgetStartDate, 'P3Y')
      }
    }
    format: 'Csv'
    deliveryInfo: {
      destination: {
        resourceId: storageAccountId
        container: exportContainerName
        rootFolderPath: 'daily-actual'
      }
    }
    definition: {
      type: 'ActualCost'
      timeframe: 'MonthToDate'
      dataSet: {
        granularity: 'Daily'
        configuration: {
          columns: [
            'Date'
            'ResourceId'
            'ResourceType'
            'ResourceGroupName'
            'ResourceLocation'
            'MeterCategory'
            'MeterSubCategory'
            'MeterName'
            'Quantity'
            'UnitOfMeasure'
            'CostInBillingCurrency'
            'BillingCurrency'
            'Tags'
          ]
        }
        filter: {
          tags: {
            name: 'env'
            operator: 'In'
            values: [ tagFilterEnv ]
          }
        }
      }
    }
  }
}

// Cost Export - Monthly amortized costs
resource costExportMonthly 'Microsoft.CostManagement/exports@2023-03-01' = if (enableCostExports) {
  name: 'avd-lab-cost-export-monthly'
  scope: subscription()
  properties: {
    schedule: {
      status: 'Active'
      recurrence: 'Monthly'
      recurrencePeriod: {
        from: budgetStartDate
        to: dateTimeAdd(budgetStartDate, 'P3Y')
      }
    }
    format: 'Csv'
    deliveryInfo: {
      destination: {
        resourceId: storageAccountId
        container: exportContainerName
        rootFolderPath: 'monthly-amortized'
      }
    }
    definition: {
      type: 'AmortizedCost'
      timeframe: 'MonthToDate'
      dataSet: {
        granularity: 'Daily'
        configuration: {
          columns: [
            'Date'
            'ResourceId'
            'ResourceType'
            'ResourceGroupName'
            'ResourceLocation'
            'MeterCategory'
            'MeterSubCategory'
            'MeterName'
            'Quantity'
            'UnitOfMeasure'
            'CostInBillingCurrency'
            'BillingCurrency'
            'EffectivePrice'
            'Tags'
          ]
        }
        filter: {
          tags: {
            name: 'env'
            operator: 'In'
            values: [ tagFilterEnv ]
          }
        }
      }
    }
  }
}

// Outputs
output monthlyBudgetId string = monthlyBudget.id
output dailyBudgetId string = dailyBudget.id
output rgBudgetId string = rgBudget.id
output ownerBudgetId string = ownerBudget.id
output costExportDailyId string = enableCostExports ? costExportDaily.id : ''
output costExportMonthlyId string = enableCostExports ? costExportMonthly.id : ''

