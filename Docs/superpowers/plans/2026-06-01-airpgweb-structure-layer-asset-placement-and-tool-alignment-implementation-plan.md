# AIRPGWeb Structure Layer Asset Placement And Tool Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make saved `structure` pixel assets render in the map editor using their real aligned `8x8` atomic size, while aligning the asset library tool UX to the map editor as the single source of truth.

**Architecture:** Keep the existing AIRPGWeb map editor and asset library structure, but thread pixel asset size metadata from persistence to palette selection and canvas rendering. Add a focused placement/rendering helper for structure-layer pixel assets instead of redesigning the entire map model. Then align the asset library tool shell and interaction flow to the existing map editor tool model.

**Tech Stack:** React 19, TypeScript, Vitest, Vite preview, Dexie

---

## File Map

### Existing files to modify

- `Project/AIRPGWeb/src/domain/map-editor/tile-palette.ts`
  - Extend `PixelAssetEntry` and `TilePreset` with aligned size metadata for pixel assets.
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/MapEditorScreen.tsx`
  - Load pixel asset dimensions from repository and pass a richer map into `TileCanvas`.
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileCanvas.tsx`
  - Render structure-layer pixel assets using aligned atomic dimensions instead of single-cell thumbnail assumptions.
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/AssetLibraryScreen.tsx`
  - Add tool overlay anchor state and pass shared tool-shell props into the asset library UI.
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/PixelEditorInspector.tsx`
  - Replace the current button rows with a map-editor-like main tool entry + overlay launcher.
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/PixelEditorCanvas.tsx`
  - Keep behavior aligned with the selected tool model and avoid regressions in pointer lifecycle.
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/asset-library.css`
  - Add left rail / overlay styles so the asset library visually behaves like the map editor.
- `Project/AIRPGWeb/src/domain/asset-library/pixel-editor-reducer.ts`
  - Keep tool state transitions consistent with the map editor tool contract.

### New files to create

- `Project/AIRPGWeb/src/domain/map-editor/pixel-asset-placement.ts`
  - Centralize `8x8` alignment helpers so canvas and palette both use the same size math.
- `Project/AIRPGWeb/src/domain/map-editor/pixel-asset-placement.test.ts`
  - Cover alignment and atomic span math.

### Existing tests to modify

- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileCanvas.test.ts`
  - Extend from single-cell atom count checks to structure asset size rendering checks.
- `Project/AIRPGWeb/src/domain/asset-library/pixel-editor-reducer.test.ts`
  - Add assertions for map-editor-style tool transitions if needed.

---

### Task 1: Add Pixel Asset Alignment Metadata

**Files:**
- Create: `Project/AIRPGWeb/src/domain/map-editor/pixel-asset-placement.ts`
- Test: `Project/AIRPGWeb/src/domain/map-editor/pixel-asset-placement.test.ts`
- Modify: `Project/AIRPGWeb/src/domain/map-editor/tile-palette.ts`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/MapEditorScreen.tsx`

- [ ] **Step 1: Write the failing helper test**

```ts
import { describe, expect, it } from 'vitest'
import { buildAlignedPixelAssetMetrics } from './pixel-asset-placement'

describe('buildAlignedPixelAssetMetrics', () => {
  it('rounds structure asset dimensions up to the nearest 8px atomic grid', () => {
    expect(buildAlignedPixelAssetMetrics({ pixelWidth: 18, pixelHeight: 10 })).toEqual({
      pixelWidth: 18,
      pixelHeight: 10,
      alignedPixelWidth: 24,
      alignedPixelHeight: 16,
      atomCols: 3,
      atomRows: 2,
    })
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test -- src/domain/map-editor/pixel-asset-placement.test.ts`

Expected: FAIL with module or export not found for `buildAlignedPixelAssetMetrics`

- [ ] **Step 3: Write the minimal alignment helper**

```ts
const ATOM_GRID_SIZE = 8

export type AlignedPixelAssetMetrics = {
  pixelWidth: number
  pixelHeight: number
  alignedPixelWidth: number
  alignedPixelHeight: number
  atomCols: number
  atomRows: number
}

export function alignToAtomGrid(size: number) {
  return Math.max(ATOM_GRID_SIZE, Math.ceil(size / ATOM_GRID_SIZE) * ATOM_GRID_SIZE)
}

export function buildAlignedPixelAssetMetrics(input: {
  pixelWidth: number
  pixelHeight: number
}): AlignedPixelAssetMetrics {
  const alignedPixelWidth = alignToAtomGrid(input.pixelWidth)
  const alignedPixelHeight = alignToAtomGrid(input.pixelHeight)

  return {
    pixelWidth: input.pixelWidth,
    pixelHeight: input.pixelHeight,
    alignedPixelWidth,
    alignedPixelHeight,
    atomCols: alignedPixelWidth / ATOM_GRID_SIZE,
    atomRows: alignedPixelHeight / ATOM_GRID_SIZE,
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm test -- src/domain/map-editor/pixel-asset-placement.test.ts`

Expected: PASS with `1 passed`

- [ ] **Step 5: Thread metadata into tile palette entries**

```ts
export type PixelAssetEntry = {
  id: string
  name: string
  layerId: EditorLayerId
  thumbnail: string | null
  pixelWidth: number
  pixelHeight: number
  alignedPixelWidth: number
  alignedPixelHeight: number
  atomCols: number
  atomRows: number
}

export type TilePreset = {
  id: string
  label: string
  layerId: EditorLayerId
  preview: string
  family: string
  pixelThumbnail?: string
  pixelAssetMetrics?: {
    pixelWidth: number
    pixelHeight: number
    alignedPixelWidth: number
    alignedPixelHeight: number
    atomCols: number
    atomRows: number
  }
}
```

- [ ] **Step 6: Load aligned metrics in the map editor screen**

```ts
import { buildAlignedPixelAssetMetrics } from '../../../domain/map-editor/pixel-asset-placement'

setPixelAssets(
  list.map((a) => {
    const metrics = buildAlignedPixelAssetMetrics({
      pixelWidth: a.pixelWidth,
      pixelHeight: a.pixelHeight,
    })

    return {
      id: a.id,
      name: a.name,
      layerId: a.layerId,
      thumbnail: a.thumbnail ?? null,
      ...metrics,
    }
  }),
)
```

- [ ] **Step 7: Run focused tests**

Run: `npm test -- src/domain/map-editor/pixel-asset-placement.test.ts src/domain/map-editor/tile-palette.ts`

Expected: The helper test passes; TypeScript transform loads the updated palette module without compile errors

- [ ] **Step 8: Commit**

```bash
git add Project/AIRPGWeb/src/domain/map-editor/pixel-asset-placement.ts \
  Project/AIRPGWeb/src/domain/map-editor/pixel-asset-placement.test.ts \
  Project/AIRPGWeb/src/domain/map-editor/tile-palette.ts \
  Project/AIRPGWeb/src/presentation/react-shell/dev-mode/MapEditorScreen.tsx
git commit -m "feat: add aligned pixel asset metadata for map editor"
```

### Task 2: Render Structure Assets By Real Atomic Footprint

**Files:**
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileCanvas.tsx`
- Test: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileCanvas.test.ts`

- [ ] **Step 1: Write the failing structure render test**

```ts
it('renders a structure pixel asset using its aligned atomic footprint', () => {
  const map = createEmptyMapAsset({ id: 'map-1', name: '草稿', width: 6, height: 6 })
  const structureLayer = map.layers.find((layer) => layer.id === 'structure')
  if (!structureLayer) throw new Error('structure layer missing')

  structureLayer.cells[0].tileId = 'pixel-wall-1'

  const state = createInitialEditorState(map)
  const html = renderToStaticMarkup(
    createElement(TileCanvas, {
      state,
      dispatch: () => undefined,
      pixelThumbnailMap: { 'pixel-wall-1': 'data:image/png;base64,wall' },
      pixelAssetMetricsMap: {
        'pixel-wall-1': {
          pixelWidth: 18,
          pixelHeight: 10,
          alignedPixelWidth: 24,
          alignedPixelHeight: 16,
          atomCols: 3,
          atomRows: 2,
        },
      },
    }),
  )

  expect(html).toContain('data-structure-span="3x2"')
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test -- src/presentation/react-shell/dev-mode/TileCanvas.test.ts`

Expected: FAIL because `pixelAssetMetricsMap` is not supported or `data-structure-span` is absent

- [ ] **Step 3: Add a metrics map prop and structure span lookup**

```ts
type TileCanvasProps = {
  state: EditorState
  dispatch: Dispatch<EditorAction>
  pixelThumbnailMap?: Record<string, string>
  pixelAssetMetricsMap?: Record<
    string,
    {
      pixelWidth: number
      pixelHeight: number
      alignedPixelWidth: number
      alignedPixelHeight: number
      atomCols: number
      atomRows: number
    }
  >
}

const metrics = atom.tileId ? pixelAssetMetricsMap[atom.tileId] : undefined
const atomSpanX = metrics?.atomCols ?? atomsPerTile
const atomSpanY = metrics?.atomRows ?? atomsPerTile
```

- [ ] **Step 4: Render structure assets using aligned footprint math**

```ts
const backgroundWidth = metrics ? metrics.alignedPixelWidth : atomsPerTile * atomSize
const backgroundHeight = metrics ? metrics.alignedPixelHeight : atomsPerTile * atomSize
const localAtomX = metrics ? atom.x % metrics.atomCols : atom.x % atomsPerTile
const localAtomY = metrics ? atom.y % metrics.atomRows : atom.y % atomsPerTile

style={
  atom.tileId
    ? {
        backgroundImage: `url(${pixelThumbnailMap[atom.tileId] ?? ''})`,
        backgroundSize: `${backgroundWidth}px ${backgroundHeight}px`,
        backgroundPosition: `-${localAtomX * atomSize}px -${localAtomY * atomSize}px`,
        imageRendering: 'pixelated' as const,
      }
    : undefined
}
data-structure-span={metrics ? `${metrics.atomCols}x${metrics.atomRows}` : undefined}
```

- [ ] **Step 5: Pass the metrics map from map editor screen**

```ts
const pixelAssetMetricsMap = useMemo(() => {
  const map: Record<string, PixelAssetEntry> = {}
  for (const asset of pixelAssets) {
    map[`pixel-${asset.id}`] = asset
  }
  return map
}, [pixelAssets])

<TileCanvas
  state={state}
  dispatch={dispatch}
  onToolBlocked={handleToolBlocked}
  pixelThumbnailMap={pixelThumbnailMap}
  pixelAssetMetricsMap={pixelAssetMetricsMap}
/>
```

- [ ] **Step 6: Run the focused test and inspect for pass**

Run: `npm test -- src/presentation/react-shell/dev-mode/TileCanvas.test.ts`

Expected: PASS and the previous 32px atomic-grid regression still passes

- [ ] **Step 7: Commit**

```bash
git add Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileCanvas.tsx \
  Project/AIRPGWeb/src/presentation/react-shell/dev-mode/MapEditorScreen.tsx \
  Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileCanvas.test.ts
git commit -m "feat: render structure assets by aligned atomic footprint"
```

### Task 3: Align Asset Library Tool Shell To Map Editor

**Files:**
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/AssetLibraryScreen.tsx`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/PixelEditorInspector.tsx`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/PixelEditorCanvas.tsx`
- Modify: `Project/AIRPGWeb/src/domain/asset-library/pixel-editor-reducer.ts`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/asset-library.css`
- Test: `Project/AIRPGWeb/src/domain/asset-library/pixel-editor-reducer.test.ts`

- [ ] **Step 1: Add a failing reducer test for map-editor-style tool switching**

```ts
it('keeps brush as the single source of truth when switching subtools', () => {
  const asset = createEmptyPixelAsset({
    id: 'pixel-1',
    name: '墙体',
    layerId: 'structure',
    previewTileSize: 32,
  })
  let state = createInitialPixelEditorState(asset)

  state = pixelEditorReducer(state, { type: 'set-tool', tool: 'brush' })
  state = pixelEditorReducer(state, { type: 'set-brush-subtool', subtool: 'fill' })

  expect(state.activeTool).toBe('brush')
  expect(state.activeBrushSubtool).toBe('fill')
})
```

- [ ] **Step 2: Run test to verify it fails if behavior drifts**

Run: `npm test -- src/domain/asset-library/pixel-editor-reducer.test.ts`

Expected: Either FAIL if current assertions are missing, or PASS after adding the new expectation set; keep this task red until the new case exists

- [ ] **Step 3: Replace the inspector button rows with a map-editor-like left rail**

```tsx
type PixelEditorInspectorProps = {
  state: PixelEditorState
  dispatch: Dispatch<PixelEditorAction>
  onSave: () => void
  brushButtonRef: React.RefObject<HTMLButtonElement | null>
}

<div className="asset-library-left-rail">
  <button
    ref={brushButtonRef}
    type="button"
    className={`menu-btn ${state.activeTool === 'brush' ? 'primary' : ''}`}
    onClick={() => dispatch({ type: 'set-tool', tool: 'brush' })}
  >
    画笔
  </button>
  <button
    type="button"
    className={`menu-btn ${state.activeTool === 'eraser' ? 'primary' : ''}`}
    onClick={() => dispatch({ type: 'set-tool', tool: 'eraser' })}
  >
    橡皮
  </button>
  <button
    type="button"
    className={`menu-btn ${state.activeTool === 'picker' ? 'primary' : ''}`}
    onClick={() => dispatch({ type: 'set-tool', tool: 'picker' })}
  >
    吸管
  </button>
</div>
```

- [ ] **Step 4: Add a brush overlay anchored from the asset library screen**

```tsx
const brushButtonRef = useRef<HTMLButtonElement | null>(null)
const [brushOverlayStyle, setBrushOverlayStyle] = useState({ left: 120, top: 160 })

{editorState?.activeTool === 'brush' ? (
  <div
    className="asset-library-brush-overlay"
    style={{ left: `${brushOverlayStyle.left}px`, top: `${brushOverlayStyle.top}px` }}
  >
    <div className="map-editor-brush-overlay-title">画笔子工具</div>
    <button
      type="button"
      className={`menu-btn ${editorState.activeBrushSubtool === 'brush' ? 'primary' : ''}`}
      onClick={() => dispatch({ type: 'set-brush-subtool', subtool: 'brush' })}
    >
      笔刷
    </button>
    <button
      type="button"
      className={`menu-btn ${editorState.activeBrushSubtool === 'fill' ? 'primary' : ''}`}
      onClick={() => dispatch({ type: 'set-brush-subtool', subtool: 'fill' })}
    >
      填充
    </button>
    <button
      type="button"
      className={`menu-btn ${editorState.activeBrushSubtool === 'rectangle-outline' ? 'primary' : ''}`}
      onClick={() => dispatch({ type: 'set-brush-subtool', subtool: 'rectangle-outline' })}
    >
      边框矩形
    </button>
  </div>
) : null}
```

- [ ] **Step 5: Keep pointer behavior aligned with map editor semantics**

```ts
if (state.activeTool === 'brush' && state.activeBrushSubtool === 'fill') {
  dispatch({ type: 'flood-fill', x, y })
  isPointerDownRef.current = false
  return
}

if (
  state.activeTool === 'brush' &&
  (state.activeBrushSubtool === 'brush' || state.activeBrushSubtool === 'rectangle-outline')
) {
  isRectDragRef.current = true
  dispatch({ type: 'start-rectangle', x, y })
  return
}
```

- [ ] **Step 6: Add CSS for the left rail and overlay**

```css
.asset-library-layout {
  display: grid;
  grid-template-columns: 92px minmax(0, 1fr) 280px;
  gap: 12px;
  min-height: 0;
}

.asset-library-left-rail {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.asset-library-brush-overlay {
  position: fixed;
  z-index: 20;
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 10px;
  border: 1px solid #3a352d;
  border-radius: 8px;
  background: #16131d;
}
```

- [ ] **Step 7: Run focused tests**

Run: `npm test -- src/domain/asset-library/pixel-editor-reducer.test.ts`

Expected: PASS with the new tool alignment assertions

- [ ] **Step 8: Commit**

```bash
git add Project/AIRPGWeb/src/presentation/react-shell/dev-mode/AssetLibraryScreen.tsx \
  Project/AIRPGWeb/src/presentation/react-shell/dev-mode/PixelEditorInspector.tsx \
  Project/AIRPGWeb/src/presentation/react-shell/dev-mode/PixelEditorCanvas.tsx \
  Project/AIRPGWeb/src/domain/asset-library/pixel-editor-reducer.ts \
  Project/AIRPGWeb/src/presentation/react-shell/dev-mode/asset-library.css \
  Project/AIRPGWeb/src/domain/asset-library/pixel-editor-reducer.test.ts
git commit -m "feat: align asset library tools with map editor"
```

### Task 4: Verification, Preview Reopen, And Regression Sweep

**Files:**
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileCanvas.test.ts`
- Optional Modify: `Project/AIRPGWeb/tests/developer-mode.spec.ts`

- [ ] **Step 1: Extend the map canvas regression tests**

```ts
it('keeps the 32px standard grid as 4x4 atomic cells', () => {
  const map = createEmptyMapAsset({ id: 'map-1', name: '草稿', width: 1, height: 1 })
  let state = createInitialEditorState(map)
  state = editorReducer(state, { type: 'set-cell-size', size: 32 })

  const html = renderToStaticMarkup(createElement(TileCanvas, { state, dispatch: () => undefined }))
  const atomCount = html.match(/data-atom-x=/g)?.length ?? 0
  expect(atomCount).toBe(16)
})
```

- [ ] **Step 2: Run the full unit suite**

Run: `npm test`

Expected: PASS with all AIRPGWeb Vitest suites green

- [ ] **Step 3: Run the production build**

Run: `npm run build`

Expected: PASS with Vite build output and no TypeScript errors

- [ ] **Step 4: Start or reuse preview server with explicit URL**

Run: `npx vite preview --host 127.0.0.1 --port 4173`

Expected: Either `http://127.0.0.1:4173/` or a clear port-drift URL such as `http://127.0.0.1:4174/`

- [ ] **Step 5: Verify preview reachability and reopen the latest page**

Run: `powershell -ExecutionPolicy Bypass -File "g:\\UEGameDevelopment\\.trae\\scripts\\web-preview-guard.ps1"`

Then verify the actual active preview URL:

```powershell
(Invoke-WebRequest -Uri 'http://127.0.0.1:4174/' -UseBasicParsing).StatusCode
```

Expected: `200`

- [ ] **Step 6: Manual page checks**

Check in the reopened preview page:

- Saved `structure` asset can be selected in map palette
- Painting on the `结构层` shows the asset footprint instead of a missing render
- The painted asset stays aligned to `8x8` atomic cells
- Zoom changes display size only
- The asset library now exposes tool entry and brush subtool flow like the map editor

- [ ] **Step 7: Commit**

```bash
git add Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileCanvas.test.ts \
  Project/AIRPGWeb/tests/developer-mode.spec.ts
git commit -m "test: add regressions for structure assets and tool alignment"
```

---

## Spec Coverage Self-Review

- `结构层素材真实尺寸落图`: Covered by Task 1 and Task 2
- `8x8 原子网格与向上补齐`: Covered by Task 1 helper and Task 2 rendering math
- `左上角锚点`: Covered by Task 2 placement/rendering assumptions
- `地图缩放只影响显示`: Covered by Task 2 and Task 4 manual checks
- `素材库工具向地图绘制靠齐`: Covered by Task 3
- `页面重新打开验证`: Covered by Task 4

## Placeholder Self-Review

- No `TBD`, `TODO`, or “implement later” placeholders remain
- All tasks include exact file paths
- Code-changing steps include concrete code snippets
- Verification steps include exact commands and expected outcomes

## Type Consistency Self-Review

- `PixelAssetEntry` metadata additions are introduced in Task 1 and then consumed consistently in Task 2
- `pixelAssetMetricsMap` is introduced in Task 2 and only used after its prop contract is defined
- Asset library tool terms stay consistent with map editor terms: `画笔 / 橡皮 / 吸管`, `笔刷 / 填充 / 边框矩形`
