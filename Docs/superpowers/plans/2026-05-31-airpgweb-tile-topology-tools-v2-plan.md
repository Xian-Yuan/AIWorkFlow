# AIRPGWeb Tile Topology And Drawing Tools V2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the existing ingame tile editor with complete topology skins for walls and doors plus baseline rectangle, fill, and picker tools so house layouts can be drawn faster without leaving hand-authored topology mode.

**Architecture:** Keep the current React shell, reducer-driven editor state, and `TileSkin` rendering path. Add focused domain helpers for rectangle geometry, fill traversal, and tool legality checks, then let `TileCanvas` switch between stroke, rectangle, fill, and picker behaviors while `TileSkin` expands to cover the remaining topology family variants.

**Tech Stack:** React 19, TypeScript, Dexie, Vitest, Playwright, Vite

---

## File Map

### New Files

- `Project/AIRPGWeb/src/domain/map-editor/rectangle-tool.ts`
- `Project/AIRPGWeb/src/domain/map-editor/rectangle-tool.test.ts`
- `Project/AIRPGWeb/src/domain/map-editor/fill-tool.ts`
- `Project/AIRPGWeb/src/domain/map-editor/fill-tool.test.ts`
- `Project/AIRPGWeb/src/domain/map-editor/tool-guards.ts`
- `Project/AIRPGWeb/src/domain/map-editor/tool-guards.test.ts`

### Modified Files

- `Project/AIRPGWeb/src/domain/map-editor/tile-topology.ts`
- `Project/AIRPGWeb/src/domain/map-editor/editor-reducer.ts`
- `Project/AIRPGWeb/src/domain/map-editor/editor-reducer.test.ts`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileSkin.tsx`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileCanvas.tsx`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/EditorToolbar.tsx`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/MapEditorScreen.tsx`
- `Project/AIRPGWeb/src/App.css`
- `Project/AIRPGWeb/tests/developer-mode.spec.ts`

### Responsibility Split

- `tile-topology.ts`: expand authoritative topology metadata to include `end-*`, `t-*`, `cross`, and all door open/closed variants
- `rectangle-tool.ts`: pure coordinate generation for `rectangle-outline` and `rectangle-fill`
- `fill-tool.ts`: pure flood-fill traversal scoped to one layer
- `tool-guards.ts`: reject illegal tool/tile combinations with readable messages
- `editor-reducer.ts`: add new tools, rectangle preview state, fill application, and picker selection events
- `TileSkin.tsx`: render all missing topology skins as full-cell DOM/CSS
- `TileCanvas.tsx`: dispatch tool-specific interactions for brush, rectangle, fill, and picker
- `EditorToolbar.tsx`: expose the new tools in the top toolbar
- `MapEditorScreen.tsx`: wire legality messages into the status area and preserve existing save/publish validation

## Task 1: Expand Topology Metadata And Skin Variants

**Files:**
- Modify: `Project/AIRPGWeb/src/domain/map-editor/tile-topology.ts`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileSkin.tsx`
- Modify: `Project/AIRPGWeb/src/App.css`
- Test: `Project/AIRPGWeb/tests/developer-mode.spec.ts`

- [ ] **Step 1: Extend the Playwright skin test to require a visible corner skin**

```ts
import { expect, test } from '@playwright/test';

test('structure palette can paint a corner skin with full-cell rendering', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('button', { name: '开发者模式' }).click();
  await page.getByRole('button', { name: '地图绘制' }).click();

  await page.getByRole('button', { name: '结构层', exact: true }).click();
  await page.getByRole('button', { name: '外墙左上角' }).click();
  await page.getByTestId('tile-cell-2-2').click();

  await expect(
    page.getByTestId('tile-cell-2-2').locator('.tile-skin.tile-skin-outer-corner.tile-skin-tl'),
  ).toBeVisible();
});
```

- [ ] **Step 2: Run the failing E2E**

Run:

```bash
npm run test:e2e -- tests/developer-mode.spec.ts
```

Expected: FAIL because the current palette/skin set does not expose all corner, T, cross, end, and door open/closed variants.

- [ ] **Step 3: Add missing topology variants and render classes**

```ts
// tile-topology.ts
const topologyTiles: TileTopologyMeta[] = [
  { tileId: 'outer-wall-h', layerId: 'structure', family: 'outer-wall', orientation: 'h', previewLabel: '外墙横', blocksMovement: true },
  { tileId: 'outer-wall-v', layerId: 'structure', family: 'outer-wall', orientation: 'v', previewLabel: '外墙竖', blocksMovement: true },
  { tileId: 'outer-corner-tl', layerId: 'structure', family: 'outer-corner', orientation: 'tl', previewLabel: '外墙左上角', blocksMovement: true },
  { tileId: 'outer-corner-tr', layerId: 'structure', family: 'outer-corner', orientation: 'tr', previewLabel: '外墙右上角', blocksMovement: true },
  { tileId: 'outer-corner-bl', layerId: 'structure', family: 'outer-corner', orientation: 'bl', previewLabel: '外墙左下角', blocksMovement: true },
  { tileId: 'outer-corner-br', layerId: 'structure', family: 'outer-corner', orientation: 'br', previewLabel: '外墙右下角', blocksMovement: true },
  { tileId: 'outer-t-up', layerId: 'structure', family: 'outer-t', orientation: 't-up', previewLabel: '外墙T上', blocksMovement: true },
  { tileId: 'outer-t-right', layerId: 'structure', family: 'outer-t', orientation: 't-right', previewLabel: '外墙T右', blocksMovement: true },
  { tileId: 'outer-t-down', layerId: 'structure', family: 'outer-t', orientation: 't-down', previewLabel: '外墙T下', blocksMovement: true },
  { tileId: 'outer-t-left', layerId: 'structure', family: 'outer-t', orientation: 't-left', previewLabel: '外墙T左', blocksMovement: true },
  { tileId: 'outer-cross', layerId: 'structure', family: 'outer-cross', orientation: 'cross', previewLabel: '外墙十字', blocksMovement: true },
  { tileId: 'outer-end-up', layerId: 'structure', family: 'wall-end', orientation: 't-up', previewLabel: '外墙端头上', blocksMovement: true },
  { tileId: 'outer-end-right', layerId: 'structure', family: 'wall-end', orientation: 't-right', previewLabel: '外墙端头右', blocksMovement: true },
  { tileId: 'outer-end-down', layerId: 'structure', family: 'wall-end', orientation: 't-down', previewLabel: '外墙端头下', blocksMovement: true },
  { tileId: 'outer-end-left', layerId: 'structure', family: 'wall-end', orientation: 't-left', previewLabel: '外墙端头左', blocksMovement: true },
  { tileId: 'door-leaf-h-open', layerId: 'openings', family: 'door-leaf', orientation: 'h', previewLabel: '横门开', blocksMovement: false, requiresSocket: 'door-socket-h' },
  { tileId: 'door-leaf-h-closed', layerId: 'openings', family: 'door-leaf', orientation: 'h', previewLabel: '横门关', blocksMovement: true, requiresSocket: 'door-socket-h' },
  { tileId: 'door-leaf-v-open', layerId: 'openings', family: 'door-leaf', orientation: 'v', previewLabel: '竖门开', blocksMovement: false, requiresSocket: 'door-socket-v' },
  { tileId: 'door-leaf-v-closed', layerId: 'openings', family: 'door-leaf', orientation: 'v', previewLabel: '竖门关', blocksMovement: true, requiresSocket: 'door-socket-v' },
];
```

```tsx
// TileSkin.tsx
const topology = getTileTopology(tileId);

return (
  <span
    className={`tile-skin tile-skin-${topology.family} tile-skin-${topology.orientation}`}
    data-tile-id={tileId}
    aria-hidden="true"
  />
);
```

```css
/* App.css */
.tile-skin-outer-corner.tile-skin-tl::before,
.tile-skin-inner-corner.tile-skin-tl::before {
  content: '';
  position: absolute;
  inset: 0;
  border-top: 2px solid #f2ead3;
  border-left: 2px solid #f2ead3;
}

.tile-skin-outer-corner.tile-skin-tr::before,
.tile-skin-inner-corner.tile-skin-tr::before {
  content: '';
  position: absolute;
  inset: 0;
  border-top: 2px solid #f2ead3;
  border-right: 2px solid #f2ead3;
}

.tile-skin-outer-cross.tile-skin-cross::before,
.tile-skin-inner-cross.tile-skin-cross::before {
  content: '';
  position: absolute;
  inset: 0;
  background:
    linear-gradient(to right, transparent 0 8px, #f2ead3 8px 10px, transparent 10px 20px, #f2ead3 20px 22px, transparent 22px 100%),
    linear-gradient(to bottom, transparent 0 8px, #f2ead3 8px 10px, transparent 10px 20px, #f2ead3 20px 22px, transparent 22px 100%);
}

.tile-skin-wall-end.tile-skin-t-up::before {
  content: '';
  position: absolute;
  left: 8px;
  right: 8px;
  top: 0;
  bottom: 8px;
  border-left: 2px solid #f2ead3;
  border-right: 2px solid #f2ead3;
}

.tile-skin-door-leaf.tile-skin-h[data-tile-id='door-leaf-h-open'] {
  background:
    linear-gradient(90deg, rgba(117, 84, 51, 0.9) 0 52%, transparent 52% 100%);
  border-top: 2px solid #f2ead3;
  border-bottom: 2px solid #f2ead3;
}

.tile-skin-door-leaf.tile-skin-v[data-tile-id='door-leaf-v-open'] {
  background:
    linear-gradient(0deg, rgba(117, 84, 51, 0.9) 0 52%, transparent 52% 100%);
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

Expected: PASS. The editor now renders corner and door open/closed variants as full-cell skins.

- [ ] **Step 5: Commit**

```bash
git add src/domain/map-editor/tile-topology.ts src/presentation/react-shell/dev-mode/TileSkin.tsx src/App.css tests/developer-mode.spec.ts
git commit -m "feat: expand tile topology skins"
```

## Task 2: Add Rectangle Geometry Helpers For Outline And Fill Modes

**Files:**
- Create: `Project/AIRPGWeb/src/domain/map-editor/rectangle-tool.ts`
- Create: `Project/AIRPGWeb/src/domain/map-editor/rectangle-tool.test.ts`

- [ ] **Step 1: Write failing unit tests for rectangle geometry**

```ts
import { describe, expect, it } from 'vitest';
import { buildOutlineRectangleCells, buildFilledRectangleCells } from './rectangle-tool';

describe('rectangle-tool', () => {
  it('builds only border cells for outline mode', () => {
    expect(buildOutlineRectangleCells({ x: 1, y: 1 }, { x: 3, y: 3 })).toEqual([
      { x: 1, y: 1 }, { x: 2, y: 1 }, { x: 3, y: 1 },
      { x: 1, y: 2 }, { x: 3, y: 2 },
      { x: 1, y: 3 }, { x: 2, y: 3 }, { x: 3, y: 3 },
    ]);
  });

  it('builds every cell for filled mode', () => {
    expect(buildFilledRectangleCells({ x: 1, y: 1 }, { x: 2, y: 2 })).toEqual([
      { x: 1, y: 1 }, { x: 2, y: 1 },
      { x: 1, y: 2 }, { x: 2, y: 2 },
    ]);
  });
});
```

- [ ] **Step 2: Run the failing unit tests**

Run:

```bash
npm run test -- src/domain/map-editor/rectangle-tool.test.ts
```

Expected: FAIL because the rectangle helper file does not exist.

- [ ] **Step 3: Implement pure rectangle geometry helpers**

```ts
// rectangle-tool.ts
type Point = { x: number; y: number };

function normalizeRectangle(a: Point, b: Point) {
  return {
    minX: Math.min(a.x, b.x),
    maxX: Math.max(a.x, b.x),
    minY: Math.min(a.y, b.y),
    maxY: Math.max(a.y, b.y),
  };
}

export function buildOutlineRectangleCells(a: Point, b: Point) {
  const bounds = normalizeRectangle(a, b);
  const result: Point[] = [];

  for (let y = bounds.minY; y <= bounds.maxY; y += 1) {
    for (let x = bounds.minX; x <= bounds.maxX; x += 1) {
      const isEdge =
        x === bounds.minX ||
        x === bounds.maxX ||
        y === bounds.minY ||
        y === bounds.maxY;
      if (isEdge) {
        result.push({ x, y });
      }
    }
  }

  return result;
}

export function buildFilledRectangleCells(a: Point, b: Point) {
  const bounds = normalizeRectangle(a, b);
  const result: Point[] = [];

  for (let y = bounds.minY; y <= bounds.maxY; y += 1) {
    for (let x = bounds.minX; x <= bounds.maxX; x += 1) {
      result.push({ x, y });
    }
  }

  return result;
}
```

- [ ] **Step 4: Re-run the rectangle tests**

Run:

```bash
npm run test -- src/domain/map-editor/rectangle-tool.test.ts
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/domain/map-editor/rectangle-tool.ts src/domain/map-editor/rectangle-tool.test.ts
git commit -m "feat: add rectangle geometry helpers"
```

## Task 3: Add Fill Traversal And Tool Legality Guards

**Files:**
- Create: `Project/AIRPGWeb/src/domain/map-editor/fill-tool.ts`
- Create: `Project/AIRPGWeb/src/domain/map-editor/fill-tool.test.ts`
- Create: `Project/AIRPGWeb/src/domain/map-editor/tool-guards.ts`
- Create: `Project/AIRPGWeb/src/domain/map-editor/tool-guards.test.ts`

- [ ] **Step 1: Write failing tests for fill traversal and illegal tool combinations**

```ts
import { describe, expect, it } from 'vitest';
import { createEmptyMapAsset } from './create-empty-map-asset';
import { collectFloodFillCells } from './fill-tool';
import { getToolGuardError } from './tool-guards';

describe('fill-tool', () => {
  it('returns only contiguous cells with the same tile id on one layer', () => {
    const map = createEmptyMapAsset({ id: 'map-1', name: '草稿', width: 4, height: 4 });
    const layer = map.layers.find((item) => item.id === 'ground')!;
    layer.cells[0].tileId = 'ground-yard';
    layer.cells[1].tileId = 'ground-yard';
    layer.cells[4].tileId = 'ground-yard';
    layer.cells[15].tileId = 'ground-yard';

    expect(collectFloodFillCells(map, 'ground', 0, 0)).toEqual([
      { x: 0, y: 0 },
      { x: 1, y: 0 },
      { x: 0, y: 1 },
    ]);
  });
});

describe('tool guards', () => {
  it('blocks rectangle tools for door leaves', () => {
    expect(getToolGuardError('rectangle-outline', 'door-leaf-h-closed')).toBe('当前 tile 不适合边框矩形');
  });
});
```

- [ ] **Step 2: Run the failing tests**

Run:

```bash
npm run test -- src/domain/map-editor/fill-tool.test.ts src/domain/map-editor/tool-guards.test.ts
```

Expected: FAIL because the helper files do not exist yet.

- [ ] **Step 3: Implement flood fill and tool guards**

```ts
// fill-tool.ts
import type { EditorLayerId, MapAsset } from './map-editor-types';

export function collectFloodFillCells(map: MapAsset, layerId: EditorLayerId, startX: number, startY: number) {
  const layer = map.layers.find((item) => item.id === layerId);
  if (!layer) return [];

  const width = map.width;
  const startIndex = startY * width + startX;
  const startTileId = layer.cells[startIndex]?.tileId ?? null;
  const queue = [{ x: startX, y: startY }];
  const visited = new Set<string>();
  const result: Array<{ x: number; y: number }> = [];

  while (queue.length > 0) {
    const current = queue.shift()!;
    const key = `${current.x}:${current.y}`;
    if (visited.has(key)) continue;
    visited.add(key);

    const index = current.y * width + current.x;
    const tileId = layer.cells[index]?.tileId ?? null;
    if (tileId !== startTileId) continue;

    result.push(current);

    [
      { x: current.x + 1, y: current.y },
      { x: current.x - 1, y: current.y },
      { x: current.x, y: current.y + 1 },
      { x: current.x, y: current.y - 1 },
    ]
      .filter((point) => point.x >= 0 && point.x < map.width && point.y >= 0 && point.y < map.height)
      .forEach((point) => queue.push(point));
  }

  return result;
}
```

```ts
// tool-guards.ts
export type EnhancedEditorTool =
  | 'brush'
  | 'eraser'
  | 'picker'
  | 'fill'
  | 'rectangle-outline'
  | 'rectangle-fill';

export function getToolGuardError(tool: EnhancedEditorTool, tileId: string | null) {
  if (!tileId) return null;

  const isDoorLeaf = tileId.startsWith('door-leaf');
  const isCornerLike =
    tileId.includes('corner') ||
    tileId.includes('-t-') ||
    tileId.includes('cross') ||
    tileId.includes('end');

  if (tool === 'rectangle-outline' && (isDoorLeaf || isCornerLike)) {
    return '当前 tile 不适合边框矩形';
  }

  if (tool === 'rectangle-fill' && (isDoorLeaf || isCornerLike)) {
    return '当前 tile 不适合填充矩形';
  }

  if (tool === 'fill' && (isDoorLeaf || isCornerLike)) {
    return '当前 tile 不适合填充';
  }

  return null;
}
```

- [ ] **Step 4: Re-run helper tests**

Run:

```bash
npm run test -- src/domain/map-editor/fill-tool.test.ts src/domain/map-editor/tool-guards.test.ts
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/domain/map-editor/fill-tool.ts src/domain/map-editor/fill-tool.test.ts src/domain/map-editor/tool-guards.ts src/domain/map-editor/tool-guards.test.ts
git commit -m "feat: add fill traversal and tool guards"
```

## Task 4: Extend Reducer State For Picker, Fill, And Rectangle Tools

**Files:**
- Modify: `Project/AIRPGWeb/src/domain/map-editor/editor-reducer.ts`
- Modify: `Project/AIRPGWeb/src/domain/map-editor/editor-reducer.test.ts`

- [ ] **Step 1: Write failing reducer tests for rectangle preview, fill, and picker**

```ts
import { describe, expect, it } from 'vitest';
import { createEmptyMapAsset } from './create-empty-map-asset';
import { createInitialEditorState, editorReducer } from './editor-reducer';

describe('editorReducer advanced tools', () => {
  it('stores rectangle preview points and applies a fill selection', () => {
    const map = createEmptyMapAsset({ id: 'map-1', name: '草稿', width: 4, height: 4 });
    map.layers.find((layer) => layer.id === 'ground')!.cells[0].tileId = 'ground-yard';
    map.layers.find((layer) => layer.id === 'ground')!.cells[1].tileId = 'ground-yard';

    let state = createInitialEditorState(map);
    state = editorReducer(state, { type: 'set-tool', tool: 'rectangle-outline' });
    state = editorReducer(state, { type: 'set-rectangle-anchor', x: 1, y: 1 });
    state = editorReducer(state, { type: 'set-rectangle-hover', x: 3, y: 2 });

    expect(state.rectanglePreview).toEqual({
      anchor: { x: 1, y: 1 },
      hover: { x: 3, y: 2 },
      mode: 'rectangle-outline',
    });

    state = editorReducer(state, {
      type: 'apply-fill-cells',
      layerId: 'ground',
      tileId: 'ground-grass',
      cells: [{ x: 0, y: 0 }, { x: 1, y: 0 }],
    });

    expect(state.map.layers.find((layer) => layer.id === 'ground')?.cells[0].tileId).toBe('ground-grass');
    expect(state.map.layers.find((layer) => layer.id === 'ground')?.cells[1].tileId).toBe('ground-grass');

    state = editorReducer(state, { type: 'pick-tile', layerId: 'ground', x: 0, y: 0 });
    expect(state.selectedTileId).toBe('ground-grass');
  });
});
```

- [ ] **Step 2: Run the failing reducer tests**

Run:

```bash
npm run test -- src/domain/map-editor/editor-reducer.test.ts
```

Expected: FAIL because the reducer does not yet support the new tool actions and preview state.

- [ ] **Step 3: Add new tool state and actions**

```ts
// editor-reducer.ts
export type EditorTool =
  | 'brush'
  | 'eraser'
  | 'picker'
  | 'fill'
  | 'rectangle-outline'
  | 'rectangle-fill';

export type RectanglePreview = {
  anchor: { x: number; y: number };
  hover: { x: number; y: number };
  mode: 'rectangle-outline' | 'rectangle-fill';
} | null;

export type EditorState = {
  map: MapAsset;
  activeLayerId: EditorLayerId;
  activeTool: EditorTool;
  selectedTileId: string | null;
  rectanglePreview: RectanglePreview;
  past: MapAsset[];
  future: MapAsset[];
};

export type EditorAction =
  | { type: 'set-tool'; tool: EditorTool }
  | { type: 'set-rectangle-anchor'; x: number; y: number }
  | { type: 'set-rectangle-hover'; x: number; y: number }
  | { type: 'clear-rectangle-preview' }
  | { type: 'apply-fill-cells'; layerId: EditorLayerId; tileId: string | null; cells: Array<{ x: number; y: number }> }
  | { type: 'pick-tile'; layerId: EditorLayerId; x: number; y: number }
  // existing actions...

if (action.type === 'set-tool') {
  return {
    ...state,
    activeTool: action.tool,
    rectanglePreview: action.tool === 'rectangle-outline' || action.tool === 'rectangle-fill'
      ? state.rectanglePreview
      : null,
  };
}

if (action.type === 'set-rectangle-anchor') {
  if (state.activeTool !== 'rectangle-outline' && state.activeTool !== 'rectangle-fill') {
    return state;
  }
  return {
    ...state,
    rectanglePreview: {
      anchor: { x: action.x, y: action.y },
      hover: { x: action.x, y: action.y },
      mode: state.activeTool,
    },
  };
}

if (action.type === 'set-rectangle-hover' && state.rectanglePreview) {
  return {
    ...state,
    rectanglePreview: {
      ...state.rectanglePreview,
      hover: { x: action.x, y: action.y },
    },
  };
}

if (action.type === 'clear-rectangle-preview') {
  return { ...state, rectanglePreview: null };
}

if (action.type === 'apply-fill-cells') {
  const nextMap = cloneMap(state.map);
  const layer = nextMap.layers.find((item) => item.id === action.layerId);
  if (!layer || layer.locked) return state;

  for (const cell of action.cells) {
    const index = cell.y * nextMap.width + cell.x;
    if (layer.cells[index]) {
      layer.cells[index].tileId = action.tileId;
    }
  }

  return {
    ...state,
    map: nextMap,
    rectanglePreview: null,
    past: [...state.past, cloneMap(state.map)],
    future: [],
  };
}

if (action.type === 'pick-tile') {
  const layer = state.map.layers.find((item) => item.id === action.layerId);
  if (!layer) return state;
  const index = action.y * state.map.width + action.x;
  return {
    ...state,
    selectedTileId: layer.cells[index]?.tileId ?? null,
  };
}
```

- [ ] **Step 4: Re-run the reducer tests**

Run:

```bash
npm run test -- src/domain/map-editor/editor-reducer.test.ts
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/domain/map-editor/editor-reducer.ts src/domain/map-editor/editor-reducer.test.ts
git commit -m "feat: add reducer support for rectangle fill and picker tools"
```

## Task 5: Wire Canvas Interaction For Picker, Fill, And Both Rectangle Modes

**Files:**
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileCanvas.tsx`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/MapEditorScreen.tsx`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/EditorToolbar.tsx`
- Modify: `Project/AIRPGWeb/src/App.css`
- Test: `Project/AIRPGWeb/tests/developer-mode.spec.ts`

- [ ] **Step 1: Add failing E2E coverage for the new tools**

```ts
test('editor supports rectangle outline, rectangle fill, fill, and picker tools', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('button', { name: '开发者模式' }).click();
  await page.getByRole('button', { name: '地图绘制' }).click();

  await page.getByRole('button', { name: '边框矩形' }).click();
  await page.getByRole('button', { name: '草地' }).click();
  await page.getByTestId('tile-cell-1-1').hover();
  await page.mouse.down();
  await page.getByTestId('tile-cell-3-3').hover();
  await page.mouse.up();

  await page.getByRole('button', { name: '填充矩形' }).click();
  await page.getByRole('button', { name: '院地' }).click();
  await page.getByTestId('tile-cell-5-5').hover();
  await page.mouse.down();
  await page.getByTestId('tile-cell-6-6').hover();
  await page.mouse.up();

  await page.getByRole('button', { name: '吸管' }).click();
  await page.getByTestId('tile-cell-5-5').click();
  await expect(page.getByRole('button', { name: '院地' })).toHaveClass(/active/);
});
```

- [ ] **Step 2: Run the failing E2E**

Run:

```bash
npm run test:e2e -- tests/developer-mode.spec.ts
```

Expected: FAIL because the toolbar and canvas do not yet implement these tool flows.

- [ ] **Step 3: Wire canvas interaction to geometry, fill, and picker helpers**

```tsx
// EditorToolbar.tsx
<button
  type="button"
  className={`menu-btn ${state.activeTool === 'picker' ? 'primary' : ''}`}
  onClick={() => dispatch({ type: 'set-tool', tool: 'picker' })}
>
  吸管
</button>
<button
  type="button"
  className={`menu-btn ${state.activeTool === 'fill' ? 'primary' : ''}`}
  onClick={() => dispatch({ type: 'set-tool', tool: 'fill' })}
>
  填充
</button>
<button
  type="button"
  className={`menu-btn ${state.activeTool === 'rectangle-outline' ? 'primary' : ''}`}
  onClick={() => dispatch({ type: 'set-tool', tool: 'rectangle-outline' })}
>
  边框矩形
</button>
<button
  type="button"
  className={`menu-btn ${state.activeTool === 'rectangle-fill' ? 'primary' : ''}`}
  onClick={() => dispatch({ type: 'set-tool', tool: 'rectangle-fill' })}
>
  填充矩形
</button>
```

```tsx
// TileCanvas.tsx
import { buildFilledRectangleCells, buildOutlineRectangleCells } from '../../../domain/map-editor/rectangle-tool';
import { collectFloodFillCells } from '../../../domain/map-editor/fill-tool';

function handleCellPointerDown(x: number, y: number) {
  if (state.activeTool === 'picker') {
    dispatch({ type: 'pick-tile', layerId: state.activeLayerId, x, y });
    return;
  }

  if (state.activeTool === 'fill') {
    const cells = collectFloodFillCells(state.map, state.activeLayerId, x, y);
    dispatch({ type: 'apply-fill-cells', layerId: state.activeLayerId, tileId: state.selectedTileId, cells });
    return;
  }

  if (state.activeTool === 'rectangle-outline' || state.activeTool === 'rectangle-fill') {
    dispatch({ type: 'set-rectangle-anchor', x, y });
    return;
  }

  beginStroke(x, y);
}

function handleCellPointerEnter(x: number, y: number) {
  if (state.rectanglePreview) {
    dispatch({ type: 'set-rectangle-hover', x, y });
    return;
  }

  continueStroke(x, y);
}

function endInteraction() {
  if (state.rectanglePreview) {
    const cells =
      state.rectanglePreview.mode === 'rectangle-outline'
        ? buildOutlineRectangleCells(state.rectanglePreview.anchor, state.rectanglePreview.hover)
        : buildFilledRectangleCells(state.rectanglePreview.anchor, state.rectanglePreview.hover);

    dispatch({
      type: 'apply-fill-cells',
      layerId: state.activeLayerId,
      tileId: state.selectedTileId,
      cells,
    });
    return;
  }

  endStroke();
}
```

```css
/* App.css */
.map-editor-rectangle-preview {
  position: absolute;
  border: 1px dashed rgba(208, 168, 83, 0.9);
  background: rgba(208, 168, 83, 0.12);
  pointer-events: none;
}
```

- [ ] **Step 4: Re-run E2E and typecheck**

Run:

```bash
npm run test:e2e -- tests/developer-mode.spec.ts
npx tsc --noEmit
```

Expected: PASS. The new tools can be selected and used from the canvas.

- [ ] **Step 5: Commit**

```bash
git add src/presentation/react-shell/dev-mode/TileCanvas.tsx src/presentation/react-shell/dev-mode/MapEditorScreen.tsx src/presentation/react-shell/dev-mode/EditorToolbar.tsx src/App.css tests/developer-mode.spec.ts
git commit -m "feat: add rectangle fill and picker interactions"
```

## Task 6: Surface Tool Legality Messages And Preserve Save Flow

**Files:**
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/MapEditorScreen.tsx`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileCanvas.tsx`
- Modify: `Project/AIRPGWeb/tests/developer-mode.spec.ts`

- [ ] **Step 1: Add a failing E2E for illegal tool/tile combinations**

```ts
test('editor blocks illegal rectangle and fill tool combinations with a readable status', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('button', { name: '开发者模式' }).click();
  await page.getByRole('button', { name: '地图绘制' }).click();

  await page.getByRole('button', { name: '结构层', exact: true }).click();
  await page.getByRole('button', { name: '外墙左上角' }).click();
  await page.getByRole('button', { name: '边框矩形' }).click();
  await page.getByTestId('tile-cell-1-1').click();

  await expect(page.getByText('当前 tile 不适合边框矩形')).toBeVisible();
});
```

- [ ] **Step 2: Run the failing E2E**

Run:

```bash
npm run test:e2e -- tests/developer-mode.spec.ts
```

Expected: FAIL because the UI currently has no legality message path for the new tools.

- [ ] **Step 3: Use tool guards before dispatching canvas actions**

```tsx
// MapEditorScreen.tsx
import { getToolGuardError } from '../../../domain/map-editor/tool-guards';

function handleToolBlocked(message: string) {
  setStatusMessage(message);
}

<TileCanvas
  state={state}
  dispatch={dispatch}
  ghostMaps={ghostMaps}
  onToolBlocked={handleToolBlocked}
/>
```

```tsx
// TileCanvas.tsx
import { getToolGuardError } from '../../../domain/map-editor/tool-guards';

type TileCanvasProps = {
  state: EditorState;
  dispatch: Dispatch<EditorAction>;
  ghostMaps?: GhostMap[];
  onToolBlocked?: (message: string) => void;
};

function ensureToolAllowed() {
  const error = getToolGuardError(state.activeTool, state.selectedTileId);
  if (!error) return true;
  onToolBlocked?.(error);
  return false;
}

if ((state.activeTool === 'fill' || state.activeTool === 'rectangle-outline' || state.activeTool === 'rectangle-fill') && !ensureToolAllowed()) {
  return;
}
```

- [ ] **Step 4: Re-run E2E and smoke regression**

Run:

```bash
npm run test:e2e -- tests/developer-mode.spec.ts
```

Expected: PASS. Illegal tool/tile combinations surface readable Chinese status messages instead of silently painting.

- [ ] **Step 5: Commit**

```bash
git add src/presentation/react-shell/dev-mode/MapEditorScreen.tsx src/presentation/react-shell/dev-mode/TileCanvas.tsx tests/developer-mode.spec.ts
git commit -m "feat: guard illegal topology tool combinations"
```

## Task 7: Full Verification And Spec Name Sync

**Files:**
- Modify: `Project/AIRPGWeb/tests/developer-mode.spec.ts`
- Review: `Docs/superpowers/specs/2026-05-31-airpgweb-tile-topology-tools-v2-design.md`

- [ ] **Step 1: Add a top-level editor flow test covering the new tool set**

```ts
test('v2 editor flow supports topology skins, rectangle tools, fill, picker, and save', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('button', { name: '开发者模式' }).click();
  await page.getByRole('button', { name: '地图绘制' }).click();

  await page.getByRole('button', { name: '结构层', exact: true }).click();
  await page.getByRole('button', { name: '外墙左上角' }).click();
  await page.getByTestId('tile-cell-2-2').click();

  await page.getByRole('button', { name: '边框矩形' }).click();
  await page.getByRole('button', { name: '草地' }).click();
  await page.getByTestId('tile-cell-4-4').hover();
  await page.mouse.down();
  await page.getByTestId('tile-cell-6-6').hover();
  await page.mouse.up();

  await page.getByRole('button', { name: '吸管' }).click();
  await page.getByTestId('tile-cell-4-4').click();
  await page.getByRole('button', { name: '保存' }).click();

  await expect(page.getByText('地图已保存')).toBeVisible();
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

- [ ] **Step 3: Fix selector drift or CSS polish issues discovered during verification**

```css
.tile-skin-outer-t.tile-skin-t-up::before {
  content: '';
  position: absolute;
  inset: 0;
  background:
    linear-gradient(to right, transparent 0 8px, #f2ead3 8px 10px, transparent 10px 20px, #f2ead3 20px 22px, transparent 22px 100%),
    linear-gradient(to bottom, transparent 0 8px, #f2ead3 8px 10px, #f2ead3 10px 22px, transparent 22px 100%);
}

.map-editor-status {
  min-height: 20px;
}
```

- [ ] **Step 4: Sync the spec if implementation names drifted**

```md
- Confirm the final implementation still uses:
  - `rectangle-outline`
  - `rectangle-fill`
  - `fill`
  - `picker`
  - `door-leaf-h-open`
  - `outer-end-up`
- If any name drift occurred, update the V2 spec immediately after tests pass.
```

- [ ] **Step 5: Commit**

```bash
git add tests/developer-mode.spec.ts Docs/superpowers/specs/2026-05-31-airpgweb-tile-topology-tools-v2-design.md
git commit -m "test: verify tile topology tools v2 flow"
```

## Self-Review

### Spec Coverage

- 完整拓扑 skin：Task 1
- 边框矩形 / 填充矩形：Task 2, Task 4, Task 5
- 填充工具：Task 3, Task 4, Task 5
- 吸管工具：Task 4, Task 5
- 工具限制提示：Task 3, Task 6
- 测试与回归：Task 7

### Placeholder Scan

- 本计划没有使用 `TODO`、`TBD`、`implement later`、`fill in details`
- 每个任务都包含具体文件、测试、命令和提交建议
- 范围继续控制在首批工具，不混入复杂选区和高级变换

### Type Consistency

- 新工具命名统一为 `picker / fill / rectangle-outline / rectangle-fill`
- 拓扑 tile id 统一使用 `outer-* / inner-* / yard-* / door-leaf-*`
- 非法组合提示统一走 `getToolGuardError()`
- 画布矩形预览统一走 `rectanglePreview`
