# GitHub Actions → Azure (OIDC, no long-lived secrets)

Infrastructure and app deploy workflows use **OpenID Connect** federation instead of storing a client secret in GitHub.

## One-time Azure setup

1. Create an **App registration** (or reuse one) for GitHub Actions.
2. Add a **federated credential** for this repository:
   - Issuer: `https://token.actions.githubusercontent.com`
   - Subject: `repo:ivegamsft/DevCamp-Modernization-Workshop:ref:refs/heads/main` (adjust org/repo/branch)
   - Audience: `api://AzureADTokenExchange`
3. Grant the app registration **Contributor** on the target resource group (or subscription for RG creation) and permission to create **Cosmos DB SQL role assignments** (typically **User Access Administrator** on the RG or account scope for workshop deploys).

## GitHub repository secrets

| Secret | Value |
|--------|--------|
| `AZURE_CLIENT_ID` | App registration application (client) ID |
| `AZURE_TENANT_ID` | Directory (tenant) ID |
| `AZURE_SUBSCRIPTION_ID` | Subscription ID |

No `AZURE_CREDENTIALS` JSON blob with a client secret is required when OIDC is configured correctly.

## Run workflows

1. **Deploy infrastructure** — Actions → *Deploy infrastructure* → Run workflow.
2. Note `webAppName` from the job summary.
3. **Deploy API** — Actions → *Deploy API* → enter `web_app_name` and resource group.

## Local parity

Developers use `az login` and Cosmos **data-plane RBAC** (see `infra/README.md`). Account keys are disabled when `cosmosDisableLocalAuth` is true in Bicep.
