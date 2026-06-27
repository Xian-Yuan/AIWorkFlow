# WP01 Root AI Workflow Commit

Status: unclaimed

## Task Packet

`.trae/tasks/jinli/2026-06-28-submit-jinli-system-ai-workflows`

## Allowed Paths

- `AGENTS.md`
- `Docs/AI/**`
- `Docs/Memory/**`
- `Docs/superpowers/**`
- `skills/**`
- `.trae/**`
- `.opencode/**`
- `.vscode/**`

## Forbidden Paths

- `Project/**`
- Any `.env` file
- `node_modules/**`
- `**/__pycache__/**`
- `**/.pytest_cache/**`
- Generated media or runtime outputs

## Read First

- `.gitignore`
- `.trae/tasks/jinli/2026-06-28-submit-jinli-system-ai-workflows/execution-prompt.md`
- `.trae/tasks/jinli/2026-06-28-submit-jinli-system-ai-workflows/analysis.md`

## Goal

Create one root repository commit for current shared AI workflow state without staging `Project/`.

## Steps

1. Confirm no files are already staged.

```powershell
git diff --cached --name-only
```

Expected: no output. If there is output, stop and report.

2. Inspect workflow status.

```powershell
git status --short -- AGENTS.md Docs/AI Docs/Memory Docs/superpowers skills .trae .opencode .vscode
```

3. Stage workflow paths only.

```powershell
git add -- AGENTS.md Docs/AI Docs/Memory Docs/superpowers skills .trae .opencode .vscode
git reset -- .trae/**/__pycache__ .opencode/**/__pycache__ skills/**/__pycache__ 2>$null
```

4. Prove root staging does not include `Project/`.

```powershell
git diff --cached --name-only -- Project
```

Expected: no output.

5. Secret scan staged root files.

```powershell
$files = git diff --cached --name-only
$patterns = 'sk-[A-Za-z0-9_-]{20,}|OPENAI_API_KEY|ANTHROPIC_API_KEY|DEEPSEEK_API_KEY|password\s*=|token\s*=|secret\s*='
foreach ($f in $files) {
  if (Test-Path -LiteralPath $f -PathType Leaf) {
    Select-String -LiteralPath $f -Pattern $patterns -AllMatches
  }
}
```

Expected: no real credentials.

6. Commit.

```powershell
git commit -m "chore(ai-workflow): checkpoint shared workflow system"
```

## Done Definition

- Root commit exists.
- `Project/` was not staged.
- Secret scan result is recorded in final report.
- Commit hash is recorded in final report.

## Required Verification

```powershell
git log -1 --oneline
git status --short
```

## Return Report

- Path: `reports/submit-report.md`

