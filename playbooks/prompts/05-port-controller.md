# Prompt 05 — Port controllers without breaking clients

---

Port the legacy Web API controller(s) below to **ASP.NET Core 8** controllers.

Rules:

- Preserve route templates, HTTP verbs, and query parameter names (e.g. `PUT /incidents?IncidentId=`).
- Keep Newtonsoft.Json and `[JsonProperty("id")]` if needed for document compatibility.
- Replace `IHttpActionResult` with `ActionResult<T>` / `IActionResult`.
- Replace static data repositories with injected services.
- Do not add Swagger unless I ask.

Deliver unified diff-style summary per file and a short manual test list (curl or `.http`).

**Legacy controller:**

```csharp
(paste legacy controller source)
```
