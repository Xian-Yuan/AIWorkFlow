# WP04: Creative Intake and Strategy

Owner model: unclaimed
Difficulty: hard
Status: unclaimed
Target model: other
Fresh context required: yes

## Task Packet

- Root: `.trae/tasks/ai-drama/2026-06-20-text-first-creator-intelligence-studio-v3`
- Parent task: `2026-06-20-text-first-creator-intelligence-studio-v3`

## Allowed Paths

- `Project/AIDramaProducer/skills/ai_drama_preproduction_studio/contracts.py`
- `Project/AIDramaProducer/skills/ai_drama_preproduction_studio/modules/intake/`
- `Project/AIDramaProducer/skills/ai_drama_preproduction_studio/modules/strategy/`
- `Project/AIDramaProducer/skills/ai_drama_preproduction_studio/tests/test_intake.py`
- `Project/AIDramaProducer/skills/ai_drama_preproduction_studio/tests/test_strategy.py`
- Package `__init__.py` and configuration files

## Forbidden Paths

- Screenplay/director/storyboard implementation
- Legacy compatibility modules
- Source adapters
- Task packet mutation

## Read First

- `routing.md`
- `analysis.md`
- `spec.md`
- WP01 registries
- WP03 style-pack and trend-digest contracts

## Goal

Require a complete creative brief, diagnose the idea and produce platform/type-aware alternatives before professional writing begins.

## Steps

- Write failing mandatory-field and routing tests.
- Implement one-question-at-a-time unresolved intake.
- Implement platform/content-type strategy routing.
- Implement idea-strength and drop-off diagnosis.
- Produce three distinct routes and a recommended route.
- Include attention-refresh map, borrowed mechanisms, transformed expression and originality notes.

## Done Definition

- AC01, AC02 and AC09 pass.
- Strategy cannot run with unresolved critical fields.
- No generic one-size-fits-all short-video structure is used.

## Required Verification

- Command: `python -m pytest ai_drama_preproduction_studio/tests/test_intake.py ai_drama_preproduction_studio/tests/test_strategy.py -q`
- Expected: all tests pass.

## Return Report

- Path: `reports/worker-WP04-result.md`
- Required status: `done`
- Declare `Extra scope taken: no`.

