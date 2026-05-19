# Prompt 07 — Verification and definition of done

---

Given this repo layout (`legacy/`, `modern/`, `infra/`, `.github/workflows/`), produce:

1. **Local commands** — restore, build, optional `az bicep build`, publish.
2. **Smoke tests** — 5–8 HTTP calls with expected status codes (include sample data endpoints).
3. **CI checks** — what GitHub Actions should gate on main.
4. **Post-deploy** — how to confirm managed identity can read/write Cosmos (no keys).

Format as a checklist instructors can paste into a lab README.

If tests are missing, generate a minimal `*.http` file or xUnit skeleton—ask before adding large test projects.
