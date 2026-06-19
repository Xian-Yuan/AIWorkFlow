# AIRPGWeb Tile Topology And Interaction Refinement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the existing ingame tile editor so house topology can be drawn with precise wall and door families, full-cell DOM/CSS skins, drag painting, locked layers, map rename/save-as, and draggable world placement.

**Architecture:** Keep the existing React shell, reducer, Dexie repositories, and runtime bridge. Add focused topology metadata and pure validation helpers in `domain/map-editor`, then let `TileCanvas` render full-cell skins from that metadata while UI panels expose drag painting, locking, rename/save-as, and snapped world placement.

**Tech Stack:** React 19, TypeScript, Dexie, Vitest, Playwright, Vite

---

## File Map

### New Files

- `Project/AIRPGWeb/src/domain/map-editor/tile-topology.ts`
- `Project/AIRPGWeb/src/domain/map-editor/tile-topology.test.ts`
- `Project/AIRPGWeb/src/domain/map-editor/tile-validation.ts`
- `Project/AIRPGWeb/src/domain/map-editor/tile-validation.test.ts`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileSkin.tsx`

### Modified Files

- `Project/AIRPGWeb/src/domain/map-editor/map-editor-types.ts`
- `Project/AIRPGWeb/src/domain/map-editor/tile-palette.ts`
- `Project/AIRPGWeb/src/domain/map-editor/editor-reducer.ts`
- `Project/AIRPGWeb/src/domain/map-editor/editor-reducer.test.ts`
- `Project/AIRPGWeb/src/persistence/repositories/map-asset-repository.ts`
- `Project/AIRPGWeb/src/persistence/repositories/world-asset-repository.ts`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/MapEditorScreen.tsx`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/EditorToolbar.tsx`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/EditorLayerList.tsx`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileCanvas.tsx`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/WorldCompositionPanel.tsx`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/MapBrowserPanel.tsx`
- `Project/AIRPGWeb/src/App.css`
- `Project/AIRPGWeb/tests/developer-mode.spec.ts`

### Responsibility Split

- `tile-topology.ts`: authoritative topology metadata for `outer-wall-*`, `inner-wall-*`, `yard-wall-*`, `door-socket-*`, `door-leaf-*`
- `tile-validation.ts`: pure legality checks for door/socket pairing, layer conflicts, locked-layer guard, and closure hints
- `TileSkin.tsx`: full-cell DOM/CSS rendering for walls, doors, and micro-texture
- `editor-reducer.ts`: drag stroke batching, lock-aware edits, map rename, save-as-ready map replacement
- `TileCanvas.tsx`: single-click paint, pointer-hold drag paint, directional straight-wall brush constraints
- `EditorLayerList.tsx`: layer lock toggles and visible edit target
- `EditorToolbar.tsx` / `MapBrowserPanel.tsx`: map rename, save-as, publish, and reopen affordances
- `WorldCompositionPanel.tsx`: draggable world placement list with tile-grid snapping

## Task 1: Expand Precise Tile Families And Topology Metadata

**Files:**
- Create: `Project/AIRPGWeb/src/domain/map-editor/tile-topology.ts`
- Create: `Project/AIRPGWeb/src/domain/map-editor/tile-topology.test.ts`
- Modify: `Project/AIRPGWeb/src/domain/map-editor/map-editor-types.ts`
- Modify: `Project/AIRPGWeb/src/domain/map-editor/tile-palette.ts`

- [ ] **Step 1: Write the failing topology metadata test**

```ts
import { describe, expect, it } from 'vitest';
import { getTileTopology, listTileFamilyIdsForLayer } from './tile-topology';

describe('tile topology metadata', () => {
  it('defines manual topology families for structure and opening layers', () => {
    expect(listTileFamilyIdsForLayer('structure')).toEqual(
      expect.arrayContaining([
        'outer-wall-h',
        'outer-corner-tl',
        'outer-t-up',
        'outer-cross',
        'inner-wall-v',
        'yard-wall-h',
        'door-socket-h',
      ]),
    );

    expect(getTileTopology('door-leaf-h-closed')).toMatchObject({
      layerId: 'openings',
      family: 'door-leaf',
      orientation: 'h',
      blocksMovement: true,
      requiresSocket: 'door-socket-h',
    });
  });
});
```

- [ ] **Step 2: Run the failing test**

Run:

```bash
npm run test -- src/domain/map-editor/tile-topology.test.ts
```

Expected: FAIL because `tile-topology.ts` does not exist and the current palette does not expose the refined families.

- [ ] **Step 3: Add explicit topology metadata and wire palette entries to it**

```ts
// tile-topology.ts
import type { EditorLayerId } from './map-editor-types';

export type TileFamily =
  | 'outer-wall'
  | 'inner-wall'
  | 'yard-wall'
  | 'outer-corner'
  | 'inner-corner'
  | 'outer-t'
  | 'inner-t'
  | 'outer-cross'
  | 'inner-cross'
  | 'wall-end'
  | 'door-socket'
  | 'door-leaf'
  | 'ground'
  | 'region'
  | 'overlay';

export type TileTopologyMeta = {
  tileId: string;
  layerId: EditorLayerId;
  family: TileFamily;
  orientation: 'none' | 'h' | 'v' | 'tl' | 'tr' | 'bl' | 'br' | 't-up' | 't-right' | 't-down' | 't-left' | 'cross';
  previewLabel: string;
  blocksMovement: boolean;
  requiresSocket?: 'door-socket-h' | 'door-socket-v';
  skin: 'full-cell-wall' | 'full-cell-door' | 'full-cell-ground' | 'full-cell-overlay';
};

const topology: TileTopologyMeta[] = [
  { tileId: 'outer-wall-h', layerId: 'structure', family: 'outer-wall', orientation: 'h', previewLabel: '外墙横', blocksMovement: true, skin: 'full-cell-wall' },
  { tileId: 'outer-wall-v', layerId: 'structure', family: 'outer-wall', orientation: 'v', previewLabel: '外墙竖', blocksMovement: true, skin: 'full-cell-wall' },
  { tileId: 'outer-corner-tl', layerId: 'structure', family: 'outer-corner', orientation: 'tl', previewLabel: '外墙左上角', blocksMovement: true, skin: 'full-cell-wall' },
  { tileId: 'outer-corner-tr', layerId: 'structure', family: 'outer-corner', orientation: 'tr', previewLabel: '外墙右上角', blocksMovement: true, skin: 'full-cell-wall' },
  { tileId: 'outer-corner-bl', layerId: 'structure', family: 'outer-corner', orientation: 'bl', previewLabel: '外墙左下角', blocksMovement: true, skin: 'full-cell-wall' },
  { tileId: 'outer-corner-br', layerId: 'structure', family: 'outer-corner', orientation: 'br', previewLabel: '外墙右下角', blocksMovement: true, skin: 'full-cell-wall' },
  { tileId: 'outer-t-up', layerId: 'structure', family: 'outer-t', orientation: 't-up', previewLabel: '外墙T上', blocksMovement: true, skin: 'full-cell-wall' },
  { tileId: 'outer-t-right', layerId: 'structure', family: 'outer-t', orientation: 't-right', previewLabel: '外墙T右', blocksMovement: true, skin: 'full-cell-wall' },
  { tileId: 'outer-t-down', layerId: 'structure', family: 'outer-t', orientation: 't-down', previewLabel: '外墙T下', blocksMovement: true, skin: 'full-cell-wall' },
  { tileId: 'outer-t-left', layerId: 'structure', family: 'outer-t', orientation: 't-left', previewLabel: '外墙T左', blocksMovement: true, skin: 'full-cell-wall' },
  { tileId: 'outer-cross', layerId: 'structure', family: 'outer-cross', orientation: 'cross', previewLabel: '外墙十字', blocksMovement: true, skin: 'full-cell-wall' },
  { tileId: 'inner-wall-h', layerId: 'structure', family: 'inner-wall', orientation: 'h', previewLabel: '内墙横', blocksMovement: true, skin: 'full-cell-wall' },
  { tileId: 'inner-wall-v', layerId: 'structure', family: 'inner-wall', orientation: 'v', previewLabel: '内墙竖', blocksMovement: true, skin: 'full-cell-wall' },
  { tileId: 'yard-wall-h', layerId: 'structure', family: 'yard-wall', orientation: 'h', previewLabel: '院墙横', blocksMovement: true, skin: 'full-cell-wall' },
  { tileId: 'yard-wall-v', layerId: 'structure', family: 'yard-wall', orientation: 'v', previewLabel: '院墙竖', blocksMovement: true, skin: 'full-cell-wall' },
  { tileId: 'door-socket-h', layerId: 'structure', family: 'door-socket', orientation: 'h', previewLabel: '横门位', blocksMovement: false, skin: 'full-cell-wall' },
  { tileId: 'door-socket-v', layerId: 'structure', family: 'door-socket', orientation: 'v', previewLabel: '竖门位', blocksMovement: false, skin: 'full-cell-wall' },
  { tileId: 'door-leaf-h-closed', layerId: 'openings', family: 'door-leaf', orientation: 'h', previewLabel: '横门关', blocksMovement: true, requiresSocket: 'door-socket-h', skin: 'full-cell-door' },
  { tileId: 'door-leaf-h-open', layerId: 'openings', family: 'door-leaf', orientation: 'h', previewLabel: '横门开', blocksMovement: false, requiresSocket: 'door-socket-h', skin: 'full-cell-door' },
  { tileId: 'door-leaf-v-closed', layerId: 'openings', family: 'door-leaf', orientation: 'v', previewLabel: '竖门关', blocksMovement: true, requiresSocket: 'door-socket-v', skin: 'full-cell-door' },
  { tileId: 'door-leaf-v-open', layerId: 'openings', family: 'door-leaf', orientation: 'v', previewLabel: '竖门开', blocksMovement: false, requiresSocket: 'door-socket-v', skin: 'full-cell-door' },
];

export function getTileTopology(tileId: string) {
  return topology.find((item) => item.tileId === tileId) ?? null;
}

export function listTileFamilyIdsForLayer(layerId: EditorLayerId) {
  return topology.filter((item) => item.layerId === layerId).map((item) => item.tileId);
}

export const topologyTiles = topology;
```

```ts
// tile-palette.ts
import { topologyTiles } from './tile-topology';

export type TilePreset = {
  id: string;
  label: string;
  layerId: EditorLayerId;
  preview: string;
  family: string;
};

const topologyPreviewMap: Record<string, string> = {
  'outer-wall-h': '==',
  'outer-wall-v': '||',
  'outer-corner-tl': 'L',
  'outer-corner-tr': 'J',
  'outer-corner-bl': 'F',
  'outer-corner-br': '7',
  'door-socket-h': '[]',
  'door-socket-v': '][',
  'door-leaf-h-closed': '门',
  'door-leaf-h-open': '开',
  'door-leaf-v-closed': '门',
  'door-leaf-v-open': '开',
};

export const tilePalette: TilePreset[] = [
  { id: 'ground-grass', label: '草地', layerId: 'ground', preview: '', family: 'ground' },
  { id: 'ground-yard', label: '院地', layerId: 'ground', preview: '', family: 'ground' },
  { id: 'ground-interior-floor', label: '室内地面', layerId: 'ground', preview: '', family: 'ground' },
  { id: 'art-micro-floor', label: '微纹理地面', layerId: 'art', preview: '', family: 'overlay' },
  ...topologyTiles.map((tile) => ({
    id: tile.tileId,
    label: tile.previewLabel,
    layerId: tile.layerId,
    preview: topologyPreviewMap[tile.tileId] ?? '',
    family: tile.family,
  })),
];
```

- [ ] **Step 4: Re-run the topology test**

Run:

```bash
npm run test -- src/domain/map-editor/tile-topology.test.ts
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/domain/map-editor/map-editor-types.ts src/domain/map-editor/tile-palette.ts src/domain/map-editor/tile-topology.ts src/domain/map-editor/tile-topology.test.ts
git commit -m "feat: add precise tile topology families"
```

## Task 2: Replace Character Preview With Full-Cell DOM/CSS Tile Skin

**Files:**
- Create: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileSkin.tsx`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileCanvas.tsx`
- Modify: `Project/AIRPGWeb/src/App.css`
- Test: `Project/AIRPGWeb/tests/developer-mode.spec.ts`

- [ ] **Step 1: Extend the Playwright editor test to verify dense full-cell rendering**

```ts
import { test, expect } from '@playwright/test';

test('structure tile skin renders tightly without visible grid gaps inside the cell', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('button', { name: '开发者模式' }).click();
  await page.getByRole('button', { name: '地图绘制' }).click();

  await page.getByRole('button', { name: '结构层' }).click();
  await page.getByRole('button', { name: '外墙横' }).click();
  await page.getByTestId('tile-cell-1-1').click();

  await expect(page.getByTestId('tile-cell-1-1').locator('.tile-skin.tile-skin-wall-h')).toBeVisible();
});
```

- [ ] **Step 2: Run the failing E2E**

Run:

```bash
npm run test:e2e -- tests/developer-mode.spec.ts
```

Expected: FAIL because the current canvas still renders string previews instead of `.tile-skin-*` DOM nodes.

- [ ] **Step 3: Add full-cell tile skin component and tighten the grid layout**

```tsx
// TileSkin.tsx
import { getTileTopology } from '../../../domain/map-editor/tile-topology';

export function TileSkin(props: { tileId: string | null; fallbackLabel?: string }) {
  if (!props.tileId) {
    return <span className="tile-skin tile-skin-empty" aria-hidden="true" />;
  }

  const topology = getTileTopology(props.tileId);
  if (!topology) {
    if (props.tileId === 'ground-grass') {
      return <span className="tile-skin tile-skin-ground-grass" aria-hidden="true" />;
    }

    if (props.tileId === 'ground-yard') {
      return <span className="tile-skin tile-skin-ground-yard" aria-hidden="true" />;
    }

    if (props.tileId === 'art-micro-floor') {
      return <span className="tile-skin tile-skin-art-micro-floor" aria-hidden="true" />;
    }

    return <span className="tile-skin tile-skin-fallback">{props.fallbackLabel ?? '?'}</span>;
  }

  return (
    <span
      className={`tile-skin tile-skin-${topology.family.replace(/[^a-z-]/g, '')} tile-skin-${topology.orientation}`}
      data-tile-id={props.tileId}
      aria-hidden="true"
    />
  );
}
```

```tsx
// TileCanvas.tsx
import { TileSkin } from './TileSkin';

<button
  key={`${cell.x}-${cell.y}`}
  type="button"
  className="map-editor-cell"
  data-testid={`tile-cell-${cell.x}-${cell.y}`}
  onClick={() => handlePaint(cell.x, cell.y)}
  onPointerDown={() => beginStroke(cell.x, cell.y)}
  onPointerEnter={() => continueStroke(cell.x, cell.y)}
  onPointerUp={endStroke}
>
  <TileSkin tileId={resolveVisibleTileId(cell.x, cell.y)} fallbackLabel={cell.tileId ? previewLookup[cell.tileId] ?? '?' : ''} />
</button>
```

```css
/* App.css */
.map-editor-canvas {
  position: absolute;
  display: grid;
  gap: 0;
  border: 1px solid rgba(163, 132, 83, 0.35);
  background:
    linear-gradient(to right, rgba(163, 132, 83, 0.22) 1px, transparent 1px),
    linear-gradient(to bottom, rgba(163, 132, 83, 0.22) 1px, transparent 1px),
    #0f0d14;
  background-size: 30px 30px;
}

.map-editor-cell {
  width: 30px;
  height: 30px;
  padding: 0;
  border: 0;
  background: transparent;
  position: relative;
}

.tile-skin {
  position: absolute;
  inset: 0;
  display: block;
}

.tile-skin-ground-grass {
  background:
    linear-gradient(90deg, rgba(92, 107, 78, 0.55) 0 50%, rgba(79, 92, 67, 0.55) 50% 100%);
}

.tile-skin-ground-yard {
  background:
    linear-gradient(90deg, rgba(116, 90, 61, 0.58) 0 50%, rgba(98, 75, 49, 0.58) 50% 100%);
}

.tile-skin-art-micro-floor {
  background:
    linear-gradient(90deg, rgba(175, 175, 165, 0.18) 0 50%, rgba(137, 137, 129, 0.18) 50% 100%),
    linear-gradient(0deg, rgba(175, 175, 165, 0.14) 0 50%, rgba(137, 137, 129, 0.14) 50% 100%);
  background-size: 8px 8px;
}

.tile-skin-outer-wall.tile-skin-h::before,
.tile-skin-inner-wall.tile-skin-h::before,
.tile-skin-yard-wall.tile-skin-h::before,
.tile-skin-door-socket.tile-skin-h::before {
  content: '';
  position: absolute;
  left: 0;
  right: 0;
  top: 9px;
  height: 12px;
  border-top: 2px solid #f2ead3;
  border-bottom: 2px solid #f2ead3;
}

.tile-skin-outer-wall.tile-skin-v::before,
.tile-skin-inner-wall.tile-skin-v::before,
.tile-skin-yard-wall.tile-skin-v::before,
.tile-skin-door-socket.tile-skin-v::before {
  content: '';
  position: absolute;
  top: 0;
  bottom: 0;
  left: 9px;
  width: 12px;
  border-left: 2px solid #f2ead3;
  border-right: 2px solid #f2ead3;
}

.tile-skin-door-leaf.tile-skin-h {
  background: linear-gradient(90deg, #7b5b38 0 100%);
  border-top: 2px solid #f2ead3;
  border-bottom: 2px solid #f2ead3;
}

.tile-skin-door-leaf.tile-skin-v {
  background: linear-gradient(0deg, #7b5b38 0 100%);
  border-left: 2px solid #f2ead3;
  border-right: 2px solid #f2ead3;
}
```

- [ ] **Step 4: Re-run E2E and typecheck**

Run:

```bash
npm run test:e2e -- tests/developer-mode.spec.ts
npx tsc --noEmit
```

Expected: PASS. The wall and door visuals fill the cell, and the grid no longer depends on cell gaps.

- [ ] **Step 5: Commit**

```bash
git add src/presentation/react-shell/dev-mode/TileSkin.tsx src/presentation/react-shell/dev-mode/TileCanvas.tsx src/App.css tests/developer-mode.spec.ts
git commit -m "feat: render full-cell tile skins"
```

## Task 3: Add Drag Painting, Directional Straight-Wall Strokes, And Locked Layers

**Files:**
- Modify: `Project/AIRPGWeb/src/domain/map-editor/editor-reducer.ts`
- Modify: `Project/AIRPGWeb/src/domain/map-editor/editor-reducer.test.ts`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileCanvas.tsx`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/EditorLayerList.tsx`

- [ ] **Step 1: Add failing reducer tests for locked layers and deduplicated stroke painting**

```ts
import { describe, expect, it } from 'vitest';
import { createEmptyMapAsset } from './create-empty-map-asset';
import { createInitialEditorState, editorReducer } from './editor-reducer';

describe('editorReducer strokes', () => {
  it('ignores paint on locked layers and de-duplicates stroke cells', () => {
    const map = createEmptyMapAsset({ id: 'map-1', name: '草稿', width: 4, height: 4 });
    let state = createInitialEditorState(map);

    state = editorReducer(state, { type: 'toggle-layer-lock', layerId: 'structure' });
    state = editorReducer(state, {
      type: 'paint-stroke',
      layerId: 'structure',
      tileId: 'outer-wall-h',
      cells: [
        { x: 1, y: 1 },
        { x: 2, y: 1 },
        { x: 2, y: 1 },
      ],
    });

    expect(state.map.layers.find((layer) => layer.id === 'structure')?.cells[5].tileId).toBe(null);

    state = editorReducer(state, { type: 'toggle-layer-lock', layerId: 'structure' });
    state = editorReducer(state, {
      type: 'paint-stroke',
      layerId: 'structure',
      tileId: 'outer-wall-h',
      cells: [
        { x: 1, y: 1 },
        { x: 2, y: 1 },
        { x: 2, y: 1 },
      ],
    });

    expect(state.map.layers.find((layer) => layer.id === 'structure')?.cells[5].tileId).toBe('outer-wall-h');
    expect(state.map.layers.find((layer) => layer.id === 'structure')?.cells[6].tileId).toBe('outer-wall-h');
    expect(state.past).toHaveLength(2);
  });
});
```

- [ ] **Step 2: Run the failing reducer test**

Run:

```bash
npm run test -- src/domain/map-editor/editor-reducer.test.ts
```

Expected: FAIL because the reducer does not support `toggle-layer-lock` or `paint-stroke`.

- [ ] **Step 3: Implement lock-aware stroke painting and pointer drag interaction**

```ts
// editor-reducer.ts
export type EditorAction =
  | { type: 'set-layer'; layerId: EditorLayerId }
  | { type: 'set-tool'; tool: EditorTool }
  | { type: 'select-tile'; tileId: string | null }
  | { type: 'toggle-layer-lock'; layerId: EditorLayerId }
  | { type: 'rename-map'; name: string }
  | { type: 'paint-stroke'; layerId: EditorLayerId; tileId: string | null; cells: Array<{ x: number; y: number }> }
  | { type: 'replace-map'; map: MapAsset }
  | { type: 'undo' }
  | { type: 'redo' };

if (action.type === 'toggle-layer-lock') {
  const nextMap = cloneMap(state.map);
  const layer = nextMap.layers.find((item) => item.id === action.layerId);
  if (!layer) return state;
  layer.locked = !layer.locked;
  return { ...state, map: nextMap };
}

if (action.type === 'paint-stroke') {
  const nextMap = cloneMap(state.map);
  const layer = nextMap.layers.find((item) => item.id === action.layerId);
  if (!layer || layer.locked) return state;

  const uniqueKeys = new Set<string>();
  const cells = action.cells.filter((cell) => {
    const key = `${cell.x}:${cell.y}`;
    if (uniqueKeys.has(key)) return false;
    uniqueKeys.add(key);
    return true;
  });

  for (const cell of cells) {
    const index = cell.y * nextMap.width + cell.x;
    if (layer.cells[index]) {
      layer.cells[index].tileId = action.tileId;
    }
  }

  return { ...state, map: nextMap, past: [...state.past, cloneMap(state.map)], future: [] };
}
```

```tsx
// TileCanvas.tsx
const [strokeCells, setStrokeCells] = useState<Array<{ x: number; y: number }>>([]);
const [isPointerDown, setIsPointerDown] = useState(false);

function normalizeStrokeCell(x: number, y: number) {
  if (state.selectedTileId === 'outer-wall-h') {
    return { x, y: strokeCells[0]?.y ?? y };
  }

  if (state.selectedTileId === 'outer-wall-v') {
    return { x: strokeCells[0]?.x ?? x, y };
  }

  return { x, y };
}

function beginStroke(x: number, y: number) {
  const first = normalizeStrokeCell(x, y);
  setIsPointerDown(true);
  setStrokeCells([first]);
}

function continueStroke(x: number, y: number) {
  if (!isPointerDown) return;
  const next = normalizeStrokeCell(x, y);
  setStrokeCells((current) => [...current, next]);
}

function endStroke() {
  if (!isPointerDown) return;
  const tileId = state.activeTool === 'eraser' ? null : state.selectedTileId;
  dispatch({ type: 'paint-stroke', layerId: state.activeLayerId, tileId, cells: strokeCells });
  setStrokeCells([]);
  setIsPointerDown(false);
}
```

```tsx
// EditorLayerList.tsx
<div className="map-editor-layer-row" key={layer.id}>
  <button
    type="button"
    className={`map-editor-layer-button ${state.activeLayerId === layer.id ? 'active' : ''}`}
    onClick={() => dispatch({ type: 'set-layer', layerId: layer.id })}
  >
    {layer.name}
  </button>
  <button
    type="button"
    className={`map-editor-layer-lock ${layer.locked ? 'active' : ''}`}
    onClick={() => dispatch({ type: 'toggle-layer-lock', layerId: layer.id })}
  >
    {layer.locked ? '已锁' : '未锁'}
  </button>
</div>
```

- [ ] **Step 4: Re-run reducer test and editor smoke**

Run:

```bash
npm run test -- src/domain/map-editor/editor-reducer.test.ts
npm run test:e2e -- tests/developer-mode.spec.ts
```

Expected: PASS. Single click still paints one cell, pointer hold drags across cells, and locked layers reject edits.

- [ ] **Step 5: Commit**

```bash
git add src/domain/map-editor/editor-reducer.ts src/domain/map-editor/editor-reducer.test.ts src/presentation/react-shell/dev-mode/TileCanvas.tsx src/presentation/react-shell/dev-mode/EditorLayerList.tsx
git commit -m "feat: add drag painting and layer locks"
```

## Task 4: Add Map Rename, Save As, And Reopen-Friendly Metadata

**Files:**
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/EditorToolbar.tsx`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/MapEditorScreen.tsx`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/MapBrowserPanel.tsx`
- Modify: `Project/AIRPGWeb/src/persistence/repositories/map-asset-repository.ts`
- Test: `Project/AIRPGWeb/tests/developer-mode.spec.ts`

- [ ] **Step 1: Extend the E2E flow for rename and save-as**

```ts
test('editor can rename the current map and save as a new map asset', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('button', { name: '开发者模式' }).click();
  await page.getByRole('button', { name: '地图绘制' }).click();

  await page.getByLabel('地图名称').fill('铁匠铺外院');
  await page.getByRole('button', { name: '另存为' }).click();

  await expect(page.getByText('已另存为新地图')).toBeVisible();
  await expect(page.getByRole('button', { name: /铁匠铺外院/ })).toBeVisible();
});
```

- [ ] **Step 2: Run the failing E2E**

Run:

```bash
npm run test:e2e -- tests/developer-mode.spec.ts
```

Expected: FAIL because there is no map name input or save-as action yet.

- [ ] **Step 3: Implement map rename and save-as flows**

```tsx
// EditorToolbar.tsx
type EditorToolbarProps = {
  state: EditorState;
  dispatch: Dispatch<EditorAction>;
  onBack: () => void;
  onExit: () => void;
  onSave: () => void;
  onSaveAs: () => void;
  onPublish: () => void;
  statusMessage: string;
};

<label className="map-editor-name-field">
  <span>地图名称</span>
  <input
    aria-label="地图名称"
    value={state.map.name}
    onChange={(event) => dispatch({ type: 'rename-map', name: event.target.value })}
  />
</label>

<button type="button" className="menu-btn" onClick={onSaveAs}>
  另存为
</button>
```

```ts
// map-asset-repository.ts
async cloneAsNew(map: MapAsset) {
  const nextMap = {
    ...structuredClone(map),
    id: `map-${Date.now()}`,
    runtimePublished: false,
    publishedAt: null,
  };
  await db.mapAssets.put(nextMap);
  return nextMap;
}
```

```tsx
// MapEditorScreen.tsx
async function handleSaveAs() {
  const nextMap = await mapRepository.cloneAsNew(state.map);
  dispatch({ type: 'replace-map', map: nextMap });
  await refreshAssets();
  setStatusMessage('已另存为新地图');
}
```

- [ ] **Step 4: Re-run E2E and typecheck**

Run:

```bash
npm run test:e2e -- tests/developer-mode.spec.ts
npx tsc --noEmit
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/presentation/react-shell/dev-mode/EditorToolbar.tsx src/presentation/react-shell/dev-mode/MapEditorScreen.tsx src/presentation/react-shell/dev-mode/MapBrowserPanel.tsx src/persistence/repositories/map-asset-repository.ts tests/developer-mode.spec.ts
git commit -m "feat: add map rename and save as flow"
```

## Task 5: Add Snapped World Placement Dragging

**Files:**
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/WorldCompositionPanel.tsx`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/MapEditorScreen.tsx`
- Modify: `Project/AIRPGWeb/src/persistence/repositories/world-asset-repository.ts`
- Test: `Project/AIRPGWeb/tests/developer-mode.spec.ts`

- [ ] **Step 1: Add the failing E2E world-drag test**

```ts
test('world composition supports dragging a map placement with tile-grid snapping', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('button', { name: '开发者模式' }).click();
  await page.getByRole('button', { name: '地图绘制' }).click();

  const placement = page.getByTestId('world-placement-current');
  await placement.dragTo(page.getByTestId('world-grid-drop-x-24-y-0'));

  await expect(page.getByText('(24, 0)')).toBeVisible();
});
```

- [ ] **Step 2: Run the failing E2E**

Run:

```bash
npm run test:e2e -- tests/developer-mode.spec.ts
```

Expected: FAIL because world placement is currently read-only.

- [ ] **Step 3: Implement draggable placement with grid snapping**

```ts
// world-asset-repository.ts
async updatePlacement(input: { worldId: string; mapId: string; worldX: number; worldY: number }) {
  const world = await db.worldAssets.get(input.worldId);
  if (!world) return null;

  const nextWorld = structuredClone(world);
  nextWorld.placements = nextWorld.placements.map((placement) =>
    placement.mapId === input.mapId
      ? { ...placement, worldX: input.worldX, worldY: input.worldY }
      : placement,
  );

  await db.worldAssets.put(nextWorld);
  return nextWorld;
}
```

```tsx
// WorldCompositionPanel.tsx
type WorldCompositionPanelProps = {
  placements: Array<{ mapId: string; worldX: number; worldY: number; isCurrent: boolean }>;
  adjacentMapIds: string[];
  onMovePlacement: (mapId: string, worldX: number, worldY: number) => void;
};

function snap(value: number, step: number) {
  return Math.round(value / step) * step;
}

<button
  type="button"
  data-testid={placement.isCurrent ? 'world-placement-current' : `world-placement-${placement.mapId}`}
  draggable
  onDragEnd={(event) => {
    const worldX = snap(event.clientX / 10, 1);
    const worldY = snap(event.clientY / 10, 1);
    onMovePlacement(placement.mapId, worldX, worldY);
  }}
>
  {placement.mapId}
</button>
```

```tsx
// MapEditorScreen.tsx
async function handleMovePlacement(mapId: string, worldX: number, worldY: number) {
  const nextWorld = await worldRepository.updatePlacement({
    worldId: world?.id ?? 'default-world',
    mapId,
    worldX,
    worldY,
  });

  if (!nextWorld) return;
  setWorld(nextWorld);
  setStatusMessage(`已移动地图：${mapId} -> (${worldX}, ${worldY})`);
}
```

- [ ] **Step 4: Re-run E2E and typecheck**

Run:

```bash
npm run test:e2e -- tests/developer-mode.spec.ts
npx tsc --noEmit
```

Expected: PASS. Placement text updates to the snapped coordinate after dragging.

- [ ] **Step 5: Commit**

```bash
git add src/presentation/react-shell/dev-mode/WorldCompositionPanel.tsx src/presentation/react-shell/dev-mode/MapEditorScreen.tsx src/persistence/repositories/world-asset-repository.ts tests/developer-mode.spec.ts
git commit -m "feat: add snapped world placement dragging"
```

## Task 6: Add Tile Validation For Door Legality And Surface It In The Editor

**Files:**
- Create: `Project/AIRPGWeb/src/domain/map-editor/tile-validation.ts`
- Create: `Project/AIRPGWeb/src/domain/map-editor/tile-validation.test.ts`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/MapEditorScreen.tsx`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/EditorToolbar.tsx`

- [ ] **Step 1: Write the failing validation test**

```ts
import { describe, expect, it } from 'vitest';
import { createEmptyMapAsset } from './create-empty-map-asset';
import { validateMapTopology } from './tile-validation';

describe('validateMapTopology', () => {
  it('reports doors that are not placed on matching sockets', () => {
    const map = createEmptyMapAsset({ id: 'map-1', name: '民居', width: 4, height: 4 });
    map.layers.find((layer) => layer.id === 'openings')!.cells[5].tileId = 'door-leaf-h-closed';

    const result = validateMapTopology(map);

    expect(result.errors).toContainEqual(
      expect.objectContaining({
        code: 'door-socket-mismatch',
        x: 1,
        y: 1,
      }),
    );
  });
});
```

- [ ] **Step 2: Run the failing unit test**

Run:

```bash
npm run test -- src/domain/map-editor/tile-validation.test.ts
```

Expected: FAIL because validation helpers do not exist.

- [ ] **Step 3: Implement validation and show actionable messages before save/publish**

```ts
// tile-validation.ts
import type { MapAsset } from './map-editor-types';
import { getTileTopology } from './tile-topology';

export type MapValidationIssue = {
  code: 'door-socket-mismatch' | 'illegal-opening-layer';
  x: number;
  y: number;
  message: string;
};

export function validateMapTopology(map: MapAsset) {
  const errors: MapValidationIssue[] = [];
  const structure = map.layers.find((layer) => layer.id === 'structure');
  const openings = map.layers.find((layer) => layer.id === 'openings');

  if (!structure || !openings) {
    return { errors };
  }

  openings.cells.forEach((cell, index) => {
    if (!cell.tileId) return;
    const openingMeta = getTileTopology(cell.tileId);
    if (!openingMeta?.requiresSocket) return;

    const structureTileId = structure.cells[index]?.tileId ?? null;
    if (structureTileId !== openingMeta.requiresSocket) {
      errors.push({
        code: 'door-socket-mismatch',
        x: cell.x,
        y: cell.y,
        message: `门必须放在匹配的门位上：(${cell.x}, ${cell.y})`,
      });
    }
  });

  return { errors };
}
```

```tsx
// MapEditorScreen.tsx
import { validateMapTopology } from '../../../domain/map-editor/tile-validation';

async function handleSave() {
  const validation = validateMapTopology(state.map);
  if (validation.errors.length > 0) {
    setStatusMessage(validation.errors[0].message);
    return;
  }

  await mapRepository.save(state.map);
  const nextWorld = await createDefaultWorld(await mapRepository.list());
  setWorld(nextWorld);
  await refreshAssets();
  setStatusMessage('地图已保存');
}
```

```tsx
// EditorToolbar.tsx
{statusMessage ? <span className="map-editor-status" role="status">{statusMessage}</span> : null}
```

- [ ] **Step 4: Re-run validation test and full smoke**

Run:

```bash
npm run test -- src/domain/map-editor/tile-validation.test.ts
npm run test:e2e -- tests/developer-mode.spec.ts
```

Expected: PASS. Illegal door placement is blocked with a readable message.

- [ ] **Step 5: Commit**

```bash
git add src/domain/map-editor/tile-validation.ts src/domain/map-editor/tile-validation.test.ts src/presentation/react-shell/dev-mode/MapEditorScreen.tsx src/presentation/react-shell/dev-mode/EditorToolbar.tsx
git commit -m "feat: validate door and socket topology"
```

## Task 7: Final Verification And Docs Sync

**Files:**
- Modify: `Project/AIRPGWeb/tests/developer-mode.spec.ts`
- Modify: `Project/AIRPGWeb/src/App.css`
- Review: `Docs/superpowers/specs/2026-05-31-airpgweb-ingame-tile-map-editor-design.md`

- [ ] **Step 1: Add a high-level E2E flow for the refined topology editor**

```ts
test('refined topology editor supports wall drag, locked layers, save-as, and publish', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('button', { name: '开发者模式' }).click();
  await page.getByRole('button', { name: '地图绘制' }).click();

  await page.getByRole('button', { name: '结构层' }).click();
  await page.getByRole('button', { name: '外墙横' }).click();
  await page.getByTestId('tile-cell-1-1').hover();
  await page.mouse.down();
  await page.getByTestId('tile-cell-4-1').hover();
  await page.mouse.up();

  await page.getByRole('button', { name: '已锁' }).click();
  await page.getByRole('button', { name: '另存为' }).click();
  await page.getByRole('button', { name: '设为运行时地图' }).click();

  await expect(page.getByText('运行时地图已更新')).toBeVisible();
});
```

- [ ] **Step 2: Run the full verification suite**

Run:

```bash
npm run test
npm run test:e2e
npm run build
```

Expected:

- Vitest PASS
- Playwright PASS
- Vite build PASS

- [ ] **Step 3: Fix CSS or test selector drift discovered during verification**

```css
.map-editor-layer-row {
  display: grid;
  grid-template-columns: 1fr auto;
  gap: 8px;
}

.map-editor-layer-lock.active {
  background: rgba(204, 167, 96, 0.22);
  color: #f2ead3;
}

.map-editor-name-field {
  display: grid;
  gap: 4px;
}
```

- [ ] **Step 4: Sync the spec if any final implementation name drift occurred**

```md
- Confirm these names still match the implementation:
  - `TileSkin`
  - `tile-topology`
  - `tile-validation`
  - `door-socket-h`
  - `door-leaf-h-closed`
- If any name drift happened during implementation, update the spec immediately after tests pass.
```

- [ ] **Step 5: Commit**

```bash
git add tests/developer-mode.spec.ts src/App.css Docs/superpowers/specs/2026-05-31-airpgweb-ingame-tile-map-editor-design.md
git commit -m "test: verify refined tile topology editor flow"
```

## Self-Review

### Spec Coverage

- 手工精确拓扑模式：Task 1
- 整格铺满与 DOM/CSS Tile Skin：Task 2
- 单击/长按拖刷、方向约束、锁层：Task 3
- 命名、另存为、回编友好：Task 4
- 世界布局拖拽与吸附：Task 5
- 门位合法性校验：Task 6
- 全量回归与文档同步：Task 7

### Placeholder Scan

- 本计划没有使用 `TODO`、`TBD`、`以后再补` 之类的占位措辞
- 每个任务都包含明确文件、测试、命令和提交建议
- 第二批功能如矩形、填充、吸管没有混入本计划，避免范围漂移

### Type Consistency

- 结构与开口 tile id 统一使用不带层前缀的家族命名：`outer-wall-*`、`door-socket-*`、`door-leaf-*`
- `TileSkin` 始终消费 `tile-topology` 元数据，不再让 `TileCanvas` 自己拼字符
- 合法性校验统一走 `validateMapTopology()`
- 世界拖拽改动只更新 `WorldAsset.placements`，不直接修改 `MapAsset`
