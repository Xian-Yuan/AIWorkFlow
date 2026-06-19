# WP02: Hermes Workflow MCP Server

Owner model: unclaimed  
Difficulty: hard  
Status: unclaimed

## Task Packet

- Root: `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/`
- Parent task: `2026-06-19-hermes-workflow-integration`

## Allowed Paths

- `.trae/hermes/mcp/jinli_workflow/**`
- `.trae/hermes/tests/test_workflow_mcp.py`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/claims/hermes-mcp-WP02.md`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/reports/hermes-mcp-WP02-result.md`

## Forbidden Paths

- `Project/**`
- `.tools/hermes-worker/**`
- `.trae/hermes/profiles/**`
- `.trae/hermes/policies/**`
- `.trae/hermes/plugins/**`
- `.trae/hermes/tests/test_workflow_guard.py`
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
- `.trae/scripts/task-state.ps1`
- `.trae/scripts/task-guard.ps1`
- `.trae/scripts/agent-claim-template.md`
- `.trae/scripts/agent-result-template.md`
- `.tools/hermes-worker/hermes-agent/website/docs/reference/mcp-config-reference.md`

## Goal

- Implement a typed, path-safe MCP server that exposes a narrow role-specific interface to the existing task-packet scripts without creating a second task state or giving Workers architecture/final verification authority.

## Steps

- [ ] Run the Plan gate and Can-Edit check before editing.
- [ ] Create `claims/hermes-mcp-WP02.md`.
- [ ] Write `test_workflow_mcp.py` first with path traversal, task discovery, gate delegation, claim collision, report schema, role allowlist, and Worker authority tests.
- [ ] Run the tests and confirm they fail because the MCP package is absent.
- [ ] Create `server.py`, `service.py`, `policy.py`, `paths.py`, `schemas.py`, `__init__.py`, and `__main__.py`.
- [ ] Implement the exact tools defined in the design document.
- [ ] Validate task names, task roots, document names, WP IDs, claim paths, and report paths through resolved root containment.
- [ ] Invoke PowerShell scripts through argument arrays with repository cwd, timeout, captured output, and exit code.
- [ ] Return structured JSON and redact secret-shaped values from diagnostics.
- [ ] Make claims collision-safe and refuse overwrite.
- [ ] Validate report sections and required `Status: done` / `Extra scope taken: no` markers.
- [ ] Ensure Implementer tools cannot alter routing, architecture, acceptance criteria, task phase, or verification state.
- [ ] Re-run the focused test file and record exact results.
- [ ] Write `reports/hermes-mcp-WP02-result.md` and stop.

## Done Definition

- MCP starts through `python -m jinli_workflow`.
- Every documented workflow tool has schema validation and role authorization.
- All paths remain under the workspace/task roots.
- Authoritative scripts decide Plan and Can-Edit.
- Claims and reports follow the shared task-packet contract.
- Worker authority is narrower than Planner/Verifier authority.
- Focused tests pass and the report maps AC05 and AC06.

## Required Verification

- Command: `& ".\.tools\hermes-worker\hermes-agent\venv\Scripts\python.exe" -m pytest .\.trae\hermes\tests\test_workflow_mcp.py -q`
- Expected: all workflow MCP tests pass with zero failures.

## Return Report

- Path: `reports/hermes-mcp-WP02-result.md`
- Required status for merge: `done`
- Must include changed files, commands run, results, acceptance criteria touched, scope control, and unresolved risks.
- Must declare `Extra scope taken: no`.

## Failure Reporting

- If blocked, write the same report path with `Status: blocked`.
- Include the failing test/command, current diagnosis, and smallest lead decision needed.
- Do not modify authoritative workflow scripts to make tests pass.

## Publisher Checklist

- [x] No template placeholder text remains.
- [x] Allowed and Forbidden Paths are concrete.
- [x] Verification command and expected outcome are concrete.
- [x] Return report path is concrete.

