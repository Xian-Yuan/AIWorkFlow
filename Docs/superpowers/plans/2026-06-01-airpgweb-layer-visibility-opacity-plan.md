# AIRPGWeb Layer Visibility And Opacity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在地图编辑器中接入图层显隐控制与透明度 UI，并让 `visible/opacity` 真正影响画布渲染。

**Architecture:** 在 `editor-reducer` 中新增图层显示状态动作，保持 `MapAsset.layers` 作为单一真相源；`EditorLayerList` 负责暴露显隐与透明度控件；`TileCanvas` 继续按固定层顺序合成可见层，但最终显示时读取最上层可见 tile 所属图层的透明度，让上层内容可被下层透出。

**Tech Stack:** React, TypeScript, Vitest, Vite

---

### Task 1: Add Layer Visibility State Actions

**Files:**
- Modify: `Project/AIRPGWeb/src/domain/map-editor/editor-reducer.ts`
- Test: `Project/AIRPGWeb/src/domain/map-editor/editor-reducer.test.ts`

- [ ] **Step 1: Write the failing tests**

```ts
it('toggles layer visibility without changing active layer selection', () => {
  const map = createEmptyMapAsset({ id: 'map-1', name: '草稿', width: 4, height: 4 })
  let state = createInitialEditorState(map)

  state = editorReducer(state, { type: 'set-layer', layerId: 'ground' })
  state = editorReducer(state, { type: 'toggle-layer-visible', layerId: 'ground' })

  expect(state.activeLayerId).toBe('ground')
  expect(state.map.layers.find((layer) => layer.id === 'ground')?.visible).toBe(false)
})

it('stores normalized opacity percentages for layers', () => {
  const map = createEmptyMapAsset({ id: 'map-2', name: '草稿', width: 4, height: 4 })
  let state = createInitialEditorState(map)

  state = editorReducer(state, { type: 'set-layer-opacity', layerId: 'art', opacity: 0.42 })
  expect(state.map.layers.find((layer) => layer.id === 'art')?.opacity).toBe(0.42)

  state = editorReducer(state, { type: 'set-layer-opacity', layerId: 'art', opacity: 9 })
  expect(state.map.layers.find((layer) => layer.id === 'art')?.opacity).toBe(1)
})
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `npm test -- src/domain/map-editor/editor-reducer.test.ts`
Expected: FAIL with unknown action type or missing assertions for `toggle-layer-visible` / `set-layer-opacity`

- [ ] **Step 3: Write the minimal implementation**

```ts
export type EditorAction =
  | { type: 'toggle-layer-visible'; layerId: EditorLayerId }
  | { type: 'set-layer-opacity'; layerId: EditorLayerId; opacity: number }

function normalizeOpacity(opacity: number) {
  return Math.min(1, Math.max(0, Math.round(opacity * 100) / 100))
}

if (action.type === 'toggle-layer-visible') {
  const nextMap = cloneMap(state.map)
  const layer = nextMap.layers.find((item) => item.id === action.layerId)
  if (!layer) return state
  layer.visible = !layer.visible
  return {
    ...state,
    map: nextMap,
    past: [...state.past, cloneMap(state.map)],
    future: [],
  }
}

if (action.type === 'set-layer-opacity') {
  const nextMap = cloneMap(state.map)
  const layer = nextMap.layers.find((item) => item.id === action.layerId)
  if (!layer) return state
  const nextOpacity = normalizeOpacity(action.opacity)
  if (layer.opacity === nextOpacity) return state
  layer.opacity = nextOpacity
  return {
    ...state,
    map: nextMap,
    past: [...state.past, cloneMap(state.map)],
    future: [],
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `npm test -- src/domain/map-editor/editor-reducer.test.ts`
Expected: PASS with new visibility/opacity reducer coverage

- [ ] **Step 5: Commit**

```bash
git add src/domain/map-editor/editor-reducer.ts src/domain/map-editor/editor-reducer.test.ts
git commit -m "feat: add layer visibility state controls"
```

### Task 2: Expose Visibility And Opacity In Layer List

**Files:**
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/EditorLayerList.tsx`
- Modify: `Project/AIRPGWeb/src/App.css`
- Test: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileCanvas.test.ts`

- [ ] **Step 1: Write the failing test**

```ts
it('does not render hidden top layer tiles after visibility is toggled off', () => {
  const map = createEmptyMapAsset({ id: 'map-5', name: '显隐图', width: 2, height: 2 })
  const groundLayer = map.layers.find((layer) => layer.id === 'ground')
  const artLayer = map.layers.find((layer) => layer.id === 'art')
  if (!groundLayer || !artLayer) throw new Error('required layers missing')

  groundLayer.cells[0].tileId = 'ground-grass'
  artLayer.cells[0].tileId = 'art-micro-floor'
  artLayer.visible = false

  const state = createInitialEditorState(map)
  const html = renderToStaticMarkup(createElement(TileCanvas, { state, dispatch: () => undefined }))
  expect(html).toContain('data-tile-id="ground-grass"')
  expect(html).not.toContain('data-tile-id="art-micro-floor"')
})
```

- [ ] **Step 2: Run test to verify it fails or exposes missing UI support**

Run: `npm test -- src/presentation/react-shell/dev-mode/TileCanvas.test.ts`
Expected: FAIL if hidden top layer is still shown, or PASS if canvas support already exists and only UI remains

- [ ] **Step 3: Write minimal implementation**

```tsx
<button
  type="button"
  className={`map-editor-layer-visibility ${layer.visible ? 'active' : ''}`}
  aria-label={`${layer.visible ? '隐藏' : '显示'}${layer.name}`}
  onClick={() => dispatch({ type: 'toggle-layer-visible', layerId: layer.id })}
>
  {layer.visible ? '显示' : '隐藏'}
</button>

<label className="map-editor-layer-opacity">
  <span>{Math.round(layer.opacity * 100)}%</span>
  <input
    type="range"
    min={0}
    max={100}
    step={5}
    value={Math.round(layer.opacity * 100)}
    onChange={(event) =>
      dispatch({
        type: 'set-layer-opacity',
        layerId: layer.id,
        opacity: Number(event.target.value) / 100,
      })
    }
  />
</label>
```

```css
.map-editor-layer-row {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: 8px;
}

.map-editor-layer-controls {
  display: flex;
  align-items: center;
  gap: 8px;
}

.map-editor-layer-opacity {
  display: flex;
  align-items: center;
  gap: 6px;
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `npm test -- src/presentation/react-shell/dev-mode/TileCanvas.test.ts`
Expected: PASS and hidden top layer no longer overrides lower visible layer

- [ ] **Step 5: Commit**

```bash
git add src/presentation/react-shell/dev-mode/EditorLayerList.tsx src/App.css src/presentation/react-shell/dev-mode/TileCanvas.test.ts
git commit -m "feat: add layer visibility and opacity controls"
```

### Task 3: Apply Opacity In Canvas Rendering And Verify In Browser

**Files:**
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileCanvas.tsx`
- Test: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileCanvas.test.ts`

- [ ] **Step 1: Write the failing test**

```ts
it('applies the top visible layer opacity to the rendered tile skin', () => {
  const map = createEmptyMapAsset({ id: 'map-6', name: '透明图', width: 2, height: 2 })
  const artLayer = map.layers.find((layer) => layer.id === 'art')
  if (!artLayer) throw new Error('art layer missing')

  artLayer.cells[0].tileId = 'art-micro-floor'
  artLayer.opacity = 0.35

  const state = createInitialEditorState(map)
  const html = renderToStaticMarkup(createElement(TileCanvas, { state, dispatch: () => undefined }))
  expect(html).toContain('opacity:0.35')
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test -- src/presentation/react-shell/dev-mode/TileCanvas.test.ts`
Expected: FAIL because rendered tile skin does not yet include layer opacity

- [ ] **Step 3: Write minimal implementation**

```ts
function resolveCompositedTile(cellKey: string) {
  let result = { tileId: null as string | null, opacity: 1 }
  for (const layer of visibleLayers) {
    const nextTileId = resolveLayerTileId(layer.id, cellKey)
    if (nextTileId) {
      result = { tileId: nextTileId, opacity: layer.opacity }
    }
  }
  return result
}
```

```tsx
const composited = resolveCompositedTile(cellKey)

<span
  className="tile-skin tile-skin-pixel-asset"
  style={{
    opacity: composited.opacity,
    backgroundImage: `url(${pixelThumbnail})`,
  }}
/>
```

- [ ] **Step 4: Run tests and browser verification**

Run: `npm test -- src/presentation/react-shell/dev-mode/TileCanvas.test.ts`
Expected: PASS

Run: `npm run build`
Expected: PASS

Run: `npx vite preview --host 127.0.0.1 --port 4173`
Expected: preview starts on `4173` or next free port

Verify in browser:
- 隐藏 `art` 层后，下层 `ground` 恢复可见
- 调低 `art` 层到 `35%` 后，顶层 tile 变淡
- 切换当前编辑层不会重置显隐和透明度

- [ ] **Step 5: Commit**

```bash
git add src/presentation/react-shell/dev-mode/TileCanvas.tsx src/presentation/react-shell/dev-mode/TileCanvas.test.ts
git commit -m "feat: apply layer opacity in canvas rendering"
```
