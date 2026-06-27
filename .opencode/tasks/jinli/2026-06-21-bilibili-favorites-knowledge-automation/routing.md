# Routing: Bilibili Favorites Knowledge Automation

## Router Decision

- Project: Jinli
- Project type: other
- System: KnowledgeGraph
- Main skill: codex-project-router
- Secondary skills: smart-requirements, doc-governance, test-driven-development, verification-before-completion
- Collaboration mode: DS4 Flash executes bounded work packages; Codex owns architecture, integration review, and final verification.
- Task packet root: `.trae/tasks/jinli/2026-06-21-bilibili-favorites-knowledge-automation`
- Parent runtime dependency: `.trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation`

## Requirement Discovery Gate

- Plain-language summary confirmed: yes
- Unresolved high-impact questions: none
- Confirmation source: original end-to-end workflow request plus the explicit 2026-06-21 instruction to repair Key first and then complete this task packet.

## Selected Runtime Path

- Add a Bilibili favorites orchestration layer to the Jinli Python knowledge service.
- Reuse vsummary for local transcription and structured summarization.
- Use SQLite as the authoritative stage ledger and atomic Markdown as the human-readable accepted artifact.
- Use `G:\JinliVideoCache` as the configurable default media cache after runtime physical-disk verification.
- Reuse the canonical knowledge runtime records and `E:\ObsidianVault\JinliKG`; queue graph indexing when the full graph layer is unavailable.
- Provide a deterministic manual CLI first, then a Windows scheduled-task installer that calls the same command.

## Quality Gate

- Default quality level: Mature production-grade
- MVP/prototype requested by user: no
- Mature Solution Evidence: analysis.md#Mature-Solution-Evidence
- Rejected shortcuts reviewed: yes
- User confirmation includes end-to-end behavior and safety boundary: yes
- Implementation completeness: discovery, eligibility, reconciliation, metadata, vsummary orchestration, durable notes, idempotency, cleanup, operations, and end-to-end evidence.

## Work Package Policy

- External workers: yes
- Task packet root: .trae/tasks/jinli/2026-06-21-bilibili-favorites-knowledge-automation
- Work packages required: yes
- Claim files required: no
- Worker reports required before merge: yes
- Packages execute in numeric order.
- Workers may not edit the task packet, acceptance criteria, task state, or verification report.

## Worker Repair Policy

- Worker profile: ds4-flash
- Lead/verifier: codex
- Fresh context per repair: yes
- Automatic repair package generation: yes
- Maximum attempts per root cause: 3
- Same-context worker self-verification: forbidden
- Only lead may set Review/Verify pass: yes
- Worker reports required before merge: yes

## Allowed Project Scope

- `Project/Jinli/services/knowledge/`
- `Project/Jinli/tests/knowledge/`
- `Project/Jinli/scripts/knowledge-*.ps1`
- `Project/Jinli/Docs/03-Architecture/KnowledgeGraph/`
- `Project/Jinli/Docs/04-Implementation/KnowledgeGraph/`
- `Project/Jinli/Docs/05-Testing/KnowledgeGraph/`
- `Project/Jinli/Docs/06-Operations/KnowledgeGraph/`
- `Project/Jinli/Docs/DOCS_TREE.md`

## Forbidden Scope

- Do not modify vsummary provider credentials or Bilibili cookies.
- Do not remove favorite-folder entries.
- Do not delete any file outside the declared managed media root.
- Do not replace the existing knowledge-runtime schemas or graph engine.
- Do not bypass platform authentication controls, DRM, paywalls, or CAPTCHA.
- Do not make graph availability a prerequisite for Markdown export.

