# AIRPGWeb Asset System Overall Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把当前单一的素材页面重构为共享同一仓库模型的 `绘制素材` 与 `素材库` 两个模块，并为后续平铺、导入、二次编辑建立统一基础。

**Architecture:** 先统一 `PixelAsset` 元数据和 Dexie 仓库接口，再拆分开发模式入口与页面容器，最后把“打开已有素材编辑”的上下文贯穿到 `DeveloperModeShell -> 绘制素材`。平铺、素材库浏览、导入编辑各自独立实现，但都依赖这份共享基础设施。

**Tech Stack:** React, TypeScript, Vite, Vitest, Dexie

---

## File Structure

- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\asset-library\asset-library-types.ts`
  - 统一素材元数据字段，承载 `tags`、`sourceType`、`sourceMeta`、`defaultTiling`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\persistence\db\airpg-db.ts`
  - 升级 Dexie schema，支持基于名字、layer、updatedAt 的查询扩展
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\persistence\repositories\asset-library-repository.ts`
  - 扩展统一仓库 API，提供 `list/get/save/search`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\DeveloperModeShell.tsx`
  - 拆出 `drawing-assets` 与 `asset-browser` 模块入口
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\DeveloperModeHome.tsx`
  - 更新开发模式菜单文案与按钮
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\DrawingAssetsScreen.tsx`
  - 承接现有像素编辑器职责，替代直接挂在旧 `AssetLibraryScreen`
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\asset-library-shared.ts`
  - 放置共享的缩略图、默认搜索条件、素材来源显示等小工具
- Test: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\asset-library\asset-library-types.test.ts`
- Test: `g:\UEGameDevelopment\Project\AIRPGWeb\src\persistence\repositories\asset-library-repository.test.ts`

### Task 1: 统一素材模型与仓库接口

**Files:**
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\asset-library\asset-library-types.ts`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\persistence\db\airpg-db.ts`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\persistence\repositories\asset-library-repository.ts`
- Test: `g:\UEGameDevelopment\Project\AIRPGWeb\src\domain\asset-library\asset-library-types.test.ts`
- Test: `g:\UEGameDevelopment\Project\AIRPGWeb\src\persistence\repositories\asset-library-repository.test.ts`

- [ ] **Step 1: 写失败测试，锁定新增元数据和仓库查询面**

```ts
it('creates a pixel asset with searchable metadata defaults', () => {
  const asset = createEmptyPixelAsset({
    id: 'pixel-1',
    name: '草地补丁',
    layerId: 'ground',
    previewTileSize: 16,
  })

  expect(asset.tags).toEqual([])
  expect(asset.defaultTiling).toBe(false)
  expect(asset.sourceType).toBe('drawn')
  expect(asset.sourceMeta).toEqual({})
})

it('filters assets by name, tag and size', async () => {
  const repo = createAssetLibraryRepository()
  await repo.save({
    ...createEmptyPixelAsset({ id: 'a', name: '苔藓砖', layerId: 'ground', previewTileSize: 16 }),
    tags: ['moss', 'floor'],
  })

  const list = await repo.search({ query: '苔藓', tag: 'moss', width: 16, height: 16 })
  expect(list.map((item) => item.id)).toEqual(['a'])
})
```

- [ ] **Step 2: 运行测试，确认当前实现失败**

Run: `npm test -- --run src/domain/asset-library/asset-library-types.test.ts src/persistence/repositories/asset-library-repository.test.ts`

Expected: FAIL，报出 `tags/defaultTiling/sourceType/sourceMeta` 不存在，且 `search` 方法未定义。

- [ ] **Step 3: 最小实现统一素材模型与仓库 API**

```ts
export type PixelAssetSourceType = 'drawn' | 'imported'

export type PixelAsset = {
  id: string
  name: string
  layerId: AssetLayerId
  baseResolution: 8
  previewTileSize: PreviewTileSize
  pixelWidth: number
  pixelHeight: number
  pixels: PixelCell[]
  thumbnail: string | null
  updatedAt: string
  tags: string[]
  defaultTiling: boolean
  sourceType: PixelAssetSourceType
  sourceMeta: Record<string, string | number | boolean>
}
```

```ts
this.version(4).stores({
  saveSlots: 'slotId,savedAt',
  mapAssets: 'id,name,runtimePublished',
  worldAssets: 'id,name,runtimePublished',
  pixelAssets: 'id,name,layerId,updatedAt,pixelWidth,pixelHeight,sourceType',
})
```

```ts
async search(filter: {
  query?: string
  tag?: string
  width?: number
  height?: number
  sourceType?: PixelAssetSourceType
}) {
  const items = await db.pixelAssets.toArray()
  return items
    .filter((item) => !filter.query || item.name.toLowerCase().includes(filter.query.toLowerCase()))
    .filter((item) => !filter.tag || item.tags.includes(filter.tag))
    .filter((item) => !filter.width || item.pixelWidth === filter.width)
    .filter((item) => !filter.height || item.pixelHeight === filter.height)
    .filter((item) => !filter.sourceType || item.sourceType === filter.sourceType)
    .sort((a, b) => b.updatedAt.localeCompare(a.updatedAt))
}
```

- [ ] **Step 4: 运行测试，确认共享基础通过**

Run: `npm test -- --run src/domain/asset-library/asset-library-types.test.ts src/persistence/repositories/asset-library-repository.test.ts`

Expected: PASS，两个测试文件全部通过。

- [ ] **Step 5: 提交**

```bash
git add src/domain/asset-library/asset-library-types.ts src/persistence/db/airpg-db.ts src/persistence/repositories/asset-library-repository.ts src/domain/asset-library/asset-library-types.test.ts src/persistence/repositories/asset-library-repository.test.ts
git commit -m "feat: unify asset metadata and repository contract"
```

### Task 2: 拆分开发模式入口与绘制素材模块容器

**Files:**
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\DeveloperModeShell.tsx`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\DeveloperModeHome.tsx`
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\DrawingAssetsScreen.tsx`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\AssetLibraryScreen.tsx`

- [ ] **Step 1: 写失败测试，锁定新模块入口文案与路由**

```ts
it('renders drawing assets and asset browser entries in developer mode', () => {
  const html = renderToStaticMarkup(<DeveloperModeHome onOpenMapEditor={() => {}} onOpenDrawingAssets={() => {}} onOpenAssetBrowser={() => {}} onBack={() => {}} />)

  expect(html).toContain('绘制素材')
  expect(html).toContain('素材库')
})
```

- [ ] **Step 2: 运行测试，确认当前只有旧入口**

Run: `npm test -- --run src/presentation/react-shell/dev-mode/DeveloperModeHome.test.tsx`

Expected: FAIL，报 `onOpenDrawingAssets/onOpenAssetBrowser` 不存在，或页面仍只有旧 `素材库` 入口。

- [ ] **Step 3: 实现新模块拆分**

```tsx
type ModuleId = 'home' | 'map-editor' | 'drawing-assets' | 'asset-browser'

if (activeModule === 'drawing-assets') {
  return <DrawingAssetsScreen onBack={() => setActiveModule('home')} />
}

if (activeModule === 'asset-browser') {
  return <AssetLibraryScreen onBack={() => setActiveModule('home')} onEditAsset={(id) => {
    setPendingEditAssetId(id)
    setActiveModule('drawing-assets')
  }} />
}
```

```tsx
<DeveloperModeHome
  onOpenMapEditor={() => setActiveModule('map-editor')}
  onOpenDrawingAssets={() => setActiveModule('drawing-assets')}
  onOpenAssetBrowser={() => setActiveModule('asset-browser')}
  onBack={onBack}
/>
```

- [ ] **Step 4: 运行相关测试**

Run: `npm test -- --run src/presentation/react-shell/dev-mode/DeveloperModeHome.test.tsx src/presentation/react-shell/dev-mode/PixelEditorCanvas.test.ts`

Expected: PASS，入口文案更新且像素编辑器容器仍可渲染。

- [ ] **Step 5: 提交**

```bash
git add src/presentation/react-shell/dev-mode/DeveloperModeShell.tsx src/presentation/react-shell/dev-mode/DeveloperModeHome.tsx src/presentation/react-shell/dev-mode/DrawingAssetsScreen.tsx src/presentation/react-shell/dev-mode/AssetLibraryScreen.tsx src/presentation/react-shell/dev-mode/DeveloperModeHome.test.tsx
git commit -m "feat: split drawing assets and asset browser modules"
```

### Task 3: 打通“从素材库打开已有素材到绘制素材”的共享编辑入口

**Files:**
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\DrawingAssetsScreen.tsx`
- Modify: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\AssetLibraryScreen.tsx`
- Create: `g:\UEGameDevelopment\Project\AIRPGWeb\src\presentation\react-shell\dev-mode\asset-library-shared.ts`
- Test: `g:\UEGameDevelopment\Project\AIRPGWeb\src\persistence\repositories\asset-library-repository.test.ts`

- [ ] **Step 1: 写失败测试，锁定传递待编辑素材 id 的行为**

```ts
it('loads an existing asset into drawing assets screen', async () => {
  const repo = createAssetLibraryRepository()
  await repo.save(createEmptyPixelAsset({ id: 'edit-me', name: '木板', layerId: 'ground', previewTileSize: 16 }))

  const result = await loadDrawingAsset(repo, 'edit-me')
  expect(result?.asset.id).toBe('edit-me')
})
```

- [ ] **Step 2: 运行测试，确认当前缺少共享加载入口**

Run: `npm test -- --run src/persistence/repositories/asset-library-repository.test.ts`

Expected: FAIL，缺少 `loadDrawingAsset` 或等价共享逻辑。

- [ ] **Step 3: 实现共享编辑入口和兜底行为**

```ts
export async function loadDrawingAsset(repo: ReturnType<typeof createAssetLibraryRepository>, assetId: string | null) {
  if (!assetId) {
    return null
  }
  const loaded = await repo.get(assetId)
  return loaded ? createInitialPixelEditorState(loaded) : null
}
```

```tsx
useEffect(() => {
  if (!initialAssetId) {
    return
  }
  loadDrawingAsset(repoRef.current, initialAssetId).then((nextState) => {
    if (nextState) {
      setCurrentAssetId(initialAssetId)
      setEditorState(nextState)
    }
  })
}, [initialAssetId])
```

- [ ] **Step 4: 运行测试并做基础构建**

Run: `npm test -- --run src/persistence/repositories/asset-library-repository.test.ts src/domain/asset-library/pixel-editor-reducer.test.ts`

Run: `npm run build`

Expected: PASS，仓库与编辑入口测试通过，构建成功。

- [ ] **Step 5: 提交**

```bash
git add src/presentation/react-shell/dev-mode/DrawingAssetsScreen.tsx src/presentation/react-shell/dev-mode/AssetLibraryScreen.tsx src/presentation/react-shell/dev-mode/asset-library-shared.ts src/persistence/repositories/asset-library-repository.test.ts
git commit -m "feat: support opening saved assets in drawing editor"
```

### Task 4: 全量验证与页面可达性确认

**Files:**
- Verify only

- [ ] **Step 1: 运行回归测试**

Run: `npm test -- --run`

Expected: PASS，现有回归测试全部通过。

- [ ] **Step 2: 运行构建**

Run: `npm run build`

Expected: PASS，输出 `dist/` 资源且退出码为 `0`。

- [ ] **Step 3: 打开预览页**

Run: `npm run preview -- --host 127.0.0.1 --port 4180`

Expected: 输出本地预览地址，例如 `http://127.0.0.1:4180/`。

- [ ] **Step 4: 校验页面可访问**

Run: `node -e "fetch('http://127.0.0.1:4180/').then(r=>console.log(r.status)).catch(e=>{console.error(e);process.exit(1)})"`

Expected: 输出 `200`。

- [ ] **Step 5: 提交**

```bash
git add .
git commit -m "chore: verify shared asset system foundation"
```
