# Bootstrap Azure + GitHub OIDC (one-time)

Use this guide and the **`scripts/bootstrap/Bootstrap-AzureGitHub.ps1`** script to prepare everything GitHub Actions needs—**no client secrets**, only OIDC federation and three repository secrets.

## What gets configured

| Item | Purpose |
|------|--------|
| Resource group (optional) | Target for Bicep (`infra/main.bicep`) |
| App registration | Identity GitHub uses to authenticate to Azure |
| Federated credential | Trusts `token.actions.githubusercontent.com` for your repo/branch |
| RBAC on resource group | **Contributor** (deploy resources) + **User Access Administrator** (Cosmos data-plane role assignments in Bicep) |
| GitHub secrets | `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` |

The script does **not** deploy Cosmos or the API—that is done by workflows after bootstrap.

## Prerequisites

| Tool | Check |
|------|--------|
| [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) | `az version` |
| [GitHub CLI](https://cli.github.com/) | `gh auth login` (needed if `setGitHubSecrets: true`) |
| Permissions | Ability to create app registrations and assign roles on the subscription or resource group (Owner or custom equivalent) |
| Repository admin | Required on GitHub to set Actions secrets |

Sign in to Azure:

```powershell
az login
az account set --subscription "<your-subscription-id>"
```

## Quick run

```powershell
cd scripts\bootstrap
Copy-Item bootstrap.config.example.json bootstrap.config.json
notepad bootstrap.config.json   # set subscriptionId, githubOwner, githubRepo, etc.
.\Bootstrap-AzureGitHub.ps1 -ConfigPath .\bootstrap.config.json
```

Preview only:

```powershell
.\Bootstrap-AzureGitHub.ps1 -ConfigPath .\bootstrap.config.json -DryRun
```

### Config file fields

| Field | Description |
|-------|-------------|
| `subscriptionId` | Azure subscription for deployments |
| `tenantId` | Optional; defaults to current `az account` tenant |
| `resourceGroupName` | e.g. `rg-devcamp-modern` |
| `location` | e.g. `eastus2` |
| `githubOwner` | GitHub org or user (`ivegamsft`) |
| `githubRepo` | Repository name |
| `githubBranch` | Branch for OIDC subject (default `main`) |
| `githubEnvironment` | If set, subject uses `environment:<name>` instead of branch |
| `appRegistrationDisplayName` | Display name for the Entra app |
| `federatedCredentialName` | Unique name for the federated credential |
| `createResourceGroup` | `true` to run `az group create` |
| `assignResourceGroupRoles` | `true` to assign Contributor + UAA on the RG |
| `setGitHubSecrets` | `true` to run `gh secret set` |

`bootstrap.config.json` is listed in `.gitignore` so local IDs are not committed. **`bootstrap-output.json`** is also ignored (contains client/tenant IDs).

## After bootstrap

### 1. Deploy infrastructure (GitHub Actions)

Actions → **Deploy infrastructure** → Run workflow:

- Resource group: same as config (e.g. `rg-devcamp-modern`)
- Location / name prefix: as needed

Save outputs from the job summary: `webAppName`, `webAppHostName`, `cosmosEndpoint`.

### 2. Deploy API

Actions → **Deploy API**:

- Resource group: `rg-devcamp-modern`
- Web app name: from Bicep output

### 3. Local development (optional)

Your user needs Cosmos **data-plane** access (keys are disabled in Bicep):

```powershell
# After first infra deploy — replace account name from output
$rg = "rg-devcamp-modern"
$accountName = "<cosmosAccountName from output>"
$scope = az cosmosdb show -g $rg -n $accountName --query id -o tsv
$userId = az ad signed-in-user show --query id -o tsv
az cosmosdb sql role assignment create `
  --account-name $accountName `
  --resource-group $rg `
  --role-definition-id 00000000-0000-0000-0000-000000000002 `
  --principal-id $userId `
  --scope $scope
```

```powershell
cd modern\dotnet\DevCamp.Api
$env:CosmosDb__Endpoint = "https://<account>.documents.azure.com:443/"
dotnet run
```

## Manual setup (no script)

If you cannot run the script, follow the same steps in [github-oidc.md](github-oidc.md) and assign:

- **Contributor** on the resource group to the app’s service principal  
- **User Access Administrator** on the resource group (for Cosmos `sqlRoleAssignments` in Bicep)

Federated credential **subject** examples:

| Scenario | Subject |
|----------|---------|
| Branch `main` | `repo:ivegamsft/DevCamp-Modernization-Workshop:ref:refs/heads/main` |
| Environment `production` | `repo:ivegamsft/DevCamp-Modernization-Workshop:environment:production` |

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `AADSTS700213` / no matching federated identity | Subject must match repo, branch, or environment exactly; re-run bootstrap or edit credential in Entra portal |
| Bicep fails on Cosmos role assignment | Ensure **User Access Administrator** on the RG for the GitHub SP |
| `gh secret set` permission denied | `gh auth refresh -s admin:repo` or set secrets manually in GitHub UI |
| Local API 403 to Cosmos | Assign **Cosmos DB Built-in Data Contributor** to your user on the account |

## Security notes

- Do not commit `bootstrap.config.json` or export files with keys.
- Prefer **branch** or **environment**-scoped federated credentials over `repo:*` wildcards.
- Rotate by creating a new federated credential name and removing the old one in Entra.

See also: [github-oidc.md](github-oidc.md), [infra/README.md](../../infra/README.md).
