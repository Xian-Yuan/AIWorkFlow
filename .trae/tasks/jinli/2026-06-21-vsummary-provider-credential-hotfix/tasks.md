# Tasks: vsummary Provider Credential Hotfix

## Dependency Graph

```text
Regression tests -> boundary validation -> credential recovery -> backend restart -> live API verification -> documentation
```

## Test-Driven Repair
- [x] T1.1: Add failing tests for non-ASCII and placeholder provider credentials.
- [x] T1.2: Run the focused tests and record the expected RED failure.
- [x] T1.3: Implement minimal provider credential validation.
- [x] T1.4: Run focused and related settings tests to GREEN.

## Runtime Recovery
- [x] T2.1: Restore the locally available provider credential without printing it.
- [x] T2.2: Sanitize hard-coded credentials from diagnostic scripts without deleting the scripts.
- [x] T2.3: Restart or refresh the backend provider runtime.
- [x] T2.4: Verify the restored credential reaches the provider path without the encoding failure.
- [x] T2.5: Verify the original video generate endpoint and read the completed summary.

## Documentation
- [x] T3.1: Add Jinli operations guidance for credential validation and recovery.
- [x] T3.2: Update `Project/Jinli/Docs/DOCS_TREE.md`.

## Final Verification
- [x] Verify selected mature path was implemented and no rejected shortcut was introduced.
- [x] Run automated verification and record command output in `verification-report.md`.
- [x] Map implementation result to Acceptance Criteria in `verification-report.md`.
