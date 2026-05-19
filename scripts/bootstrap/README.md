# Bootstrap scripts

| File | Purpose |
|------|--------|
| [`Bootstrap-AzureGitHub.ps1`](Bootstrap-AzureGitHub.ps1) | Creates Entra app + OIDC federated credential, RG RBAC, GitHub secrets |
| [`bootstrap.config.example.json`](bootstrap.config.example.json) | Copy to `bootstrap.config.json` and edit |

Full guide: [`docs/deployment/bootstrap.md`](../../docs/deployment/bootstrap.md).

```powershell
Copy-Item bootstrap.config.example.json bootstrap.config.json
# Edit subscriptionId, githubOwner, githubRepo, ...
.\Bootstrap-AzureGitHub.ps1 -ConfigPath .\bootstrap.config.json
```
