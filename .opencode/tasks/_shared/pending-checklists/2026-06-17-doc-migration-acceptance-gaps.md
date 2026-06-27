# Document Migration Acceptance Gaps

Date: 2026-06-17
Status: Gaps 2 & 3 resolved; Gap 1 → formal task
Scope: post-migration governance metadata and verification harness cleanup

## Acceptance Summary

The root mirror document migration content is complete:

- 38 checklist rows were verified.
- 38 target project documents exist.
- 38 old root mirror paths exist as `<!-- doc-migration-redirect -->` stubs.
- No target project document contains the redirect marker.
- `Docs/rts/` has no Markdown files to move.

Fresh verification commands that pass:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\migrate-root-docs.ps1 -Mode check
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\migrate-docs.ps1 -Mode check
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\update-docs-tree.ps1 -Mode check
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-doc-guard.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-workflow-regression.ps1
```

## Remaining Gaps

### 1. Workspace taxonomy inventory still labels root mirrors as candidates

`Docs/AI/document-taxonomy-inventory.md` still contains:

- `Docs/airpgweb/ | legacy-project-mirror-candidate`
- `Docs/characterdesigntool/ | legacy-project-mirror-candidate`
- `Docs/rts/ | legacy-project-mirror-candidate`
- `Root Docs/airpgweb/, Docs/characterdesigntool/, and Docs/rts/ are legacy project mirror candidates.`

This is stale after migration because `Docs/airpgweb/` and `Docs/characterdesigntool/` now contain only redirect stubs, and `Docs/rts/` has no Markdown files.

Recommended fix:

1. Update `.trae/scripts/update-docs-tree.ps1` and `engine/update-docs-tree.ps1` root classification logic.
2. Classify root project mirror dirs by content:
   - all Markdown files are redirect stubs: `legacy-project-mirror-redirects`
   - no Markdown files: `legacy-project-mirror-empty`
   - non-stub Markdown remains: `legacy-project-mirror-candidate`
3. Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\update-docs-tree.ps1 -Mode write
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\update-docs-tree.ps1 -Mode check
```

### 2. Migration log does not record root mirror migration history

`Docs/AI/document-migration-log.md` records project-internal redirects, but still says:

- `Scope: Project/*/Docs internal migration only`
- `Root Docs project mirrors are not migrated in this pass.`

Recommended fix:

1. Add a root mirror migration section to `Docs/AI/document-migration-log.md`, or create a dedicated root migration log.
2. Record the 38 old-to-new paths from `.trae/tasks/_shared/pending-checklists/2026-06-17-remaining-root-doc-migration.md`.
3. Preserve the distinction between project-internal migration and root mirror migration.

### 3. Experimental engine copies of regression tests are not directly runnable

The formal `.trae/scripts/` test scripts pass, but the experimental copies fail when invoked directly:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\engine\_experimental\test-doc-guard.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\engine\_experimental\test-workflow-regression.ps1
```

Failure cause:

- `engine/_experimental/test-doc-guard.ps1` resolves `doc-guard.ps1` under `engine/_experimental/`, but the actual file is `engine/doc-guard.ps1`.
- `engine/_experimental/test-workflow-regression.ps1` resolves `task-state.ps1`, `spec-living.ps1`, `update-docs-tree.ps1`, and `task-guard.ps1` under `engine/_experimental/`, but those files are not there.

Recommended fix:

1. Either mark `engine/_experimental/test-*.ps1` as archived/non-runnable, or
2. Fix their dependency paths to point at `engine/` or `.trae/scripts/`.
3. Re-run both experimental scripts if they are meant to remain executable.

## Current Verdict

Document files are migrated. Gap 2 (migration log) and Gap 3 (experimental scripts) resolved. Gap 1 (taxonomy labels) → formal task at .trae/tasks/_shared/2026-06-17-taxonomy-cleanup/.
