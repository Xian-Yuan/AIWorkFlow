# WP04: Hermes Launcher, Integration Regression, and Documentation

Owner model: unclaimed  
Difficulty: hard  
Status: unclaimed

## Task Packet

- Root: `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/`
- Parent task: `2026-06-19-hermes-workflow-integration`
- Dependency: WP01, WP02, and WP03 reports must be `Status: done` before this work package is claimed.

## Allowed Paths

- `.trae/scripts/invoke-hermes-agent.ps1`
- `.trae/scripts/test-hermes-workflow-integration.ps1`
- `.trae/hermes/README.md`
- `Docs/AI/39-Hermes-Workflow-Integration.md`
- `Docs/AI/README.md`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/claims/hermes-launcher-WP04.md`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/reports/hermes-launcher-WP04-result.md`

## Forbidden Paths

- `Project/**`
- `.tools/hermes-worker/**`; synchronization and runtime verification are lead-owned after WP04
- `.trae/hermes/profiles/**`
- `.trae/hermes/policies/**`
- `.trae/hermes/mcp/**`
- `.trae/hermes/plugins/**`
- `.trae/hermes/tests/**`
- `.trae/scripts/task-state.ps1`
- `.trae/scripts/task-guard.ps1`
- `.trae/scripts/doc-guard.ps1`
- `.trae/scripts/sync-hermes-workflow.ps1`
- `.trae/scripts/test-hermes-skill-compatibility.ps1`
- `skills/**`
- other task packets
- Git metadata, branches, commits, remotes, pushes, resets, rebases, and credentials

## Read First

- `AGENTS.md`
- `Docs/AI/27-AI-Workflow-Refactor-Manifest.md`
- `Docs/AI/29-Mature-Solution-First-Workflow.md`
- `Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md`
- `Docs/superpowers/specs/2026-06-19-hermes-workflow-integration-design.md`
- `Docs/superpowers/plans/2026-06-19-hermes-workflow-integration-plan.md`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/routing.md`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/analysis.md`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/spec.md`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/tasks.md`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/reports/hermes-profile-WP01-result.md`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/reports/hermes-mcp-WP02-result.md`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/reports/hermes-guard-WP03-result.md`

## Goal

- Provide one safe, role-aware Hermes launcher, deterministic end-to-end regression coverage, and durable operating documentation that ties Profiles, Skills, MCP, plugin policy, task packets, and verification together.

## Steps

- [ ] Confirm all three dependency reports exist, declare `Status: done`, and declare `Extra scope taken: no`.
- [ ] Run the Plan gate and Can-Edit check before editing.
- [ ] Create `claims/hermes-launcher-WP04.md`.
- [ ] Write `test-hermes-workflow-integration.ps1` first for invalid role/task/WP, failed Plan/Can-Edit, dry-run resolution, profile drift, and runtime placement.
- [ ] Run the tests and confirm they fail because the launcher is absent.
- [ ] Implement `invoke-hermes-agent.ps1` with Planner, Implementer, Verifier, task, WP, dry-run, and no-sync parameters.
- [ ] Require WP only for Implementer and require task identity for Implementer/Verifier.
- [ ] Call synchronization Check/Apply through the repository-owned script.
- [ ] Resolve the managed Hermes executable and start from `E:\UEGameDevelopment`.
- [ ] Set `JINLI_ROLE`, `JINLI_TASK_NAME`, `JINLI_WORK_PACKAGE`, and `UEGAMEDEV_ROOT`.
- [ ] Print a secret-free dry-run containing profile, task, WP, MCP, plugin, claim, and report paths.
- [ ] Add `.trae/hermes/README.md` for repository maintainers.
- [ ] Add `Docs/AI/39-Hermes-Workflow-Integration.md` for users and agents.
- [ ] Update `Docs/AI/README.md` index without altering unrelated entries.
- [ ] Re-run deterministic integration tests and record exact results.
- [ ] Write `reports/hermes-launcher-WP04-result.md` and stop.

## Done Definition

- Launcher rejects unauthorized context before starting Hermes.
- Valid dry-run resolves one role/profile/task/WP/claim/report contract.
- Launcher uses the managed workspace-local runtime and repository cwd.
- Integration tests require no live model call.
- Durable documentation covers setup, use, security, troubleshooting, and verification.
- Report maps AC08, AC09, AC10, AC11, and AC13.

## Required Verification

- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-hermes-workflow-integration.ps1`
- Expected: all deterministic integration cases pass.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\doc-guard.ps1 check-task "_shared/2026-06-19-hermes-workflow-integration" -Stage implement`
- Expected: documentation governance passes for global workflow changes.

## Return Report

- Path: `reports/hermes-launcher-WP04-result.md`
- Required status for merge: `done`
- Must include changed files, commands run, results, acceptance criteria touched, scope control, and unresolved risks.
- Must declare `Extra scope taken: no`.
- Must not include credentials or authorization headers.

## Failure Reporting

- If blocked, write the same report path with `Status: blocked`.
- Include dependency status, failing command, current diagnosis, and smallest lead decision needed.
- Do not bypass dependency reports or gate checks.

## Publisher Checklist

- [x] No template placeholder text remains.
- [x] Allowed and Forbidden Paths are concrete.
- [x] Verification commands and expected outcomes are concrete.
- [x] Return report path is concrete.

