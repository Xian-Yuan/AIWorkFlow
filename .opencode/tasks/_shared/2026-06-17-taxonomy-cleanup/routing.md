# Routing Decision: Taxonomy Cleanup

## Entry Analysis
- **Type:** Other (documentation/governance)
- **Phase:** Plan (ready to implement)
- **Complexity:** Low — single file edit, no code changes

## Architecture Decision
- **Implement Mode:** direct
- **No branching needed** — documentation-only change
- **No compilation needed**

## Context
From pending-checklists/2026-06-17-doc-migration-acceptance-gaps.md Gap 1:
The root mirror document migration is complete (38 files), but Docs/AI/document-taxonomy-inventory.md still labels Docs/airpgweb/, Docs/characterdesigntool/, and Docs/rts/ as legacy-project-mirror-candidate. After migration, these dirs contain only redirect stubs (or no markdown), so the labels are stale.

## References
- Docs/AI/document-taxonomy-inventory.md — file to fix
- .trae/tasks/_shared/pending-checklists/2026-06-17-doc-migration-acceptance-gaps.md — gap description
- Docs/AI/15-FailSafe-AntiBloat.md — single source of truth rule
