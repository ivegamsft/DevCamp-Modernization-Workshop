targetScope = 'resourceGroup'

@description('Short prefix for resource names (lowercase alphanumeric, 3–12 chars).')
@minLength(3)
@maxLength(12)
param namePrefix string

@description('Azure region for all resources.')
param location string = resourceGroup().location

@description('Cosmos DB database name.')
param cosmosDatabaseName string = 'DevCamp'

@description('Cosmos DB container name.')
param cosmosContainerName string = 'Incidents'

@description('App Service plan SKU (workshop default: inexpensive Linux plan).')
param appServicePlanSku string = 'B1'

@description('When true, Cosmos DB account disables keys and requires Entra ID (RBAC) data plane access.')
param cosmosDisableLocalAuth bool = true

var uniqueSuffix = uniqueString(resourceGroup().id, namePrefix)
var cosmosAccountName = toLower('${namePrefix}cosmos${uniqueSuffix}')
var appServicePlanName = '${namePrefix}-plan-${uniqueSuffix}'
var webAppName = toLower('${namePrefix}-api-${uniqueSuffix}')

module cosmos 'modules/cosmos.bicep' = {
  name: 'cosmosDeploy'
  params: {
    location: location
    accountName: cosmosAccountName
    databaseName: cosmosDatabaseName
    containerName: cosmosContainerName
    disableLocalAuth: cosmosDisableLocalAuth
  }
}

module app 'modules/appservice.bicep' = {
  name: 'appDeploy'
  params: {
    location: location
    planName: appServicePlanName
    webAppName: webAppName
    planSku: appServicePlanSku
    cosmosEndpoint: cosmos.outputs.accountEndpoint
    cosmosDatabaseName: cosmosDatabaseName
    cosmosContainerName: cosmosContainerName
  }
}

module rbac 'modules/rbac-cosmos.bicep' = {
  name: 'cosmosRbac'
  params: {
    cosmosAccountName: cosmos.outputs.accountName
    principalId: app.outputs.principalId
  }
}

output cosmosAccountName string = cosmos.outputs.accountName
output cosmosEndpoint string = cosmos.outputs.accountEndpoint
output webAppName string = app.outputs.webAppName
output webAppHostName string = app.outputs.defaultHostName
output webAppPrincipalId string = app.outputs.principalId
