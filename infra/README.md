# Infrastructure (Bicep) — no click ops

All Azure resources for the modern workshop path are defined here and deployed with the Azure CLI or GitHub Actions. **No account keys**: Cosmos DB uses **Entra ID data-plane RBAC**; the API uses the App Service **system-assigned managed identity**.

## What gets deployed

| Resource | Purpose |
|----------|---------|
| Cosmos DB (SQL API) | Incident store; `disableLocalAuth: true` when `cosmosDisableLocalAuth` is true |
| App Service (Linux, .NET 8) | Hosts `DevCamp.Api` |
| Cosmos SQL role assignment | **Cosmos DB Built-in Data Contributor** for the web app managed identity |

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) 2.55+
- `az login` (and rights to create resources + assign Cosmos data-plane roles in the target subscription)
- Resource group (create once):

```powershell
az group create -n rg-devcamp-modern -l eastus2
```

## Deploy locally

```powershell
cd infra
az deployment group create `
  --resource-group rg-devcamp-modern `
  --template-file main.bicep `
  --parameters parameters/dev.bicepparam
```

Note outputs: `cosmosEndpoint`, `webAppName`, `webAppHostName`.

## Local API against deployed Cosmos (no keys)

1. Deploy infra (above).
2. Grant **your user** the same data-plane role for dev testing, or use a dev account with access:

```powershell
# Example: assign Cosmos DB Built-in Data Contributor to your signed-in user on the account
$accountId = az cosmosdb show -g rg-devcamp-modern -n <cosmosAccountName> --query id -o tsv
$yourId = az ad signed-in-user show --query id -o tsv
az cosmosdb sql role assignment create `
  --account-name <cosmosAccountName> `
  --resource-group rg-devcamp-modern `
  --role-definition-id 00000000-0000-0000-0000-000000000002 `
  --principal-id $yourId `
  --scope $accountId
```

3. Run the API with endpoint only:

```powershell
cd ..\modern\dotnet\DevCamp.Api
$env:CosmosDb__Endpoint = "https://<account>.documents.azure.com:443/"
$env:CosmosDb__UseManagedIdentity = "true"
dotnet run
```

Uses `DefaultAzureCredential` (Azure CLI / VS / managed identity).

## CI/CD

See [`.github/workflows/`](../.github/workflows/) and [`docs/deployment/github-oidc.md`](../docs/deployment/github-oidc.md).
