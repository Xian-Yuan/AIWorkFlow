# AIRPGWeb AI Connection Gate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a persisted AI connection validation flow in the start-menu settings and make the tile editor AI panel usable only after the current API configuration has been tested successfully.

**Architecture:** Keep `App.tsx` as the single persistence entry for `airpg-settings`, extend `SettingsState` with validation metadata, and isolate fingerprint plus connection-test logic in a focused settings helper. The settings screen owns testing and invalidation, while the map editor only consumes the validated status and never reimplements provider configuration.

**Tech Stack:** React 19, TypeScript, Vite, Vitest, Playwright

---

## File Map

### New Files

- `Project/AIRPGWeb/src/domain/settings/ai-connection.ts`
- `Project/AIRPGWeb/src/domain/settings/ai-connection.test.ts`

### Modified Files

- `Project/AIRPGWeb/src/presentation/react-shell/SettingsPanel.tsx`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/MapEditorScreen.tsx`
- `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/AiAssistPanel.tsx`
- `Project/AIRPGWeb/src/App.tsx`
- `Project/AIRPGWeb/src/App.css`
- `Project/AIRPGWeb/tests/developer-mode.spec.ts`

### Responsibility Split

- `ai-connection.ts`: build a stable fingerprint from provider settings, clear stale validation, and run the smallest provider test request through `fetch`
- `SettingsPanel.tsx`: edit AI provider fields, invalidate stale validation immediately, trigger connection test, and show success or failure state
- `App.tsx`: hydrate old saved settings safely by merging the new defaults and persist the richer settings object without extra branching
- `MapEditorScreen.tsx`: replace the old “fields are non-empty” gate with “current settings fingerprint has a successful validation”
- `AiAssistPanel.tsx`: show the new validated or missing status copy without owning any provider form fields
- `developer-mode.spec.ts`: prove the regression path for untested settings, successful test connection, and automatic invalidation after changing a field

## Task 1: Add Validation Metadata And Connection Helpers

**Files:**
- Create: `Project/AIRPGWeb/src/domain/settings/ai-connection.ts`
- Create: `Project/AIRPGWeb/src/domain/settings/ai-connection.test.ts`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/SettingsPanel.tsx`

- [ ] **Step 1: Write the failing helper tests**

```ts
import { describe, expect, it, vi } from 'vitest'
import {
  clearAiConnectionValidation,
  createAiConnectionFingerprint,
  testAiConnection,
  type AiConnectionSettings,
} from './ai-connection'

const baseSettings: AiConnectionSettings = {
  aiEnabled: true,
  aiProvider: 'zhipu',
  aiModel: 'glm-4-flash',
  aiApiKey: 'demo-key',
  aiBaseUrl: 'https://open.bigmodel.cn/api/paas/v4',
}

describe('ai-connection helpers', () => {
  it('builds a stable fingerprint from provider fields', () => {
    expect(createAiConnectionFingerprint(baseSettings)).toBe(
      'zhipu::glm-4-flash::https://open.bigmodel.cn/api/paas/v4::demo-key',
    )
  })

  it('clears validation state when provider settings change', () => {
    expect(
      clearAiConnectionValidation({
        ...baseSettings,
        aiConnectionStatus: 'success',
        aiConnectionMessage: '连接成功',
        aiConnectionFingerprint: 'old',
        aiConnectionValidatedAt: '2026-05-31T10:00:00.000Z',
      }),
    ).toMatchObject({
      aiConnectionStatus: 'idle',
      aiConnectionMessage: '',
      aiConnectionFingerprint: '',
      aiConnectionValidatedAt: '',
    })
  })

  it('posts a minimal request to the configured provider', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ choices: [{ message: { content: 'ok' } }] }),
    })

    const result = await testAiConnection(baseSettings, fetchMock)

    expect(fetchMock).toHaveBeenCalledWith(
      'https://open.bigmodel.cn/api/paas/v4/chat/completions',
      expect.objectContaining({
        method: 'POST',
        headers: expect.objectContaining({
          Authorization: 'Bearer demo-key',
        }),
      }),
    )
    expect(result.status).toBe('success')
  })
})
```

- [ ] **Step 2: Run the focused test to verify it fails**

Run:

```bash
npm run test -- src/domain/settings/ai-connection.test.ts
```

Expected: FAIL because the helper file does not exist yet.

- [ ] **Step 3: Implement the helper module**

```ts
export type AiConnectionSettings = {
  aiEnabled: boolean
  aiProvider: string
  aiModel: string
  aiApiKey: string
  aiBaseUrl: string
}

export type AiConnectionState = {
  aiConnectionStatus: 'idle' | 'testing' | 'success' | 'error'
  aiConnectionMessage: string
  aiConnectionFingerprint: string
  aiConnectionValidatedAt: string
}

export function createAiConnectionFingerprint(settings: AiConnectionSettings) {
  return [
    settings.aiProvider.trim(),
    settings.aiModel.trim(),
    settings.aiBaseUrl.trim().replace(/\/+$/, ''),
    settings.aiApiKey.trim(),
  ].join('::')
}

export function clearAiConnectionValidation<T extends AiConnectionSettings & AiConnectionState>(settings: T): T {
  return {
    ...settings,
    aiConnectionStatus: 'idle',
    aiConnectionMessage: '',
    aiConnectionFingerprint: '',
    aiConnectionValidatedAt: '',
  }
}

export async function testAiConnection(
  settings: AiConnectionSettings,
  fetchImpl: typeof fetch = fetch,
) {
  const endpoint = `${settings.aiBaseUrl.trim().replace(/\/+$/, '')}/chat/completions`
  const response = await fetchImpl(endpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${settings.aiApiKey.trim()}`,
    },
    body: JSON.stringify({
      model: settings.aiModel.trim(),
      messages: [{ role: 'user', content: 'Reply with OK.' }],
      max_tokens: 4,
      temperature: 0,
    }),
  })

  if (!response.ok) {
    const message = await response.text()
    return {
      status: 'error' as const,
      message: message || `连接失败（HTTP ${response.status}）`,
    }
  }

  return {
    status: 'success' as const,
    message: 'API 连接测试成功',
  }
}
```

- [ ] **Step 4: Extend the settings state shape with validation metadata**

```ts
export type SettingsState = {
  language: 'zh' | 'en'
  masterVolume: number
  sfxEnabled: boolean
  musicEnabled: boolean
  aiEnabled: boolean
  aiProvider: string
  aiModel: string
  aiApiKey: string
  aiBaseUrl: string
  aiConnectionStatus: 'idle' | 'testing' | 'success' | 'error'
  aiConnectionMessage: string
  aiConnectionFingerprint: string
  aiConnectionValidatedAt: string
}

export const DEFAULT_SETTINGS: SettingsState = {
  language: 'zh',
  masterVolume: 0.8,
  sfxEnabled: true,
  musicEnabled: true,
  aiEnabled: true,
  aiProvider: 'zhipu',
  aiModel: 'glm-4-flash',
  aiApiKey: '',
  aiBaseUrl: 'https://open.bigmodel.cn/api/paas/v4',
  aiConnectionStatus: 'idle',
  aiConnectionMessage: '',
  aiConnectionFingerprint: '',
  aiConnectionValidatedAt: '',
}
```

- [ ] **Step 5: Run the helper tests again**

Run:

```bash
npm run test -- src/domain/settings/ai-connection.test.ts
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add src/domain/settings/ai-connection.ts src/domain/settings/ai-connection.test.ts src/presentation/react-shell/SettingsPanel.tsx
git commit -m "feat: add ai connection settings helpers"
```

## Task 2: Add Settings-Side Test Connection Flow And Automatic Invalidation

**Files:**
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/SettingsPanel.tsx`
- Modify: `Project/AIRPGWeb/src/App.tsx`
- Modify: `Project/AIRPGWeb/src/App.css`

- [ ] **Step 1: Write the failing Playwright regression for validated settings**

```ts
test('map editor ai panel stays disabled until the start-menu settings connection test succeeds', async ({ page }) => {
  await setSettings(page, {
    aiApiKey: 'demo-key',
    aiConnectionStatus: 'idle',
    aiConnectionFingerprint: '',
    aiConnectionValidatedAt: '',
    aiConnectionMessage: '',
  })

  await openMapEditor(page)

  await expect(page.getByText('AI 未配置，请先到设置完成 API 连接')).toBeVisible()
  await expect(page.getByRole('button', { name: '生成房屋流程' })).toBeDisabled()
})

test('editing provider fields clears a previously successful connection state', async ({ page }) => {
  await page.goto('/')
  await page.getByRole('button', { name: '设置' }).click()

  await page.route('https://open.bigmodel.cn/api/paas/v4/chat/completions', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ choices: [{ message: { content: 'OK' } }] }),
    })
  })

  await page.getByLabel('API Key：').fill('demo-key')
  await page.getByRole('button', { name: '测试连接' }).click()
  await expect(page.getByText('API 连接测试成功')).toBeVisible()

  await page.getByLabel('模型：').fill('glm-4-flash-x')
  await expect(page.getByText('配置已变更，请重新测试连接')).toBeVisible()
})
```

- [ ] **Step 2: Run the regression to verify it fails**

Run:

```bash
npx playwright test tests/developer-mode.spec.ts --grep "连接"
```

Expected: FAIL because the settings screen has no test button and the map editor still accepts non-empty fields.

- [ ] **Step 3: Add invalidation-aware field updates and async connection testing**

```tsx
import { useState } from 'react'
import {
  clearAiConnectionValidation,
  createAiConnectionFingerprint,
  testAiConnection,
} from '../../domain/settings/ai-connection'

function updateAiField<K extends 'aiProvider' | 'aiModel' | 'aiApiKey' | 'aiBaseUrl'>(
  field: K,
  value: SettingsState[K],
) {
  setSettings((current) => {
    const next = { ...current, [field]: value }
    const nextFingerprint = createAiConnectionFingerprint(next)
    return current.aiConnectionFingerprint === nextFingerprint ? next : {
      ...clearAiConnectionValidation(next),
      aiConnectionMessage: '配置已变更，请重新测试连接',
    }
  })
}

async function handleTestConnection() {
  setSettings((current) => ({
    ...current,
    aiConnectionStatus: 'testing',
    aiConnectionMessage: '正在测试连接...',
  }))

  const result = await testAiConnection(settings)

  setSettings((current) => {
    if (result.status === 'success') {
      return {
        ...current,
        aiConnectionStatus: 'success',
        aiConnectionMessage: result.message,
        aiConnectionFingerprint: createAiConnectionFingerprint(current),
        aiConnectionValidatedAt: new Date().toISOString(),
      }
    }

    return {
      ...current,
      aiConnectionStatus: 'error',
      aiConnectionMessage: result.message,
      aiConnectionFingerprint: '',
      aiConnectionValidatedAt: '',
    }
  })
}
```

- [ ] **Step 4: Render the new test button and validation status block**

```tsx
<div className="settings-ai-actions">
  <button
    type="button"
    className="menu-btn"
    onClick={handleTestConnection}
    disabled={
      settings.aiConnectionStatus === 'testing' ||
      !settings.aiProvider.trim() ||
      !settings.aiModel.trim() ||
      !settings.aiBaseUrl.trim() ||
      !settings.aiApiKey.trim()
    }
  >
    {settings.aiConnectionStatus === 'testing' ? '测试中...' : '测试连接'}
  </button>
  <span className={`settings-ai-status ${settings.aiConnectionStatus}`}>
    {settings.aiConnectionMessage || '未测试连接'}
  </span>
</div>
```

- [ ] **Step 5: Add supporting styles and keep App persistence unchanged except for richer defaults**

```css
.settings-ai-actions {
  display: grid;
  gap: 8px;
  margin-top: 4px;
}

.settings-ai-status {
  font-size: 12px;
  padding: 4px 2px;
}

.settings-ai-status.success {
  color: #8ccf8c;
}

.settings-ai-status.error {
  color: #e18b6b;
}

.settings-ai-status.testing,
.settings-ai-status.idle {
  color: #d9bf82;
}
```

- [ ] **Step 6: Run tests and build**

Run:

```bash
npx playwright test tests/developer-mode.spec.ts --grep "连接"
npm run build
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add src/presentation/react-shell/SettingsPanel.tsx src/App.tsx src/App.css tests/developer-mode.spec.ts
git commit -m "feat: add ai connection test flow to settings"
```

## Task 3: Gate Map Editor AI By Successful Validation

**Files:**
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/MapEditorScreen.tsx`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/AiAssistPanel.tsx`
- Modify: `Project/AIRPGWeb/tests/developer-mode.spec.ts`

- [ ] **Step 1: Add the failing map-editor regression for validated settings**

```ts
test('ai house workflow waits for a successful settings validation before generating steps', async ({ page }) => {
  await setSettings(page, {
    aiApiKey: 'demo-key',
    aiConnectionStatus: 'success',
    aiConnectionFingerprint: 'zhipu::glm-4-flash::https://open.bigmodel.cn/api/paas/v4::demo-key',
    aiConnectionValidatedAt: '2026-05-31T10:00:00.000Z',
    aiConnectionMessage: 'API 连接测试成功',
  })

  await openMapEditor(page)

  await page.getByLabel('房屋需求').fill('给我一个铁匠的生活居所')
  await page.getByRole('button', { name: '生成房屋流程' }).click()
  await expect(page.getByText('当前步骤：structure', { exact: true })).toBeVisible()
})
```

- [ ] **Step 2: Run the focused regression and verify it fails before the gate is updated**

Run:

```bash
npx playwright test tests/developer-mode.spec.ts --grep "workflow waits for a successful settings validation"
```

Expected: FAIL because the map editor does not yet compare the saved fingerprint with the current settings.

- [ ] **Step 3: Replace the old gate in the map editor**

```tsx
import { createAiConnectionFingerprint } from '../../../domain/settings/ai-connection'

const aiFingerprint = createAiConnectionFingerprint(settings)
const isAiConfigured = Boolean(
  settings.aiEnabled &&
    settings.aiConnectionStatus === 'success' &&
    settings.aiConnectionFingerprint === aiFingerprint,
)
```

- [ ] **Step 4: Update panel copy so the user sees the stricter requirement**

```tsx
<p className={`map-editor-ai-config-status ${isConfigured ? 'ready' : 'missing'}`}>
  {isConfigured
    ? 'AI 已通过主设置中的 API 连接测试'
    : 'AI 未配置，请先到设置完成 API 连接测试'}
</p>
```

- [ ] **Step 5: Run the full regression pack and diagnostics**

Run:

```bash
npx playwright test tests/developer-mode.spec.ts
npm run test -- src/domain/settings/ai-connection.test.ts
```

Then check diagnostics for:

```text
g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\SettingsPanel.tsx
g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\MapEditorScreen.tsx
g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\AiAssistPanel.tsx
```

Expected: all tests PASS, no new diagnostics that need cleanup.

- [ ] **Step 6: Verify preview availability and commit**

Run:

```bash
powershell -ExecutionPolicy Bypass -File "g:\UEGameDevelopment\.trae\scripts\web-preview-guard.ps1"
```

Expected: prints the current valid local preview URL, then reopen that URL in preview before handoff.

Commit:

```bash
git add src/presentation/react-shell/dev-mode/MapEditorScreen.tsx src/presentation/react-shell/dev-mode/AiAssistPanel.tsx tests/developer-mode.spec.ts
git commit -m "feat: gate map editor ai with validated settings"
```

## Self-Review

- Spec coverage: the plan covers persisted validation metadata, automatic invalidation after editing provider fields, settings-side connection testing, stricter map-editor gating, and regression proof for all three paths
- Placeholder scan: no `TODO`, `TBD`, or “handle later” steps remain
- Type consistency: `aiConnectionStatus`, `aiConnectionMessage`, `aiConnectionFingerprint`, and `aiConnectionValidatedAt` are used consistently across helper, settings, and map-editor tasks
