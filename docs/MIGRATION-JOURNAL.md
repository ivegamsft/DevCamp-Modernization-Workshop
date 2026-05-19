# Migration journal

Chronological record of repository creation and migrations. **Update this file** whenever you add a module, change behavior, or complete a migration milestone.

---

## 2026-05-19 — Repository bootstrap

1. **Created folder** `f:\Git\DevCamp-Modernization-Workshop` as the new workshop root (sibling to the original `f:\Git\DevCamp` clone).
2. **Copied upstream workshop** into `legacy/` using `robocopy` from `f:\Git\DevCamp`, excluding `.git` and `.vs` so the new repo does not reuse the old Git history.
3. **Pruned restore artifacts** under `legacy/` (`packages`, `bin`, `obj`, `node_modules`) to reduce size and avoid committing binaries. Learners can run `nuget restore` / `npm install` in specific labs when comparing against legacy behavior.
4. **Added legal / attribution**: copied `LICENSE` from legacy MIT terms to repo root; added `NOTICE.md` describing DevCamp provenance and new layers.
5. **Added `.gitignore`** for build outputs, packages, secrets patterns, and IDE cruft.
6. **Initialized Git** in the workshop root (`git init`). A first commit was left for you to author locally (see root `README.md`).

---

## 2026-05-19 — Milestone 1: Incident API (`Shared/API`) → ASP.NET Core 8

### Source of truth (legacy)

- Project: `legacy/Shared/API/DevCamp.API/` — ASP.NET Web API on **.NET Framework 4.5**, `packages.config`, **Microsoft.Azure.DocumentDB** client, `Web.config` app settings (`DOCUMENTDB_*`, storage keys, etc.).
- Primary HTTP surface: `IncidentController` attribute routes on paths such as `incidents`, `incidents/{IncidentId}`, `incidents/count`, `PUT incidents?IncidentId=...` (query string preserved for existing `IncidentAPIClient`).

### Target (modern)

- Project: `modern/dotnet/DevCamp.Api/` — **ASP.NET Core 8** minimal hosting + **controllers**.
- Data: **Azure Cosmos DB .NET SDK v3** (`Microsoft.Azure.Cosmos`) replacing `DocumentClient`.
- Configuration: `appsettings.json` + environment variables + user-secrets; supports both `CosmosDb:*` and legacy-style `DOCUMENTDB_*` keys for teaching mapping from `Web.config`.
- Seed JSON: copied `SampleIncidents.json` and `FakeIncidents.json` into `DevCamp.Api/Data/` with `CopyToOutputDirectory`.

### Design decisions (document for learners)

| Topic | Decision |
|--------|-----------|
| Route compatibility | Kept the same URL shapes and `PUT` query parameter `IncidentId` so legacy auto-generated clients keep working. |
| JSON | `Microsoft.AspNetCore.Mvc.NewtonsoftJson` to preserve Newtonsoft serialization behavior and `[JsonProperty("id")]` on `Incident.Id`. |
| Partition key | Container uses `/id` (matches document `id` field). |
| Throughput | Container created with **400 RU/s** manual throughput (minimum for many accounts; tune for production). |
| `UserProfileController` (MVC) | Not ported in this milestone — it was a stub view in the old API project; identity work belongs to the web app / later lab. |

### Build verification

- `dotnet build modern/dotnet/DevCamp.Modern.slnx` succeeds on the agent host.

### Data edge case (teaching point)

Legacy sample JSON used string values such as `"Resolved": "false"` in places. The new API stores **boolean** `Resolved` in Cosmos DB. SQL filters use `c.Resolved = false`, which matches boolean documents. If you import very old JSON verbatim as strings, queries may return unexpected sets—normalize types during seeding in a future iteration.

### Follow-ups (not done yet)

- Port **DevCamp.WebApp** (MVC) to ASP.NET Core and update `INCIDENT_API_URL`.
- Add automated tests (integration tests against Cosmos emulator or test container).
- GitHub Actions workflow for `modern/dotnet`.

---

## 2026-05-19 — Milestone 2: RBAC, IaC, GitHub Actions, playbooks

1. **`infra/`** — Bicep modules: Cosmos DB (`disableLocalAuth`), Linux App Service + system MI, Cosmos SQL **Built-in Data Contributor** role assignment.
2. **API** — Removed connection-string/key auth paths; `Azure.Identity` + `DefaultAzureCredential` via `CosmosClientFactory`.
3. **`.github/workflows/`** — `ci.yml`, `infrastructure.yml` (OIDC Bicep deploy), `deploy-api.yml` (zip deploy).
4. **`playbooks/prompts/`** — Seven proven prompts + RBAC/pre-merge checklists.
5. **Docs** — `docs/ARCHITECTURE.md`, `docs/deployment/github-oidc.md`, `docs/steps/02-rbac-and-iac.md`.

### Breaking change (intentional)

Local/dev must use **Entra ID** (`az login` + data-plane role) or run on App Service with managed identity. Account keys are not supported in `modern/` code.

---

## How to extend this journal

Add a new dated section per migration milestone. Each section should list: sources touched, new projects, breaking changes, verification commands, and open issues.
