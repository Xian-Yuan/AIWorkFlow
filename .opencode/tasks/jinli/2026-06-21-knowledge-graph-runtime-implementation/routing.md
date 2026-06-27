# Routing: Jinli Knowledge Graph Runtime Implementation

## Router Decision
- Project: Jinli
- Project type: other
- System: KnowledgeGraph
- Main skill: codex-project-router
- Secondary skills: doc-governance, test-driven-development, verification-before-completion
- Collaboration mode: DS4 Flash executes bounded work packages; Codex retains architecture, Review, and Verify.
- Task packet root: `.trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation`
- Canonical design: `Project/Jinli/docs/02-Design/General/soul-core-phase2.5-knowledge-evolution-spec.md`
- Superseded planning packets: `2026-06-20-knowledge-graph-video-ingestion`, `2026-06-20-kg-video-implementation-plan`, and `2026-06-20-obsidian-native-kg-upgrade`

## Selected Runtime Path
- Implement a Python knowledge service under `Project/Jinli/services/knowledge/`.
- Reuse `yt-dlp` for public metadata/captions and treat vsummary as an optional local ASR/workspace adapter, pinned to reviewed source revision.
- Use a provider-neutral Local Worker Gateway with Ollama as the default provider.
- Store canonical accepted records in Jinli-owned SQLite/JSONL data and export human-readable graph notes to `E:\ObsidianVault\JinliKG`.
- Reuse `obra/knowledge-graph` as the Obsidian indexing, traversal, semantic search, and MCP layer instead of building a second graph engine.
- Keep external providers and visual analysis optional; all outputs remain schema-checked candidates until accepted.

## Quality Gate
- Default quality level: Mature production-grade
- MVP/prototype requested by user: no
- Mature Solution Evidence: analysis.md#Mature-Solution-Evidence
- Rejected shortcuts reviewed: yes
- User confirmation must include quality level: yes
- Implementation completeness: contracts, local worker gateway, video ingestion, graph export, retrieval/MCP, visual extension, lifecycle integration, operations, and end-to-end evidence.

## Work Package Policy
- External workers: yes
- Task packet root: .trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation
- Work packages required: yes
- Claim files required: no
- Worker reports required before merge: yes
- Workers execute one package from a fresh context and do not mutate task packet files.
- Packages execute in numeric order unless the lead explicitly proves independence.

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
- `Project/Jinli/data/knowledge/schemas/`
- `Project/Jinli/scripts/knowledge-*.ps1`
- `Project/Jinli/scripts/soul-core.ps1`
- `Project/Jinli/scripts/soul-core.tests.ps1`
- `Project/Jinli/tests/knowledge/`
- `Project/Jinli/Docs/03-Architecture/KnowledgeGraph/`
- `Project/Jinli/Docs/04-Implementation/KnowledgeGraph/`
- `Project/Jinli/Docs/05-Testing/KnowledgeGraph/`
- `Project/Jinli/Docs/06-Operations/KnowledgeGraph/`
- `Project/Jinli/Docs/DOCS_TREE.md`

## Forbidden Scope
- Do not edit unrelated Soul Core persona, expression, avatar, or vision behavior.
- Do not write directly into existing user notes outside `E:\ObsidianVault\JinliKG`.
- Do not bypass login, DRM, paywalls, or platform access controls.
- Do not make vsummary, external APIs, Obsidian Local REST API, or visual models mandatory for text-first ingestion.
- Do not let worker/model output directly mutate canonical records without schema validation and acceptance policy.
- Do not replace `obra/knowledge-graph` with a new graph database or custom graph UI in this task.
