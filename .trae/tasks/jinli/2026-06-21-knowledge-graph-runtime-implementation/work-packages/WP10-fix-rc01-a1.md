# WP10: Fix RC01 attempt 1

Owner model: deepseek-v4-flash
Difficulty: focused
Status: unclaimed
Target model: deepseek-v4-flash
Fresh context required: yes

## Worker Profile
- Profile: ds4-flash
- Role: implementation worker
- Review authority: none
- Verify authority: none

## Context Budget
- Read only this package and the Read First list.
- Do not re-read the complete task packet or repository.
- Import architecture decisions; do not reinterpret them.

## Root Cause Boundary
- Root Cause ID: RC01
- Attempt: 1
- Failure evidence: verification-history/A001-review-rc01.md
- Summary: WP01 runtime foundation does not satisfy path containment and full schema contract
- Previous repair package: none; first repair for this root cause
- Scope rule: this package handles only RC01 and may not expand allowed paths.

## Task Packet
- Root: .trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation/
- Parent task: 2026-06-21-knowledge-graph-runtime-implementation

## Allowed Paths
- Project/Jinli/services/knowledge/config.py
- Project/Jinli/services/knowledge/contracts.py
- Project/Jinli/services/knowledge/tests/test_config.py
- Project/Jinli/services/knowledge/tests/test_contracts.py
- Project/Jinli/data/knowledge/schemas

## Forbidden Paths
- tests or fixtures unless explicitly listed in Allowed Paths
- acceptance criteria and specification files
- .task.yaml
- repair-state.json
- verification-report.md
- verification-history/

## Read First
- .trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation/work-packages/WP01-runtime-foundation.md
- .trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation/verification-history/A001-review-rc01.md
- Project/Jinli/services/knowledge/config.py
- Project/Jinli/services/knowledge/contracts.py
- Project/Jinli/services/knowledge/tests/test_config.py
- Project/Jinli/services/knowledge/tests/test_contracts.py
- verification-history/A001-review-rc01.md

## Goal
- Fix the bounded root cause described above without changing architecture or acceptance.

## Steps
- [ ] Reproduce: python -m pytest Project/Jinli/services/knowledge/tests/test_config.py Project/Jinli/services/knowledge/tests/test_contracts.py Project/Jinli/services/knowledge/tests/test_io_utils.py -q plus independent schema/path spot-check
- [ ] Confirm actual failure: 95 pytest tests pass, but path_contained accepts E:/ObsidianVault_evil as inside E:/ObsidianVault and schemas transcript-entry, graph-candidate, graph-node, graph-edge, evidence-record are missing
- [ ] Modify only Allowed Paths.
- [ ] Re-run the exact command until it produces: WP01 tests pass and independent spot-check rejects sibling-prefix path escapes and finds all required WP01 schemas
- [ ] Write the required worker report.

## Done Definition
- python -m pytest Project/Jinli/services/knowledge/tests/test_config.py Project/Jinli/services/knowledge/tests/test_contracts.py Project/Jinli/services/knowledge/tests/test_io_utils.py -q plus independent schema/path spot-check returns the expected result.
- No forbidden path, test weakening, acceptance change, or extra scope occurred.

## Required Verification
- Command: python -m pytest Project/Jinli/services/knowledge/tests/test_config.py Project/Jinli/services/knowledge/tests/test_contracts.py Project/Jinli/services/knowledge/tests/test_io_utils.py -q plus independent schema/path spot-check
- Expected: WP01 tests pass and independent spot-check rejects sibling-prefix path escapes and finds all required WP01 schemas

## Do Not Game The Gate
- Do not modify tests to hide the failure.
- Do not weaken acceptance criteria or expected output.
- Do not change task state, Review result, Verify result, or verification evidence.
- Do not introduce a workaround outside the selected architecture.

## Stop Conditions
- Stop if the fix requires a path outside Allowed Paths.
- Stop if the evidence identifies a different root cause.
- Return Status: blocked with the smallest concrete blocker.

## Return Report
- Path: reports/ds4-flash-WP10-result.md
- Required status for merge: done
- Must include changed files, raw command result, acceptance criteria touched, authority declarations, residual risk, and Extra scope taken: no.
