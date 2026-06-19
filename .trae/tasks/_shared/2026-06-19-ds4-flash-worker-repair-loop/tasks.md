# Tasks: DS4 Flash Worker Repair Loop

## Dependency Graph

```text
T1 tests and fixtures
 -> T2 repair-loop orchestrator
 -> T3 guard and state integration
 -> T4 templates and handoff
 -> T5 docs and indexes
 -> T6 full verification
```

## T1: Regression specification

- [x] T1.1: Add failing Plan-policy and package-contract tests.
- [x] T1.2: Add failing first/second/third failure-loop tests.
- [x] T1.3: Add failing immutable-evidence and scope-narrowing tests.
- [x] T1.4: Add failing verifier-independence and worker-authority tests.
- [x] T1.5: Run the new suite and record expected RED failures.

## T2: Repair-loop orchestration

- [x] T2.1: Add `worker-repair-loop.ps1` task resolution and initialization.
- [x] T2.2: Add per-root-cause counters and immutable evidence.
- [x] T2.3: Add Rxx task append and unique WPxx repair package generation.
- [x] T2.4: Add scope subset validation and idempotence checks.
- [x] T2.5: Add third-failure architecture-review circuit breaker.
- [x] T2.6: Add root-cause resolve and status commands.

## T3: State and gate integration

- [x] T3.1: Add repair fields to task-state initialization and allowed fields.
- [x] T3.2: Require DS4 failures to use the repair-loop command.
- [x] T3.3: Enforce DS4 Worker Repair Policy at Plan.
- [x] T3.4: Enforce DS4 package/report authority and pending-repair state at Implement.
- [x] T3.5: Enforce independent verifier evidence at Review and Verify.
- [x] T3.6: Preserve legacy task behavior.

## T4: Templates and handoff

- [x] T4.1: Upgrade work-package template with DS4-specific bounded context sections.
- [x] T4.2: Upgrade worker-result template with authority declarations.
- [x] T4.3: Upgrade verification template with worker/verifier context identity.
- [x] T4.4: Add repair-state and repair-evidence templates.
- [x] T4.5: Make Plan-to-Implement handoff select and publish DS4 packages instead of broad task instructions.

## T5: Documentation

- [x] T5.1: Add `Docs/AI/40-DS4-Flash-Worker-Repair-Loop.md`.
- [x] T5.2: Update Docs 24 and 33.
- [x] T5.3: Update Docs 27 active component inventory.
- [x] T5.4: Update `Docs/AI/README.md`, `.cache-manifest.md`, and `AGENTS.md`.

## T6: Final Verification

- [x] Verify selected mature path was implemented and no rejected shortcut was introduced.
- [x] Run automated verification and record command output in verification-report.md.
- [x] Map implementation result to Acceptance Criteria in verification-report.md.
- [x] Run parser checks for all modified PowerShell files.
- [x] Run `test-worker-repair-loop.ps1`.
- [x] Run `test-workflow-regression.ps1`.
- [x] Run `test-doc-guard.ps1`.
- [x] Run task guard through Implement, Review, and Verify with independent evidence.
