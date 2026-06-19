# WP01: Deploy Hermes Local Worker

Owner model: unclaimed
Difficulty: hard
Status: unclaimed

## Task Packet

- Root: `.trae/tasks/_shared/2026-06-18-hermes-local-worker-deployment/`
- Parent task: `2026-06-18-hermes-local-worker-deployment`

## Allowed Paths

- `.tools/hermes-worker/**`
- `.tmp/hermes-install/**`
- `.trae/scripts/invoke-hermes-worker.ps1`
- `.trae/scripts/test-invoke-hermes-worker.ps1`
- `.trae/tasks/_shared/2026-06-18-hermes-local-worker-deployment/claims/hermes-WP01.md`
- `.trae/tasks/_shared/2026-06-18-hermes-local-worker-deployment/reports/hermes-WP01-result.md`

## Forbidden Paths

- `Project/**`
- `Docs/Memory/**`
- `skills/**`
- `.agents/**`
- `.trae/scripts/task-state.ps1`
- `.trae/scripts/task-guard.ps1`
- `.trae/scripts/doc-guard.ps1`
- `.trae/tasks/**` except the two exact claim and report files listed under Allowed Paths
- `.git/**`
- Any Git remote, branch, commit, push, reset, revert, or credential mutation
- `%LOCALAPPDATA%\hermes/**`

## Read First

- `AGENTS.md`
- `Docs/AI/27-AI-Workflow-Refactor-Manifest.md`
- `Docs/AI/29-Mature-Solution-First-Workflow.md`
- `Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md`
- `.trae/tasks/_shared/2026-06-18-hermes-local-worker-deployment/routing.md`
- `.trae/tasks/_shared/2026-06-18-hermes-local-worker-deployment/analysis.md`
- `.trae/tasks/_shared/2026-06-18-hermes-local-worker-deployment/spec.md`
- `.trae/tasks/_shared/2026-06-18-hermes-local-worker-deployment/tasks.md`
- `.trae/tasks/_shared/2026-06-18-hermes-local-worker-deployment/doc-impact.md`

## Goal

- Install Hermes Agent as a workspace-local, bounded Worker runtime and add a tested adapter that enforces the existing task-packet gates before Hermes can execute a work package.

## Steps

- [ ] Run the Plan gate with `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\task-guard.ps1 _shared/2026-06-18-hermes-local-worker-deployment plan`.
- [ ] Ask the lead model to transition the task to Implement if it is still in Plan; do not edit until that transition is complete.
- [ ] Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\task-state.ps1 can-edit _shared/2026-06-18-hermes-local-worker-deployment`.
- [ ] Create `claims/hermes-WP01.md` before any allowed-path edit.
- [ ] Detect and record pre-existing `%LOCALAPPDATA%\hermes` without modifying it.
- [ ] Resolve an official stable Hermes release tag or immutable commit and record it in the result report.
- [ ] Download the official `scripts/install.ps1` to `.tmp/hermes-install/install.ps1`.
- [ ] Record the installer SHA256 in the result report.
- [ ] Run the installer with `-HermesHome "E:\UEGameDevelopment\.tools\hermes-worker"` and `-InstallDir "E:\UEGameDevelopment\.tools\hermes-worker\hermes-agent"`.
- [ ] Configure Hermes for repository-root cwd, manual approvals, secret redaction, and flat delegation; do not enable gateway or cron.
- [ ] Write adapter regression tests before implementing the adapter.
- [ ] Implement the adapter with exact task/WP resolution, Plan and Can-Edit checks, claim/report requirements, and dry-run support.
- [ ] Run adapter tests, `hermes --version`, and `hermes doctor`.
- [ ] Run a read-only repository-context smoke test if model credentials are available; otherwise report that check as not run.
- [ ] Write the required result report and stop. Do not perform Review, Verify, archive, Git commit, or Git push.

## Done Definition

- Hermes runtime is contained under `.tools/hermes-worker`.
- No task-created files exist under `%LOCALAPPDATA%\hermes`.
- Adapter tests pass.
- Hermes version and doctor checks complete without blocking errors.
- The adapter rejects failed gates and invalid work-package resolution.
- `reports/hermes-WP01-result.md` is complete and states `Status: done` and `Extra scope taken: no`.

## Required Verification

- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-invoke-hermes-worker.ps1`
- Expected: all adapter test cases pass.
- Command: `& "E:\UEGameDevelopment\.tools\hermes-worker\hermes-agent\venv\Scripts\hermes.exe" --version`
- Expected: exit code 0 and a Hermes Agent version string.
- Command: `& "E:\UEGameDevelopment\.tools\hermes-worker\hermes-agent\venv\Scripts\hermes.exe" doctor`
- Expected: no blocking installation error.
- Command: `Test-Path "E:\UEGameDevelopment\.tools\hermes-worker\hermes-agent"`
- Expected: `True`.

## Return Report

- Path: `reports/hermes-WP01-result.md`
- Required status for merge: `done`
- Must include changed files, commands run, results, acceptance criteria touched, scope control, and unresolved risks.
- Must declare `Extra scope taken: no`.

## Failure Reporting

- If blocked, write `reports/hermes-WP01-result.md` with `Status: blocked`.
- Include the blocker, commands already run, and the smallest question needed from the lead agent.
- Do not edit outside Allowed Paths while blocked.

## Publisher Checklist

- [x] No template placeholder text remains in this work package.
- [x] Allowed Paths and Forbidden Paths are concrete.
- [x] Required Verification has real commands and expected results.
- [x] Return Report path is concrete.
