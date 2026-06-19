# AIRPGWeb Asset Import And Roundtrip Edit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为素材系统增加图片导入、保留原始尺寸、一键适配模板尺寸，以及“覆盖原素材 / 另存为新素材”的二次编辑闭环。

**Architecture:** 把导入解析、模板适配、保存策略做成共享能力，素材库负责选择素材并进入编辑，绘制素材负责实际修改、适配与保存。导入素材和手绘素材都进入同一套 `PixelAsset` 模型与 repository。

**Tech Stack:** React, TypeScript, Vite, Vitest, Dexie

---

## File Structure

- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\asset-library\imported-asset.ts`
  - 处理导入图片到 `PixelAsset` 的转换
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\asset-library\pixel-asset-save-mode.ts`
  - 封装覆盖/另存为保存策略
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\AssetBrowserScreen.tsx`
  - 增加导入入口
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\DrawingAssetsScreen.tsx`
  - 加入“适配模板尺寸”和保存模式对话
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\persistence\repositories\asset-library-repository.ts`
  - 支持覆盖与另存为调用路径
- Test: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\asset-library\imported-asset.test.ts`
- Test: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\asset-library\pixel-asset-save-mode.test.ts`

### Task 1: 建立导入图片到 PixelAsset 的共享转换逻辑

**Files:**
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\asset-library\imported-asset.ts`
- Test: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\asset-library\imported-asset.test.ts`

- [ ] **Step 1: 写失败测试，锁定保留原始尺寸和来源信息**

```ts
it('creates an imported pixel asset without changing original size', async () => {
  const asset = await createImportedPixelAsset({
    id: 'import-1',
    name: '外部石砖',
    layerId: 'ground',
    imageDataUrl: 'data:image/png;base64,xx',
    width: 20,
    height: 12,
  })

  expect(asset.pixelWidth).toBe(20)
  expect(asset.pixelHeight).toBe(12)
  expect(asset.sourceType).toBe('imported')
})
```

- [ ] **Step 2: 运行测试，确认导入转换工具不存在**

Run: `npm test -- --run src/domain/asset-library/imported-asset.test.ts`

Expected: FAIL。

- [ ] **Step 3: 实现最小导入转换**

```ts
export async function createImportedPixelAsset(input: {
  id: string
  name: string
  layerId: AssetLayerId
  imageDataUrl: string
  width: number
  height: number
}): Promise<PixelAsset> {
  return {
    id: input.id,
    name: input.name,
    layerId: input.layerId,
    baseResolution: 8,
    previewTileSize: normalizePreviewTileSize(Math.max(input.width, input.height)),
    pixelWidth: input.width,
    pixelHeight: input.height,
    pixels: await decodePixelsFromImage(input.imageDataUrl, input.width, input.height),
    thumbnail: input.imageDataUrl,
    updatedAt: new Date().toISOString(),
    tags: [],
    defaultTiling: false,
    sourceType: 'imported',
    sourceMeta: { imported: true },
  }
}
```

- [ ] **Step 4: 跑测试**

Run: `npm test -- --run src/domain/asset-library/imported-asset.test.ts`

Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add src/domain/asset-library/imported-asset.ts src/domain/asset-library/imported-asset.test.ts
git commit -m "feat: add imported asset conversion"
```

### Task 2: 在素材库中加入导入入口，并进入统一资产仓库

**Files:**
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\AssetBrowserScreen.tsx`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\persistence\repositories\asset-library-repository.ts`
- Test: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\AssetBrowserScreen.test.tsx`

- [ ] **Step 1: 写失败测试，锁定导入按钮和导入后刷新列表**

```tsx
it('shows an import button in asset browser', () => {
  const html = renderToStaticMarkup(<AssetBrowserScreen onBack={() => {}} onEditAsset={() => {}} />)
  expect(html).toContain('导入素材')
})
```

- [ ] **Step 2: 运行测试，确认当前浏览页无导入入口**

Run: `npm test -- --run src/presentation/react-shell/dev-mode/AssetBrowserScreen.test.tsx`

Expected: FAIL。

- [ ] **Step 3: 实现导入入口**

```tsx
<label className="menu-btn secondary">
  导入素材
  <input
    hidden
    type="file"
    accept="image/png,image/jpeg,image/webp"
    onChange={handleImportFile}
  />
</label>
```

```tsx
async function handleImportFile(event: React.ChangeEvent<HTMLInputElement>) {
  const file = event.target.files?.[0]
  if (!file) return
  const imageDataUrl = await readFileAsDataUrl(file)
  const { width, height } = await loadImageSize(imageDataUrl)
  const asset = await createImportedPixelAsset({
    id: `pixel-${Date.now()}`,
    name: file.name.replace(/\.[^.]+$/, ''),
    layerId: 'ground',
    imageDataUrl,
    width,
    height,
  })
  await repoRef.current.save(asset)
  await refreshAssets()
}
```

- [ ] **Step 4: 跑测试**

Run: `npm test -- --run src/presentation/react-shell/dev-mode/AssetBrowserScreen.test.tsx`

Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add src/presentation/react-shell/dev-mode/AssetBrowserScreen.tsx src/persistence/repositories/asset-library-repository.ts src/presentation/react-shell/dev-mode/AssetBrowserScreen.test.tsx
git commit -m "feat: allow importing assets from browser module"
```

### Task 3: 在绘制素材模块加入模板适配与覆盖/另存为保存

**Files:**
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\asset-library\pixel-asset-save-mode.ts`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\DrawingAssetsScreen.tsx`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\PixelEditorInspector.tsx`
- Test: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\asset-library\pixel-asset-save-mode.test.ts`

- [ ] **Step 1: 写失败测试，锁定覆盖和另存为两条路径**

```ts
it('overwrites an asset without changing id', () => {
  const result = buildAssetSavePayload('overwrite', { id: 'floor-1', name: '木地板' }, '木地板')
  expect(result.id).toBe('floor-1')
})

it('creates a new asset id for save-as mode', () => {
  const result = buildAssetSavePayload('save-as', { id: 'floor-1', name: '木地板' }, '木地板-副本')
  expect(result.id).not.toBe('floor-1')
  expect(result.name).toBe('木地板-副本')
})
```

- [ ] **Step 2: 运行测试，确认保存策略工具不存在**

Run: `npm test -- --run src/domain/asset-library/pixel-asset-save-mode.test.ts`

Expected: FAIL。

- [ ] **Step 3: 实现保存模式和模板适配入口**

```ts
export type PixelAssetSaveMode = 'overwrite' | 'save-as'

export function buildAssetSavePayload(mode: PixelAssetSaveMode, asset: PixelAsset, nextName: string): PixelAsset {
  if (mode === 'overwrite') {
    return { ...asset, name: nextName, updatedAt: new Date().toISOString() }
  }
  return {
    ...asset,
    id: `pixel-${Date.now()}`,
    name: nextName,
    updatedAt: new Date().toISOString(),
  }
}
```

```tsx
<button type="button" onClick={() => dispatch({ type: 'set-preview-tile-size', size: 32 })}>
  适配 32x32 模板
</button>
<button type="button" onClick={() => handleSave('overwrite')}>覆盖原素材</button>
<button type="button" onClick={() => handleSave('save-as')}>另存为</button>
```

- [ ] **Step 4: 跑测试**

Run: `npm test -- --run src/domain/asset-library/pixel-asset-save-mode.test.ts src/domain/asset-library/pixel-editor-reducer.test.ts`

Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add src/domain/asset-library/pixel-asset-save-mode.ts src/presentation/react-shell/dev-mode/DrawingAssetsScreen.tsx src/presentation/react-shell/dev-mode/PixelEditorInspector.tsx src/domain/asset-library/pixel-asset-save-mode.test.ts
git commit -m "feat: add asset template adaptation and save modes"
```

### Task 4: 打通素材库详情到绘制素材的回环编辑

**Files:**
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\AssetBrowserDetail.tsx`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\DeveloperModeShell.tsx`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\DrawingAssetsScreen.tsx`
- Test: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\AssetBrowserScreen.test.tsx`

- [ ] **Step 1: 写失败测试，锁定“编辑”后进入像素画板**

```tsx
it('opens selected imported asset in drawing editor', async () => {
  // 渲染 shell，点击素材详情中的“编辑”
  // 断言 DrawingAssetsScreen 收到初始 asset id
  expect(screen.getByText('覆盖原素材')).toBeInTheDocument()
})
```

- [ ] **Step 2: 运行测试，确认回环编辑没打通**

Run: `npm test -- --run src/presentation/react-shell/dev-mode/AssetBrowserScreen.test.tsx`

Expected: FAIL。

- [ ] **Step 3: 实现回环编辑**

```tsx
function handleOpenDrawingAsset(assetId: string) {
  setPendingEditAssetId(assetId)
  setActiveModule('drawing-assets')
}
```

```tsx
<AssetBrowserDetail
  asset={selectedAsset}
  onEdit={() => onEditAsset(selectedAsset.id)}
/>
```

- [ ] **Step 4: 跑测试与构建**

Run: `npm test -- --run src/presentation/react-shell/dev-mode/AssetBrowserScreen.test.tsx src/domain/asset-library/imported-asset.test.ts src/domain/asset-library/pixel-asset-save-mode.test.ts`

Run: `npm run build`

Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add src/presentation/react-shell/dev-mode/AssetBrowserDetail.tsx src/presentation/react-shell/dev-mode/DeveloperModeShell.tsx src/presentation/react-shell/dev-mode/DrawingAssetsScreen.tsx src/presentation/react-shell/dev-mode/AssetBrowserScreen.test.tsx
git commit -m "feat: support roundtrip asset editing workflow"
```

### Task 5: 页面验证

**Files:**
- Verify only

- [ ] **Step 1: 跑全量测试**

Run: `npm test -- --run`

Expected: PASS。

- [ ] **Step 2: 跑全量构建**

Run: `npm run build`

Expected: PASS。

- [ ] **Step 3: 打开预览**

Run: `npm run preview -- --host 127.0.0.1 --port 4183`

Expected: 输出 `http://127.0.0.1:4183/`。

- [ ] **Step 4: 校验页面可达**

Run: `node -e "fetch('http://127.0.0.1:4183/').then(r=>console.log(r.status)).catch(e=>{console.error(e);process.exit(1)})"`

Expected: 输出 `200`。

- [ ] **Step 5: 提交**

```bash
git add .
git commit -m "chore: verify asset import and roundtrip editing"
```
