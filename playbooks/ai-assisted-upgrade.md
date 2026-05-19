# AI-assisted upgrade playbooks

Use these patterns when you (or learners) drive an AI coding agent to modernize applications. They are **guardrails**, not magic.

**Preferred:** the numbered prompts in [`prompts/`](prompts/) and checklists in [`checklists/`](checklists/). The sections below are a short summary; copy full text from the prompt files for consistency.

## 1. Repository inventory prompt (paste first)

> You are assisting with a brownfield upgrade. Scan this repository and produce: (1) solution/project files and target frameworks, (2) every external service (databases, queues, identity), (3) every NuGet/npm package older than 24 months, (4) every place secrets or connection strings are read, (5) HTTP routes or public API contracts. Output as Markdown tables. Do not change files yet.

**Human follow-up:** Delete or redact any accidental secret before sharing logs.

## 2. Migration plan prompt

> Given the inventory, propose a phased migration to .NET 8 / ASP.NET Core and Azure Cosmos DB v3 SDK. Each phase must be independently buildable. List risks and rollback steps. Do not write code until I approve the phases.

## 3. Contract preservation prompt

> When porting controllers, preserve URL paths, HTTP methods, query parameter names, and JSON property names unless I explicitly approve a breaking change. List any intentional breaks at the end.

## 4. Security review prompt

> Review the proposed changes for secret handling, TLS, authentication, and logging of PII. Flag issues with severity (High/Med/Low).

## 5. Definition of done (workshop rubric)

- Builds on a clean machine with documented prerequisites only.
- No secrets committed; user-secrets or environment variables documented.
- Smoke test script or README steps verify critical flows.
- `docs/MIGRATION-JOURNAL.md` updated with decisions and follow-ups.
