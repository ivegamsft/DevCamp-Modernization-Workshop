# DevCamp modernization workshop

Hands-on workshop for **AI-assisted brownfield upgrades**, based on the historical [Azure DevCamp](https://github.com/Azure/DevCamp) materials. Compare `legacy/` with `modern/`, deploy with **Bicep** (no click-ops), authenticate with **RBAC** (no Cosmos keys), and automate with **GitHub Actions**.

**Repository:** [github.com/ivegamsft/DevCamp-Modernization-Workshop](https://github.com/ivegamsft/DevCamp-Modernization-Workshop)

## Repository layout

| Path | Purpose |
|------|--------|
| [`legacy/`](legacy/) | Original workshop snapshot (reference only; may require NuGet/npm restore to build). |
| [`modern/`](modern/) | ASP.NET Core 8 API and future migrated apps. |
| [`infra/`](infra/) | Bicep — Cosmos DB, App Service, managed identity, Cosmos data-plane RBAC. |
| [`.github/workflows/`](.github/workflows/) | CI, infrastructure deploy (OIDC), API deploy. |
| [`playbooks/`](playbooks/) | Proven AI prompts and human checklists. |
| [`docs/`](docs/) | Migration journal, architecture, deployment guides. |

## Quick start (modern API + RBAC)

### 1. Deploy infrastructure (no portal)

```powershell
az group create -n rg-devcamp-modern -l eastus2
cd infra
az deployment group create `
  --resource-group rg-devcamp-modern `
  --template-file main.bicep `
  --parameters parameters/dev.bicepparam
```

Save outputs: `cosmosEndpoint`, `webAppName`, `webAppHostName`.

### 2. Local run (Entra ID, no keys)

Sign in and grant yourself **Cosmos DB Built-in Data Contributor** on the account (see [`infra/README.md`](infra/README.md)), then:

```powershell
cd modern\dotnet\DevCamp.Api
$env:CosmosDb__Endpoint = "https://<account>.documents.azure.com:443/"
dotnet run
```

### 3. CI/CD

Configure GitHub OIDC secrets per [`docs/deployment/github-oidc.md`](docs/deployment/github-oidc.md), then run **Deploy infrastructure** and **Deploy API** workflows.

## AI-assisted modernization

Use prompts in order: [`playbooks/README.md`](playbooks/README.md) (`01-inventory` → `07-verification`). Require [`playbooks/checklists/rbac-no-keys.md`](playbooks/checklists/rbac-no-keys.md) before merge.

## Documentation

1. [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
2. [`docs/MIGRATION-JOURNAL.md`](docs/MIGRATION-JOURNAL.md)
3. [`docs/steps/`](docs/steps/) — step-by-step labs
4. [`docs/deployment/github-oidc.md`](docs/deployment/github-oidc.md)

## Prerequisites

- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)
- Azure subscription with permission to deploy Cosmos DB and assign SQL data-plane roles

## Credits

Derived from Azure DevCamp (MIT). See [`NOTICE.md`](NOTICE.md) and [`LICENSE`](LICENSE).
