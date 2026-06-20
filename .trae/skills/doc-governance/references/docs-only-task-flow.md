# Docs-Only Task Implementation Flow

When a task packet only produces documentation (no code changes), follow this flow:

## Gate Sequence (git-bash / MSYS environment)

```bash
# 1. Set user_confirmed_plan
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\\.trae\\scripts\\task-state.ps1" set <scope>/<task-name> user_confirmed_plan true

# 2. Transition plan → implement
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\\.trae\\scripts\\task-guard.ps1" <scope>/<task-name> plan -Apply

# 3. Verify edit authorization
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\\.trae\\scripts\\task-state.ps1" can-edit <scope>/<task-name>
```

All three must pass before editing any file.

## Implementation Steps

1. **Create the design document** at the path specified in `doc-impact.md` → `Documentation Updates`
2. **Update DOCS_TREE.md**: add entry to `Classified Docs` table + add row to `Recent Updates` + update `Last updated` date
3. **Update tasks.md**: mark completed tasks as `[x]`, deferred tasks as `[~]` with reason
4. **Write verification-report.md** in the task packet root

## Verification Commands

```bash
# Doc governance check
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\\.trae\\scripts\\doc-guard.ps1" check-task <scope>/<task-name> -Stage implement

# Phase transition check (implement → review)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\\.trae\\scripts\\task-guard.ps1" <scope>/<task-name> implement
```

## Common Pitfalls

- **Unfinished tasks block phase transition**: `task-guard.ps1 implement` will FAIL if tasks.md has unchecked `[ ]` items. Mark deferred items as `[~]` with a reason.
- **DOCS_TREE must match reality**: If a file is created but not listed in DOCS_TREE, doc-guard won't catch it, but the tree becomes stale. Always update both the file and the tree.
- **doc-impact.md must exist before doc-guard**: It's checked first. If missing, the entire doc governance check fails.
