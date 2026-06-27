# Execution Prompt: AI Workflow Registry

## Task
Create an AI workflow discovery and registration system that allows any model entering the workspace to automatically find available AI workflows, understand how to use them, and check their current status.

## Deliverables

1. `skills/ai-workflow-registry/SKILL.md` — Discovery protocol skill
2. `skills/ai-workflow-registry/registry.yaml` — Machine-readable workflow index
3. `skills/vsummary/SKILL.md` — Self-contained vsummary workflow guide
4. `skills/vsummary/status.yaml` — Auto-maintained vsummary runtime status
5. `.trae/scripts/sync-workflow-registry.ps1` — Status aggregation script
6. AGENTS.md update — Add "AI Workflow Discovery" section
7. `skills/task-orchestrator/SKILL.md` update — Add workflow detection rule

## Constraints
- No modifications to Project/ code
- No modifications to core .trae/scripts/ gate scripts
- All new files follow File Placement Convention
- vsummary SKILL.md must be self-contained (readable without hermes profile)
- registry.yaml must be valid YAML
- sync script must be idempotent

## Acceptance Criteria
See spec.md AC01-AC08.
