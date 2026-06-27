---
name: ai-workflow-registry
version: 1.0.0
description: AI workflow discovery and registration system. Any model entering the workspace can find all available AI workflows, check their status, and learn how to use them. Read registry.yaml for the full index.
trigger: user asks about available AI workflows, wants to run a workflow, asks "what can you do", or any model needs to discover workflow capabilities
---

# AI Workflow Registry

## Purpose

This skill is the **single entry point** for AI workflow discovery. Any model (Codex, Trae, OpenCode, or other) entering this workspace can read `registry.yaml` to find all available AI workflows, their current status, and how to use them.

## Discovery Protocol

### Step 1: Read the registry

```
Read: skills/ai-workflow-registry/registry.yaml
```

This file lists every registered AI workflow with:
- `name` — workflow identifier
- `description` — one-line summary
- `status` — current runtime status (idle/running/completed/error)
- `skill_path` — path to the self-contained SKILL.md
- `last_run` — ISO timestamp of last execution
- `trigger_keywords` — words that should route to this workflow

### Step 2: Read the workflow's SKILL.md

For any workflow you want to use, read its `skill_path` (e.g., `skills/vsummary/SKILL.md`). This file is **self-contained** — it includes all prerequisites, commands, pitfall lists, and status query instructions. You do not need any other context.

### Step 3: Check status (optional)

Each workflow has a `status.yaml` alongside its SKILL.md. Read it for:
- Current progress (e.g., "218/232 videos summarized")
- Active provider (if applicable)
- Last error
- Next steps

## How to Add a New Workflow

Adding a new AI workflow requires exactly three steps:

### 1. Create the workflow skill directory

```
skills/<workflow-name>/
  SKILL.md          # Self-contained usage guide
  status.yaml       # Auto-maintained runtime status
  references/       # Optional: supplementary docs
```

### 2. Write SKILL.md

Follow this template:

```yaml
---
name: <workflow-name>
version: 1.0.0
description: One-line description of what this workflow does
trigger: keywords or phrases that should route to this workflow
---
```

Then include these sections:
- **Environment Prerequisites** — what must be installed/running
- **Core Workflow** — step-by-step commands to execute
- **Provider Configuration** — if the workflow uses LLM providers
- **Progress Query** — how to check current status
- **Pitfall List** — known issues and workarounds
- **Status Auto-Update** — how the workflow updates its status.yaml

### 3. Register in registry.yaml

Add an entry to `skills/ai-workflow-registry/registry.yaml`:

```yaml
- name: <workflow-name>
  description: "One-line description"
  status: idle
  skill_path: skills/<workflow-name>/SKILL.md
  last_run: null
  trigger_keywords:
    - keyword1
    - keyword2
```

That's it. No other files need modification. The `sync-workflow-registry.ps1` script will pick up the `status.yaml` automatically.

## Status Auto-Maintenance

### How it works

1. Each workflow script writes its own `status.yaml` on completion (or on error)
2. `.trae/scripts/sync-workflow-registry.ps1` scans all `skills/*/status.yaml` files
3. It aggregates them into `skills/ai-workflow-registry/registry.yaml`
4. The sync script is idempotent — safe to run multiple times

### status.yaml schema

```yaml
name: <workflow-name>
last_run: <ISO timestamp>
status: idle|running|completed|error
progress: "<human-readable progress summary>"
provider: <current active provider, or null>
next_steps: "<what needs to happen next>"
error: <last error message, or null>
updated_by: <script or model that wrote this>
updated_at: <ISO timestamp>
```

### Integration pattern

At the end of any workflow script, add:

```python
# Write status.yaml
import yaml
from datetime import datetime
status = {
    "name": "vsummary",
    "last_run": datetime.now().isoformat(),
    "status": "completed",
    "progress": f"{done}/{total} videos summarized ({pct}%)",
    "provider": current_provider,
    "next_steps": next_steps,
    "error": None,
    "updated_by": "workflow.py",
    "updated_at": datetime.now().isoformat(),
}
with open("skills/vsummary/status.yaml", "w") as f:
    yaml.dump(status, f, allow_unicode=True, default_flow_style=False)
```

Then run the sync script:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\sync-workflow-registry.ps1
```

## Registry Location

- **Registry**: `skills/ai-workflow-registry/registry.yaml`
- **Sync script**: `.trae/scripts/sync-workflow-registry.ps1`
- **This skill**: `skills/ai-workflow-registry/SKILL.md`

## Related Skills

- `task-orchestrator` — routes user requests to the correct workflow
- `find-skills` — general skill discovery (workflows are a subset of skills)
