# WP04: Classified Knowledge Export

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

- Read this package, parent truth sources, accepted knowledge contracts, and WP01-WP03 result contracts.
- Do not implement orchestration or deletion.

## Root Cause Boundary

- Root Cause ID: BILI-AUTO-WP04
- This package owns link extraction, classification normalization, canonical records, and atomic Markdown output.

## Task Packet

- Root: `.trae/tasks/jinli/2026-06-21-bilibili-favorites-knowledge-automation`
- Parent task: `2026-06-21-bilibili-favorites-knowledge-automation`

## Allowed Paths

- `Project/Jinli/services/knowledge/automation/export.py`
- `Project/Jinli/services/knowledge/automation/classification.py`
- `Project/Jinli/services/knowledge/automation/links.py`
- `Project/Jinli/services/knowledge/tests/test_knowledge_export.py`
- `Project/Jinli/services/knowledge/tests/test_link_extraction.py`
- `Project/Jinli/services/knowledge/tests/test_classification.py`

## Forbidden Paths

- `.trae/tasks/`
- real Obsidian user notes
- graph engine source
- every file outside Allowed Paths

## Read First

- `.trae/tasks/jinli/2026-06-21-bilibili-favorites-knowledge-automation/requirements.md`
- `.trae/tasks/jinli/2026-06-21-bilibili-favorites-knowledge-automation/analysis.md`
- canonical graph candidate and note contracts from the knowledge runtime
- WP01 source metadata and WP03 summary result contracts

## Goal

- Produce validated canonical records and atomic Obsidian Markdown notes with identity, optional evidence, important links, classification, and provenance.

## Steps

- [ ] Write failing tests for required fields, absent optional evidence, URL normalization and deduplication, category allow-list, low-confidence fallback, and atomic write failure.
- [ ] Extract URLs from source metadata, pinned comment, transcript evidence, and summary without inventing URLs.
- [ ] Normalize one primary category plus tags, confidence, and evidence.
- [ ] Render stable UTF-8 Markdown with BVID-based identity and readable title.
- [ ] Write canonical record and note atomically, calculate digests, and produce a graph queue record when indexing is unavailable.

## Done Definition

- Required identity and provenance are always present.
- Missing description or pinned comment does not fail export.
- Important links are normalized, deduplicated, and source-attributed.
- Graph outage does not invalidate the accepted note.

## Required Verification

- Command: `python -m pytest Project/Jinli/services/knowledge/tests/test_knowledge_export.py Project/Jinli/services/knowledge/tests/test_link_extraction.py Project/Jinli/services/knowledge/tests/test_classification.py -q`
- Expected: all WP04 tests pass.

## Do Not Game The Gate

- Do not mark low-confidence model text as a trusted category without fallback.
- Do not write to the real vault during tests or edit task state.

## Stop Conditions

- Stop if canonical record schemas are unavailable or incompatible.
- Stop if an allowed category change requires a design decision.

## Return Report

- Path: `reports/ds4-WP04-result.md`
- Include Changed Files, Commands Run, Acceptance Criteria Touched, Scope Control, Worker Authority, and Unresolved Risks.
- Declare `Extra scope taken: no`.

