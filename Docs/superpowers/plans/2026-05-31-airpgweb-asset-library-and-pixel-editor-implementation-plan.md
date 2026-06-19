# AIRPGWeb Asset Library And Pixel Editor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a standalone `开发者模式 -> 素材库` module with an `8x8`-based pixel editor, grouped preview grid for `16/24/32`, zoomable large canvas, and persistent asset save/reopen workflow.

**Architecture:** Keep the asset library separate from the existing map editor by introducing a new `domain/asset-library` state model and a dedicated Dexie-backed repository. The React shell only routes into the new module, while the pixel editor screen composes a list panel, a zoomable canvas with dual grids, and a property/tool panel around a focused reducer.

**Tech Stack:** React 19, TypeScript, Vitest, Playwright, Dexie

---

## File Structure

**Create**
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\asset-library\asset-library-types.ts`
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\asset-library\asset-library-types.test.ts`
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\asset-library\pixel-editor-reducer.ts`
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\asset-library\pixel-editor-reducer.test.ts`
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\persistence\repositories\asset-library-repository.ts`
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\AssetLibraryScreen.tsx`
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\AssetLibrarySidebar.tsx`
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\PixelEditorCanvas.tsx`
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\PixelEditorInspector.tsx`

**Modify**
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\persistence\db\airpg-db.ts`
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\DeveloperModeShell.tsx`
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\DeveloperModeHome.tsx`
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\App.css`
- `g:\UEGameDevelopment\Project\AIRPGWeb\tests\developer-mode.spec.ts`

**Why these files**
- `asset-library-types.ts` defines the source of truth for `8x8` base resolution, preview tile sizes, layer ownership, and structured pixels.
- `pixel-editor-reducer.ts` isolates drawing, zoom, brush, and grouping-grid behavior from the map editor reducer.
- `asset-library-repository.ts` persists assets into Dexie so saved assets survive reload and can later be consumed by the map editor.
- `AssetLibraryScreen.tsx` owns async loading/saving and composes the UI.
- `PixelEditorCanvas.tsx` renders the large zoomable board with thin atom-grid lines and thicker preview-group lines.

---

### Task 1: Define asset-library data types and constraints

**Files:**
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\asset-library\asset-library-types.ts`
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\asset-library\asset-library-types.test.ts`

- [ ] **Step 1: Write the failing tests**

```ts
import { describe, expect, it } from 'vitest'
import {
  ASSET_LIBRARY_LAYERS,
  ATOM_GRID_SIZE,
  PREVIEW_TILE_SIZES,
  createEmptyPixelAsset,
  getPreviewGroupingFactor,
} from './asset-library-types'

describe('asset-library-types', () => {
  it('fixes the asset atom grid at 8 and supports 16/24/32 preview tile sizes', () => {
    expect(ATOM_GRID_SIZE).toBe(8)
    expect(PREVIEW_TILE_SIZES).toEqual([16, 24, 32])
    expect(getPreviewGroupingFactor(16)).toBe(2)
    expect(getPreviewGroupingFactor(24)).toBe(3)
    expect(getPreviewGroupingFactor(32)).toBe(4)
  })

  it('creates a new asset bound to one layer with transparent pixels', () => {
    const asset = createEmptyPixelAsset({
      id: 'asset-1',
      name: '外墙试作',
      layerId: 'structure',
      previewTileSize: 32,
    })

    expect(ASSET_LIBRARY_LAYERS).toEqual(['region', 'ground', 'structure', 'openings', 'art'])
    expect(asset.baseResolution).toBe(8)
    expect(asset.pixelWidth).toBe(8)
    expect(asset.pixelHeight).toBe(8)
    expect(asset.pixels).toHaveLength(64)
    expect(asset.pixels.every((pixel) => pixel.color === null)).toBe(true)
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
npm run test -- src/domain/asset-library/asset-library-types.test.ts
```

Expected: FAIL because the new module does not exist yet.

- [ ] **Step 3: Write the minimal implementation**

```ts
export const ATOM_GRID_SIZE = 8
export const PREVIEW_TILE_SIZES = [16, 24, 32] as const
export const ASSET_LIBRARY_LAYERS = ['region', 'ground', 'structure', 'openings', 'art'] as const

export type AssetLayerId = (typeof ASSET_LIBRARY_LAYERS)[number]
export type PreviewTileSize = (typeof PREVIEW_TILE_SIZES)[number]

export type PixelCell = {
  x: number
  y: number
  color: string | null
}

export type PixelAsset = {
  id: string
  name: string
  layerId: AssetLayerId
  baseResolution: 8
  previewTileSize: PreviewTileSize
  pixelWidth: number
  pixelHeight: number
  pixels: PixelCell[]
  thumbnail: string | null
  updatedAt: string
}

export function getPreviewGroupingFactor(size: PreviewTileSize) {
  return size / ATOM_GRID_SIZE
}

export function createEmptyPixelAsset(input: {
  id: string
  name: string
  layerId: AssetLayerId
  previewTileSize: PreviewTileSize
}): PixelAsset {
  return {
    id: input.id,
    name: input.name,
    layerId: input.layerId,
    baseResolution: 8,
    previewTileSize: input.previewTileSize,
    pixelWidth: 8,
    pixelHeight: 8,
    pixels: Array.from({ length: 64 }, (_, index) => ({
      x: index % 8,
      y: Math.floor(index / 8),
      color: null,
    })),
    thumbnail: null,
    updatedAt: new Date(0).toISOString(),
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
npm run test -- src/domain/asset-library/asset-library-types.test.ts
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/domain/asset-library/asset-library-types.ts src/domain/asset-library/asset-library-types.test.ts
git commit -m "feat: add asset library base types"
```

---

### Task 2: Build the pixel-editor reducer for drawing and zoom

**Files:**
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\asset-library\pixel-editor-reducer.ts`
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\asset-library\pixel-editor-reducer.test.ts`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\asset-library\asset-library-types.ts`

- [ ] **Step 1: Write the failing tests**

```ts
import { describe, expect, it } from 'vitest'
import { createEmptyPixelAsset } from './asset-library-types'
import { createInitialPixelEditorState, pixelEditorReducer } from './pixel-editor-reducer'

describe('pixelEditorReducer', () => {
  it('paints pixels with the selected color and brush size', () => {
    const asset = createEmptyPixelAsset({
      id: 'asset-1',
      name: '草地',
      layerId: 'ground',
      previewTileSize: 32,
    })
    let state = createInitialPixelEditorState(asset)

    state = pixelEditorReducer(state, { type: 'set-color', color: '#6d955b' })
    state = pixelEditorReducer(state, { type: 'set-brush-size', size: 2 })
    state = pixelEditorReducer(state, { type: 'paint-at', x: 1, y: 1 })

    expect(state.asset.pixels.filter((pixel) => pixel.color === '#6d955b')).toHaveLength(4)
  })

  it('locks stroke direction to horizontal or vertical when axis lock is enabled', () => {
    const asset = createEmptyPixelAsset({
      id: 'asset-2',
      name: '墙线',
      layerId: 'structure',
      previewTileSize: 16,
    })
    let state = createInitialPixelEditorState(asset)

    state = pixelEditorReducer(state, { type: 'toggle-axis-lock', enabled: true })
    state = pixelEditorReducer(state, { type: 'set-color', color: '#ffffff' })
    state = pixelEditorReducer(state, { type: 'start-stroke', x: 0, y: 0 })
    state = pixelEditorReducer(state, { type: 'extend-stroke', x: 3, y: 2 })
    state = pixelEditorReducer(state, { type: 'finish-stroke' })

    expect(state.asset.pixels.filter((pixel) => pixel.color === '#ffffff').map((pixel) => `${pixel.x}:${pixel.y}`)).toEqual([
      '0:0',
      '1:0',
      '2:0',
      '3:0',
    ])
  })

  it('changes preview grouping and editor zoom independently', () => {
    const asset = createEmptyPixelAsset({
      id: 'asset-3',
      name: '树冠',
      layerId: 'art',
      previewTileSize: 24,
    })
    let state = createInitialPixelEditorState(asset)

    state = pixelEditorReducer(state, { type: 'set-preview-tile-size', size: 32 })
    state = pixelEditorReducer(state, { type: 'set-canvas-zoom', zoom: 18 })

    expect(state.asset.previewTileSize).toBe(32)
    expect(state.canvasZoom).toBe(18)
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
npm run test -- src/domain/asset-library/pixel-editor-reducer.test.ts
```

Expected: FAIL because the reducer does not exist yet.

- [ ] **Step 3: Write the minimal reducer state and actions**

```ts
export type PixelTool = 'brush' | 'eraser' | 'picker'

export type PixelEditorState = {
  asset: PixelAsset
  activeTool: PixelTool
  selectedColor: string
  brushSize: 1 | 2 | 3
  axisLockEnabled: boolean
  canvasZoom: number
  strokeAnchor: { x: number; y: number } | null
}

export function createInitialPixelEditorState(asset: PixelAsset): PixelEditorState {
  return {
    asset,
    activeTool: 'brush',
    selectedColor: '#000000',
    brushSize: 1,
    axisLockEnabled: false,
    canvasZoom: 18,
    strokeAnchor: null,
  }
}
```

- [ ] **Step 4: Add minimal paint and axis-lock behavior**

```ts
function paintSquare(pixels: PixelCell[], x: number, y: number, size: 1 | 2 | 3, color: string | null) {
  const next = pixels.map((pixel) => ({ ...pixel }))
  for (let offsetY = 0; offsetY < size; offsetY++) {
    for (let offsetX = 0; offsetX < size; offsetX++) {
      const target = next.find((pixel) => pixel.x === x + offsetX && pixel.y === y + offsetY)
      if (target) {
        target.color = color
      }
    }
  }
  return next
}
```

- [ ] **Step 5: Run test to verify it passes**

Run:

```bash
npm run test -- src/domain/asset-library/pixel-editor-reducer.test.ts
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add src/domain/asset-library/asset-library-types.ts src/domain/asset-library/pixel-editor-reducer.ts src/domain/asset-library/pixel-editor-reducer.test.ts
git commit -m "feat: add pixel editor reducer"
```

---

### Task 3: Add Dexie persistence for pixel assets

**Files:**
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\persistence\db\airpg-db.ts`
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\persistence\repositories\asset-library-repository.ts`
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\persistence\repositories\asset-library-repository.test.ts`

- [ ] **Step 1: Write the failing repository tests**

```ts
import { describe, expect, it } from 'vitest'
import { createEmptyPixelAsset } from '../../domain/asset-library/asset-library-types'
import { createAssetLibraryRepository } from './asset-library-repository'

describe('asset-library-repository', () => {
  it('saves and reloads pixel assets ordered by update time', async () => {
    const repo = createAssetLibraryRepository()
    const ground = createEmptyPixelAsset({ id: 'ground-1', name: '草地', layerId: 'ground', previewTileSize: 16 })
    const wall = createEmptyPixelAsset({ id: 'wall-1', name: '外墙', layerId: 'structure', previewTileSize: 32 })

    await repo.save({ ...ground, updatedAt: '2026-05-31T10:00:00.000Z' })
    await repo.save({ ...wall, updatedAt: '2026-05-31T11:00:00.000Z' })

    const items = await repo.list()

    expect(items.map((item) => item.id)).toEqual(['wall-1', 'ground-1'])
  })

  it('filters by layer id', async () => {
    const repo = createAssetLibraryRepository()
    await repo.save(createEmptyPixelAsset({ id: 'region-1', name: '区域块', layerId: 'region', previewTileSize: 24 }))
    await repo.save(createEmptyPixelAsset({ id: 'art-1', name: '光影块', layerId: 'art', previewTileSize: 24 }))

    const items = await repo.list({ layerId: 'art' })
    expect(items.map((item) => item.id)).toEqual(['art-1'])
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
npm run test -- src/persistence/repositories/asset-library-repository.test.ts
```

Expected: FAIL because the repository and new Dexie table do not exist yet.

- [ ] **Step 3: Extend Dexie with an asset table**

```ts
import type { PixelAsset } from '../../domain/asset-library/asset-library-types'

export class AirpgDb extends Dexie {
  pixelAssets!: EntityTable<PixelAsset, 'id'>

  constructor() {
    super('airpg-web-v3')
    this.version(3).stores({
      saveSlots: 'slotId,savedAt',
      mapAssets: 'id,name,runtimePublished',
      worldAssets: 'id,name,runtimePublished',
      pixelAssets: 'id,name,layerId,updatedAt',
    })
  }
}
```

- [ ] **Step 4: Add the repository implementation**

```ts
import { db } from '../db/airpg-db'
import type { AssetLayerId, PixelAsset } from '../../domain/asset-library/asset-library-types'

export function createAssetLibraryRepository() {
  return {
    async save(asset: PixelAsset) {
      await db.pixelAssets.put(asset)
    },
    async get(id: string) {
      return (await db.pixelAssets.get(id)) ?? null
    },
    async list(filter?: { layerId?: AssetLayerId }) {
      const items = filter?.layerId
        ? await db.pixelAssets.where('layerId').equals(filter.layerId).toArray()
        : await db.pixelAssets.toArray()
      return items.sort((a, b) => b.updatedAt.localeCompare(a.updatedAt))
    },
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run:

```bash
npm run test -- src/persistence/repositories/asset-library-repository.test.ts
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add src/persistence/db/airpg-db.ts src/persistence/repositories/asset-library-repository.ts src/persistence/repositories/asset-library-repository.test.ts
git commit -m "feat: add pixel asset repository"
```

---

### Task 4: Add the developer-mode asset library entry and screen shell

**Files:**
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\DeveloperModeShell.tsx`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\DeveloperModeHome.tsx`
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\AssetLibraryScreen.tsx`
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\AssetLibrarySidebar.tsx`
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\PixelEditorInspector.tsx`

- [ ] **Step 1: Write the failing UI test**

```ts
test('developer mode opens the asset library module', async ({ page }) => {
  await page.goto('/')
  await page.getByRole('button', { name: '开发者模式' }).click()
  await page.getByRole('button', { name: '素材库' }).click()

  await expect(page.getByRole('heading', { name: '素材库' })).toBeVisible()
  await expect(page.getByRole('button', { name: '新建素材' })).toBeVisible()
  await expect(page.getByLabel('预览规格')).toBeVisible()
})
```

- [ ] **Step 2: Run the UI test to verify it fails**

Run:

```bash
npx playwright test tests/developer-mode.spec.ts --grep "developer mode opens the asset library module"
```

Expected: FAIL because the module entry does not exist yet.

- [ ] **Step 3: Add the new developer-mode route**

```tsx
type ModuleId = 'home' | 'map-editor' | 'asset-library'

if (activeModule === 'asset-library') {
  return <AssetLibraryScreen onBack={() => setActiveModule('home')} />
}

return (
  <DeveloperModeHome
    onOpenMapEditor={() => setActiveModule('map-editor')}
    onOpenAssetLibrary={() => setActiveModule('asset-library')}
    onBack={onBack}
  />
)
```

- [ ] **Step 4: Add the home-entry button and minimal screen shell**

```tsx
<button type="button" className="menu-btn primary" onClick={onOpenAssetLibrary}>
  素材库
</button>
```

```tsx
export function AssetLibraryScreen({ onBack }: { onBack: () => void }) {
  return (
    <section className="asset-library-shell">
      <header className="asset-library-header">
        <h1>素材库</h1>
        <button type="button" className="menu-btn secondary" onClick={onBack}>
          返回
        </button>
      </header>
      <div className="asset-library-layout">
        <AssetLibrarySidebar />
        <div className="asset-library-editor-empty">请先新建素材</div>
        <PixelEditorInspector />
      </div>
    </section>
  )
}
```

- [ ] **Step 5: Run the UI test to verify it passes**

Run:

```bash
npx playwright test tests/developer-mode.spec.ts --grep "developer mode opens the asset library module"
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add src/presentation/react-shell/dev-mode/DeveloperModeShell.tsx src/presentation/react-shell/dev-mode/DeveloperModeHome.tsx src/presentation/react-shell/dev-mode/AssetLibraryScreen.tsx src/presentation/react-shell/dev-mode/AssetLibrarySidebar.tsx src/presentation/react-shell/dev-mode/PixelEditorInspector.tsx tests/developer-mode.spec.ts
git commit -m "feat: add asset library developer module"
```

---

### Task 5: Implement the large dual-grid canvas and save workflow

**Files:**
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\PixelEditorCanvas.tsx`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\AssetLibraryScreen.tsx`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\AssetLibrarySidebar.tsx`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\PixelEditorInspector.tsx`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\App.css`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\tests\developer-mode.spec.ts`

- [ ] **Step 1: Write the failing reducer/UI integration tests**

```ts
test('asset library creates, paints, saves, and reopens a ground asset', async ({ page }) => {
  await page.goto('/')
  await page.getByRole('button', { name: '开发者模式' }).click()
  await page.getByRole('button', { name: '素材库' }).click()
  await page.getByRole('button', { name: '新建素材' }).click()

  await page.getByLabel('素材名称').fill('草地试作')
  await page.getByLabel('所属图层').selectOption('ground')
  await page.getByLabel('预览规格').selectOption('32')
  await page.getByRole('button', { name: '放大画板' }).click()
  await page.getByTestId('pixel-cell-1-1').click()
  await page.getByRole('button', { name: '保存素材' }).click()

  await expect(page.getByRole('button', { name: '草地试作' })).toBeVisible()
  await page.getByRole('button', { name: '草地试作' }).click()
  await expect(page.getByTestId('pixel-cell-1-1')).toHaveAttribute('data-filled', 'true')
})

test('asset library shows thicker grouping lines when preview tile size is 32', async ({ page }) => {
  await page.goto('/')
  await page.getByRole('button', { name: '开发者模式' }).click()
  await page.getByRole('button', { name: '素材库' }).click()
  await page.getByRole('button', { name: '新建素材' }).click()
  await page.getByLabel('预览规格').selectOption('32')

  await expect(page.getByTestId('pixel-editor-canvas')).toHaveAttribute('data-preview-group-size', '4')
})
```

- [ ] **Step 2: Run the UI tests to verify they fail**

Run:

```bash
npx playwright test tests/developer-mode.spec.ts --grep "asset library creates, paints, saves, and reopens a ground asset|asset library shows thicker grouping lines when preview tile size is 32"
```

Expected: FAIL because the editor canvas, save workflow, and preview-group metadata are not implemented.

- [ ] **Step 3: Build the zoomable canvas**

```tsx
export function PixelEditorCanvas({
  state,
  dispatch,
}: {
  state: PixelEditorState
  dispatch: Dispatch<PixelEditorAction>
}) {
  const groupSize = getPreviewGroupingFactor(state.asset.previewTileSize)

  return (
    <section className="pixel-editor-board">
      <div className="pixel-editor-board-toolbar">
        <button type="button" onClick={() => dispatch({ type: 'set-canvas-zoom', zoom: state.canvasZoom + 2 })}>
          放大画板
        </button>
      </div>
      <div
        className="pixel-editor-canvas"
        data-testid="pixel-editor-canvas"
        data-preview-group-size={groupSize}
        style={{
          '--pixel-size': `${state.canvasZoom}px`,
          '--preview-group-size': String(groupSize),
        } as React.CSSProperties}
      >
        {state.asset.pixels.map((pixel) => (
          <button
            key={`${pixel.x}-${pixel.y}`}
            type="button"
            data-testid={`pixel-cell-${pixel.x}-${pixel.y}`}
            data-filled={pixel.color ? 'true' : 'false'}
            className="pixel-editor-cell"
            style={{ backgroundColor: pixel.color ?? 'transparent' }}
            onPointerDown={() => dispatch({ type: 'paint-at', x: pixel.x, y: pixel.y })}
          />
        ))}
      </div>
    </section>
  )
}
```

- [ ] **Step 4: Add CSS for dual-grid rendering and large canvas**

```css
.pixel-editor-canvas {
  --pixel-size: 18px;
  --preview-group-size: 4;
  display: grid;
  grid-template-columns: repeat(8, var(--pixel-size));
  grid-template-rows: repeat(8, var(--pixel-size));
  background:
    linear-gradient(to right, rgba(212, 168, 83, 0.15) 1px, transparent 1px),
    linear-gradient(to bottom, rgba(212, 168, 83, 0.15) 1px, transparent 1px);
  image-rendering: pixelated;
}

.pixel-editor-cell {
  border-right: 1px solid rgba(212, 168, 83, 0.18);
  border-bottom: 1px solid rgba(212, 168, 83, 0.18);
}

.pixel-editor-cell.group-edge-x {
  border-right: 2px solid rgba(212, 168, 83, 0.44);
}

.pixel-editor-cell.group-edge-y {
  border-bottom: 2px solid rgba(212, 168, 83, 0.44);
}
```

- [ ] **Step 5: Connect save/reopen to Dexie**

```tsx
const repoRef = useRef(createAssetLibraryRepository())
const [assets, setAssets] = useState<PixelAsset[]>([])
const [editorState, setEditorState] = useState<PixelEditorState | null>(null)

async function handleSave() {
  if (!editorState) return
  const nextAsset = {
    ...editorState.asset,
    updatedAt: new Date().toISOString(),
  }
  await repoRef.current.save(nextAsset)
  setAssets(await repoRef.current.list())
}
```

- [ ] **Step 6: Run the UI tests to verify they pass**

Run:

```bash
npx playwright test tests/developer-mode.spec.ts --grep "asset library creates, paints, saves, and reopens a ground asset|asset library shows thicker grouping lines when preview tile size is 32"
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add src/presentation/react-shell/dev-mode/AssetLibraryScreen.tsx src/presentation/react-shell/dev-mode/AssetLibrarySidebar.tsx src/presentation/react-shell/dev-mode/PixelEditorCanvas.tsx src/presentation/react-shell/dev-mode/PixelEditorInspector.tsx src/App.css tests/developer-mode.spec.ts
git commit -m "feat: add pixel editor canvas and asset save flow"
```

---

### Task 6: Final verification and cleanup

**Files:**
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\AssetLibraryScreen.tsx` (if needed)
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\App.css` (if needed)
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\tests\developer-mode.spec.ts` (if needed)

- [ ] **Step 1: Run focused unit tests**

Run:

```bash
npm run test -- src/domain/asset-library/asset-library-types.test.ts src/domain/asset-library/pixel-editor-reducer.test.ts src/persistence/repositories/asset-library-repository.test.ts
```

Expected: PASS.

- [ ] **Step 2: Run the developer-mode regression tests**

Run:

```bash
npx playwright test tests/developer-mode.spec.ts --grep "developer mode opens the asset library module|asset library creates, paints, saves, and reopens a ground asset|asset library shows thicker grouping lines when preview tile size is 32|map editor filters palette by active layer and paints selected tile|structure palette groups wall tiles before showing detailed variants"
```

Expected: PASS.

- [ ] **Step 3: Run production build**

Run:

```bash
npm run build
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add src/domain/asset-library src/persistence/db/airpg-db.ts src/persistence/repositories/asset-library-repository.ts src/presentation/react-shell/dev-mode/DeveloperModeShell.tsx src/presentation/react-shell/dev-mode/DeveloperModeHome.tsx src/presentation/react-shell/dev-mode/AssetLibraryScreen.tsx src/presentation/react-shell/dev-mode/AssetLibrarySidebar.tsx src/presentation/react-shell/dev-mode/PixelEditorCanvas.tsx src/presentation/react-shell/dev-mode/PixelEditorInspector.tsx src/App.css tests/developer-mode.spec.ts
git commit -m "test: verify asset library pixel editor workflow"
```

---

## Self-Review

### Spec coverage
- 独立 `开发者模式 -> 素材库` 入口: Task 4
- `8x8` 原子基准与 `16/24/32` 预览规格: Tasks 1 and 2
- 大画板 + 缩放: Tasks 2 and 5
- 双层网格与较粗预览分组线: Tasks 1 and 5
- 单图层归档与素材持久化: Tasks 1 and 3
- 保存并重新打开素材: Task 5

### Placeholder scan
- No `TODO`, `TBD`, or vague future placeholders remain in tasks
- Each task includes explicit files, code, commands, and expected outcomes

### Type consistency
- `PixelAsset`, `PreviewTileSize`, and `AssetLayerId` are introduced in Task 1 and reused consistently
- `createAssetLibraryRepository`, `createInitialPixelEditorState`, and `AssetLibraryScreen` names remain stable across later tasks

---

Plan complete and saved to `Docs/superpowers/plans/2026-05-31-airpgweb-asset-library-and-pixel-editor-implementation-plan.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
