# Step 1 — Migrate the Incident API (DocumentDB → Cosmos DB, Web API → ASP.NET Core)

This step documents the first **vertical slice**: the **City Power & Light** incident REST API from `legacy/Shared/API/DevCamp.API` to `modern/dotnet/DevCamp.Api`.

## Learning objectives

- Map **.NET Framework** + `System.Web.Http` patterns to **ASP.NET Core** hosting and `Microsoft.AspNetCore.Mvc`.
- Replace deprecated **DocumentDB** (`Microsoft.Azure.Documents.Client`) with **Azure Cosmos DB** SDK v3 (`Microsoft.Azure.Cosmos`).
- Move secrets from `Web.config` to **configuration + user-secrets** (12-factor style).
- Preserve **HTTP contracts** so existing workshop clients (e.g. `IncidentAPIClient`) still work.

## Inventory (what the legacy API did)

| Area | Legacy implementation |
|------|-------------------------|
| Hosting | IIS + `Global.asax` → `Application_Start` |
| DI | None (static `DocumentDBRepository<T>`) |
| Data | `DocumentDBRepository<Incident>` using `DocumentClient` |
| Routes | Attribute routes on `IncidentController` (`incidents`, `incidents/{id}`, …) |
| JSON | Web API + Newtonsoft.Json |

## Implementation outline (modern)

1. `dotnet new webapi -f net8.0 -o DevCamp.Api --no-openapi`
2. Packages: `Microsoft.Azure.Cosmos`, `Microsoft.AspNetCore.Mvc.NewtonsoftJson` (8.x line for net8).
3. Add `CosmosIncidentRepository` (replaces static `DocumentDBRepository<Incident>`).
4. Add `IncidentController` with the same route strings and HTTP verbs.
5. Call `InitializeAsync()` on the repository at startup (fail fast if Cosmos is not configured).
6. Copy `SampleIncidents.json` / `FakeIncidents.json` to `Data/` and set **Copy to Output Directory**.

## Configuration mapping

| Legacy `Web.config` | Modern location |
|---------------------|-----------------|
| `DOCUMENTDB_ENDPOINT` | `CosmosDb:Endpoint` or user-secret |
| `DOCUMENTDB_PRIMARY_KEY` | `CosmosDb:Key` or user-secret |
| `DOCUMENTDB_DATABASEID` | `CosmosDb:DatabaseId` |
| `DOCUMENTDB_COLLECTIONID` | `CosmosDb:ContainerId` |
| *(none)* | `CosmosDb:ConnectionString` (`AccountEndpoint=...;AccountKey=...;`) supported as a single secret |

## Verify locally

```powershell
cd modern\dotnet\DevCamp.Api
dotnet user-secrets init
dotnet user-secrets set "CosmosDb:ConnectionString" "AccountEndpoint=...;AccountKey=...;"
dotnet run
```

Then (example):

- `GET https://localhost:7xxx/incidents/sampledata`
- `GET https://localhost:7xxx/incidents`

## Teaching notes (AI-assisted upgrade)

Ask learners to use an AI assistant to:

1. Generate an **inventory table** (packages, TFMs, entry points, external services).
2. Propose a **side-by-side** migration plan (hosting → data → routes → config).
3. Produce a **diff** for the repository layer only; instructor reviews partition key and secrets handling.

Then require a **human checklist**: no secrets in source control, confirm `PUT` still uses query string `IncidentId`, run the two GETs above.

## Known gaps

- Emulator-based automated tests not yet added.
- OpenAPI/Swagger not yet enabled (optional improvement for workshops).
