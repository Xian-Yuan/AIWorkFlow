# AIRPGWeb Asset Library Browser Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新建真正的 `素材库` 浏览模块，提供卡片列表、名字/tag/尺寸搜索、详情预览和跳转到绘制素材编辑的工作流。

**Architecture:** 在共享仓库模型之上新增浏览页面与详情面板，页面只负责“看、搜、筛、打开编辑”，不再承担主像素编辑器职责。查询逻辑尽量放进 repository，而不是散落在组件内部。

**Tech Stack:** React, TypeScript, Vite, Vitest, Dexie

---

## File Structure

- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\AssetBrowserScreen.tsx`
  - 新素材库主屏
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\AssetBrowserGrid.tsx`
  - 素材卡片网格
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\AssetBrowserDetail.tsx`
  - 素材详情与操作按钮
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\asset-browser.css`
  - 浏览模块样式
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\persistence\repositories\asset-library-repository.ts`
  - 提供基于名字/tag/尺寸的查询
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\DeveloperModeShell.tsx`
  - 挂接新 `AssetBrowserScreen`
- Test: `g:\UEGameDevelopment\Project\AIRPGWeb\src\persistence\repositories\asset-library-repository.test.ts`
- Test: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\AssetBrowserScreen.test.tsx`

### Task 1: 扩展 repository 查询并锁定浏览输入模型

**Files:**
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\persistence\repositories\asset-library-repository.ts`
- Test: `g:\UEGameDevelopment\Project\AIRPGWeb\src\persistence\repositories\asset-library-repository.test.ts`

- [ ] **Step 1: 写失败测试，锁定名字/tag/尺寸组合查询**

```ts
it('searches by name tag and size together', async () => {
  const repo = createAssetLibraryRepository()
  await repo.save({
    ...createEmptyPixelAsset({ id: 'stone-1', name: '石砖地板', layerId: 'ground', previewTileSize: 16 }),
    tags: ['stone', 'floor'],
  })

  const result = await repo.search({ query: '石砖', tag: 'floor', width: 16, height: 16 })
  expect(result.map((item) => item.id)).toEqual(['stone-1'])
})
```

- [ ] **Step 2: 运行测试，确认当前查询条件不完整**

Run: `npm test -- --run src/persistence/repositories/asset-library-repository.test.ts`

Expected: FAIL。

- [ ] **Step 3: 实现最小查询面**

```ts
export type AssetSearchFilter = {
  query?: string
  tag?: string
  width?: number
  height?: number
}

async search(filter: AssetSearchFilter) {
  const items = await db.pixelAssets.toArray()
  return items
    .filter((item) => !filter.query || item.name.toLowerCase().includes(filter.query.toLowerCase()))
    .filter((item) => !filter.tag || item.tags.some((tag) => tag.toLowerCase().includes(filter.tag!.toLowerCase())))
    .filter((item) => !filter.width || item.pixelWidth === filter.width)
    .filter((item) => !filter.height || item.pixelHeight === filter.height)
    .sort((a, b) => b.updatedAt.localeCompare(a.updatedAt))
}
```

- [ ] **Step 4: 运行测试**

Run: `npm test -- --run src/persistence/repositories/asset-library-repository.test.ts`

Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add src/persistence/repositories/asset-library-repository.ts src/persistence/repositories/asset-library-repository.test.ts
git commit -m "feat: add asset browser search filters"
```

### Task 2: 建立素材库浏览页面与卡片网格

**Files:**
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\AssetBrowserScreen.tsx`
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\AssetBrowserGrid.tsx`
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\asset-browser.css`
- Test: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\AssetBrowserScreen.test.tsx`

- [ ] **Step 1: 写失败测试，锁定搜索表单与卡片字段**

```tsx
it('renders asset cards with name size and tags', () => {
  const html = renderToStaticMarkup(
    <AssetBrowserGrid
      assets={[{
        id: 'grass-1',
        name: '草地补丁',
        pixelWidth: 16,
        pixelHeight: 16,
        thumbnail: 'data:image/png;base64,xx',
        tags: ['ground', 'green'],
        updatedAt: '2026-06-01T00:00:00.000Z',
        sourceType: 'drawn',
      }]}
      selectedAssetId={null}
      onSelect={() => {}}
    />,
  )

  expect(html).toContain('草地补丁')
  expect(html).toContain('16x16')
  expect(html).toContain('ground')
})
```

- [ ] **Step 2: 运行测试，确认浏览模块还不存在**

Run: `npm test -- --run src/presentation/react-shell/dev-mode/AssetBrowserScreen.test.tsx`

Expected: FAIL，文件或组件不存在。

- [ ] **Step 3: 实现浏览主屏与卡片网格**

```tsx
export function AssetBrowserScreen({ onBack, onEditAsset }: AssetBrowserScreenProps) {
  const repoRef = useRef(createAssetLibraryRepository())
  const [query, setQuery] = useState('')
  const [tag, setTag] = useState('')
  const [size, setSize] = useState('')
  const [assets, setAssets] = useState<PixelAsset[]>([])
  const [selectedAssetId, setSelectedAssetId] = useState<string | null>(null)
  // ...
}
```

```tsx
<article className={`asset-browser-card ${selected ? 'active' : ''}`} onClick={() => onSelect(asset.id)}>
  <img src={asset.thumbnail ?? ''} alt={asset.name} />
  <h3>{asset.name}</h3>
  <p>{asset.pixelWidth}x{asset.pixelHeight}</p>
  <p>{asset.tags.join(', ')}</p>
</article>
```

- [ ] **Step 4: 运行测试**

Run: `npm test -- --run src/presentation/react-shell/dev-mode/AssetBrowserScreen.test.tsx`

Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add src/presentation/react-shell/dev-mode/AssetBrowserScreen.tsx src/presentation/react-shell/dev-mode/AssetBrowserGrid.tsx src/presentation/react-shell/dev-mode/asset-browser.css src/presentation/react-shell/dev-mode/AssetBrowserScreen.test.tsx
git commit -m "feat: add asset browser grid screen"
```

### Task 3: 加入素材详情预览和“编辑”跳转

**Files:**
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\AssetBrowserDetail.tsx`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\AssetBrowserScreen.tsx`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\DeveloperModeShell.tsx`
- Test: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\AssetBrowserScreen.test.tsx`

- [ ] **Step 1: 写失败测试，锁定详情面板和编辑按钮**

```tsx
it('shows selected asset detail and edit action', () => {
  const html = renderToStaticMarkup(
    <AssetBrowserDetail
      asset={{
        id: 'floor-1',
        name: '木地板',
        pixelWidth: 32,
        pixelHeight: 32,
        previewTileSize: 32,
        thumbnail: 'data:image/png;base64,xx',
        tags: ['wood', 'floor'],
        defaultTiling: false,
        sourceType: 'drawn',
        updatedAt: '2026-06-01T00:00:00.000Z',
      }}
      onEdit={() => {}}
    />,
  )

  expect(html).toContain('木地板')
  expect(html).toContain('编辑')
  expect(html).toContain('默认平铺')
})
```

- [ ] **Step 2: 运行测试，确认详情面板不存在**

Run: `npm test -- --run src/presentation/react-shell/dev-mode/AssetBrowserScreen.test.tsx`

Expected: FAIL。

- [ ] **Step 3: 实现详情面板与跳转**

```tsx
<AssetBrowserDetail
  asset={selectedAsset}
  onEdit={() => {
    if (selectedAsset) {
      onEditAsset(selectedAsset.id)
    }
  }}
/>
```

```tsx
if (activeModule === 'asset-browser') {
  return <AssetBrowserScreen onBack={() => setActiveModule('home')} onEditAsset={handleOpenDrawingAsset} />
}
```

- [ ] **Step 4: 运行测试**

Run: `npm test -- --run src/presentation/react-shell/dev-mode/AssetBrowserScreen.test.tsx`

Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add src/presentation/react-shell/dev-mode/AssetBrowserDetail.tsx src/presentation/react-shell/dev-mode/AssetBrowserScreen.tsx src/presentation/react-shell/dev-mode/DeveloperModeShell.tsx src/presentation/react-shell/dev-mode/AssetBrowserScreen.test.tsx
git commit -m "feat: add asset browser detail and edit entry"
```

### Task 4: 回归验证

**Files:**
- Verify only

- [ ] **Step 1: 跑浏览模块相关测试**

Run: `npm test -- --run src/persistence/repositories/asset-library-repository.test.ts src/presentation/react-shell/dev-mode/AssetBrowserScreen.test.tsx`

Expected: PASS。

- [ ] **Step 2: 跑全量构建**

Run: `npm run build`

Expected: PASS。

- [ ] **Step 3: 打开预览**

Run: `npm run preview -- --host 127.0.0.1 --port 4182`

Expected: 输出 `http://127.0.0.1:4182/`。

- [ ] **Step 4: 校验页面可达**

Run: `node -e "fetch('http://127.0.0.1:4182/').then(r=>console.log(r.status)).catch(e=>{console.error(e);process.exit(1)})"`

Expected: 输出 `200`。

- [ ] **Step 5: 提交**

```bash
git add .
git commit -m "chore: verify asset browser module"
```
