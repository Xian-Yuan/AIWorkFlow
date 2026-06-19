# AIRPGWeb Save/Load And Random Name Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix AIRPGWeb save availability and load-position restoration, then add data-driven random-name buttons to character creation.

**Architecture:** Keep the current page-state flow in `App.tsx`, but centralize save-availability refresh and snapshot construction so the menu, save panel, and in-game exit flows use one rule. Add stable UI evidence for current position and loaded-save metadata, then extend character creation with a small data/domain name generator instead of hardcoding names inside the component.

**Tech Stack:** React, TypeScript, Vite, Dexie/IndexedDB, Playwright

---

## File Map

### Modify

- `g:\UEGameDevelopment\Project\AIRPGWeb\src\App.tsx`
  - Centralize `hasSave` refresh
  - Split initial auto-save builder and runtime snapshot builder
  - Fix setting-exit auto-save corruption
  - Refresh save availability on startup and after save-related flows
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\GameShell.tsx`
  - Surface current position to the right panel
  - Add load-success log entry
  - Provide stable test hook for current position
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\WorldInfo.tsx`
  - Render current coordinates and optional last-loaded message
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\SaveLoadPanel.tsx`
  - Show save details beyond player name and time
  - Reuse one slot detail shape for menu/game modes
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\CharacterCreate.tsx`
  - Add random-name buttons beside both name inputs
  - Use data/domain name generator
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\TextMapView.tsx`
  - Keep movement logic
  - Add optional test hook only if `WorldInfo` display is not enough
- `g:\UEGameDevelopment\Project\AIRPGWeb\tests\new-game-and-save.spec.ts`
  - Add refresh-case assertion
  - Add exact coordinate restore assertion

### Create

- `g:\UEGameDevelopment\Project\AIRPGWeb\src\data\names\world-names.ts`
  - First-pass world-appropriate male/female name pools
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\names\random-name.ts`
  - Small deterministic helper for filtering and choosing random names

### Verification

- `g:\UEGameDevelopment\Project\AIRPGWeb\tests\new-game-and-save.spec.ts`
- `g:\UEGameDevelopment\Project\AIRPGWeb\tests\app-smoke.spec.ts`

## Task 1: Add Failing Save/Load Regression Tests

**Files:**
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\tests\new-game-and-save.spec.ts`
- Verify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\GameShell.tsx`
- Verify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\WorldInfo.tsx`

- [ ] **Step 1: Rewrite the test to assert refresh persistence and exact position restoration**

Replace the existing broad smoke flow with explicit coordinate assertions:

```ts
import { expect, test } from '@playwright/test'

async function completeCharacterCreate(page: import('@playwright/test').Page, playerName: string, friendName: string) {
  await page.goto('/')
  await page.getByRole('button', { name: '新游戏' }).click()

  const inputs = page.locator('input[type="text"]')
  await inputs.nth(0).fill(playerName)
  await page.locator('fieldset').nth(0).locator('text=男').click()
  await page.locator('fieldset').nth(0).locator('button', { hasText: '全部重随机' }).click()

  await inputs.nth(1).fill(friendName)
  await page.locator('fieldset').nth(1).locator('text=女').click()
  await page.locator('fieldset').nth(1).locator('button', { hasText: '全部重随机' }).click()

  await page.getByRole('button', { name: '确定' }).click()
  await page.waitForSelector('.game-shell-full', { timeout: 15000 })
}

test('continue stays enabled after reload when local save exists', async ({ page }) => {
  await completeCharacterCreate(page, '测试甲', '小花甲')
  await page.reload()
  await expect(page.getByRole('button', { name: '继续游戏' })).toBeEnabled()
})

test('manual save restores exact player position after moving again', async ({ page }) => {
  await completeCharacterCreate(page, '测试乙', '小花乙')

  const terrainCells = page.locator('.textmap-cell.clickable')
  await terrainCells.nth(8).click()
  await page.waitForTimeout(1000)

  const pos = page.getByTestId('player-position')
  const savedPosition = await pos.textContent()

  await page.getByRole('button', { name: '💾 存档' }).click()
  const slot1 = page.locator('.save-slot').filter({ hasText: '存档槽 1' })
  await slot1.locator('button', { hasText: '保存' }).click()
  await expect(page.getByText('保存成功')).toBeVisible()
  await page.locator('.dialog-header .btn-small').click()

  await terrainCells.nth(15).click()
  await page.waitForTimeout(1000)
  await expect(pos).not.toHaveText(savedPosition ?? '')

  await page.getByRole('button', { name: '💾 存档' }).click()
  await slot1.locator('button', { hasText: '加载' }).click()
  await page.waitForSelector('.game-shell-full', { timeout: 15000 })
  await expect(page.getByTestId('player-position')).toHaveText(savedPosition ?? '')
})
```

- [ ] **Step 2: Run the focused test file to confirm it fails**

Run:

```bash
npx playwright test tests/new-game-and-save.spec.ts --reporter=line
```

Expected:

- at least one failure because `player-position` does not exist yet
- or the refresh case fails because `继续游戏` still stays disabled after reload

- [ ] **Step 3: Keep the existing auto-save creation smoke test but update it to use the same helper**

Append this test beneath the new ones:

```ts
test('auto-save on character creation', async ({ page }) => {
  await completeCharacterCreate(page, '自动测试', '小自动')
  await page.getByRole('button', { name: '💾 存档' }).click()
  await expect(page.getByText('🔷 自动存档')).toBeVisible()
  await expect(page.locator('.save-slot.auto').locator('.save-slot-detail')).toContainText('自动测试')
})
```

- [ ] **Step 4: Re-run the focused test file and capture the failing evidence**

Run:

```bash
npx playwright test tests/new-game-and-save.spec.ts --reporter=line
```

Expected:

- still FAIL
- failures now point to the real regression targets, not vague flow breakage

- [ ] **Step 5: Commit the failing test baseline**

```bash
git add Project/AIRPGWeb/tests/new-game-and-save.spec.ts
git commit -m "test: capture AIRPGWeb save availability regressions"
```

## Task 2: Fix Save Availability Initialization And Snapshot Builders

**Files:**
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\App.tsx`
- Verify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\persistence\repositories\save-repository.ts`

- [ ] **Step 1: Add a shared valid-slot predicate and save refresh helper**

Update imports and helpers near the top of `App.tsx`:

```ts
import { useEffect, useRef, useState } from 'react'

type PersistedGameState = {
  player: PlayerData
  worldDay: number
  worldMinute: number
  season: string
  weather: string
  playerX: number
  playerY: number
}

function isSlotUsable(slot: { savedAt?: string | null; player?: unknown }) {
  return Boolean(slot.savedAt && slot.player)
}
```

Inside `App()` add:

```ts
  async function refreshSaveAvailability() {
    const slots = await repoRef.current.getAllSlots()
    const available = slots.filter(isSlotUsable)
    setHasSave(available.length > 0)
    return available
  }

  useEffect(() => {
    refreshSaveAvailability().catch(() => setHasSave(false))
  }, [])
```

- [ ] **Step 2: Replace the initial-only `autoSlot()` helper with two explicit builders**

Replace the bottom helper section with:

```ts
function buildInitialAutoSave(player: PlayerData) {
  return buildRuntimeSnapshot('auto-save', player, 24, 17, 1, 480, '春季', '晴天')
}

function buildRuntimeSnapshot(
  slotId: string,
  player: PlayerData,
  playerX: number,
  playerY: number,
  worldDay: number,
  worldMinute: number,
  season: string,
  weather: string,
) {
  return {
    slotId,
    currentTileId: 'ironhollow',
    savedAt: new Date().toISOString(),
    playerName: player.name,
    player,
    worldDay,
    worldMinute,
    season,
    weather,
    playerX,
    playerY,
  }
}
```

- [ ] **Step 3: Use the builders in every save path and refresh menu availability after each save-related flow**

Update the relevant `App.tsx` sections:

```ts
  async function confirmExitFromSettings(saveFirst: boolean) {
    setShowExitConfirm(false)
    if (saveFirst && player && loadedState) {
      await repoRef.current.save(
        buildRuntimeSnapshot(
          'auto-save',
          player,
          loadedState.playerX,
          loadedState.playerY,
          loadedState.worldDay,
          loadedState.worldMinute,
          loadedState.season,
          loadedState.weather,
        ),
      )
    }
    await refreshSaveAvailability()
    setPlayer(null)
    setLoadedState(null)
    setScreen('start')
  }
```

```ts
  async function handleLoadingComplete() {
    const data = createDataRef.current
    if (!data) { setScreen('start'); return }
    const p = buildPlayer(data)
    setPlayer(p)
    setLoadedState({
      player: p,
      worldDay: 1,
      worldMinute: 480,
      season: '春季',
      weather: '晴天',
      playerX: 24,
      playerY: 17,
    })
    setGameKey(k => k + 1)
    setScreen('game')
    try {
      await repoRef.current.save(buildInitialAutoSave(p))
      await refreshSaveAvailability()
    } catch (e) {
      console.error('自动存档失败:', e)
    }
  }
```

```ts
  async function handleManualSave(slotId: string, p: PlayerData, x: number, y: number, day: number, min: number, season: string, weather: string): Promise<boolean> {
    try {
      await repoRef.current.save(buildRuntimeSnapshot(slotId, p, x, y, day, min, season, weather))
      await refreshSaveAvailability()
      return true
    } catch (e) {
      console.error('手动存档失败:', e)
      return false
    }
  }
```

```ts
  async function handleExitWithSave(p: PlayerData, x: number, y: number, day: number, min: number, season: string, weather: string) {
    try {
      await repoRef.current.save(buildRuntimeSnapshot('auto-save', p, x, y, day, min, season, weather))
    } catch (e) {
      console.error('退出自动存档失败:', e)
    }
    await refreshSaveAvailability()
    setPlayer(null)
    setLoadedState(null)
    setScreen('start')
  }

  async function handleExitWithoutSave() {
    await refreshSaveAvailability()
    setPlayer(null)
    setLoadedState(null)
    setScreen('start')
  }
```

- [ ] **Step 4: Normalize load output into one initial state object**

Replace the existing load completion body with:

```ts
  async function handleLoadComplete() {
    const slotId = pendingLoadRef.current
    if (!slotId) { setScreen('start'); return }

    try {
      const slot = await repoRef.current.load(slotId)
      if (!slot || !slot.player) { setScreen('start'); return }

      const nextState: PersistedGameState = {
        player: slot.player as PlayerData,
        worldDay: slot.worldDay ?? 1,
        worldMinute: slot.worldMinute ?? 480,
        season: slot.season ?? '春季',
        weather: slot.weather ?? '晴天',
        playerX: slot.playerX ?? 24,
        playerY: slot.playerY ?? 17,
      }

      setLoadedState(nextState)
      setPlayer(nextState.player)
      setGameKey(k => k + 1)
      setScreen('game')
    } catch {
      setScreen('start')
    }
  }
```

- [ ] **Step 5: Run TypeScript and the focused Playwright file**

Run:

```bash
npx tsc --noEmit
npx playwright test tests/new-game-and-save.spec.ts --reporter=line
```

Expected:

- TypeScript may pass
- Playwright may still fail on missing `player-position` and missing save details, which is acceptable at this step

- [ ] **Step 6: Commit the App-layer save flow fix**

```bash
git add Project/AIRPGWeb/src/App.tsx Project/AIRPGWeb/tests/new-game-and-save.spec.ts
git commit -m "fix: centralize AIRPGWeb save availability"
```

## Task 3: Add Visible Position Evidence And Save Detail UI

**Files:**
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\GameShell.tsx`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\WorldInfo.tsx`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\SaveLoadPanel.tsx`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\TextMapView.tsx`

- [ ] **Step 1: Extend `WorldInfo` props to render current position and a test hook**

Update `WorldInfo.tsx`:

```ts
type WorldInfoProps = {
  day: number
  minuteOfDay: number
  season: string
  weather: string
  npcCount: number
  playerX: number
  playerY: number
  logs: string[]
}

export function WorldInfo({ day, minuteOfDay, season, weather, npcCount, playerX, playerY, logs }: WorldInfoProps) {
```

Add this block under the existing area section:

```tsx
      <div className="info-section">
        <div className="info-section-title">位置</div>
        <div className="info-row" data-testid="player-position">
          坐标：({playerX}, {playerY})
        </div>
      </div>
```

- [ ] **Step 2: Pass live position to `WorldInfo` and log successful loads**

Update `GameShell.tsx`:

```ts
type GameShellProps = {
  player: PlayerData
  initialPlayerX: number
  initialPlayerY: number
  worldDay: number
  worldMinute: number
  season: string
  weather: string
  isAiEnabled: boolean
  onOpenSettings: () => void
  onManualSave: (slotId: string, player: PlayerData, x: number, y: number, day: number, min: number, season: string, weather: string) => Promise<boolean>
  onLoadSave: (slotId: string) => void
  onExitWithSave: (player: PlayerData, x: number, y: number, day: number, min: number, season: string, weather: string) => void
  onExitWithoutSave: () => void
}
```

Add this effect-style initialization via `useState` callback:

```ts
  const [logs, setLogs] = useState<string[]>(() => [
    `你当前位于坐标 (${initialPlayerX}, ${initialPlayerY})。`,
    `世界时间：第 ${worldDay} 天 ${String(Math.floor(worldMinute / 60)).padStart(2, '0')}:${String(worldMinute % 60).padStart(2, '0')}。`,
    '清晨的阳光洒在铁锤镇的石板路上。',
  ])
```

Then pass coordinates:

```tsx
        <WorldInfo
          day={worldDay}
          minuteOfDay={worldMinute}
          season={season}
          weather={weather}
          npcCount={INITIAL_ACTORS.length}
          playerX={playerX}
          playerY={playerY}
          logs={logs}
        />
```

- [ ] **Step 3: Extend save panel slot detail shape to include coordinates**

Update `SaveLoadPanel.tsx`:

```ts
type SlotInfo = {
  id: string
  label: string
  savedAt: string | null
  playerName: string | null
  playerX: number | null
  playerY: number | null
  isAuto: boolean
}
```

Initialize defaults:

```ts
  const [slots, setSlots] = useState<SlotInfo[]>([
    { id: 'auto-save', label: '自动存档', savedAt: null, playerName: null, playerX: null, playerY: null, isAuto: true },
    { id: 'slot-1', label: '存档槽 1', savedAt: null, playerName: null, playerX: null, playerY: null, isAuto: false },
    { id: 'slot-2', label: '存档槽 2', savedAt: null, playerName: null, playerX: null, playerY: null, isAuto: false },
    { id: 'slot-3', label: '存档槽 3', savedAt: null, playerName: null, playerX: null, playerY: null, isAuto: false },
  ])
```

Map loaded data:

```ts
        return found
          ? {
              ...s,
              savedAt: found.savedAt,
              playerName: found.playerName ?? null,
              playerX: found.playerX ?? null,
              playerY: found.playerY ?? null,
            }
          : s
```

Render extra detail:

```tsx
                {autoSlot.playerName ? (
                  <>
                    <span className="save-slot-detail">{autoSlot.playerName} — {formatTime(autoSlot.savedAt)}</span>
                    <span className="save-slot-detail">坐标：({autoSlot.playerX ?? '-'}, {autoSlot.playerY ?? '-'})</span>
                  </>
                ) : (
```

Use the same shape for manual slots.

- [ ] **Step 4: Run the focused test file and the full test suite**

Run:

```bash
npx playwright test tests/new-game-and-save.spec.ts --reporter=line
npx playwright test --reporter=line
```

Expected:

- `tests/new-game-and-save.spec.ts` PASS
- full Playwright suite PASS

- [ ] **Step 5: Run TypeScript and diagnostics**

Run:

```bash
npx tsc --noEmit
```

Then check diagnostics for:

- `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\GameShell.tsx`
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\WorldInfo.tsx`
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\SaveLoadPanel.tsx`

Expected:

- no TypeScript or editor diagnostics

- [ ] **Step 6: Commit the evidence and slot-detail UI**

```bash
git add Project/AIRPGWeb/src/presentation/react-shell/GameShell.tsx Project/AIRPGWeb/src/presentation/react-shell/WorldInfo.tsx Project/AIRPGWeb/src/presentation/react-shell/SaveLoadPanel.tsx Project/AIRPGWeb/tests/new-game-and-save.spec.ts
git commit -m "fix: show AIRPGWeb restored save position"
```

## Task 4: Add Data-Driven Random Name Buttons

**Files:**
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\data\names\world-names.ts`
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\names\random-name.ts`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\CharacterCreate.tsx`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\tests\new-game-and-save.spec.ts`

- [ ] **Step 1: Create the world name pools**

Create `src/data/names/world-names.ts`:

```ts
export const maleNames = [
  '阿德',
  '布伦',
  '科林',
  '达恩',
  '埃德',
  '法尔',
  '格伦',
  '霍尔',
  '伊文',
  '约里',
]

export const femaleNames = [
  '艾琳',
  '贝拉',
  '赛娜',
  '黛拉',
  '艾薇',
  '菲雅',
  '格温',
  '海妲',
  '伊娜',
  '琼娜',
]

export const neutralFallbackNames = [...maleNames, ...femaleNames]
```

- [ ] **Step 2: Create the generator helper with exclude support**

Create `src/domain/names/random-name.ts`:

```ts
import { femaleNames, maleNames, neutralFallbackNames } from '../../data/names/world-names'

type Gender = 'male' | 'female' | null

export function pickRandomName(gender: Gender, exclude: string[] = []) {
  const pool = gender === 'male'
    ? maleNames
    : gender === 'female'
      ? femaleNames
      : neutralFallbackNames

  const filtered = pool.filter(name => !exclude.includes(name))
  const usablePool = filtered.length > 0 ? filtered : pool
  const index = Math.floor(Math.random() * usablePool.length)
  return usablePool[index]
}
```

- [ ] **Step 3: Add buttons in `CharacterCreate.tsx` and wire them to the helper**

Update imports:

```ts
import { pickRandomName } from '../../domain/names/random-name'
```

Add handlers inside the component:

```ts
  function randomizePlayerName() {
    setPlayerName(pickRandomName(playerGender, friendName ? [friendName] : []))
    setError('')
  }

  function randomizeFriendName() {
    setFriendName(pickRandomName(friendGender, playerName ? [playerName] : []))
    setError('')
  }
```

Replace the player name row with:

```tsx
        <label className="input-row">
          <span>姓名：</span>
          <input
            type="text"
            value={playerName}
            onChange={e => { setPlayerName(e.target.value); setError('') }}
            placeholder="输入你的名字"
            maxLength={12}
          />
          <button type="button" className="btn-small" onClick={randomizePlayerName}>
            随机名字
          </button>
        </label>
```

Replace the friend name row with:

```tsx
        <label className="input-row">
          <span>姓名：</span>
          <input
            type="text"
            value={friendName}
            onChange={e => { setFriendName(e.target.value); setError('') }}
            placeholder="青梅竹马的名字"
            maxLength={12}
          />
          <button type="button" className="btn-small" onClick={randomizeFriendName}>
            随机名字
          </button>
        </label>
```

- [ ] **Step 4: Add one Playwright assertion covering the new buttons**

Extend `tests/new-game-and-save.spec.ts`:

```ts
test('random name buttons fill both role inputs', async ({ page }) => {
  await page.goto('/')
  await page.getByRole('button', { name: '新游戏' }).click()

  const fieldsets = page.locator('fieldset')
  await fieldsets.nth(0).getByRole('button', { name: '随机名字' }).click()
  await fieldsets.nth(1).getByRole('button', { name: '随机名字' }).click()

  const inputs = page.locator('input[type="text"]')
  await expect(inputs.nth(0)).not.toHaveValue('')
  await expect(inputs.nth(1)).not.toHaveValue('')
})
```

- [ ] **Step 5: Run full validation**

Run:

```bash
npx tsc --noEmit
npx playwright test --reporter=line
```

Expected:

- TypeScript PASS
- Playwright PASS

- [ ] **Step 6: Run diagnostics on edited files**

Check diagnostics for:

- `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\CharacterCreate.tsx`
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\data\names\world-names.ts`
- `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\names\random-name.ts`

Expected:

- no linter or TypeScript diagnostics

- [ ] **Step 7: Commit the random-name feature**

```bash
git add Project/AIRPGWeb/src/presentation/react-shell/CharacterCreate.tsx Project/AIRPGWeb/src/data/names/world-names.ts Project/AIRPGWeb/src/domain/names/random-name.ts Project/AIRPGWeb/tests/new-game-and-save.spec.ts
git commit -m "feat: add AIRPGWeb random character names"
```

## Final Verification

- [ ] Run the full project checks:

```bash
npx tsc --noEmit
npx playwright test --reporter=line
```

Expected:

- all checks PASS

- [ ] Inspect the final changed files:

```bash
git diff --stat HEAD~4 HEAD
git status --short
```

Expected:

- only the intended AIRPGWeb files are changed
- working tree is clean or only contains unrelated pre-existing changes outside this plan

- [ ] Prepare a short verification summary covering:
- startup save availability
- exact coordinate restore after load
- auto-save after exit no longer resets to spawn
- random-name buttons for both roles
