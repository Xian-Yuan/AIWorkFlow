# WP04: Gates, Regression, And Verification

Owner model: unclaimed
Difficulty: hard
Status: unclaimed
Target model: general
Fresh context required: yes

## Worker Profile

- Profile: general
- Role: verification worker
- Review authority: none
- Verify authority: none

## Context Budget

Read only this package and the files listed under Read First.

## Root Cause Boundary

- Root Cause ID: RC04-cross-model-stability-unverified
- This package handles scripts, regression coverage, and evidence gathering.

## Task Packet

- Root: `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/`
- Parent task: `2026-06-26-runtime-enforcement-layer`

## Allowed Paths

- `Project/Jinli/services/runtime/tests/**`
- `.trae/scripts/jinli-runtime-turn.ps1`
- `.trae/scripts/jinli-route-index.ps1`
- `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/reports/**`

## Forbidden Paths

- `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/.task.yaml`
- `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/routing.md`
- `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/analysis.md`
- `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/spec.md`
- `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/tasks.md`
- `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/verification-report.md`

## Read First

- `routing.md`
- `analysis.md`
- `spec.md`
- `requirements.md`
- `.trae/scripts/task-state.ps1`
- `.trae/scripts/contract-verify.ps1`
- `.trae/scripts/test-workflow-regression.ps1`

## Goal

Add regression checks that prove the runtime blocks skipped steps and that route indexes remain current.

## Steps

- [ ] Add or update tests for weak-model skipped-step behavior.
- [ ] Add or update route index check tests.
- [ ] Verify `task-state.ps1 init` can initialize a new task without manual directory creation, or report a blocker with root cause.
- [ ] Run runtime tests.
- [ ] Run workflow regression or record exact blocker.

## Done Definition

All assigned verification commands run and results are reported to the lead.

## Required Verification

- Command: `python -m pytest Project/Jinli/services/runtime/tests/ -q`
- Expected: all runtime tests pass.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-workflow-regression.ps1`
- Expected: pass, or report exact failing scenario and root cause.

## Do Not Game The Gate

- Do not weaken workflow regression tests.
- Do not mark verification pass.
- Do not edit final verification report.

## Stop Conditions

- Stop if workflow regression fails outside this package's allowed paths.
- Stop if a gate script defect requires lead-owned patching.

## Return Report

- Path: `reports/runtime-WP04-result.md`
- Required status for merge: `done`
- Must include changed files, commands run, results, acceptance criteria touched, scope control, unresolved risks, and `Extra scope taken: no`.
