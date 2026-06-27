# Routing: AI Workflow Registry

## Requirement Classification

**Classification**: deep-discovery

**Reason**: This is a new system-level capability — an "AI workflow service discovery" mechanism. It affects how all future AI models interact with the project, introduces new file conventions, and has cross-cutting impact on AGENTS.md, skill discovery, and task-orchestrator. Not a bounded fix.

## Project

- **Project**: _shared (infrastructure, cross-project)
- **System**: AI workflow management / skill discovery
- **Owner**: jinli (Codex as lead)

## Entry Analysis

User wants:
1. Any AI model entering the workspace can **automatically discover** what AI workflows exist
2. Each workflow's **usage instructions** are self-contained and discoverable
3. **Current progress/status** of each workflow is visible without manual investigation
4. The system is **auto-maintained** — running a workflow updates its status automatically
5. **Extensible** — new workflows follow the same pattern, no special-casing

## Primary Skill

- `codex-project-router` (infrastructure task, cross-project)

## Secondary Skills

- `writing-skills` (creating new skill definitions)
- `spec-living` (living spec pattern for workflow status)
- `task-orchestrator` (needs update for workflow routing)

## Quality Gate

- Any model (Codex, Trae, OpenCode, or other) can find all available AI workflows by reading a single registry file
- Each workflow has a self-contained SKILL.md that is sufficient to execute the workflow without additional context
- Running a workflow automatically updates its status in the registry
- Adding a new workflow requires only: create directory + SKILL.md + register in registry.yaml

## Work Package Policy

- Single agent (Codex as lead), no worker delegation needed
- All files are in `skills/` and `Docs/` — no project code changes
- Work packages: WP01 (registry spec + SKILL.md), WP02 (auto-maintain script), WP03 (AGENTS.md + orchestrator update), WP04 (vsummary migration as proof)

## Documents to Read

1. `Docs/AI/13-File-Placement-Convention.md` — skill placement rules
2. `Docs/AI/11-Skill-Routing-Workflow.md` — existing routing patterns
3. `skills/task-orchestrator/SKILL.md` — needs workflow detection
4. `skills/find-skills/SKILL.md` — existing (minimal) skill discovery
5. `.tools/hermes-worker/profiles/jinli-implementer/skills/local-ai-tools/vsummary-batch/SKILL.md` — reference workflow
6. `.tools/hermes-worker/profiles/jinli-implementer/skills/local-ai-tools/vsummary-deploy/SKILL.md` — reference workflow

## Forbidden Paths

- `Project/` — no game code changes
- `.tools/hermes-worker/` — read-only reference, do not modify
- `.trae/scripts/task-state.ps1`, `task-guard.ps1`, `contract-verify.ps1` — do not modify core scripts
