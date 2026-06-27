# Analysis: Jinli Knowledge Graph + Video Ingestion Design Update

## Architecture Context

### System boundaries
- In scope: Jinli design documentation for knowledge ingestion, local LLM worker routing, Obsidian export, graph-backed retrieval, and video-link summarization.
- In scope: documentation evidence for how future implementation should integrate with `Project/Jinli/data/memory.db`, `events.jsonl`, `knowledge-base.md`, and existing Soul Core lifecycle commands.
- Out of scope: implementing downloaders, Whisper transcription, schema migrations, or runtime code in this task.

### Dependency map
- `Project/Jinli/scripts/soul-core.ps1` owns `Search-Memories`, `Add-Memory`, `Invoke-SessionEnd`, and command routing.
- `Project/Jinli/scripts/evolve-self.ps1` owns knowledge discovery prompts and appending findings to `knowledge-base.md`.
- `Project/Jinli/services/vision/` already has an Ollama vision inference pattern that can inform future video frame analysis.
- `Docs/reference/local-llm-tools.md` provides local Ollama model inventory and RAG/GraphRAG/video-to-graph reference options.
- `skills/code-knowledge-graph/SKILL.md` and `.trae/scripts/codegraph.ps1` provide existing graph/token-saving patterns.

### Data and state ownership
- `memory.db`: runtime structured memory and future canonical knowledge item index.
- `events.jsonl`: chronological interaction and lifecycle event log.
- `knowledge-base.md`: current lightweight learning-engine registry.
- Obsidian vault: human-readable exported graph surface, not the only source of truth.
- Graph JSON/vector index: derived cache for low-token retrieval, rebuildable from source files and memory records.

### Integration points
- `soul_discover`: search/video/document discoveries should become structured knowledge items.
- `soul_end`: session reflection should promote high-value discoveries into memory/graph records.
- `soul_init`: retrieve relevant graph/memory context before replies.
- Plan phase: graph summaries should be read before bulk source files to reduce token consumption.

## Mature Solution Evidence

### Project-local evidence
- `Project/Jinli/docs/02-Design/General/soul-core-phase2.5-knowledge-evolution-spec.md` already defines automatic knowledge memory, Obsidian export, and graph evolution.
- `Project/Jinli/data/memory.md`, `memory.db`, `events.jsonl`, and `knowledge-base.md` already exist as Jinli memory/learning data stores.
- `Project/Jinli/services/vision/inference.py` already calls Ollama-style local vision models with fallback behavior.
- `.trae/scripts/codegraph.ps1` already implements a local graph cache for reducing repeated code reads.

### Official/framework evidence
- Obsidian-compatible Markdown uses YAML frontmatter and wiki links as a simple local graph surface.
- Ollama-compatible local endpoints are documented in `Docs/reference/local-llm-tools.md`.
- Local RAG/GraphRAG patterns in the reference doc support hybrid search, embeddings, and graph summaries.

### External mature references
- Microsoft GraphRAG: mature graph-based retrieval architecture, useful as a later reference.
- SwarmVault: local-first graph/RAG concept suitable for future evaluation.
- yt-dlp + Whisper pipeline: widely used pattern for video URL ingestion and transcription.

### Options compared
| Option | Source | Pros | Cons | Decision |
|---|---|---|---|---|
| Patch existing Jinli Phase 2.5 spec | Project-local design doc | Preserves one source of truth and avoids duplicate plans | Requires careful rewrite | Selected |
| Create a new standalone video-knowledge spec | New project doc | Clean separation | Splits knowledge graph decisions across docs | Rejected |
| Adopt Neo4j/GraphRAG immediately | External mature tools | Powerful graph queries | Heavy dependencies before Jinli schema is stable | Rejected for first implementation phase |
| SQLite/FTS + Obsidian + derived graph JSON first | Existing Jinli/codegraph pattern | Local-first, inspectable, easy to verify | Less powerful than dedicated graph DB | Selected |

### Rejected shortcuts
- Do not treat video summaries as plain chat output only; they must be source-linked and graph-ingestible.
- Do not let local models directly edit canonical project docs or task state.
- Do not make Obsidian the only source of truth; it is an export/read surface.
- Do not require heavy graph infrastructure before the local schema and ingestion pipeline are stable.

### Selected mature path
- Update the existing Phase 2.5 Jinli design into a complete knowledge hub design covering docs, code, task packets, memory, search results, and video links.
- Use local LLM workers only for bounded, verifiable extraction/summarization/reranking tasks.
- Define video ingestion as a first-class source with transcript, keyframe, timestamp, citation, and graph entity outputs.

## Acceptance Criteria
- AC01: Existing local design document is used and not bypassed by a new parallel design.
- AC02: Updated design includes local model routing for `qwen3:14b`, `qwen2.5-coder:14b`, and `openbmb/minicpm-v4.6`.
- AC03: Updated design includes video URL summarization and video knowledge retrieval.
- AC04: Updated design defines Obsidian/knowledge graph storage and source-of-truth boundaries.
- AC05: Updated design defines token-saving and local-worker safety rules.
- AC06: Documentation governance evidence is recorded in `doc-impact.md`.

## Automated Verification Plan
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\task-guard.ps1 jinli/2026-06-20-knowledge-graph-video-ingestion plan`
- Expected: plan gate passes before editing the project document.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\task-state.ps1 can-edit jinli/2026-06-20-knowledge-graph-video-ingestion`
- Expected: edit gate passes before project document edits.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\doc-guard.ps1 check-task jinli/2026-06-20-knowledge-graph-video-ingestion -Stage implement`
- Expected: documentation governance passes after the document update.
