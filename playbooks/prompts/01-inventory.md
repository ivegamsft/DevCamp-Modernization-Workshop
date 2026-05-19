# Prompt 01 — Repository inventory

Paste into your AI assistant with the repo root attached (or `@` folder).

---

You are assisting with a **brownfield Azure/.NET modernization**. Do not change files yet.

Scan this repository and produce Markdown tables for:

1. **Solutions and projects** — path, TFM, project type (Web API, MVC, console).
2. **External dependencies** — Cosmos/DocumentDB, Storage, Redis, Service Bus, Graph, App Insights; include package names and approximate age if visible.
3. **Secrets and configuration** — every place connection strings, API keys, or `Web.config` / `appsettings` secrets appear (file path + key name only; redact values).
4. **Public HTTP contracts** — method, route template, query parameters, and JSON property names that clients likely depend on.
5. **Hosting model** — IIS, App Service, containers, Functions.

End with a **risk-ranked** list (High/Med/Low) of upgrade blockers.

**Output format:** Markdown only. No code changes.
