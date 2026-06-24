# WP01: Bilibili Source and Eligibility

Owner model: unclaimed
Difficulty: medium
Status: unclaimed
Target model: deepseek-v4-flash
Fresh context required: yes

## Worker Profile

- Profile: ds4-flash
- Role: implementation worker
- Review authority: none
- Verify authority: none

## Context Budget

- Read this package, the parent task truth sources, existing knowledge contracts, and existing Bilibili scripts only.
- Do not inspect unrelated Jinli systems.

## Root Cause Boundary

- Root Cause ID: BILI-AUTO-WP01
- This package owns favorite discovery, metadata normalization, optional pinned-comment retrieval, and eligibility only.

## Task Packet

- Root: `.trae/tasks/jinli/2026-06-21-bilibili-favorites-knowledge-automation`
- Parent task: `2026-06-21-bilibili-favorites-knowledge-automation`

## Allowed Paths

- `Project/Jinli/services/knowledge/sources/__init__.py`
- `Project/Jinli/services/knowledge/sources/bilibili.py`
- `Project/Jinli/services/knowledge/tests/test_bilibili_source.py`
- `Project/Jinli/services/knowledge/tests/fixtures/bilibili/`

## Forbidden Paths

- `.trae/tasks/`
- vsummary configuration and credentials
- Bilibili cookies and browser profiles
- every file outside Allowed Paths

## Read First

- `.trae/tasks/jinli/2026-06-21-bilibili-favorites-knowledge-automation/requirements.md`
- `.trae/tasks/jinli/2026-06-21-bilibili-favorites-knowledge-automation/analysis.md`
- `.trae/tasks/jinli/2026-06-21-bilibili-favorites-knowledge-automation/spec.md`
- existing `Project/Jinli/services/knowledge/contracts.py`
- existing local Bilibili scripts under `E:\Obsidian\tools\vsummary`

## Goal

- Implement a read-only, paginated source adapter that normalizes folder entries and filters strictly below 1,800 seconds before downstream media work.

## Steps

- [ ] Write failing tests for pagination, duplicate BVIDs, 1,799/1,800/1,801-second boundaries, missing description, and present/missing pinned comments.
- [ ] Define normalized source records with collection identity, BVID, CID when available, title, uploader, duration, URL, description, pinned comment, and source revision inputs.
- [ ] Reuse the configured authenticated session without exposing cookie data.
- [ ] Make comment retrieval best-effort and distinguish unavailable from empty.
- [ ] Return deterministic discovery order and eligibility reason.

## Done Definition

- Source fixtures cover multiple pages and optional evidence.
- Duration equal to 1,800 seconds is ineligible.
- The adapter performs no download, note write, graph mutation, or favorite mutation.
- Logs redact session and authorization data.

## Required Verification

- Command: `python -m pytest Project/Jinli/services/knowledge/tests/test_bilibili_source.py -q`
- Expected: all WP01 tests pass.

## Do Not Game The Gate

- Do not weaken boundary tests, replace live fields with constants, or edit task state.
- Do not claim Review or Verify pass.

## Stop Conditions

- Stop if authenticated access requires changing cookies or bypassing platform controls.
- Stop if source fields require an architecture change to canonical contracts.

## Return Report

- Path: `reports/ds4-WP01-result.md`
- Include Changed Files, Commands Run, Acceptance Criteria Touched, Scope Control, Worker Authority, and Unresolved Risks.
- Declare `Extra scope taken: no`.

