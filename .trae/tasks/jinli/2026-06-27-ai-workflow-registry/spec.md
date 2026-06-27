# AI Workflow Registry — Living Spec

## Quick Status (AI Entry Point)

- **Current Phase**: Plan
- **Last Updated**: 2026-06-27
- **Progress**: 0/8 acceptance criteria verified
- **Next Step**: Complete Plan gate, then implement

## GIVEN

The project has multiple AI workflows (vsummary video summarization, AI drama production, etc.) but they are scattered across different locations:
- vsummary skills live in `.tools/hermes-worker/profiles/jinli-implementer/skills/local-ai-tools/`
- AI drama skills live in `Project/AIDramaProducer/skills/`
- No unified index exists
- No model entering the workspace can discover what workflows are available without prior knowledge
- Workflow status (progress, errors, last run) is not centrally tracked

## WHEN

An AI model (Codex, Trae, OpenCode, or any other) enters the workspace and needs to:
- Find what AI workflows are available
- Execute a specific workflow
- Check the current status/progress of a workflow
- Add a new workflow to the system

## THEN

1. The model reads `skills/ai-workflow-registry/registry.yaml` and sees a complete list of all AI workflows with their current status
2. The model reads `skills/<workflow-name>/SKILL.md` and gets self-contained instructions sufficient to execute the workflow
3. After a workflow runs, its `status.yaml` is automatically updated
4. `sync-workflow-registry.ps1` aggregates all status.yaml files into registry.yaml
5. Adding a new workflow requires only: create `skills/<name>/SKILL.md` + `skills/<name>/status.yaml` + register in registry.yaml

## Acceptance Criteria

- AC01: `skills/ai-workflow-registry/SKILL.md` exists with discovery protocol
- AC02: `skills/ai-workflow-registry/registry.yaml` lists all AI workflows with name, status, description, skill_path
- AC03: `skills/vsummary/SKILL.md` exists as a self-contained, discoverable workflow guide
- AC04: `skills/vsummary/status.yaml` reflects actual vsummary runtime state
- AC05: `.trae/scripts/sync-workflow-registry.ps1` exists and correctly aggregates status.yaml files into registry.yaml
- AC06: AGENTS.md contains an "AI Workflow Discovery" section referencing the registry
- AC07: `skills/task-orchestrator/SKILL.md` includes workflow detection and routing rules
- AC08: A new workflow can be added by: create `skills/<name>/SKILL.md` + `skills/<name>/status.yaml` + add entry to registry.yaml — no other files need modification

## Quality Checklist

- [ ] All new files follow File Placement Convention (skills/ for SKILL.md, .trae/scripts/ for scripts)
- [ ] No modifications to Project/ code
- [ ] No modifications to core .trae/scripts/ gate scripts
- [ ] registry.yaml is valid YAML
- [ ] status.yaml schema is documented and consistent
- [ ] SKILL.md frontmatter follows existing conventions (name, description, trigger)
