# Analysis: AI Workflow Registry

## Mature Solution Evidence

### Existing patterns in this codebase

1. **Skill system** (`skills/` + `SKILL.md`) — already the canonical discovery mechanism. Every AI tool that Codex can use is registered as a skill with a SKILL.md frontmatter (name, description, trigger). This is the closest existing "service registry".

2. **Hermes profile skills** (`.tools/hermes-worker/profiles/jinli-implementer/skills/`) — a parallel skill tree for the Hermes agent, but invisible to Codex's skill discovery.

3. **`find-skills` skill** — exists in `skills/find-skills/SKILL.md` but is a concept shell with no search logic.

4. **`task-orchestrator`** — auto-detects task type and selects skill stacks, but has no concept of "AI workflow" as a distinct category.

5. **`Docs/workflow/README.md`** — indexes AI development workflow documents, not runnable AI workflows.

6. **vsummary's existing status tracking** — `~/.vsummary/provider_state.json` and `data/workflow_report.json` are ad-hoc status files, not integrated into any discovery system.

### Industry patterns

- **MCP (Model Context Protocol)** — tools self-describe via JSON schema. Codex already uses this for MCP servers.
- **OpenAPI/Swagger** — service registry with machine-readable spec.
- **Homebrew formula / npm package.json** — decentralized registry + per-package metadata.

### Decision: Extend the existing skill system

The most framework-consistent approach is to treat "AI workflows" as a **category of skills** with additional conventions, NOT a separate system. This means:

- Workflows live in `skills/` (where they already belong per File Placement Convention)
- Each workflow has a `SKILL.md` with standard frontmatter + workflow-specific extensions
- A single `registry.yaml` provides the overview index
- Status is tracked in a `status.yaml` alongside each workflow's SKILL.md

This avoids introducing a new top-level directory or a new concept that competes with skills.

## Architecture Context

### System boundaries

```
skills/                           ← existing skill tree (70+ skills)
  ai-workflow-registry/           ← NEW: discovery skill (the registry itself)
    SKILL.md                      ← how to discover workflows
  vsummary/                       ← NEW: workflow skill (migrated from hermes)
    SKILL.md                      ← self-contained usage guide
    status.yaml                   ← auto-maintained runtime status
    references/                   ← supplementary docs (symlinks or copies)
  ai-drama/                       ← FUTURE: another workflow skill
    SKILL.md
    status.yaml
```

### Dependency map

```
AGENTS.md
  └─ references ai-workflow-registry SKILL.md (discovery protocol)
task-orchestrator SKILL.md
  └─ adds "AI Workflow" detection rule + routing to registry
sync-workflow-registry.ps1
  └─ reads each workflow's status.yaml → updates registry.yaml
  └─ called by workflow scripts on completion
vsummary workflow.py
  └─ calls sync-workflow-registry.ps1 after each run
```

### Data and state ownership

| Data | Owner | Location |
|------|-------|----------|
| Workflow registry index | `registry.yaml` | `skills/ai-workflow-registry/registry.yaml` |
| Per-workflow status | Each workflow's `status.yaml` | `skills/<workflow-name>/status.yaml` |
| Per-workflow instructions | Each workflow's `SKILL.md` | `skills/<workflow-name>/SKILL.md` |
| Auto-sync script | `sync-workflow-registry.ps1` | `.trae/scripts/sync-workflow-registry.ps1` |

### Integration points

1. **AGENTS.md** — add "AI Workflow Discovery Protocol" section pointing to registry
2. **task-orchestrator** — add detection rule for workflow-related requests
3. **vsummary** — proof-of-concept: existing vsummary-batch SKILL.md migrates to `skills/vsummary/`
4. **Hermes profiles** — can keep their own copies; the `skills/` versions are the canonical discoverable ones

## Key Design Decisions

### D1: Where do workflow SKILL.md files live?

**Decision**: `skills/<workflow-name>/SKILL.md`

**Rationale**: File Placement Convention explicitly states skills go in `.trae/skills/` (junction to `skills/`). This is the only discoverable location for Codex. Creating a separate `ai-workflows/` directory would require a new discovery mechanism.

### D2: How is status auto-maintained?

**Decision**: Each workflow writes its own `status.yaml` on completion. A lightweight PowerShell script `sync-workflow-registry.ps1` aggregates all `status.yaml` files into the central `registry.yaml`.

**Rationale**: 
- Workflows already have scripts (e.g., `workflow.py`). Adding a status write at the end is trivial.
- The sync script is a simple directory scan — no complex dependencies.
- This avoids a central service that could go down.

### D3: How to handle the Hermes profile duplication?

**Decision**: `skills/<workflow-name>/SKILL.md` is the **canonical** version. Hermes profile copies are secondary and may diverge. The registry only tracks the canonical version.

**Rationale**: Hermes profiles are agent-specific overlays. The project needs an agent-agnostic source of truth.

### D4: How does a model discover workflows?

**Decision**: Two-level discovery:
1. **Quick scan**: Read `skills/ai-workflow-registry/registry.yaml` — lists all workflows, their status, and one-line descriptions
2. **Deep dive**: Read `skills/<workflow-name>/SKILL.md` — full usage instructions

The registry.yaml is referenced from AGENTS.md so any model entering the workspace sees it immediately.

### D5: What does status.yaml contain?

**Decision**:
```yaml
name: vsummary
last_run: 2026-06-22T14:30:00
status: idle          # idle | running | completed | error
progress: "218/232 videos summarized (94%)"
provider: MiniMax-M1  # current active provider, if applicable
next_steps: "4 failed videos need retry; 10 skipped (no audio)"
error: null
updated_by: workflow.py
```

Minimal, machine-writable, human-readable.

## Acceptance Criteria

- AC01: `skills/ai-workflow-registry/SKILL.md` exists with discovery protocol
- AC02: `skills/ai-workflow-registry/registry.yaml` lists all AI workflows with name, status, description, skill_path
- AC03: `skills/vsummary/SKILL.md` exists as a self-contained, discoverable workflow guide (derived from hermes profile version)
- AC04: `skills/vsummary/status.yaml` reflects actual vsummary runtime state
- AC05: `.trae/scripts/sync-workflow-registry.ps1` exists and correctly aggregates status.yaml files into registry.yaml
- AC06: AGENTS.md contains an "AI Workflow Discovery" section referencing the registry
- AC07: `skills/task-orchestrator/SKILL.md` includes workflow detection and routing rules
- AC08: A new workflow can be added by: create `skills/<name>/SKILL.md` + `skills/<name>/status.yaml` + add entry to registry.yaml — no other files need modification

## Automated Verification Plan

1. `sync-workflow-registry.ps1` runs without error and produces valid registry.yaml
2. registry.yaml contains entry for vsummary with correct status fields
3. Reading `skills/vsummary/SKILL.md` provides sufficient instructions to run vsummary without reading hermes profile version
4. AGENTS.md contains the string "ai-workflow-registry" or "AI Workflow Discovery"
5. task-orchestrator SKILL.md contains "workflow" detection rule
