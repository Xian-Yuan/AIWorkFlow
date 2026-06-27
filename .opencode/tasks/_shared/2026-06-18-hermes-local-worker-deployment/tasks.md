# Tasks: Hermes Local Worker Deployment

## Dependency Graph

```text
T1 Plan gate
  -> T2 Preflight and preserve existing state
    -> T3 Install workspace-local Hermes
      -> T4 Configure bounded Worker profile
        -> T5 Implement adapter tests
          -> T6 Implement adapter
            -> T7 Installation and context smoke tests
              -> T8 Worker report
                -> T9 Lead review
                  -> T10 Final verification
```

## Plan authorization

- [ ] T1.1: Run `task-guard.ps1 _shared/2026-06-18-hermes-local-worker-deployment plan`.
- [ ] T1.2: Transition the task to Implement using the authoritative task-state script.
- [ ] T1.3: Run `task-state.ps1 can-edit _shared/2026-06-18-hermes-local-worker-deployment`.

## Preflight

- [ ] T2.1: Record whether `%LOCALAPPDATA%\hermes` already exists without deleting or modifying it.
- [ ] T2.2: Confirm `.tools/` and `.tmp/` are ignored and available.
- [ ] T2.3: Record the selected official Hermes release tag or commit and installer SHA.

## Installation

- [ ] T3.1: Download the official Windows installer to `.tmp/hermes-install/install.ps1`.
- [ ] T3.2: Install with explicit `HermesHome` and `InstallDir` under `.tools/hermes-worker`.
- [ ] T3.3: Confirm Hermes binaries, managed environment, and configuration files remain inside the approved home.

## Configuration

- [ ] T4.1: Configure repository-root working directory, manual approvals, secret redaction, and flat delegation.
- [ ] T4.2: Confirm gateway, cron, and autonomous orchestration are not enabled.
- [ ] T4.3: Keep secrets out of task documents, logs, and reports.

## Adapter regression tests

- [ ] T5.1: Create `.trae/scripts/test-invoke-hermes-worker.ps1`.
- [ ] T5.2: Add failed-Plan-gate coverage.
- [ ] T5.3: Add failed-Can-Edit coverage.
- [ ] T5.4: Add missing and ambiguous work-package coverage.
- [ ] T5.5: Add valid dry-run coverage.
- [ ] T5.6: Run the tests and confirm they fail before adapter implementation.

## Adapter implementation

- [ ] T6.1: Create `.trae/scripts/invoke-hermes-worker.ps1`.
- [ ] T6.2: Resolve exactly one task packet and exactly one work package.
- [ ] T6.3: Require Plan and Can-Edit gates before mutating execution.
- [ ] T6.4: Require concrete claim and report paths.
- [ ] T6.5: Provide a dry-run mode that prints the resolved invocation without launching Hermes.
- [ ] T6.6: Run the adapter regression tests and confirm they pass.

## Smoke verification

- [ ] T7.1: Run the managed `hermes --version`.
- [ ] T7.2: Run the managed `hermes doctor`.
- [ ] T7.3: From the repository root, ask Hermes to identify the Implement gates without modifying files.
- [ ] T7.4: Confirm no new task-owned Hermes home was created under `%LOCALAPPDATA%`.

## Worker evidence

- [ ] T8.1: Create `claims/hermes-WP01.md` before edits.
- [ ] T8.2: Write `reports/hermes-WP01-result.md` with commands, results, AC mapping, scope control, and risks.
- [ ] T8.3: Declare `Status: done` only if all required worker checks pass.
- [ ] T8.4: Declare `Extra scope taken: no`.

## Lead review

- [ ] T9.1: Review every changed path against Allowed and Forbidden Paths.
- [ ] T9.2: Independently rerun adapter tests.
- [ ] T9.3: Independently inspect configuration and installation location.
- [ ] T9.4: Verify selected mature path was implemented and no rejected shortcut was introduced.

## Final Verification

- [ ] T10.1: Run automated verification and record command output in `verification-report.md`.
- [ ] T10.2: Map implementation result to Acceptance Criteria in `verification-report.md`.
- [ ] T10.3: Run `task-guard.ps1 _shared/2026-06-18-hermes-local-worker-deployment verify`.
