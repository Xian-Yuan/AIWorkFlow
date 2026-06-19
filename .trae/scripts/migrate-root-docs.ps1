# 2026-06-17 Root Doc Mirror Migration
# Moves remaining legacy root mirror docs to project Doc/ taxonomy and leaves redirect stubs.
param(
    [ValidateSet("move", "check")]
    [string]$Mode = "move"
)

$ErrorActionPreference = "Stop"
$root = "E:\UEGameDevelopment"

$moves = @(
    # airpgweb plans (18)
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
    # airpgweb specs (16)
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
    # characterdesigntool plans (2)
    @{Old="Docs\characterdesigntool\plans\2026-05-20-characterdesigntool-anime-beauty-render-plan.md"; New="Project\CharacterDesignTool\Docs\01-Planning\General\2026-05-20-characterdesigntool-anime-beauty-render-plan.md"},
    @{Old="Docs\characterdesigntool\plans\2026-05-20-characterdesigntool-prompt-workflow-v2-plan.md"; New="Project\CharacterDesignTool\Docs\01-Planning\General\2026-05-20-characterdesigntool-prompt-workflow-v2-plan.md"},
    # characterdesigntool specs (2)
    @{Old="Docs\characterdesigntool\specs\2026-05-20-characterdesigntool-anime-beauty-render-design.md"; New="Project\CharacterDesignTool\Docs\02-Design\General\2026-05-20-characterdesigntool-anime-beauty-render-design.md"},
    @{Old="Docs\characterdesigntool\specs\2026-05-20-characterdesigntool-prompt-workflow-v2-design.md"; New="Project\CharacterDesignTool\Docs\02-Design\General\2026-05-20-characterdesigntool-prompt-workflow-v2-design.md"}
)

$total = $moves.Count
$moved = 0
$skipped = 0
$pending = 0

foreach ($m in $moves) {
    $oldFull = Join-Path $root $m.Old
    $newFull = Join-Path $root $m.New

    if ($Mode -eq "check") {
        $oldExists = Test-Path -Path $oldFull -PathType Leaf
        $newExists = Test-Path -Path $newFull -PathType Leaf
        if (-not $oldExists -and -not $newExists) { Write-Host "BOTH MISSING: $($m.Old)" }
        elseif (-not $oldExists) { Write-Host "MISSING OLD: $($m.Old)" }
        elseif (-not $newExists) { $pending++ ; Write-Host "PENDING: $($m.Old) -> $($m.New)" }
        else { $moved++ ; Write-Host "OK: $($m.Old) -> $($m.New)" }
        continue
    }

    # Mode "move": check if target already exists
    if (Test-Path -Path $newFull -PathType Leaf) {
        Write-Host "SKIP (target exists): $($m.New)" -ForegroundColor Yellow
        $skipped++
        continue
    }

    # Ensure target parent dir exists
    $newParent = Split-Path $newFull -Parent
    if (-not (Test-Path -Path $newParent)) {
        New-Item -ItemType Directory -Path $newParent -Force | Out-Null
    }

    # Move the file
    Move-Item -Path $oldFull -Destination $newFull -Force
    Write-Host "MOVED: $($m.Old) -> $($m.New)"

    # Write redirect stub
    $stub = @"
<!-- doc-migration-redirect -->
# Moved Document

This document moved during the 2026-06-17 root documentation mirror migration.

- Old path: `$($m.Old)`
- New path: `$($m.New)`

Use the new path for future references.
"@
    New-Item -ItemType File -Path $oldFull -Force -Value $stub | Out-Null
    Write-Host "  STUB: $($m.Old)"
    $moved++
}

Write-Host ""
Write-Host "=== Migration $Mode complete ==="
Write-Host "Total: $total | Moved: $moved | Skipped: $skipped | Pending: $pending"
