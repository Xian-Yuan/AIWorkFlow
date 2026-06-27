# WP05: Professional Screenplay

Owner model: unclaimed
Difficulty: hard
Status: unclaimed
Target model: other
Fresh context required: yes

## Task Packet

- Root: `.trae/tasks/ai-drama/2026-06-20-text-first-creator-intelligence-studio-v3`
- Parent task: `2026-06-20-text-first-creator-intelligence-studio-v3`

## Allowed Paths

- `Project/AIDramaProducer/skills/ai_drama_preproduction_studio/modules/screenwriter/`
- `Project/AIDramaProducer/skills/ai_drama_preproduction_studio/renderers/`
- `Project/AIDramaProducer/skills/ai_drama_preproduction_studio/schemas/screenplay*.json`
- `Project/AIDramaProducer/skills/ai_drama_preproduction_studio/tests/test_screenwriter.py`
- `Project/AIDramaProducer/skills/ai_drama_preproduction_studio/tests/test_fountain_renderer.py`
- `Project/AIDramaProducer/skills/ai_drama_preproduction_studio/tests/golden/`

## Forbidden Paths

- Director, storyboard and art-direction modules
- Source research modules
- Existing media generators
- Task packet mutation

## Read First

- `routing.md`
- `analysis.md`
- `spec.md`
- WP04 creative strategy contract
- Existing Scriptwriter schema and prompts as compatibility references

## Goal

Create one canonical professional screenplay model with human-readable Fountain/Markdown and legacy compatibility views.

## Steps

- Write failing hierarchy, scene and dialogue tests.
- Write a failing golden Fountain rendering test.
- Implement story bible and beat sheet.
- Implement episode, act, sequence and scene hierarchy.
- Implement objective, conflict, beats, value changes, action, dialogue, subtext and transitions.
- Render Fountain and Markdown deterministically.
- Derive legacy scenes/shots without discarding canonical fields.

## Done Definition

- AC10 passes.
- Human and machine outputs derive from one canonical model.
- Existing downstream fields remain available.

## Required Verification

- Command: `python -m pytest ai_drama_preproduction_studio/tests/test_screenwriter.py ai_drama_preproduction_studio/tests/test_fountain_renderer.py -q`
- Expected: all tests and golden comparisons pass.

## Return Report

- Path: `reports/worker-WP05-result.md`
- Required status: `done`
- Declare `Extra scope taken: no`.

