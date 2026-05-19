# Prompt 04 — Infrastructure as code (Bicep)

---

Create or extend **Bicep** modules for this workshop API:

Resources:

- Resource group–scoped deployment
- Cosmos DB SQL API account (database + container, partition key `/id`, 400 RU/s)
- Linux App Service plan + Web App (.NET 8)
- System-assigned managed identity on the Web App
- Cosmos **data-plane** role assignment for the Web App identity
- App settings: `CosmosDb__Endpoint`, `CosmosDb__DatabaseId`, `CosmosDb__ContainerId` only (no keys)

Requirements:

- Parameterize `namePrefix`, `location`, database/container names.
- Output: `cosmosEndpoint`, `webAppName`, `webAppHostName`, `webAppPrincipalId`.
- Include `infra/README.md` deploy commands for `az deployment group create`.
- Add GitHub Actions workflow using **OIDC** (`azure/login@v2`), not client secrets.

Do not use the Azure Portal steps in the lab narrative—CLI/Actions only.

Match patterns already in `infra/` if present; otherwise generate consistent module layout under `infra/modules/`.
