# Spec: Jinli Knowledge Graph + Video Ingestion Design Update

## GIVEN
Jinli already has a Phase 2.5 knowledge evolution spec and local memory artifacts. Ba Ba asked whether a local design exists and requested that Jinli update the existing design if present, otherwise create a new rules-compliant design document.

## WHEN
The existing design is updated.

## THEN
The updated design must cover local knowledge graph ingestion, Obsidian export, local LLM worker routing, video-link summarization, and future video-based information retrieval.

### S1 Existing Design Reuse
**Status**: [x]

GIVEN `Project/Jinli/docs/02-Design/General/soul-core-phase2.5-knowledge-evolution-spec.md` exists
WHEN this task updates the design
THEN the existing file is the canonical target
AND no new parallel design document is created.

### S2 Video Knowledge Ingestion
**Status**: [x]

GIVEN Ba Ba provides a video URL from a mainstream supported platform
WHEN the future system ingests the URL
THEN it should produce transcript-backed summaries, timestamped notes, entities, relations, and source citations suitable for graph retrieval.

### S3 Local Model Worker Boundaries
**Status**: [x]

GIVEN local Ollama models are available under `E:\Ollama\models`
WHEN the design assigns work to local models
THEN it must restrict them to bounded, verifiable extraction, summarization, classification, reranking, OCR, and keyframe analysis tasks
AND reserve architecture and final acceptance for the lead agent/human workflow.

## Acceptance Criteria

| AC# | Description | Verification Command | Expected Output |
|-----|-------------|---------------------|-----------------|
| AC01 | Existing design document is reused | `Test-Path Project/Jinli/docs/02-Design/General/soul-core-phase2.5-knowledge-evolution-spec.md` | `True` |
| AC02 | Updated design includes video ingestion | `Select-String -Path Project/Jinli/docs/02-Design/General/soul-core-phase2.5-knowledge-evolution-spec.md -Pattern "Video Knowledge Ingestion"` | At least one match |
| AC03 | Updated design includes local model routing | `Select-String -Path Project/Jinli/docs/02-Design/General/soul-core-phase2.5-knowledge-evolution-spec.md -Pattern "qwen3:14b","qwen2.5-coder:14b","openbmb/minicpm-v4.6"` | Matches for all models |
| AC04 | Updated design includes Obsidian graph boundaries | `Select-String -Path Project/Jinli/docs/02-Design/General/soul-core-phase2.5-knowledge-evolution-spec.md -Pattern "Obsidian","source of truth"` | Matches present |
| AC05 | Task verification evidence is recorded | `Test-Path .trae/tasks/jinli/2026-06-20-knowledge-graph-video-ingestion/verification-report.md` | `True` |

## Quality Checklist

### Completeness
- [x] [OK] All requested sources are covered.
- [x] [OK] Each scenario has input and expected output.
- [x] [OK] Acceptance Criteria cover the main scenarios.

### Clarity
- [x] [OK] Video ingestion, graph storage, and local workers are explicitly separated.
- [x] [OK] Third-party/external tool interactions are marked as future implementation dependencies.

### Consistency
- [x] [OK] Existing Jinli terminology and file locations are reused.
- [x] [OK] Documentation target is under `Project/Jinli/docs/02-Design/General`.

### Scenario Coverage
- [x] [OK] Main path, local-worker boundary, and existing-doc reuse are covered.

### Edge Case Coverage
- [x] [OK] Unsupported platforms, missing subtitles, and local model failure are required in the updated design.

## Progress Summary

| Phase | Status | Key Decision |
|-------|--------|-------------|
| Plan | Complete | Reuse and overwrite existing Phase 2.5 spec |
| Implement | Pending | Update design doc and docs tree |
| Review | Pending | Verify AC markers |
| Verify | Pending | Record final evidence |

## Non-Goals

- Implementing video download, transcript, or graph database code in this task.
- Installing external tools.
- Changing Jinli runtime scripts.
