# WP02: Injection Consumer and Canonical Test Entry

Owner model: Codex issuer-direct
Difficulty: hard
Status: done

## Task Packet
- Root: `.trae/tasks/ai-drama/2026-06-20-verification-truth-closure`
- Parent task: `2026-06-20-verification-truth-closure`

## Allowed Paths
- `Project/AIDramaProducer/skills/pytest.ini`
- `Project/AIDramaProducer/skills/ai_drama_scriptwriter/`
- `Project/AIDramaProducer/skills/ai_drama_viral_analyzer/viral_analyzer.py`
- `Project/AIDramaProducer/skills/ai_drama_orchestrator/orchestrator.py`
- `Project/AIDramaProducer/skills/ai_drama_orchestrator/tests/`

## Forbidden Paths
- Provider credentials
- External API calls
- Real-media acceptance thresholds

## Read First
- `analysis.md`
- `spec.md`
- Viral creator output schema
- Scriptwriter Step 1/2/3 prompt builders
- Orchestrator Phase 2 handler

## Goal
Make the advertised Viral injection contract executable and make root pytest deterministic.

## Steps
- Add root pytest discovery configuration.
- Write injection loader and prompt-consumption tests first.
- Implement validated bundle loading.
- Propagate the bundle through all Scriptwriter steps.
- Add CLI and Orchestrator pass-through.
- Run focused and root tests.

## Done Definition
- The advertised CLI option exists.
- All four sibling injection files can be consumed.
- Injection values reach generation prompts.
- Root pytest ignores runtime `.txt` inputs.

## Required Verification
- Command: `python -m pytest -q`
- Expected: all tests pass from the skills root.

## Return Report
- Path: `reports/codex-WP02-result.md`
- Issuer-direct execution records evidence in the final verification report.
