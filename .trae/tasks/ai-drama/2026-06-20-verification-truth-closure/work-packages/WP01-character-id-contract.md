# WP01: Character ID Contract

Owner model: Codex issuer-direct
Difficulty: medium
Status: done

## Task Packet
- Root: `.trae/tasks/ai-drama/2026-06-20-verification-truth-closure`
- Parent task: `2026-06-20-verification-truth-closure`

## Allowed Paths
- `Project/AIDramaProducer/skills/ai_drama_text_preprocessor/text_preprocessor.py`
- `Project/AIDramaProducer/skills/ai_drama_text_preprocessor/tests/test_preprocessor.py`

## Forbidden Paths
- Original acceptance criteria
- Task result fields
- Other generator modules

## Read First
- `analysis.md`
- `spec.md`
- `tasks.md`
- Existing preprocessor implementation and tests

## Goal
Return stable IDs for mapped characters without breaking regex-only fallback detection.

## Steps
- Write the mapped-ID regression test.
- Observe the expected failure.
- Implement the smallest dual-mode behavior.
- Run the full preprocessor suite.

## Done Definition
- Mapped mode returns only known IDs.
- Fallback mode continues returning detected names.

## Required Verification
- Command: `python -m pytest ai_drama_text_preprocessor/tests -q`
- Expected: all tests pass.

## Return Report
- Path: `reports/codex-WP01-result.md`
- Issuer-direct execution records evidence in the final verification report.
