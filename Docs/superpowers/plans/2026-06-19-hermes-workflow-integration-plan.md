# Hermes Workflow Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate Hermes as a first-class, Chinese-capable Plan/Implement workflow entrypoint using native Profiles, shared Skills, a bounded workflow MCP server, a fail-closed guard plugin, and the existing `.trae` task-packet authority.

**Architecture:** Repository-owned Hermes integration sources live under `.trae/hermes`, while runtime profiles, credentials, memories, and sessions remain under `.tools/hermes-worker`. Two native profiles share canonical Skills through `skills.external_dirs`; a typed MCP server wraps authoritative workflow scripts; a plugin and launch adapter enforce role and work-package boundaries.

**Tech Stack:** PowerShell 7/Windows PowerShell, Python 3.11, pytest, Hermes Agent v0.16+, Model Context Protocol, YAML, Markdown task packets.

---

## Authoritative Task Packet

```text
.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/
```

The task packet owns acceptance criteria, work-package boundaries, reports, and final verification.

## Planned File Structure

```text
.trae/hermes/
  README.md
  policies/roles.yaml
  profiles/jinli-planner/
  profiles/jinli-implementer/
  mcp/jinli_workflow/
  plugins/jinli-workflow-guard/
  tests/

skills/
  hermes-project-router/SKILL.md
  hermes-jinli-planner/SKILL.md
  hermes-jinli-implementer/SKILL.md
  hermes-jinli-verifier/SKILL.md

.trae/scripts/
  sync-hermes-workflow.ps1
  invoke-hermes-agent.ps1
  test-hermes-skill-compatibility.ps1
  test-hermes-workflow-integration.ps1

Docs/AI/39-Hermes-Workflow-Integration.md
```

## Task 1: Plan Authorization

- [ ] Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\task-guard.ps1 _shared/2026-06-19-hermes-workflow-integration plan
```

Expected: every Plan check passes.

- [ ] Transition the task to Implement through the authoritative task-state script.

- [ ] Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\task-state.ps1 can-edit _shared/2026-06-19-hermes-workflow-integration
```

Expected: editing is allowed.

## Task 2: Profiles, Skills, and Synchronization

**Owner:** WP01

- [ ] Write failing compatibility tests in `.trae/scripts/test-hermes-skill-compatibility.ps1` for:

```text
required Hermes adapter Skills exist
every adapter has valid name and description frontmatter
required canonical Skills resolve through E:/UEGameDevelopment/skills
no profile-local Skill shadows a shared Skill
profile config uses skills.external_dirs
profile config contains no inline API key
both role bundles resolve every listed Skill
```

- [ ] Run the tests before creating adapters:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-hermes-skill-compatibility.ps1
```

Expected: failure identifying missing adapters/profile sources.

- [ ] Create the four thin adapter Skills. Each must:

```text
reference AGENTS.md and the shared task-packet workflow
name the matching canonical 金璃 role
translate Hermes Profile, MCP, bundle, and plugin semantics
avoid copying domain-specific UE/Web rules
require Chinese output unless code or a proper noun requires otherwise
```

- [ ] Create repository-owned profile sources:

```text
.trae/hermes/profiles/jinli-planner/
.trae/hermes/profiles/jinli-implementer/
```

Each profile source includes:

```text
SOUL.md
config.overlay.yaml
mcp.json
skill-bundles/
```

- [ ] Add `.trae/hermes/policies/roles.yaml` with explicit planner, implementer, and verifier path/tool rules.

- [ ] Write `sync-hermes-workflow.ps1` with `-Check`, `-Apply`, and optional `-Profile` modes.

Required behavior:

```text
preserve .env, memories, sessions, logs, and state databases
copy only repository-owned profile/plugin/bundle files
configure external skill root
detect shadowing and inline credentials
produce a structured summary without secret values
be idempotent
```

- [ ] Re-run compatibility tests.

Expected: all compatibility checks pass.

## Task 3: Workflow MCP Server

**Owner:** WP02

- [ ] Write failing pytest cases under `.trae/hermes/tests/test_workflow_mcp.py` for:

```python
def test_rejects_task_path_traversal(): ...
def test_lists_only_real_task_packets(): ...
def test_plan_check_delegates_to_task_guard(): ...
def test_can_edit_delegates_to_task_state(): ...
def test_claim_is_collision_safe(): ...
def test_report_requires_scope_and_evidence_sections(): ...
def test_implementer_cannot_change_architecture_or_verify_state(): ...
def test_tool_allowlists_are_role_specific(): ...
```

- [ ] Run:

```powershell
& ".\.tools\hermes-worker\hermes-agent\venv\Scripts\python.exe" -m pytest .\.trae\hermes\tests\test_workflow_mcp.py -q
```

Expected: failure because the MCP package does not exist.

- [ ] Implement `.trae/hermes/mcp/jinli_workflow/` as a Python package with:

```text
server.py        MCP registration and stdio entrypoint
service.py       workflow operations
policy.py        role/tool authorization
paths.py         root containment and task resolution
schemas.py       request/response validation
__main__.py      python -m entrypoint
```

- [ ] Ensure every subprocess call:

```text
uses an argument array rather than shell interpolation
sets cwd to E:/UEGameDevelopment
captures stdout, stderr, and exit code
uses a bounded timeout
redacts secret-shaped values
returns structured JSON
```

- [ ] Re-run MCP tests.

Expected: all MCP unit tests pass.

## Task 4: Workflow Guard Plugin

**Owner:** WP03

- [ ] Write failing pytest cases under `.trae/hermes/tests/test_workflow_guard.py` for:

```python
def test_missing_role_blocks_mutation(): ...
def test_planner_cannot_edit_application_code(): ...
def test_implementer_requires_task_and_work_package(): ...
def test_implementer_requires_plan_and_can_edit(): ...
def test_forbidden_paths_override_allowed_paths(): ...
def test_verifier_only_writes_verification_report(): ...
def test_subagent_result_requires_bounded_report(): ...
def test_read_only_tools_remain_available_when_blocked(): ...
```

- [ ] Run:

```powershell
& ".\.tools\hermes-worker\hermes-agent\venv\Scripts\python.exe" -m pytest .\.trae\hermes\tests\test_workflow_guard.py -q
```

Expected: failure because the plugin does not exist.

- [ ] Implement `.trae/hermes/plugins/jinli-workflow-guard/` with:

```text
plugin.yaml
__init__.py
guard.py
audit.py
```

- [ ] Register:

```python
ctx.register_hook("on_session_start", validate_session)
ctx.register_hook("pre_llm_call", inject_task_context)
ctx.register_hook("pre_tool_call", authorize_tool)
ctx.register_hook("post_tool_call", record_tool_result)
ctx.register_hook("subagent_stop", validate_subagent_result)
```

- [ ] `authorize_tool` must return Hermes' canonical block response:

```python
{"action": "block", "message": "A concise reason and required next action."}
```

- [ ] Re-run guard tests.

Expected: all guard unit tests pass.

## Task 5: Launch Adapter and End-to-End Regression

**Owner:** WP04

- [ ] Write failing tests in `.trae/scripts/test-hermes-workflow-integration.ps1` covering:

```text
unknown role rejected
missing task rejected for implementer
missing work package rejected
failed Plan gate prevents implementer launch
failed Can-Edit prevents implementer launch
dry-run prints profile, task, WP, MCP, plugin, claim, and report paths
planner dry-run does not require a WP
sync check detects profile drift
runtime files remain under .tools/hermes-worker
```

- [ ] Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-hermes-workflow-integration.ps1
```

Expected: failure because the launcher does not exist.

- [ ] Implement `invoke-hermes-agent.ps1` with:

```text
-Role planner|implementer|verifier
-TaskName optional for planner, required otherwise
-WorkPackage required for implementer
-DryRun
-NoSync
```

- [ ] The launcher must run sync/check, resolve the managed Hermes executable, set role/task environment variables, and execute from the repository root.

- [ ] Add `Docs/AI/39-Hermes-Workflow-Integration.md` documenting:

```text
architecture and ownership
profile commands
task lifecycle
MCP tools
Skill sharing
security and credential rotation
troubleshooting
verification commands
```

- [ ] Re-run end-to-end regression.

Expected: all deterministic tests pass without a live model call.

## Task 6: Runtime Profile Verification

- [ ] Apply synchronization:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\sync-hermes-workflow.ps1 -Apply
```

Expected: both runtime profiles and the plugin are synchronized without modifying user-owned state.

- [ ] Run:

```powershell
& ".\.tools\hermes-worker\hermes-agent\venv\Scripts\hermes.exe" -p jinli-planner doctor
& ".\.tools\hermes-worker\hermes-agent\venv\Scripts\hermes.exe" -p jinli-implementer doctor
```

Expected: no blocking profile, plugin, MCP, or configuration error.

- [ ] Run dry-run launch checks:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\invoke-hermes-agent.ps1 -Role planner -DryRun
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\invoke-hermes-agent.ps1 -Role implementer -TaskName _shared/2026-06-19-hermes-workflow-integration -WorkPackage WP01 -DryRun
```

Expected: each resolves the correct profile and bounded context without starting a model session.

- [ ] If valid credentials are available, run read-only Chinese smoke prompts for both profiles. Do not treat unavailable credentials as a test pass; record the smoke test as not run with residual risk.

## Task 7: Independent Review and Verify

- [ ] Review all worker reports and changed paths.

- [ ] Independently run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-hermes-skill-compatibility.ps1
& ".\.tools\hermes-worker\hermes-agent\venv\Scripts\python.exe" -m pytest .\.trae\hermes\tests -q
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-hermes-workflow-integration.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\doc-guard.ps1 check-task "_shared/2026-06-19-hermes-workflow-integration" -Stage implement
```

Expected: all deterministic checks pass.

- [ ] Confirm no inline credential remains in repository-owned or generated profile configuration. Report only file/field names, never secret values.

- [ ] Create `verification-report.md`, map AC01 through AC13, and run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\task-guard.ps1 _shared/2026-06-19-hermes-workflow-integration verify
```

Expected: Verify gate passes only after independent evidence is recorded.

## Execution Order

```text
Plan gate
  -> WP01 Profiles/Skills/Sync
  -> WP02 Workflow MCP        } WP01-WP03 may run in parallel
  -> WP03 Guard Plugin        }
  -> WP04 Launcher/E2E/Docs
  -> Lead Review
  -> Independent Verify
```

## Handoff

Implementation should use subagent-driven development with one worker per work package. WP01, WP02, and WP03 have disjoint write sets and may execute concurrently after the Plan gate. WP04 starts only after their interfaces and tests are available.

