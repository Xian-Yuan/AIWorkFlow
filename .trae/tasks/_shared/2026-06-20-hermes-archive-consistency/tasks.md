# Tasks: Hermes Archive Consistency Repair

## Dependency Graph

`T1 Plan → T2 Regression → T3 Repair → T4 Full Verify`

## Plan

- [x] T1.1: Pass Plan gate.
- [x] T1.2: Transition to Implement and pass Can-Edit.

## Regression and Repair

- [x] T2.1: Add archive consistency regression.
- [x] T2.2: Confirm regression detects current stale facts.
- [x] T3.1: Synchronize original YAML scenario counters.
- [x] T3.2: Synchronize original Living Spec final state.
- [x] T3.3: Synchronize original verification report final addendum and evidence.
- [x] T3.4: Synchronize Docs/AI/39 status and test totals.
- [x] T3.5: Pass archive consistency regression.

## Final Verification

- [x] T4.1: Verify selected mature path was implemented and no rejected shortcut was introduced.
- [x] T4.2: Run automated verification and record command output in verification-report.md.
- [x] T4.3: Map implementation result to Acceptance Criteria in verification-report.md.
- [x] T4.4: Run all 66 Hermes tests, sync, doctors, doc guard, and original gates.
