# Prompt 03 — Identity: keys to RBAC

Prerequisite: approved migration plan including data stores.

---

Refactor data access to **eliminate account keys and connection strings** for Azure services.

Requirements:

1. Use **managed identity** on App Service (system-assigned unless I specify user-assigned).
2. Use **DefaultAzureCredential** in .NET for Cosmos DB.
3. Document required **Cosmos DB Built-in Data Contributor** (or Reader) role assignment scope.
4. Set Cosmos account **`disableLocalAuth: true`** in Bicep when appropriate.
5. Map legacy `Web.config` / `appSettings` keys to new `appsettings` + environment variables (no secrets in git).

Produce:

- Before/after configuration table.
- Bicep snippet for role assignment (`sqlRoleAssignments`).
- C# factory or startup code for `CosmosClient`.
- Local dev instructions using `az login` (not keys).

Flag any service that cannot use RBAC yet and propose a mitigating control.

**Legacy config excerpt (if any):**

```xml
(paste Web.config appSettings here)
```
