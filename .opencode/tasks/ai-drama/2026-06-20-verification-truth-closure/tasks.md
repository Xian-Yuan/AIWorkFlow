# Tasks: AIDramaProducer Verification Truth Closure

## Dependency Graph
```text
WP01 ─┐
      ├─ WP03 ─ WP04
WP02 ─┘
```

## WP01 Character ID Contract
- [x] T1.1 Add a regression test requiring mapped character names to return `known_ids`.
- [x] T1.2 Run the regression test and record the expected failure.
- [x] T1.3 Implement mapped-ID output while preserving regex fallback mode.
- [x] T1.4 Run all text-preprocessor tests.

## WP02 Test Entry and Injection Chain
- [x] T2.1 Add canonical pytest discovery configuration and verify root pytest no longer collects runtime `.txt` inputs.
- [x] T2.2 Add failing tests for injection-bundle validation and sibling-file loading.
- [x] T2.3 Add failing tests proving Step 1/2/3 receive injected prompt context.
- [x] T2.4 Implement the Scriptwriter injection loader and prompt propagation.
- [x] T2.5 Add `--style-injection` to Scriptwriter and correct the Viral Analyzer command.
- [x] T2.6 Add failing Orchestrator pass-through coverage.
- [x] T2.7 Implement Orchestrator injection-path pass-through.
- [x] T2.8 Run focused Scriptwriter, Viral Analyzer, and Orchestrator tests.

## WP03 Documentation Truth Reconciliation
- [x] T3.1 Update the 2026-06-19 repair spec/tasks/report/audit to remove approval-override language.
- [x] T3.2 Correct AC03, AC06, AC08, AC09, and AC10 evidence statements.
- [x] T3.3 Keep original product packets in Implement with their unfinished tasks intact.
- [x] T3.4 Update AIDramaProducer implementation/testing docs and `DOCS_TREE.md`.

## WP04 Final Verification
- [x] T4.1 Verify selected mature path was implemented and no rejected shortcut was introduced.
- [x] T4.2 Run automated verification and record command output in `verification-report.md`.
- [x] T4.3 Map implementation result to Acceptance Criteria in `verification-report.md`.
- [x] T4.4 Run new-packet Implement gate and reseal the issuer packet.
- [x] T4.5 Obtain fresh-context independent verification.
- [x] T4.6 Confirm Verify and Archive are separate issuer operations and record the post-review commands.
