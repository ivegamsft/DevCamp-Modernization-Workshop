@description('Cosmos DB account name (not FQDN).')
param cosmosAccountName string

@description('Principal ID of the App Service system-assigned managed identity.')
param principalId string

// Built-in Cosmos DB SQL API data plane role (Entra ID RBAC).
// https://learn.microsoft.com/azure/cosmos-db/security/reference-data-plane-roles
var cosmosDataContributorRoleId = '00000000-0000-0000-0000-000000000002'

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' existing = {
  name: cosmosAccountName
}

resource dataContributor 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-05-15' = {
  parent: cosmosAccount
  name: guid(cosmosAccount.id, principalId, cosmosDataContributorRoleId)
  properties: {
    roleDefinitionId: '${cosmosAccount.id}/sqlRoleDefinitions/${cosmosDataContributorRoleId}'
    principalId: principalId
    scope: cosmosAccount.id
  }
}
