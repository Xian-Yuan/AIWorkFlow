# WP03: Existing Service Adapters And After-Turn Commit

Owner model: unclaimed
Difficulty: hard
Status: unclaimed
Target model: general
Fresh context required: yes

## Worker Profile

- Profile: general
- Role: implementation worker
- Review authority: none
- Verify authority: none

## Context Budget

Read only this package and the files listed under Read First.

## Root Cause Boundary

- Root Cause ID: RC03-services-exist-but-not-used
- This package wires existing services through adapters without rewriting them.

## Task Packet

- Root: `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/`
- Parent task: `2026-06-26-runtime-enforcement-layer`

## Allowed Paths

- `Project/Jinli/services/runtime/**`

## Forbidden Paths

- `Project/Jinli/services/memory/**`
- `Project/Jinli/services/persona/**`
- `Project/Jinli/services/proactive/**`
- `Project/Jinli/services/evolution/**`
- `Project/Jinli/services/nervous/**`
- `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/.task.yaml`
- `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/*.md`

## Read First

- `routing.md`
- `analysis.md`
- `spec.md`
- `requirements.md`
- `Project/Jinli/services/memory/keeper/final-result.md`
- `Project/Jinli/services/memory/dreamer/final-result.md`
- `Project/Jinli/services/proactive/p1/final-result.md`
- `Project/Jinli/services/persona/final-result.md`

## Goal

Create adapters that prove whether memory, persona, event, dreamer, proactive, and evolution systems were used or explicitly degraded during a turn.

## Steps

- [ ] Implement adapter interfaces.
- [ ] Implement safe degradation records for unavailable services.
- [ ] Implement after-turn commit summary.
- [ ] Add tests that distinguish "service exists" from "service used this turn".
- [ ] Add tests for after-turn memory/event/dream/proactive/evolution pending signals.

## Done Definition

Runtime adapter tests pass and produce structured evidence records.

## Required Verification

- Command: `python -m pytest Project/Jinli/services/runtime/tests/ -q`
- Expected: all runtime adapter tests pass.

## Do Not Game The Gate

- Do not edit existing service internals.
- Do not claim a service was used when the adapter only found its files.
- Do not write memory directly outside approved paths.

## Stop Conditions

- Stop if an existing service has no stable API and needs lead architecture decision.
- Stop if after-turn commit would write outside runtime-approved data paths.

## Return Report

- Path: `reports/runtime-WP03-result.md`
- Required status for merge: `done`
- Must include changed files, commands run, results, acceptance criteria touched, scope control, unresolved risks, and `Extra scope taken: no`.
