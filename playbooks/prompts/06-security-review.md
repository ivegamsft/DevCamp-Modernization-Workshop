# Prompt 06 — Security review

---

Review the proposed or completed modernization diff for:

1. Secrets in source control, logs, or AI chat exports
2. Over-privileged RBAC (Owner vs data-plane contributor)
3. Cosmos `disableLocalAuth` alignment with app auth mode
4. HTTPS-only and TLS for App Service
5. PII in Application Insights or logs
6. Supply chain (NuGet package versions, pinned actions SHAs in workflows)

Output a table: **Finding | Severity | File/line | Remediation**.  
Block merge on any **High** without a documented exception.
