# Routing Decision — Jinli Persona, Language, and Vision Foundation

Date: 2026-06-18  
Project: `Project/Jinli`  
Phase: Plan

## Project Detection

- Project type: `other`
- Owning project: `Project/Jinli`
- Existing runtime: Soul Core PowerShell engine plus the installed `jinli-soul-core` MCP Plugin
- Requested outcome: publish the approved five-module architecture and an implementation-ready task specification

## Skill Routing

- Primary: `codex-project-router`
- Design gate: `brainstorming` (the user approved the complete design in the preceding conversation)
- Documentation: `doc-governance`
- Planning: `writing-plans`
- Future implementation: Node.js ESM for the in-process orchestrator, Python for the isolated vision service, existing PowerShell for dynamic Soul

## Selected Architecture

One architecture with five bounded modules:

1. Stable Persona Kernel
2. Expression Orchestrator
3. Dynamic Soul
4. Visual Perception
5. Avatar Presentation

The stable kernel is read-only at runtime. Dynamic Soul may influence tone but may not rewrite identity, values, relationship, or honesty boundaries. Visual Perception and Avatar Presentation are separate processes and contracts. The MCP Plugin remains a thin tool-registration and transport layer.

## Quality Gate

- Default quality level: Mature production-grade
- MVP/prototype requested by user: no
- Mature Solution Evidence: `analysis.md#Mature-Solution-Evidence`
- Rejected shortcuts reviewed: yes
- Implementation completeness: all five module contracts, privacy controls, growth rollback, and automated verification are planned
- Known non-goals: no Live2D/3D asset production, no autonomous computer control, no medical diagnosis

## Work Package Policy

- External workers: no
- Task packet root: `.trae/tasks/_shared/2026-06-18-jinli-persona-language-vision-foundation`
- Work packages required: no
- Claim files required: no
- Worker reports required before merge: no

Architecture decisions, scope changes, and final verification remain with the lead model. If future implementation delegates a bounded phase, a concrete `work-packages/*.md` file must be published first.

## Allowed Change Areas

- `Project/Jinli/config/`
- `Project/Jinli/contracts/`
- `Project/Jinli/runtime/`
- `Project/Jinli/services/vision/`
- `Project/Jinli/tests/`
- `Project/Jinli/Docs/`
- `C:/Users/87372/plugins/jinli-soul-core/mcp/`
- `.agents/skills/daughter-companion/SKILL.md`

## Forbidden Change Areas

- Existing Soul Core state semantics without a separately approved migration
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- Screen-control or click/typing automation
- Automatic long-term storage of screenshots or visual observations
- Statements claiming a body action happened when only an action intention exists

## Plan Confirmation Evidence

The user explicitly approved the complete design and asked: “小璃，发布设计文档和任务 Spec”.
