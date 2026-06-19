# AIRPGWeb Pixel Precise Paint And Grid Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为素材库像素画板补齐可用的 `Ctrl + 滚轮` 缩放、始终显示的单像素细网格，以及 `1-8` 的 `NxN` 正方形像素笔刷。

**Architecture:** 保留当前“每个像素一个 DOM 单元”的画板实现，只对缩放事件绑定、网格视觉层次和笔刷尺寸状态做增量修复。缩放继续复用 `canvasZoom`，绘制继续复用 reducer，只把 `brushSize` 扩展到 `1-8` 并用测试锁定单像素与边界裁切语义。

**Tech Stack:** React 19, TypeScript, Vite, Vitest

---

### Task 1: 扩展笔刷尺寸到 1-8 并锁定像素级绘制语义

**Files:**
- Modify: `Project/AIRPGWeb/src/domain/asset-library/pixel-editor-reducer.ts`
- Modify: `Project/AIRPGWeb/src/domain/asset-library/pixel-editor-reducer.test.ts`

- [ ] **Step 1: 写失败测试**

在 `Project/AIRPGWeb/src/domain/asset-library/pixel-editor-reducer.test.ts` 追加以下测试：

```ts
it('supports brush sizes from 1 through 8 and paints exactly one pixel when size is 1', () => {
  const asset = createEmptyPixelAsset({
    id: 'asset-7',
    name: '单像素测试',
    layerId: 'ground',
    previewTileSize: 16,
  })
  let state = createInitialPixelEditorState(asset)

  state = pixelEditorReducer(state, { type: 'set-brush-size', size: 1 })
  state = pixelEditorReducer(state, { type: 'set-color', color: '#ff0000' })
  state = pixelEditorReducer(state, { type: 'paint-at', x: 3, y: 4 })

  const filled = state.asset.pixels.filter((pixel) => pixel.color === '#ff0000')
  expect(filled).toHaveLength(1)
  expect(filled.map((pixel) => `${pixel.x}:${pixel.y}`)).toEqual(['3:4'])
})

it('clips an 8x8 brush to the asset bounds instead of painting out of range', () => {
  const asset = createEmptyPixelAsset({
    id: 'asset-8',
    name: '边界裁切',
    layerId: 'ground',
    previewTileSize: 8,
  })
  let state = createInitialPixelEditorState(asset)

  state = pixelEditorReducer(state, { type: 'set-brush-size', size: 8 })
  state = pixelEditorReducer(state, { type: 'set-color', color: '#00ff00' })
  state = pixelEditorReducer(state, { type: 'paint-at', x: 6, y: 6 })

  const filled = state.asset.pixels.filter((pixel) => pixel.color === '#00ff00')
  expect(filled).toHaveLength(4)
  expect(filled.map((pixel) => `${pixel.x}:${pixel.y}`).sort()).toEqual(['6:6', '6:7', '7:6', '7:7'])
})

it('uses the same 8x8 square size rule for erasing', () => {
  const asset = createEmptyPixelAsset({
    id: 'asset-9',
    name: '橡皮规则',
    layerId: 'ground',
    previewTileSize: 16,
  })
  let state = createInitialPixelEditorState(asset)

  state = pixelEditorReducer(state, { type: 'set-brush-size', size: 4 })
  state = pixelEditorReducer(state, { type: 'set-color', color: '#123456' })
  state = pixelEditorReducer(state, { type: 'paint-at', x: 1, y: 1 })
  state = pixelEditorReducer(state, { type: 'set-tool', tool: 'eraser' })
  state = pixelEditorReducer(state, { type: 'set-brush-size', size: 4 })
  state = pixelEditorReducer(state, { type: 'paint-at', x: 1, y: 1 })

  expect(state.asset.pixels.filter((pixel) => pixel.color === '#123456')).toHaveLength(0)
})
```

- [ ] **Step 2: 跑测试确认失败**

Run:

```bash
npm test -- --run src/domain/asset-library/pixel-editor-reducer.test.ts
```

Expected: FAIL，原因是 `set-brush-size` 目前只接受 `1 | 2 | 3`，新测试无法通过。

- [ ] **Step 3: 写最小实现**

在 `Project/AIRPGWeb/src/domain/asset-library/pixel-editor-reducer.ts` 做以下最小修改：

```ts
type PixelBrushSize = 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8

export type PixelEditorState = {
  // ...
  brushSize: PixelBrushSize
  // ...
}

export type PixelEditorAction =
  // ...
  | { type: 'set-brush-size'; size: PixelBrushSize }
```

并把 `paintSquare()` 签名改为：

```ts
function paintSquare(
  pixels: PixelCell[],
  width: number,
  height: number,
  x: number,
  y: number,
  size: PixelBrushSize,
  color: string | null,
) {
```

其余绘制逻辑保持当前边界裁切实现不变。

- [ ] **Step 4: 跑测试确认通过**

Run:

```bash
npm test -- --run src/domain/asset-library/pixel-editor-reducer.test.ts
```

Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add src/domain/asset-library/pixel-editor-reducer.ts src/domain/asset-library/pixel-editor-reducer.test.ts
git commit -m "feat: expand pixel brush size to 8"
```

### Task 2: 在属性面板与画板样式中落地 1-8 笔刷和始终显示的单像素细网格

**Files:**
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/PixelEditorInspector.tsx`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/PixelEditorCanvas.tsx`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/asset-library.css`

- [ ] **Step 1: 写失败测试**

创建组件静态渲染测试 `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/PixelEditorCanvas.test.tsx`：

```tsx
import { createElement } from 'react'
import { renderToStaticMarkup } from 'react-dom/server'
import { describe, expect, it, vi } from 'vitest'
import { createEmptyPixelAsset } from '../../../domain/asset-library/asset-library-types'
import { createInitialPixelEditorState } from '../../../domain/asset-library/pixel-editor-reducer'
import { PixelEditorCanvas } from './PixelEditorCanvas'
import { PixelEditorInspector } from './PixelEditorInspector'

describe('Pixel editor UI', () => {
  it('renders fine-grid and group-grid hooks on the pixel canvas', () => {
    const state = createInitialPixelEditorState(
      createEmptyPixelAsset({
        id: 'asset-ui-1',
        name: '网格测试',
        layerId: 'ground',
        previewTileSize: 16,
      }),
    )

    const html = renderToStaticMarkup(createElement(PixelEditorCanvas, { state, dispatch: vi.fn() }))
    expect(html).toContain('data-preview-group-size="2"')
    expect(html).toContain('pixel-editor-cell')
  })

  it('renders brush size options through 8 in the inspector', () => {
    const state = createInitialPixelEditorState(
      createEmptyPixelAsset({
        id: 'asset-ui-2',
        name: '粗细测试',
        layerId: 'ground',
        previewTileSize: 16,
      }),
    )

    const html = renderToStaticMarkup(
      createElement(PixelEditorInspector, { state, dispatch: vi.fn(), onSave: vi.fn() }),
    )

    expect(html).toContain('<option value="8">8</option>')
  })
})
```

- [ ] **Step 2: 跑测试确认失败**

Run:

```bash
npm test -- --run src/presentation/react-shell/dev-mode/PixelEditorCanvas.test.tsx
```

Expected: FAIL，原因是 `PixelEditorInspector` 目前只渲染到 `3`。

- [ ] **Step 3: 写最小实现**

在 `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/PixelEditorInspector.tsx` 把粗细下拉改为 `1-8`：

```tsx
onChange={(event) =>
  dispatch({ type: 'set-brush-size', size: Number(event.target.value) as 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 })
}
```

并补齐选项：

```tsx
<option value="1">1</option>
<option value="2">2</option>
<option value="3">3</option>
<option value="4">4</option>
<option value="5">5</option>
<option value="6">6</option>
<option value="7">7</option>
<option value="8">8</option>
```

在 `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/asset-library.css` 明确两层网格视觉：

```css
.pixel-editor-cell {
  width: var(--pixel-size);
  height: var(--pixel-size);
  border: 0;
  border-right: 1px solid rgba(240, 230, 210, 0.12);
  border-bottom: 1px solid rgba(240, 230, 210, 0.12);
  box-shadow: inset 1px 0 0 rgba(255, 255, 255, 0.04), inset 0 1px 0 rgba(255, 255, 255, 0.04);
  padding: 0;
}

.pixel-editor-cell.group-edge-x {
  border-right: 2px solid rgba(212, 168, 83, 0.55);
}

.pixel-editor-cell.group-edge-y {
  border-bottom: 2px solid rgba(212, 168, 83, 0.55);
}
```

在 `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/PixelEditorCanvas.tsx` 保持 `group-edge-x/group-edge-y` 计算逻辑不变，只确保 `button` 单元持续作为每个真实像素的交互实体。

- [ ] **Step 4: 跑测试确认通过**

Run:

```bash
npm test -- --run src/presentation/react-shell/dev-mode/PixelEditorCanvas.test.tsx
```

Expected: PASS

- [ ] **Step 5: 检查诊断**

确认以下文件无新增诊断：

```text
src/presentation/react-shell/dev-mode/PixelEditorInspector.tsx
src/presentation/react-shell/dev-mode/PixelEditorCanvas.tsx
src/presentation/react-shell/dev-mode/asset-library.css
src/presentation/react-shell/dev-mode/PixelEditorCanvas.test.tsx
```

- [ ] **Step 6: 提交**

```bash
git add src/presentation/react-shell/dev-mode/PixelEditorInspector.tsx src/presentation/react-shell/dev-mode/PixelEditorCanvas.tsx src/presentation/react-shell/dev-mode/asset-library.css src/presentation/react-shell/dev-mode/PixelEditorCanvas.test.tsx
git commit -m "feat: show precise pixel grid and brush sizes"
```

### Task 3: 修正 Ctrl+滚轮缩放生效路径并完成页面验证

**Files:**
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/pixel-editor-wheel-zoom.ts`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/pixel-editor-wheel-zoom.test.ts`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/PixelEditorCanvas.tsx`

- [ ] **Step 1: 写失败测试**

在 `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/pixel-editor-wheel-zoom.test.ts` 追加：

```ts
it('ignores zero-delta ctrl wheel events so zoom only changes on real wheel movement', () => {
  expect(getNextCanvasZoomFromWheel({ canvasZoom: 18, deltaY: 0, ctrlKey: true })).toBe(18)
})
```

- [ ] **Step 2: 跑测试确认失败**

Run:

```bash
npm test -- --run src/presentation/react-shell/dev-mode/pixel-editor-wheel-zoom.test.ts
```

Expected: FAIL，原因是当前实现会把 `deltaY = 0` 当成缩小处理。

- [ ] **Step 3: 写最小实现**

在 `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/pixel-editor-wheel-zoom.ts` 改为：

```ts
export function getNextCanvasZoomFromWheel({ canvasZoom, deltaY, ctrlKey }: WheelZoomInput) {
  if (!ctrlKey) {
    return null
  }

  if (deltaY === 0) {
    return canvasZoom
  }

  return canvasZoom + (deltaY < 0 ? 2 : -2)
}
```

在 `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/PixelEditorCanvas.tsx` 中保留：

```tsx
function handleWheelZoom(event: React.WheelEvent<HTMLDivElement>) {
  const nextZoom = getNextCanvasZoomFromWheel({
    canvasZoom: state.canvasZoom,
    deltaY: event.deltaY,
    ctrlKey: event.ctrlKey,
  })

  if (nextZoom === null) {
    return
  }

  event.preventDefault()
  dispatch({ type: 'set-canvas-zoom', zoom: nextZoom })
}
```

这样 `Ctrl + 滚轮` 与按钮继续共用同一个 `canvasZoom`。

- [ ] **Step 4: 跑相关测试**

Run:

```bash
npm test -- --run src/presentation/react-shell/dev-mode/pixel-editor-wheel-zoom.test.ts src/domain/asset-library/pixel-editor-reducer.test.ts src/presentation/react-shell/dev-mode/PixelEditorCanvas.test.tsx
```

Expected: PASS

- [ ] **Step 5: 跑全量测试与构建**

Run:

```bash
npm test -- --run
npm run build
```

Expected: 全量测试通过，构建退出码 `0`

- [ ] **Step 6: 重新打开页面并验证**

Run:

```bash
npx vite preview --host 127.0.0.1 --port 4179 --strictPort
node -e "fetch('http://127.0.0.1:4179/').then((r)=>{console.log(r.status);process.exit(r.ok?0:1)}).catch((e)=>{console.error(e);process.exit(1)})"
```

Expected:

```text
http://127.0.0.1:4179/
200
```

手动确认：

```text
1. 按住 Ctrl + 滚轮时画板缩放生效
2. 未按 Ctrl 时滚轮保持滚动容器行为
3. 细网格始终可见
4. brushSize=1 时只改一个像素
5. brushSize=8 时一次覆盖 8x8 区块
```

- [ ] **Step 7: 提交**

```bash
git add src/presentation/react-shell/dev-mode/pixel-editor-wheel-zoom.ts src/presentation/react-shell/dev-mode/pixel-editor-wheel-zoom.test.ts src/presentation/react-shell/dev-mode/PixelEditorCanvas.tsx src/presentation/react-shell/dev-mode/PixelEditorCanvas.test.tsx src/domain/asset-library/pixel-editor-reducer.ts src/domain/asset-library/pixel-editor-reducer.test.ts src/presentation/react-shell/dev-mode/PixelEditorInspector.tsx src/presentation/react-shell/dev-mode/asset-library.css
git commit -m "feat: improve precise pixel painting workflow"
```
