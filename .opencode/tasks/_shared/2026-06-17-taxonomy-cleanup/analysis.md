# Analysis: Taxonomy Label Cleanup

## Background
On 2026-06-17, 38 root mirror documents were migrated from Docs/<project>/ to Project/<project>/Docs/. The old paths now contain only <!-- doc-migration-redirect --> stubs (airpgweb, characterdesigntool) or are empty (rts).

## Current State
Docs/AI/document-taxonomy-inventory.md still labels these three directories as legacy-project-mirror-candidate, implying they contain active content awaiting migration. This is stale.

## Proposed Change
| Directory | Old Label | New Label | Rationale |
|-----------|-----------|-----------|-----------|
| Docs/airpgweb/ | legacy-project-mirror-candidate | legacy-project-mirror-redirects | All .md files are redirect stubs |
| Docs/characterdesigntool/ | legacy-project-mirror-candidate | legacy-project-mirror-redirects | All .md files are redirect stubs |
| Docs/rts/ | legacy-project-mirror-candidate | legacy-project-mirror-empty | No .md files exist |

## Impact
- Single file edit: Docs/AI/document-taxonomy-inventory.md
- No code changes
- No compilation needed
- No downstream consumers depend on these labels (they are documentation-only)

## Risk
- Low. This is a label update reflecting ground truth.
