using '../main.bicep'

param namePrefix = 'devcamp'
param location = 'eastus2'
param cosmosDatabaseName = 'DevCamp'
param cosmosContainerName = 'Incidents'
param appServicePlanSku = 'B1'
param cosmosDisableLocalAuth = true
