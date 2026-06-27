# WP06: Director, Storyboard, Art Direction and Editorial

Owner model: unclaimed
Difficulty: hard
Status: unclaimed
Target model: other
Fresh context required: yes

## Task Packet

- Root: `.trae/tasks/ai-drama/2026-06-20-text-first-creator-intelligence-studio-v3`
- Parent task: `2026-06-20-text-first-creator-intelligence-studio-v3`

## Allowed Paths

- `Project/AIDramaProducer/skills/ai_drama_preproduction_studio/modules/director/`
- `Project/AIDramaProducer/skills/ai_drama_preproduction_studio/modules/storyboard/`
- `Project/AIDramaProducer/skills/ai_drama_preproduction_studio/modules/art_direction/`
- `Project/AIDramaProducer/skills/ai_drama_preproduction_studio/modules/editorial/`
- Related schemas, renderers and tests

## Forbidden Paths

- Creator source adapters
- Legacy compatibility facade
- Image/video/TTS generators
- Task packet mutation

## Read First

- `routing.md`
- `analysis.md`
- `spec.md`
- WP05 screenplay contract
- Existing shot schema and continuity validators as compatibility references

## Goal

Produce separate professional artifacts for directing, cinematography/storyboards, visual consistency and editorial quality.

## Steps

- Write failing director-intent, blocking, performance, rhythm and sound tests.
- Write failing shot timecode, lens, movement, eyeline, screen-direction and transition tests.
- Write failing visual-bible palette, lighting, model-sheet, costume, prop and forbidden-element tests.
- Implement the three professional passes as independent modules.
- Implement editorial pass/fail findings and targeted rewrite ownership.
- Add Markdown and JSON renderers.

## Done Definition

- AC11-AC14 pass.
- Each professional role owns a separate artifact.
- Editorial failures name the responsible pass and do not silently rewrite upstream intent.

## Required Verification

- Command: `python -m pytest ai_drama_preproduction_studio/tests/test_director_storyboard.py ai_drama_preproduction_studio/tests/test_visual_bible.py ai_drama_preproduction_studio/tests/test_editorial.py -q`
- Expected: all tests pass.

## Return Report

- Path: `reports/worker-WP06-result.md`
- Required status: `done`
- Declare `Extra scope taken: no`.

