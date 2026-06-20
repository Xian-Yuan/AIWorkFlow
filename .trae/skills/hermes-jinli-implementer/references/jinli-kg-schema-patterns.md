# Jinli Knowledge Graph Schema Patterns

> Session: 2026-06-20 kg-video-implementation-plan
> Source: Project/Jinli/docs/02-Design/General/soul-core-phase2.5-knowledge-evolution-spec.md v2.1 sections 17-21

## Schema Naming Convention

- Format: `<domain-entity>.v<N>` where N starts at 1
- `$id`: `jinli://schemas/<name>.v<N>`
- All schemas use JSON Schema draft-07
- `additionalProperties: false` on all schemas (strict validation)

## ID Patterns

| Entity | Pattern | Example |
|--------|---------|---------|
| Video | `kg-video-YYYYMMDD-NNNN` | `kg-video-20260620-0001` |
| Segment | `kg-seg-YYYYMMDD-NNNN-NNN` | `kg-seg-20260620-0001-001` |
| Worker Job | `local-llm-YYYYMMDD-NNNN` | `local-llm-20260620-0001` |

## Key Schemas (defined in spec section 17)

1. **video-metadata.v1** — Video metadata with ingestion_status enum: `metadata_only | caption_extracted | whisper_transcribed | unsupported_source | access_denied`
2. **transcript-segment.v1** — Timestamped segment with enrichment fields (summary, entities, relations, confidence)
3. **local-worker-job.v1** — Job tracking with status: `queued | running | completed | failed | schema_validation_failed`
4. **local-worker-output-envelope.v1** — Wrapper with validation_status: `pending | valid | invalid`

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

## First Slice Boundaries (spec section 21)

In scope: YouTube + Bilibili captions, qwen3:14b summarization, video_segment records, Obsidian export, keyword search, graceful fallback.
Out of scope: full graph DB, vector search, Whisper, MiniCPM-V, memory.md import, soul lifecycle, non-KG uses.
