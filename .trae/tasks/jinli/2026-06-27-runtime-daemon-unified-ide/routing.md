# Routing Decision

## Task

jinli/2026-06-27-runtime-daemon-unified-ide

## Project Type

other

## Requirement Classification: deep-discovery

- This is a new runtime architecture and workflow integration task.
- It changes service lifecycle ownership, data ownership boundaries, MCP routing, and multi-IDE configuration.
- It affects multiple systems: Project/Jinli Python services, MCP plugin, PowerShell scripts, Codex/OpenCode/Trae config, and documentation.

## Main Skill

codex-project-router

## Secondary Skills

- smart-requirements
- web-fullstack or web-engineer only if an HTTP API or small local dashboard is implemented later
- code-quality-reviewer for Review phase
- code-verifier for Verify phase

## Quality Gate

- Default quality level: Mature production-grade
- MVP/prototype requested by user: no
- Quality Exception: none
- Mature Solution Evidence: analysis.md#Mature-Solution-Evidence
- Rejected shortcuts reviewed: yes
- User confirmation must include quality level: yes
- Implementation completeness: runtime daemon, MCP adapter migration, IDE sync, diagnostics, docs, and verification must all be addressed.

## Work Package Policy

- External workers: yes
- Task packet root: .trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide
- Work packages required: yes
- Claim files required: yes
- Worker reports required before merge: yes
- Lead owns architecture: yes
- Workers may edit only paths listed in their work package.
- Workers must not edit .task.yaml, routing.md, analysis.md, requirements.md, execution-prompt.md, spec.md, tasks.md, acceptance criteria, or verification state unless a later lead-issued repair package explicitly permits it.

## Requirement Discovery Gate

- Plain-language summary confirmed: yes
- Unresolved high-impact questions: none
- Requirement source: requirements.md
- Implementation entry blocked until Ba Ba explicitly confirms this full task packet and the `.task.yaml` field `user_confirmed_plan` is set to true.

## Architecture Route

This task routes to the Jinli infrastructure and runtime layer, not to UE5 gameplay, web app UI, or content-generation service work.

### In Scope

- `Project/Jinli/services/runtime/**`
- `Project/Jinli/services/jinli_service.py`
- `Project/Jinli/services/jinli_daemon.py`
- `Project/Jinli/services/**` adapters needed for lifecycle and health wiring
- `C:/Users/87372/plugins/jinli-soul-core/mcp/**`
- `.trae/scripts/jinli-*.ps1`
- `.trae/scripts/validate-codex-capabilities.ps1` and related capability validation scripts, only if required for IDE drift checks
- `.opencode/mcp.json`, `opencode.json`, Codex plugin/marketplace metadata scripts, and future IDE registry files
- `Project/Jinli/docs/**`, `Docs/AI/**`, and `AGENTS.md` updates required to document the runtime contract

### Out of Scope

- UE5 RTS gameplay systems
- CharacterDesignTool feature changes
- New voice/avatar/mobile/WeChat implementations
- Remote cloud deployment
- Removing legacy Soul Core files
- Replacing the project task-state or authority gate framework

## Collaboration Mode

Multi-agent task packet with one lead planner/verifier and bounded worker packages.

## Authority Policy

- Authority profile: none
- Packet mutation authority: lead only
- Review authority: lead reviewer only
- Verify authority: lead verifier only
- Archive authority: lead only
- Verify auto-archive: forbidden

## Phase Notes

- Plan phase may write task-packet files only.
- Project implementation files must not be edited until contract verify, task guard, and can-edit gates pass.
- The current packet is intentionally not implement-ready until Ba Ba confirms the selected mature path.
