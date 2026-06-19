# Analysis: Hermes Workflow Integration

## Architecture Context

### System boundaries

- The affected system is the global AI workflow rooted at `E:\UEGameDevelopment`.
- Hermes becomes a first-class workflow entrypoint, but not a new workflow authority.
- Repository truth remains in `AGENTS.md`, `Docs/AI`, `skills`, `.trae/tasks`, and `.trae/scripts`.
- Hermes runtime state remains under `.tools/hermes-worker` and stays outside version-controlled truth.
- No UE5 or Web project application code is in scope.
- Hermes upstream source is read-only evidence and must not be patched.

### Dependency map

```text
Docs/AI + AGENTS.md + skills/
                 |
                 v
      .trae/hermes repository source
      + profiles
      + policy
      + MCP
      + guard plugin
                 |
                 v
      sync-hermes-workflow.ps1
                 |
                 v
 .tools/hermes-worker runtime profiles
                 |
                 v
      invoke-hermes-agent.ps1
                 |
       +---------+----------+
       |                    |
 jinli-planner       jinli-implementer
       |                    |
       +---------+----------+
                 |
    .trae/tasks + authoritative gates
                 |
                 v
         Lead Review + Verify
```

### Data and state ownership

| State | Owner | Persistence |
|---|---|---|
| Workflow policy | `Docs/AI`, `AGENTS.md` | repository |
| Skills | `skills/` | repository |
| Task phase and acceptance | `.trae/tasks` | repository |
| Gate decisions | `.trae/scripts` | deterministic runtime |
| Hermes profile source | `.trae/hermes/profiles` | repository |
| Hermes MCP/plugin source | `.trae/hermes` | repository |
| API credentials | profile `.env` | ignored runtime |
| Hermes memory/session/logs | `.tools/hermes-worker` | ignored runtime |
| Worker evidence | task-local `claims/` and `reports/` | repository |
| Final acceptance | `verification-report.md` + Verify gate | repository |

Hermes memory is advisory. It must not own task phase, architecture, acceptance criteria, work-package claims, or verification state.

### Integration points

- Hermes Profiles and Profile commands.
- `SOUL.md` for Chinese role identity.
- `skills.external_dirs` for the canonical `skills/` root.
- Skill Bundles for role composition.
- `mcp_servers` with per-profile `tools.include` allowlists.
- Plugin hooks: `on_session_start`, `pre_llm_call`, `pre_tool_call`, `post_tool_call`, and `subagent_stop`.
- `.trae/scripts/task-state.ps1`, `task-guard.ps1`, `doc-guard.ps1`, and `verify.ps1`.
- Task-local work packages, claims, reports, and final verification.

### Allowed implementation files

- `.trae/hermes/**`
- `skills/hermes-project-router/**`
- `skills/hermes-jinli-planner/**`
- `skills/hermes-jinli-implementer/**`
- `skills/hermes-jinli-verifier/**`
- `.trae/scripts/sync-hermes-workflow.ps1`
- `.trae/scripts/invoke-hermes-agent.ps1`
- `.trae/scripts/test-hermes-skill-compatibility.ps1`
- `.trae/scripts/test-hermes-workflow-integration.ps1`
- `Docs/AI/39-Hermes-Workflow-Integration.md`
- task-local claim, report, progress, and verification files
- `.tools/hermes-worker/**` only through the synchronization script and only for generated profile/plugin/config state

### Forbidden implementation files

- `Project/**`
- `.tools/hermes-worker/hermes-agent/**`
- `.trae/scripts/task-state.ps1`
- `.trae/scripts/task-guard.ps1`
- `.trae/scripts/doc-guard.ps1`
- unrelated Skills, documents, or task packets
- Git metadata, remotes, history, or credentials

## Current-State Evidence

- Hermes Agent v0.16.0 is installed under `.tools/hermes-worker/hermes-agent`.
- The current runtime has one generic config and a default `SOUL.md`.
- `skills.external_dirs` is currently empty.
- No Hermes workflow launch/sync adapter exists.
- No `jinli-workflow` MCP server or guard plugin exists.
- The current configuration stores a model credential inline and must be migrated without reproducing its value.
- The existing `_shared/2026-06-18-hermes-local-worker-deployment` packet is still in Implement and owns installation concerns.

## Implicit Requirements

- The new integration must coexist with the unfinished local-worker task and must not rewrite its architecture.
- Shared Skills must remain single-source; adapter Skills may translate role semantics but not duplicate domain content.
- Profile isolation is not filesystem sandboxing, so path and mutation policy require mechanical enforcement.
- Hermes plugin hooks can block tools, but hook failure alone cannot be the sole security boundary.
- MCP and launch adapters must fail closed if authoritative scripts fail or return ambiguous output.
- The Planner needs bounded task-document writes but must not gain application-code mutation.
- The Implementer must receive exactly one work package and must not own final verification.
- Credentials require human rotation; automation can only remove inline storage and verify absence.
- Chinese communication belongs in profile/persona and role Skills, not in the workflow state machine.
- Profile synchronization must preserve user-owned state and be idempotent.

## Mature Solution Evidence

### Project-local evidence

- `Docs/AI/27-AI-Workflow-Refactor-Manifest.md` declares `.trae/scripts` as current mechanical authority.
- `Docs/AI/29-Mature-Solution-First-Workflow.md` rejects prompt-only shortcuts and requires options comparison.
- `Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md` requires bounded work packages, claims, reports, and independent verification.
- Existing OpenCode agents use compatibility pointers to canonical Skills rather than duplicating full logic.
- `skills/` is already the physical source behind `.agents/skills`, `.trae/skills`, and `.opencode/skills`.
- The prior Hermes task established workspace-local runtime placement and Worker-only safety.

### Official/framework evidence

- Hermes Profiles provide independent config, `.env`, `SOUL.md`, memory, sessions, Skills, and state.
- Hermes external Skill directories integrate shared Agent Skills directly but are mutable unless policy prevents writes.
- Hermes Skill Bundles compose role-specific Skills without copying content.
- Hermes Profile Distributions package personality, config, Skills, and MCP while excluding credentials and user state.
- Hermes MCP supports per-server tool allowlists, timeouts, resources/prompts policy, and stdio/HTTP transports.
- Hermes plugins can register tools, commands, Skills, and lifecycle hooks.
- Hermes `pre_tool_call` may return `{"action":"block","message":"..."}` to veto a call.
- Profiles do not sandbox filesystem access; explicit `terminal.cwd`, tool filtering, and external enforcement are required.

Official sources:

- https://github.com/NousResearch/hermes-agent
- https://hermes-agent.nousresearch.com/docs/user-guide/profiles
- https://hermes-agent.nousresearch.com/docs/user-guide/profile-distributions
- https://hermes-agent.nousresearch.com/docs/user-guide/features/skills
- https://hermes-agent.nousresearch.com/docs/user-guide/features/plugins
- https://hermes-agent.nousresearch.com/docs/user-guide/features/hooks
- https://hermes-agent.nousresearch.com/docs/reference/mcp-config-reference

### External mature references

| Source | Relevant lesson | Integration decision |
|---|---|---|
| SWE-agent, arXiv:2405.15793 | Agent-computer interface design materially affects coding performance | expose small typed workflow tools instead of broad shell instructions |
| SWE-bench, arXiv:2310.06770 | repository behavior and tests, not model claims, determine success | retain independent deterministic Verify |
| Agentless, arXiv:2407.01489 | multi-agent orchestration is not always necessary | keep deterministic phase/state logic in scripts |
| MAST, arXiv:2503.13657 | multi-agent failures cluster around specification, role, communication, and verification | task packet, role policy, reports, and evidence gates are mandatory |
| OpenHands | isolation and observable event traces improve control | add bounded audit records; do not import the full platform |
| Microsoft Agent Framework | handoff, concurrency, checkpoints, and tracing are useful primitives | use Profiles/work packages/checkpoints within existing state machine |
| Agent Skills specification | SKILL.md is a portable procedural knowledge format | keep shared Skills canonical and adapter layers thin |
| MCP architecture | host controls authorization and context; servers expose capabilities | per-profile allowlists and narrow workflow server |

### Options compared

| Option | Source | Pros | Cons | Decision |
|---|---|---|---|---|
| Native Profiles + shared Skills + MCP + guard plugin | Hermes official extension model | maintainable, updateable, role-isolated, mechanically enforceable | requires adapter/test implementation | Selected |
| Prompt-only two-role emulation | generic LLM practice | very fast | no real state isolation, permissions, claims, or evidence | Rejected |
| Copy OpenCode files into Hermes | current local OpenCode layout | familiar surface | mismatched permission/tool semantics and duplicated truth | Rejected |
| Patch Hermes core | Hermes source | maximum control | upstream drift and maintenance burden | Rejected |
| Introduce LangGraph/AutoGen orchestrator | external frameworks | rich graph abstractions | duplicates task state and creates competing authority | Rejected |
| Keep Hermes as generic Worker | prior task | safest minimum | does not meet first-class entrypoint requirement | Rejected |

### Rejected shortcuts

- Do not copy the two Chinese Skill files into profile-local Skills.
- Do not rely on `SOUL.md` or `AGENTS.md` as a filesystem boundary.
- Do not expose the full MCP tool surface to both profiles.
- Do not let a Worker transition task phase or declare verification pass.
- Do not store task truth in Hermes memory.
- Do not treat profile separation as sandboxing.
- Do not keep credentials inline in YAML.
- Do not modify Hermes core to add project-specific behavior.

### Selected mature path

Build a repository-owned Hermes adapter layer using native Profiles, shared Skills, role bundles, a typed workflow MCP server, a fail-closed guard plugin, and tested sync/launch adapters. Preserve `.trae` scripts and task packets as the sole mechanical authority. Keep runtime secrets and user state under `.tools`, and independently verify every worker result.

## Acceptance Criteria

- AC01: Repository-owned sources define separate `jinli-planner` and `jinli-implementer` Profiles with Chinese role identities and repository-root cwd.
- AC02: Both Profiles load canonical `E:/UEGameDevelopment/skills` through `skills.external_dirs` without profile-local name shadowing.
- AC03: Four Hermes adapter Skills exist, pass Agent Skills compatibility checks, and do not duplicate domain implementation rules.
- AC04: Role Skill Bundles resolve all required Skills and differ appropriately between Plan, Implement, and Verify.
- AC05: The `jinli-workflow` MCP server exposes only documented tools, rejects path traversal, delegates gate decisions to authoritative scripts, and returns structured evidence.
- AC06: Planner and Implementer MCP allowlists expose only role-appropriate tools; Implementer cannot change architecture, task criteria, or verification state.
- AC07: The guard plugin blocks mutation when role/task/WP/gate context is missing and enforces work-package Allowed/Forbidden Paths.
- AC08: The synchronization script is idempotent, preserves user-owned runtime state, detects drift/shadowing/inline credentials, and supports check-only mode.
- AC09: The launch adapter refuses invalid role/task/WP or failed Plan/Can-Edit gates and produces a complete dry-run resolution.
- AC10: Inline model credentials are removed from generated/runtime config, repository files contain no copied credential, and human rotation is recorded as required external action.
- AC11: Deterministic unit and integration tests pass without requiring a live model call.
- AC12: Both Hermes Profiles pass `doctor`; read-only Chinese smoke tests run when valid credentials are available or are explicitly recorded as not run.
- AC13: Documentation explains architecture, operations, security, troubleshooting, and verification, and final Verify remains lead-owned.

## Automated Verification Plan

- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-hermes-skill-compatibility.ps1`
- Expected: all shared Skill, adapter, bundle, shadowing, and credential checks pass.
- Command: `& ".\.tools\hermes-worker\hermes-agent\venv\Scripts\python.exe" -m pytest .\.trae\hermes\tests -q`
- Expected: all MCP and guard plugin unit tests pass.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-hermes-workflow-integration.ps1`
- Expected: all sync, launcher, gate, scope, and dry-run integration tests pass.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\sync-hermes-workflow.ps1 -Check`
- Expected: no runtime drift, Skill shadow, inline credential, or missing integration component.
- Command: `& ".\.tools\hermes-worker\hermes-agent\venv\Scripts\hermes.exe" -p jinli-planner doctor`
- Expected: no blocking profile, MCP, or plugin error.
- Command: `& ".\.tools\hermes-worker\hermes-agent\venv\Scripts\hermes.exe" -p jinli-implementer doctor`
- Expected: no blocking profile, MCP, or plugin error.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\doc-guard.ps1 check-task "_shared/2026-06-19-hermes-workflow-integration" -Stage implement`
- Expected: documentation governance passes.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\task-guard.ps1 _shared/2026-06-19-hermes-workflow-integration verify`
- Expected: passes only after reports, AC mapping, independent evidence, and verification state are complete.

## Risks and Mitigations

- Hermes hook fail-open behavior: MCP and launch adapters remain authoritative; plugin is defense in depth.
- Windows path parsing: all path checks use resolved absolute paths and `-LiteralPath`; tests cover traversal and mixed separators.
- Shared Skill mutation: role policy blocks shared Skill writes and compatibility checks detect shadowing/drift.
- Runtime/profile drift: source-to-runtime synchronization supports `-Check` and idempotence.
- Credential exposure: no value is copied into plans/reports; runtime config is migrated to `.env`; provider rotation remains explicit.
- Task overlap with local-worker deployment: this task consumes the installed runtime but does not edit the prior task packet or installer architecture.
- Live-model variability: deterministic tests carry acceptance; smoke prompts are supplementary.

