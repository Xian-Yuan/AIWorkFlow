# Tasks: Bilibili Favorites Knowledge Automation

## Dependency Graph

```text
knowledge runtime foundation
  -> WP01 source and eligibility
  -> WP02 ledger and reconciliation
  -> WP03 HDD media and vsummary adapter
  -> WP04 classified Markdown export
  -> WP05 orchestration, cleanup, CLI, scheduler, E2E
  -> lead Review and Verify
```

## Implementation

- [ ] T1: Complete WP01 Bilibili discovery, metadata, optional pinned-comment, and duration-filter contracts.
- [ ] T2: Complete WP02 SQLite ledger, revision identity, idempotency, and legacy reconciliation.
- [ ] T3: Complete WP03 physical-disk guard, managed media paths, downloader, and vsummary adapter.
- [ ] T4: Complete WP04 URL preservation, classification, canonical records, and atomic Markdown export.
- [ ] T5: Complete WP05 orchestrator, post-commit cleanup, dry-run, CLI, scheduled-task installer, and observability.

## Integration

- [ ] Reconcile the current local snapshot and report adopted, missing, ineligible, ambiguous, and unmanaged files without deleting.
- [ ] Run a live read-only dry-run of folder `3972516389`.
- [ ] Run one-video canary from discovery through export and cleanup.
- [ ] Run the same canary again and prove unchanged-revision skip.
- [ ] Run graph-offline degradation and cleanup-resume tests.

## Documentation

- [ ] Update KnowledgeGraph architecture, implementation, testing, and operations documents.
- [ ] Add a runbook for cache migration, manual execution, scheduling, retries, and disaster recovery.
- [ ] Update `Project/Jinli/Docs/DOCS_TREE.md`.

## Final Verification

- [ ] Verify the selected mature path was implemented and every rejected shortcut remains rejected.
- [ ] Run automated verification and record exact current-session evidence.
- [ ] Map every Acceptance Criteria entry to tests or canary evidence in `verification-report.md`.
- [ ] Run secret scan, path-containment tests, and documentation guard.

