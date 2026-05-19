@description('Azure region.')
param location string

param planName string
param webAppName string
param planSku string

@description('Cosmos account document endpoint (https://....documents.azure.com:443/).')
param cosmosEndpoint string

param cosmosDatabaseName string
param cosmosContainerName string

resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: planName
  location: location
  sku: {
    name: planSku
    capacity: 1
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|8.0'
      alwaysOn: true
      appSettings: [
        {
          name: 'CosmosDb__Endpoint'
          value: cosmosEndpoint
        }
        {
          name: 'CosmosDb__DatabaseId'
          value: cosmosDatabaseName
        }
        {
          name: 'CosmosDb__ContainerId'
          value: cosmosContainerName
        }
        {
          name: 'CosmosDb__UseManagedIdentity'
          value: 'true'
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Production'
        }
      ]
    }
  }
}

output webAppName string = webApp.name
output defaultHostName string = webApp.properties.defaultHostName
output principalId string = webApp.identity.principalId
