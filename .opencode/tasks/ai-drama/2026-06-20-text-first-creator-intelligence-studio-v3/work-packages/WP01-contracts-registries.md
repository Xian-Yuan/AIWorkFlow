# WP01: Contracts and Registries

Owner model: unclaimed
Difficulty: medium
Status: unclaimed
Target model: other
Fresh context required: yes

## Task Packet

- Root: `.trae/tasks/ai-drama/2026-06-20-text-first-creator-intelligence-studio-v3`
- Parent task: `2026-06-20-text-first-creator-intelligence-studio-v3`

## Allowed Paths

- `Project/AIDramaProducer/skills/ai_drama_creator_intelligence/contracts.py`
- `Project/AIDramaProducer/skills/ai_drama_creator_intelligence/schemas/`
- `Project/AIDramaProducer/skills/ai_drama_creator_intelligence/registries/`
- `Project/AIDramaProducer/skills/ai_drama_creator_intelligence/tests/test_contracts.py`
- Package `__init__.py` and `__main__.py`

## Forbidden Paths

- Existing Viral Analyzer implementation
- Preproduction Studio implementation
- Task state and acceptance criteria
- Provider credentials and network calls

## Read First

- `routing.md`
- `analysis.md`
- `spec.md`
- `tasks.md`
- Project design document

## Goal

Create versioned contracts and independent platform/content-type registries that every later package can consume.

## Steps

- Write failing tests for required fields and invalid schemas.
- Run the focused tests and retain RED evidence.
- Implement immutable contract types and JSON Schema files.
- Add Douyin, Bilibili, Xiaohongshu and YouTube Shorts platform profiles.
- Add comedy, suspense, emotion, knowledge and commercial content-type profiles.
- Add validation CLI and run GREEN tests.

## Done Definition

- AC01-AC02 contract prerequisites pass.
- Platform and content type are separate dimensions.
- No network/provider behavior is introduced.

## Required Verification

- Command: `python -m pytest ai_drama_creator_intelligence/tests/test_contracts.py -q`
- Expected: all tests pass.

## Return Report

- Path: `reports/worker-WP01-result.md`
- Required status: `done`
- Declare `Extra scope taken: no`.

