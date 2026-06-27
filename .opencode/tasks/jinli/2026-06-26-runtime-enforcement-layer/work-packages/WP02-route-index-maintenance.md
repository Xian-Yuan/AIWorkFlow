# WP02: File And Workflow Route Index Maintenance

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

- Root Cause ID: RC02-route-knowledge-not-mechanical
- This package handles generated file route and workflow route indexes.

## Task Packet

- Root: `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/`
- Parent task: `2026-06-26-runtime-enforcement-layer`

## Allowed Paths

- `Project/Jinli/services/runtime/**`
- `.trae/scripts/jinli-route-index.ps1`
- `Docs/AI/47-Jinli-Runtime-Enforcement-Layer.md`

## Forbidden Paths

- `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/.task.yaml`
- `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/routing.md`
- `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/analysis.md`
- `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/spec.md`
- `.trae/tasks/jinli/2026-06-26-runtime-enforcement-layer/tasks.md`
- project gameplay source under `Project/RTS/**`

## Read First

- `routing.md`
- `analysis.md`
- `spec.md`
- `requirements.md`
- `Docs/AI/27-AI-Workflow-Refactor-Manifest.md`
- `Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md`

## Goal

Implement generated/checkable route indexes so a new model can discover file placement and workflow process rules mechanically.

## Steps

- [ ] Define route index data shape.
- [ ] Implement route index generator/checker.
- [ ] Cover canonical locations for Docs/AI, skills, scripts, task packets, Jinli services, runtime data, reports, and generated indexes.
- [ ] Add freshness check behavior.
- [ ] Document how models should consume the route index.

## Done Definition

`powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\jinli-route-index.ps1 -Check` passes.

## Required Verification

- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\jinli-route-index.ps1 -Check`
- Expected: exits 0 and reports route indexes current.

## Do Not Game The Gate

- Do not hard-code only the current task.
- Do not mark unknown routes as pass without a clear degradation reason.
- Do not delete existing docs or scripts.

## Stop Conditions

- Stop if route generation requires changing unrelated task packets.
- Stop if a location cannot be inferred and needs lead decision.

## Return Report

- Path: `reports/runtime-WP02-result.md`
- Required status for merge: `done`
- Must include changed files, commands run, results, acceptance criteria touched, scope control, unresolved risks, and `Extra scope taken: no`.
