# WP07: Compatibility and Orchestration

Owner model: unclaimed
Difficulty: hard
Status: unclaimed
Target model: other
Fresh context required: yes

## Task Packet

- Root: `.trae/tasks/ai-drama/2026-06-20-text-first-creator-intelligence-studio-v3`
- Parent task: `2026-06-20-text-first-creator-intelligence-studio-v3`

## Allowed Paths

- `Project/AIDramaProducer/skills/ai_drama_viral_analyzer/`
- `Project/AIDramaProducer/skills/ai_drama_scriptwriter/`
- `Project/AIDramaProducer/skills/ai_drama_orchestrator/`
- Compatibility and orchestrator tests

## Forbidden Paths

- TTS, asset, keyframe, video and compositor implementation
- Deletion of legacy commands
- Task state, acceptance criteria and verification report
- Provider credentials

## Read First

- `routing.md`
- `analysis.md`
- `spec.md`
- WP03 style-pack output
- WP04 strategy output
- WP05/WP06 artifact contracts
- Existing Viral Analyzer and Orchestrator tests

## Goal

Preserve old callers while introducing an optional checkpointed text-first pipeline.

## Steps

- Write failing tests for legacy CLI forwarding.
- Write failing tests for four-file injection derivation.
- Write failing tests for the `text_first` pipeline variant and resume state.
- Implement compatibility facade and deprecation messages.
- Add creator-intelligence and preproduction phases before legacy Scriptwriter.
- Preserve the existing standard pipeline path.
- Run focused and regression tests.

## Done Definition

- AC15 passes.
- No legacy entrypoint is silently removed.
- Existing media-generation packages remain unchanged.

## Required Verification

- Command: `python -m pytest ai_drama_viral_analyzer/tests ai_drama_scriptwriter/tests ai_drama_orchestrator/tests -q`
- Expected: all compatibility and regression tests pass.

## Return Report

- Path: `reports/worker-WP07-result.md`
- Required status: `done`
- Declare `Extra scope taken: no`.

