# Spec: DS4 Flash Worker Repair Loop

## GIVEN

The shared workflow can delegate work through packages and independently verify reports, but failed verification does not automatically update the task packet or produce a narrower DS4 Flash repair assignment.

## WHEN

The DS4 Flash Worker Repair Loop is enabled for a task through its routing policy.

## THEN

### S01: DS4 policy is mandatory

**Status**: [x]

A DS4 task cannot leave Plan without a lead/verifier, fresh-context rule, maximum same-root attempts, automatic repair policy, and required worker reports.

### S02: Initial package is Flash-optimized

**Status**: [x]

The worker receives only bounded read-first files, allowed paths, forbidden paths, one goal, exact commands, expected output, stop conditions, and a unique report path.

### S03: Worker cannot game acceptance

**Status**: [x]

The package forbids weakening tests, acceptance criteria, task state, verification evidence, or architecture to obtain a passing result.

### S04: First failure republishes work

**Status**: [x]

The first independent failure for RC01 creates A001 evidence, increments attempts, returns to Implement, appends R01, and creates one RC01 repair package.

### S05: Repair scope narrows

**Status**: [x]

A later RC01 repair package may use the same or fewer paths but cannot add paths and must reference the newest exact failure.

### S06: Third failure trips the circuit breaker

**Status**: [x]

The third RC01 failure creates evidence, sets architecture review, and does not create another repair package.

### S07: Root causes are isolated

**Status**: [x]

RC01 and RC02 maintain separate consecutive attempt counts and repair packages.

### S08: Failure history is immutable

**Status**: [x]

Each attempt receives a unique evidence file, and later attempts do not rewrite earlier files.

### S09: Worker authority is bounded

**Status**: [x]

Worker reports that claim Review pass, Verify pass, archive authority, extra scope, or forbidden-path edits are rejected.

### S10: Independent verification is required

**Status**: [x]

Codex verification is accepted when evidence is independently rerun. DS4 verification is accepted only from a declared fresh context when no stronger verifier is available.

### S11: Repair resolution clears active state

**Status**: [x]

After independent verification resolves a root cause, active repair state is cleared while history and counters remain auditable.

### S12: Existing tasks remain compatible

**Status**: [x]

Tasks without `Worker profile: ds4-flash` retain their current package, report, state, and gate behavior.

## Acceptance Criteria

| AC# | Description | Verification Command | Expected Output |
|---|---|---|---|
| AC01 | DS4 Plan policy enforced | `test-worker-repair-loop.ps1` | Missing policy blocked |
| AC02 | Flash package contract enforced | `test-worker-repair-loop.ps1` | Weak package blocked |
| AC03 | First failure creates full repair artifacts | `test-worker-repair-loop.ps1` | A001, R01, WP fix exist |
| AC04 | Scope expansion blocked | `test-worker-repair-loop.ps1` | Added path rejected |
| AC05 | Third same-root failure stops redistribution | `test-worker-repair-loop.ps1` | architecture_review, no new WP |
| AC06 | Root-cause counters independent | `test-worker-repair-loop.ps1` | RC01 and RC02 counts differ correctly |
| AC07 | Evidence files immutable | `test-worker-repair-loop.ps1` | Earlier hash unchanged |
| AC08 | Worker authority claims blocked | `test-worker-repair-loop.ps1` | Invalid report rejected |
| AC09 | Same-context Flash verification blocked | `test-worker-repair-loop.ps1` | Verify gate nonzero |
| AC10 | Fresh-context fallback supported | `test-worker-repair-loop.ps1` | Explicit fallback accepted |
| AC11 | Codex independent verification supported | `test-worker-repair-loop.ps1` | Verify gate passes |
| AC12 | Legacy task compatibility preserved | `test-workflow-regression.ps1` | Existing scenarios pass |
| AC13 | Docs and scripts remain valid | parser, doc guard, workflow regression | All exit 0 |

## Progress Summary

| Phase | Status | Key Decision |
|---|---|---|
| Plan | Complete | Per-root repair state plus immutable evidence |
| Implement | Complete | TDD suite passes 18 scenarios |
| Review | Complete | Codex code review added path, evidence, and consecutive-counter hardening |
| Verify | Complete | Parser, focused, full workflow, and doc-guard suites pass |

## Non-Goals

- Calling DS4 automatically through an API.
- Allowing Flash to own architecture or final acceptance.
- Retrying more than one root cause in a package.
- Replacing existing phases or task roots.
