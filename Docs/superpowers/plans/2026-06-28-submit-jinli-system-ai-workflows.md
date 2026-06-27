# Submit Jinli System And AI Workflows Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prepare and create safe commits for the shared AI workflow root repository and the independent `Project/Jinli` system repository.

**Architecture:** Use two commit streams. The root repository owns shared AI workflow, documentation, skills, task packets, and IDE adapters. `Project/Jinli` owns the Jinli system and must not be force-added into the root repository because root `.gitignore` explicitly reserves `Project/` for independent repositories.

**Tech Stack:** Git, PowerShell, repository task packets, Markdown workflow docs, Jinli Python/Node project files.

---

## File Structure

- Task packet: `.trae/tasks/jinli/2026-06-28-submit-jinli-system-ai-workflows/`
- Root workflow commit target: `AGENTS.md`, `Docs/AI/`, `Docs/Memory/`, `Docs/superpowers/`, `skills/`, `.trae/`, `.opencode/`
- Jinli system commit target: `Project/Jinli/`
- Worker reports: `.trae/tasks/jinli/2026-06-28-submit-jinli-system-ai-workflows/reports/`

## Task 1: Root AI Workflow Commit

**Files:**
- Read: `.gitignore`
- Read: `.trae/tasks/jinli/2026-06-28-submit-jinli-system-ai-workflows/work-packages/WP01-root-ai-workflow-commit.md`
- Modify via Git only: root repository index and one root commit

- [ ] **Step 1: Confirm no files are already staged**

Run:

```powershell
git diff --cached --name-only
```

Expected: no output. If output exists, stop and report the existing staged paths before changing the index.

- [ ] **Step 2: Review root workflow status**

Run:

```powershell
git status --short -- AGENTS.md Docs/AI Docs/Memory Docs/superpowers skills .trae .opencode .vscode
```

Expected: only shared workflow, documentation, skills, task packets, and IDE adapter files are listed.

- [ ] **Step 3: Stage only root AI workflow paths**

Run:

```powershell
git add -- AGENTS.md Docs/AI Docs/Memory Docs/superpowers skills .trae .opencode .vscode
git reset -- .trae/**/__pycache__ .opencode/**/__pycache__ skills/**/__pycache__ 2>$null
```

Expected: `Project/` is not staged.

- [ ] **Step 4: Audit staged root paths**

Run:

```powershell
git diff --cached --name-only
git diff --cached --name-only -- Project
```

Expected: first command lists intended workflow files; second command has no output.

- [ ] **Step 5: Secret scan staged root files**

Run:

```powershell
$files = git diff --cached --name-only
$patterns = 'sk-[A-Za-z0-9_-]{20,}|OPENAI_API_KEY|ANTHROPIC_API_KEY|DEEPSEEK_API_KEY|password\s*=|token\s*=|secret\s*='
foreach ($f in $files) {
  if (Test-Path -LiteralPath $f -PathType Leaf) {
    Select-String -LiteralPath $f -Pattern $patterns -AllMatches
  }
}
```

Expected: no real credentials. If a match is only documentation text, include it in the report and continue. If a real secret appears, unstage the file and stop.

- [ ] **Step 6: Commit root workflow**

Run:

```powershell
git commit -m "chore(ai-workflow): checkpoint shared workflow system"
```

Expected: one root repository commit on the current branch.

## Task 2: Jinli System Repository Commit

**Files:**
- Read: `Project/Jinli/.gitignore`
- Read: `.trae/tasks/jinli/2026-06-28-submit-jinli-system-ai-workflows/work-packages/WP02-jinli-system-repo-commit.md`
- Modify: `Project/Jinli/.gitignore` if needed
- Modify via Git only: `Project/Jinli/.git/` and one Jinli repository commit

- [ ] **Step 1: Enter Jinli project**

Run:

```powershell
Set-Location E:\UEGameDevelopment\Project\Jinli
Test-Path .git
```

Expected: currently `False`. If it is `True`, use the existing repository instead of reinitializing.

- [ ] **Step 2: Initialize independent repository if missing**

Run only when `.git` is missing:

```powershell
git init
```

Expected: `Project/Jinli/.git` exists.

- [ ] **Step 3: Harden Jinli `.gitignore` before staging**

Ensure `Project/Jinli/.gitignore` contains these entries:

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

Use `apply_patch` or a normal editor. Do not remove the existing `.env` rules.

- [ ] **Step 4: Stage system source and docs**

Run:

```powershell
git add -- .gitignore .env.example README.md SOUL.md package.json package-lock.json agents config contracts docs scripts services tests test_*.py
```

Expected: source, docs, config templates, scripts, services, and tests are staged; `.env`, runtime data, generated outputs, node modules, temp test folders, and captured output logs are not staged.

- [ ] **Step 5: Audit staged Jinli paths**

Run:

```powershell
git status --short
git diff --cached --name-only
git diff --cached --name-only | Select-String -Pattern '^\.env$|^data/|^runtime/|^output/|^node_modules/|jinli_evo_test_|jinli_mem_test_|p2_wechat_test_|pytest-of-|_out\.txt$|_err\.txt$'
```

Expected: the final command has no output.

- [ ] **Step 6: Secret scan staged Jinli files**

Run:

```powershell
$files = git diff --cached --name-only
$patterns = 'sk-[A-Za-z0-9_-]{20,}|OPENAI_API_KEY|ANTHROPIC_API_KEY|DEEPSEEK_API_KEY|password\s*=|token\s*=|secret\s*='
foreach ($f in $files) {
  if (Test-Path -LiteralPath $f -PathType Leaf) {
    Select-String -LiteralPath $f -Pattern $patterns -AllMatches
  }
}
```

Expected: no real credentials. `.env.example` may contain placeholder variable names, but not real values.

- [ ] **Step 7: Run lightweight verification**

Run:

```powershell
if (Test-Path package.json) { npm test }
python -m pytest tests -q
```

Expected: tests pass. If dependencies are missing, record the exact error and continue only if Ba Ba accepts a documentation-only baseline commit.

- [ ] **Step 8: Commit Jinli baseline**

Run:

```powershell
git commit -m "chore(jinli): checkpoint system baseline"
```

Expected: one commit in the independent `Project/Jinli` repository.

## Task 3: Final Report

**Files:**
- Create: `.trae/tasks/jinli/2026-06-28-submit-jinli-system-ai-workflows/reports/submit-report.md`

- [ ] **Step 1: Record root commit evidence**

Run:

```powershell
Set-Location E:\UEGameDevelopment
git log -1 --oneline
git status --short
```

- [ ] **Step 2: Record Jinli commit evidence**

Run:

```powershell
Set-Location E:\UEGameDevelopment\Project\Jinli
git log -1 --oneline
git status --short
```

- [ ] **Step 3: Write report**

Create `.trae/tasks/jinli/2026-06-28-submit-jinli-system-ai-workflows/reports/submit-report.md` with:

```markdown
# Submit Report

Status: done or blocked

## Root Workflow Commit
- Commit:
- Branch:
- Files staged summary:
- Secret scan result:
- Verification:

## Jinli System Commit
- Commit:
- Branch:
- Files staged summary:
- Excluded runtime/temp paths:
- Secret scan result:
- Verification:

## Deviations
- None, or exact reason.

## Follow-Up
- None, or exact next action.
```

Expected: report contains current commit hashes and any residual risks.

