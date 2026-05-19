# Checklist — RBAC, no keys

- [ ] No `AccountKey`, `PrimaryKey`, or full Cosmos connection strings in app settings committed to git
- [ ] Cosmos account has `disableLocalAuth: true` in Bicep (or documented exception for sandbox only)
- [ ] App uses `DefaultAzureCredential` or managed identity credential only
- [ ] Data-plane role assignment exists for App Service **principalId**
- [ ] Developers have a documented path (`az login` + role assignment) without sharing keys
- [ ] GitHub Actions uses OIDC (`azure/login@v2`), not `AZURE_CREDENTIALS` with client secret
- [ ] Legacy `legacy/` samples are labeled reference-only; learners deploy from `modern/` + `infra/`
