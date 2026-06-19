# AIRPGWeb Tile Editor Interaction Rework Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rework the AIRPGWeb tile editor so the brush submenu permanently includes `rectangle-fill`, the drawing screen hides world-composition UI, and the AI helper can drive a step-by-step house workflow that pauses for user confirmation at every stage.

**Architecture:** Keep the reducer-driven editor and overlay-based layout, extend the brush model to include filled rectangles, preserve live preview as the single interaction truth, and treat AI drawing as a staged command generator rather than freeform text. The screen continues to be drawing-first, while world-composition UI is removed only from the current page and AI house generation is constrained to `structure -> floor -> furniture` steps.

**Tech Stack:** React 19, TypeScript, Vite, Vitest, Playwright

---

## File Map

### New Files

- `Project/AIRPGWeb/src/domain/map-editor/ai-house-workflow.ts`
- `Project/AIRPGWeb/src/domain/map-editor/ai-house-workflow.test.ts`
- `Project/AIRPGWeb/src/domain/map-editor/editor-preview.ts`
- `Project/AIRPGWeb/src/domain/map-editor/editor-preview.test.ts`
- `Project/AIRPGWeb/src/domain/map-editor/editor-tool-state.ts`
- `Project/AIRPGWeb/src/domain/map-editor/editor-tool-state.test.ts`

### Modified Files

- `Project/AIRPGWeb/src/domain/map-editor/editor-reducer.ts`
- `Project/AIRPGWeb/src/domain/map-editor/editor-reducer.test.ts`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/AiAssistPanel.tsx`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/EditorToolbar.tsx`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/MapEditorScreen.tsx`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileCanvas.tsx`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TilePalette.tsx`
- `Project/AIRPGWeb/src/App.css`
- `Project/AIRPGWeb/tests/developer-mode.spec.ts`

### Responsibility Split

- `editor-tool-state.ts`: top-level tools, brush subtools, effective mode mapping
- `editor-preview.ts`: preview cell generation for brush drag, rectangle outline, rectangle fill, and rectangle erase
- `editor-reducer.ts`: canonical editor state, overlay state, preview state, AI staged workflow state, and commit actions
- `TileCanvas.tsx`: pointer gesture handling and preview rendering for manual tools
- `MapEditorScreen.tsx`: left tool rail, brush overlay, right canvas overlays, and removal of world-composition UI from the current page
- `AiAssistPanel.tsx`: provider config, prompt input, staged AI workflow controls, and per-step confirm/apply actions
- `ai-house-workflow.ts`: normalize AI step responses into `structure / floor / furniture` commands the editor can preview and apply
- `developer-mode.spec.ts`: regression proof for rectangle fill, removed world UI, and staged AI confirmation flow

## Task 1: Extend Tool State With Permanent Rectangle Fill

**Files:**
- Create: `Project/AIRPGWeb/src/domain/map-editor/editor-tool-state.ts`
- Create: `Project/AIRPGWeb/src/domain/map-editor/editor-tool-state.test.ts`
- Modify: `Project/AIRPGWeb/src/domain/map-editor/editor-reducer.ts`
- Modify: `Project/AIRPGWeb/src/domain/map-editor/editor-reducer.test.ts`

- [ ] **Step 1: Write failing tests for the approved brush model**

```ts
import { describe, expect, it } from 'vitest'
import {
  createDefaultToolState,
  getEffectivePaintMode,
  isBrushSubtool,
} from './editor-tool-state'

describe('editor-tool-state', () => {
  it('defaults to brush and rectangle eraser mode', () => {
    expect(createDefaultToolState()).toEqual({
      activeTool: 'brush',
      activeBrushSubtool: 'brush',
      eraserMode: 'rectangle-fill',
      isBrushOverlayOpen: false,
    })
  })

  it('accepts the permanent rectangle-fill brush subtool', () => {
    expect(isBrushSubtool('brush')).toBe(true)
    expect(isBrushSubtool('fill')).toBe(true)
    expect(isBrushSubtool('rectangle-outline')).toBe(true)
    expect(isBrushSubtool('rectangle-fill')).toBe(true)
    expect(isBrushSubtool('stroke')).toBe(false)
  })

  it('maps the active brush subtool to the effective paint mode', () => {
    expect(getEffectivePaintMode({
      activeTool: 'brush',
      activeBrushSubtool: 'rectangle-fill',
      eraserMode: 'rectangle-fill',
      isBrushOverlayOpen: false,
    })).toBe('rectangle-fill')
  })
})
```

- [ ] **Step 2: Run the focused test and verify it fails**

Run:

```bash
npm run test -- src/domain/map-editor/editor-tool-state.test.ts
```

Expected: FAIL because the helper file still excludes `rectangle-fill` from brush subtools.

- [ ] **Step 3: Implement the new tool helper**

```ts
export type TopLevelEditorTool = 'brush' | 'eraser' | 'picker'
export type BrushSubtool = 'brush' | 'fill' | 'rectangle-outline' | 'rectangle-fill'
export type EraserMode = 'rectangle-fill'

export type ToolState = {
  activeTool: TopLevelEditorTool
  activeBrushSubtool: BrushSubtool
  eraserMode: EraserMode
  isBrushOverlayOpen: boolean
}

export function createDefaultToolState(): ToolState {
  return {
    activeTool: 'brush',
    activeBrushSubtool: 'brush',
    eraserMode: 'rectangle-fill',
    isBrushOverlayOpen: false,
  }
}

export function isBrushSubtool(value: string): value is BrushSubtool {
  return ['brush', 'fill', 'rectangle-outline', 'rectangle-fill'].includes(value)
}

export function getEffectivePaintMode(state: ToolState) {
  if (state.activeTool === 'eraser') {
    return 'eraser-rectangle-fill' as const
  }

  if (state.activeTool === 'picker') {
    return 'picker' as const
  }

  return state.activeBrushSubtool
}
```

- [ ] **Step 4: Extend reducer state for rectangle fill and staged AI workflow**

```ts
export type AiWorkflowStepKind = 'structure' | 'floor' | 'furniture'

export type AiWorkflowStep = {
  kind: AiWorkflowStepKind
  summary: string
  commands: AiDrawCommand[]
}

export type AiWorkflowState = {
  prompt: string
  provider: string
  baseUrl: string
  apiKey: string
  model: string
  currentStep: AiWorkflowStep | null
  pendingSteps: AiWorkflowStep[]
  status: 'idle' | 'loading' | 'ready' | 'applying' | 'error'
  errorMessage: string | null
}
```

- [ ] **Step 5: Update reducer tests for brush mode and AI placeholders**

```ts
it('switches brush subtools including rectangle fill', () => {
  const map = createEmptyMapAsset({ id: 'map-1', name: '草稿', width: 4, height: 4 })
  let state = createInitialEditorState(map)

  state = editorReducer(state, { type: 'toggle-brush-overlay', open: true })
  state = editorReducer(state, { type: 'set-brush-subtool', subtool: 'rectangle-fill' })

  expect(state.activeTool).toBe('brush')
  expect(state.activeBrushSubtool).toBe('rectangle-fill')
  expect(state.isBrushOverlayOpen).toBe(false)
})

it('stores the current AI workflow step separately from future steps', () => {
  const map = createEmptyMapAsset({ id: 'map-1', name: '草稿', width: 4, height: 4 })
  let state = createInitialEditorState(map)

  state = editorReducer(state, {
    type: 'set-ai-workflow-steps',
    steps: [
      { kind: 'structure', summary: '骨架', commands: [] },
      { kind: 'floor', summary: '地板', commands: [] },
    ],
  })

  expect(state.aiWorkflow.currentStep?.kind).toBe('structure')
  expect(state.aiWorkflow.pendingSteps).toHaveLength(1)
})
```

- [ ] **Step 6: Run the tool-state and reducer tests**

Run:

```bash
npm run test -- src/domain/map-editor/editor-tool-state.test.ts src/domain/map-editor/editor-reducer.test.ts
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add src/domain/map-editor/editor-tool-state.ts src/domain/map-editor/editor-tool-state.test.ts src/domain/map-editor/editor-reducer.ts src/domain/map-editor/editor-reducer.test.ts
git commit -m "refactor: add rectangle fill to tile editor tool state"
```

## Task 2: Add Real-Time Preview And Commit Flow For Rectangle Fill

**Files:**
- Create: `Project/AIRPGWeb/src/domain/map-editor/editor-preview.ts`
- Create: `Project/AIRPGWeb/src/domain/map-editor/editor-preview.test.ts`
- Modify: `Project/AIRPGWeb/src/domain/map-editor/editor-reducer.ts`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileCanvas.tsx`
- Modify: `Project/AIRPGWeb/src/App.css`

- [ ] **Step 1: Write failing tests for filled-rectangle preview generation**

```ts
import { describe, expect, it } from 'vitest'
import {
  buildBrushPreviewCells,
  buildEraseRectanglePreviewCells,
  buildFillRectanglePreviewCells,
  buildOutlineRectanglePreviewCells,
} from './editor-preview'

describe('editor-preview', () => {
  it('builds a filled rectangle preview for paint mode', () => {
    expect(buildFillRectanglePreviewCells({ x: 1, y: 1 }, { x: 2, y: 2 }, 'ground-yard')).toEqual([
      { x: 1, y: 1, tileId: 'ground-yard' },
      { x: 2, y: 1, tileId: 'ground-yard' },
      { x: 1, y: 2, tileId: 'ground-yard' },
      { x: 2, y: 2, tileId: 'ground-yard' },
    ])
  })

  it('keeps erase rectangle behavior unchanged', () => {
    expect(buildEraseRectanglePreviewCells({ x: 1, y: 1 }, { x: 2, y: 2 })).toHaveLength(4)
  })
})
```

- [ ] **Step 2: Run the preview test and verify it fails**

Run:

```bash
npm run test -- src/domain/map-editor/editor-preview.test.ts
```

Expected: FAIL because `buildFillRectanglePreviewCells()` does not exist yet.

- [ ] **Step 3: Implement preview helpers for outline, fill, and erase rectangles**

```ts
export function buildFillRectanglePreviewCells(anchor: Point, hover: Point, tileId: string | null): PreviewCell[] {
  const minX = Math.min(anchor.x, hover.x)
  const maxX = Math.max(anchor.x, hover.x)
  const minY = Math.min(anchor.y, hover.y)
  const maxY = Math.max(anchor.y, hover.y)
  const cells: PreviewCell[] = []

  for (let y = minY; y <= maxY; y += 1) {
    for (let x = minX; x <= maxX; x += 1) {
      cells.push({ x, y, tileId })
    }
  }

  return cells
}
```

- [ ] **Step 4: Wire `rectangle-fill` into `TileCanvas.tsx` pointer flow**

```tsx
if (effectiveMode === 'rectangle-fill') {
  dispatch({ type: 'set-rectangle-anchor', x, y, mode: 'rectangle-fill' })
  dispatch({
    type: 'set-preview-cells',
    cells: buildFillRectanglePreviewCells({ x, y }, { x, y }, state.selectedTileId),
    kind: 'paint',
  })
  return
}
```

- [ ] **Step 5: Update move and release handlers to preview then commit full rectangles**

```tsx
if (state.rectanglePreview?.mode === 'rectangle-fill') {
  dispatch({
    type: 'set-preview-cells',
    cells: buildFillRectanglePreviewCells(state.rectanglePreview.anchor, { x, y }, state.selectedTileId),
    kind: 'paint',
  })
  return
}

if (state.rectanglePreview?.mode === 'rectangle-fill' && state.previewCells.length > 0) {
  dispatch({ type: 'apply-preview-cells', layerId: state.activeLayerId })
  dispatch({ type: 'clear-preview-cells' })
  return
}
```

- [ ] **Step 6: Add preview styling for filled paint ranges**

```css
.map-editor-cell-preview-paint {
  outline: 1px solid rgba(212, 168, 83, 0.45);
  outline-offset: -1px;
}

.map-editor-cell-preview-erase::after {
  content: '';
  position: absolute;
  inset: 0;
  background: rgba(208, 72, 72, 0.18);
  pointer-events: none;
}
```

- [ ] **Step 7: Run preview unit tests and targeted E2E**

Run:

```bash
npm run test -- src/domain/map-editor/editor-preview.test.ts
npm run test:e2e -- tests/developer-mode.spec.ts -g "rectangle fill"
```

Expected: PASS, and the rectangle fill preview remains visible before pointer release.

- [ ] **Step 8: Commit**

```bash
git add src/domain/map-editor/editor-preview.ts src/domain/map-editor/editor-preview.test.ts src/domain/map-editor/editor-reducer.ts src/presentation/react-shell/dev-mode/TileCanvas.tsx src/App.css
git commit -m "feat: add rectangle fill preview and commit flow"
```

## Task 3: Keep The Screen Drawing-Only And Remove World UI From This Page

**Files:**
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/EditorToolbar.tsx`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/MapEditorScreen.tsx`
- Modify: `Project/AIRPGWeb/src/App.css`
- Modify: `Project/AIRPGWeb/tests/developer-mode.spec.ts`

- [ ] **Step 1: Write failing E2E for drawing-only screen scope**

```ts
test('map editor keeps world composition UI out of the drawing screen', async ({ page }) => {
  await page.goto('/')
  await page.getByRole('button', { name: '开发者模式' }).click()
  await page.getByRole('button', { name: '地图绘制' }).click()

  await expect(page.getByRole('button', { name: '设为运行时地图' })).toHaveCount(0)
  await expect(page.getByTestId('world-placement-current')).toHaveCount(0)
  await expect(page.getByText('世界拼接')).toHaveCount(0)
})
```

- [ ] **Step 2: Run the failing E2E**

Run:

```bash
npm run test:e2e -- tests/developer-mode.spec.ts -g "drawing screen"
```

Expected: FAIL because the current page still renders world-composition content.

- [ ] **Step 3: Keep the compact toolbar and left rail layout, but drop world UI from `MapEditorScreen.tsx`**

```tsx
<div className="map-editor-secondary-panels">
  <MapBrowserPanel
    maps={maps}
    currentMapId={state.map.id}
    onOpen={handleOpenMap}
    onCreate={handleCreateMap}
  />
  <AiAssistPanel
    state={state.aiWorkflow}
    dispatch={dispatch}
  />
</div>
```

- [ ] **Step 4: Remove `WorldCompositionPanel` imports and rendering from the current page only**

```tsx
import { AiAssistPanel } from './AiAssistPanel'
import { MapBrowserPanel } from './MapBrowserPanel'
// remove WorldCompositionPanel import from this screen
```

- [ ] **Step 5: Update E2E to cover brush overlay plus removed world UI**

```ts
await page.getByRole('button', { name: '画笔' }).click()
await expect(page.getByTestId('map-editor-brush-overlay')).toBeVisible()
await expect(page.getByTestId('map-editor-overlay-layers')).toBeVisible()
await expect(page.getByTestId('map-editor-overlay-palette')).toBeVisible()
await expect(page.getByTestId('world-placement-current')).toHaveCount(0)
```

- [ ] **Step 6: Re-run the page-scope E2E**

Run:

```bash
npm run test:e2e -- tests/developer-mode.spec.ts -g "drawing screen"
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add src/presentation/react-shell/dev-mode/EditorToolbar.tsx src/presentation/react-shell/dev-mode/MapEditorScreen.tsx src/App.css tests/developer-mode.spec.ts
git commit -m "refactor: keep tile editor screen focused on drawing"
```

## Task 4: Add Staged AI House Workflow With Per-Step Confirmation

**Files:**
- Create: `Project/AIRPGWeb/src/domain/map-editor/ai-house-workflow.ts`
- Create: `Project/AIRPGWeb/src/domain/map-editor/ai-house-workflow.test.ts`
- Modify: `Project/AIRPGWeb/src/domain/map-editor/editor-reducer.ts`
- Modify: `Project/AIRPGWeb/src/domain/map-editor/editor-reducer.test.ts`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/AiAssistPanel.tsx`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/MapEditorScreen.tsx`
- Modify: `Project/AIRPGWeb/tests/developer-mode.spec.ts`

- [ ] **Step 1: Write failing tests for AI step normalization**

```ts
import { describe, expect, it } from 'vitest'
import { normalizeHouseWorkflow } from './ai-house-workflow'

describe('ai-house-workflow', () => {
  it('accepts only structure, floor, and furniture steps', () => {
    const workflow = normalizeHouseWorkflow({
      workflow: 'house-residence',
      steps: [
        { kind: 'structure', summary: '骨架', commands: [] },
        { kind: 'floor', summary: '地板', commands: [] },
        { kind: 'furniture', summary: '家具', commands: [] },
      ],
    })

    expect(workflow.steps.map((step) => step.kind)).toEqual(['structure', 'floor', 'furniture'])
  })
})
```

- [ ] **Step 2: Run the AI workflow test and verify it fails**

Run:

```bash
npm run test -- src/domain/map-editor/ai-house-workflow.test.ts
```

Expected: FAIL because the workflow normalizer does not exist yet.

- [ ] **Step 3: Implement the house workflow normalizer**

```ts
const validKinds = ['structure', 'floor', 'furniture'] as const

export function normalizeHouseWorkflow(input: unknown): HouseWorkflow {
  const parsed = houseWorkflowSchema.parse(input)

  return {
    workflow: 'house-residence',
    steps: parsed.steps.filter((step) => validKinds.includes(step.kind)),
  }
}
```

- [ ] **Step 4: Add reducer actions for AI load, preview, apply, and advance**

```ts
export type EditorAction =
  | { type: 'load-ai-workflow-start' }
  | { type: 'load-ai-workflow-success'; workflow: HouseWorkflow }
  | { type: 'load-ai-workflow-error'; message: string }
  | { type: 'preview-ai-current-step' }
  | { type: 'apply-ai-current-step'; layerId: EditorLayerId }
  | { type: 'advance-ai-step' }
```

- [ ] **Step 5: Redesign `AiAssistPanel.tsx` around provider config and staged confirmation**

```tsx
<section className="map-editor-panel">
  <h2>AI 绘制辅助</h2>
  <input aria-label="AI Provider" value={state.provider} onChange={...} />
  <input aria-label="Base URL" value={state.baseUrl} onChange={...} />
  <input aria-label="API Key" value={state.apiKey} onChange={...} />
  <input aria-label="Model" value={state.model} onChange={...} />
  <textarea aria-label="房屋需求" value={state.prompt} onChange={...} />
  <button type="button" className="menu-btn primary" onClick={handleGenerateHouseWorkflow}>生成房屋流程</button>

  {state.currentStep ? (
    <>
      <div>{state.currentStep.kind}</div>
      <p>{state.currentStep.summary}</p>
      <button type="button" className="menu-btn" onClick={handlePreviewCurrentStep}>预览当前步</button>
      <button type="button" className="menu-btn primary" onClick={handleApplyCurrentStep}>确认并应用当前步</button>
      <button type="button" className="menu-btn" onClick={handleSkipCurrentStep}>跳过当前步</button>
    </>
  ) : null}
</section>
```

- [ ] **Step 6: Map AI commands to existing manual tools instead of creating a second drawing pipeline**

```ts
function buildPreviewCellsFromAiCommands(commands: AiDrawCommand[]): PreviewCell[] {
  return commands.flatMap((command) => {
    if (command.tool === 'rectangle-outline') {
      return buildOutlineRectanglePreviewCells(command.anchor, command.hover, command.tileId)
    }

    if (command.tool === 'rectangle-fill') {
      return buildFillRectanglePreviewCells(command.anchor, command.hover, command.tileId)
    }

    if (command.tool === 'brush') {
      return buildBrushPreviewCells(command.cells, command.tileId)
    }

    return []
  })
}
```

- [ ] **Step 7: Write failing E2E for staged AI confirmation flow**

```ts
test('ai house workflow waits for user confirmation at every step', async ({ page }) => {
  await page.goto('/')
  await page.getByRole('button', { name: '开发者模式' }).click()
  await page.getByRole('button', { name: '地图绘制' }).click()

  await page.getByLabel('房屋需求').fill('铁匠的生活居所')
  await page.getByRole('button', { name: '生成房屋流程' }).click()
  await expect(page.getByText('structure')).toBeVisible()
  await page.getByRole('button', { name: '预览当前步' }).click()
  await page.getByRole('button', { name: '确认并应用当前步' }).click()
  await expect(page.getByText('floor')).toBeVisible()
})
```

- [ ] **Step 8: Run the AI tests and targeted E2E**

Run:

```bash
npm run test -- src/domain/map-editor/ai-house-workflow.test.ts src/domain/map-editor/editor-reducer.test.ts
npm run test:e2e -- tests/developer-mode.spec.ts -g "ai house workflow"
```

Expected: PASS, and the UI never applies `floor` or `furniture` before the user confirms the current step.

- [ ] **Step 9: Commit**

```bash
git add src/domain/map-editor/ai-house-workflow.ts src/domain/map-editor/ai-house-workflow.test.ts src/domain/map-editor/editor-reducer.ts src/domain/map-editor/editor-reducer.test.ts src/presentation/react-shell/dev-mode/AiAssistPanel.tsx src/presentation/react-shell/dev-mode/MapEditorScreen.tsx tests/developer-mode.spec.ts
git commit -m "feat: add staged AI house drawing workflow"
```

## Task 5: Full Regression And Preview Verification

**Files:**
- Modify: `Project/AIRPGWeb/tests/developer-mode.spec.ts`
- Review: `Docs/superpowers/specs/2026-05-31-airpgweb-tile-editor-interaction-rework-design.md`

- [ ] **Step 1: Add a final high-level interaction regression**

```ts
test('tile editor stays overlay-driven, drawing-first, and AI-step-confirmed', async ({ page }) => {
  await page.goto('/')
  await page.getByRole('button', { name: '开发者模式' }).click()
  await page.getByRole('button', { name: '地图绘制' }).click()

  await page.getByRole('button', { name: '画笔' }).click()
  await page.getByTestId('map-editor-brush-overlay').getByRole('button', { name: '填充矩形' }).click()
  await page.getByRole('button', { name: '地板层', exact: true }).click()
  await page.getByRole('button', { name: '草地' }).click()
  await page.getByTestId('tile-cell-1-1').hover()
  await page.mouse.down()
  await page.getByTestId('tile-cell-3-3').hover()
  await expect(page.getByTestId('tile-cell-2-2').locator('.tile-skin.tile-skin-ground-grass')).toBeVisible()
  await page.mouse.up()

  await expect(page.getByTestId('world-placement-current')).toHaveCount(0)
})
```

- [ ] **Step 2: Run all unit tests**

Run:

```bash
npm run test
```

Expected: PASS.

- [ ] **Step 3: Run full Playwright regression**

Run:

```bash
npm run test:e2e -- tests/developer-mode.spec.ts
```

Expected: PASS.

- [ ] **Step 4: Run production build**

Run:

```bash
npm run build
```

Expected: PASS.

- [ ] **Step 5: Re-open preview and verify the current URL**

Run:

```bash
powershell -ExecutionPolicy Bypass -File "g:\UEGameDevelopment\.trae\scripts\web-preview-guard.ps1"
```

Expected: one reachable local URL such as `http://127.0.0.1:5173/`.

- [ ] **Step 6: Sync spec names if implementation drifted**

```md
- Confirm final brush subtools remain:
  - `brush`
  - `fill`
  - `rectangle-outline`
  - `rectangle-fill`
- Confirm AI house workflow remains:
  - `structure`
  - `floor`
  - `furniture`
- If code names drift, update the design doc immediately.
```

- [ ] **Step 7: Commit**

```bash
git add tests/developer-mode.spec.ts Docs/superpowers/specs/2026-05-31-airpgweb-tile-editor-interaction-rework-design.md
git commit -m "test: verify rectangle fill and staged AI drawing workflow"
```

## Self-Review

### Spec Coverage

- 画笔常驻 `rectangle-fill`：Task 1, Task 2
- 实时预览与矩形提交：Task 2
- 当前页面移出世界拼接 UI：Task 3
- AI provider 配置与分步确认流程：Task 4
- AI 房屋流程限制为 `structure / floor / furniture`：Task 4
- 回归与预览验证：Task 5

### Placeholder Scan

- 本计划未使用 `TODO`、`TBD`、`implement later`、`fill in details`
- 每个任务都包含具体文件、测试、命令和提交建议
- 范围保持在房屋流程，不把村落级自动规划混入本轮

### Type Consistency

- 顶层工具统一为 `brush / eraser / picker`
- 画笔子工具统一为 `brush / fill / rectangle-outline / rectangle-fill`
- 橡皮默认模式统一为 `rectangle-fill`
- AI 房屋步骤统一为 `structure / floor / furniture`
- AI 与手工绘制共用同一命令层与 preview cell 流程
