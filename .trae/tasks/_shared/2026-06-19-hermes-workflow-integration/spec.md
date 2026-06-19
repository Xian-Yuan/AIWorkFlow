# Hermes Workflow Integration — Living Spec

## Quick Status (AI Entry Point)

- **Current Phase**: Plan
- **Last Updated**: 2026-06-19
- **Progress**: 0/13 acceptance criteria verified
- **Next Step**: Pass Plan gate, transition to Implement, then execute WP01-WP03 in parallel.
- **Blockers**: None for planning. Human credential rotation will be required during implementation.

## GIVEN

- Hermes Agent v0.16.0 is installed under `.tools/hermes-worker`.
- The shared workflow uses `AGENTS.md`, `Docs/AI`, `skills`, `.trae/tasks`, and authoritative PowerShell gates.
- 金璃小天才 and 金璃好帮手 exist as canonical shared Skills and OpenCode compatibility agents.
- Hermes Profiles do not provide filesystem sandboxing by themselves.
- The user approved a mature, first-class Hermes integration with MCP, Skills, and the current workflow framework.

## WHEN

- The task's four work packages implement repository-owned profile sources, Hermes Skill adapters, a workflow MCP server, a guard plugin, synchronization, launch tooling, tests, and documentation.
- The lead model independently reviews worker evidence and runs final verification.

## THEN

### S01: Planner entrypoint

**Status**: [ ] pending  
**Tasks**: T2, T5, T6  
**Linked AC**: AC01, AC04, AC09, AC12

GIVEN the `jinli-planner` Profile is synchronized  
WHEN the user starts it from `E:\UEGameDevelopment`  
THEN it communicates in Simplified Chinese, loads the shared project context and Plan bundle, and does not require a work package.

### S02: Shared Skill consistency

**Status**: [ ] pending  
**Tasks**: T2  
**Linked AC**: AC02, AC03, AC04

GIVEN canonical Skills live under `E:\UEGameDevelopment\skills`  
WHEN either Hermes Profile indexes Skills  
THEN shared Skills are discovered through `skills.external_dirs`, role adapters load successfully, and no profile-local Skill shadows a shared name.

### S03: Authorized implementation

**Status**: [ ] pending  
**Tasks**: T3, T4, T5  
**Linked AC**: AC05, AC06, AC07, AC09

GIVEN a task has passed Plan, Can-Edit succeeds, and one work package exists  
WHEN `jinli-implementer` starts with that task and WP ID  
THEN it resolves exactly one claim/report contract and may mutate only the work package's allowed paths.

### S04: Failed authorization

**Status**: [ ] pending  
**Tasks**: T3, T4, T5  
**Linked AC**: AC05, AC07, AC09

GIVEN task identity, WP identity, Plan state, Can-Edit state, or path scope is missing or invalid  
WHEN a mutating tool is requested  
THEN launch or tool execution is blocked with a concise reason and required next action while read-only diagnostics remain available.

### S05: Safe synchronization and credentials

**Status**: [ ] pending  
**Tasks**: T2, T5  
**Linked AC**: AC08, AC10

GIVEN profile source differs from runtime or runtime contains user-owned state  
WHEN sync runs  
THEN repository-owned files converge, user-owned `.env`/memory/session/log state is preserved, inline credentials are rejected, and a second run is idempotent.

### S06: Worker evidence and independent verification

**Status**: [ ] pending  
**Tasks**: T3, T5, T7  
**Linked AC**: AC06, AC11, AC13

GIVEN a Worker reports completion  
WHEN the lead reviews the task  
THEN the report alone is insufficient; deterministic checks are rerun, AC evidence is recorded, and only the Verify gate may accept completion.

### S07: Failure containment

**Status**: [ ] pending  
**Tasks**: T3, T4, T5, T7  
**Linked AC**: AC05, AC07, AC08, AC11

GIVEN MCP, plugin, profile, or live-model functionality fails  
WHEN the workflow handles the failure  
THEN mutation remains blocked, diagnostics are recorded without secrets, and no pass is inferred from unavailable evidence.

## Acceptance Criteria

| AC# | Description | Verification Command | Expected Output |
|---|---|---|---|
| AC01 | Two role Profiles with Chinese identity and repository cwd | `sync-hermes-workflow.ps1 -Check` | both profiles valid |
| AC02 | Shared canonical Skill root with no shadowing | `test-hermes-skill-compatibility.ps1` | pass |
| AC03 | Four thin Hermes adapter Skills are compatible | `test-hermes-skill-compatibility.ps1` | pass |
| AC04 | Plan/Implement/Verify bundles resolve | `test-hermes-skill-compatibility.ps1` | pass |
| AC05 | Workflow MCP is typed, bounded, traversal-safe, and delegates gates | `python -m pytest .trae/hermes/tests/test_workflow_mcp.py -q` | pass |
| AC06 | MCP tools are role-specific and Worker cannot own architecture/Verify | MCP tests plus config inspection | pass |
| AC07 | Guard plugin blocks unauthorized mutation and enforces WP paths | `python -m pytest .trae/hermes/tests/test_workflow_guard.py -q` | pass |
| AC08 | Sync is idempotent and preserves user state | integration regression | pass |
| AC09 | Launcher rejects invalid context and resolves valid dry-runs | integration regression | pass |
| AC10 | No inline credential remains; provider rotation is documented | compatibility/security scan | no inline secret |
| AC11 | Deterministic tests pass without live model | all automated test commands | zero failures |
| AC12 | Both Profiles pass doctor and optional Chinese smoke tests are recorded | Hermes doctor commands | no blocking errors |
| AC13 | Operations/security docs and independent Verify evidence exist | doc guard + task Verify gate | pass |

## Quality Checklist

### Completeness

- [x] [OK] Profiles, Skills, MCP, plugin, sync, launch, credentials, documentation, and Verify are covered.
- [x] [OK] Every Scenario has explicit preconditions and observable outcomes.
- [x] [OK] Acceptance Criteria cover all seven Scenarios.

### Clarity

- [x] [OK] Role, task, work package, claim, report, and verification ownership are explicit.
- [x] [OK] External systems and Hermes extension surfaces are identified.
- [x] [OK] Credential rotation is separated into automated and human responsibilities.

### Consistency

- [x] [OK] Terminology matches `Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md`.
- [x] [OK] Repository and runtime ownership follow file-placement conventions.
- [x] [OK] The design does not introduce a competing state machine.

### Scenario Coverage

- [x] [OK] Happy paths: S01, S02, S03.
- [x] [OK] Boundary/error paths: S04, S05, S07.
- [x] [OK] Acceptance path: S06.

### Edge Case Coverage

- [x] [OK] Missing and ambiguous task/WP values are covered.
- [x] [OK] Claim collision and parallel work packages are covered.
- [x] [OK] MCP/plugin/live-model failures are covered.
- [x] [OK] User-owned state preservation and credential absence are covered.

## Implementation Progress

| Task ID | Description | Scenario | Status | Completed |
|---|---|---|---|---|
| T1 | Plan authorization | All | [ ] | — |
| T2 | Profiles, Skills, policy, sync | S01, S02, S05 | [ ] | — |
| T3 | Workflow MCP | S03, S04, S06, S07 | [ ] | — |
| T4 | Guard plugin | S03, S04, S07 | [ ] | — |
| T5 | Launcher and E2E regression | S01, S03, S04, S05, S07 | [ ] | — |
| T6 | Runtime profile verification | S01, S02, S05 | [ ] | — |
| T7 | Independent Review and Verify | S06, S07 | [ ] | — |

## Key Decisions

| Date | Decision | Rationale | Impact |
|---|---|---|---|
| 2026-06-19 | Use shared kernel plus native Hermes adapters | avoids duplicated workflow truth | `.trae` remains authoritative |
| 2026-06-19 | Two Profiles, three role bundles | matches requested two Agents while preserving independent Verify mode | Planner owns Plan and Verify coordination |
| 2026-06-19 | Direct shared Skill discovery with anti-shadow controls | closest to OpenCode sharing without copying content | compatibility test and plugin policy required |
| 2026-06-19 | MCP and launch adapter are hard boundaries; plugin is defense in depth | Hermes hooks may fail without crashing the agent | mutation still fails closed |
| 2026-06-19 | No Hermes core patch | official extension points are sufficient | upstream updates remain viable |

## Change Log

| Date | File | Change Type | Description |
|---|---|---|---|
| 2026-06-19 | `Docs/superpowers/specs/2026-06-19-hermes-workflow-integration-design.md` | Added | approved architecture |
| 2026-06-19 | `Docs/superpowers/plans/2026-06-19-hermes-workflow-integration-plan.md` | Added | implementation plan |
| 2026-06-19 | task packet files | Added | runtime planning and work packages |

## Verification Status

| Check | Status | Detail |
|---|---|---|
| Plan gate | pending | run after packet publication |
| Unit tests | pending | implementation not started |
| Integration tests | pending | implementation not started |
| Hermes doctor | pending | profiles not created |
| Verify gate | pending | implementation not started |

## Non-Goals

- Patch Hermes core.
- Replace `.trae` task state.
- Enable messaging gateways, cron, or unattended approvals.
- Give Workers architecture or final verification authority.
- Copy task truth into Hermes memory.
- Modify application projects.

