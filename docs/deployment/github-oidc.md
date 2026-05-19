# GitHub Actions → Azure (OIDC, no long-lived secrets)

Infrastructure and app deploy workflows use **OpenID Connect** federation instead of storing a client secret in GitHub.

## Recommended: automated bootstrap

Use the script and guide—fastest path:

1. [`docs/deployment/bootstrap.md`](bootstrap.md)
2. [`scripts/bootstrap/Bootstrap-AzureGitHub.ps1`](../../scripts/bootstrap/Bootstrap-AzureGitHub.ps1)

```powershell
cd scripts\bootstrap
Copy-Item bootstrap.config.example.json bootstrap.config.json
# Edit subscriptionId, githubOwner, githubRepo
.\Bootstrap-AzureGitHub.ps1 -ConfigPath .\bootstrap.config.json
```

That creates the Entra app, federated credential, resource group RBAC, and GitHub secrets.

## GitHub repository secrets

| Secret | Value |
|--------|--------|
| `AZURE_CLIENT_ID` | App registration **application (client) ID** |
| `AZURE_TENANT_ID` | Directory (tenant) ID |
| `AZURE_SUBSCRIPTION_ID` | Subscription ID |

No `AZURE_CREDENTIALS` JSON blob with a client secret is required when OIDC is configured correctly.

## Manual setup (reference)

1. Create an **App registration** for GitHub Actions.
2. Add a **federated credential**:
   - Issuer: `https://token.actions.githubusercontent.com`
   - Subject: `repo:ivegamsft/DevCamp-Modernization-Workshop:ref:refs/heads/main` (adjust org/repo/branch)
   - Audience: `api://AzureADTokenExchange`
3. Create a **service principal** for the app and assign on the target resource group:
   - **Contributor**
   - **User Access Administrator** (required for Cosmos DB SQL role assignments in Bicep)

## Run workflows

1. **Deploy infrastructure** — Actions → *Deploy infrastructure* → Run workflow.
2. Note `webAppName` from the job summary.
3. **Deploy API** — Actions → *Deploy API* → enter `web_app_name` and resource group.

## Local parity

Developers use `az login` and Cosmos **data-plane RBAC** (see [`infra/README.md`](../../infra/README.md)). Account keys are disabled when `cosmosDisableLocalAuth` is true in Bicep.
