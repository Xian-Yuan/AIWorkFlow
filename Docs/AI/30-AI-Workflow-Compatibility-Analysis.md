---
domain: ai
domain_path: ai/workflow
kg_node_id: node.doc-ai-ai-30-ai-workflow-compatibility-analysis-1d22
t13_retro_classified_at: "2026-06-24T04:47:04Z"
kg_id: doc.ai.ai.30-ai-workflow-compatibility-analysis.1d22

---

# AI Workflow Compatibility Analysis

> **Status note: Historical compatibility report. Partially superseded by Docs/AI/33 and Docs/AI/34. Codex sync scripts now in engine/_experimental/, not .trae/scripts/.**

Date: 2026-06-17
Status: Active
Scope: Codex, OpenCode, Trae-compatible shared workflow

## Executive Summary

> **Status note: Historical compatibility report. Partially superseded by Docs/AI/33 and Docs/AI/34. Codex sync scripts now in engine/_experimental/, not .trae/scripts/.**

Current AI workflow is **not OpenCode-only**.

The global workflow rules are shared and can be used by Codex, OpenCode, and any agent that can read repository files and run PowerShell scripts. However, platform integration maturity is uneven:

| Platform | Current support level | Practical conclusion |
|---|---|---|
| OpenCode | First-class | Best integrated agent workflow today. It has `.opencode/agents`, `.opencode/rules`, `.opencode/scripts/task-state.ps1`, and `.opencode/tasks`. |
| Codex | Shared-rule compatible with a Codex adapter skill | Codex can use `AGENTS.md`, `Docs/AI`, `skills/`, `.trae/scripts`, and `.trae/tasks`; `skills/codex-project-router` now defines Codex-specific behavior, but there is still no native `.codex/tasks` root. |
| Trae-compatible shared layer | First-class mechanical layer | `.trae/scripts` and `.trae/tasks` are currently the strongest mechanical state/guard layer and are reusable by Codex and OpenCode. |

So the accurate answer is:

**OpenCode has the most complete native integration. Codex now has a dedicated adapter skill and can use the workflow through the shared repository docs, skills, and `.trae/scripts` mechanical gates, but it is still missing a native `.codex/tasks` runtime root.**

## What The Current Workflow Contains

> **Status note: Historical compatibility report. Partially superseded by Docs/AI/33 and Docs/AI/34. Codex sync scripts now in engine/_experimental/, not .trae/scripts/.**

The active workflow is a Comet-style phase system:

```text
Plan -> Implement -> Review -> Verify -> Archive
```

Core components:

| Component | Location | Function |
|---|---|---|
| Global entrypoint docs | `AGENTS.md`, `Docs/AI/README.md`, `Docs/AI/27-AI-Workflow-Refactor-Manifest.md` | Tell agents where truth lives. |
| Router | `skills/ue-project-router/SKILL.md`, `.opencode/agents/ue-project-router.md` | Classifies project type, phase, skills, and task structure. |
| Task state | `.trae/scripts/task-state.ps1`, `.opencode/scripts/task-state.ps1` | Phase state and edit authorization. |
| Phase guard | `.trae/scripts/task-guard.ps1` | Mechanical exit gate for phase transitions. |
| Living spec | `skills/spec-living/SKILL.md`, `.trae/scripts/spec-living.ps1` | Keeps `spec.md` as runtime state, not just static docs. |
| Doc governance | `skills/doc-governance/SKILL.md`, `.trae/scripts/doc-guard.ps1` | Requires project docs and doc-impact evidence. |
| Mature solution gate | `Docs/AI/29-Mature-Solution-First-Workflow.md`, `.trae/scripts/task-guard.ps1` | Blocks MVP/reduced-quality plans unless explicitly approved. |
| Regression | `.trae/scripts/test-workflow-regression.ps1` | Checks phase gates and docs indexes. |

## Current OpenCode Integration

> **Status note: Historical compatibility report. Partially superseded by Docs/AI/33 and Docs/AI/34. Codex sync scripts now in engine/_experimental/, not .trae/scripts/.**

OpenCode is currently the best supported native workflow target.

Evidence:

- `.opencode/rules/project_rules.md` defines OpenCode-specific behavior.
- `.opencode/agents/*.md` defines first-class agent roles:
  - `ue-project-router`
  - `ue-lyra-gas-implementer`
  - `ue-ai-validator`
  - `code-quality-reviewer`
  - `web-implementer`
  - `character-designer`
- `.opencode/scripts/task-state.ps1` exists as an OpenCode-compatible state checker.
- `.opencode/tasks/README.md` defines the OpenCode task file format.
- OpenCode agents explicitly support fallback to `.trae/tasks` for shared context.

Weakness:

- OpenCode rules say OpenCode should not modify `.trae/` in normal operation, but several shared guards live in `.trae/scripts`. That is acceptable for read/execute shared scripts, but the rule should be clarified to mean "do not edit `.trae/` workflow files unless explicitly doing global workflow maintenance."

## Current Codex Integration

> **Status note: Historical compatibility report. Partially superseded by Docs/AI/33 and Docs/AI/34. Codex sync scripts now in engine/_experimental/, not .trae/scripts/.**

Codex can use the workflow, but the support is mostly through shared repository conventions rather than a Codex-native workflow package.

Evidence:

- `AGENTS.md` is the Codex-readable entrypoint in this workspace.
- `AGENTS.md` points Codex to `Docs/AI`, `Docs/Memory`, `skills/`, and shared scripts.
- Codex has access to the same `skills/` directory used by the current session.
- `.trae/scripts/task-guard.ps1`, `task-state.ps1`, `spec-living.ps1`, and `doc-guard.ps1` can be run from Codex.
- `.trae/scripts/sync-codex-state.ps1` and `.trae/scripts/sync-codex-merge.py` exist, but they only synchronize Codex conversation state, not workflow phases.
- `skills/codex-project-router/SKILL.md` now defines Codex-specific workflow behavior.
- `.codex/shared` exists, but `.codex` currently has no native task root.

Practical Codex workflow today:

```text
Codex reads AGENTS.md
-> reads Docs/AI/27 and Docs/AI/29
-> uses skills/ue-project-router/SKILL.md as the router rule
-> writes/reads .trae/tasks/<scope>/<task>/*
-> runs .trae/scripts/task-state.ps1 and task-guard.ps1
-> runs implementation/review/verify according to shared docs
```

This works because Codex is file-and-command capable. The new adapter skill makes the rules explicit, but Codex still uses `.trae/tasks` until a native `.codex/tasks` root exists.

## What Is Truly Shared

> **Status note: Historical compatibility report. Partially superseded by Docs/AI/33 and Docs/AI/34. Codex sync scripts now in engine/_experimental/, not .trae/scripts/.**

The following are tool-agnostic and should be treated as shared truth:

- `Docs/AI/*`
- `Docs/Memory/*`
- `skills/*`
- `.trae/scripts/*` when used as shared mechanical tooling
- Project code under `Project/*`
- Runtime task file contract:
  - `.task.yaml`
  - `routing.md`
  - `spec.md`
  - `tasks.md`
  - `analysis.md`
  - `doc-impact.md`

These are usable by both Codex and OpenCode.

## What Is Platform-Specific

> **Status note: Historical compatibility report. Partially superseded by Docs/AI/33 and Docs/AI/34. Codex sync scripts now in engine/_experimental/, not .trae/scripts/.**

| Area | OpenCode | Codex |
|---|---|---|
| Native agent definitions | `.opencode/agents/*.md` | Not present |
| Native rules file | `.opencode/rules/project_rules.md` | `AGENTS.md` only |
| Native task root | `.opencode/tasks` | Not present; uses `.trae/tasks` through adapter |
| State sync | `.opencode/scripts/task-state.ps1` | Codex conversation DB sync only |
| Mechanical guards | Uses shared `.trae/scripts` | Uses shared `.trae/scripts` |
| Skill loading | OpenCode agent/skill convention | Codex skill system and repository `skills/` |

## Key Finding: The Mechanical Gate Is Shared, But The UX Is Not

> **Status note: Historical compatibility report. Partially superseded by Docs/AI/33 and Docs/AI/34. Codex sync scripts now in engine/_experimental/, not .trae/scripts/.**

The most important enforcement is not OpenCode-specific:

- `task-guard.ps1 plan` checks routing, tasks, spec, analysis, doc-impact, user confirmation, router proof, and mature solution evidence.
- `doc-guard.ps1` checks documentation governance.
- `test-workflow-regression.ps1` verifies gates.

Those scripts are shared and can be run by Codex.

But the user experience is OpenCode-first:

- OpenCode has named agents and role files.
- Codex currently relies on `AGENTS.md` plus `skills/codex-project-router`.
- Codex still does not have a native task root, so the adapter maps Codex to `.trae/tasks`.

## Current Risks

> **Status note: Historical compatibility report. Partially superseded by Docs/AI/33 and Docs/AI/34. Codex sync scripts now in engine/_experimental/, not .trae/scripts/.**

### Risk 1: Codex can bypass the phase model unless reminded

> **Status note: Historical compatibility report. Partially superseded by Docs/AI/33 and Docs/AI/34. Codex sync scripts now in engine/_experimental/, not .trae/scripts/.**

Codex can read the workflow, but nothing Codex-native forces it to create task files before editing. The shared `task-guard.ps1` catches phase transitions, but Codex could still perform direct edits unless the instruction layer is explicit enough.

Mitigation:

- Add a Codex-specific workflow adapter document or skill that says: "for project tasks, use `.trae/tasks` and run `task-state.ps1 can-edit` before edits."

### Risk 2: OpenCode and Trae separation wording conflicts with shared scripts

> **Status note: Historical compatibility report. Partially superseded by Docs/AI/33 and Docs/AI/34. Codex sync scripts now in engine/_experimental/, not .trae/scripts/.**

Docs say workflows are independent and should not modify each other, but `.trae/scripts` is also described as shared tooling. This can confuse agents.

Mitigation:

- Clarify: `.trae/scripts` is shared executable infrastructure; `.trae/tasks` and `.opencode/tasks` are separate runtime state roots unless explicitly sharing/fallback.

### Risk 3: Mature Solution Gate is enforced only on `.trae/tasks`

> **Status note: Historical compatibility report. Partially superseded by Docs/AI/33 and Docs/AI/34. Codex sync scripts now in engine/_experimental/, not .trae/scripts/.**

`task-guard.ps1` currently resolves `.trae/tasks`. If OpenCode keeps task state only in `.opencode/tasks`, the hard guard may not inspect it unless the task is mirrored or resolved through shared paths.

Mitigation:

- Either mirror OpenCode tasks into `.trae/tasks`, or update `task-guard.ps1` to resolve both `.trae/tasks` and `.opencode/tasks`.

### Risk 4: Codex state sync is unrelated to workflow state

> **Status note: Historical compatibility report. Partially superseded by Docs/AI/33 and Docs/AI/34. Codex sync scripts now in engine/_experimental/, not .trae/scripts/.**

`sync-codex-state.ps1` and `sync-codex-merge.py` manage Codex conversation/session state only. They do not synchronize task phase, routing, or verification evidence.

Mitigation:

- Do not describe Codex sync as workflow integration. It is session portability only.

## Recommendations

> **Status note: Historical compatibility report. Partially superseded by Docs/AI/33 and Docs/AI/34. Codex sync scripts now in engine/_experimental/, not .trae/scripts/.**

### P0: Add a Codex workflow adapter

> **Status note: Historical compatibility report. Partially superseded by Docs/AI/33 and Docs/AI/34. Codex sync scripts now in engine/_experimental/, not .trae/scripts/.**

Completed by:

```text
skills/codex-project-router/SKILL.md
```

Purpose:

- Treat `AGENTS.md` + `Docs/AI/27` + `Docs/AI/29` as required entry.
- Use `.trae/tasks` as Codex runtime task root until `.codex/tasks` exists.
- Require `task-state.ps1 can-edit` before file edits.
- Require `task-guard.ps1 plan` before implement.
- Map OpenCode agent roles to Codex skills/subagents:
  - `ue-project-router` -> `skills/ue-project-router/SKILL.md`
  - `ue-lyra-gas-implementer` -> relevant UE skills
  - `code-quality-reviewer` -> Codex review stance plus shared checklists

### P1: Make task-guard multi-root

> **Status note: Historical compatibility report. Partially superseded by Docs/AI/33 and Docs/AI/34. Codex sync scripts now in engine/_experimental/, not .trae/scripts/.**

Completed for `task-guard.ps1` and `doc-guard.ps1`. They now resolve:

1. `.trae/tasks/<scope>/<task>`
2. `.opencode/tasks/<task>`
3. future `.codex/tasks/<task>`

This makes the mechanical mature-solution gate platform-neutral.

### P1: Update `AGENTS.md`

> **Status note: Historical compatibility report. Partially superseded by Docs/AI/33 and Docs/AI/34. Codex sync scripts now in engine/_experimental/, not .trae/scripts/.**

The current `AGENTS.md` lists Trae and OpenCode, and mentions Codex skills, but does not clearly answer how Codex should run the workflow.

Add a short Codex row:

| IDE | Config | Skill source | Scripts | Task root |
|---|---|---|---|---|
| Codex | `AGENTS.md` + `skills/` | `skills/` | `.trae/scripts/` shared | `.trae/tasks/` until Codex adapter exists |

### P2: Create a compatibility regression

> **Status note: Historical compatibility report. Partially superseded by Docs/AI/33 and Docs/AI/34. Codex sync scripts now in engine/_experimental/, not .trae/scripts/.**

Add tests for:

- Codex-style task in `.trae/tasks` passes `task-guard`.
- OpenCode-style task either mirrors to `.trae/tasks` or is accepted by multi-root `task-guard`.
- A task missing `Mature Solution Evidence` fails regardless of originating platform.

## Answer To The User Question

> **Status note: Historical compatibility report. Partially superseded by Docs/AI/33 and Docs/AI/34. Codex sync scripts now in engine/_experimental/, not .trae/scripts/.**

The current workflow is **usable by both Codex and OpenCode**, but not equally.

- **OpenCode**: first-class, agent-driven, native files exist.
- **Codex**: can use the same workflow through `AGENTS.md`, `Docs/AI`, `skills/codex-project-router`, and shared `.trae/scripts`; still not fully native because there is no `.codex/tasks` root.
- **The real enforcement layer** is `.trae/scripts`, especially `task-guard.ps1`; that layer is shared and not inherently OpenCode-only.

Therefore, the next improvement should be making Codex first-class rather than duplicating the whole workflow.
