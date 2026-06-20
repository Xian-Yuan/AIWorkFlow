# Tasks: Jinli Knowledge Graph + Video Ingestion Design Update

## Dependency Graph

```
T1 task packet -> T2 gates -> T3 doc update -> T4 docs tree -> T5 verification
```

---

## Planning

- [x] T1.1: Identify existing local design document for Jinli knowledge graph / Obsidian integration.
- [x] T1.2: Create task packet with architecture context, quality gate, and doc-impact evidence.
- [x] T1.3: Run plan gate before editing project documentation.
- [x] T1.4: Run can-edit gate before editing project documentation.

## Documentation Update

- [x] T2.1: Update `Project/Jinli/docs/02-Design/General/soul-core-phase2.5-knowledge-evolution-spec.md` with the unified knowledge graph hub design.
- [x] T2.2: Add first-class video URL ingestion, transcription, timestamped summary, and video knowledge retrieval design.
- [x] T2.3: Add local model routing and local-worker safety boundaries.
- [x] T2.4: Add Obsidian/source-of-truth and token-saving architecture boundaries.
- [x] T2.5: Update `Project/Jinli/docs/DOCS_TREE.md` recent updates.

## Final Verification

- [x] T3.1: Verify selected mature path was implemented and no rejected shortcut was introduced.
- [x] T3.2: Run automated verification and record command output in `verification-report.md`.
- [x] T3.3: Map implementation result to Acceptance Criteria in `verification-report.md`.
