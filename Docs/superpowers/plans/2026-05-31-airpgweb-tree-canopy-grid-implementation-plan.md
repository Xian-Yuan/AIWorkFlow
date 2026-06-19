# AIRPGWeb Tree Canopy Grid Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current placeholder tree preview with a topology-driven 9-slice canopy system that forms a rounded multi-tile crown and connects to the trunk at the bottom center.

**Architecture:** Keep tree work isolated from wall topology by introducing explicit canopy/trunk preview tile ids and a small preset layer that tells the preview page how each canopy piece behaves. Update preview-case data to assemble `3x3` and expanded crowns from center, edges, corners, and a bottom connector tile, then render them in the existing brainstorm page.

**Tech Stack:** TypeScript, Vite, Vitest, browser preview page

---

## File Structure

**Create**
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\tree-canopy-presets.ts`
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\tree-canopy-presets.test.ts`

**Modify**
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\wall-material-presets.ts`
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\wall-material-presets.test.ts`
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\wall-preview-cases.ts`
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\wall-preview-cases.test.ts`
- `g:\UEGameDevelopment\Project\AIRPGWeb\public\brainstorm\tile-style-direction-v6.html`

**Why these files**
- `tree-canopy-presets.ts`: one source of truth for canopy part kinds and their tile ids
- `wall-material-presets.ts`: maps canopy parts and trunk parts to visual classes
- `wall-preview-cases.ts`: swaps the current single canopy placeholder for real 9-slice trees
- `tile-style-direction-v6.html`: renders rounded crowns from the new tile ids

---

### Task 1: Define the canopy part system

**Files:**
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\tree-canopy-presets.ts`
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\tree-canopy-presets.test.ts`

- [ ] **Step 1: Write the failing tests**

```ts
import { describe, expect, it } from 'vitest'
import { getTreeCanopyPreset, listTreeCanopyTileIds } from './tree-canopy-presets'

describe('tree canopy presets', () => {
  it('defines the full nine-slice canopy set plus bottom connector', () => {
    expect(listTreeCanopyTileIds()).toEqual([
      'tree-canopy-center',
      'tree-canopy-edge-top',
      'tree-canopy-edge-right',
      'tree-canopy-edge-bottom',
      'tree-canopy-edge-left',
      'tree-canopy-corner-tl',
      'tree-canopy-corner-tr',
      'tree-canopy-corner-bl',
      'tree-canopy-corner-br',
      'tree-canopy-connector-bottom',
      'tree-trunk-top',
      'tree-trunk-mid',
    ])
  })

  it('marks the connector tile as the only canopy part that may touch the trunk', () => {
    expect(getTreeCanopyPreset('tree-canopy-connector-bottom')).toMatchObject({
      role: 'connector-bottom',
      trunkAnchor: 'bottom-center',
    })
  })
})
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
npm run test -- src/domain/map-editor/tree-canopy-presets.test.ts
```

Expected: FAIL because `tree-canopy-presets.ts` does not exist yet.

- [ ] **Step 3: Add the minimal preset module**

```ts
export type TreeCanopyRole =
  | 'center'
  | 'edge-top'
  | 'edge-right'
  | 'edge-bottom'
  | 'edge-left'
  | 'corner-tl'
  | 'corner-tr'
  | 'corner-bl'
  | 'corner-br'
  | 'connector-bottom'
  | 'trunk-top'
  | 'trunk-mid'

export type TreeCanopyPreset = {
  tileId: string
  role: TreeCanopyRole
  trunkAnchor: 'none' | 'bottom-center'
}

const TREE_CANOPY_PRESETS: TreeCanopyPreset[] = [
  { tileId: 'tree-canopy-center', role: 'center', trunkAnchor: 'none' },
  { tileId: 'tree-canopy-edge-top', role: 'edge-top', trunkAnchor: 'none' },
  { tileId: 'tree-canopy-edge-right', role: 'edge-right', trunkAnchor: 'none' },
  { tileId: 'tree-canopy-edge-bottom', role: 'edge-bottom', trunkAnchor: 'none' },
  { tileId: 'tree-canopy-edge-left', role: 'edge-left', trunkAnchor: 'none' },
  { tileId: 'tree-canopy-corner-tl', role: 'corner-tl', trunkAnchor: 'none' },
  { tileId: 'tree-canopy-corner-tr', role: 'corner-tr', trunkAnchor: 'none' },
  { tileId: 'tree-canopy-corner-bl', role: 'corner-bl', trunkAnchor: 'none' },
  { tileId: 'tree-canopy-corner-br', role: 'corner-br', trunkAnchor: 'none' },
  { tileId: 'tree-canopy-connector-bottom', role: 'connector-bottom', trunkAnchor: 'bottom-center' },
  { tileId: 'tree-trunk-top', role: 'trunk-top', trunkAnchor: 'none' },
  { tileId: 'tree-trunk-mid', role: 'trunk-mid', trunkAnchor: 'none' },
]

export function listTreeCanopyTileIds() {
  return TREE_CANOPY_PRESETS.map((item) => item.tileId)
}

export function getTreeCanopyPreset(tileId: string) {
  return TREE_CANOPY_PRESETS.find((item) => item.tileId === tileId) ?? null
}
```

- [ ] **Step 4: Run the tests again**

Run:

```bash
npm run test -- src/domain/map-editor/tree-canopy-presets.test.ts
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/domain/map-editor/tree-canopy-presets.ts src/domain/map-editor/tree-canopy-presets.test.ts
git commit -m "feat: define tree canopy slice presets"
```

---

### Task 2: Teach material presets about canopy parts

**Files:**
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\wall-material-presets.ts`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\wall-material-presets.test.ts`

- [ ] **Step 1: Write the failing tests for the new tree tile ids**

```ts
it('maps canopy center to the rounded canopy material', () => {
  expect(getTileMaterialPreset('tree-canopy-center')).toMatchObject({
    material: 'grass',
    surfaceClass: 'tile-skin-tree-canopy-center',
  })
})

it('maps trunk-top to a dedicated trunk material class', () => {
  expect(getTileMaterialPreset('tree-trunk-top')).toMatchObject({
    material: 'wood',
    surfaceClass: 'tile-skin-tree-trunk-top',
  })
})
```

- [ ] **Step 2: Run the targeted test to verify it fails**

Run:

```bash
npm run test -- src/domain/map-editor/wall-material-presets.test.ts
```

Expected: FAIL because the new tree tile ids are not mapped yet.

- [ ] **Step 3: Map every canopy part to a specific visual class**

```ts
if (tileId === 'tree-canopy-center') {
  return {
    material: 'grass',
    surfaceClass: 'tile-skin-tree-canopy-center',
    outlineClass: null,
    textureClass: 'tile-skin-texture-tree-canopy',
  }
}

if (tileId === 'tree-canopy-edge-top') {
  return {
    material: 'grass',
    surfaceClass: 'tile-skin-tree-canopy-edge-top',
    outlineClass: null,
    textureClass: 'tile-skin-texture-tree-canopy',
  }
}
```

- [ ] **Step 4: Add the rest of the new ids**

```ts
const treeCanopySurfaceMap: Record<string, string> = {
  'tree-canopy-center': 'tile-skin-tree-canopy-center',
  'tree-canopy-edge-top': 'tile-skin-tree-canopy-edge-top',
  'tree-canopy-edge-right': 'tile-skin-tree-canopy-edge-right',
  'tree-canopy-edge-bottom': 'tile-skin-tree-canopy-edge-bottom',
  'tree-canopy-edge-left': 'tile-skin-tree-canopy-edge-left',
  'tree-canopy-corner-tl': 'tile-skin-tree-canopy-corner-tl',
  'tree-canopy-corner-tr': 'tile-skin-tree-canopy-corner-tr',
  'tree-canopy-corner-bl': 'tile-skin-tree-canopy-corner-bl',
  'tree-canopy-corner-br': 'tile-skin-tree-canopy-corner-br',
  'tree-canopy-connector-bottom': 'tile-skin-tree-canopy-connector-bottom',
}
```

- [ ] **Step 5: Run the tests again**

Run:

```bash
npm run test -- src/domain/map-editor/wall-material-presets.test.ts
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add src/domain/map-editor/wall-material-presets.ts src/domain/map-editor/wall-material-presets.test.ts
git commit -m "feat: map tree canopy slices to material presets"
```

---

### Task 3: Replace placeholder trees in preview data

**Files:**
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\wall-preview-cases.ts`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\wall-preview-cases.test.ts`

- [ ] **Step 1: Write the failing test for a 3x3 crown and an expanded crown**

```ts
it('uses a 3x3 rounded crown for the small tree and a wider crown for the large tree', () => {
  expect(naturalPreviewCases.smallTree.cells).toEqual(
    expect.arrayContaining([
      expect.objectContaining({ tileId: 'tree-canopy-corner-tl' }),
      expect.objectContaining({ tileId: 'tree-canopy-center' }),
      expect.objectContaining({ tileId: 'tree-canopy-connector-bottom' }),
      expect.objectContaining({ tileId: 'tree-trunk-top' }),
    ]),
  )

  expect(naturalPreviewCases.largeTree.cells.filter((cell) => cell.tileId === 'tree-canopy-center').length).toBeGreaterThan(1)
})
```

- [ ] **Step 2: Run the targeted test to verify it fails**

Run:

```bash
npm run test -- src/domain/map-editor/wall-preview-cases.test.ts
```

Expected: FAIL because the current preview data still uses `preview-tree-canopy-large` and `preview-tree-trunk`.

- [ ] **Step 3: Replace the current tree preview data with 9-slice tile ids**

```ts
smallTree: {
  title: '3x3 树冠',
  width: 5,
  height: 6,
  cells: [
    { x: 1, y: 0, tileId: 'tree-canopy-corner-tl' },
    { x: 2, y: 0, tileId: 'tree-canopy-edge-top' },
    { x: 3, y: 0, tileId: 'tree-canopy-corner-tr' },
    { x: 1, y: 1, tileId: 'tree-canopy-edge-left' },
    { x: 2, y: 1, tileId: 'tree-canopy-center' },
    { x: 3, y: 1, tileId: 'tree-canopy-edge-right' },
    { x: 1, y: 2, tileId: 'tree-canopy-corner-bl' },
    { x: 2, y: 2, tileId: 'tree-canopy-connector-bottom' },
    { x: 3, y: 2, tileId: 'tree-canopy-corner-br' },
    { x: 2, y: 3, tileId: 'tree-trunk-top' },
    { x: 2, y: 4, tileId: 'tree-trunk-mid' },
  ],
}
```

- [ ] **Step 4: Add an expanded rounded crown case**

```ts
largeTree: {
  title: '5x4 扩展树冠',
  width: 8,
  height: 7,
  cells: [
    { x: 1, y: 0, tileId: 'tree-canopy-corner-tl' },
    { x: 2, y: 0, tileId: 'tree-canopy-edge-top' },
    { x: 3, y: 0, tileId: 'tree-canopy-edge-top' },
    { x: 4, y: 0, tileId: 'tree-canopy-edge-top' },
    { x: 5, y: 0, tileId: 'tree-canopy-corner-tr' },
    { x: 1, y: 1, tileId: 'tree-canopy-edge-left' },
    { x: 2, y: 1, tileId: 'tree-canopy-center' },
    { x: 3, y: 1, tileId: 'tree-canopy-center' },
    { x: 4, y: 1, tileId: 'tree-canopy-center' },
    { x: 5, y: 1, tileId: 'tree-canopy-edge-right' },
    { x: 2, y: 2, tileId: 'tree-canopy-edge-bottom' },
    { x: 3, y: 2, tileId: 'tree-canopy-connector-bottom' },
    { x: 4, y: 2, tileId: 'tree-canopy-edge-bottom' },
    { x: 3, y: 3, tileId: 'tree-trunk-top' },
    { x: 3, y: 4, tileId: 'tree-trunk-mid' },
  ],
}
```

- [ ] **Step 5: Run the tests again**

Run:

```bash
npm run test -- src/domain/map-editor/wall-preview-cases.test.ts
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add src/domain/map-editor/wall-preview-cases.ts src/domain/map-editor/wall-preview-cases.test.ts
git commit -m "feat: add rounded tree canopy preview cases"
```

---

### Task 4: Render canopy edges and corners in the preview page

**Files:**
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\public\brainstorm\tile-style-direction-v6.html`

- [ ] **Step 1: Update the preview page to recognize the new tree tile ids**

```js
if (cell.tileId.startsWith('tree-canopy-')) {
  classes.push('tree-canopy')
  classes.push(`tree-part-${cell.tileId.replace('tree-canopy-', '')}`)
  classes.push('material-grass')
}

if (cell.tileId === 'tree-trunk-top' || cell.tileId === 'tree-trunk-mid') {
  classes.push('tree-trunk')
  classes.push(`tree-part-${cell.tileId.replace('tree-', '')}`)
  classes.push('material-wood')
}
```

- [ ] **Step 2: Add rounded canopy CSS for center, edges, corners, and connector**

```css
.tile.tree-canopy.tree-part-center {
  background:
    radial-gradient(circle at 50% 50%, #6d955b 0 72%, transparent 74%),
    linear-gradient(90deg, #5f8750 0 100%);
}

.tile.tree-canopy.tree-part-edge-top {
  background:
    radial-gradient(circle at 50% 90%, #6d955b 0 74%, transparent 76%);
}

.tile.tree-canopy.tree-part-corner-tl {
  background:
    radial-gradient(circle at 82% 82%, #6d955b 0 74%, transparent 76%);
}
```

- [ ] **Step 3: Give the connector a crown-to-trunk transition**

```css
.tile.tree-canopy.tree-part-connector-bottom {
  background:
    radial-gradient(circle at 50% 28%, #6d955b 0 68%, transparent 70%),
    linear-gradient(180deg, transparent 0 46%, #56784a 46% 100%);
}

.tile.tree-trunk.tree-part-trunk-top::before {
  top: -34%;
  bottom: 0;
}
```

- [ ] **Step 4: Run the browser preview**

Open:

```text
http://127.0.0.1:5173/brainstorm/tile-style-direction-v6.html
```

Expected: one `3x3` rounded crown and one larger rounded crown that both connect to a centered trunk without gaps.

- [ ] **Step 5: Commit**

```bash
git add public/brainstorm/tile-style-direction-v6.html
git commit -m "feat: render rounded tree canopy slices in preview"
```

---

### Task 5: Verify and checkpoint

**Files:**
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\wall-material-presets.ts` (if needed)
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\wall-preview-cases.ts` (if needed)
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\public\brainstorm\tile-style-direction-v6.html` (if needed)

- [ ] **Step 1: Run focused automated verification**

Run:

```bash
npm run test -- src/domain/map-editor/tree-canopy-presets.test.ts src/domain/map-editor/wall-material-presets.test.ts src/domain/map-editor/wall-preview-cases.test.ts
npx playwright test tests/developer-mode.spec.ts --grep "map editor filters palette by active layer and paints selected tile|structure palette groups wall tiles before showing detailed variants"
npm run build
```

Expected: all PASS.

- [ ] **Step 2: Confirm the preview page still loads without browser errors**

Open:

```text
http://127.0.0.1:5173/brainstorm/tile-style-direction-v6.html
```

Expected: page loads and shows both rounded trees.

- [ ] **Step 3: Commit**

```bash
git add public/brainstorm/tile-style-direction-v6.html src/domain/map-editor/tree-canopy-presets.ts src/domain/map-editor/tree-canopy-presets.test.ts src/domain/map-editor/wall-material-presets.ts src/domain/map-editor/wall-material-presets.test.ts src/domain/map-editor/wall-preview-cases.ts src/domain/map-editor/wall-preview-cases.test.ts
git commit -m "test: verify tree canopy grid preview workflow"
```

---

## Self-Review

### Spec coverage
- Nine-slice canopy parts: Task 1
- Bottom-center trunk anchor: Tasks 1 and 3
- Rounded grouped silhouette: Task 4
- `3x3` and expanded crown examples: Task 3
- Explicit anti-gap canopy-to-trunk transition: Tasks 3 and 4

### Placeholder scan
- No `TODO`, `TBD`, or vague “later” instructions remain
- Every task contains exact files, code snippets, commands, and expected outcomes

### Type consistency
- Tree tile ids are introduced once in `tree-canopy-presets.ts` and reused in material mapping, preview cases, and preview rendering
- `tree-canopy-connector-bottom`, `tree-trunk-top`, and `tree-trunk-mid` are used consistently across all tasks

---

Plan complete and saved to `Docs/superpowers/plans/2026-05-31-airpgweb-tree-canopy-grid-implementation-plan.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using `executing-plans`, batch execution with checkpoints

**Which approach?**
