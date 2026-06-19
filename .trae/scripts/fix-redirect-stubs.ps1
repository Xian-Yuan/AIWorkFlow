# Fix redirect stubs that have broken variable interpolation
$root = "E:\UEGameDevelopment"

$moves = @(
    @{Old="Docs\airpgweb\plans\2026-05-31-airpgweb-ai-connection-gate-plan.md";                    New="Project\AIRPGWeb\Docs\01-Planning\General\2026-05-31-airpgweb-ai-connection-gate-plan.md"},
    @{Old="Docs\airpgweb\plans\2026-05-31-airpgweb-asset-library-and-pixel-editor-implementation-plan.md"; New="Project\AIRPGWeb\Docs\01-Planning\General\2026-05-31-airpgweb-asset-library-and-pixel-editor-implementation-plan.md"},
    @{Old="Docs\airpgweb\plans\2026-05-31-airpgweb-ingame-tile-map-editor-plan.md";               New="Project\AIRPGWeb\Docs\01-Planning\General\2026-05-31-airpgweb-ingame-tile-map-editor-plan.md"},
    @{Old="Docs\airpgweb\plans\2026-05-31-airpgweb-save-load-and-random-name-plan.md";             New="Project\AIRPGWeb\Docs\01-Planning\General\2026-05-31-airpgweb-save-load-and-random-name-plan.md"},
    @{Old="Docs\airpgweb\plans\2026-05-31-airpgweb-tile-editor-interaction-rework-plan.md";        New="Project\AIRPGWeb\Docs\01-Planning\General\2026-05-31-airpgweb-tile-editor-interaction-rework-plan.md"},
    @{Old="Docs\airpgweb\plans\2026-05-31-airpgweb-tile-topology-interaction-refinement-plan.md";  New="Project\AIRPGWeb\Docs\01-Planning\General\2026-05-31-airpgweb-tile-topology-interaction-refinement-plan.md"},
    @{Old="Docs\airpgweb\plans\2026-05-31-airpgweb-tile-topology-tools-v2-plan.md";                New="Project\AIRPGWeb\Docs\01-Planning\General\2026-05-31-airpgweb-tile-topology-tools-v2-plan.md"},
    @{Old="Docs\airpgweb\plans\2026-05-31-airpgweb-tree-canopy-grid-implementation-plan.md";       New="Project\AIRPGWeb\Docs\01-Planning\General\2026-05-31-airpgweb-tree-canopy-grid-implementation-plan.md"},
    @{Old="Docs\airpgweb\plans\2026-05-31-airpgweb-wall-topology-material-implementation-plan.md"; New="Project\AIRPGWeb\Docs\01-Planning\General\2026-05-31-airpgweb-wall-topology-material-implementation-plan.md"},
    @{Old="Docs\airpgweb\plans\2026-06-01-airpgweb-asset-import-and-roundtrip-edit-implementation-plan.md"; New="Project\AIRPGWeb\Docs\01-Planning\General\2026-06-01-airpgweb-asset-import-and-roundtrip-edit-implementation-plan.md"},
    @{Old="Docs\airpgweb\plans\2026-06-01-airpgweb-asset-library-browser-implementation-plan.md";  New="Project\AIRPGWeb\Docs\01-Planning\General\2026-06-01-airpgweb-asset-library-browser-implementation-plan.md"},
    @{Old="Docs\airpgweb\plans\2026-06-01-airpgweb-asset-system-overall-implementation-plan.md";   New="Project\AIRPGWeb\Docs\01-Planning\General\2026-06-01-airpgweb-asset-system-overall-implementation-plan.md"},
    @{Old="Docs\airpgweb\plans\2026-06-01-airpgweb-layer-visibility-opacity-plan.md";              New="Project\AIRPGWeb\Docs\01-Planning\General\2026-06-01-airpgweb-layer-visibility-opacity-plan.md"},
    @{Old="Docs\airpgweb\plans\2026-06-01-airpgweb-map-tile-tiling-implementation-plan.md";        New="Project\AIRPGWeb\Docs\01-Planning\General\2026-06-01-airpgweb-map-tile-tiling-implementation-plan.md"},
    @{Old="Docs\airpgweb\plans\2026-06-01-airpgweb-pixel-canvas-ctrl-wheel-zoom-plan.md";          New="Project\AIRPGWeb\Docs\01-Planning\General\2026-06-01-airpgweb-pixel-canvas-ctrl-wheel-zoom-plan.md"},
    @{Old="Docs\airpgweb\plans\2026-06-01-airpgweb-pixel-precise-paint-and-grid-plan.md";          New="Project\AIRPGWeb\Docs\01-Planning\General\2026-06-01-airpgweb-pixel-precise-paint-and-grid-plan.md"},
    @{Old="Docs\airpgweb\plans\2026-06-01-airpgweb-shared-canvas-system-plan.md";                  New="Project\AIRPGWeb\Docs\01-Planning\General\2026-06-01-airpgweb-shared-canvas-system-plan.md"},
    @{Old="Docs\airpgweb\plans\2026-06-01-airpgweb-structure-layer-asset-placement-and-tool-alignment-implementation-plan.md"; New="Project\AIRPGWeb\Docs\01-Planning\General\2026-06-01-airpgweb-structure-layer-asset-placement-and-tool-alignment-implementation-plan.md"},
    @{Old="Docs\airpgweb\specs\2026-05-31-airpgweb-asset-library-and-pixel-editor-design.md";       New="Project\AIRPGWeb\Docs\02-Design\General\2026-05-31-airpgweb-asset-library-and-pixel-editor-design.md"},
    @{Old="Docs\airpgweb\specs\2026-05-31-airpgweb-ingame-tile-map-editor-design.md";              New="Project\AIRPGWeb\Docs\02-Design\General\2026-05-31-airpgweb-ingame-tile-map-editor-design.md"},
    @{Old="Docs\airpgweb\specs\2026-05-31-airpgweb-save-load-and-random-name-design.md";            New="Project\AIRPGWeb\Docs\02-Design\General\2026-05-31-airpgweb-save-load-and-random-name-design.md"},
    @{Old="Docs\airpgweb\specs\2026-05-31-airpgweb-tile-editor-interaction-rework-design.md";       New="Project\AIRPGWeb\Docs\02-Design\General\2026-05-31-airpgweb-tile-editor-interaction-rework-design.md"},
    @{Old="Docs\airpgweb\specs\2026-05-31-airpgweb-tile-editor-open-source-research.md";            New="Project\AIRPGWeb\Docs\02-Design\General\2026-05-31-airpgweb-tile-editor-open-source-research.md"},
    @{Old="Docs\airpgweb\specs\2026-05-31-airpgweb-tile-topology-tools-v2-design.md";               New="Project\AIRPGWeb\Docs\02-Design\General\2026-05-31-airpgweb-tile-topology-tools-v2-design.md"},
    @{Old="Docs\airpgweb\specs\2026-05-31-airpgweb-tree-canopy-grid-design.md";                     New="Project\AIRPGWeb\Docs\02-Design\General\2026-05-31-airpgweb-tree-canopy-grid-design.md"},
    @{Old="Docs\airpgweb\specs\2026-05-31-airpgweb-wall-topology-and-material-rules-design.md";     New="Project\AIRPGWeb\Docs\02-Design\General\2026-05-31-airpgweb-wall-topology-and-material-rules-design.md"},
    @{Old="Docs\airpgweb\specs\2026-05-31-airpgweb-world-floorplan-temporary-summary.md";           New="Project\AIRPGWeb\Docs\02-Design\General\2026-05-31-airpgweb-world-floorplan-temporary-summary.md"},
    @{Old="Docs\airpgweb\specs\2026-06-01-airpgweb-asset-import-and-roundtrip-edit-design.md";      New="Project\AIRPGWeb\Docs\02-Design\General\2026-06-01-airpgweb-asset-import-and-roundtrip-edit-design.md"},
    @{Old="Docs\airpgweb\specs\2026-06-01-airpgweb-asset-library-browser-design.md";                New="Project\AIRPGWeb\Docs\02-Design\General\2026-06-01-airpgweb-asset-library-browser-design.md"},
    @{Old="Docs\airpgweb\specs\2026-06-01-airpgweb-asset-system-overall-design.md";                 New="Project\AIRPGWeb\Docs\02-Design\General\2026-06-01-airpgweb-asset-system-overall-design.md"},
    @{Old="Docs\airpgweb\specs\2026-06-01-airpgweb-map-tile-tiling-design.md";                      New="Project\AIRPGWeb\Docs\02-Design\General\2026-06-01-airpgweb-map-tile-tiling-design.md"},
    @{Old="Docs\airpgweb\specs\2026-06-01-airpgweb-pixel-canvas-ctrl-wheel-zoom-design.md";         New="Project\AIRPGWeb\Docs\02-Design\General\2026-06-01-airpgweb-pixel-canvas-ctrl-wheel-zoom-design.md"},
    @{Old="Docs\airpgweb\specs\2026-06-01-airpgweb-pixel-precise-paint-and-grid-design.md";         New="Project\AIRPGWeb\Docs\02-Design\General\2026-06-01-airpgweb-pixel-precise-paint-and-grid-design.md"},
    @{Old="Docs\airpgweb\specs\2026-06-01-airpgweb-structure-layer-asset-placement-and-tool-alignment-design.md"; New="Project\AIRPGWeb\Docs\02-Design\General\2026-06-01-airpgweb-structure-layer-asset-placement-and-tool-alignment-design.md"},
    @{Old="Docs\characterdesigntool\plans\2026-05-20-characterdesigntool-anime-beauty-render-plan.md"; New="Project\CharacterDesignTool\Docs\01-Planning\General\2026-05-20-characterdesigntool-anime-beauty-render-plan.md"},
    @{Old="Docs\characterdesigntool\plans\2026-05-20-characterdesigntool-prompt-workflow-v2-plan.md"; New="Project\CharacterDesignTool\Docs\01-Planning\General\2026-05-20-characterdesigntool-prompt-workflow-v2-plan.md"},
    @{Old="Docs\characterdesigntool\specs\2026-05-20-characterdesigntool-anime-beauty-render-design.md"; New="Project\CharacterDesignTool\Docs\02-Design\General\2026-05-20-characterdesigntool-anime-beauty-render-design.md"},
    @{Old="Docs\characterdesigntool\specs\2026-05-20-characterdesigntool-prompt-workflow-v2-design.md"; New="Project\CharacterDesignTool\Docs\02-Design\General\2026-05-20-characterdesigntool-prompt-workflow-v2-design.md"}
)

$fixed = 0
foreach ($m in $moves) {
    $oldPath = $m["Old"]
    $newPath = $m["New"]
    $oldFull = Join-Path $root $oldPath
    $stub = "<!-- doc-migration-redirect -->
# Moved Document

This document moved during the 2026-06-17 root documentation mirror migration.

- Old path: ``$oldPath``
- New path: ``$newPath``

Use the new path for future references.
"
    Set-Content -Path $oldFull -Value $stub -NoNewline
    $fixed++
}
Write-Host "Fixed $fixed redirect stubs"
