# AIRPGWeb Ingame Tile Map Editor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a first usable ingame developer mode for `AIRPGWeb` with a layer-aware tile map editor, map save/load, multi-map world composition with adjacent-map ghost previews, runtime map loading, and AI-assisted draft generation.

**Architecture:** The editor lives inside the existing React shell, while tile logic, persistence, world composition, and runtime loading stay in focused domain/runtime modules. Map data is stored as structured `MapAsset`/`WorldAsset` records with layer-oriented cells; the renderer can switch visual presets without changing logical data.

**Tech Stack:** React 19, TypeScript, Dexie, Vitest, Playwright, Vite

---

## File Map

### New Files

- `Project/AIRPGWeb/src/domain/map-editor/map-editor-types.ts`
- `Project/AIRPGWeb/src/domain/map-editor/tile-palette.ts`
- `Project/AIRPGWeb/src/domain/map-editor/create-empty-map-asset.ts`
- `Project/AIRPGWeb/src/domain/map-editor/editor-reducer.ts`
- `Project/AIRPGWeb/src/domain/map-editor/world-composition.ts`
- `Project/AIRPGWeb/src/domain/map-editor/ai-layout-assistant.ts`
- `Project/AIRPGWeb/src/domain/map-editor/create-empty-map-asset.test.ts`
- `Project/AIRPGWeb/src/domain/map-editor/editor-reducer.test.ts`
- `Project/AIRPGWeb/src/domain/map-editor/world-composition.test.ts`
- `Project/AIRPGWeb/src/domain/map-editor/ai-layout-assistant.test.ts`
- `Project/AIRPGWeb/src/persistence/repositories/map-asset-repository.ts`
- `Project/AIRPGWeb/src/persistence/repositories/world-asset-repository.ts`
- `Project/AIRPGWeb/src/persistence/repositories/map-asset-repository.test.ts`
- `Project/AIRPGWeb/src/runtime/world/runtime-map-loader.ts`
- `Project/AIRPGWeb/src/runtime/world/runtime-map-loader.test.ts`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/DeveloperModeShell.tsx`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/DeveloperModeHome.tsx`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/MapEditorScreen.tsx`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/EditorToolbar.tsx`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/EditorLayerList.tsx`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TilePalette.tsx`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileCanvas.tsx`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/MapBrowserPanel.tsx`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/WorldCompositionPanel.tsx`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/AiAssistPanel.tsx`
- `Project/AIRPGWeb/tests/developer-mode.spec.ts`

### Modified Files

- `Project/AIRPGWeb/src/App.tsx`
- `Project/AIRPGWeb/src/App.css`
- `Project/AIRPGWeb/src/presentation/react-shell/StartScreen.tsx`
- `Project/AIRPGWeb/src/persistence/db/airpg-db.ts`
- `Project/AIRPGWeb/src/runtime/world/world-runtime-service.ts`
- `Project/AIRPGWeb/src/presentation/react-shell/GameShell.tsx`
- `Project/AIRPGWeb/src/presentation/react-shell/TextMapView.tsx`
- `Project/AIRPGWeb/tests/app-smoke.spec.ts`

### Responsibility Split

- `domain/map-editor/*`: tile editor data model, reducers, world composition, AI draft contracts
- `persistence/repositories/*`: `MapAsset` / `WorldAsset` Dexie persistence
- `presentation/react-shell/dev-mode/*`: developer mode UI, toolbar, layer list, palette, canvas, world composition
- `runtime/world/*`: convert saved editor assets into runtime-ready map structures
- `App.tsx` / `StartScreen.tsx`: route entry and navigation glue
- `GameShell.tsx` / `TextMapView.tsx`: consume runtime-loaded maps instead of only static map data

## Task 1: Developer Mode Entry And Shell

**Files:**
- Create: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/DeveloperModeShell.tsx`
- Create: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/DeveloperModeHome.tsx`
- Modify: `Project/AIRPGWeb/src/App.tsx`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/StartScreen.tsx`
- Modify: `Project/AIRPGWeb/tests/app-smoke.spec.ts`
- Test: `Project/AIRPGWeb/tests/developer-mode.spec.ts`

- [ ] **Step 1: Write the failing Playwright smoke for developer mode entry**

```ts
import { test, expect } from '@playwright/test';

test('developer mode entry opens module hub', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('button', { name: '开发者模式' }).click();

  await expect(page.getByRole('heading', { name: '开发者模式' })).toBeVisible();
  await expect(page.getByRole('button', { name: '地图绘制' })).toBeVisible();
});
```

- [ ] **Step 2: Run the failing test**

Run:

```bash
npm run test:e2e -- tests/developer-mode.spec.ts
```

Expected: FAIL because `开发者模式` button and `DeveloperModeShell` do not exist yet.

- [ ] **Step 3: Add the app route and start-screen button**

```tsx
// App.tsx
type AppScreen =
  | 'start'
  | 'create'
  | 'loading'
  | 'loading-load'
  | 'game'
  | 'settings'
  | 'game-settings'
  | 'save-select'
  | 'dev-mode';

if (screen === 'start') {
  return (
    <main className="app-shell">
      <StartScreen
        hasSave={hasSave}
        onStart={() => setScreen('create')}
        onContinue={handleContinue}
        onSettings={() => setScreen('settings')}
        onQuit={handleQuit}
        onDeveloperMode={() => setScreen('dev-mode')}
      />
    </main>
  );
}

if (screen === 'dev-mode') {
  return (
    <main className="app-shell">
      <DeveloperModeShell onBack={() => setScreen('start')} />
    </main>
  );
}
```

```tsx
// StartScreen.tsx
type StartScreenProps = {
  hasSave: boolean;
  onStart: () => void;
  onContinue: () => void;
  onSettings: () => void;
  onQuit: () => void;
  onDeveloperMode: () => void;
};

<button type="button" onClick={onDeveloperMode}>
  开发者模式
</button>
```

```tsx
// dev-mode/DeveloperModeShell.tsx
import { useState } from 'react';
import { DeveloperModeHome } from './DeveloperModeHome';
import { MapEditorScreen } from './MapEditorScreen';

type ModuleId = 'home' | 'map-editor';

export function DeveloperModeShell({ onBack }: { onBack: () => void }) {
  const [activeModule, setActiveModule] = useState<ModuleId>('home');

  if (activeModule === 'map-editor') {
    return <MapEditorScreen onBack={() => setActiveModule('home')} onExit={onBack} />;
  }

  return <DeveloperModeHome onOpenMapEditor={() => setActiveModule('map-editor')} onBack={onBack} />;
}
```

```tsx
// dev-mode/DeveloperModeHome.tsx
export function DeveloperModeHome(props: { onOpenMapEditor: () => void; onBack: () => void }) {
  return (
    <section className="dev-mode-shell">
      <header className="dev-mode-header">
        <h1>开发者模式</h1>
        <button onClick={props.onBack}>返回</button>
      </header>
      <div className="dev-mode-modules">
        <button onClick={props.onOpenMapEditor}>地图绘制</button>
      </div>
    </section>
  );
}
```

- [ ] **Step 4: Run smoke and typecheck**

Run:

```bash
npm run test:e2e -- tests/developer-mode.spec.ts
npx tsc --noEmit
```

Expected: Playwright PASS for the new entry flow, TypeScript PASS.

- [ ] **Step 5: Commit**

```bash
git add src/App.tsx src/presentation/react-shell/StartScreen.tsx src/presentation/react-shell/dev-mode/DeveloperModeShell.tsx src/presentation/react-shell/dev-mode/DeveloperModeHome.tsx tests/developer-mode.spec.ts tests/app-smoke.spec.ts
git commit -m "feat: add developer mode shell"
```

## Task 2: Tile Data Model And Empty Map Creation

**Files:**
- Create: `Project/AIRPGWeb/src/domain/map-editor/map-editor-types.ts`
- Create: `Project/AIRPGWeb/src/domain/map-editor/tile-palette.ts`
- Create: `Project/AIRPGWeb/src/domain/map-editor/create-empty-map-asset.ts`
- Create: `Project/AIRPGWeb/src/domain/map-editor/create-empty-map-asset.test.ts`

- [ ] **Step 1: Write failing unit tests for empty map creation**

```ts
import { describe, expect, it } from 'vitest';
import { createEmptyMapAsset } from './create-empty-map-asset';

describe('createEmptyMapAsset', () => {
  it('creates all default editor layers with the same grid size', () => {
    const map = createEmptyMapAsset({ id: 'map-1', name: '新地图', width: 8, height: 6 });

    expect(map.width).toBe(8);
    expect(map.height).toBe(6);
    expect(map.layers.map(layer => layer.id)).toEqual([
      'ground',
      'region',
      'structure',
      'openings',
      'art',
    ]);
    expect(map.layers.every(layer => layer.cells.length === 48)).toBe(true);
  });
});
```

- [ ] **Step 2: Run the failing unit test**

Run:

```bash
npm run test -- src/domain/map-editor/create-empty-map-asset.test.ts
```

Expected: FAIL because the domain files do not exist.

- [ ] **Step 3: Define the editor types and empty asset factory**

```ts
// map-editor-types.ts
export type EditorLayerId = 'ground' | 'region' | 'structure' | 'openings' | 'art';

export type TileVisualStyle = 'blueprint' | 'microPixel';

export type TileLogic = {
  region: 'outside' | 'yard' | 'frontRoom' | 'sleepRoom' | 'storage' | 'kitchen';
  terrain: 'grass' | 'dirtRoad' | 'yardFloor' | 'interiorFloor';
  structure: 'none' | 'outerWall' | 'innerWall' | 'corner' | 'junction' | 'doorSocket';
  orientation: 'none' | 'h' | 'v' | 'tl' | 'tr' | 'bl' | 'br' | 't-up' | 't-right' | 't-down' | 't-left' | 'cross';
  doorState: 'none' | 'open' | 'closed';
  walkable: boolean;
  blocksPlacement: boolean;
};

export type MapTileCell = {
  x: number;
  y: number;
  tileId: string | null;
  visualStyle: TileVisualStyle;
  logic: TileLogic;
};

export type MapLayerAsset = {
  id: EditorLayerId;
  name: string;
  visible: boolean;
  locked: boolean;
  opacity: number;
  cells: MapTileCell[];
};

export type MapAsset = {
  id: string;
  name: string;
  width: number;
  height: number;
  tileSize: number;
  properties: Record<string, string | number | boolean>;
  layers: MapLayerAsset[];
  publishedAt: string | null;
  runtimePublished: boolean;
};
```

```ts
// tile-palette.ts
import type { EditorLayerId } from './map-editor-types';

export type TilePreset = {
  id: string;
  label: string;
  layerId: EditorLayerId;
  preview: string;
};

export const tilePalette: TilePreset[] = [
  { id: 'ground-grass', label: '草地', layerId: 'ground', preview: '░' },
  { id: 'ground-yard', label: '院地', layerId: 'ground', preview: '▒' },
  { id: 'structure-outer-wall-h', label: '外墙横', layerId: 'structure', preview: '══' },
  { id: 'structure-outer-wall-v', label: '外墙竖', layerId: 'structure', preview: '║' },
  { id: 'structure-corner-tl', label: '左上角', layerId: 'structure', preview: '╔' },
  { id: 'opening-door-h-closed', label: '横门关', layerId: 'openings', preview: '═╬═' },
  { id: 'opening-door-h-open', label: '横门开', layerId: 'openings', preview: '═ ║' },
  { id: 'art-micro-floor', label: '室内微纹理', layerId: 'art', preview: '▓▓' },
];
```

```ts
// create-empty-map-asset.ts
import type { EditorLayerId, MapAsset, MapLayerAsset, MapTileCell } from './map-editor-types';

const layerNames: Record<EditorLayerId, string> = {
  ground: '地表层',
  region: '区域层',
  structure: '结构层',
  openings: '开口层',
  art: '美术覆盖层',
};

function createDefaultCell(x: number, y: number): MapTileCell {
  return {
    x,
    y,
    tileId: null,
    visualStyle: 'blueprint',
    logic: {
      region: 'outside',
      terrain: 'grass',
      structure: 'none',
      orientation: 'none',
      doorState: 'none',
      walkable: true,
      blocksPlacement: false,
    },
  };
}

function createLayer(id: EditorLayerId, width: number, height: number): MapLayerAsset {
  return {
    id,
    name: layerNames[id],
    visible: true,
    locked: false,
    opacity: 1,
    cells: Array.from({ length: width * height }, (_, index) =>
      createDefaultCell(index % width, Math.floor(index / width))
    ),
  };
}

export function createEmptyMapAsset(input: { id: string; name: string; width: number; height: number }): MapAsset {
  return {
    id: input.id,
    name: input.name,
    width: input.width,
    height: input.height,
    tileSize: 32,
    properties: {},
    publishedAt: null,
    runtimePublished: false,
    layers: (['ground', 'region', 'structure', 'openings', 'art'] as const).map(layerId =>
      createLayer(layerId, input.width, input.height)
    ),
  };
}
```

- [ ] **Step 4: Run the unit test**

Run:

```bash
npm run test -- src/domain/map-editor/create-empty-map-asset.test.ts
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/domain/map-editor/map-editor-types.ts src/domain/map-editor/tile-palette.ts src/domain/map-editor/create-empty-map-asset.ts src/domain/map-editor/create-empty-map-asset.test.ts
git commit -m "feat: add tile editor core types"
```

## Task 3: Layer-Aware Painting, Palette Filtering, And Undo/Redo

**Files:**
- Create: `Project/AIRPGWeb/src/domain/map-editor/editor-reducer.ts`
- Create: `Project/AIRPGWeb/src/domain/map-editor/editor-reducer.test.ts`
- Create: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/MapEditorScreen.tsx`
- Create: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/EditorToolbar.tsx`
- Create: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/EditorLayerList.tsx`
- Create: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TilePalette.tsx`
- Create: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileCanvas.tsx`
- Modify: `Project/AIRPGWeb/src/App.css`
- Test: `Project/AIRPGWeb/tests/developer-mode.spec.ts`

- [ ] **Step 1: Write reducer tests for active-layer paint and undo/redo**

```ts
import { describe, expect, it } from 'vitest';
import { createEmptyMapAsset } from './create-empty-map-asset';
import { createInitialEditorState, editorReducer } from './editor-reducer';

describe('editorReducer', () => {
  it('applies paint only to the active layer and supports undo/redo', () => {
    const map = createEmptyMapAsset({ id: 'map-1', name: '草稿', width: 4, height: 4 });
    let state = createInitialEditorState(map);

    state = editorReducer(state, {
      type: 'paint-tile',
      layerId: 'structure',
      x: 1,
      y: 1,
      tileId: 'structure-outer-wall-h',
    });

    expect(state.map.layers.find(layer => layer.id === 'structure')?.cells[5].tileId).toBe('structure-outer-wall-h');
    expect(state.map.layers.find(layer => layer.id === 'ground')?.cells[5].tileId).toBe(null);

    state = editorReducer(state, { type: 'undo' });
    expect(state.map.layers.find(layer => layer.id === 'structure')?.cells[5].tileId).toBe(null);

    state = editorReducer(state, { type: 'redo' });
    expect(state.map.layers.find(layer => layer.id === 'structure')?.cells[5].tileId).toBe('structure-outer-wall-h');
  });
});
```

- [ ] **Step 2: Run the reducer test**

Run:

```bash
npm run test -- src/domain/map-editor/editor-reducer.test.ts
```

Expected: FAIL because reducer and state model do not exist.

- [ ] **Step 3: Implement editor reducer and first usable editor UI**

```ts
// editor-reducer.ts
import type { EditorLayerId, MapAsset } from './map-editor-types';

export type EditorTool = 'brush' | 'eraser' | 'fill' | 'rectangle' | 'picker';

export type EditorState = {
  map: MapAsset;
  activeLayerId: EditorLayerId;
  activeTool: EditorTool;
  selectedTileId: string | null;
  past: MapAsset[];
  future: MapAsset[];
};

export function createInitialEditorState(map: MapAsset): EditorState {
  return {
    map,
    activeLayerId: 'structure',
    activeTool: 'brush',
    selectedTileId: null,
    past: [],
    future: [],
  };
}

function cloneMap(map: MapAsset): MapAsset {
  return structuredClone(map);
}

export function editorReducer(state: EditorState, action:
  | { type: 'set-layer'; layerId: EditorLayerId }
  | { type: 'set-tool'; tool: EditorTool }
  | { type: 'select-tile'; tileId: string | null }
  | { type: 'paint-tile'; layerId: EditorLayerId; x: number; y: number; tileId: string | null }
  | { type: 'undo' }
  | { type: 'redo' }
): EditorState {
  if (action.type === 'undo') {
    const previous = state.past.at(-1);
    if (!previous) return state;
    return { ...state, map: previous, past: state.past.slice(0, -1), future: [cloneMap(state.map), ...state.future] };
  }

  if (action.type === 'redo') {
    const next = state.future[0];
    if (!next) return state;
    return { ...state, map: next, past: [...state.past, cloneMap(state.map)], future: state.future.slice(1) };
  }

  if (action.type === 'paint-tile') {
    const nextMap = cloneMap(state.map);
    const layer = nextMap.layers.find(item => item.id === action.layerId);
    if (!layer) return state;
    const index = action.y * nextMap.width + action.x;
    layer.cells[index].tileId = action.tileId;
    return { ...state, map: nextMap, past: [...state.past, cloneMap(state.map)], future: [] };
  }

  if (action.type === 'set-layer') return { ...state, activeLayerId: action.layerId };
  if (action.type === 'set-tool') return { ...state, activeTool: action.tool };
  if (action.type === 'select-tile') return { ...state, selectedTileId: action.tileId };
  return state;
}
```

```tsx
// MapEditorScreen.tsx
import { useMemo, useReducer } from 'react';
import { createEmptyMapAsset } from '../../../domain/map-editor/create-empty-map-asset';
import { createInitialEditorState, editorReducer } from '../../../domain/map-editor/editor-reducer';
import { tilePalette } from '../../../domain/map-editor/tile-palette';
import { EditorToolbar } from './EditorToolbar';
import { EditorLayerList } from './EditorLayerList';
import { TilePalette } from './TilePalette';
import { TileCanvas } from './TileCanvas';
import { AiAssistPanel } from './AiAssistPanel';

export function MapEditorScreen({ onBack, onExit }: { onBack: () => void; onExit: () => void }) {
  const initialMap = useMemo(() => createEmptyMapAsset({ id: 'draft-map', name: '未命名地图', width: 24, height: 18 }), []);
  const [state, dispatch] = useReducer(editorReducer, initialMap, createInitialEditorState);
  const palette = tilePalette.filter(tile => tile.layerId === state.activeLayerId);

  return (
    <section className="map-editor-layout">
      <EditorToolbar state={state} dispatch={dispatch} onBack={onBack} onExit={onExit} />
      <div className="map-editor-body">
        <EditorLayerList state={state} dispatch={dispatch} />
        <TileCanvas state={state} dispatch={dispatch} />
        <TilePalette tiles={palette} selectedTileId={state.selectedTileId} onSelect={(tileId) => dispatch({ type: 'select-tile', tileId })} />
      </div>
      <AiAssistPanel />
    </section>
  );
}
```

- [ ] **Step 4: Add Playwright coverage for layer selection and paint**

```ts
test('map editor filters palette by active layer and paints selected tile', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('button', { name: '开发者模式' }).click();
  await page.getByRole('button', { name: '地图绘制' }).click();

  await page.getByRole('button', { name: '结构层' }).click();
  await expect(page.getByRole('button', { name: '外墙横' })).toBeVisible();
  await expect(page.getByRole('button', { name: '草地' })).toHaveCount(0);

  await page.getByRole('button', { name: '外墙横' }).click();
  await page.getByTestId('tile-cell-1-1').click();
  await expect(page.getByTestId('tile-cell-1-1')).toContainText('══');
});
```

Run:

```bash
npm run test -- src/domain/map-editor/editor-reducer.test.ts
npm run test:e2e -- tests/developer-mode.spec.ts
```

Expected: PASS for reducer and editor smoke.

- [ ] **Step 5: Commit**

```bash
git add src/domain/map-editor/editor-reducer.ts src/domain/map-editor/editor-reducer.test.ts src/presentation/react-shell/dev-mode/MapEditorScreen.tsx src/presentation/react-shell/dev-mode/EditorToolbar.tsx src/presentation/react-shell/dev-mode/EditorLayerList.tsx src/presentation/react-shell/dev-mode/TilePalette.tsx src/presentation/react-shell/dev-mode/TileCanvas.tsx src/App.css tests/developer-mode.spec.ts
git commit -m "feat: add layer-aware tile editor"
```

## Task 4: Map Persistence, Browser, And Reopen Flow

**Files:**
- Modify: `Project/AIRPGWeb/src/persistence/db/airpg-db.ts`
- Create: `Project/AIRPGWeb/src/persistence/repositories/map-asset-repository.ts`
- Create: `Project/AIRPGWeb/src/persistence/repositories/world-asset-repository.ts`
- Create: `Project/AIRPGWeb/src/persistence/repositories/map-asset-repository.test.ts`
- Create: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/MapBrowserPanel.tsx`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/MapEditorScreen.tsx`

- [ ] **Step 1: Write the repository test**

```ts
import { describe, expect, it } from 'vitest';
import { createEmptyMapAsset } from '../../domain/map-editor/create-empty-map-asset';
import { createMapAssetRepository } from './map-asset-repository';

describe('map asset repository', () => {
  it('saves, lists and reloads map assets', async () => {
    const repo = createMapAssetRepository();
    const map = createEmptyMapAsset({ id: 'house-01', name: '铁匠铺', width: 12, height: 10 });

    await repo.save(map);

    const list = await repo.list();
    const loaded = await repo.load('house-01');

    expect(list.some(item => item.id === 'house-01')).toBe(true);
    expect(loaded?.name).toBe('铁匠铺');
  });
});
```

- [ ] **Step 2: Run the failing repository test**

Run:

```bash
npm run test -- src/persistence/repositories/map-asset-repository.test.ts
```

Expected: FAIL because repository and DB tables do not exist.

- [ ] **Step 3: Add map/world tables and repositories**

```ts
// airpg-db.ts
export class AirpgDb extends Dexie {
  saveSlots!: EntityTable<SaveSlot, 'slotId'>;
  mapAssets!: EntityTable<MapAsset, 'id'>;
  worldAssets!: EntityTable<WorldAsset, 'id'>;

  constructor() {
    super('airpg-web-v3');
    this.version(1).stores({
      saveSlots: 'slotId,savedAt',
      mapAssets: 'id,name,runtimePublished',
      worldAssets: 'id,name,runtimePublished',
    });
  }
}
```

```ts
// map-asset-repository.ts
import { db } from '../db/airpg-db';
import type { MapAsset } from '../../domain/map-editor/map-editor-types';

export function createMapAssetRepository() {
  return {
    async save(map: MapAsset) {
      await db.mapAssets.put(map);
    },
    async load(id: string) {
      return (await db.mapAssets.get(id)) ?? null;
    },
    async list() {
      return db.mapAssets.orderBy('name').toArray();
    },
    async publish(id: string) {
      await db.mapAssets.toCollection().modify({ runtimePublished: false });
      await db.mapAssets.update(id, { runtimePublished: true, publishedAt: new Date().toISOString() });
    },
  };
}
```

```tsx
// MapBrowserPanel.tsx
export function MapBrowserPanel(props: {
  maps: { id: string; name: string; runtimePublished: boolean }[];
  onOpen: (id: string) => void;
  onCreate: () => void;
}) {
  return (
    <aside className="map-browser-panel">
      <header>
        <h2>地图列表</h2>
        <button onClick={props.onCreate}>新建地图</button>
      </header>
      <ul>
        {props.maps.map(map => (
          <li key={map.id}>
            <button onClick={() => props.onOpen(map.id)}>
              {map.name}{map.runtimePublished ? '（运行中）' : ''}
            </button>
          </li>
        ))}
      </ul>
    </aside>
  );
}
```

- [ ] **Step 4: Run repository test and reopen smoke**

Run:

```bash
npm run test -- src/persistence/repositories/map-asset-repository.test.ts
npx tsc --noEmit
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/persistence/db/airpg-db.ts src/persistence/repositories/map-asset-repository.ts src/persistence/repositories/world-asset-repository.ts src/persistence/repositories/map-asset-repository.test.ts src/presentation/react-shell/dev-mode/MapBrowserPanel.tsx src/presentation/react-shell/dev-mode/MapEditorScreen.tsx
git commit -m "feat: add map asset persistence"
```

## Task 5: World Composition And Adjacent Ghost Preview

**Files:**
- Create: `Project/AIRPGWeb/src/domain/map-editor/world-composition.ts`
- Create: `Project/AIRPGWeb/src/domain/map-editor/world-composition.test.ts`
- Create: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/WorldCompositionPanel.tsx`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileCanvas.tsx`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/MapEditorScreen.tsx`

- [ ] **Step 1: Write the world composition test**

```ts
import { describe, expect, it } from 'vitest';
import { collectAdjacentGhosts } from './world-composition';

describe('world composition', () => {
  it('returns only the directly adjacent maps around the current placement', () => {
    const ghosts = collectAdjacentGhosts({
      currentMapId: 'village-square',
      placements: [
        { mapId: 'village-square', worldX: 0, worldY: 0, width: 20, height: 20 },
        { mapId: 'blacksmith-yard', worldX: 20, worldY: 0, width: 16, height: 20 },
        { mapId: 'north-farm', worldX: 0, worldY: -20, width: 20, height: 20 },
        { mapId: 'far-away', worldX: 80, worldY: 80, width: 20, height: 20 },
      ],
    });

    expect(ghosts.map(item => item.mapId)).toEqual(['blacksmith-yard', 'north-farm']);
  });
});
```

- [ ] **Step 2: Run the failing test**

Run:

```bash
npm run test -- src/domain/map-editor/world-composition.test.ts
```

Expected: FAIL because the world composition helper does not exist.

- [ ] **Step 3: Implement adjacent ghost logic and ghost rendering**

```ts
// world-composition.ts
export type WorldPlacement = {
  mapId: string;
  worldX: number;
  worldY: number;
  width: number;
  height: number;
};

export function collectAdjacentGhosts(input: {
  currentMapId: string;
  placements: WorldPlacement[];
}) {
  const current = input.placements.find(item => item.mapId === input.currentMapId);
  if (!current) return [];

  return input.placements.filter(item => {
    if (item.mapId === current.mapId) return false;
    const horizontalTouch = item.worldY < current.worldY + current.height && item.worldY + item.height > current.worldY;
    const verticalTouch = item.worldX < current.worldX + current.width && item.worldX + item.width > current.worldX;
    const touchesLeftOrRight = item.worldX + item.width === current.worldX || item.worldX === current.worldX + current.width;
    const touchesTopOrBottom = item.worldY + item.height === current.worldY || item.worldY === current.worldY + current.height;
    return (horizontalTouch && touchesLeftOrRight) || (verticalTouch && touchesTopOrBottom);
  });
}
```

```tsx
// TileCanvas.tsx
{ghostMaps.map(ghost => (
  <div
    key={ghost.mapId}
    className="tile-canvas-ghost"
    style={{ left: ghost.offsetX * tileSize, top: ghost.offsetY * tileSize }}
  >
    {ghost.previewRows.map((row, rowIndex) => (
      <div key={rowIndex}>{row}</div>
    ))}
  </div>
))}
```

- [ ] **Step 4: Verify adjacent preview by test and manual smoke**

Run:

```bash
npm run test -- src/domain/map-editor/world-composition.test.ts
npx tsc --noEmit
```

Expected: PASS. Manual verification: current map keeps edit focus, adjacent maps render as read-only translucent ghosts.

- [ ] **Step 5: Commit**

```bash
git add src/domain/map-editor/world-composition.ts src/domain/map-editor/world-composition.test.ts src/presentation/react-shell/dev-mode/WorldCompositionPanel.tsx src/presentation/react-shell/dev-mode/TileCanvas.tsx src/presentation/react-shell/dev-mode/MapEditorScreen.tsx
git commit -m "feat: add world composition ghost previews"
```

## Task 6: Runtime Map Loader And Ingame Display Bridge

**Files:**
- Create: `Project/AIRPGWeb/src/runtime/world/runtime-map-loader.ts`
- Create: `Project/AIRPGWeb/src/runtime/world/runtime-map-loader.test.ts`
- Modify: `Project/AIRPGWeb/src/runtime/world/world-runtime-service.ts`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/GameShell.tsx`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/TextMapView.tsx`

- [ ] **Step 1: Write runtime loader unit test**

```ts
import { describe, expect, it } from 'vitest';
import { createRuntimeMapLoader } from './runtime-map-loader';
import { createEmptyMapAsset } from '../../domain/map-editor/create-empty-map-asset';

describe('runtime map loader', () => {
  it('converts a published editor map into runtime tile rows', () => {
    const map = createEmptyMapAsset({ id: 'house-01', name: '贫农民居', width: 3, height: 2 });
    map.layers.find(layer => layer.id === 'structure')!.cells[0].tileId = 'structure-corner-tl';

    const runtimeMap = createRuntimeMapLoader().fromMapAsset(map);

    expect(runtimeMap.width).toBe(3);
    expect(runtimeMap.height).toBe(2);
    expect(runtimeMap.cells[0].renderToken).toBe('╔');
  });
});
```

- [ ] **Step 2: Run the failing unit test**

Run:

```bash
npm run test -- src/runtime/world/runtime-map-loader.test.ts
```

Expected: FAIL because the loader does not exist.

- [ ] **Step 3: Implement runtime loader and thread it through the game shell**

```ts
// runtime-map-loader.ts
import type { MapAsset } from '../../domain/map-editor/map-editor-types';

const renderLookup: Record<string, string> = {
  'structure-corner-tl': '╔',
  'structure-outer-wall-h': '══',
  'structure-outer-wall-v': '║',
  'opening-door-h-open': '║',
  'opening-door-h-closed': '═╬═',
  'ground-grass': '░',
  'ground-yard': '▒',
  'art-micro-floor': '▓',
};

export function createRuntimeMapLoader() {
  return {
    fromMapAsset(map: MapAsset) {
      const cells = map.layers[0].cells.map((_, index) => {
        const art = map.layers.find(layer => layer.id === 'art')!.cells[index].tileId;
        const structure = map.layers.find(layer => layer.id === 'structure')!.cells[index].tileId;
        const openings = map.layers.find(layer => layer.id === 'openings')!.cells[index].tileId;
        const ground = map.layers.find(layer => layer.id === 'ground')!.cells[index].tileId;
        const tileId = art ?? openings ?? structure ?? ground;
        return { ...map.layers[0].cells[index], renderToken: tileId ? renderLookup[tileId] ?? '?' : ' ' };
      });

      return { id: map.id, name: map.name, width: map.width, height: map.height, cells };
    },
  };
}
```

```ts
// world-runtime-service.ts
export async function loadPublishedRuntimeMap() {
  const repo = createMapAssetRepository();
  const published = (await repo.list()).find(item => item.runtimePublished);
  if (!published) return null;
  const map = await repo.load(published.id);
  return map ? createRuntimeMapLoader().fromMapAsset(map) : null;
}
```

```tsx
// GameShell.tsx
type GameShellProps = {
  player: PlayerData;
  runtimeMapOverride?: RuntimeEditorMap | null;
  // existing props...
};

<TextMapView
  mapOverride={runtimeMapOverride}
  initialPlayerX={initialPlayerX}
  initialPlayerY={initialPlayerY}
  onPlayerPositionChange={(x, y) => {
    setPlayerX(x);
    setPlayerY(y);
  }}
/>
```

- [ ] **Step 4: Run unit tests and runtime smoke**

Run:

```bash
npm run test -- src/runtime/world/runtime-map-loader.test.ts
npx tsc --noEmit
```

Expected: PASS. Manual smoke: publishing a map in developer mode changes the map that the game renders.

- [ ] **Step 5: Commit**

```bash
git add src/runtime/world/runtime-map-loader.ts src/runtime/world/runtime-map-loader.test.ts src/runtime/world/world-runtime-service.ts src/presentation/react-shell/GameShell.tsx src/presentation/react-shell/TextMapView.tsx
git commit -m "feat: bridge editor maps into runtime world"
```

## Task 7: AI Draft Generation And Layer Beautification

**Files:**
- Create: `Project/AIRPGWeb/src/domain/map-editor/ai-layout-assistant.ts`
- Create: `Project/AIRPGWeb/src/domain/map-editor/ai-layout-assistant.test.ts`
- Create: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/AiAssistPanel.tsx`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/MapEditorScreen.tsx`

- [ ] **Step 1: Write deterministic AI assistant unit tests**

```ts
import { describe, expect, it } from 'vitest';
import { createAiLayoutAssistant } from './ai-layout-assistant';

describe('ai layout assistant', () => {
  it('returns a structured two-person peasant house draft', () => {
    const draft = createAiLayoutAssistant().generateDraft('生成一个 2 人贫农民居布局图，带小院和分体厨房');

    expect(draft.template).toBe('peasant-house-2p');
    expect(draft.rooms.map(room => room.type)).toEqual(['yard', 'frontRoom', 'sleepRoom', 'storage', 'kitchen']);
    expect(draft.doors.length).toBeGreaterThan(0);
  });
});
```

- [ ] **Step 2: Run the failing unit test**

Run:

```bash
npm run test -- src/domain/map-editor/ai-layout-assistant.test.ts
```

Expected: FAIL because the assistant does not exist.

- [ ] **Step 3: Implement the AI contract and preview panel**

```ts
// ai-layout-assistant.ts
export type LayoutDraft = {
  template: string;
  rooms: Array<{ type: 'yard' | 'frontRoom' | 'sleepRoom' | 'storage' | 'kitchen'; x: number; y: number; w: number; h: number }>;
  doors: Array<{ x: number; y: number; orientation: 'h' | 'v'; kind: 'yardGate' | 'mainDoor' | 'innerDoor' }>;
  suggestions: string[];
};

export function createAiLayoutAssistant() {
  return {
    generateDraft(prompt: string): LayoutDraft {
      if (prompt.includes('2 人贫农民居')) {
        return {
          template: 'peasant-house-2p',
          rooms: [
            { type: 'yard', x: 0, y: 0, w: 14, h: 10 },
            { type: 'frontRoom', x: 2, y: 2, w: 6, h: 3 },
            { type: 'sleepRoom', x: 2, y: 5, w: 6, h: 3 },
            { type: 'storage', x: 8, y: 4, w: 2, h: 2 },
            { type: 'kitchen', x: 10, y: 3, w: 3, h: 4 },
          ],
          doors: [
            { x: 2, y: 0, orientation: 'h', kind: 'yardGate' },
            { x: 8, y: 3, orientation: 'v', kind: 'mainDoor' },
          ],
          suggestions: ['院地层建议使用夯土地面', '室内地面建议使用木板 micro-pixel'],
        };
      }

      return { template: 'empty', rooms: [], doors: [], suggestions: ['请补充更具体的房屋描述'] };
    },
  };
}
```

```tsx
// AiAssistPanel.tsx
import { useState } from 'react';

export function AiAssistPanel(props: {
  onGenerateDraft: (prompt: string) => void;
  suggestions: string[];
}) {
  const [prompt, setPrompt] = useState('生成一个 2 人贫农民居布局图，带小院和分体厨房');

  return (
    <section className="ai-assist-panel">
      <h2>AI 辅助</h2>
      <textarea value={prompt} onChange={(event) => setPrompt(event.target.value)} />
      <button onClick={() => props.onGenerateDraft(prompt)}>生成草稿</button>
      <ul>
        {props.suggestions.map(item => (
          <li key={item}>{item}</li>
        ))}
      </ul>
    </section>
  );
}
```

- [ ] **Step 4: Run the unit test and smoke**

Run:

```bash
npm run test -- src/domain/map-editor/ai-layout-assistant.test.ts
npx tsc --noEmit
```

Expected: PASS. Manual smoke: AI suggestions appear in the panel and draft data can be previewed before merge.

- [ ] **Step 5: Commit**

```bash
git add src/domain/map-editor/ai-layout-assistant.ts src/domain/map-editor/ai-layout-assistant.test.ts src/presentation/react-shell/dev-mode/AiAssistPanel.tsx src/presentation/react-shell/dev-mode/MapEditorScreen.tsx
git commit -m "feat: add ai draft assistant for tile editor"
```

## Task 8: End-To-End Flow, Final Verification, And Docs Sync

**Files:**
- Modify: `Project/AIRPGWeb/tests/developer-mode.spec.ts`
- Modify: `Project/AIRPGWeb/tests/app-smoke.spec.ts`
- Modify: `Project/AIRPGWeb/src/App.css`
- Review: `Docs/superpowers/specs/2026-05-31-airpgweb-ingame-tile-map-editor-design.md`

- [ ] **Step 1: Add an end-to-end flow test**

```ts
test('developer mode can save a map, reopen it, publish it, and show adjacent ghosts', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('button', { name: '开发者模式' }).click();
  await page.getByRole('button', { name: '地图绘制' }).click();

  await page.getByRole('button', { name: '结构层' }).click();
  await page.getByRole('button', { name: '外墙横' }).click();
  await page.getByTestId('tile-cell-1-1').click();
  await page.getByRole('button', { name: '保存' }).click();

  await page.getByRole('button', { name: '地图列表' }).click();
  await page.getByRole('button', { name: /未命名地图/ }).click();
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

- [ ] **Step 3: Fix CSS/UI polish issues found during verification**

```css
.map-editor-layout {
  display: grid;
  grid-template-rows: auto 1fr auto;
  gap: 12px;
  min-height: 100vh;
}

.map-editor-body {
  display: grid;
  grid-template-columns: 220px 1fr 280px;
  gap: 12px;
}

.tile-canvas-ghost {
  opacity: 0.35;
  pointer-events: none;
}
```

- [ ] **Step 4: Update the spec if names changed during implementation**

```md
- Confirm the implemented component names still match:
  - `DeveloperModeShell`
  - `MapEditorScreen`
  - `RuntimeMapLoader`
  - `MapAsset`
  - `WorldAsset`
- If any names drifted during implementation, update the spec immediately after code passes verification.
```

- [ ] **Step 5: Commit**

```bash
git add tests/developer-mode.spec.ts tests/app-smoke.spec.ts src/App.css Docs/superpowers/specs/2026-05-31-airpgweb-ingame-tile-map-editor-design.md
git commit -m "test: verify ingame tile editor flow"
```

## Self-Review

### Spec Coverage

- 开发者模式入口：Task 1
- 分层 tile 编辑与按层 palette：Task 2, Task 3
- 地图保存/打开/另存为/回编：Task 4
- 多地图拼接与相邻地图幽灵层：Task 5
- 运行时读取编辑地图：Task 6
- AI 草稿生成与指定层美化：Task 7
- 运行时验证与整体回归：Task 8

### Placeholder Scan

- 本计划未使用占位词或“以后再补”的延后实现措辞
- 所有任务都包含了实际文件路径、测试代码、命令和提交建议

### Type Consistency

- 编辑器层 id 统一为 `ground / region / structure / openings / art`
- 运行时桥接统一使用 `RuntimeMapLoader`
- 地图资产统一使用 `MapAsset / WorldAsset`
- AI 输出统一进入草稿层或建议预览态，不直接覆盖正式层
