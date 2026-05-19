# Checklist — Pre-merge (human gate)

- [ ] `dotnet build` passes on `modern/dotnet/DevCamp.Modern.slnx`
- [ ] `az bicep build --file infra/main.bicep` passes
- [ ] `docs/MIGRATION-JOURNAL.md` updated with decisions
- [ ] No secrets in diff (`git diff` / PR files)
- [ ] AI prompt output reviewed against [rbac-no-keys.md](rbac-no-keys.md)
- [ ] HTTP contract changes called out in PR description
- [ ] Workshop step doc added or updated under `docs/steps/`
