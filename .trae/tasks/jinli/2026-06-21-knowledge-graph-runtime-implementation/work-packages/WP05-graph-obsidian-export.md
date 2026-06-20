# WP05: Canonical Graph And Obsidian Export

Owner model: unclaimed
Difficulty: hard
Status: unclaimed
Target model: deepseek-v4-flash
Fresh context required: yes

## Worker Profile
- Profile: ds4-flash
- Role: implementation worker
- Review authority: none
- Verify authority: none

## Context Budget
- Read this package, contracts, and Phase 2.5 sections 22.1-22.6.
- Do not inspect obra implementation or Soul Core lifecycle code.

## Root Cause Boundary
- Root Cause ID: KG-RUNTIME-WP05
- This package handles SQLite canonical records, candidate review state, deduplication, and controlled Obsidian Markdown export.

## Task Packet
- Root: `.trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation`
- Parent task: `2026-06-21-knowledge-graph-runtime-implementation`

## Allowed Paths
- `Project/Jinli/services/knowledge/graph_store.py`
- `Project/Jinli/services/knowledge/deduplication.py`
- `Project/Jinli/services/knowledge/obsidian_export.py`
- `Project/Jinli/services/knowledge/migrations/`
- `Project/Jinli/services/knowledge/tests/test_graph_store.py`
- `Project/Jinli/services/knowledge/tests/test_deduplication.py`
- `Project/Jinli/services/knowledge/tests/test_obsidian_export.py`

## Forbidden Paths
- `.trae/tasks/`
- `Project/Jinli/data/memory.db`
- Real `E:\ObsidianVault` during tests
- Obsidian configuration files under `.obsidian`
- Any file outside Allowed Paths

## Read First
- `.trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation/spec.md`
- `Project/Jinli/services/knowledge/contracts.py`
- `Project/Jinli/docs/02-Design/General/soul-core-phase2.5-knowledge-evolution-spec.md`

## Goal
- Implement candidate-to-accepted graph persistence and an idempotent Obsidian exporter that preserves user content.

## Steps
- [ ] Write failing tests for transactional writes, schema versioning, evidence foreign keys, exact ID merge, alias merge, ambiguous similarity, conflict queue, low-confidence queue, and rollback.
- [ ] Create SQLite migrations for sources, evidence, candidates, nodes, edges, exports, and review decisions.
- [ ] Require provenance and accepted status before canonical node/edge insertion.
- [ ] Implement deterministic deduplication rules before optional model-assisted similarity.
- [ ] Implement vault path containment and slugs that remain stable across title changes.
- [ ] Export source video, concept, important segment, index, and review queue notes with frontmatter and internal links.
- [ ] Separate generated sections with stable markers and preserve text outside those markers on repeated export.
- [ ] Never update `.obsidian` configuration from the exporter.

## Done Definition
- Repeated export is idempotent and preserves manually edited sections.
- Exact duplicates merge evidence; ambiguous/conflicting candidates remain reviewable.
- All tests use temporary databases and temporary vaults.

## Required Verification
- Command: `python -m pytest Project/Jinli/services/knowledge/tests/test_graph_store.py Project/Jinli/services/knowledge/tests/test_deduplication.py Project/Jinli/services/knowledge/tests/test_obsidian_export.py -q`
- Expected: all WP05 tests pass.

## Do Not Game The Gate
- Do not modify tests, acceptance criteria, task state, or verification evidence to obtain a passing result.
- Do not claim Review or Verify pass.

## Stop Conditions
- Stop if an operation would overwrite content outside generated markers.
- Stop if candidate acceptance lacks source evidence.
- Stop if a migration would alter existing `memory.db`.

## Return Report
- Path: `reports/ds4-WP05-result.md`
- Required status for merge: `done`
- Include Changed Files, Commands Run, Acceptance Criteria Touched, Scope Control, Worker Authority, and Unresolved Risks.
- Declare `Extra scope taken: no`.

## Failure Reporting
- Write the same report path with `Status: blocked` and the smallest data-ownership blocker.

