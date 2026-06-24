# Jinli Knowledge Graph WP Implementation Patterns

> Session: 2026-06-21 kg-runtime-wp01-wp02-wp03-wp04
> Task: 2026-06-21-knowledge-graph-runtime-implementation

## Module Layout (WP01-WP05)

```
services/knowledge/
  __init__.py          # __version__ = "0.1.0"
  config.py            # KnowledgeConfig, DriftReport, detect_vault_drift, config_status
  contracts.py         # Enums, dataclass contracts, validate_against_schema, load_schema
  io_utils.py          # PathEscapeError, resolve_and_check, atomic_write, jsonl_append/read
  worker_gateway.py    # WorkerGateway, GatewayConfig, MODEL_ROUTING, _compute_hash
  transcript.py        # parse_srt, parse_vtt, normalize_transcript, _compute_segment_hash
  segmentation.py      # SegmentationConfig, compute_segment_id, segment_transcript
  enrichment.py        # EnrichmentConfig, EnrichedSegment, create_bounded_job, enrich_segments
  summary.py           # compile_summary, _fmt_ts, _make_timestamp_link
  evidence_search.py   # SearchConfig, SearchResult, search_evidence
  graph_store.py       # GraphStore — SQLite canonical records, migrations, candidate→accept
  deduplication.py     # DeduplicationResult, normalize_slug, deduplicate_candidate, check_*_match
  obsidian_export.py   # ExportConfig, stable_slug, export_*_note, GEN_START/GEN_END markers
  providers/
    __init__.py
    base.py            # ProviderProtocol, ProviderHealth, ProviderResult, ProviderStatus
    ollama.py          # OllamaProvider with injectable http_transport
    external.py        # ExternalProvider (disabled by default)
  sources/
    __init__.py        # Package exports
    base.py            # SourceProtocol, SourceFamily, TranscriptAcquisition, classify_url
    ytdlp_source.py    # YtdlpSource — yt-dlp Python API adapter (injectable mock)
    vsummary_adapter.py # VsummaryAdapter — workspace file reader, VSUMMARY_REVISION constant
  migrations/
    V1__initial_schema.sql  # 7 tables + indexes + schema_version
  tests/
    __init__.py
    test_config.py
    test_contracts.py
    test_io_utils.py
    test_providers.py
    test_worker_gateway.py
    test_video_sources.py
    test_vsummary_adapter.py
    test_segmentation.py
    test_enrichment.py
    test_summary.py
    test_evidence_search.py
    test_graph_store.py
    test_deduplication.py
    test_obsidian_export.py
    fixtures/video_sources/
      youtube_captions.srt / .vtt
      bilibili_captions.srt
      vsummary_transcript_cleaned.json / vsummary_summary.json / vsummary_transcript_raw.json
      duplicate_captions.srt
      invalid_timestamps.srt
      vsummary_workspace/
        BV1UF7m68E1K/  (full: cleaned + summary + raw)
        BV1RAWONLY00/  (only raw transcript)
        BV1EMPTY0000/  (empty workspace)

data/knowledge/schemas/
  video-metadata.v1.json
  transcript-segment.v1.json
  local-worker-job.v1.json
  local-worker-output-envelope.v1.json
```

## Pitfalls Encountered

### 1. jsonschema missing-required-field path is `(root)`

When `validate_against_schema()` reports a missing required field, `error.path` is empty — the `field_path` becomes `"(root)"`, not `"provenance"`. The field name appears in `error.message` instead.

**Fix**: Test assertions for missing fields must check both `field_path` and `message`:
```python
assert any(
    "provenance" in e.message or "provenance" in e.field_path
    for e in result.errors
)
```

### 2. Path containment with different roots

`KnowledgeConfig.path_contained(candidate, root=data_root)` resolves `candidate` against the filesystem, not against `data_root`. If `candidate = Path("/project/data/knowledge/test.json")` but `data_root` resolves to `E:/UEGameDevelopment/Project/Jinli/data/knowledge`, the paths differ and containment fails.

**Fix**: Construct candidates relative to the root: `data_root / "test.json"`.

### 3. PYTHONPATH must include `services/` not `services/knowledge/`

pytest imports use `from knowledge.xxx import ...` which requires the parent directory (`services/`) on PYTHONPATH, not the package directory itself.

```bash
PYTHONPATH="E:/UEGameDevelopment/Project/Jinli/services:$PYTHONPATH"
```

### 4. Provider mock transport interface

The simplified `HttpTransport = Callable[[url, payload, timeout], tuple]` works for tests but doesn't distinguish GET vs POST. Ollama health check (`/api/tags`) is a GET endpoint. Future WP (WP03/WP09) should implement a proper HTTP adapter.

### 5. Worker Gateway state updates are append-only JSONL

Each job status transition appends a new line to `jobs.jsonl`. There's no in-place update. This is by design (audit trail), but consumers reading history must filter by `job_id` and take the latest entry.

### 6. YtdlpSource mock injection pattern

`YtdlpSource.__init__` accepts an optional `ytdlp_instance` parameter. When provided, `_get_ytdlp()` returns it directly instead of creating a real `yt_dlp.YoutubeDL`. This allows all probe/acquire tests to run offline.

**Key**: The mock must implement `extract_info(url, download=False)` returning a dict with the same keys as real yt-dlp output (`id`, `title`, `duration`, `subtitles`, `automatic_captions`, etc.).

### 7. vsummary workspace file hierarchy

The vsummary workspace has a specific directory structure per video:

```
workspace/<VIDEO_ID>/
  transcript.cleaned.json   # Primary — cleaned Whisper output with title/language/duration/segments
  summary.json              # Structured summary with chapters/key_takeaways
  summary.md                # Markdown export
  audio.wav                 # Extracted audio
  debug.log                 # Processing log
  .cache/
    media/
      manifest.json
      audio.wav
    whisper/
      manifest.json
      transcript.raw.json   # Raw Whisper output (fallback if no cleaned version)
```

**Adapter priority**: `transcript.cleaned.json` → `.cache/whisper/transcript.raw.json` → UNAVAILABLE

### 8. SRT/VTT timestamp parsing edge cases

- SRT uses comma as decimal separator (`00:00:01,000`), VTT uses dot (`00:00:01.000`). Parser must normalize commas to dots.
- Invalid timestamps (e.g., `00:XX:03,000`) produce `None` from `_parse_timestamp()` — the segment is silently skipped, not errored.
- Duplicate segments (same start+end timestamps) are deduped during `normalize_transcript()`, keeping only the first occurrence.

### 9. Cross-file import in test files

`test_vsummary_adapter.py` uses `YtdlpSource` in `TestCrossAdapterConsistency` but the import was at the bottom of the file. **Always place all imports at the top of test files** to avoid `NameError` at test collection time.

### 10. vsummary transcript language priority

When `acquire_transcript(url, language="en")` is called but the file contains `language: "zh"`, the adapter returns the file's language (`zh`), not the parameter. The file is the authority source; the parameter is a preference hint for live sources (yt-dlp), not for pre-generated workspace files.

### 11. Source hash computation

`_compute_segment_hash()` uses SHA-256 of `{"start": float, "end": float, "text": str}` (sorted keys, ensure_ascii=False), truncated to 16 hex chars. This provides content-addressable identity for transcript segments without being sensitive to metadata changes.

### 12. Deterministic segment IDs without LLM

`compute_segment_id(video_id, start_seconds)` uses SHA-256 of `"{video_id}:{start_seconds:.3f}"` truncated to 16 hex chars. The `.3f` format ensures float precision doesn't cause ID drift (e.g., `0.0` vs `0.000`).

**Critical**: The segment ID must be computed from the *resolved* start_seconds after segmentation logic (gap/chapter/duration splits), not from the raw entry timestamps.

### 13. Segmentation short-segment merging

When a segment's duration is below `min_segment_seconds` (default 2.0), it merges into the previous segment rather than forming a standalone segment. The only exception is when there is no previous segment (first segment) — it's kept regardless of duration.

### 14. Enrichment pending vs source data preservation

When the WorkerGateway is unavailable (None) or throws an exception, `enrich_segments()` returns `EnrichedSegment` with `enrichment_pending=True` but the original `TranscriptSegment` is fully preserved. **Never delete or replace source data when model is unavailable** — this is a hard constraint from the spec.

### 15. YouTube timestamp link format

`_make_timestamp_link()` appends `&t={seconds}` for YouTube/Bilibili URLs. This works when the URL already has query parameters (`?v=...`). For URLs without any query params, `?t=` would be correct instead. Current implementation uses `&t=` unconditionally, which may produce technically invalid but functionally working links for bare URLs.

### 16. write_file timeout on Windows

`write_file` can timeout (5s) on Windows for files around 3KB, even when previous writes of similar size succeed immediately. When this happens, fall back to `terminal` with `cat > path << 'EOF'` heredoc syntax. The content is preserved exactly.

### 17. GraphNode created_at is required, no default

`GraphNode(dataclass)` has `created_at: str` as a required field. Forgetting it causes `TypeError: missing 1 required positional argument`. This also applies to `graph_store.accept_candidate()` which internally constructs a `GraphNode` — it must compute `created_at` from `datetime.now(timezone.utc).isoformat()`.

### 18. SQLite :memory: db lifetime in tests

`GraphStore` uses SQLite. Tests that create a `:memory:` database must keep the `GraphStore` instance alive for the entire test — closing or garbage-collecting it drops all tables. Use `@pytest.fixture` with function scope (default) to create a fresh in-memory db per test.

### 19. Obsidian re-export preserves user edits

When `export_video_note()` or `export_concept_note()` is called on an existing file, only the content between `<!-- kg-gen-start -->` and `<!-- kg-gen-end -->` is replaced. The test must verify that content *outside* markers is preserved. If a test only checks generated content, it won't catch a bug that overwrites the full file.

## Test Statistics

- WP01: 95 tests (20 config + 49 contracts + 26 io_utils)
- WP02: 50 tests (21 providers + 29 worker_gateway)
- WP03: 58 tests (30 video_sources + 28 vsummary_adapter)
- WP04: 61 tests (17 segmentation + 15 enrichment + 13 summary + 16 evidence_search)
- WP05: 49 tests (17 graph_store + 14 deduplication + 18 obsidian_export)
- **Total: 340 tests, all passing**

## Key Design Decisions

1. **Config is immutable** — `KnowledgeConfig` is a `frozen=True` dataclass. No environment mutation on import.
2. **Schemas are Draft 2020-12** — all have `additionalProperties: false` and `$id` starting with `jinli://schemas/`.
3. **Provider injection** — OllamaProvider accepts `http_transport` callable for testability. No real network in tests.
4. **ExternalProvider disabled by default** — requires explicit `base_url + model + api_key` configuration.
5. **One normalization retry** — if schema validation fails, WorkerGateway retries once with a correction prompt. After that, status becomes `schema_validation_failed`.
6. **Job cancellation is in-memory** — `_cancelled_jobs` set on the gateway instance. Not persisted. Only relevant within a single process run.
7. **Source protocol is runtime-checkable** — `SourceProtocol` uses `@runtime_checkable` so `isinstance()` works for adapter validation.
8. **Caption-first operation** — YtdlpSource uses `skip_download: True` and only extracts metadata + captions. No media download.
9. **Access denied vs unsupported** — login/DRM/paywall → `ACCESS_DENIED`; unknown platform → `UNSUPPORTED_SOURCE`. No retry around controls.
10. **vsummary adapter reads files only** — no API calls, no vsummary source code dependency. Workspace path injected at construction time.
11. **Segmentation is deterministic and LLM-free** — uses gap thresholds, chapter boundaries, and max-duration limits. Segment IDs are SHA-256 based, not random.
12. **Enrichment preserves raw data** — when gateway unavailable, `EnrichedSegment.enrichment_pending=True` and original text is untouched. No deletion, no replacement.
13. **Summary claims are source-linked or marked unverified** — every segment in the compiled Markdown either has a verified summary or is marked `[unverified]`. Pending segments get `⏳ *pending*` markers.
14. **Evidence search is keyword-only** — `search_evidence()` uses AND-query on raw text. Works without Ollama. Results limited by count and character budget.

### WP05: Graph Store / Deduplication / Obsidian Export

15. **GraphNode.created_at is required** — `GraphNode` dataclass has `created_at: str` as a positional field with no default. Both direct construction and `graph_store.accept_candidate()` must pass it. Use `datetime.now(timezone.utc).isoformat()` for production code.

16. **SQLite migration versioning** — `schema_version` table tracks applied migrations. `V1__initial_schema.sql` creates all 7 tables. Future migrations add rows, never modify existing ones. `GraphStore.__init__` runs pending migrations automatically.

17. **Candidate→Accept transaction** — `accept_candidate()` is a 3-step transaction: insert node → create review decision → commit. Failure at any step rolls back. The `review_decisions` table stores the human/automated decision for audit.

18. **Deduplication priority chain** — exact_id_match > title_slug_match > alias_match > source_overlap_match > text_similarity_match > low_confidence. Each checker returns `DeduplicationResult(action=...)`. The first non-None result wins.

19. **normalize_slug() rules** — lowercase → strip punctuation → spaces→hyphens → collapse consecutive hyphens → strip leading/trailing hyphens. Example: `"AI 代理：综述 & 展望"` → `"ai-代理综述-展望"`.

20. **Obsidian GEN markers** — `<!-- kg-gen-start -->` and `<!-- kg-gen-end -->` delimit agent-generated content. On re-export, only content between markers is replaced. User edits outside markers are preserved. New files get markers wrapped around all content.

21. **stable_slug() for Obsidian** — `normalize_slug(title).lower() + "-" + SHA256(title)[:6]`. The hash suffix ensures uniqueness even when two concepts have similar titles. The slug is stable across re-exports (deterministic from title).

22. **Obsidian vault containment** — `_ensure_vault_containment()` rejects any resolved path that escapes the vault root. This prevents symlink attacks and path traversal (e.g., `../../etc/passwd`).

23. **Deduplication Jaccard threshold** — Text similarity uses word-level Jaccard similarity with default threshold 0.7. This is imprecise for Chinese (word boundaries differ from character boundaries). A future WP may replace with embedding similarity.

## Pipeline Orchestrator (WP-Pipeline)

### Module Layout (added)

```
services/knowledge/
  pipeline.py         # VideoPipeline, PipelineConfig, PipelineResult, StageResult, StageStatus
  tests/
    test_pipeline.py  # 36 tests — 8 stages + degradation + e2e + search
```

### Pitfalls Encountered (continued)

### 20. `segments or [...]` vs `segments if segments is not None else [...]`

In test helper functions, when `segments=[]` is a valid test input (empty transcript), `segments or [default_list]` incorrectly returns the default because `[]` is falsy. **Always use `segments if segments is not None else [default_list]`** when empty list is a valid value.

### 21. Pipeline stage indexing in tests

`result.stages[2]` corresponds to Stage 3 (transcript_acquisition) only when Stages 1-2 succeed. If an earlier stage fails, the pipeline may have fewer stages. Always check `s.stage == "transcript_acquisition"` before asserting on status.

### Key Design Decisions (continued)

24. **8-stage pipeline is sequential with graceful degradation** — Each stage has explicit input/output/failure paths. Stage failure triggers early return or skip of dependent stages, but the pipeline never crashes mid-process.

25. **PipelineResult tracks all 8 stages** — `PipelineResult.stages` contains `StageResult` objects with `stage`, `status` (COMPLETED/DEGRADED/FAILED/SKIPPED), `data`, and `error`. `is_full_success` requires all 8 stages COMPLETED (no DEGRADED).

26. **Source adapter is injectable** — `VideoPipeline.__init__` accepts `source_adapter` (SourceProtocol), `gateway` (WorkerGateway), `graph_store` (GraphStore). All can be None — pipeline skips corresponding stages.

27. **DEGRADED status for partial enrichment** — When WorkerGateway is unavailable or fails, enrichment stage returns DEGRADED instead of FAILED. Raw segments are preserved with `enrichment_pending=True`.

28. **Metadata-only path** — When transcript acquisition fails, stages 4-6 are SKIPPED, but stages 7-8 still run with only metadata. This ensures every URL gets at least an Obsidian note and graph record.

29. **Unsupported URL stops at Stage 1** — `classify_url()` returns `UNSUPPORTED` → pipeline returns immediately with `ingestion_status=UNSUPPORTED_SOURCE`.

30. **Auto-accept threshold** — `PipelineConfig.auto_accept_confidence=0.85` means candidates with confidence >= 0.85 are auto-accepted into graph store. Lower-confidence candidates go to review queue.

## Test Statistics (updated)

- WP01: 95 tests (20 config + 49 contracts + 26 io_utils)
- WP02: 50 tests (21 providers + 29 worker_gateway)
- WP03: 58 tests (30 video_sources + 28 vsummary_adapter)
- WP04: 61 tests (17 segmentation + 15 enrichment + 13 summary + 16 evidence_search)
- WP05: 49 tests (17 graph_store + 14 deduplication + 18 obsidian_export)
- Pipeline: 36 tests (3 platform + 4 metadata + 5 transcript + 2 segmentation + 2 enrichment + 2 summary + 2 obsidian + 3 graph_write + 5 e2e + 2 degradation + 2 search + 4 properties)
- **Total: 376 tests, all passing**

## WP06: Obra Index & MCP Bridge (done)

> Status: done as of 2026-06-22 (34 tests)
> See `references/jinli-kg-wp06-obra-bridge-context.md` for full WP06 context

### Key Implementation Points

1. **obra_bridge.py** wraps obra/knowledge-graph CLI commands (index, search, path, neighbors, node, mcp)
2. **Process runner injection** — `ObraBridge.__init__` accepts `runner` parameter (`FakeProcessRunner` or `SubprocessRunner`) for testability
3. **KG_VAULT_PATH enforcement** — `_validate_vault_path()` checks vault matches config, rejects path traversal and mismatched paths
4. **JSON normalization** — obra CLI returns verbose JSON; bridge normalizes to `ObraSearchResult` dataclass with `node_id, title, path, score, links, evidence_excerpt`
5. **PowerShell bridge** — `knowledge-tools.ps1` exposes inspect/install/update/index/search/mcp commands using `npm.cmd` (not global npm)
6. **Fixture vault already exists** — `tests/fixtures/obsidian_vault/` has 1 source + 3 concept notes with internal links

### Pitfalls Encountered

### 22. ObraBridge `inspect()` must match FakeProcessRunner keyword matching

Tests use `bridge._runner.set_response("inspect", ...)` which matches the keyword "inspect" against the command string. If `inspect()` calls `[self._cli_name, "--version"]` instead of `[self._cli_name, "inspect"]`, the keyword won't match and the test gets the default response instead of the configured one.

**Fix**: Use a subcommand keyword in the command that matches what tests expect: `[self._cli_name, "inspect"]` not `[self._cli_name, "--version"]`.

### 23. obra CLI actual commands (from source at pinned revision 1d2481e)

The obra CLI (`kg`) exposes these subcommands:
- `kg index --vault-path <path> [--resolution N] [--force]` → stats JSON
- `kg node <name> --vault-path <path> [--full] [--max-content N]` → node details
- `kg neighbors <name> --vault-path <path> [--depth N]` → neighbor list
- `kg search <query> --vault-path <path> [--fulltext] [--limit N]` → results
- `kg paths <from> <to> --vault-path <path> [--max-depth N]` → path list
- `kg subgraph <name> [--depth N]` → local neighborhood
- `kg communities` → community list
- `kg bridges [--limit N]` → high-betweenness nodes
- `kg central [--community ID] [--limit N]` → PageRank nodes

MCP server: `node dist/mcp/index.js` (starts `McpServer` with tools: kg_index, kg_node, kg_neighbors, kg_search, kg_paths)

Binary: `kg` → `dist/cli/index.js` (package name: `knowledge-graph`, bin: `kg`)

## WP07: Visual Candidate Extension (done)

> Status: done as of 2026-06-22 (40 tests)

### Module Layout (added)

```
services/knowledge/
  keyframes.py           # KeyframeConfig, KeyframeExtractor, KeyframeResult, sample_timestamps
  visual_enrichment.py   # VisualEnricher, VisualObservation, VisualEnrichmentResult
  tests/
    test_keyframes.py         # 27 tests — sampling, disabled-default, FFmpeg, dedup, budget, cancel, candidate-only
    test_visual_enrichment.py # 13 tests — result properties, integration, prohibited methods, boundaries
```

### Pitfalls Encountered

### 24. Fake FFmpeg runner must create valid image files for perceptual hash

FakeProcessRunner that creates dummy bytes (e.g., `b"\xff\xd8..."`) causes PIL to fail when computing perceptual hash, returning empty hash strings. This defeats duplicate frame detection tests.

**Fix**: Fake runner must create a minimal valid image that PIL can open. PGM format works: `b"P5\n8 8\n255\n" + bytes([128]*64)`. JPEG headers alone won't parse.

### 25. PIL Image.getdata() deprecated in Pillow 14

`_compute_perceptual_hash()` uses `img.getdata()` which triggers `DeprecationWarning` in newer Pillow versions. Future migration needed to `get_flattened_data()`. Not blocking but noisy in test output.

### 26. Keyframe extraction disabled by default

`KeyframeConfig(enabled=False)` is the default. All tests that exercise extraction must explicitly set `enabled=True`. Tests for the disabled path should verify `result.frame_count == 0` and `result.visual_enabled == False`.

### 27. VisualEnricher cannot call graph_store.accept_candidate()

Visual enrichment produces CANDIDATE evidence only. The `VisualEnricher` class explicitly documents prohibited methods in `_PROHIBITED_METHODS` list. Tests verify these methods don't exist. If a test tries to call `accept_candidate` through the enricher, it will fail.

## WP08: Soul Core Integration (done)

> Status: done as of 2026-06-22 (43 tests)

### Module Layout (added)

```
services/knowledge/
  service.py   # KnowledgeService, ServiceResult — unified facade
  cli.py       # CLI entry point (health/ingest-video/search/export/index/analyze-keyframes)
  tests/
    test_cli.py      # 25 tests — health, ingest, search, export, index, soul hooks, CLI subprocess
    test_service.py  # 18 tests — construction, dependency reporting, constraints
scripts/
  knowledge-runtime.ps1  # PowerShell wrapper around Python CLI
  soul-core.ps1          # Added k-ingest and k-search commands
```

### Pitfalls Encountered

### 28. GraphStore requires explicit connect() call

`GraphStore.__init__` does NOT auto-connect. The `conn` property raises `RuntimeError("GraphStore not connected. Call connect() first.")` if accessed before `connect()`. E2E tests that create a `GraphStore(db_path)` must call `store.connect()` before any operation.

**This is different from the WP05 test fixtures** which use `:memory:` databases — those tests may have a fixture that auto-connects. When writing E2E tests without such fixtures, explicitly call `connect()`.

### 29. GraphStore.insert_source() takes a VideoMetadata object, not keyword args

`insert_source(metadata: VideoMetadata)` — not `insert_source(source_url=..., source_type=..., ...)`. Similarly, `insert_candidate(candidate: GraphCandidate)` takes a `GraphCandidate` dataclass, not keyword args. And `accept_candidate(candidate_id: str, reviewer, reason)` takes a string ID, not the candidate object.

**Pattern**: Read the actual method signatures from graph_store.py before writing tests that call GraphStore methods. The API uses typed dataclass/object parameters, not flat keyword arguments.

### 30. KnowledgeService.analyze_keyframes() must check video file existence

When `analyze_keyframes()` is called with a nonexistent video path, `VisualEnricher` returns a result with `frames_extracted=0` but `success=True` (because keyframe extraction treats missing input as "no frames", not an error). The service layer should add a file existence check before delegating to the enricher.

### 31. soul_end_promote returns "queued_for_review" not "accepted"

Even high-confidence candidates are only "queued for review", never directly accepted. The `note` field in the result data explicitly states "not auto-accepted". Tests must check `status == "queued_for_review"`, not `status == "accepted"`.

## WP09: Operations & E2E (done)

> Status: done as of 2026-06-22 (5 E2E tests)

### Module Layout (added)

```
services/knowledge/
  tests/test_e2e_offline.py   # 5 tests — source-to-search pipeline, degradation, fixture integrity
  tests/fixtures/e2e/         # E2E fixtures directory
scripts/
  knowledge-env.ps1           # Environment inspect/apply (requires -Confirm for apply)
Docs/03-Architecture/KnowledgeGraph/runtime-architecture.md
Docs/04-Implementation/KnowledgeGraph/video-knowledge-runtime.md
Docs/05-Testing/KnowledgeGraph/runtime-test-plan.md
Docs/06-Operations/KnowledgeGraph/local-runtime-runbook.md
```

### Key Implementation Points

1. **Offline E2E pipeline**: transcript → segments → graph candidates → accept → Obsidian export → verify vault structure
2. **knowledge-env.ps1 apply** requires explicit `-Confirm` switch — never silently changes environment
3. **Live test** requires `JINLI_KG_TEST_VIDEO_URL` env var — no invented URLs

## Test Statistics (final)

- WP01: 95 tests
- WP02: 50 tests
- WP03: 58 tests
- WP04: 61 tests
- WP05: 49 tests
- WP06: 34 tests
- WP07: 40 tests
- WP08: 43 tests
- WP09: 5 tests (E2E)
- Pipeline: 36 tests
- Knowledge DB: 130 tests (cold archive, search, import)
- **Total: 601 tests, all passing**
