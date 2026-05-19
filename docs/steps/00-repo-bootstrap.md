# Step 0 — Bootstrap this repository from DevCamp

This step captures **exactly** how the `DevCamp-Modernization-Workshop` folder was produced so you can reproduce or teach the process.

## Goals

- Preserve the original workshop as a **read-only reference** (`legacy/`).
- Start a **new Git history** focused on modernization and AI-assisted upgrade narratives.
- Keep the working copy small enough for GitHub by **excluding** restored NuGet/npm artifacts from `legacy/`.

## Commands used (PowerShell)

```powershell
$src  = "f:\Git\DevCamp"
$dest = "f:\Git\DevCamp-Modernization-Workshop"

New-Item -ItemType Directory -Path $dest -Force
robocopy $src "$dest\legacy" /E /XD .git .vs /XF .gitattributes
```

## Post-copy cleanup

Removed bulky folders that can be regenerated:

```powershell
$root = "$dest\legacy"
$dirs = @('packages','bin','obj','node_modules')
foreach ($d in $dirs) {
  Get-ChildItem $root -Recurse -Directory -Filter $d -ErrorAction SilentlyContinue |
    ForEach-Object { Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue }
}
```

## Git

From `$dest`:

```powershell
git init
git add .
git commit -m "Describe your import commit"
```

## Files added in this workshop layer (not from robocopy)

- Root `README.md`, `NOTICE.md`, `LICENSE`, `.gitignore`
- `docs/**`, `playbooks/**`
- `modern/dotnet/**`

See [`MIGRATION-JOURNAL.md`](../MIGRATION-JOURNAL.md) for the running log.
