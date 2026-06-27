# WP02: Source Acquisition and Evidence

Owner model: unclaimed
Difficulty: hard
Status: unclaimed
Target model: other
Fresh context required: yes

## Task Packet

- Root: `.trae/tasks/ai-drama/2026-06-20-text-first-creator-intelligence-studio-v3`
- Parent task: `2026-06-20-text-first-creator-intelligence-studio-v3`

## Allowed Paths

- `Project/AIDramaProducer/skills/ai_drama_creator_intelligence/modules/source_adapters/`
- `Project/AIDramaProducer/skills/ai_drama_creator_intelligence/modules/research/`
- `Project/AIDramaProducer/skills/ai_drama_creator_intelligence/tests/test_source_adapters.py`
- `Project/AIDramaProducer/skills/ai_drama_creator_intelligence/tests/test_sample_selector.py`
- `Project/AIDramaProducer/skills/ai_drama_creator_intelligence/tests/fixtures/`

## Forbidden Paths

- Credentials, cookies or authenticated scraping
- Generated creator Skills
- Preproduction passes
- Task packet mutation

## Read First

- `routing.md`
- `analysis.md`
- `spec.md`
- WP01 contracts and registries
- Existing Viral Analyzer media utilities as read-only reference

## Goal

Implement provider-neutral evidence collection, explicit partial failures, creator-relative metrics and deterministic sample selection.

## Steps

- Write adapter contract and failure-path tests.
- Implement fixture/manual adapters before network adapters.
- Implement Bilibili public metadata behind the same protocol.
- Implement robust creator-baseline normalization.
- Select 8-20 recommended works and mark profiles below five works low-confidence.
- Record missing metrics and access issues without fabrication.

## Done Definition

- AC03-AC05 pass.
- Offline fixture tests are deterministic.
- Network access is optional and separately marked.

## Required Verification

- Command: `python -m pytest ai_drama_creator_intelligence/tests/test_source_adapters.py ai_drama_creator_intelligence/tests/test_sample_selector.py -q`
- Expected: all offline tests pass.

## Return Report

- Path: `reports/worker-WP02-result.md`
- Required status: `done`
- Declare `Extra scope taken: no`.

