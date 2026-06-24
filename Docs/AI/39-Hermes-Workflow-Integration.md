---
domain: ai
domain_path: ai/workflow
kg_node_id: node.doc-ai-ai-39-hermes-workflow-integration-7d50
t13_retro_classified_at: "2026-06-24T04:47:04Z"
kg_id: doc.ai.ai.39-hermes-workflow-integration.7d50

---

# 39. Hermes Workflow Integration

> **Status**: Active (Archived)
> **Date**: 2026-06-19
> **Task Packet**: `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/`

## Overview

Hermes Agent is integrated as a first-class workflow entrypoint alongside Codex, OpenCode, and Trae. The integration uses Hermes' documented extension surfaces — native Profiles, shared Skills, a typed MCP server, and a fail-closed guard plugin — without modifying Hermes core.

## Architecture

Two native Hermes Profiles provide role-isolated entrypoints:

| Profile | Role | Canonical Agent |
|---------|------|----------------|
| `jinli-planner` | Plan + Review/Verify coordination | 金璃小天才 |
| `jinli-implementer` | Single work package implementation | 金璃好帮手 |

Both profiles share:
- Canonical Skills through `skills.external_dirs` → `E:/UEGameDevelopment/skills`
- Authoritative workflow gates: `task-state.ps1`, `task-guard.ps1`
- Task packets under `.trae/tasks`
- Repository root: `E:/UEGameDevelopment`

## Components

### 1. Thin Hermes Adapter Skills

Four adapter Skills translate Hermes Profile/MCP/Bundle/Plugin semantics without duplicating domain knowledge:

- `hermes-project-router` — routing layer
- `hermes-jinli-planner` — Planner semantics
- `hermes-jinli-implementer` — Implementer semantics
- `hermes-jinli-verifier` — Verifier semantics

### 2. `jinli-workflow` MCP Server

A typed, path-safe MCP server exposing a narrow interface over authoritative PowerShell scripts:

| Tool | Planner | Implementer | Verifier |
|------|:-------:|:-----------:|:--------:|
| `workflow_list_tasks` | ✅ | ✅ | ✅ |
| `workflow_read_packet` | ✅ | ✅ | ✅ |
| `workflow_init_task` | ✅ | — | — |
| `workflow_write_task_document` | ✅ | — | — |
| `workflow_check_plan` | ✅ | — | — |
| `workflow_can_edit` | — | ✅ | — |
| `workflow_read_work_package` | — | ✅ | — |
| `workflow_claim_work_package` | — | ✅ | — |
| `workflow_submit_report` | — | ✅ | — |
| `workflow_run_verify` | ✅ | — | ✅ |

### 3. `jinli-workflow-guard` Plugin

Defense-in-depth around Hermes tools:

- `pre_tool_call`: blocks unauthorized mutation based on role/task/WP/path
- `post_tool_call`: records secret-safe audit trail
- `pre_llm_call`: injects role/task/WP context
- `on_session_start`: validates profile/workspace identity
- `subagent_stop`: validates bounded child report contract

### 4. Synchronization

`sync-hermes-workflow.ps1` copies repository-owned sources to the runtime while preserving user-owned state (`.env`, memories, sessions, logs).

### 5. Launch Adapter

`invoke-hermes-agent.ps1` resolves role/task/WP, verifies gates, sets environment, and starts Hermes.

## Commands

```powershell
# Check profile drift
.\.trae\scripts\sync-hermes-workflow.ps1 -Check

# Apply synchronization
.\.trae\scripts\sync-hermes-workflow.ps1 -Apply

# Launch planner (dry-run)
.\.trae\scripts\invoke-hermes-agent.ps1 -Role planner -DryRun

# Launch implementer for WP01
.\.trae\scripts\invoke-hermes-agent.ps1 -Role implementer -TaskName _shared/2026-06-19-hermes-workflow-integration -WorkPackage WP01

# Run compatibility tests
.\.trae\scripts\test-hermes-skill-compatibility.ps1

# Run MCP unit tests
& ".\.tools\hermes-worker\hermes-agent\venv\Scripts\python.exe" -m pytest .\.trae\hermes\tests -q

# Run integration tests
.\.trae\scripts\test-hermes-workflow-integration.ps1
```

## Security

- No inline credentials in repository files
- All profiles inherit main opencode.json configuration (model/apiKey removed from profile configs to avoid duplication)
- Guard plugin blocks mutation on missing/invalid context
- MCP server rejects path traversal
- Audit records redact secret values
- Credential rotation is a human/external-provider action

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| "Plan gate has not passed" | Task still in Plan phase | Run `task-guard.ps1 <task> plan` and resolve failures |
| "Can-Edit check failed" | Phase is not `implement` | Transition task with `task-state.ps1 transition <task> plan-complete` |
| "Profile not found" | Profiles not synchronized | Run `sync-hermes-workflow.ps1 -Apply` |
| "Hermes executable not found" | Hermes not installed | Install under `.tools/hermes-worker/` |
| "Skill shadowing detected" | Local Skill duplicates shared name | Remove the local Skill or rename it |

## Verification

All deterministic tests must pass without a live model call:

1. `test-hermes-skill-compatibility.ps1` — 27/27
2. `pytest .trae/hermes/tests -q` — 23/23
3. `test-hermes-workflow-integration.ps1` — integration suite
4. `sync-hermes-workflow.ps1 -Check` — 2/2 profiles valid, no drift
5. `hermes doctor` for both profiles — no blocking errors

Current deterministic total: **66/66** checks passed:

- Skill Compatibility: 27
- MCP unit tests: 12
- Guard unit tests: 6
- MCP stdio subprocess tests: 5
- E2E integration tests: 14
- Sync checks: 2
