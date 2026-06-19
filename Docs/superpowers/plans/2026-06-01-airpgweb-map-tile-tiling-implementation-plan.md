# AIRPGWeb Map Tile Tiling Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为地图中的像素素材增加“默认平铺 + 放置前临时覆盖”的单格内平铺语义，让小尺寸素材可以在单个标准格中按需重复铺满或按真实尺寸显示。

**Architecture:** 在素材元数据里新增 `defaultTiling`，在地图编辑会话态里新增 `tilePlacementTilingOverride`，再把这两个状态串到调色板和 `TileCanvas` 的渲染路径。最终只改单格内部渲染，不改地图格子数据结构和多格占地模型。

**Tech Stack:** React, TypeScript, Vite, Vitest

---

## File Structure

- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\asset-library\asset-library-types.ts`
  - 确保素材模型具备 `defaultTiling`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\tile-palette.ts`
  - 扩展像素素材条目，携带默认平铺信息
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\editor-reducer.ts`
  - 增加地图调色板平铺临时覆盖状态与 action
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\TilePalette.tsx`
  - 为像素素材项增加“平铺/不平铺/跟随默认”切换入口
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\TileCanvas.tsx`
  - 实现单格内非平铺与平铺两条渲染路径
- Test: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\editor-reducer.test.ts`
- Test: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\TileCanvas.test.ts`

### Task 1: 锁定默认平铺与临时覆盖的状态模型

**Files:**
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\editor-reducer.ts`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\tile-palette.ts`
- Test: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\editor-reducer.test.ts`

- [ ] **Step 1: 写失败测试，确认 reducer 能保存临时覆盖状态**

```ts
it('stores tile placement tiling override independently from selected tile id', () => {
  const state = createInitialEditorState(createEmptyMapAsset({ id: 'map-1', name: '草稿', width: 4, height: 4 }))
  const next = editorReducer(state, { type: 'set-tile-placement-tiling-override', value: true })

  expect(next.tilePlacementTilingOverride).toBe(true)
  expect(next.selectedTileId).toBe(state.selectedTileId)
})

it('exposes pixel asset default tiling in tile presets', () => {
  const groups = getTilePaletteGroups('ground', [
    {
      id: 'pixel-1',
      name: '地砖',
      layerId: 'ground',
      thumbnail: null,
      pixelWidth: 16,
      pixelHeight: 16,
      alignedPixelWidth: 16,
      alignedPixelHeight: 16,
      atomCols: 2,
      atomRows: 2,
      defaultTiling: true,
    },
  ])

  expect(groups[0].tiles?.[0].defaultTiling).toBe(true)
})
```

- [ ] **Step 2: 运行测试，确认当前状态字段缺失**

Run: `npm test -- --run src/domain/map-editor/editor-reducer.test.ts`

Expected: FAIL，缺少 `tilePlacementTilingOverride` action 或 `TilePreset.defaultTiling` 字段。

- [ ] **Step 3: 做最小实现**

```ts
export type EditorAction =
  | { type: 'set-tile-placement-tiling-override'; value: boolean | null }
```

```ts
export type EditorState = {
  // ...
  tilePlacementTilingOverride: boolean | null
}
```

```ts
case 'set-tile-placement-tiling-override':
  return {
    ...state,
    tilePlacementTilingOverride: action.value,
  }
```

```ts
export type TilePreset = {
  id: string
  label: string
  layerId: EditorLayerId
  preview: string
  family: string
  defaultTiling?: boolean
  // ...
}
```

- [ ] **Step 4: 再跑测试**

Run: `npm test -- --run src/domain/map-editor/editor-reducer.test.ts`

Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add src/domain/map-editor/editor-reducer.ts src/domain/map-editor/tile-palette.ts src/domain/map-editor/editor-reducer.test.ts
git commit -m "feat: add map tile tiling state model"
```

### Task 2: 给地图调色板增加“默认/平铺/不平铺”切换入口

**Files:**
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\TilePalette.tsx`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\App.css`
- Test: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\TilePalette.test.tsx`

- [ ] **Step 1: 写失败测试，锁定像素素材条目旁的平铺按钮**

```tsx
it('renders tiling controls for pixel asset presets', () => {
  const html = renderToStaticMarkup(
    <TilePalette
      groups={[{
        id: 'ground-default',
        label: '可用地块',
        tiles: [{ id: 'pixel-1', label: '地砖', layerId: 'ground', preview: '🖼', family: 'pixel-asset', defaultTiling: true }],
      }]}
      selectedTileId="pixel-1"
      tilingOverride={null}
      onSelect={() => {}}
      onSetTilingOverride={() => {}}
    />,
  )

  expect(html).toContain('跟随默认')
  expect(html).toContain('平铺')
  expect(html).toContain('不平铺')
})
```

- [ ] **Step 2: 运行测试，确认调色板还没有相关 UI**

Run: `npm test -- --run src/presentation/react-shell/dev-mode/TilePalette.test.tsx`

Expected: FAIL。

- [ ] **Step 3: 实现像素素材专属平铺切换**

```tsx
{tile.family === 'pixel-asset' ? (
  <div className="tile-palette-tiling">
    <button type="button" onClick={() => onSetTilingOverride(null)}>跟随默认</button>
    <button type="button" onClick={() => onSetTilingOverride(true)}>平铺</button>
    <button type="button" onClick={() => onSetTilingOverride(false)}>不平铺</button>
  </div>
) : null}
```

- [ ] **Step 4: 运行测试**

Run: `npm test -- --run src/presentation/react-shell/dev-mode/TilePalette.test.tsx`

Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add src/presentation/react-shell/dev-mode/TilePalette.tsx src/App.css src/presentation/react-shell/dev-mode/TilePalette.test.tsx
git commit -m "feat: add tile tiling controls to map palette"
```

### Task 3: 在 TileCanvas 中实现单格内平铺与非平铺渲染

**Files:**
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\TileCanvas.tsx`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\TileSkin.tsx`
- Test: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\TileCanvas.test.ts`

- [ ] **Step 1: 写失败测试，覆盖 16x16 进 32x32 单格时的两种路径**

```ts
it('renders a non-tiled pixel asset only once inside a 32x32 map cell', () => {
  const html = renderTileCanvasWithPixelAsset({ pixelWidth: 16, pixelHeight: 16, tiling: false, mapCellSize: 32 })
  expect(html).toContain('background-size:16px 16px')
  expect(html).not.toContain('background-repeat:repeat')
})

it('renders a tiled pixel asset repeatedly inside a 32x32 map cell', () => {
  const html = renderTileCanvasWithPixelAsset({ pixelWidth: 16, pixelHeight: 16, tiling: true, mapCellSize: 32 })
  expect(html).toContain('background-repeat:repeat')
  expect(html).toContain('background-size:16px 16px')
})
```

- [ ] **Step 2: 运行测试，确认当前只有单一渲染路径**

Run: `npm test -- --run src/presentation/react-shell/dev-mode/TileCanvas.test.ts`

Expected: FAIL。

- [ ] **Step 3: 实现单格内渲染分发**

```tsx
function resolveTileTiling(tileId: string) {
  const override = state.tilePlacementTilingOverride
  if (override !== null) {
    return override
  }
  return pixelAssetMetricsMap[tileId]?.defaultTiling ?? false
}
```

```tsx
const pixelStyle = isTiled
  ? {
      backgroundImage: `url(${pixelThumbnail})`,
      backgroundSize: `${metrics.pixelWidth}px ${metrics.pixelHeight}px`,
      backgroundRepeat: 'repeat' as const,
    }
  : {
      backgroundImage: `url(${pixelThumbnail})`,
      backgroundSize: `${metrics.pixelWidth}px ${metrics.pixelHeight}px`,
      backgroundRepeat: 'no-repeat' as const,
      width: `${metrics.pixelWidth}px`,
      height: `${metrics.pixelHeight}px`,
      left: 0,
      top: 0,
    }
```

- [ ] **Step 4: 运行测试**

Run: `npm test -- --run src/presentation/react-shell/dev-mode/TileCanvas.test.ts`

Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add src/presentation/react-shell/dev-mode/TileCanvas.tsx src/presentation/react-shell/dev-mode/TileSkin.tsx src/presentation/react-shell/dev-mode/TileCanvas.test.ts
git commit -m "feat: support tiled pixel asset rendering in map cells"
```

### Task 4: 回归验证与页面预览

**Files:**
- Verify only

- [ ] **Step 1: 跑相关测试**

Run: `npm test -- --run src/domain/map-editor/editor-reducer.test.ts src/presentation/react-shell/dev-mode/TileCanvas.test.ts src/presentation/react-shell/dev-mode/TilePalette.test.tsx`

Expected: PASS。

- [ ] **Step 2: 跑全量构建**

Run: `npm run build`

Expected: PASS。

- [ ] **Step 3: 打开预览页**

Run: `npm run preview -- --host 127.0.0.1 --port 4181`

Expected: 输出 `http://127.0.0.1:4181/`。

- [ ] **Step 4: 校验页面可达**

Run: `node -e "fetch('http://127.0.0.1:4181/').then(r=>console.log(r.status)).catch(e=>{console.error(e);process.exit(1)})"`

Expected: 输出 `200`。

- [ ] **Step 5: 提交**

```bash
git add .
git commit -m "chore: verify map tile tiling workflow"
```
