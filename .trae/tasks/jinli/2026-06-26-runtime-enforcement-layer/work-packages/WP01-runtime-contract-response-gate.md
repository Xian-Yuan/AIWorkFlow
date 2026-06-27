# WP01: Runtime Contract And Response Gate

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

- Root Cause ID: RC01-runtime-evidence-missing
- This package handles the runtime manifest, mode contract, and response gate.

## Task Packet

- Root: `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/`
- Parent task: `2026-06-26-runtime-enforcement-layer`

## Allowed Paths

- `Project/Jinli/services/runtime/**`

## Forbidden Paths

- `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/.task.yaml`
- `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/routing.md`
- `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/analysis.md`
- `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/spec.md`
- `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/tasks.md`
- `.trae/scripts/**`
- `Docs/AI/**`

## Read First

- `routing.md`
- `analysis.md`
- `spec.md`
- `tasks.md`
- `requirements.md`
- `execution-prompt.md`

## Goal

Implement a runtime manifest schema, mode policy, and response gate that blocks Standard/Strict/Critical answers when required evidence is missing.

## Steps

- [ ] Define `TurnMode`, `EvidenceRequirement`, `EvidenceRecord`, `TurnManifest`, and `GateResult`.
- [ ] Implement mode-to-required-evidence policy.
- [ ] Implement response gate validation.
- [ ] Add tests for Lite, Standard, Strict, Critical modes.
- [ ] Add a test where a weak model skips memory/skill evidence and the gate blocks output.

## Done Definition

`python -m pytest Project/Jinli/services/runtime/tests/ -q` passes for WP01 tests.

## Required Verification

- Command: `python -m pytest Project/Jinli/services/runtime/tests/ -q`
- Expected: all runtime manifest and response gate tests pass.

## Do Not Game The Gate

- Do not make missing required evidence pass.
- Do not downgrade Strict/Critical to Lite to avoid checks.
- Do not use a free-form string where a structured status is required.

## Stop Conditions

- Stop if existing Jinli service imports are required before WP03.
- Stop if a required path is outside Allowed Paths.

## Return Report

- Path: `reports/runtime-WP01-result.md`
- Required status for merge: `done`
- Must include changed files, commands run, results, acceptance criteria touched, scope control, unresolved risks, and `Extra scope taken: no`.
