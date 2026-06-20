# WP03: Distillation and Controlled Skill Bundles

Owner model: unclaimed
Difficulty: hard
Status: unclaimed
Target model: other
Fresh context required: yes

## Task Packet

- Root: `.trae/tasks/ai-drama/2026-06-20-text-first-creator-intelligence-studio-v3`
- Parent task: `2026-06-20-text-first-creator-intelligence-studio-v3`

## Allowed Paths

- `Project/AIDramaProducer/skills/ai_drama_creator_intelligence/modules/distillation/`
- `Project/AIDramaProducer/skills/ai_drama_creator_intelligence/modules/trends/`
- `Project/AIDramaProducer/skills/ai_drama_creator_intelligence/modules/skill_publisher/`
- `Project/AIDramaProducer/skills/ai_drama_creator_intelligence/tests/test_distillation.py`
- `Project/AIDramaProducer/skills/ai_drama_creator_intelligence/tests/test_style_pack.py`
- `Project/AIDramaProducer/skills/ai_drama_creator_intelligence/tests/test_trend_digest.py`
- `Project/AIDramaProducer/skills/ai_drama_creator_intelligence/tests/test_skill_bundle.py`

## Forbidden Paths

- Auto-discovered workspace Skill directories
- Verbatim source scripts and joke compilations
- Platform account mutation
- Task state and verification evidence

## Read First

- `routing.md`
- `analysis.md`
- `spec.md`
- WP01 contracts
- WP02 research snapshot and sample selector
- `skills/writing-skills/SKILL.md`

## Goal

Distill reusable creative mechanisms with provenance and produce validated but inactive creator Skill bundles.

## Steps

- Write failing tests for sample confidence, provenance, freshness and prohibited copying.
- Implement hook, narrative, humor, performance, editing, visual, audio and series-mechanism distillation.
- Implement provider-neutral trend/meme digests and safety scoring.
- Generate inactive Skill bundles with references and pressure scenarios.
- Validate bundles and forward-test them without publishing.

## Done Definition

- AC06-AC08 pass.
- A single work cannot create a creator profile.
- Generated bundles are inactive and cannot self-register.

## Required Verification

- Command: `python -m pytest ai_drama_creator_intelligence/tests/test_distillation.py ai_drama_creator_intelligence/tests/test_style_pack.py ai_drama_creator_intelligence/tests/test_trend_digest.py ai_drama_creator_intelligence/tests/test_skill_bundle.py -q`
- Expected: all tests pass.

## Return Report

- Path: `reports/worker-WP03-result.md`
- Required status: `done`
- Declare `Extra scope taken: no`.

