# Tasks: Jinli Runtime Enforcement Layer

## Dependency Graph

```text
WP01 runtime contract/core
  -> WP02 file and workflow route indexes
  -> WP03 integration adapters
  -> WP04 gates and tests
  -> final verification
```

## Task List

- [x] Fix or safely work around `task-state.ps1 init` so new tasks can be initialized without pre-creating directories.
- [x] Implement runtime turn manifest schema and validator.
- [x] Implement response gate for missing evidence, mode rules, and self-attestation rejection.
- [x] Implement file route index generation/checking.
- [x] Implement workflow route index generation/checking.
- [x] Implement adapters for memory, persona, skill routing, task packet state, event bus, dreamer, proactive, and evolution signals.
- [x] Add a `process_turn` or equivalent bridge that proves per-turn usage, not only service availability.
- [x] Add JS/Python bridge evidence or declared degradation for the expression orchestrator path.
- [x] Implement after-turn commit with approved degradation behavior.
- [x] Add deterministic tests for weak-model skipped-step behavior.
- [x] Add worker report normalization tests.
- [x] Strengthen or supplement verification-report section checks so all required sections are present.
- [x] Add Strict/Critical manifest support for issuer-worker evidence artifacts.
- [x] Add script check for stale file/workflow route indexes.
- [x] Document the runtime in `Docs/AI/47-Jinli-Runtime-Enforcement-Layer.md`.
- [x] Verify selected mature path was implemented and no rejected shortcut was introduced.
- [x] Run automated verification and record command output in verification-report.md.
- [x] Map implementation result to Acceptance Criteria in verification-report.md.

## Work Packages

- [x] WP01: Runtime contract and response gate.
- [x] WP02: File route and workflow route auto-maintenance.
- [x] WP03: Existing service adapters and after-turn commit.
- [x] WP04: Tests, regression, and verification report.

## Current Blockers

- (none)