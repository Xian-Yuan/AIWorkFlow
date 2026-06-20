# Analysis: Jinli Knowledge Graph + Video Implementation Plan

## Architecture Context

### System boundaries
- In scope: implementation planning for the v2.0 Jinli knowledge graph/video ingestion design.
- In scope: selecting the first build slice, data ownership, verification strategy, and local model worker boundaries.
- In scope: local-model token-saving strategy for simple, repetitive, schema-checkable work tied to knowledge ingestion and retrieval.
- In scope: video-link-to-text-summary capability for accessible mainstream video sources.
- In scope: defining the `Local Worker Gateway` contract used by the KG/video pipeline.
- Out of scope: implementing runtime code in this planning packet.
- Out of scope: Mentor Mode persona/runtime behavior; this packet only references it as a boundary.
- Out of scope: applying local workers to all daily tasks, coding tasks, or global AI workflow automation in this packet.
- Cross-cutting boundary: Mentor Mode controls exploration/decision pacing but does not own graph infrastructure.

### Dependency map
- Design source: `Project/Jinli/docs/02-Design/General/soul-core-phase2.5-knowledge-evolution-spec.md`.
- Local model reference: `Docs/reference/local-llm-tools.md`.
- Technical ecosystem reference: `Docs/AI/research/2026-06-20-AI-Agent-Ecosystem-Technical-Reference.md`.
- Existing runtime: `Project/Jinli/scripts/soul-core.ps1`, `Project/Jinli/scripts/evolve-self.ps1`.
- Existing local vision pattern: `Project/Jinli/services/vision/`.
- Existing graph pattern: `.trae/scripts/codegraph.ps1`, `skills/code-knowledge-graph/SKILL.md`.
- Local model inventory: `qwen3:14b`, `qwen2.5-coder:14b`, and `openbmb/minicpm-v4.6:latest` under `E:\Ollama\models\`.

### Data and state ownership
- Canonical runtime memory: `Project/Jinli/data/memory.db`.
- Event history: `Project/Jinli/data/events.jsonl`.
- Human learning digest: `Project/Jinli/data/knowledge-base.md`.
- Proposed derived data: `Project/Jinli/data/knowledge/`.
- Obsidian export: derived/human-readable, not canonical.
- `Local Worker Gateway` job inputs and outputs are derived artifacts under `Project/Jinli/data/knowledge/jobs/` until accepted by schema validation and the lead workflow.

### Integration points
- `soul_discover`: future discovery/video ingestion entry.
- `soul_end`: future insight promotion and export queue.
- `Search-Memories` and `Add-Memory`: schema extension points.
- Future video ingestion command: metadata/captions/transcript/segments/graph records.
- Local worker queue: schema-checked jobs for transcript cleanup, summarization, entity extraction, JSON normalization, and reranking.
- `Local Worker Gateway`: receives bounded job JSON from Codex/Jinli, calls Ollama, writes schema-checked output, and returns compact evidence to the lead model.
- Plan phase retrieval: query local graph/FTS/vector caches before reading long raw documents or transcripts.

## Mature Solution Evidence

### Project-local evidence
- The v2.0 design already defines video ingestion, local LLM worker policy, Obsidian export, and recommended first build slice.
- Jinli already has SQLite memory, JSONL events, a learning knowledge base, and Ollama vision service patterns.
- Current task-packet workflow requires concrete acceptance criteria and verification before implementation.
- `Docs/reference/local-llm-tools.md` identifies local Ollama models and recommends local workers for repetitive text, JSON, code, and vision/OCR tasks.
- The existing code graph pattern proves the value of compact local indexes before expensive raw source reads.

### Official/framework evidence
- The local workflow requires Plan/can-edit gates before any project edit.
- Documentation governance requires `doc-impact.md` and same-project docs tree updates when docs change.

### External mature references
- The technical reference document supports context engineering, file-backed memory, skill-level memory, hooks, knowledge graphs, and video/tooling references.
- `yt-dlp + captions/Whisper + local LLM` is the mature pattern for accessible video ingestion.

### Options compared
| Option | Source | Pros | Cons | Decision |
|---|---|---|---|---|
| One packet for Mentor + KG/video | User question | Fewer packets | Different validation domains; risks conflating values with infra | Rejected |
| Two packets with cross-reference | Current design | Separate acceptance, cleaner pacing | More files | Selected |
| Split token optimization into a third packet | Technical reference | Very clean workflow scope | Too early; token-saving is part of this graph/video slice's value proposition | Rejected for now |
| Merge local-worker token optimization into KG/video | Local LLM reference | Keeps data pipeline and cost reduction together | Must document worker authority limits | Selected |
| Define a named `Local Worker Gateway` contract | Current refinement | Prevents ad hoc local-model calls and makes outputs verifiable | Adds one more interface to document | Selected |
| Let local models call tools directly | Agent automation shortcut | Flexible | Hard to verify, can mutate state, unsafe for workflow authority | Rejected |
| Implement full graph/video system at once | v2.0 design | Complete capability | High risk, large blast radius | Rejected |
| First vertical slice: one video -> transcript/summary/segment search/export | v2.0 section 16 | Demonstrates value, bounded verification | Does not solve full graph stack yet | Selected |

### Rejected shortcuts
- Do not build a heavyweight graph database before proving local schema and ingestion.
- Do not ingest videos as untraceable summaries.
- Do not let local models write canonical records without schema validation.
- Do not treat Mentor Mode as implementation scope for the infrastructure packet.
- Do not claim "mainstream video support" means bypassing login, DRM, paywalls, or platform restrictions.
- Do not make local models architecture owners; they only produce bounded, verifiable artifacts.
- Do not use cloud-model context to repeatedly summarize the same long transcript when local cached segments exist.
- Do not call local models through untracked prompts when a durable job record is needed.
- Do not let local worker outputs skip schema checks, source hashes, or acceptance by the lead workflow.

### Selected mature path
- Keep Mentor Mode and KG/video as two task packets.
- Use this packet to plan a bounded first implementation slice for video knowledge ingestion.
- Start from local stores and derived exports before evaluating heavyweight graph databases.
- Keep token-saving optimization inside this packet only where it directly supports knowledge ingestion/retrieval: local worker jobs, caches, segment records, and graph-first retrieval.
- Treat video-link summarization as the first proof of value: one accessible URL becomes transcript-backed text, timestamped evidence, searchable records, and an Obsidian note.
- Introduce `Local Worker Gateway` as the single contract for local Ollama workers in this slice:
  `Codex/Jinli -> job JSON -> Ollama model -> schema validation -> derived cache -> compact evidence returned to lead`.
- Record non-KG uses of local models as future expansion candidates, not implementation scope for this packet.

## Local Worker Gateway Contract

### Purpose
- Provide a controlled path for using local Ollama models without giving them project authority.
- Reduce cloud-token usage by pre-processing long or repetitive artifacts locally.
- Preserve traceability through job IDs, input hashes, model names, schemas, and output paths.

### First supported job types
| Job type | Preferred model | Output |
|---|---|---|
| `summarize_video_segment` | `qwen3:14b` | timestamped segment summary JSON |
| `extract_entities` | `qwen3:14b` | entities and candidate relations JSON |
| `normalize_json` | `qwen2.5-coder:14b` | schema-conformant JSON |
| `compress_transcript` | `qwen3:14b` | concise transcript digest |
| `describe_keyframe` | `openbmb/minicpm-v4.6:latest` | OCR/visual observation JSON |

### Authority boundary
- Local workers may produce drafts, summaries, labels, relations, and normalized JSON.
- Local workers must not edit task packets, project source files, acceptance criteria, or verification reports.
- Lead workflow validates every output before writing canonical knowledge records.

### Future expansion candidates outside this packet
| Area | Candidate local-worker use | Suggested future packet |
|---|---|---|
| Daily task assistance | meeting/note cleanup, todo extraction, repetitive text formatting | `jinli-local-worker-daily-assist` |
| Coding support | log compression, test output grouping, simple refactor suggestions, code map summaries | `_shared` or per-project workflow packet |
| Jinli runtime | memory candidate extraction, emotion/event digest, Obsidian note drafting | Jinli Soul Core implementation packet |
| Project workflow | work-package draft generation, evidence summarization, duplicate detection summaries | global AI workflow packet |
| UI/visual work | screenshot OCR, UI state description, keyframe summaries | project-specific vision worker packet |

## Acceptance Criteria
- AC01: The KG/video task packet explicitly references the updated v2.0 design.
- AC02: The packet selects a bounded first build slice rather than the full graph system.
- AC03: The packet defines data ownership and local-worker boundaries.
- AC04: The packet keeps Mentor Mode as a separate cross-cutting protocol.
- AC05: The packet defines verification commands for future implementation.
- AC06: The packet explicitly supports video link to text summary for accessible mainstream video sources.
- AC07: The packet defines how local models reduce cloud-token consumption without owning architecture or final acceptance.
- AC08: The packet defines a named `Local Worker Gateway` contract and keeps non-KG uses as future expansion candidates.

## Automated Verification Plan
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\task-guard.ps1 jinli/2026-06-20-kg-video-implementation-plan plan`
- Expected: The plan gate is ready once Ba Ba confirms the build slice.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\doc-guard.ps1 check-task jinli/2026-06-20-kg-video-implementation-plan -Stage plan`
- Expected: Documentation governance passes.
