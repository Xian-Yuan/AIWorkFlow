# WP04: Segmentation, Enrichment, And Evidence Search

Owner model: unclaimed
Difficulty: hard
Status: unclaimed
Target model: deepseek-v4-flash
Fresh context required: yes

## Worker Profile
- Profile: ds4-flash
- Role: implementation worker
- Review authority: none
- Verify authority: none

## Context Budget
- Read this package and WP01-WP03 public interfaces only.
- Do not inspect Obsidian export or Soul Core code.

## Root Cause Boundary
- Root Cause ID: KG-RUNTIME-WP04
- This package handles deterministic segmentation, gateway enrichment orchestration, summary compilation, and raw/keyword evidence search.

## Task Packet
- Root: `.trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation`
- Parent task: `2026-06-21-knowledge-graph-runtime-implementation`

## Allowed Paths
- `Project/Jinli/services/knowledge/segmentation.py`
- `Project/Jinli/services/knowledge/enrichment.py`
- `Project/Jinli/services/knowledge/evidence_search.py`
- `Project/Jinli/services/knowledge/summary.py`
- `Project/Jinli/services/knowledge/tests/test_segmentation.py`
- `Project/Jinli/services/knowledge/tests/test_enrichment.py`
- `Project/Jinli/services/knowledge/tests/test_evidence_search.py`
- `Project/Jinli/services/knowledge/tests/test_summary.py`

## Forbidden Paths
- `.trae/tasks/`
- `Project/Jinli/services/knowledge/graph_store.py`
- `Project/Jinli/services/knowledge/obsidian_export.py`
- `Project/Jinli/scripts/`
- Any file outside Allowed Paths

## Read First
- `.trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation/spec.md`
- `Project/Jinli/services/knowledge/contracts.py`
- `Project/Jinli/services/knowledge/transcript.py`
- `Project/Jinli/services/knowledge/worker_gateway.py`

## Goal
- Produce stable timestamped segments, bounded worker jobs, source-backed summaries, and keyword evidence results even when local models are unavailable.

## Steps
- [ ] Write failing tests for timestamp gaps, chapter boundaries, maximum duration, empty transcript, repeated text, multilingual text, and deterministic segment IDs.
- [ ] Implement segmentation without using an LLM.
- [ ] Create bounded summarize/extract jobs per segment and validate their envelopes.
- [ ] Preserve raw segments and mark enrichment pending when the gateway is unavailable.
- [ ] Compile a Markdown summary with source URL, chapter/segment timestamps, key claims, and explicit pending markers.
- [ ] Implement deterministic keyword search returning video ID, title, segment ID, timestamp, excerpt, and source path.
- [ ] Limit returned evidence by result count and character budget.

## Done Definition
- Segment IDs and timestamps are deterministic.
- Every summary claim links to at least one source segment or is marked unverified.
- Keyword search works using raw text with Ollama disabled.

## Required Verification
- Command: `python -m pytest Project/Jinli/services/knowledge/tests/test_segmentation.py Project/Jinli/services/knowledge/tests/test_enrichment.py Project/Jinli/services/knowledge/tests/test_evidence_search.py Project/Jinli/services/knowledge/tests/test_summary.py -q`
- Expected: all WP04 tests pass.

## Do Not Game The Gate
- Do not modify tests, acceptance criteria, task state, or verification evidence to obtain a passing result.
- Do not claim Review or Verify pass.

## Stop Conditions
- Stop if a segment cannot retain source timestamp provenance.
- Stop if an unavailable model causes source artifacts to be deleted or replaced.
- Stop if a claim cannot be linked to evidence under the current contract.

## Return Report
- Path: `reports/ds4-WP04-result.md`
- Required status for merge: `done`
- Include Changed Files, Commands Run, Acceptance Criteria Touched, Scope Control, Worker Authority, and Unresolved Risks.
- Declare `Extra scope taken: no`.

## Failure Reporting
- Write the same report path with `Status: blocked` and exact fixture evidence.

