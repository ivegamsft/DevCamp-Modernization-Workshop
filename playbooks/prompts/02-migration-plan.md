# Prompt 02 — Phased migration plan

Prerequisite: output from [01-inventory.md](01-inventory.md).

---

Using the inventory below, propose a **phased migration** to:

- ASP.NET Core 8 (LTS) for web/API workloads
- Azure Cosmos DB SDK v3 with **Entra ID RBAC** (no account keys)
- Bicep for infrastructure (no portal click-ops)
- GitHub Actions for CI and optional CD

Constraints:

- Each phase must **build and deploy independently**.
- Preserve HTTP routes and JSON shapes unless you list an explicit breaking change.
- Call out which legacy paths stay in `legacy/` for comparison only.

Deliver:

1. Phase table (name, scope, exit criteria, estimated effort S/M/L).
2. Rollback strategy per phase.
3. List of files/projects touched per phase.

Do not write code until I approve the phase list.

**Inventory:**

```text
(paste 01-inventory output here)
```
