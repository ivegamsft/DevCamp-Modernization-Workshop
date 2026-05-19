# Step 2 — RBAC (no keys) and infrastructure as code

## Why this step exists

The legacy DevCamp stack stored **Cosmos/Storage keys** in `Web.config`. The modern workshop path removes that pattern:

- **Cosmos DB**: `disableLocalAuth: true` in Bicep (no account keys).
- **Application**: `DefaultAzureCredential` + **Cosmos DB Built-in Data Contributor** on the App Service managed identity.
- **Provisioning**: Bicep under `infra/` — no portal click-ops for the happy path.

## Learner flow

0. Run bootstrap once: [`docs/deployment/bootstrap.md`](../deployment/bootstrap.md) (`scripts/bootstrap/Bootstrap-AzureGitHub.ps1`).
1. Deploy `infra/main.bicep` (CLI or GitHub Actions).
2. Confirm role assignment for the web app identity in the deployment outputs.
3. Run or deploy `DevCamp.Api` with only `CosmosDb:Endpoint` configured.
4. Use AI prompts in `playbooks/prompts/03-identity-rbac.md` and `04-iac-bicep.md` to explain the diff from legacy config.

## Verification

```powershell
# After deploy, hit the App Service host
curl "https://<webAppHostName>/incidents/sampledata"
curl "https://<webAppHostName>/incidents"
```

## Teaching checkpoint

Ask: *What breaks if someone pastes a Cosmos connection string into app settings now?*  
Expected answer: keys are disabled at the account; the app no longer reads connection strings anyway.
