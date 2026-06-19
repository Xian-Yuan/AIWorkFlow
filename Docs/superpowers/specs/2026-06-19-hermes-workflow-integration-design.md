# Hermes Workflow Integration Design

Date: 2026-06-19  
Status: Approved for task-packet planning  
Scope: Global AI workflow infrastructure

## Goal

Promote Hermes Agent from an isolated local Worker runtime into a first-class entrypoint beside Codex, OpenCode, and Trae while preserving one authoritative workflow kernel:

- `Docs/AI/` for shared policy;
- `skills/` for shared procedural knowledge;
- `.trae/tasks/` for runtime task packets;
- `.trae/scripts/task-state.ps1` and `.trae/scripts/task-guard.ps1` for mechanical authority;
- lead-owned Review and Verify for final acceptance.

The integration provides two user-facing Hermes agents:

- `jinli-planner` — 金璃小天才, responsible for Plan and final Review/Verify coordination;
- `jinli-implementer` — 金璃好帮手, responsible for one authorized work package at a time.

## Design Principles

1. Shared kernel, native adapters: reuse repository truth and express it through Hermes Profiles, Skills, MCP, plugins, and launch scripts.
2. Mechanical authority remains outside the model: prompts can explain policy, but PowerShell gates decide authorization.
3. Fail closed for mutation: missing task identity, invalid work package, failed gate, or plugin/MCP error blocks mutation.
4. Least privilege: expose only the workflow tools and repository paths required by the active role.
5. No second truth source: Hermes memory may retain preferences and lessons, but not duplicate task state or architecture decisions.
6. No Hermes core fork: use documented extension points and keep the upstream runtime updateable.
7. Evidence before acceptance: worker completion is a report, not proof; independent verification remains mandatory.

## Architecture

```text
                         User
                           |
              +------------+-------------+
              |                          |
     jinli-planner profile      jinli-implementer profile
       金璃小天才                    金璃好帮手
              |                          |
              +------------+-------------+
                           |
          Hermes-native integration surfaces
          +--------------------------------+
          | Profiles / SOUL.md             |
          | Shared Skills + Skill Bundles  |
          | jinli-workflow MCP server      |
          | jinli-workflow-guard plugin    |
          | launch/sync adapters           |
          +--------------------------------+
                           |
                 Shared workflow kernel
          +--------------------------------+
          | AGENTS.md / Docs/AI            |
          | skills/                        |
          | .trae/tasks                    |
          | task-state.ps1 / task-guard.ps1|
          | doc-guard.ps1 / verify.ps1     |
          +--------------------------------+
```

## Repository-Owned and Runtime-Owned State

### Repository-owned, version-controlled

```text
.trae/hermes/
  profiles/
    jinli-planner/
    jinli-implementer/
  mcp/jinli_workflow/
  plugins/jinli-workflow-guard/
  policies/
  tests/

skills/
  hermes-project-router/
  hermes-jinli-planner/
  hermes-jinli-implementer/
  hermes-jinli-verifier/

.trae/scripts/
  sync-hermes-workflow.ps1
  invoke-hermes-agent.ps1
  test-hermes-workflow-integration.ps1
  test-hermes-skill-compatibility.ps1
```

### Runtime-owned, ignored

```text
.tools/hermes-worker/
  profiles/
  plugins/
  memories/
  sessions/
  logs/
  state databases
  .env
```

Repository-owned files are the reproducible source. Runtime files are generated or synchronized copies. API keys, tokens, memories, sessions, and logs never enter the repository.

## Components

### 1. Native Hermes Profiles

`jinli-planner` and `jinli-implementer` are separate Hermes Profiles, not prompt aliases. Each receives an independent:

- `config.yaml`;
- `.env`;
- `SOUL.md`;
- memory and session store;
- enabled plugin/tool policy;
- MCP configuration;
- Skill Bundle.

Both profiles set `terminal.cwd` to `E:/UEGameDevelopment` and use the existing root `AGENTS.md`. No root `.hermes.md` is added because Hermes uses the first matching project context file and a second root context file could hide shared policy.

Profile responsibilities:

| Profile | May do | Must not do |
|---|---|---|
| `jinli-planner` | research, clarify, create/update task design documents, obtain user confirmation, run Plan gate, coordinate Review/Verify | edit application code, claim implementation work, accept worker claims without verification |
| `jinli-implementer` | read one task packet, claim one work package, edit only its allowed paths, run scoped checks, submit one report | choose architecture, change task acceptance criteria, transition final verification, edit outside work-package scope |

### 2. Shared Skill Layer

Hermes loads the canonical `E:/UEGameDevelopment/skills` directory through `skills.external_dirs`. This matches the existing junction-based sharing used by Codex, Trae, and OpenCode.

Four thin Hermes adapter Skills translate role and tool semantics without copying domain knowledge:

- `hermes-project-router`;
- `hermes-jinli-planner`;
- `hermes-jinli-implementer`;
- `hermes-jinli-verifier`.

The adapters reference the canonical workflow documents and existing 金璃 Skills. Domain Skills remain single-source under `skills/`.

Controls:

- local profile Skills may not shadow shared Skill names;
- `skill_manage` cannot mutate shared Skills during normal project tasks;
- compatibility tests validate frontmatter, required files, duplicate names, and role adapters;
- workflow-maintenance tasks require an explicit allowed path before shared Skills can change.

### 3. Hermes Skill Bundles

Profiles receive role bundles:

```text
/jinli-plan
  hermes-project-router
  hermes-jinli-planner
  doc-governance
  failure-memory

/jinli-implement
  hermes-project-router
  hermes-jinli-implementer
  anti-degradation
  anti-duplication
  verification-before-completion

/jinli-verify
  hermes-project-router
  hermes-jinli-verifier
  code-quality-reviewer
  verification-before-completion
```

Bundles define role composition only. They do not duplicate Skill content.

### 4. `jinli-workflow` MCP Server

The MCP server exposes a narrow, typed interface over the existing PowerShell workflow:

| Tool | Role | Behavior |
|---|---|---|
| `workflow_list_tasks` | both | list active task packets and phases |
| `workflow_read_packet` | both | read approved task packet files |
| `workflow_init_task` | planner | initialize a task packet under `.trae/tasks` |
| `workflow_write_task_document` | planner | write only approved task document names |
| `workflow_check_plan` | planner | run `task-guard.ps1 task plan` |
| `workflow_can_edit` | implementer | run `task-state.ps1 can-edit task` |
| `workflow_read_work_package` | implementer | resolve one concrete work package |
| `workflow_claim_work_package` | implementer | create one collision-safe claim |
| `workflow_submit_report` | implementer | validate and write one worker report |
| `workflow_run_verify` | planner/verifier | run verification commands and return evidence; cannot self-declare pass |

The MCP server:

- delegates state decisions to authoritative scripts;
- validates task names and paths against traversal;
- uses structured JSON responses;
- never stores a parallel task state;
- never exposes destructive task-state transitions to the Worker profile;
- redacts secrets from command output;
- records command, exit code, and evidence path.

Hermes MCP configuration uses per-server `tools.include` allowlists. Planner and Implementer profiles receive different tool subsets.

### 5. `jinli-workflow-guard` Plugin

The plugin is defense in depth around Hermes tools. It uses:

- `pre_llm_call` to inject current role, task, work package, and phase context;
- `pre_tool_call` to block unauthorized mutation;
- `post_tool_call` to append audit records;
- `subagent_stop` to require a bounded child result;
- `on_session_start` to validate profile and workspace identity.

Launch environment:

```text
JINLI_ROLE=planner|implementer|verifier
JINLI_TASK_NAME=_shared/2026-06-19-hermes-workflow-integration
JINLI_WORK_PACKAGE=WP01
UEGAMEDEV_ROOT=E:/UEGameDevelopment
```

Mutation policy:

- Planner may write only task documents, formal design/plan documents, and explicitly authorized workflow-maintenance paths.
- Implementer requires a valid task, work package, claim, Plan pass, and Can-Edit pass.
- Implementer paths are derived from the work package's `Allowed Paths`; `Forbidden Paths` always win.
- Verifier is read-only except the task-local `verification-report.md` and approved verification state updates.
- Missing or malformed context blocks mutation.

The plugin does not replace the workflow MCP or scripts. If the plugin crashes, the launch adapter and MCP still enforce gates.

### 6. Synchronization and Launch Adapters

`sync-hermes-workflow.ps1`:

- creates or updates both profiles from repository-owned source;
- preserves `.env`, memory, sessions, logs, and user-owned state;
- installs the guard plugin;
- configures `skills.external_dirs`;
- writes role-specific Skill Bundles and MCP allowlists;
- detects local Skill shadowing;
- rejects inline API keys in generated config;
- supports `-Check` without mutation.

`invoke-hermes-agent.ps1`:

- resolves role, task, and optional work package;
- verifies profile health;
- checks Plan/Can-Edit before starting an Implementer;
- sets role/task environment variables;
- starts Hermes from the repository root;
- supports `-DryRun`;
- never enables gateway, cron, or unattended approvals.

### 7. Credentials

The existing inline model credential in the Hermes runtime configuration is treated as compromised because it was stored in plaintext. Implementation must:

1. remove inline credentials from `config.yaml`;
2. reference environment-backed credentials through `.env`;
3. verify repository files contain no credential values;
4. require the user to rotate the exposed credential outside the repository;
5. never print credential values in reports or test output.

Credential rotation itself is a human/external-provider action and cannot be asserted complete by repository automation.

## Data Flow

### Planner flow

```text
Chinese request
  -> jinli-planner profile
  -> shared AGENTS.md + role bundle
  -> research and task discovery
  -> workflow_init_task / workflow_write_task_document
  -> user confirms mature design
  -> workflow_check_plan
  -> handoff references task packet
```

### Implementer flow

```text
task + WP ID
  -> invoke-hermes-agent.ps1
  -> Plan gate + Can-Edit gate
  -> jinli-implementer profile
  -> workflow_read_work_package
  -> claim
  -> bounded edits and tests
  -> workflow_submit_report
  -> stop
```

### Verification flow

```text
worker reports
  -> jinli-planner / verifier mode
  -> independent rerun
  -> verification-report.md
  -> task-guard.ps1 verify
  -> archive only after pass
```

## Failure Behavior

| Failure | Required behavior |
|---|---|
| Task missing or ambiguous | refuse launch and list valid tasks |
| Plan gate fails | no Implementer session |
| Can-Edit fails | no mutating tools |
| Work package missing/ambiguous | refuse claim and launch |
| Claim collision | return current owner; do not overwrite |
| MCP process fails | mutation remains blocked; report diagnostic |
| Guard plugin fails | launch adapter/MCP still block mutation |
| Skill shadowing detected | sync/check fails |
| Inline secret detected | sync/check fails without printing value |
| Worker report incomplete | Implement gate remains blocked |
| Verification command unavailable | mark not-run/fail with residual risk; never infer pass |

## Testing Strategy

### Unit tests

- task/path validation and traversal rejection;
- role-to-tool allowlists;
- claim collision behavior;
- report schema validation;
- work-package allowed/forbidden path resolution;
- plugin `pre_tool_call` decisions;
- secret and Skill-shadow detection.

### Integration tests

- profile sync dry-run and idempotence;
- planner profile sees shared Skills and Chinese persona;
- implementer cannot start before Plan/Can-Edit;
- valid task/WP resolves exactly one claim/report path;
- MCP tool filtering differs by role;
- plugin blocks writes outside work-package paths;
- reports remain insufficient until independent verification.

### End-to-end smoke tests

- `jinli-planner` summarizes active workflow in Chinese without mutation;
- `jinli-implementer` dry-run resolves a valid work package;
- a synthetic invalid task is rejected;
- Hermes `doctor` passes for both profiles;
- no new Hermes state is written outside `.tools/hermes-worker`.

## Options Compared

| Option | Advantages | Problems | Decision |
|---|---|---|---|
| Native Profiles + shared Skills + MCP + guard plugin | Uses official extension points, preserves shared truth, supports role isolation and mechanical gates | Requires adapter code and tests | Selected |
| Copy OpenCode Agent files into Hermes prompts | Fast initial setup | No real permissions, MCP policy, profile isolation, or mechanical enforcement | Rejected |
| Fork Hermes core | Maximum control | High maintenance cost, upstream drift, unnecessary for documented extension points | Rejected |
| Keep Hermes as a generic Worker only | Lowest change | Does not meet first-class entrypoint or two-Agent requirement | Rejected |
| Introduce LangGraph/AutoGen as a new orchestrator | Rich graph abstractions | Creates a competing state machine and duplicates `.trae` authority | Rejected |

## External Evidence

- Hermes Agent official repository: https://github.com/NousResearch/hermes-agent
- Hermes Profiles: https://hermes-agent.nousresearch.com/docs/user-guide/profiles
- Hermes Profile Distributions: https://hermes-agent.nousresearch.com/docs/user-guide/profile-distributions
- Hermes Skills: https://hermes-agent.nousresearch.com/docs/user-guide/features/skills
- Hermes Plugins and Hooks: https://hermes-agent.nousresearch.com/docs/user-guide/features/plugins
- Hermes MCP reference: https://hermes-agent.nousresearch.com/docs/reference/mcp-config-reference
- Agent Skills specification: https://agentskills.io/specification
- Model Context Protocol architecture: https://modelcontextprotocol.io/docs/learn/architecture
- SWE-agent / Agent-Computer Interface: https://arxiv.org/abs/2405.15793
- SWE-bench: https://arxiv.org/abs/2310.06770
- Agentless: https://arxiv.org/abs/2407.01489
- MAST failure taxonomy: https://arxiv.org/abs/2503.13657
- OpenHands: https://github.com/All-Hands-AI/OpenHands
- Microsoft Agent Framework: https://github.com/microsoft/agent-framework

## Non-Goals

- Replacing `.trae/scripts` with Hermes state.
- Forking or patching Hermes core.
- Enabling gateway, cron, unattended autonomy, or autonomous Skill publication.
- Migrating repository truth into Hermes memory.
- Giving Workers architecture or final acceptance authority.
- Sharing API keys, memories, sessions, or logs through profile distributions.
- Modifying UE5 or Web project application code.

