# Remaining Root Document Migration Checklist

Date: 2026-06-17
Status: Pending handoff
Scope: root legacy mirror docs only

## Current Audit Result

Project-internal documentation migration is complete.

Verified commands:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\migrate-docs.ps1 -Mode check
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\update-docs-tree.ps1 -Mode check
```

Observed result:

- `migrate-docs.ps1 -Mode check`: `candidates=0`
- `update-docs-tree.ps1 -Mode check`: passed

Remaining work is root legacy mirror migration:

- `Docs/airpgweb/`
- `Docs/characterdesigntool/`
- `Docs/rts/` currently has no Markdown files to move

## Required Migration Method

Do not delete old paths directly.

For every moved file:

1. Move the document to the target project `Docs/` taxonomy folder.
2. Leave a short redirect stub at the old root path.
3. Refresh project docs trees:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\update-docs-tree.ps1 -Mode write
```

4. Run verification:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\update-docs-tree.ps1 -Mode check
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-doc-guard.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-workflow-regression.ps1
```

5. Update `Docs/AI/document-taxonomy-inventory.md` and `Project/<ProjectName>/Docs/DOCS_TREE.md` through the generator, not by hand.

## Redirect Stub Template

```markdown
<!-- doc-migration-redirect -->
# Moved Document

This document moved during the 2026-06-17 root documentation mirror migration.

- Old path: <old-path>
- New path: <new-path>

Use the new path for future references.
```

## Pending Moves

| Old Path | New Path |
|---|---|
| Docs/airpgweb/plans/2026-05-31-airpgweb-ai-connection-gate-plan.md | Project/AIRPGWeb/Docs/01-Planning/General/2026-05-31-airpgweb-ai-connection-gate-plan.md |
| Docs/airpgweb/plans/2026-05-31-airpgweb-asset-library-and-pixel-editor-implementation-plan.md | Project/AIRPGWeb/Docs/01-Planning/General/2026-05-31-airpgweb-asset-library-and-pixel-editor-implementation-plan.md |
| Docs/airpgweb/plans/2026-05-31-airpgweb-ingame-tile-map-editor-plan.md | Project/AIRPGWeb/Docs/01-Planning/General/2026-05-31-airpgweb-ingame-tile-map-editor-plan.md |
| Docs/airpgweb/plans/2026-05-31-airpgweb-save-load-and-random-name-plan.md | Project/AIRPGWeb/Docs/01-Planning/General/2026-05-31-airpgweb-save-load-and-random-name-plan.md |
| Docs/airpgweb/plans/2026-05-31-airpgweb-tile-editor-interaction-rework-plan.md | Project/AIRPGWeb/Docs/01-Planning/General/2026-05-31-airpgweb-tile-editor-interaction-rework-plan.md |
| Docs/airpgweb/plans/2026-05-31-airpgweb-tile-topology-interaction-refinement-plan.md | Project/AIRPGWeb/Docs/01-Planning/General/2026-05-31-airpgweb-tile-topology-interaction-refinement-plan.md |
| Docs/airpgweb/plans/2026-05-31-airpgweb-tile-topology-tools-v2-plan.md | Project/AIRPGWeb/Docs/01-Planning/General/2026-05-31-airpgweb-tile-topology-tools-v2-plan.md |
| Docs/airpgweb/plans/2026-05-31-airpgweb-tree-canopy-grid-implementation-plan.md | Project/AIRPGWeb/Docs/01-Planning/General/2026-05-31-airpgweb-tree-canopy-grid-implementation-plan.md |
| Docs/airpgweb/plans/2026-05-31-airpgweb-wall-topology-material-implementation-plan.md | Project/AIRPGWeb/Docs/01-Planning/General/2026-05-31-airpgweb-wall-topology-material-implementation-plan.md |
| Docs/airpgweb/plans/2026-06-01-airpgweb-asset-import-and-roundtrip-edit-implementation-plan.md | Project/AIRPGWeb/Docs/01-Planning/General/2026-06-01-airpgweb-asset-import-and-roundtrip-edit-implementation-plan.md |
| Docs/airpgweb/plans/2026-06-01-airpgweb-asset-library-browser-implementation-plan.md | Project/AIRPGWeb/Docs/01-Planning/General/2026-06-01-airpgweb-asset-library-browser-implementation-plan.md |
| Docs/airpgweb/plans/2026-06-01-airpgweb-asset-system-overall-implementation-plan.md | Project/AIRPGWeb/Docs/01-Planning/General/2026-06-01-airpgweb-asset-system-overall-implementation-plan.md |
| Docs/airpgweb/plans/2026-06-01-airpgweb-layer-visibility-opacity-plan.md | Project/AIRPGWeb/Docs/01-Planning/General/2026-06-01-airpgweb-layer-visibility-opacity-plan.md |
| Docs/airpgweb/plans/2026-06-01-airpgweb-map-tile-tiling-implementation-plan.md | Project/AIRPGWeb/Docs/01-Planning/General/2026-06-01-airpgweb-map-tile-tiling-implementation-plan.md |
| Docs/airpgweb/plans/2026-06-01-airpgweb-pixel-canvas-ctrl-wheel-zoom-plan.md | Project/AIRPGWeb/Docs/01-Planning/General/2026-06-01-airpgweb-pixel-canvas-ctrl-wheel-zoom-plan.md |
| Docs/airpgweb/plans/2026-06-01-airpgweb-pixel-precise-paint-and-grid-plan.md | Project/AIRPGWeb/Docs/01-Planning/General/2026-06-01-airpgweb-pixel-precise-paint-and-grid-plan.md |
| Docs/airpgweb/plans/2026-06-01-airpgweb-shared-canvas-system-plan.md | Project/AIRPGWeb/Docs/01-Planning/General/2026-06-01-airpgweb-shared-canvas-system-plan.md |
| Docs/airpgweb/plans/2026-06-01-airpgweb-structure-layer-asset-placement-and-tool-alignment-implementation-plan.md | Project/AIRPGWeb/Docs/01-Planning/General/2026-06-01-airpgweb-structure-layer-asset-placement-and-tool-alignment-implementation-plan.md |
| Docs/airpgweb/specs/2026-05-31-airpgweb-asset-library-and-pixel-editor-design.md | Project/AIRPGWeb/Docs/02-Design/General/2026-05-31-airpgweb-asset-library-and-pixel-editor-design.md |
| Docs/airpgweb/specs/2026-05-31-airpgweb-ingame-tile-map-editor-design.md | Project/AIRPGWeb/Docs/02-Design/General/2026-05-31-airpgweb-ingame-tile-map-editor-design.md |
| Docs/airpgweb/specs/2026-05-31-airpgweb-save-load-and-random-name-design.md | Project/AIRPGWeb/Docs/02-Design/General/2026-05-31-airpgweb-save-load-and-random-name-design.md |
| Docs/airpgweb/specs/2026-05-31-airpgweb-tile-editor-interaction-rework-design.md | Project/AIRPGWeb/Docs/02-Design/General/2026-05-31-airpgweb-tile-editor-interaction-rework-design.md |
| Docs/airpgweb/specs/2026-05-31-airpgweb-tile-editor-open-source-research.md | Project/AIRPGWeb/Docs/02-Design/General/2026-05-31-airpgweb-tile-editor-open-source-research.md |
| Docs/airpgweb/specs/2026-05-31-airpgweb-tile-topology-tools-v2-design.md | Project/AIRPGWeb/Docs/02-Design/General/2026-05-31-airpgweb-tile-topology-tools-v2-design.md |
| Docs/airpgweb/specs/2026-05-31-airpgweb-tree-canopy-grid-design.md | Project/AIRPGWeb/Docs/02-Design/General/2026-05-31-airpgweb-tree-canopy-grid-design.md |
| Docs/airpgweb/specs/2026-05-31-airpgweb-wall-topology-and-material-rules-design.md | Project/AIRPGWeb/Docs/02-Design/General/2026-05-31-airpgweb-wall-topology-and-material-rules-design.md |
| Docs/airpgweb/specs/2026-05-31-airpgweb-world-floorplan-temporary-summary.md | Project/AIRPGWeb/Docs/02-Design/General/2026-05-31-airpgweb-world-floorplan-temporary-summary.md |
| Docs/airpgweb/specs/2026-06-01-airpgweb-asset-import-and-roundtrip-edit-design.md | Project/AIRPGWeb/Docs/02-Design/General/2026-06-01-airpgweb-asset-import-and-roundtrip-edit-design.md |
| Docs/airpgweb/specs/2026-06-01-airpgweb-asset-library-browser-design.md | Project/AIRPGWeb/Docs/02-Design/General/2026-06-01-airpgweb-asset-library-browser-design.md |
| Docs/airpgweb/specs/2026-06-01-airpgweb-asset-system-overall-design.md | Project/AIRPGWeb/Docs/02-Design/General/2026-06-01-airpgweb-asset-system-overall-design.md |
| Docs/airpgweb/specs/2026-06-01-airpgweb-map-tile-tiling-design.md | Project/AIRPGWeb/Docs/02-Design/General/2026-06-01-airpgweb-map-tile-tiling-design.md |
| Docs/airpgweb/specs/2026-06-01-airpgweb-pixel-canvas-ctrl-wheel-zoom-design.md | Project/AIRPGWeb/Docs/02-Design/General/2026-06-01-airpgweb-pixel-canvas-ctrl-wheel-zoom-design.md |
| Docs/airpgweb/specs/2026-06-01-airpgweb-pixel-precise-paint-and-grid-design.md | Project/AIRPGWeb/Docs/02-Design/General/2026-06-01-airpgweb-pixel-precise-paint-and-grid-design.md |
| Docs/airpgweb/specs/2026-06-01-airpgweb-structure-layer-asset-placement-and-tool-alignment-design.md | Project/AIRPGWeb/Docs/02-Design/General/2026-06-01-airpgweb-structure-layer-asset-placement-and-tool-alignment-design.md |
| Docs/characterdesigntool/plans/2026-05-20-characterdesigntool-anime-beauty-render-plan.md | Project/CharacterDesignTool/Docs/01-Planning/General/2026-05-20-characterdesigntool-anime-beauty-render-plan.md |
| Docs/characterdesigntool/plans/2026-05-20-characterdesigntool-prompt-workflow-v2-plan.md | Project/CharacterDesignTool/Docs/01-Planning/General/2026-05-20-characterdesigntool-prompt-workflow-v2-plan.md |
| Docs/characterdesigntool/specs/2026-05-20-characterdesigntool-anime-beauty-render-design.md | Project/CharacterDesignTool/Docs/02-Design/General/2026-05-20-characterdesigntool-anime-beauty-render-design.md |
| Docs/characterdesigntool/specs/2026-05-20-characterdesigntool-prompt-workflow-v2-design.md | Project/CharacterDesignTool/Docs/02-Design/General/2026-05-20-characterdesigntool-prompt-workflow-v2-design.md |

## Notes For The Next Model

- There are 38 pending root mirror files.
- `Docs/rts/` has no Markdown files at audit time.
- The previous project-internal migration moved 52 files and left redirect stubs; do the same pattern here.
- Before moving, check whether target path already exists. If it exists, compare content before deciding whether to merge, skip, or rename.
- After moving, update any direct references only when safe; redirect stubs are acceptable as a compatibility bridge.

