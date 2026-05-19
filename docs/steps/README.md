# Step-by-step migration notes

| Step | File | Summary |
|------|------|---------|
| 0 | [00-repo-bootstrap.md](00-repo-bootstrap.md) | Create `legacy/` snapshot, cleanup, Git init. |
| 1 | [01-migrate-incident-api.md](01-migrate-incident-api.md) | Incident REST API → ASP.NET Core 8 + Cosmos DB SDK v3. |
| 2 | [02-rbac-and-iac.md](02-rbac-and-iac.md) | RBAC (no keys), Bicep, GitHub Actions OIDC. |

Return to the [migration journal](../MIGRATION-JOURNAL.md) for the authoritative chronological log.
