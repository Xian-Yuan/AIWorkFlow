# WP05: Orchestration, Cleanup, and Operations

Owner model: unclaimed
Difficulty: high
Status: unclaimed
Target model: deepseek-v4-flash
Fresh context required: yes

## Worker Profile

- Profile: ds4-flash
- Role: integration implementation worker
- Review authority: none
- Verify authority: none

## Context Budget

- Read this package, parent truth sources, all prior worker reports, and public WP01-WP04 contracts.
- Do not redesign prior package internals.

## Root Cause Boundary

- Root Cause ID: BILI-AUTO-WP05
- This package owns orchestration, cleanup policy, CLI, scheduled-task wrapper, integration tests, and operator documentation.

## Task Packet

- Root: `.trae/tasks/jinli/2026-06-21-bilibili-favorites-knowledge-automation`
- Parent task: `2026-06-21-bilibili-favorites-knowledge-automation`

## Allowed Paths

- `Project/Jinli/services/knowledge/automation/pipeline.py`
- `Project/Jinli/services/knowledge/automation/cli.py`
- `Project/Jinli/tests/knowledge/test_bilibili_favorites_e2e.py`
- `Project/Jinli/scripts/knowledge-bilibili-favorites.ps1`
- `Project/Jinli/scripts/knowledge-schedule.ps1`
- `Project/Jinli/Docs/03-Architecture/KnowledgeGraph/bilibili-favorites-pipeline.md`
- `Project/Jinli/Docs/04-Implementation/KnowledgeGraph/bilibili-favorites-automation.md`
- `Project/Jinli/Docs/05-Testing/KnowledgeGraph/bilibili-favorites-automation-verification.md`
- `Project/Jinli/Docs/06-Operations/KnowledgeGraph/bilibili-favorites-runbook.md`
- `Project/Jinli/Docs/DOCS_TREE.md`

## Forbidden Paths

- `.trae/tasks/`
- vsummary source and credentials
- Bilibili cookies and browser profiles
- files outside the configured managed media root during cleanup
- unrelated Jinli code

## Read First

- `.trae/tasks/jinli/2026-06-21-bilibili-favorites-knowledge-automation/requirements.md`
- `.trae/tasks/jinli/2026-06-21-bilibili-favorites-knowledge-automation/analysis.md`
- `.trae/tasks/jinli/2026-06-21-bilibili-favorites-knowledge-automation/spec.md`
- reports for WP01, WP02, WP03, and WP04

## Goal

- Integrate one restartable runner with dry-run, bounded concurrency, post-commit cleanup, scheduling, metrics, and end-to-end tests.

## Steps

- [ ] Write failing integration tests for happy path, unchanged-revision skip, retry, graph outage, missing comment, cleanup failure, and no-delete-before-commit.
- [ ] Implement stage orchestration with per-stage concurrency and retry policy.
- [ ] Implement cleanup that verifies ledger ownership, managed-root containment, note digest, and committed export before deletion.
- [ ] Add dry-run and batch-limit controls with zero mutation guarantees.
- [ ] Add a PowerShell entrypoint and an idempotent scheduled-task installer that invokes the same CLI.
- [ ] Add structured run summaries and operator runbooks.

## Done Definition

- One canary can complete discovery through cleanup.
- The second unchanged run skips all expensive work.
- Failed cleanup is retryable without repeating summary generation.
- Dry-run produces no download, write, ledger mutation, graph mutation, or deletion.
- Documentation and docs tree are synchronized.

## Required Verification

- Command: `python -m pytest Project/Jinli/tests/knowledge/test_bilibili_favorites_e2e.py -q`
- Expected: all WP05 integration tests pass.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File Project/Jinli/scripts/knowledge-bilibili-favorites.ps1 -DryRun`
- Expected: a read-only action report and zero mutations.

## Do Not Game The Gate

- Do not delete a file to make cleanup tests pass, bypass ledger checks, or weaken dry-run assertions.
- Do not set Review or Verify results or edit task packet files.

## Stop Conditions

- Stop if any earlier worker report is missing or blocked.
- Stop if cleanup containment, export durability, or disk identity cannot be proven.
- Stop if scheduler installation would require unapproved credentials or elevated account changes.

## Return Report

- Path: `reports/ds4-WP05-result.md`
- Include Changed Files, Commands Run, Acceptance Criteria Touched, Scope Control, Worker Authority, and Unresolved Risks.
- Declare `Extra scope taken: no`.

