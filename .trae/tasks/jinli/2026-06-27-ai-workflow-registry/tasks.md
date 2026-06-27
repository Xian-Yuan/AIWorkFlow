# Tasks: AI Workflow Registry

## WP01: Create ai-workflow-registry skill + registry.yaml

- [ ] Create `skills/ai-workflow-registry/SKILL.md` with discovery protocol
- [ ] Create `skills/ai-workflow-registry/registry.yaml` with initial workflow entries
- [ ] SKILL.md must specify: how to discover workflows, how to read status, how to add new workflows
- [ ] registry.yaml schema: name, description, status, skill_path, last_run, trigger_keywords

## WP02: Create auto-maintain script

- [ ] Create `.trae/scripts/sync-workflow-registry.ps1`
- [ ] Script scans `skills/*/status.yaml` files
- [ ] Aggregates into `skills/ai-workflow-registry/registry.yaml`
- [ ] Preserves manual entries that have no status.yaml
- [ ] Idempotent — safe to run multiple times
- [ ] Can be called from workflow completion hooks

## WP03: Migrate vsummary as proof-of-concept

- [ ] Create `skills/vsummary/SKILL.md` — self-contained guide derived from hermes profile version
- [ ] Create `skills/vsummary/status.yaml` — initial status reflecting current vsummary state
- [ ] SKILL.md must be sufficient to run vsummary without reading hermes profile version
- [ ] Include: environment prerequisites, core workflow, provider config, pitfall list, progress query

## WP04: Update AGENTS.md + task-orchestrator

- [ ] Add "AI Workflow Discovery" section to AGENTS.md
- [ ] Add workflow detection rule to task-orchestrator SKILL.md Detection Rules table
- [ ] AGENTS.md section must reference `skills/ai-workflow-registry/registry.yaml`
- [ ] Orchestrator rule: "summarize video" / "vsummary" / "batch summarize" → route to vsummary workflow

## Verification

- [ ] Run `sync-workflow-registry.ps1` — produces valid registry.yaml
- [ ] registry.yaml contains vsummary entry with correct fields
- [ ] Reading `skills/vsummary/SKILL.md` provides complete vsummary instructions
- [ ] AGENTS.md contains "AI Workflow Discovery" section
- [ ] task-orchestrator contains workflow detection rule
- [ ] Test: simulate adding a new workflow (create SKILL.md + status.yaml + registry entry) — no other files need changes
