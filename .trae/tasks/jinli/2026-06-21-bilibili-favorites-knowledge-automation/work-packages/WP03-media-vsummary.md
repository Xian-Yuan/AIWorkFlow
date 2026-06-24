# WP03: Managed HDD Media and vsummary Adapter

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

- Read this package, parent truth sources, WP01-WP02 contracts, and vsummary API contracts.
- Do not alter vsummary source or configuration.

## Root Cause Boundary

- Root Cause ID: BILI-AUTO-WP03
- This package owns disk verification, managed paths, downloading, and vsummary request handling.

## Task Packet

- Root: `.trae/tasks/jinli/2026-06-21-bilibili-favorites-knowledge-automation`
- Parent task: `2026-06-21-bilibili-favorites-knowledge-automation`

## Allowed Paths

- `Project/Jinli/services/knowledge/automation/media.py`
- `Project/Jinli/services/knowledge/automation/vsummary_client.py`
- `Project/Jinli/services/knowledge/tests/test_managed_media.py`
- `Project/Jinli/services/knowledge/tests/test_vsummary_client.py`

## Forbidden Paths

- `.trae/tasks/`
- `E:\Obsidian\tools\vsummary\.env`
- real Bilibili cookies
- real media outside test temporary directories
- every file outside Allowed Paths

## Read First

- `.trae/tasks/jinli/2026-06-21-bilibili-favorites-knowledge-automation/analysis.md`
- `.trae/tasks/jinli/2026-06-21-bilibili-favorites-knowledge-automation/spec.md`
- WP01 source record contract
- WP02 ledger and managed-artifact contracts
- vsummary OpenAPI routes for generate and summary retrieval

## Goal

- Implement path-contained media management on a verified non-SSD root and a bounded vsummary adapter with structured result validation.

## Steps

- [ ] Write failing tests for SSD rejection, free-space floor, path escape, partial download cleanup, retry, timeout, malformed response, and successful structured summary.
- [ ] Implement physical-disk identity checks with injectable platform probes.
- [ ] Default to `G:\JinliVideoCache` through configuration, not business-logic constants.
- [ ] Download to a temporary managed path and atomically promote only verified complete media.
- [ ] Call vsummary without exposing provider credentials and support asynchronous completion behavior.
- [ ] Classify errors as retryable, terminal, or operator-action-required.

## Done Definition

- No download begins on a verified SSD or below the free-space floor.
- Every resolved media path remains under the managed root.
- Partial files never appear as media-ready.
- vsummary timeout and malformed output preserve media for retry.

## Required Verification

- Command: `python -m pytest Project/Jinli/services/knowledge/tests/test_managed_media.py Project/Jinli/services/knowledge/tests/test_vsummary_client.py -q`
- Expected: all WP03 tests pass.

## Do Not Game The Gate

- Do not mock away path containment or physical-disk decisions in the behavior under test.
- Do not hard-code credentials, cookies, or production responses.

## Stop Conditions

- Stop if Windows cannot prove disk media type with available supported APIs.
- Stop if the vsummary contract differs from the task analysis and requires architecture change.

## Return Report

- Path: `reports/ds4-WP03-result.md`
- Include Changed Files, Commands Run, Acceptance Criteria Touched, Scope Control, Worker Authority, and Unresolved Risks.
- Declare `Extra scope taken: no`.

