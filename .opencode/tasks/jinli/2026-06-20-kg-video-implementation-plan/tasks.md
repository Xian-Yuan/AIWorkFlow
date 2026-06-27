# Tasks: Jinli Knowledge Graph + Video Implementation Plan

## Dependency Graph

```text
T1 split decision -> T2 first-slice design -> T3 Ba Ba confirmation -> T4 implementation packet
```

---

## Plan

- [x] T1.1: Decide whether Mentor Mode and KG/video optimization should be combined.
- [x] T1.2: Create KG/video implementation planning packet separate from Mentor Mode.
- [x] T1.3: Define first vertical slice and acceptance criteria.
- [x] T1.4: Keep local-worker token optimization inside the KG/video packet because it directly supports ingestion/retrieval.
- [x] T1.5: Make video URL to text summary an explicit user-facing capability of the first slice.
- [x] T1.6: Add `Local Worker Gateway` as the controlled interface for local Ollama workers.
- [x] T1.7: Record daily/coding/Jinli local-model uses as future expansion candidates, not current KG/video scope.
- [x] T1.8: Ba Ba reviews whether to proceed with the first slice. (Confirmed 2026-06-20)

## Implement — Design Document Enrichment (v2.1)

- [x] T2.1: Define JSON schemas for video metadata, transcript segment, and local worker job. (Added sections 17.1-17.4 to spec)
- [x] T2.2: Create `Project/Jinli/data/knowledge/` cache layout. (Added section 20 to spec)
- [x] T2.3: Define Local Worker Gateway contract with flow, model routing, authority boundary, failure policy. (Added section 18 to spec)
- [x] T2.4: Define video pipeline I/O specification with input, output, stages, and failure paths. (Added section 19 to spec)
- [x] T2.5: Define first-slice implementation boundaries with in-scope, out-of-scope, and verification criteria. (Added section 21 to spec)
- [x] T2.6: Update spec version from v2.0 to v2.1 with change log.
- [x] T2.7: Update DOCS_TREE.md with new entry for kg-video-implementation-plan.
- [x] T2.8: Update doc-impact.md with documentation change evidence.
- [x] T2.9: Run doc-guard and task-guard verification and record results in verification-report.md.
- [x] T2.10: Verify selected mature path was implemented and no rejected shortcut was introduced.
- [x] T2.11: Run automated verification and record command output in verification-report.md.
- [x] T2.12: Map implementation result to Acceptance Criteria in verification-report.md.

> Future code implementation tasks (T3.x, T4.x) are defined in the spec document section 21 and will be tracked in a separate implementation packet when Ba Ba authorizes code work.
