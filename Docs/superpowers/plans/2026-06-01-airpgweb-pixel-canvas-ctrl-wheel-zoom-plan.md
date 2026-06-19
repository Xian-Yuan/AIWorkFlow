# AIRPGWeb Pixel Canvas Ctrl Wheel Zoom Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为素材库像素画板增加与地图绘制一致的 `Ctrl + 滚轮` 缩放，同时保留现有按钮作为备用入口。

**Architecture:** 复用现有 `canvasZoom` 状态和 `set-canvas-zoom` action，不新增新的缩放状态。缩放逻辑只落在 `PixelEditorCanvas` 的画板容器上，`Ctrl + 滚轮` 时阻止浏览器默认缩放，普通滚轮继续保留容器滚动。

**Tech Stack:** React 19, TypeScript, Vite, Vitest

---

### Task 1: 补齐缩放行为测试

**Files:**
- Modify: `Project/AIRPGWeb/src/domain/asset-library/pixel-editor-reducer.test.ts`
- Create: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/PixelEditorCanvas.test.tsx`

- [ ] **Step 1: 写失败测试**

```tsx
import { createElement } from 'react'
import { describe, expect, it, vi } from 'vitest'
import { renderToStaticMarkup } from 'react-dom/server'
import { createEmptyPixelAsset } from '../../../domain/asset-library/asset-library-types'
import { createInitialPixelEditorState } from '../../../domain/asset-library/pixel-editor-reducer'
import { PixelEditorCanvas } from './PixelEditorCanvas'

describe('PixelEditorCanvas', () => {
  it('renders the current canvas zoom value for button and wheel paths', () => {
    const state = createInitialPixelEditorState(
      createEmptyPixelAsset({
        id: 'zoom-canvas',
        name: '缩放画板',
        layerId: 'ground',
        previewTileSize: 16,
      }),
    )

    const html = renderToStaticMarkup(
      createElement(PixelEditorCanvas, {
        state,
        dispatch: vi.fn(),
      }),
    )

    expect(html).toContain('画板缩放 18px')
  })
})
```

- [ ] **Step 2: 跑测试确认失败**

Run:

```bash
npm test -- --run src/presentation/react-shell/dev-mode/PixelEditorCanvas.test.tsx
```

Expected: 当前若测试文件不存在则失败，证明测试目标尚未落地。

- [ ] **Step 3: 写最小测试实现文件**

```tsx
import { createElement } from 'react'
import { renderToStaticMarkup } from 'react-dom/server'
import { describe, expect, it, vi } from 'vitest'
import { createEmptyPixelAsset } from '../../../domain/asset-library/asset-library-types'
import { createInitialPixelEditorState } from '../../../domain/asset-library/pixel-editor-reducer'
import { PixelEditorCanvas } from './PixelEditorCanvas'

describe('PixelEditorCanvas', () => {
  it('renders the current canvas zoom value for button and wheel paths', () => {
    const state = createInitialPixelEditorState(
      createEmptyPixelAsset({
        id: 'zoom-canvas',
        name: '缩放画板',
        layerId: 'ground',
        previewTileSize: 16,
      }),
    )

    const html = renderToStaticMarkup(
      createElement(PixelEditorCanvas, {
        state,
        dispatch: vi.fn(),
      }),
    )

    expect(html).toContain('画板缩放 18px')
  })
})
```

- [ ] **Step 4: 跑测试确认通过**

Run:

```bash
npm test -- --run src/presentation/react-shell/dev-mode/PixelEditorCanvas.test.tsx
```

Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add src/presentation/react-shell/dev-mode/PixelEditorCanvas.test.tsx
git commit -m "test: cover pixel canvas zoom display"
```

### Task 2: 接入 Ctrl + 滚轮缩放

**Files:**
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/PixelEditorCanvas.tsx`

- [ ] **Step 1: 写失败测试说明**

把 Task 1 的测试保留，同时新增一个最小的行为断言目标:

```tsx
// 目标行为：
// - Ctrl + wheel -> dispatch set-canvas-zoom
// - plain wheel -> no dispatch
```

由于当前组件测试基于静态渲染，无法直接触发事件，因此本任务用“实现后页面验证 + 现有 zoom 状态回归测试”作为落地验证。

- [ ] **Step 2: 实现最小缩放逻辑**

在 `PixelEditorCanvas.tsx` 中补充：

```tsx
function handleWheelZoom(event: React.WheelEvent<HTMLDivElement>) {
  if (!event.ctrlKey) {
    return
  }

  event.preventDefault()
  dispatch({
    type: 'set-canvas-zoom',
    zoom: state.canvasZoom + (event.deltaY < 0 ? 2 : -2),
  })
}
```

并把它挂到画板容器：

```tsx
<div
  className="pixel-editor-board-wrap"
  onWheel={handleWheelZoom}
  onPointerUp={handlePointerUp}
  onPointerLeave={() => {
    if (isPointerDownRef.current) {
      handlePointerUp()
    }
  }}
>
```

- [ ] **Step 3: 跑相关测试**

Run:

```bash
npm test -- --run src/domain/asset-library/pixel-editor-reducer.test.ts src/presentation/react-shell/dev-mode/PixelEditorCanvas.test.tsx
```

Expected: PASS

- [ ] **Step 4: 检查诊断**

确认以下文件无新增诊断：

```text
src/presentation/react-shell/dev-mode/PixelEditorCanvas.tsx
```

- [ ] **Step 5: 提交**

```bash
git add src/presentation/react-shell/dev-mode/PixelEditorCanvas.tsx src/presentation/react-shell/dev-mode/PixelEditorCanvas.test.tsx
git commit -m "feat: add ctrl wheel zoom to pixel canvas"
```

### Task 3: 全量验证与页面预览

**Files:**
- Verify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/PixelEditorCanvas.tsx`
- Verify: `Project/AIRPGWeb/src/domain/asset-library/pixel-editor-reducer.test.ts`

- [ ] **Step 1: 跑全量测试**

Run:

```bash
npm test -- --run
```

Expected: all tests pass

- [ ] **Step 2: 跑构建**

Run:

```bash
npm run build
```

Expected: exit code `0`

- [ ] **Step 3: 重新打开预览页**

Run:

```bash
npx vite preview --host 127.0.0.1 --port 4177 --strictPort
```

Expected: 输出 `http://127.0.0.1:4177/`

- [ ] **Step 4: 验证页面可访问**

Run:

```bash
node -e "fetch('http://127.0.0.1:4177/').then((r)=>{console.log(r.status);process.exit(r.ok?0:1)}).catch((e)=>{console.error(e);process.exit(1)})"
```

Expected: 输出 `200`

- [ ] **Step 5: 手动回归检查**

在页面中确认：

```text
1. 素材库画板按住 Ctrl + 滚轮可以放大/缩小
2. 未按 Ctrl 时，滚轮仍然滚动画板容器
3. 缩小画板 / 放大画板按钮仍然可用
4. 放大后仍可点击单个真实像素绘制
```

- [ ] **Step 6: 提交**

```bash
git add src/presentation/react-shell/dev-mode/PixelEditorCanvas.tsx src/presentation/react-shell/dev-mode/PixelEditorCanvas.test.tsx
git commit -m "test: verify pixel canvas ctrl wheel zoom"
```
