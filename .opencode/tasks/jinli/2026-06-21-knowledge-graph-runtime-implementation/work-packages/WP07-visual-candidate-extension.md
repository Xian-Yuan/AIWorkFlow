# WP07: Visual Candidate Extension

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
- Read this package, existing vision service public interfaces, and graph candidate contracts.
- Do not modify screen-capture privacy behavior.

## Root Cause Boundary
- Root Cause ID: KG-RUNTIME-WP07
- This package handles explicit keyframe sampling and candidate-only visual observations.

## Task Packet
- Root: `.trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation`
- Parent task: `2026-06-21-knowledge-graph-runtime-implementation`

## Allowed Paths
- `Project/Jinli/services/knowledge/keyframes.py`
- `Project/Jinli/services/knowledge/visual_enrichment.py`
- `Project/Jinli/services/knowledge/tests/test_keyframes.py`
- `Project/Jinli/services/knowledge/tests/test_visual_enrichment.py`

## Forbidden Paths
- `.trae/tasks/`
- `Project/Jinli/services/vision/`
- Screen capture code
- Canonical graph acceptance methods
- Any file outside Allowed Paths

## Read First
- `.trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation/spec.md`
- `Project/Jinli/services/knowledge/contracts.py`
- `Project/Jinli/services/knowledge/worker_gateway.py`
- `Project/Jinli/services/vision/inference.py`

## Goal
- Add opt-in video keyframe sampling and visual-model jobs whose outputs remain candidate evidence until reviewed.

## Steps
- [ ] Write failing tests for disabled-by-default behavior, deterministic timestamp sampling, duplicate-frame suppression, maximum-frame budget, cancellation, missing FFmpeg, model unavailable, and candidate-only output.
- [ ] Implement FFmpeg-based keyframe extraction through an injected process runner.
- [ ] Submit `describe_keyframe` jobs through Local Worker Gateway using the configured local visual model.
- [ ] Store keyframe path, timestamp, source hash, model/provider, OCR text, observations, and confidence in candidate evidence.
- [ ] Prohibit direct calls to graph acceptance or Obsidian export from visual enrichment.
- [ ] Delete incomplete temporary frames after cancellation or failure while preserving accepted source media.

## Done Definition
- Visual analysis is disabled unless explicitly requested.
- Candidate evidence is timestamped and schema validated.
- Tests prove no accepted graph mutation occurs.

## Required Verification
- Command: `python -m pytest Project/Jinli/services/knowledge/tests/test_keyframes.py Project/Jinli/services/knowledge/tests/test_visual_enrichment.py -q`
- Expected: all WP07 tests pass.

## Do Not Game The Gate
- Do not modify tests, acceptance criteria, task state, or verification evidence to obtain a passing result.
- Do not claim Review or Verify pass.

## Stop Conditions
- Stop if implementation requires modifying privacy-sensitive screen vision code.
- Stop if visual output can reach accepted graph state without review.
- Stop if frame extraction has no cancellation or disk-budget boundary.

## Return Report
- Path: `reports/ds4-WP07-result.md`
- Required status for merge: `done`
- Include Changed Files, Commands Run, Acceptance Criteria Touched, Scope Control, Worker Authority, and Unresolved Risks.
- Declare `Extra scope taken: no`.

## Failure Reporting
- Write the same report path with `Status: blocked` and exact boundary violation.

