# Spec: Hermes Archive Consistency Repair

## GIVEN

The Hermes Workflow Integration implementation and tests are complete, but its archived task state disagrees with its Living Spec, verification addendum, scenario counters, and operations document.

## WHEN

The archive consistency hotfix synchronizes those facts and adds a deterministic regression.

## THEN

### S01: Final archive truth

**Status**: [x] verified

All canonical and narrative state surfaces report the same completed archive state.

### S02: Regression protection

**Status**: [x] verified

The consistency test fails on stale phase, counters, evidence totals, or stdio-risk text and passes on the repaired packet.

## Acceptance Criteria

| AC# | Description | Verification Command | Expected Output |
|---|---|---|---|
| AC01 | Original YAML is archive/pass/pass/true and 7/7 | consistency test | pass |
| AC02 | Living Spec is fully archived | consistency test | pass |
| AC03 | Verification report records final 66/66 | consistency test | pass |
| AC04 | Operations doc is current | consistency test | pass |
| AC05 | Regression passes | consistency test | all pass |
| AC06 | Existing behavior remains green | full Hermes verification | 66/66 |

## Quality Checklist

- [x] [OK] Scope is limited to archive truth and its regression.
- [x] [OK] Both happy and stale-state failure paths are defined.
- [x] [OK] No Hermes runtime behavior is changed.

## Progress Summary

| Phase | Status | Key Decision |
|---|---|---|
| Plan | Complete | Separate hotfix preserves archive history |
| Implement | Complete | Four truth surfaces and secret evidence repaired |
| Review | Complete | Diff and architecture boundaries reviewed |
| Verify | Complete | 66/66 plus 20/20 consistency checks passed |

## Non-Goals

- Runtime behavior changes.
- Credential provisioning or rotation.
- Git publishing.
