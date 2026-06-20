# Analysis: Hermes Archive Consistency Repair

## Architecture Context

### System boundaries

- This task owns archival metadata, Living Spec truth, final verification narrative, and operations documentation.
- The original Hermes runtime implementation is read-only behaviorally.

### Dependency map

- Original `.task.yaml` is canonical mechanical state.
- Original `spec.md` and `verification-report.md` must describe that state.
- `Docs/AI/39-Hermes-Workflow-Integration.md` is durable operational guidance.
- `test-hermes-archive-consistency.ps1` detects future drift.

### Data and state ownership

- Task phase/results/counters: original `.task.yaml`.
- Scenario and progress narrative: original `spec.md`.
- Evidence summary: original `verification-report.md`.
- User operations: `Docs/AI/39-Hermes-Workflow-Integration.md`.

### Integration points

- `.trae/scripts/task-guard.ps1`
- `.trae/scripts/doc-guard.ps1`
- Existing Hermes test suites and profile doctors.

## Mature Solution Evidence

### Project-local evidence

- The original task is already `phase: archive` and `archived: true`.
- `task-state.ps1 can-edit` correctly blocks edits to archived tasks.
- Existing archive gate checks `archived: true` but does not validate narrative consistency.

### Official/framework evidence

- Repository workflow documents require Living Spec, task state, and verification evidence to remain synchronized.

### External mature references

- Not required: this is a repository-local state consistency hotfix.

### Options compared

| Option | Pros | Cons | Decision |
|---|---|---|---|
| Separate hotfix task | Preserves archived history and obeys gates | Adds a small packet | Selected |
| Reopen original task | Fewer files | Corrupts archive semantics | Rejected |
| Edit without task | Fast | Violates mechanical workflow | Rejected |

### Rejected shortcuts

- Do not directly edit the archived task without a new authorized packet.
- Do not merely silence stale text; add a regression that checks final facts.

### Selected mature path

Use an authorized hotfix packet, repair all four truth surfaces, add a deterministic consistency test, and re-run the complete Hermes verification set.

## Acceptance Criteria

- AC01: Original task state reports archive/pass/pass/true and 7/7 scenarios.
- AC02: Living Spec reports Archive, 13/13 AC, 7/7 scenarios, and completed Review/Verify.
- AC03: Verification report has an authoritative final addendum, records 66/66, and no obsolete stdio risk.
- AC04: Docs/AI/39 reports Archived and the current 23-test Python suite.
- AC05: Archive consistency regression passes.
- AC06: Existing Hermes tests, doctors, sync, documentation, and gates remain green.

## Automated Verification Plan

- Command: `powershell -File .\.trae\scripts\test-hermes-archive-consistency.ps1`
- Expected: all archive consistency checks pass.
- Command: Hermes compatibility, pytest, E2E, sync, doctors, doc guard, and original Verify/Archive gates.
- Expected: 66/66 tests and all structural gates pass.

