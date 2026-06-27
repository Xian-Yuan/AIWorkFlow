# WP02: Ledger and Legacy Reconciliation

Owner model: unclaimed
Difficulty: high
Status: unclaimed
Target model: deepseek-v4-flash
Fresh context required: yes

## Worker Profile

- Profile: ds4-flash
- Role: implementation worker
- Review authority: none
- Verify authority: none

## Context Budget

- Read this package, parent truth sources, WP01 public contracts, and current download-progress formats.
- Do not redesign the knowledge graph.

## Root Cause Boundary

- Root Cause ID: BILI-AUTO-WP02
- This package owns transactional stage state, revision identity, retry state, and reconciliation planning.

## Task Packet

- Root: `.trae/tasks/jinli/2026-06-21-bilibili-favorites-knowledge-automation`
- Parent task: `2026-06-21-bilibili-favorites-knowledge-automation`

## Allowed Paths

- `Project/Jinli/services/knowledge/automation/__init__.py`
- `Project/Jinli/services/knowledge/automation/ledger.py`
- `Project/Jinli/services/knowledge/automation/reconcile.py`
- `Project/Jinli/services/knowledge/tests/test_automation_ledger.py`
- `Project/Jinli/services/knowledge/tests/test_legacy_reconcile.py`
- `Project/Jinli/services/knowledge/tests/fixtures/legacy_downloads/`

## Forbidden Paths

- `.trae/tasks/`
- real downloaded media
- real SQLite databases
- every file outside Allowed Paths

## Read First

- `.trae/tasks/jinli/2026-06-21-bilibili-favorites-knowledge-automation/requirements.md`
- `.trae/tasks/jinli/2026-06-21-bilibili-favorites-knowledge-automation/analysis.md`
- `.trae/tasks/jinli/2026-06-21-bilibili-favorites-knowledge-automation/spec.md`
- WP01 source record contract
- existing progress JSON formats under `E:\Obsidian\tools\vsummary`

## Goal

- Implement the SQLite state machine and a no-delete reconciliation planner for existing Hermes/vsummary downloads.

## Steps

- [ ] Write failing tests for legal transitions, transaction rollback, unchanged-revision skip, changed-revision reprocessing, retries, and independent cleanup retry.
- [ ] Implement schema creation and migrations for source item, revision, stage event, managed artifact, attempt, error, and graph queue state.
- [ ] Derive deterministic content revision from normalized source metadata.
- [ ] Reconcile files by embedded BVID or trusted sidecar evidence; mark ambiguous files for review.
- [ ] Import old progress JSON as evidence without treating it as authoritative completion.
- [ ] Produce a migration plan with adopt, move, redownload, ineligible, ambiguous, and unmanaged actions.

## Done Definition

- Ledger transactions survive restart and reject illegal stage jumps.
- Only exported current revisions qualify for summary skip.
- Reconciliation never deletes or mutates real files.
- Ambiguous identity never becomes automatic adoption.

## Required Verification

- Command: `python -m pytest Project/Jinli/services/knowledge/tests/test_automation_ledger.py Project/Jinli/services/knowledge/tests/test_legacy_reconcile.py -q`
- Expected: all WP02 tests pass.

## Do Not Game The Gate

- Do not equate file existence, old progress flags, or favorite presence with completion.
- Do not edit task state or acceptance criteria.

## Stop Conditions

- Stop if existing runtime database ownership conflicts with the proposed ledger location.
- Stop if reconciliation would require moving or deleting real user files.

## Return Report

- Path: `reports/ds4-WP02-result.md`
- Include Changed Files, Commands Run, Acceptance Criteria Touched, Scope Control, Worker Authority, and Unresolved Risks.
- Declare `Extra scope taken: no`.

