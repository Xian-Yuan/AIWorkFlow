# Analysis: Jinli Obsidian-Native Knowledge Graph Upgrade

## Architecture Context

### System boundaries
- In scope: upgrade the Phase 2.5 design so Obsidian native Graph View is the first-class visible graph experience.
- In scope: define note-as-node, internal-link-as-edge, frontmatter metadata, candidate review, deduplication, and video-to-graph flow.
- In scope: define model provider routing for local Ollama defaults and optional external APIs.
- In scope: preserve local visual model support as a bounded enhancement path for visual-only video/frame content.
- Out of scope: writing runtime ingestion code, Obsidian plugin code, or external provider implementation in this packet.

### Dependency map
- Existing design: `Project/Jinli/docs/02-Design/General/soul-core-phase2.5-knowledge-evolution-spec.md`.
- Obsidian native Graph View: notes are nodes and internal links are edges.
- Obsidian Canvas: optional map layer stored as JSON Canvas.
- Dataview: optional query layer over Markdown frontmatter and inline fields.
- Local REST API: optional bridge when Obsidian is running; file-system writes remain the primary integration path.
- Local worker models: `qwen3:14b`, `qwen2.5-coder:14b`, `openbmb/minicpm-v4.6:latest`.

### Data and state ownership
- Canonical accepted graph records remain Jinli-owned (`memory.db` / graph JSON) until a future migration changes that.
- Obsidian vault files are the primary human-visible graph surface and a rebuildable export.
- Candidate notes and candidate edges are non-canonical until accepted by schema validation and review policy.
- External API output is treated the same as local worker output: schema-checked, provenance-recorded, and not trusted directly.

### Integration points
- Video ingestion pipeline writes source/video/segment notes plus concept notes and internal links.
- Local Worker Gateway routes extraction jobs to provider/model combinations.
- Obsidian Graph View reads generated internal links without requiring a custom Obsidian plugin.
- Optional Local REST API can open, update, or inspect vault notes when Obsidian is running.
- Optional visual model jobs can add image/keyframe evidence after the text-first first slice.

## Mature Solution Evidence

### Project-local evidence
- The v2.1 Phase 2.5 design already defines Obsidian export, graph schemas, video segments, Local Worker Gateway, and MiniCPM-V as an optional visual model.
- Ba Ba clarified the desired experience: visible Obsidian-like graph, clickable knowledge nodes, automatic node/edge enrichment from video links, local model handling of repetitive work, and external API extensibility.
- Current task packet workflow requires plan gate, doc governance, and verification evidence before claiming completion.

### Official/framework evidence
- Obsidian Graph View is a core plugin that visualizes note relationships; circles represent notes and lines represent internal links.
- Obsidian Canvas is a core plugin for visual note-taking and saves canvases as `.canvas` files using JSON Canvas.
- Dataview indexes Markdown metadata and lets users query notes as a live index.
- Obsidian Local REST API allows external programs to interact with notes after plugin setup.

### External mature references
- Obsidian native Graph View: https://obsidian.md/help/plugins/graph
- Obsidian Canvas: https://obsidian.md/help/plugins/canvas
- Obsidian Dataview: https://blacksmithgu.github.io/obsidian-dataview/
- Obsidian Local REST API: https://github.com/coddingtonbear/obsidian-local-rest-api

### Options compared
| Option | Source | Pros | Cons | Decision |
|---|---|---|---|---|
| Custom web graph first | General graph UI pattern | Full control over interaction | More code, delays visible value, duplicates Obsidian | Rejected for first slice |
| Obsidian native Graph View first | Obsidian core plugin | Immediate visible graph; links are durable Markdown | Less custom layout control | Selected |
| Obsidian custom plugin first | Obsidian plugin ecosystem | Deep integration | More maintenance and API surface | Rejected for first slice |
| File-system vault export | Existing Jinli local-first pattern | Works without Obsidian running; easy to verify | Cannot trigger UI actions directly | Selected as primary |
| Local REST API bridge | Community plugin | Can open/update notes via API | Requires plugin setup/API key | Optional enhancement |
| Local-only models | Local worker policy | Privacy and cost control | May be weaker on difficult extraction | Default |
| External API fallback | Provider abstraction | Higher quality when needed | Cost/privacy/API-key handling | Optional provider |

### Rejected shortcuts
- Do not represent the graph only as JSON while leaving Obsidian Graph View empty.
- Do not create one video summary note without concept notes and internal links.
- Do not let model output write canonical notes without schema validation and deduplication.
- Do not require a custom Obsidian plugin for the first visible graph.
- Do not make external APIs mandatory for the first slice.
- Do not mix visual model processing into the text-first slice unless visual-only content requires it.

### Selected mature path
- Upgrade the design to Obsidian-native first: one accepted knowledge node equals one Markdown note, and accepted relationships are emitted as `[[internal links]]`.
- Use frontmatter for stable ids, aliases, node type, confidence, source count, and provenance.
- Keep Local Worker Gateway provider-neutral: local Ollama is default; external APIs are optional providers with the same job schema and validation envelope.
- Treat visual model support as a separate enhancement path that consumes sampled frames/keyframes and produces candidate observations linked to source video notes.

## Acceptance Criteria
- AC01: The design explicitly states Obsidian Graph View is the primary first-slice visual graph.
- AC02: The design defines note-as-node and internal-link-as-edge rules.
- AC03: The design defines a vault folder layout and frontmatter schema for knowledge nodes, video source notes, segment notes, and review candidates.
- AC04: The design defines deduplication/merge policy before creating new nodes.
- AC05: The design defines Local Worker Gateway provider routing with local Ollama defaults and external API extension points.
- AC06: The design keeps visual model processing as a bounded enhancement path with local visual model support.
- AC07: DOCS_TREE and doc-impact evidence are updated.

## Automated Verification Plan
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\task-guard.ps1 jinli/2026-06-20-obsidian-native-kg-upgrade plan`
- Expected: Plan gate passes before project docs are edited.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\doc-guard.ps1 check-task jinli/2026-06-20-obsidian-native-kg-upgrade -Stage implement`
- Expected: Documentation governance passes after design doc and DOCS_TREE update.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\task-guard.ps1 jinli/2026-06-20-obsidian-native-kg-upgrade implement`
- Expected: Implement gate passes after all checklist items are complete.
