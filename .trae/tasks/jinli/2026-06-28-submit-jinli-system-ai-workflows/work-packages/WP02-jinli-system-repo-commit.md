# WP02 Jinli System Repository Commit

Status: unclaimed

## Task Packet

`.trae/tasks/jinli/2026-06-28-submit-jinli-system-ai-workflows`

## Allowed Paths

- `Project/Jinli/**`

## Forbidden Paths

- Root repository index for `Project/**`
- `Project/Jinli/.env`
- `Project/Jinli/.env.*` except `.env.example`
- `Project/Jinli/node_modules/**`
- `Project/Jinli/data/**`
- `Project/Jinli/runtime/**`
- `Project/Jinli/output/**`
- `Project/Jinli/.pytest_cache/**`
- `Project/Jinli/jinli_evo_test_*/**`
- `Project/Jinli/jinli_mem_test_*/**`
- `Project/Jinli/p2_wechat_test_*/**`
- `Project/Jinli/pytest-of-*/**`
- `Project/Jinli/*_out.txt`
- `Project/Jinli/*_err.txt`

## Read First

- `Project/Jinli/.gitignore`
- `Project/Jinli/README.md`
- `.trae/tasks/jinli/2026-06-28-submit-jinli-system-ai-workflows/execution-prompt.md`

## Goal

Create one independent Jinli repository baseline commit from inside `Project/Jinli`, excluding secrets, runtime state, generated outputs, dependency folders, and temporary test artifacts.

## Steps

1. Enter Jinli project and check repository state.

```powershell
Set-Location E:\UEGameDevelopment\Project\Jinli
Test-Path .git
git status --short 2>$null
```

If `.git` exists and shows unexpected remote/history, stop and report.

2. Initialize repository when missing.

```powershell
if (-not (Test-Path .git)) { git init }
```

3. Harden `.gitignore`.

Ensure these lines exist in `Project/Jinli/.gitignore`:

```gitignore
node_modules/
data/
runtime/
output/
jinli_evo_test_*/
jinli_mem_test_*/
p2_wechat_test_*/
pytest-of-*/
*_out.txt
*_err.txt
temp_*.py
imp.py
audit*.py
completion_audit.py
```

Do not remove existing `.env` rules.

4. Stage source and documentation.

```powershell
git add -- .gitignore .env.example README.md SOUL.md package.json package-lock.json agents config contracts docs scripts services tests test_*.py
```

5. Audit staged paths.

```powershell
git diff --cached --name-only
git diff --cached --name-only | Select-String -Pattern '^\.env$|^data/|^runtime/|^output/|^node_modules/|jinli_evo_test_|jinli_mem_test_|p2_wechat_test_|pytest-of-|_out\.txt$|_err\.txt$'
```

Expected: second command has no output.

6. Secret scan staged Jinli files.

```powershell
$files = git diff --cached --name-only
$patterns = 'sk-[A-Za-z0-9_-]{20,}|OPENAI_API_KEY|ANTHROPIC_API_KEY|DEEPSEEK_API_KEY|password\s*=|token\s*=|secret\s*='
foreach ($f in $files) {
  if (Test-Path -LiteralPath $f -PathType Leaf) {
    Select-String -LiteralPath $f -Pattern $patterns -AllMatches
  }
}
```

Expected: no real credentials. `.env.example` may contain placeholder variable names.

7. Run lightweight checks.

```powershell
if (Test-Path package.json) { npm test }
python -m pytest tests -q
```

If dependencies are missing, record exact error. Do not install dependencies unless Ba Ba explicitly approves.

8. Commit Jinli baseline.

```powershell
git commit -m "chore(jinli): checkpoint system baseline"
```

## Done Definition

- `Project/Jinli/.git` exists.
- Jinli baseline commit exists.
- `.env`, runtime state, generated output, node modules, caches, and temp test folders are excluded.
- Secret scan and verification outcomes are recorded.

## Required Verification

```powershell
git log -1 --oneline
git status --short
```

## Return Report

- Path: `reports/submit-report.md`

