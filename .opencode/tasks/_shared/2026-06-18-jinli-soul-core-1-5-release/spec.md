# Spec: Jinli Soul Core 1.5 Release Closeout

## GIVEN

- Core behavior currently passes 18 Pester assertions and the isolated raw-text CLI E2E.
- The previous release claim is not authoritative because task state, task checklist, documentation, report freshness, and verify guard do not agree.
- `_verify_fixes.ps1` still contains direct production-data writes.
- Review evidence is not bound to the reviewed source hashes and has no executable fail-path self-test.

## WHEN

The existing task packet is repaired in place using the approved release-closeout design.

## THEN

### S01 Verification Isolation

**Status**: [x]

- Every mutating test uses a unique root below `E:\UEGameDevelopment\.tmp\`.
- Production Soul data is read only for before/after hashing.
- `_verify_fixes.ps1` cannot write to `Project/Jinli/data/`.

### S02 Full Behavioral Regression

**Status**: [x]

- The complete Pester suite runs with exit-code propagation.
- Failed, skipped, pending, and inconclusive counts are all zero.
- Existing Soul Core behavior is not redesigned during release closeout.

### S03 Raw-Text CLI E2E

**Status**: [x]

- The isolated E2E exercises init, raw-text classification, repeated ignored advice, acknowledgement, feedback learning, and session end across subprocess boundaries.
- The command exits zero and prints `E2E PASSED`.

### S04 Source-Bound Review Evidence

**Status**: [x]

- The review report records timestamp, actual round, rule count, result, and SHA256 for runtime and test sources.
- Report hashes match the files present when final verification runs.

### S05 Review Fail-Closed Self-Test

**Status**: [x]

- Review can run against an isolated fixture and report path.
- A valid fixture exits zero.
- A deliberately invalid fixture exits non-zero.
- The self-test itself exits non-zero if either expectation is violated.

### S06 Canonical Release Verifier

**Status**: [x]

- `verify-soul-core-release.ps1` runs the full test/review sequence.
- It captures command exit codes and source hashes in machine-readable evidence.
- It fails immediately on missing evidence, command failure, malformed output, stale hash, or production-data mutation.
- It never changes task state.

### S07 Documentation Synchronization

**Status**: [x]

- The implementation document describes runtime boundaries, test isolation, review evidence, and release commands.
- The testing document reflects the actual automated suite instead of “design stage”.
- `DOCS_TREE.md` indexes the implementation document and records the closeout update.

### S08 Verification Report Authority

**Status**: [x]

- The authoritative report is task-root `verification-report.md`.
- It contains `Automated Verification`, `Acceptance Criteria`, `Architecture Compliance`, `Test Evidence`, and `Residual Risk`.
- The legacy output report is marked historical and cannot be mistaken for current acceptance.

### S09 Mechanical State Completion

**Status**: [x]

- All implementation tasks are checked only after their evidence exists.
- Implement and Review gates pass before Verify.
- Verify passes only with a current task-root report and `verify_result: pass`.
- Archive is reached through state-machine transitions, not direct YAML edits.

## Acceptance Criteria

| AC# | Description | Verification Command | Expected Output |
|-----|-------------|---------------------|-----------------|
| AC01 | Mutating verification is isolated below repository `.tmp` | release verifier + production hash comparison | exit 0; identical before/after hashes |
| AC02 | `_verify_fixes.ps1` has no production write path | Pester/static safety assertion | PASS |
| AC03 | Complete behavior suite passes | `Invoke-Pester ... -EnableExit` | zero failures/skips/pending/inconclusive |
| AC04 | Raw-text CLI E2E passes | `test-soul-core-e2e.ps1` | exit 0; `E2E PASSED` |
| AC05 | Review report is source-bound | production review + hash comparison | current matching SHA256 values |
| AC06 | Review is demonstrably fail-closed | `soul-core-review.tests.ps1` | valid fixture 0; invalid fixture non-zero |
| AC07 | Production Soul data is unchanged | release verifier | all file hashes unchanged |
| AC08 | Project documentation is current | `doc-guard.ps1 ... implement` | documentation governance passes |
| AC09 | Task-root report is complete and fresh | report section/hash validation | all required sections and matching hashes |
| AC10 | Mechanical workflow closes normally | task guards and state transitions | Implement, Review, Verify, Archive pass |

## Progress Summary

| Phase | Status | Key Decision |
|-------|--------|-------------|
| Plan revision | Approved | Repair original task packet in place |
| Implement | Pending closeout work | Preserve working runtime behavior |
| Review | Pending | Require source-bound pass/fail evidence |
| Verify | Pending | Independent report and mechanical gates are authoritative |

## Non-Goals

- New Soul Core features or emotional behavior
- Voice, visual avatar, or game control
- Memory backend migration
- Deleting historical evidence
- Refactoring unrelated workflow infrastructure
