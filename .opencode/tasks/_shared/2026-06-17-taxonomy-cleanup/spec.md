# Spec: Update Taxonomy Labels for Migrated Root Mirrors

## GIVEN
The root mirror document migration is complete (2026-06-17):
- Docs/airpgweb/ contains only <!-- doc-migration-redirect --> stubs
- Docs/characterdesigntool/ contains only <!-- doc-migration-redirect --> stubs
- Docs/rts/ has no Markdown files

## WHEN
An agent reads Docs/AI/document-taxonomy-inventory.md

## THEN
- Docs/airpgweb/ should be labeled legacy-project-mirror-redirects (not legacy-project-mirror-candidate)
- Docs/characterdesigntool/ should be labeled legacy-project-mirror-redirects (not legacy-project-mirror-candidate)
- Docs/rts/ should be labeled legacy-project-mirror-empty (not legacy-project-mirror-candidate)
- Any prose describing them as "candidates" should be updated to reflect their migrated status

## Acceptance Criteria
1. g "legacy-project-mirror-candidate" Docs/AI/document-taxonomy-inventory.md returns zero matches for airpgweb, characterdesigntool, rts
2. Updated labels match the actual directory content
3. No other files are modified
4. Run update-docs-tree.ps1 -Mode check to verify consistency
