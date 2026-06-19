# Tasks: Jinli Soul Core 1.5 Release Closeout

## Dependency Graph

`T1 -> T2 -> T3 -> T4 -> T5 -> T6`

## T1 — Lock the release boundary

- [x] T1.1: Record current SHA256 values for `soul-core.ps1`, Pester tests, CLI E2E, review script, and every production data file.
- [x] T1.2: Add safety assertions proving verification paths do not target `Project/Jinli/data/` for writes.
- [x] T1.3: Run the safety assertions and record the expected pre-fix failure for `_verify_fixes.ps1`.

## T2 — Remove the unsafe verifier

- [x] T2.1: Change `_verify_fixes.ps1` to require an isolated `JINLI_TEST_ROOT` or delegate to the canonical release verifier.
- [x] T2.2: Remove all hard-coded production data writes from `_verify_fixes.ps1`.
- [x] T2.3: Run the safety assertions and verify AC01/AC02 pass.

## T3 — Make review evidence source-bound and fail-closed

- [x] T3.1: Add explicit isolated root/report parameters to `soul-core-review.ps1` while preserving production defaults.
- [x] T3.2: Add timestamp, actual round, rule count, result, and runtime/test SHA256 fields to the review report.
- [x] T3.3: Create `soul-core-review.tests.ps1` with a valid fixture expected to exit zero.
- [x] T3.4: Add an invalid fixture expected to exit non-zero.
- [x] T3.5: Run review self-tests and verify AC05/AC06 pass.

## T4 — Publish canonical release verification

- [x] T4.1: Create `verify-soul-core-release.ps1` with repository-local temporary roots.
- [x] T4.2: Snapshot production data hashes before verification.
- [x] T4.3: Run the full Pester suite and require zero failures/skips/pending/inconclusive.
- [x] T4.4: Run isolated raw-text CLI E2E and require `E2E PASSED`.
- [x] T4.5: Run review self-tests and production review.
- [x] T4.6: Snapshot production hashes after verification and fail on any difference.
- [x] T4.7: Emit machine-readable evidence containing commands, exits, counts, timestamps, and source hashes.
- [x] T4.8: Run the canonical verifier and verify AC03/AC04/AC07 pass.

## T5 — Synchronize documentation and evidence authority

- [x] T5.1: Create `Project/Jinli/Docs/04-Implementation/General/soul-core-release-repair.md`.
- [x] T5.2: Update `Project/Jinli/Docs/05-Testing/General/soul-core-test-plan.md` to the implemented release suite and commands.
- [x] T5.3: Update `Project/Jinli/Docs/DOCS_TREE.md`.
- [x] T5.4: Mark `Project/Jinli/output/verification-report.md` as historical/non-authoritative without deleting it.
- [x] T5.5: Run document governance and verify AC08 passes.

## T6 — Independent review and mechanical closeout

- [x] T6.1: Verify selected mature path was implemented and no rejected shortcut was introduced.
- [x] T6.2: Run automated verification and record command output in task-root `verification-report.md`.
- [x] T6.3: Map implementation result to Acceptance Criteria in `verification-report.md`.
- [x] T6.4: Verify report source hashes match the current runtime and tests.

## Phase Exit Procedure

After every checkbox above is complete:

1. Run `task-guard.ps1 2026-06-18-jinli-soul-core-1-5-release implement -Apply` to enter Review.
2. Complete independent review and record `review_result=pass` through `task-state.ps1 set`.
3. Run `task-guard.ps1 2026-06-18-jinli-soul-core-1-5-release review -Apply` to enter Verify.
4. Record the task-root report path and `verify_result=pass` through supported `task-state.ps1 set` commands.
5. Run `task-guard.ps1 2026-06-18-jinli-soul-core-1-5-release verify -Apply` to enter Archive.
6. Run `task-state.ps1 transition 2026-06-18-jinli-soul-core-1-5-release archived`.
7. Run `task-guard.ps1 2026-06-18-jinli-soul-core-1-5-release archive` and verify AC09/AC10.
