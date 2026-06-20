# Spec: Jinli Knowledge Graph + Video Implementation Plan

## GIVEN
The Jinli Phase 2.5 design has been upgraded to v2.0 with local knowledge graph, Obsidian export, local model workers, and video ingestion.

## WHEN
Ba Ba decides to proceed from design into implementation planning.

## THEN
The first build slice should be bounded, verifiable, and aligned with Mentor Mode: it should provide capability without forcing premature product direction.

### S1 Packet Separation
**Status**: [x] done

GIVEN Mentor Mode and KG/video infrastructure have different success criteria
WHEN task packets are designed
THEN they remain separate
AND this packet references the Mentor Mode packet only as a cross-cutting interaction boundary.

### S2 First Build Slice
**Status**: [x] done

GIVEN full graph/video ingestion is large
WHEN implementation begins
THEN the first slice should ingest one accessible video URL, extract metadata/captions or transcript, summarize into timestamped segments, write structured records, and export one Obsidian note.

### S3 Video Link To Text Summary
**Status**: [x] done

GIVEN Ba Ba provides a supported public video link
WHEN captions are available or transcription is allowed
THEN Jinli should produce a text summary backed by transcript or caption evidence
AND include timestamped notes that can be reused later.

### S4 Mainstream Platform Boundaries
**Status**: [x] done

GIVEN the design targets mainstream video websites
WHEN a platform requires login, blocks download, lacks captions, or uses unsupported DRM
THEN Jinli should fail gracefully with metadata-only or unsupported-source status
AND must not bypass access controls.

### S5 Local Worker Token Saving
**Status**: [x] done

GIVEN transcript cleanup, chunk summaries, entity extraction, JSON normalization, or reranking are simple and repeatable
WHEN local Ollama models are available
THEN `qwen3:14b`, `qwen2.5-coder:14b`, or `openbmb/minicpm-v4.6:latest` may handle bounded worker jobs
AND every worker output must be schema-checked before becoming canonical knowledge.

### S6 Local Worker Gateway
**Status**: [x] done

GIVEN Jinli or Codex needs local-model assistance for the KG/video pipeline
WHEN the task is sent to a local model
THEN it must go through a `Local Worker Gateway` job record
AND the flow must be `job JSON -> Ollama call -> schema validation -> derived cache -> compact evidence returned to lead`.

### S7 Future Non-KG Expansion
**Status**: [x] done

GIVEN daily tasks, coding support, and broader Jinli runtime work can also benefit from local models
WHEN those uses are considered
THEN this packet should record them as future expansion candidates
AND not expand the first KG/video implementation scope.

### S8 Future Retrieval
**Status**: [x] done

GIVEN video segment records exist
WHEN Ba Ba asks a related question later
THEN Jinli should be able to retrieve the relevant video title and timestamp instead of reprocessing the whole video.

## Acceptance Criteria

| AC# | Description | Verification Command | Expected Output |
|-----|-------------|---------------------|-----------------|
| AC01 | Packet references v2.0 design | `Select-String -Path .trae/tasks/jinli/2026-06-20-kg-video-implementation-plan/analysis.md -Pattern "v2.0"` | Match |
| AC02 | First build slice is bounded | `Select-String -Path .trae/tasks/jinli/2026-06-20-kg-video-implementation-plan/spec.md -Pattern "one accessible video URL"` | Match |
| AC03 | Mentor packet is separate | `Select-String -Path .trae/tasks/jinli/2026-06-20-kg-video-implementation-plan/routing.md -Pattern "Related Mentor packet"` | Match |
| AC04 | Doc governance evidence exists | `Test-Path .trae/tasks/jinli/2026-06-20-kg-video-implementation-plan/doc-impact.md` | True |
| AC05 | Video URL to text summary is explicit | `Select-String -Path .trae/tasks/jinli/2026-06-20-kg-video-implementation-plan/spec.md -Pattern "Video Link To Text Summary"` | Match |
| AC06 | Local worker token saving is explicit | `Select-String -Path .trae/tasks/jinli/2026-06-20-kg-video-implementation-plan/spec.md -Pattern "Local Worker Token Saving"` | Match |
| AC07 | Local Worker Gateway is explicit | `Select-String -Path .trae/tasks/jinli/2026-06-20-kg-video-implementation-plan/spec.md -Pattern "Local Worker Gateway"` | Match |
| AC08 | Non-KG expansion is bounded | `Select-String -Path .trae/tasks/jinli/2026-06-20-kg-video-implementation-plan/spec.md -Pattern "Future Non-KG Expansion"` | Match |

## Quality Checklist

### Completeness
- [x] [OK] Covers task split, first slice, and retrieval outcome.
- [x] [OK] Names data ownership and implementation surfaces in analysis.
- [x] [OK] Makes video link summarization and mainstream-platform fallback explicit.
- [x] [OK] Includes local model routing as a token-saving mechanism.
- [x] [OK] Defines Local Worker Gateway as the controlled local-model interface.
- [x] [OK] Captures daily/coding/Jinli local-worker uses without expanding this packet scope.

### Clarity
- [x] [OK] Does not start implementation automatically.
- [x] [OK] Does not merge Mentor Mode into infrastructure acceptance.

### Consistency
- [x] [OK] Reuses v2.0 Jinli design and task-packet workflow.

### Scenario Coverage
- [x] [OK] Covers separation, ingestion, and retrieval scenarios.

### Edge Case Coverage
- [x] [OK] Full implementation is explicitly deferred until Ba Ba confirms.

## Progress Summary

| Phase | Status | Key Decision |
|-------|--------|-------------|
| Plan | Complete | First slice is video -> segments -> searchable/exportable notes |
| Implement | Complete | v2.1 design enrichment completed; no runtime code written |
| Review | Complete | Documentation-only scope accepted |
| Verify | Complete | verification-report.md maps evidence to acceptance criteria |

## Non-Goals

- Do not implement video ingestion in this planning packet.
- Do not install external tools.
- Do not decide the final graph database yet.
- Do not bypass login, paywalls, DRM, or platform access restrictions.
- Do not let local workers mutate task packets or project architecture.
- Do not implement non-KG daily/coding/local-worker automation in this packet.
