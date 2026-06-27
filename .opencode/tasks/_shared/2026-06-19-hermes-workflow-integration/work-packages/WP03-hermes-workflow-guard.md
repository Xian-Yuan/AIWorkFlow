# WP03: Hermes Workflow Guard Plugin

Owner model: unclaimed  
Difficulty: hard  
Status: unclaimed

## Task Packet

- Root: `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/`
- Parent task: `2026-06-19-hermes-workflow-integration`

## Allowed Paths

- `.trae/hermes/plugins/jinli-workflow-guard/**`
- `.trae/hermes/tests/test_workflow_guard.py`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/claims/hermes-guard-WP03.md`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/reports/hermes-guard-WP03-result.md`

## Forbidden Paths

- `Project/**`
- `.tools/hermes-worker/**`
- `.trae/hermes/profiles/**`
- `.trae/hermes/policies/**`
- `.trae/hermes/mcp/**`
- `.trae/hermes/tests/test_workflow_mcp.py`
- `.trae/scripts/**`
- `skills/**`
- `Docs/**`
- other task packets
- Git metadata, branches, commits, remotes, pushes, resets, rebases, and credentials

## Read First

- `AGENTS.md`
- `Docs/AI/27-AI-Workflow-Refactor-Manifest.md`
- `Docs/AI/29-Mature-Solution-First-Workflow.md`
- `Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md`
- `Docs/superpowers/specs/2026-06-19-hermes-workflow-integration-design.md`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/routing.md`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/analysis.md`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/spec.md`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/tasks.md`
- `.tools/hermes-worker/hermes-agent/website/docs/user-guide/features/plugins.md`
- `.tools/hermes-worker/hermes-agent/website/docs/user-guide/features/hooks.md`

## Goal

- Implement a Hermes plugin that injects role/task context, blocks unauthorized mutation with canonical `pre_tool_call` responses, audits tool results without secrets, and validates delegated child results.

## Steps

- [ ] Run the Plan gate and Can-Edit check before editing.
- [ ] Create `claims/hermes-guard-WP03.md`.
- [ ] Write `test_workflow_guard.py` first for missing role, Planner code mutation, Implementer missing task/WP, failed gates, path precedence, Verifier write scope, subagent result, and read-only fallback.
- [ ] Run the tests and confirm they fail because the plugin is absent.
- [ ] Create `plugin.yaml`, `__init__.py`, `guard.py`, and `audit.py`.
- [ ] Register `on_session_start`, `pre_llm_call`, `pre_tool_call`, `post_tool_call`, and `subagent_stop`.
- [ ] Parse only explicit launch environment and task packet evidence; do not infer authorization from conversation text.
- [ ] Return `{"action":"block","message":"..."}` for invalid mutation.
- [ ] Make Forbidden Paths override Allowed Paths after absolute path resolution.
- [ ] Treat missing/malformed role, task, WP, policy, or gate evidence as blocked for mutation.
- [ ] Keep read-only tools available for diagnosis.
- [ ] Redact credentials, tokens, authorization headers, and secret-shaped values from audit records.
- [ ] Require delegated Implementer children to return the bounded report contract.
- [ ] Re-run focused tests and record exact results.
- [ ] Write `reports/hermes-guard-WP03-result.md` and stop.

## Done Definition

- Plugin discovery metadata is valid.
- All required hooks are registered.
- Mutating tool decisions are deterministic and fail closed.
- Planner, Implementer, and Verifier scopes follow the design.
- Path resolution handles Windows separators and traversal.
- Audit output contains no secret values.
- Focused tests pass and the report maps AC07.

## Required Verification

- Command: `& ".\.tools\hermes-worker\hermes-agent\venv\Scripts\python.exe" -m pytest .\.trae\hermes\tests\test_workflow_guard.py -q`
- Expected: all workflow guard tests pass with zero failures.

## Return Report

- Path: `reports/hermes-guard-WP03-result.md`
- Required status for merge: `done`
- Must include changed files, commands run, results, acceptance criteria touched, scope control, and unresolved risks.
- Must declare `Extra scope taken: no`.

## Failure Reporting

- If blocked, write the same report path with `Status: blocked`.
- Include the failing test/command, current diagnosis, and smallest lead decision needed.
- Do not weaken fail-closed behavior to make a test pass.

## Publisher Checklist

- [x] No template placeholder text remains.
- [x] Allowed and Forbidden Paths are concrete.
- [x] Verification command and expected outcome are concrete.
- [x] Return report path is concrete.

