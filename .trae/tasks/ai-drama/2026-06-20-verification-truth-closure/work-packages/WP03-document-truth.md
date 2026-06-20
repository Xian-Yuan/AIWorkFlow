# WP03: Task-Packet Truth Reconciliation

Owner model: Codex issuer-direct
Difficulty: medium
Status: done

## Task Packet
- Root: `.trae/tasks/ai-drama/2026-06-20-verification-truth-closure`
- Parent task: `2026-06-20-verification-truth-closure`

## Allowed Paths
- The four active task packets under `.trae/tasks/ai-drama/`
- `Project/AIDramaProducer/Docs/`

## Forbidden Paths
- Checking unfinished original product tasks
- Setting original packet Review, Verify, or Archive states to pass
- Removing original acceptance criteria

## Read First
- `analysis.md`
- `spec.md`
- All four active task `spec.md`, `tasks.md`, and verification reports

## Goal
Make documentation agree with code, tests, and mechanical gates.

## Steps
- Remove approval-override wording.
- Correct disproven AC statements.
- Preserve unfinished original scope.
- Add project implementation/testing records.
- Update the project docs tree.

## Done Definition
- No task document claims that approval can override a failed gate.
- Original packets remain open for their real missing work.
- Project docs describe exactly what this closure changed.

## Required Verification
- Command: `Select-String` scan plus `doc-guard.ps1 check-task`
- Expected: no override wording and documentation governance passes.

## Return Report
- Path: `reports/codex-WP03-result.md`
- Issuer-direct execution records evidence in the final verification report.
