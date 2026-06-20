# WP03: Video Source And Transcript Adapters

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
- Read this package, task contracts, and source adapter requirements only.
- Do not clone or inspect the full vsummary repository unless the lead provides a pinned local checkout.

## Root Cause Boundary
- Root Cause ID: KG-RUNTIME-WP03
- This package handles public source resolution, yt-dlp metadata/captions, vsummary workspace import, and transcript normalization.

## Task Packet
- Root: `.trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation`
- Parent task: `2026-06-21-knowledge-graph-runtime-implementation`

## Allowed Paths
- `Project/Jinli/services/knowledge/sources/`
- `Project/Jinli/services/knowledge/transcript.py`
- `Project/Jinli/services/knowledge/tests/fixtures/video_sources/`
- `Project/Jinli/services/knowledge/tests/test_video_sources.py`
- `Project/Jinli/services/knowledge/tests/test_vsummary_adapter.py`
- `Project/Jinli/services/knowledge/requirements.txt`

## Forbidden Paths
- `.trae/tasks/`
- vsummary source code
- Browser cookies, login tokens, DRM tools, or credential files
- Real vault content
- Any file outside Allowed Paths

## Read First
- `.trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation/spec.md`
- `Project/Jinli/services/knowledge/contracts.py`
- `Project/Jinli/services/knowledge/config.py`
- `Project/Jinli/docs/02-Design/General/soul-core-phase2.5-knowledge-evolution-spec.md`
- vsummary README at `https://github.com/alpha03123/vsummary`

## Goal
- Normalize accessible public video metadata/captions and pinned vsummary workspace exports into one provenance-preserving transcript contract.

## Steps
- [ ] Write failing fixture-based tests for YouTube metadata, Bilibili metadata, VTT/SRT parsing, duplicate captions, invalid timestamps, access denied, unsupported source, missing captions, and vsummary workspace import.
- [ ] Implement a source protocol with `probe` and `acquire_transcript`.
- [ ] Implement yt-dlp through its Python API with download disabled for caption-first operation.
- [ ] Restrict supported live source families to YouTube and Bilibili for this task.
- [ ] Map login/DRM/paywall/private failures to explicit statuses without retrying around controls.
- [ ] Implement a vsummary workspace adapter for exported transcript/chapter/Markdown artifacts and record revision `4de6dbbd376c29d35380d8d8fcc2094821b2b3f9`.
- [ ] Normalize captions into ordered transcript entries with start/end seconds, text, language, source method, and source hash.
- [ ] Ensure all default tests use fixtures and no network.

## Done Definition
- YouTube, Bilibili, and vsummary fixtures produce the same normalized transcript contract.
- Access denied and unsupported statuses are distinguishable.
- No media download, login bypass, or live network runs during focused tests.

## Required Verification
- Command: `python -m pytest Project/Jinli/services/knowledge/tests/test_video_sources.py Project/Jinli/services/knowledge/tests/test_vsummary_adapter.py -q`
- Expected: all WP03 tests pass offline.

## Do Not Game The Gate
- Do not modify tests, acceptance criteria, task state, or verification evidence to obtain a passing result.
- Do not claim Review or Verify pass.

## Stop Conditions
- Stop if an adapter requires credentials or circumvention.
- Stop if the vsummary export format cannot be identified from pinned evidence.
- Stop if implementing ASR would require copying vsummary internals instead of using the adapter boundary.

## Return Report
- Path: `reports/ds4-WP03-result.md`
- Required status for merge: `done`
- Include Changed Files, Commands Run, Acceptance Criteria Touched, Scope Control, Worker Authority, and Unresolved Risks.
- Declare `Extra scope taken: no`.

## Failure Reporting
- Write the same report path with `Status: blocked` and the smallest source-format question.

