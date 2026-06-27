# Analysis: Jinli Soul Core 1.5 Release Closeout

## Architecture Context

### System boundaries
- `soul-core.ps1` owns deterministic emotion, relationship, memory, and CLI behavior.
- Pester and CLI E2E own behavioral regression evidence.
- `soul-core-review.ps1` owns source-bound structural review evidence.
- `verify-soul-core-release.ps1` owns deterministic evidence orchestration, not final acceptance.
- The task-root `verification-report.md` and authoritative task scripts own release-state truth.

### Dependency map
- Runtime source + tests -> source hash manifest
- Isolated fixtures -> Pester + CLI E2E -> command evidence
- Review fixture -> pass/fail self-test -> fail-closed evidence
- Production source -> review report with matching hashes
- Production data before/after hashes -> isolation invariant
- Evidence -> independent AC mapping -> task-root report -> task guard

### Data and state ownership
- Production runtime state is owned by `Project/Jinli/data/` and is read-only during release verification.
- Test state is owned by a unique directory below `E:\UEGameDevelopment\.tmp\`.
- Release evidence is owned by the task packet or `Project/Jinli/output/` machine-evidence files.
- Final acceptance is owned only by the independent verifier and task state machine.

### Integration points
- PowerShell/Pester provides the assertion runner.
- CLI subprocesses provide cross-process E2E boundaries.
- `task-state.ps1`, `task-guard.ps1`, and `doc-guard.ps1` provide mechanical release gates.
- Project docs and `DOCS_TREE.md` provide durable release documentation.

## Acceptance Failure Findings
- The previous completion claim contradicted `.task.yaml`, which remained in Implement with pending review and verification.
- Every item in `tasks.md` remained unchecked, so Implement and Verify guards correctly failed.
- The old verification report predates the final source and states that automatic triggering and task verification were not complete.
- `_verify_fixes.ps1` directly mutates production Soul data.
- Review output lacks source hashes and does not prove its non-zero fail path through an isolated self-test.
- The required implementation document is missing, the testing document is stale, and `DOCS_TREE.md` has no release-closeout entry.

## Mature Solution Evidence

### Project-local evidence
- Fresh independent execution passed 18/18 Pester tests and the raw-text CLI E2E.
- Fresh production-data hashes remained unchanged across those isolated runs.
- `task-guard.ps1 verify` failed because tasks, report authority, and task state were incomplete.
- The current output report explicitly records automatic E2E and verify as unfinished.

### Official/framework evidence
- Pester supports assertion-based tests and exit-code propagation.
- PowerShell supports explicit script parameters, process-scoped environment variables, SHA256 hashing, and subprocess exit-code checks.
- The authoritative project workflow requires fresh automated evidence and a task-root verification report before completion.

### External mature references
- Mature release pipelines bind evidence to immutable source identifiers and separate evidence generation from final acceptance.
- Fail-closed verification treats missing or stale evidence as failure.

### Options compared
| Option | Pros | Cons | Decision |
|---|---|---|---|
| Repair existing task packet in place | One authority chain, preserves failure history | Must reconcile stale evidence carefully | Selected |
| Create a second closeout task | Clean phase state | Splits one release across two task authorities | Rejected |
| Update only YAML and report text | Fast | Does not prove isolation or fail-closed review | Rejected |

### Rejected shortcuts
- Do not accept the historical output report as current evidence.
- Do not use production `data/` as a mutable test fixture.
- Do not infer review fail-closed behavior from source inspection alone.
- Do not directly set task state to pass/archive.
- Do not expand into new Soul Core features during closeout.

### Selected mature path
- Preserve the working runtime behavior.
- Remove the unsafe production-mutating verification path.
- Add a canonical release verifier that collects fresh, source-bound, isolated evidence.
- Test both the passing and failing review paths.
- Publish current implementation/testing documentation.
- Require independent AC mapping and normal task-state transitions.

## Acceptance Criteria
- AC01: Every mutating verification command uses an isolated test root below `E:\UEGameDevelopment\.tmp\`.
- AC02: `_verify_fixes.ps1` contains no production-data write path and refuses unsafe execution.
- AC03: Full Pester execution reports zero failed, skipped, pending, or inconclusive tests.
- AC04: Raw-text CLI E2E exits zero and prints `E2E PASSED`.
- AC05: Review evidence includes current source/test SHA256 values, actual round, timestamp, rule count, and result.
- AC06: An isolated review self-test proves a valid fixture exits zero and an invalid fixture exits non-zero.
- AC07: Production data hashes are identical before and after all verification.
- AC08: Implementation docs, test docs, and `DOCS_TREE.md` describe the final release process.
- AC09: The task-root verification report maps fresh evidence to every AC and contains all required sections.
- AC10: Implement, Review, Verify, and Archive gates pass through `task-state.ps1` and `task-guard.ps1` without direct YAML manipulation.

## Automated Verification Plan
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Pester -Script 'Project/Jinli/scripts/soul-core.tests.ps1' -PassThru -EnableExit"`
- Expected: exit 0; all tests pass; zero failed/skipped/pending/inconclusive.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File Project/Jinli/scripts/test-soul-core-e2e.ps1`
- Expected: exit 0 and `E2E PASSED`.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File Project/Jinli/scripts/soul-core-review.tests.ps1`
- Expected: exit 0 after proving both review pass and fail exit paths.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File Project/Jinli/scripts/verify-soul-core-release.ps1`
- Expected: exit 0, production hashes unchanged, machine evidence generated with current source hashes.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/task-guard.ps1 2026-06-18-jinli-soul-core-1-5-release implement`
- Expected: exit 0 after implementation tasks and docs are complete.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/task-guard.ps1 2026-06-18-jinli-soul-core-1-5-release verify`
- Expected: exit 0 only after independent verification and task-root report publication.

## Allowed Change Set
- `Project/Jinli/scripts/_verify_fixes.ps1`
- `Project/Jinli/scripts/soul-core-review.ps1`
- `Project/Jinli/scripts/soul-core-review.tests.ps1`
- `Project/Jinli/scripts/verify-soul-core-release.ps1`
- `Project/Jinli/scripts/soul-core.tests.ps1` only for missing acceptance assertions
- `Project/Jinli/scripts/test-soul-core-e2e.ps1` only for isolation/evidence corrections
- `Project/Jinli/Docs/04-Implementation/General/soul-core-release-repair.md`
- `Project/Jinli/Docs/05-Testing/General/soul-core-test-plan.md`
- `Project/Jinli/Docs/DOCS_TREE.md`
- `Project/Jinli/output/verification-report.md` only to mark it historical
- This task packet

## Forbidden Change Set
- Runtime behavior changes without a failing regression test
- Mutating `Project/Jinli/data/` during verification
- Direct `.task.yaml` pass/archive edits
- Unrelated project or workflow refactors
