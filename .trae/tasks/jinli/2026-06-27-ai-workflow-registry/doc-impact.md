# Doc Impact: AI Workflow Registry

## Changed Documentation

| File | Change Type | Description |
|------|------------|-------------|
| `AGENTS.md` | Modify | Add "AI Workflow Discovery" section pointing to registry |
| `skills/task-orchestrator/SKILL.md` | Modify | Add workflow detection rule to Detection Rules table |

## New Documentation

| File | Description |
|------|-------------|
| `skills/ai-workflow-registry/SKILL.md` | Discovery protocol — how to find and use AI workflows |
| `skills/ai-workflow-registry/registry.yaml` | Machine-readable workflow index |
| `skills/vsummary/SKILL.md` | Self-contained vsummary workflow guide |
| `skills/vsummary/status.yaml` | Auto-maintained vsummary runtime status |

## New Scripts

| File | Description |
|------|-------------|
| `.trae/scripts/sync-workflow-registry.ps1` | Aggregates status.yaml → registry.yaml |

## No Impact

- `Project/` — no game code changes
- `.tools/hermes-worker/` — not modified, only read as reference
- `Docs/AI/` — no changes to existing AI workflow docs
- Core gate scripts — not modified
