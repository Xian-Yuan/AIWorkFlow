# Analysis: Jinli Knowledge Graph Runtime Implementation

## Architecture Context

### System boundaries
- `Project/Jinli/services/knowledge/` owns ingestion orchestration, schema validation, candidate generation, acceptance, Obsidian export, and retrieval adapters.
- vsummary remains a separate local application. Jinli may import its workspace artifacts or call a documented local endpoint through an adapter, but must not fork its code into Jinli.
- `obra/knowledge-graph` remains a separate pinned tool that indexes the generated Obsidian vault and exposes CLI/MCP graph operations.
- Ollama and optional external providers generate derived candidates only. They do not own canonical state or workflow authority.
- Existing Soul Core lifecycle commands may call the knowledge service through a small CLI/PowerShell bridge. Knowledge implementation must not absorb persona or emotional-state behavior.

### Dependency map
- Canonical design: `Project/Jinli/docs/02-Design/General/soul-core-phase2.5-knowledge-evolution-spec.md`, especially sections 17-22.
- Existing runtime: `Project/Jinli/scripts/soul-core.ps1`, `Project/Jinli/data/memory.db`, and `Project/Jinli/data/events.jsonl`.
- Existing local inference pattern: `Project/Jinli/services/vision/inference.py`.
- Public-video extraction: `yt-dlp` Python package and FFmpeg.
- Optional local transcription/workspace: `alpha03123/vsummary` revision `4de6dbbd376c29d35380d8d8fcc2094821b2b3f9`.
- Obsidian graph query/MCP: `obra/knowledge-graph` revision `1d2481ece87807f2f695b8853a790b8c8aa62b29`.
- Local model endpoint: Ollama HTTP API at `http://localhost:11434`.
- Human graph surface: `E:\ObsidianVault\JinliKG`.

### Data and state ownership
- `Project/Jinli/data/knowledge/schemas/`: versioned canonical contracts.
- `Project/Jinli/data/knowledge/videos/`: source metadata, transcripts, segments, summaries, and provenance.
- `Project/Jinli/data/knowledge/knowledge.db`: accepted node, edge, evidence, source, and export state.
- `Project/Jinli/data/knowledge/jobs/`: append-oriented worker job history and validated output envelopes.
- `Project/Jinli/data/knowledge/cache/`: rebuildable hashes and derived indexes.
- `E:\ObsidianVault\JinliKG`: generated and user-readable graph surface; only controlled machine sections may be updated automatically.
- obra index data: derived and rebuildable from the vault.

### Integration points
- CLI: `python -m knowledge.cli ingest-video`, `search`, `export`, `health`, and `analyze-keyframes`.
- PowerShell: `Project/Jinli/scripts/knowledge-runtime.ps1` provides Windows-friendly inspect/setup/ingest/search/index commands.
- `soul_discover`: may enqueue or invoke URL ingestion and return compact evidence.
- `soul_init`: may retrieve bounded graph context for an explicit query without loading the entire vault.
- `soul_end`: may promote reviewed session discoveries; it must not auto-accept low-confidence candidates.
- Obsidian: direct filesystem export is primary; Local REST API is optional and not required.

## Mature Solution Evidence

### Project-local evidence
- The v2.2 design already defines JSON contracts, Local Worker Gateway flow, video artifacts, Obsidian note-as-node/internal-link-as-edge behavior, deduplication, provider routing, and visual candidate boundaries.
- Jinli already uses Python for the vision service and PowerShell for lifecycle integration, so a Python service plus thin PowerShell bridge follows existing patterns.
- Current environment has Python 3.11, pytest, FFmpeg, Node.js, `E:\ObsidianVault`, and `E:\Ollama\models`; `yt-dlp` is not installed and Ollama is not guaranteed to be running.
- `OBSIDIAN_VAULT_PATH` currently points to `D:\xuexi\OBLibrary\OB`; setup must detect this drift and require explicit apply before switching to `E:\ObsidianVault`.

### Official/framework evidence
- yt-dlp exposes metadata and subtitle extraction without requiring a custom downloader.
- Ollama structured outputs can constrain model responses with JSON schema, but Jinli must still validate the returned payload locally.
- Obsidian native Graph View treats Markdown notes as nodes and internal links as edges.
- vsummary provides local video transcription, chaptering, notes, Markdown export, Bilibili import, and local-first storage.
- obra/knowledge-graph parses Obsidian Markdown into SQLite/FTS/vector indexes and exposes graph traversal and MCP operations.

### External mature references
- vsummary: https://github.com/alpha03123/vsummary
- obra/knowledge-graph: https://github.com/obra/knowledge-graph
- yt-dlp: https://github.com/yt-dlp/yt-dlp
- Ollama structured outputs: https://docs.ollama.com/capabilities/structured-outputs
- Obsidian Graph View: https://obsidian.md/help/plugins/graph

### Options compared
| Option | Source | Pros | Cons | Decision |
|---|---|---|---|---|
| Copy vsummary into Jinli | Existing open-source application | Many features immediately | Large fork, duplicate UI/runtime, upgrade burden | Rejected |
| Adapter to vsummary artifacts plus direct yt-dlp captions | vsummary + yt-dlp | Reuses mature ASR while keeping URL path lightweight | Two adapters to maintain | Selected |
| Build custom graph index and MCP | Local implementation | Full control | Duplicates mature graph/search work | Rejected |
| Export Obsidian notes and index with obra/knowledge-graph | Obsidian + obra | Native visual graph, local semantic/FTS/traversal, MCP | Requires Node tool installation | Selected |
| Make Obsidian the canonical database | Simplified storage | Easy to inspect | Manual edits and runtime state conflict | Rejected |
| Jinli SQLite canonical store plus controlled Obsidian export | Existing design | Transactional state, provenance, rebuildable export | Requires export synchronization | Selected |
| Require external API for quality | Cloud path | Potentially stronger extraction | Cost, privacy, credentials | Rejected |
| Local Ollama default with provider extension | Existing local models | Private and token-efficient | Must degrade when unavailable | Selected |

### Rejected shortcuts
- Do not call a model with raw transcript text and save its prose as the only result.
- Do not overwrite manually edited Obsidian note sections.
- Do not silently switch the user environment from the D drive vault to the E drive vault.
- Do not claim graph integration when only Markdown files exist but no index/MCP smoke test was run.
- Do not claim video support using only mocked extractors; final verification needs one real accessible URL.
- Do not accept a candidate only because its JSON validates; acceptance also requires provenance and confidence policy.
- Do not make live-network tests part of every unit-test run.

### Selected mature path
- Implement a testable Python knowledge service with dependency injection for source, provider, storage, and process adapters.
- Use TDD and offline fixtures for deterministic behavior, plus an explicit opt-in live smoke test.
- Pin external tool revisions in configuration and installation scripts.
- Keep a two-stage knowledge write: validated candidate first, accepted canonical node/edge second.
- Export controlled machine sections to Obsidian and preserve user sections.
- Use obra/knowledge-graph for local indexing, search, path traversal, graph analysis, and MCP.

## Work Package Dependency Order
1. WP01 contracts and runtime foundation.
2. WP02 Local Worker Gateway.
3. WP03 video source and transcript acquisition.
4. WP04 segmentation, enrichment, and evidence search.
5. WP05 canonical graph, deduplication, and Obsidian export.
6. WP06 obra index and MCP bridge.
7. WP07 visual candidate enhancement.
8. WP08 Soul Core and command integration.
9. WP09 setup, documentation, offline E2E, and live acceptance.

## Acceptance Criteria
- AC01: Versioned schemas reject malformed metadata, segments, worker jobs, worker outputs, graph candidates, and accepted records.
- AC02: Configuration resolves `E:\ObsidianVault` as the intended vault and reports D-drive environment drift without silently changing it.
- AC03: Local Worker Gateway records input hashes, provider/model, timing, status, validation result, and retry history.
- AC04: Public YouTube or Bilibili URLs with captions produce timestamped transcript and segment artifacts without bypassing access controls.
- AC05: vsummary workspace import is supported as an optional ASR/artifact source and is pinned rather than copied.
- AC06: Ollama-unavailable execution preserves raw transcript segments and marks enrichment pending.
- AC07: Accepted graph nodes and edges retain source URL, timestamp, source hash, provider chain, confidence, and review status.
- AC08: Deduplication merges exact identities, queues ambiguous candidates, and never silently overwrites conflicting knowledge.
- AC09: Obsidian export creates source/concept/segment notes with frontmatter and internal links while preserving manual sections.
- AC10: obra/knowledge-graph can index the generated fixture vault and return keyword/semantic or graph traversal results through a wrapper.
- AC11: Visual analysis produces candidate observations and keyframe evidence only; it cannot directly accept graph mutations.
- AC12: Soul Core bridge exposes bounded ingest/search hooks without changing unrelated persona or lifecycle behavior.
- AC13: Existing Jinli Node and Soul Core tests remain green.
- AC14: Offline end-to-end fixture creates a searchable Obsidian graph; live verification processes one accessible URL from `JINLI_KG_TEST_VIDEO_URL`.
- AC15: Architecture, implementation, testing, operations documents and `Project/Jinli/Docs/DOCS_TREE.md` reflect the final runtime.

## Automated Verification Plan
- Command: `python -m pytest Project/Jinli/services/knowledge/tests -q`
  Expected: all knowledge service unit and offline integration tests pass.
- Command: `npm.cmd test --prefix Project/Jinli`
  Expected: existing Jinli Node tests pass.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File Project/Jinli/scripts/soul-core.tests.ps1`
  Expected: existing and new Soul Core bridge tests pass.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File Project/Jinli/scripts/knowledge-runtime.ps1 health`
  Expected: JSON health report distinguishes required, optional, available, and unavailable dependencies.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File Project/Jinli/scripts/knowledge-runtime.ps1 test-offline`
  Expected: fixture video artifacts, graph records, Obsidian notes, and search results are produced under a temporary directory.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File Project/Jinli/scripts/knowledge-runtime.ps1 test-live -Url $env:JINLI_KG_TEST_VIDEO_URL`
  Expected: one accessible public video produces timestamped evidence and Obsidian graph notes; command is blocked with a clear message when the environment variable is absent.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\doc-guard.ps1 check-task jinli/2026-06-21-knowledge-graph-runtime-implementation -Stage implement`
  Expected: documentation governance passes.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\task-guard.ps1 jinli/2026-06-21-knowledge-graph-runtime-implementation implement`
  Expected: all worker reports, tasks, tests, documentation, and repair state pass before Review.

## Known Prerequisites
- `yt-dlp` must be installed into the knowledge-service Python environment.
- Ollama must be running for local enrichment; raw ingestion still works without it.
- A real public test URL must be supplied through `JINLI_KG_TEST_VIDEO_URL` for final live verification.
- obra/knowledge-graph installation downloads a local embedding model on first index.
- Strong issuer-worker capability mode is not enabled because typical local models share the same Windows SID; scoped DS4 reports and independent Codex verification are used instead.
