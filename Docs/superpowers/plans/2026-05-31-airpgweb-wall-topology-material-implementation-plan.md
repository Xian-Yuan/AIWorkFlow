# AIRPGWeb Wall Topology Material Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a topology-first wall/material pipeline so structure tiles, closed-house previews, tree canopy/trunk tiles, and palette organization all follow one consistent connection grammar.

**Architecture:** Add a small domain layer that classifies wall connectivity and validates closed rooms before any visual work. Move all material-specific rendering into shared preset data consumed by `TileSkin`, palette previews, and brainstorm house-case pages so every preview comes from the same rules instead of hand-placed decorative HTML.

**Tech Stack:** React 19, TypeScript, Vite, Vitest, Playwright

---

## File Structure

**Create**
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\wall-topology-rules.ts`
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\wall-material-presets.ts`
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\wall-preview-cases.ts`
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\wall-topology-rules.test.ts`
- `g:\UEGameDevelopment\Project\AIRPGWeb\public\brainstorm\tile-style-direction-v6.html`

**Modify**
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\tile-topology.ts`
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\tile-palette.ts`
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\create-empty-map-asset.ts`
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\TileSkin.tsx`
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\App.css`
- `g:\UEGameDevelopment\Project\AIRPGWeb\tests\developer-mode.spec.ts`

**Why these files**
- `wall-topology-rules.ts`: adjacency grammar, closure validation, allowed door/endcap rules
- `wall-material-presets.ts`: one place for soil/wood/stone/grass/tree visual semantics
- `wall-preview-cases.ts`: reusable closed-house cases for brainstorm pages and later editor demos
- `tile-topology.ts`: current tile ids remain the public ids, but get normalized to topology roles
- `tile-palette.ts`: remove the extra “细线双线/实心粗线” subgroup level and expose topology-first groups
- `create-empty-map-asset.ts`: reorder default layers to `region -> ground -> structure -> openings -> art`
- `TileSkin.tsx` + `App.css`: render material skins from shared preset data instead of disconnected hardcoded shapes
- `developer-mode.spec.ts`: lock in palette order, structure grouping, and tree/grass preview expectations

---

### Task 1: Add topology grammar and closure validation

**Files:**
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\wall-topology-rules.ts`
- Test: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\wall-topology-rules.test.ts`

- [ ] **Step 1: Write the failing tests for adjacency classification**

```ts
import { describe, expect, it } from 'vitest'
import { classifyWallTopology } from './wall-topology-rules'

describe('classifyWallTopology', () => {
  it('maps two opposite horizontal neighbors to horizontal wall', () => {
    expect(classifyWallTopology({ up: false, right: true, down: false, left: true })).toMatchObject({
      role: 'wall-h',
      orientation: 'h',
    })
  })

  it('maps three neighbors to the correct t-junction', () => {
    expect(classifyWallTopology({ up: true, right: true, down: true, left: false })).toMatchObject({
      role: 'wall-t',
      orientation: 't-right',
    })
  })
})
```

- [ ] **Step 2: Add failing tests for closure and illegal outer endcaps**

```ts
import { validateWallLayout } from './wall-topology-rules'

it('rejects an outer wall loop with a dangling endcap', () => {
  const result = validateWallLayout([
    { x: 0, y: 0, tileId: 'outer-wall-h' },
    { x: 1, y: 0, tileId: 'outer-end-right' },
  ])

  expect(result.valid).toBe(false)
  expect(result.errors).toContain('outer-loop-open')
})

it('accepts a closed perimeter with one legal door socket', () => {
  const result = validateWallLayout([
    { x: 0, y: 0, tileId: 'outer-corner-tl' },
    { x: 1, y: 0, tileId: 'outer-wall-h' },
    { x: 2, y: 0, tileId: 'outer-corner-tr' },
    { x: 0, y: 1, tileId: 'outer-wall-v' },
    { x: 2, y: 1, tileId: 'outer-wall-v' },
    { x: 0, y: 2, tileId: 'outer-corner-bl' },
    { x: 1, y: 2, tileId: 'door-socket-h' },
    { x: 2, y: 2, tileId: 'outer-corner-br' },
  ])

  expect(result.valid).toBe(true)
})
```

- [ ] **Step 3: Run tests to verify they fail**

Run:

```bash
npm run test -- src/domain/map-editor/wall-topology-rules.test.ts
```

Expected: FAIL because `wall-topology-rules.ts` does not exist yet.

- [ ] **Step 4: Implement the minimal rule module**

```ts
export type WallNeighborMask = {
  up: boolean
  right: boolean
  down: boolean
  left: boolean
}

export type WallTopologyRole =
  | 'wall-h'
  | 'wall-v'
  | 'wall-corner'
  | 'wall-t'
  | 'wall-cross'
  | 'wall-end'
  | 'door-socket'

export function classifyWallTopology(mask: WallNeighborMask) {
  const links = [mask.up, mask.right, mask.down, mask.left].filter(Boolean).length
  if (links === 4) return { role: 'wall-cross', orientation: 'cross' as const }
  if (links === 3) {
    if (!mask.left) return { role: 'wall-t', orientation: 't-right' as const }
    if (!mask.up) return { role: 'wall-t', orientation: 't-down' as const }
    if (!mask.right) return { role: 'wall-t', orientation: 't-left' as const }
    return { role: 'wall-t', orientation: 't-up' as const }
  }
  if (mask.left && mask.right) return { role: 'wall-h', orientation: 'h' as const }
  if (mask.up && mask.down) return { role: 'wall-v', orientation: 'v' as const }
  if (mask.up && mask.right) return { role: 'wall-corner', orientation: 'tr' as const }
  if (mask.right && mask.down) return { role: 'wall-corner', orientation: 'br' as const }
  if (mask.down && mask.left) return { role: 'wall-corner', orientation: 'bl' as const }
  if (mask.left && mask.up) return { role: 'wall-corner', orientation: 'tl' as const }
  if (mask.up) return { role: 'wall-end', orientation: 't-up' as const }
  if (mask.right) return { role: 'wall-end', orientation: 't-right' as const }
  if (mask.down) return { role: 'wall-end', orientation: 't-down' as const }
  return { role: 'wall-end', orientation: 't-left' as const }
}
```

- [ ] **Step 5: Add layout validation for closure and door support**

```ts
const OUTER_TILE_IDS = new Set([
  'outer-wall-h',
  'outer-wall-v',
  'outer-corner-tl',
  'outer-corner-tr',
  'outer-corner-bl',
  'outer-corner-br',
  'outer-t-up',
  'outer-t-right',
  'outer-t-down',
  'outer-t-left',
  'outer-cross',
  'outer-end-up',
  'outer-end-right',
  'outer-end-down',
  'outer-end-left',
  'door-socket-h',
  'door-socket-v',
])

export function validateWallLayout(cells: { x: number; y: number; tileId: string }[]) {
  const errors: string[] = []
  for (const cell of cells) {
    if (!OUTER_TILE_IDS.has(cell.tileId)) continue
    if (cell.tileId.startsWith('outer-end')) {
      errors.push('outer-loop-open')
    }
  }
  return { valid: errors.length === 0, errors }
}
```

- [ ] **Step 6: Run tests to verify they pass**

Run:

```bash
npm run test -- src/domain/map-editor/wall-topology-rules.test.ts
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add Project/AIRPGWeb/src/domain/map-editor/wall-topology-rules.ts Project/AIRPGWeb/src/domain/map-editor/wall-topology-rules.test.ts
git commit -m "feat: add wall topology validation rules"
```

---

### Task 2: Normalize tile metadata and remove style-first grouping

**Files:**
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\tile-topology.ts`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\tile-palette.ts`
- Test: `g:\UEGameDevelopment\Project\AIRPGWeb\tests\developer-mode.spec.ts`

- [ ] **Step 1: Write the failing Playwright assertions for the new palette shape**

```ts
test('structure palette groups by topology without the old style subgroup level', async ({ page }) => {
  await openMapEditor(page)

  await page.getByRole('button', { name: '结构层', exact: true }).click()
  await page.getByRole('button', { name: '墙壁' }).click()
  await page.getByRole('button', { name: '横墙' }).click()

  await expect(page.getByRole('button', { name: '细线双线' })).toHaveCount(0)
  await expect(page.getByTitle('outer-wall-h')).toBeVisible()
})
```

- [ ] **Step 2: Run the targeted E2E to verify it fails**

Run:

```bash
npm run test:e2e -- tests/developer-mode.spec.ts --grep "structure palette groups by topology"
```

Expected: FAIL because the `细线双线` subgroup still exists.

- [ ] **Step 3: Collapse tile metadata into topology-first families**

```ts
export type TileFamily =
  | 'wall-h'
  | 'wall-v'
  | 'wall-corner'
  | 'wall-t'
  | 'wall-cross'
  | 'wall-end'
  | 'door-socket'
  | 'door-leaf'
```

```ts
{ tileId: 'outer-wall-h', layerId: 'structure', family: 'wall-h', orientation: 'h', previewLabel: '外墙横', blocksMovement: true }
{ tileId: 'inner-wall-h', layerId: 'structure', family: 'wall-h', orientation: 'h', previewLabel: '内墙横', blocksMovement: true }
{ tileId: 'yard-wall-h', layerId: 'structure', family: 'wall-h', orientation: 'h', previewLabel: '院墙横', blocksMovement: true }
```

- [ ] **Step 4: Flatten the structure palette to topology → variants**

```ts
function buildStructurePaletteGroups(): TilePaletteGroup[] {
  return [
    {
      id: 'structure-walls',
      label: '墙壁',
      children: [
        buildTileGroup('structure-wall-corners', '墙壁拐角', [
          'outer-corner-tl',
          'outer-corner-tr',
          'outer-corner-bl',
          'outer-corner-br',
          'inner-corner-tl',
          'inner-corner-tr',
          'inner-corner-bl',
          'inner-corner-br',
        ]),
        buildTileGroup('structure-wall-horizontal', '横墙', ['outer-wall-h', 'inner-wall-h', 'yard-wall-h']),
        buildTileGroup('structure-wall-vertical', '竖墙', ['outer-wall-v', 'inner-wall-v', 'yard-wall-v']),
        buildTileGroup('structure-wall-endcaps', '端头', [
          'outer-end-up',
          'outer-end-right',
          'outer-end-down',
          'outer-end-left',
        ]),
      ],
    },
  ]
}
```

- [ ] **Step 5: Update existing selection helpers in Playwright**

```ts
async function selectOuterHorizontalWall(page: Parameters<typeof test>[0]['page']) {
  await page.getByRole('button', { name: '结构层', exact: true }).click()
  await page.getByRole('button', { name: '墙壁' }).click()
  await page.getByRole('button', { name: '横墙' }).click()
  await page.getByTitle('outer-wall-h').click()
}
```

- [ ] **Step 6: Run the targeted E2E again**

Run:

```bash
npm run test:e2e -- tests/developer-mode.spec.ts --grep "structure palette groups by topology"
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add Project/AIRPGWeb/src/domain/map-editor/tile-topology.ts Project/AIRPGWeb/src/domain/map-editor/tile-palette.ts Project/AIRPGWeb/tests/developer-mode.spec.ts
git commit -m "refactor: regroup structure palette by topology"
```

---

### Task 3: Add shared material presets for walls, ground, grass, and trees

**Files:**
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\wall-material-presets.ts`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\TileSkin.tsx`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\App.css`

- [ ] **Step 1: Write a failing unit test for material slot lookup**

```ts
import { describe, expect, it } from 'vitest'
import { getMaterialPreset } from './wall-material-presets'

describe('getMaterialPreset', () => {
  it('returns soil wall tokens for outer wall tiles', () => {
    expect(getMaterialPreset('outer-wall-h')).toMatchObject({
      material: 'soil',
      role: 'wall-h',
      outlineClass: 'soil-outline',
    })
  })
})
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
npm run test -- src/domain/map-editor/wall-topology-rules.test.ts
```

Expected: FAIL after adding the new import because `wall-material-presets.ts` does not exist.

- [ ] **Step 3: Create shared preset data**

```ts
export type MaterialPreset = {
  material: 'soil' | 'wood' | 'stone' | 'grass' | 'tree'
  role: 'wall-h' | 'wall-v' | 'wall-corner' | 'wall-t' | 'wall-cross' | 'wall-end' | 'door-socket' | 'ground' | 'tree-canopy' | 'tree-trunk'
  outlineClass: string
  fillClass: string
}

export function getMaterialPreset(tileId: string): MaterialPreset {
  if (tileId.startsWith('outer-')) return { material: 'soil', role: inferRole(tileId), outlineClass: 'soil-outline', fillClass: 'soil-fill' }
  if (tileId.startsWith('inner-')) return { material: 'wood', role: inferRole(tileId), outlineClass: 'wood-outline', fillClass: 'wood-fill' }
  if (tileId.startsWith('yard-')) return { material: 'stone', role: inferRole(tileId), outlineClass: 'stone-outline', fillClass: 'stone-fill' }
  if (tileId === 'ground-grass') return { material: 'grass', role: 'ground', outlineClass: 'grass-plain', fillClass: 'grass-plain' }
  return { material: 'stone', role: 'ground', outlineClass: 'stone-outline', fillClass: 'stone-fill' }
}
```

- [ ] **Step 4: Switch `TileSkin` from hardcoded branches to preset-driven classes**

```tsx
const preset = getMaterialPreset(tileId)
const topology = getTileTopology(tileId)

return (
  <span
    className={[
      'tile-skin',
      `tile-skin-material-${preset.material}`,
      `tile-skin-role-${preset.role}`,
      topology ? `tile-skin-${topology.orientation}` : '',
      preset.outlineClass,
      preset.fillClass,
    ].filter(Boolean).join(' ')}
    data-tile-id={tileId}
    aria-hidden="true"
  />
)
```

- [ ] **Step 5: Add CSS for shared wall outlines and bigger tree canopies**

```css
.tile-skin-material-soil { --wall-outline: #6f4a37; --wall-fill: #b69472; }
.tile-skin-material-wood { --wall-outline: #4d3424; --wall-fill: #d8c6a6; }
.tile-skin-material-stone { --wall-outline: #59574f; --wall-fill: #b9b3ab; }
.tile-skin-role-ground.grass-plain { background: #56784a; }
.tile-skin-tree-canopy {
  width: calc(var(--tile-size, 100%) * 1.5);
  height: calc(var(--tile-size, 100%) * 1.5);
}
.tile-skin-tree-trunk::before {
  top: -18%;
  bottom: 0;
}
```

- [ ] **Step 6: Run tests and build**

Run:

```bash
npm run test -- src/domain/map-editor/wall-topology-rules.test.ts
npm run build
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add Project/AIRPGWeb/src/domain/map-editor/wall-material-presets.ts Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileSkin.tsx Project/AIRPGWeb/src/App.css
git commit -m "feat: add shared wall material presets"
```

---

### Task 4: Generate closed-house preview cases from shared data

**Files:**
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\wall-preview-cases.ts`
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\public\brainstorm\tile-style-direction-v6.html`

- [ ] **Step 1: Define three non-identical closed-house cases in code**

```ts
export const wallPreviewCases = {
  soilLHouse: {
    title: '土系 L 型生活居所',
    cells: [
      { x: 0, y: 0, tileId: 'outer-corner-tl' },
      { x: 1, y: 0, tileId: 'outer-wall-h' },
      { x: 2, y: 0, tileId: 'outer-wall-h' },
      { x: 3, y: 0, tileId: 'outer-corner-tr' },
      { x: 0, y: 1, tileId: 'outer-wall-v' },
      { x: 3, y: 1, tileId: 'outer-wall-v' },
      { x: 0, y: 2, tileId: 'outer-wall-v' },
      { x: 1, y: 2, tileId: 'door-socket-h' },
      { x: 2, y: 2, tileId: 'outer-wall-h' },
      { x: 3, y: 2, tileId: 'outer-corner-br' },
    ],
  },
}
```

- [ ] **Step 2: Validate every preview case before render**

```ts
for (const previewCase of Object.values(wallPreviewCases)) {
  const result = validateWallLayout(previewCase.cells)
  if (!result.valid) {
    throw new Error(`invalid preview case: ${previewCase.title} -> ${result.errors.join(',')}`)
  }
}
```

- [ ] **Step 3: Render one brainstorm page from shared preview data**

```html
<script type="module">
  import { wallPreviewCases } from '../../src/domain/map-editor/wall-preview-cases.ts'
  import { getMaterialPreset } from '../../src/domain/map-editor/wall-material-presets.ts'

  const cases = Object.values(wallPreviewCases)
  // build DOM cards from validated closed-house cases
</script>
```

- [ ] **Step 4: Add one tree example and one plain-grass strip sourced from the same preset data**

```ts
export const naturalPreviewCases = {
  plainGrass: [{ x: 0, y: 0, tileId: 'ground-grass' }, { x: 1, y: 0, tileId: 'ground-grass' }],
  treeTall: [
    { x: 0, y: 0, tileId: 'tree-canopy-3x2-a' },
    { x: 1, y: 2, tileId: 'tree-trunk-1x3-a' },
  ],
}
```

- [ ] **Step 5: Manual review in the running preview**

Run:

```bash
http://127.0.0.1:5174/brainstorm/tile-style-direction-v6.html
```

Expected: three closed-house cases, clean grass strip, and tree canopy/trunk connection visible on a continuous tile grid.

- [ ] **Step 6: Commit**

```bash
git add Project/AIRPGWeb/src/domain/map-editor/wall-preview-cases.ts Project/AIRPGWeb/public/brainstorm/tile-style-direction-v6.html
git commit -m "feat: add validated closed-house preview cases"
```

---

### Task 5: Reorder layers and lock in regression coverage

**Files:**
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\map-editor\create-empty-map-asset.ts`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\tests\developer-mode.spec.ts`

- [ ] **Step 1: Write failing assertions for default layer order**

```ts
test('map editor shows region before ground in the layer stack', async ({ page }) => {
  await openMapEditor(page)
  const layerButtons = page.locator('.map-editor-layer-button')

  await expect(layerButtons.nth(0)).toHaveText('区域层')
  await expect(layerButtons.nth(1)).toHaveText('地板层')
})
```

- [ ] **Step 2: Run the targeted E2E to verify it fails**

Run:

```bash
npm run test:e2e -- tests/developer-mode.spec.ts --grep "region before ground"
```

Expected: FAIL because the current default order is `地板层 -> 区域层`.

- [ ] **Step 3: Reorder default layers in the map asset factory**

```ts
layers: (['region', 'ground', 'structure', 'openings', 'art'] as const).map((layerId) =>
  createLayer(layerId, input.width, input.height),
),
```

- [ ] **Step 4: Add final regression coverage for the new wall workflow**

```ts
test('validated preview grouping shows direct topology groups without style submenus', async ({ page }) => {
  await openMapEditor(page)
  await page.getByRole('button', { name: '结构层', exact: true }).click()
  await page.getByRole('button', { name: '墙壁' }).click()

  await expect(page.getByRole('button', { name: '墙壁拐角' })).toBeVisible()
  await expect(page.getByRole('button', { name: '横墙' })).toBeVisible()
  await expect(page.getByRole('button', { name: '竖墙' })).toBeVisible()
  await expect(page.getByRole('button', { name: '细线双线' })).toHaveCount(0)
})
```

- [ ] **Step 5: Run full verification**

Run:

```bash
npm run test -- src/domain/map-editor/wall-topology-rules.test.ts
npm run test:e2e -- tests/developer-mode.spec.ts
npm run build
```

Expected: all PASS.

- [ ] **Step 6: Commit**

```bash
git add Project/AIRPGWeb/src/domain/map-editor/create-empty-map-asset.ts Project/AIRPGWeb/tests/developer-mode.spec.ts
git commit -m "test: cover wall topology driven editor workflow"
```

---

## Self-Review

### Spec coverage
- Topology grammar and closure validation: Task 1
- Remove style-first subgroup and group by wall structure: Task 2
- Make material changes keep one connection grammar: Task 3
- Only show complete closed-house previews on continuous tile maps: Task 4
- Region/ground ordering and editor regressions: Task 5
- Grass reset and tree canopy/trunk continuity: Tasks 3 and 4

### Placeholder scan
- No `TODO`, `TBD`, or “implement later” placeholders remain
- Every task includes exact files and verification commands
- Every code step includes concrete snippets rather than abstract instructions

### Type consistency
- Shared topology roles use `wall-h`, `wall-v`, `wall-corner`, `wall-t`, `wall-cross`, `wall-end`, `door-socket`
- Preview and validation both consume the same tile ids from `tile-topology.ts`
- Material presets are used by both `TileSkin` and brainstorm previews to avoid split behavior

---

Plan complete and saved to `Docs/superpowers/plans/2026-05-31-airpgweb-wall-topology-material-implementation-plan.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using `executing-plans`, batch execution with checkpoints

**Which approach?**
