# AI modernization playbooks

Proven, copy-paste prompts for brownfield upgrades. Use in order; **do not skip** human review steps in `checklists/`.

| Order | Prompt file | Purpose |
|-------|-------------|---------|
| 1 | [prompts/01-inventory.md](prompts/01-inventory.md) | Map frameworks, dependencies, secrets, APIs |
| 2 | [prompts/02-migration-plan.md](prompts/02-migration-plan.md) | Phased plan with rollback |
| 3 | [prompts/03-identity-rbac.md](prompts/03-identity-rbac.md) | Keys → managed identity + RBAC |
| 4 | [prompts/04-iac-bicep.md](prompts/04-iac-bicep.md) | Click-ops → Bicep modules |
| 5 | [prompts/05-port-controller.md](prompts/05-port-controller.md) | Port HTTP surface without breaking clients |
| 6 | [prompts/06-security-review.md](prompts/06-security-review.md) | Secrets, authz, logging |
| 7 | [prompts/07-verification.md](prompts/07-verification.md) | Build, smoke tests, IaC what-if |

Checklists: [checklists/rbac-no-keys.md](checklists/rbac-no-keys.md), [checklists/pre-merge.md](checklists/pre-merge.md).

Overview: [ai-assisted-upgrade.md](ai-assisted-upgrade.md).
