---
name: codex-project-router
description: Codex-specific adapter for the shared UEGameDevelopment AI workflow. Use before Codex plans or edits project/workflow tasks so Codex follows task packets, architecture evidence, and mechanical gates.
---

# Codex Project Router

## Purpose

This skill makes Codex a first-class participant in the shared workflow.

Codex must not rely only on conversational memory. It must convert project work into a task packet and use the shared mechanical gates.

## Required Read Order

Before planning or editing project work, read:

1. `AGENTS.md`
2. `Docs/AI/27-AI-Workflow-Refactor-Manifest.md`
3. `Docs/AI/29-Mature-Solution-First-Workflow.md`
4. `Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md`
5. task-local `routing.md`, `analysis.md`, `spec.md`, `tasks.md`, `doc-impact.md` if a task already exists

## Runtime Task Root

Codex uses `.codex/tasks/` (junction → `.trae/tasks/`). Task packets are shared across Codex, OpenCode, and Trae.

Task names use:

```text
YYYY-MM-DD-<system>-<feature-or-requirement>
```

## Non-Skippable Gates

Codex must not edit project files until:

```powershell
& .\.trae\scripts\task-state.ps1 can-edit <task-name>
```

passes.

Codex must not move from Plan to Implement until:

```powershell
& .\.trae\scripts\task-guard.ps1 <task-name> plan
```

passes.

Codex must not claim a task is complete until:

```powershell
& .\.trae\scripts\task-guard.ps1 <task-name> verify
```

passes, or Codex clearly reports why verification could not be run.

## Architecture Ability Requirements

Every Codex-authored `analysis.md` must include:

```markdown
## Architecture Context

### System boundaries

### Dependency map

### Data and state ownership

### Integration points
```

Codex must explicitly identify:

- which project owns the change
- which system or feature owns the behavior
- which existing modules or docs constrain the design
- which files are allowed to change
- which files are forbidden
- how state flows through the system
- what existing pattern is being reused

If Codex cannot identify those, it must stop in Plan instead of implementing.

## Acceptance And Test Requirements

Every Codex-authored `analysis.md` must include:

```markdown
## Acceptance Criteria
- AC01: ...

## Automated Verification Plan
- Command: ...
- Expected: ...
```

Every Codex-authored `tasks.md` must include:

```markdown
- [ ] Verify selected mature path was implemented and no rejected shortcut was introduced.
- [ ] Run automated verification and record command output in verification-report.md.
- [ ] Map implementation result to Acceptance Criteria in verification-report.md.
```

Every final verification report must contain:

- `## Automated Verification`
- `## Acceptance Criteria`
- `## Architecture Compliance`
- `## Test Evidence`
- `## Residual Risk`

## Multi-Agent Delegation

Codex may delegate simple work to other models only through `work-packages/*.md`.

Codex remains responsible for:

- architecture decisions
- task packet creation
- work package boundaries
- report review
- final verification

Worker models may own:

- a single work package
- bounded file edits
- focused tests
- evidence gathering
- documentation updates

Worker models must not own:

- system architecture
- final acceptance
- quality exceptions
- rejected shortcut reversal

## Output Contract

When Codex finishes a project task, final response must include:

- task packet path
- changed files
- verification commands run
- whether `task-guard.ps1 verify` passed
- any remaining risk

If verification is not run, Codex must say why.
