# Jinli Soul Core 1.5 Release Closeout Design

Date: 2026-06-18  
Status: Approved  
Task packet: `.trae/tasks/_shared/2026-06-18-jinli-soul-core-1-5-release/`

## Goal

Close the gap between the working Soul Core fixes and a mechanically valid 1.5 release. The release is accepted only when isolated tests, review evidence, documentation, task state, and the authoritative verification report all describe the same source revision.

## Selected Approach

Repair the existing task packet in place.

This preserves the failed acceptance history and avoids creating two competing Soul Core 1.5 release tasks. The existing task remains the sole authority. No task-state field may be hand-edited to manufacture completion.

## Alternatives Considered

| Approach | Benefit | Cost | Decision |
|---|---|---|---|
| Repair the existing task packet | Preserves history and one authority chain | Requires careful reconciliation of stale evidence | Selected |
| Create a new closeout task | Clean task state | Splits one release across two authorities | Rejected |
| Patch only task state and reports | Smallest change | Leaves unsafe verification and AC07 unproven | Rejected |

## Architecture

### Runtime behavior

`Project/Jinli/scripts/soul-core.ps1` remains the Soul Core runtime authority. The closeout must not redesign emotion, memory, or relationship behavior unless a new regression test demonstrates that an acceptance criterion is still failing.

### Test isolation

All mutating verification runs under a unique root below `E:\UEGameDevelopment\.tmp\` through `JINLI_TEST_ROOT` or explicit test-root parameters.

`Project/Jinli/scripts/_verify_fixes.ps1` must no longer write to `Project/Jinli/data/`. It becomes an isolated compatibility verifier or a thin wrapper around the canonical release verifier.

### Review evidence

`soul-core-review.ps1` must produce evidence tied to the reviewed source:

- actual review round;
- UTC timestamp;
- SHA256 of `soul-core.ps1`;
- SHA256 of `soul-core.tests.ps1`;
- SHA256 of `test-soul-core-e2e.ps1`;
- rule count and result;
- non-zero exit whenever any rule fails.

The review script must accept an isolated review root/report path so fail-closed behavior can be tested without damaging production files.

### Release verification

A canonical `verify-soul-core-release.ps1` orchestrates evidence collection:

1. hash every production file under `Project/Jinli/data/`;
2. run the full Pester suite;
3. run raw-text CLI E2E;
4. run review-script self-tests for both pass and fail paths;
5. run the production review;
6. hash production data again and require an exact match;
7. emit machine-readable evidence with command exit codes and source hashes.

This script does not transition task state and does not declare the task archived.

### Final authority

The independent verifier writes:

`.trae/tasks/_shared/2026-06-18-jinli-soul-core-1-5-release/verification-report.md`

The report must use current source hashes and map every acceptance criterion to fresh command evidence. Only then may the normal state transitions reach archive.

## Data Flow

```text
source + tests
    -> isolated verification commands
    -> release evidence JSON/log
    -> independent AC mapping
    -> task-root verification-report.md
    -> task-guard verify
    -> task-state verify-pass
    -> archive
```

Production Soul data is an observed invariant, never a test fixture.

## Error Handling

- Any test or review subprocess with a non-zero exit stops release verification.
- Missing hashes, missing expected output, or malformed evidence are failures.
- A changed production-data hash is a release blocker even if tests pass.
- A verification report whose source hashes do not match current files is stale and invalid.
- The legacy output report must be clearly marked historical and cannot satisfy the task guard.

## Documentation

The implementation must create or update:

- `Project/Jinli/Docs/04-Implementation/General/soul-core-release-repair.md`
- `Project/Jinli/Docs/05-Testing/General/soul-core-test-plan.md`
- `Project/Jinli/Docs/DOCS_TREE.md`

## Non-Goals

- New emotion model behavior
- Voice or avatar features
- Vector memory migration
- Sprint 2 feature expansion
- Deleting historical reports

## Acceptance Summary

The closeout is complete only when:

- mutating tests are isolated;
- the full behavior suite and CLI E2E pass;
- review fail-closed behavior is tested;
- review evidence is source-bound;
- production-data hashes remain unchanged;
- project documentation is current;
- the task-root verification report is fresh and complete;
- Implement, Review, Verify, and Archive gates pass through the state machine.
