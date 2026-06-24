# Jinli Knowledge Graph Schema Patterns

> Sessions: 2026-06-20 kg-video-implementation-plan, 2026-06-21 WP01-implementation
> Source: Project/Jinli/docs/02-Design/General/soul-core-phase2.5-knowledge-evolution-spec.md v2.2 sections 17-21
> Implementation: Project/Jinli/services/knowledge/contracts.py + data/knowledge/schemas/

## Schema Naming Convention

- Format: `<domain-entity>.v<N>` where N starts at 1
- `$id`: `jinli://schemas/<name>.v<N>`
- All schemas use **JSON Schema Draft 2020-12** (updated from v2.1's draft-07)
- `additionalProperties: false` on all schemas (strict validation)

## ID Patterns

| Entity | Pattern | Example |
|--------|---------|---------|
| Video | `kg-video-YYYYMMDD-NNNN` | `kg-video-20260620-0001` |
| Segment | `kg-seg-YYYYMMDD-NNNN-NNN` | `kg-seg-20260620-0001-001` |
| Worker Job | `local-llm-YYYYMMDD-NNNN` | `local-llm-20260620-0001` |

## Implemented Schemas (WP01, 2026-06-21)

All 4 schemas live at `Project/Jinli/data/knowledge/schemas/`.

### 1. video-metadata.v1

Required fields: `video_id`, `source_url`, `platform`, `title`, `duration_seconds`, `uploader`, `ingestion_status`, `fetched_at`, `provenance`

- `platform` enum: `bilibili | youtube | vsummary | other`
- `ingestion_status` enum: `metadata_only | caption_extracted | whisper_transcribed | unsupported_source | access_denied`
- `provenance` is a nested object with `additionalProperties: false`, required: `source`, `fetched_by`; optional: `revision`
- Optional fields: `description`, `cid` (int|null), `thumbnail_url`
- Python dataclass: `VideoMetadata` in contracts.py with `create()` factory (auto-generates `fetched_at`)

### 2. transcript-segment.v1

Required fields: `segment_id`, `video_id`, `start_seconds`, `end_seconds`, `text`, `source`, `provenance`

- `source` enum: `caption | whisper | vsummary`
- `provenance` required: `source`, `extracted_by`; optional: `revision`
- Enrichment fields (optional): `summary`, `entities` (string[]), `relations` (string[]), `confidence` (0-1)
- Python dataclass: `TranscriptSegment` in contracts.py

### 3. local-worker-job.v1

Required fields: `job_id`, `job_type`, `status`, `input_hash`, `provider`, `model`, `created_at`, `provenance`

- `job_type` enum: `summarize_video_segment | extract_entities | normalize_json | compress_transcript | describe_keyframe`
- `status` enum: `queued | running | completed | failed | schema_validation_failed`
- `provenance` required: `source`, `submitted_by`; optional: `revision`
- Optional: `input_data`, `retries`, `error_message`, `completed_at`
- Python dataclass: `WorkerJob` with `create()` factory (auto-generates `created_at`, defaults status to QUEUED)

### 4. local-worker-output-envelope.v1

Required fields: `job_id`, `validation_status`, `output_data`, `provider`, `model`, `timing_ms`, `provenance`

- `validation_status` enum: `pending | valid | invalid`
- `provenance` required: `source`, `produced_by`; optional: `revision`
- Optional: `token_usage` (dict of string→int), `validation_errors` (string[])
- Python dataclass: `WorkerOutputEnvelope` in contracts.py

## Python Dataclass Contracts (contracts.py)

Additional dataclasses without dedicated schema files yet:

- `TranscriptEntry` — raw timestamped transcript line
- `GraphCandidate` — pending review with `CandidateReviewStatus` enum: `pending | accepted | rejected | conflict`
- `GraphNode` — accepted knowledge node with `source_url`, `source_hash`, `provider_chain`
- `GraphEdge` — relationship between nodes
- `EvidenceRecord` — links source to accepted records

Enums: `IngestionStatus`, `WorkerJobStatus`, `ValidationStatus`, `CandidateReviewStatus`

## Validation Helper (contracts.py)

```python
validate_against_schema(data: dict, schema: dict) -> ValidationResult
```

- Uses `jsonschema.Draft202012Validator.iter_errors()` for field-level errors
- Returns `ValidationResult` with structured `ValidationError` list
- **Pitfall**: When a required field is missing, jsonschema reports the error at `(root)` path, not the field name. The field name appears in the `message` string instead. Tests checking for missing-field errors should match against both `e.field_path` and `e.message`.

## Worker Gateway (WP02, 2026-06-21)

### Module Structure

```
services/knowledge/
  worker_gateway.py    — WorkerGateway, GatewayConfig, MODEL_ROUTING
  providers/
    __init__.py        — Re-exports
    base.py            — ProviderProtocol, ProviderHealth, ProviderResult, ProviderStatus
    ollama.py          — OllamaProvider (injectable http_transport)
    external.py        — ExternalProvider (disabled by default)
  tests/
    test_providers.py       — 21 tests
    test_worker_gateway.py  — 29 tests
```

### Provider Architecture

- `ProviderProtocol` (runtime_checkable) — `name`, `model`, `health_check()`, `structured_generate()`
- `OllamaProvider` — calls `/api/chat`, accepts `http_transport: Callable[[url, payload, timeout], tuple]` for test injection
- `ExternalProvider` — requires `base_url + model + api_key` to activate; UNCONFIGURED otherwise; no embedded credentials
- `ProviderResult` — success/fail with `error_type` enum: `timeout | connection | schema | model | unknown`
- `ProviderHealth` — status: `AVAILABLE | UNAVAILABLE | UNCONFIGURED`

### WorkerGateway Lifecycle

1. `submit_job()` → creates QUEUED job with auto-computed input hash
2. `execute_job(job, output_schema?)` → RUNNING → call provider → validate → COMPLETED/FAILED/SCHEMA_VALIDATION_FAILED
3. If schema validation fails and `retries < MAX_NORMALIZATION_RETRIES (1)`: one normalization retry with correction prompt
4. `cancel_job(job_id)` → adds to in-memory set; next `execute_job` checks and rejects
5. All transitions appended to `jobs.jsonl` (audit trail, no in-place updates)

### Key Design Decisions

- **Input hash verification**: `_compute_hash(input_data)` using SHA-256 of JSON (sort_keys=True). Mismatch → immediate failure.
- **One normalization retry**: prevents infinite loops. After retry failure → `SCHEMA_VALIDATION_FAILED` status.
- **Raw output preserved**: `ProviderResult.raw_output` retains original for diagnosis but does not enter canonical records.
- **Job cancellation is in-memory**: `_cancelled_jobs` set on gateway instance. Not persisted across restarts.

### Known Limitation

The mock `HttpTransport` interface (`url, payload, timeout → (status_code, body)`) doesn't distinguish GET vs POST. The Ollama health check currently sends a payload to `/api/tags` which is semantically wrong for a GET endpoint. WP03/WP09 should add a proper HTTP adapter layer.

## Local Worker Gateway Flow (spec section 18)

```
Lead → create job (queued) → Gateway reads job → reads input → verify input_hash →
call Ollama API → wrap in envelope → validate against schema → write output →
update job status → Lead reads envelope → accept (valid) or reject (invalid)
```

### Model Routing

| Job type | Model | Temp |
|----------|-------|------|
| summarize_video_segment | qwen3:14b | 0.2 |
| extract_entities | qwen3:14b | 0.1 |
| normalize_json | qwen2.5-coder:14b | 0.1 |
| compress_transcript | qwen3:14b | 0.2 |
| describe_keyframe | minicpm-v4.6 | 0.2 |

## Video Pipeline Stages (spec section 19)

8 stages with failure paths at each:
1. Platform Resolution → unsupported_source / access_denied
2. Metadata Extraction → retry once → metadata_only
3. Transcript Acquisition → captions → whisper → metadata_only
4. Segmentation → empty transcript → skip
5. Local LLM Enrichment → Ollama unavailable → raw segments
6. Summary Generation → no enriched → raw transcript
7. Obsidian Export → formatting only (no failure)
8. Knowledge Store Write → db error → queue retry

## Data Layout (spec section 20)

```
data/knowledge/
  schemas/        — JSON Schema files (canonical, not rebuildable)
  jobs/           — Worker job records (derived)
  videos/<id>/    — Per-video artifacts
  graph/          — Entity/relation JSONL (derived, rebuildable)
  cache/          — Hash index etc. (derived, rebuildable)
```

## Configuration Defaults (config.py)

- Default vault: `E:\ObsidianVault`
- Default project root: `E:\UEGameDevelopment\Project\Jinli`
- Default tool root: `E:\Obsidian\tools`
- Drift detection: `detect_vault_drift()` compares intended vault vs `OBSIDIAN_VAULT_PATH` env var (passed as parameter, not read from os.environ)
- Path containment: `KnowledgeConfig.path_contained(candidate, root)` resolves and checks
- Config is frozen/immutable — no setters

## Source Adapters (WP03, 2026-06-21)

### Module Structure

```
services/knowledge/
  transcript.py         — parse_srt, parse_vtt, normalize_transcript
  sources/
    __init__.py         — Re-exports
    base.py             — SourceProtocol, SourceFamily, TranscriptAcquisition, classify_url
    ytdlp_source.py     — YtdlpSource (injectable ytdlp_instance for mocking)
    vsummary_adapter.py — VsummaryAdapter (workspace_root injection)
  tests/
    test_video_sources.py    — 30 tests
    test_vsummary_adapter.py — 28 tests
```

### Source Protocol

- `SourceProtocol` (runtime_checkable) — `probe(url) → SourceProbeResult`, `acquire_transcript(url, language) → TranscriptResult`
- `SourceFamily` enum: `youtube | bilibili | vsummary | unsupported`
- `TranscriptAcquisition` enum: `caption | whisper | vsummary | unavailable`
- `classify_url(url) → SourceFamily` — URL → platform routing

### YtdlpSource

- `__init__(ytdlp_instance=None)` — inject mock for offline tests
- `probe()` returns `SourceProbeResult` with caption availability and languages
- `acquire_transcript()` prefers manual captions > auto-captions; SRT string → `parse_srt()` → segments
- Access denied (private/DRM/login) → `IngestionStatus.ACCESS_DENIED`
- Unsupported platform → `IngestionStatus.UNSUPPORTED_SOURCE`

### VsummaryAdapter

- `__init__(workspace_root: Path)` — workspace directory injection
- `VSUMMARY_REVISION = "4de6dbbd376c29d35380d8d8fcc2094821b2b3f9"`
- File priority: `transcript.cleaned.json` → `.cache/whisper/transcript.raw.json` → UNAVAILABLE
- `get_summary(url)` — reads `summary.json` for chapters/key_takeaways
- `_extract_video_id(url)` — BV号 from Bilibili, 11-char ID from YouTube

### Transcript Normalization

- `normalize_transcript(segments, source, language)` — sort + dedup + metadata + source_hash
- Dedup key: `(round(start, 2), round(end, 2))` — same timestamps → keep first
- `source_hash`: SHA-256 of `{"start": float, "end": float, "text": str}` → first 16 hex chars

## Segmentation & Enrichment (WP04, 2026-06-21)

### Module Structure

```
services/knowledge/
  segmentation.py    — SegmentationConfig, compute_segment_id, segment_transcript
  enrichment.py      — EnrichmentConfig, EnrichedSegment, create_bounded_job, enrich_segments
  summary.py         — compile_summary, _fmt_ts, _make_timestamp_link
  evidence_search.py  — SearchConfig, SearchResult, search_evidence
  tests/
    test_segmentation.py     — 17 tests
    test_enrichment.py       — 15 tests
    test_summary.py          — 13 tests
    test_evidence_search.py  — 16 tests
```

### Segmentation (deterministic, no LLM)

- `compute_segment_id(video_id, start_seconds)` — SHA-256 of `"{video_id}:{start:.3f}"` → 16 hex chars
- Split conditions: gap > `gap_threshold_seconds` (5s), merged > `max_segment_seconds` (120s), chapter boundaries
- Short segments (< `min_segment_seconds` 2s) merge into previous
- Duplicate consecutive text: skip but update end time

### Enrichment

- `EnrichedSegment` wraps `TranscriptSegment` + `enrichment_pending` + `summary/entities/relations`
- Gateway=None → all pending, original segment preserved (never deleted/replaced)
- `create_bounded_job()` truncates input text to `max_input_chars` (4000)
- Creates one `summarize` + one `extract` job per segment

### Summary Compilation

- Markdown with source URL, timestamp links, chapter overview
- Pending segments: `[unverified]` + `⏳ *pending*` markers
- Timestamp links: YouTube/Bilibili `&t=N`, generic `#t=N`

### Evidence Search

- AND-query keyword search on raw text, no LLM dependency
- `SearchConfig`: `max_results` (20) + `max_char_budget` (4000) dual limits
- Results sorted by `match_count` descending

## Running Tests

```bash
cd E:\UEGameDevelopment\Project\Jinli
PYTHONPATH="E:/UEGameDevelopment/Project/Jinli/services:$PYTHONPATH" python -m pytest services/knowledge/tests/ -q
```

## Test Statistics

- WP01: 95 tests (20 config + 49 contracts + 26 io_utils)
- WP02: 50 tests (21 providers + 29 worker_gateway)
- WP03: 58 tests (30 video_sources + 28 vsummary_adapter)
- WP04: 61 tests (17 segmentation + 15 enrichment + 13 summary + 16 evidence_search)
- Total: 291 tests, all passing

## First Slice Boundaries (spec section 21)

In scope: YouTube + Bilibili captions, qwen3:14b summarization, video_segment records, Obsidian export, keyword search, graceful fallback.
Out of scope: full graph DB, vector search, Whisper, MiniCPM-V, memory.md import, soul lifecycle, non-KG uses.
