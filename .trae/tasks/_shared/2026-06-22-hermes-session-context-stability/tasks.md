# Tasks: Hermes Session Context Stability

## Plan

- [x] Record confirmed requirements for Hermes history/context stability.
- [x] Record architecture context, mature solution evidence, acceptance criteria, and verification plan.
- [x] Pass Plan gate and can-edit gate before touching Hermes config or code.

## Implement

- [x] Update Jinli planner and implementer profile overlays with explicit model, context length, and safer compression settings.
- [x] Sync repository overlays to runtime Hermes profile configs.
- [x] Add or adjust Hermes session listing/search behavior for true ghost sessions and compression lineage dedupe if current tests expose a gap.
- [x] Add a non-destructive Hermes session diagnostic script for ghost sessions, multi-child lineages, and severe compression ratios.
- [x] Repair Jinli provider/model pairing so `z-ai/glm-5.1` is not sent to the XF-Coding endpoint.
- [x] Add desktop stream regression coverage for terminal run failure events.
- [x] Handle desktop `run.failed`, `response.failed`, and `run.cancelled` terminal stream events without dropping visible assistant content.
- [x] Verify selected mature path was implemented and no rejected shortcut was introduced.

## Verify

- [x] Run automated verification and record command output in verification-report.md.
- [x] Map implementation result to Acceptance Criteria in verification-report.md.
- [x] Run task gates through implement/review/verify as far as evidence permits.
