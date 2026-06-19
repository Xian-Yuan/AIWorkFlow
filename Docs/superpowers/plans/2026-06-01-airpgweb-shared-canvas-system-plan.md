# AIRPGWeb Shared Canvas System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 统一素材库与地图编辑器的画板系统、工具系统与尺寸语义，确保素材库选择的 `8x8 / 16x16 / 24x24 / 32x32` 模板会以真实尺寸保存，并在地图编辑器中按 `1:1` 占格显示。

**Architecture:** 保留地图编辑器现有工具行为作为基准，把素材库从“预览规格驱动”的旧模型迁移为“真实尺寸模板 + 视图缩放”模型。共享逻辑优先沉到 domain 层，UI 只负责展示尺寸模板、缩放和工具入口。

**Tech Stack:** React 19, TypeScript, Vite, Vitest

---

### Task 1: 修正像素素材尺寸语义

**Files:**
- Modify: `Project/AIRPGWeb/src/domain/asset-library/asset-library-types.ts`
- Modify: `Project/AIRPGWeb/src/domain/asset-library/pixel-editor-reducer.ts`
- Modify: `Project/AIRPGWeb/src/domain/asset-library/asset-library-types.test.ts`
- Modify: `Project/AIRPGWeb/src/persistence/repositories/asset-library-repository.test.ts`

- [ ] **Step 1: 写失败测试，锁定“尺寸模板决定真实尺寸”**
  - 在 `asset-library-types.test.ts` 增加断言：新建 `16x16` 模板素材时，`pixelWidth=16`、`pixelHeight=16`；`32x32` 同理。
  - 在 `asset-library-repository.test.ts` 增加断言：保存并重新读取后，真实尺寸保持不变。

- [ ] **Step 2: 跑测试确认当前实现失败**
  - Run: `npm test -- --run src/domain/asset-library/asset-library-types.test.ts src/persistence/repositories/asset-library-repository.test.ts`
  - Expected: 至少 1 条关于真实尺寸的断言失败，因为当前素材仍默认初始化为 `8x8`。

- [ ] **Step 3: 最小实现资产模型重构**
  - 把 `previewTileSize` 的职责重命名或降级为纯显示字段，新增明确的尺寸模板来源。
  - 让 `createEmptyPixelAsset()` 根据模板创建真实 `pixelWidth / pixelHeight` 和对应 `pixels` 数组。
  - 保持旧素材兼容读取：若缺少新字段，则回退到现有真实宽高，不删除旧数据。

- [ ] **Step 4: 复跑测试确认通过**
  - Run: `npm test -- --run src/domain/asset-library/asset-library-types.test.ts src/persistence/repositories/asset-library-repository.test.ts`
  - Expected: PASS

- [ ] **Step 5: 提交**
  - Commit message: `feat: align pixel asset size template with real dimensions`

### Task 2: 扩展素材库画板与属性面板

**Files:**
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/PixelEditorInspector.tsx`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/PixelEditorCanvas.tsx`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/AssetLibraryScreen.tsx`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/asset-library.css`
- Test: `Project/AIRPGWeb/src/domain/asset-library/pixel-editor-reducer.test.ts`

- [ ] **Step 1: 写失败测试，锁定尺寸模板与缩放语义**
  - 增加 reducer 测试：切换尺寸模板会重建对应大小的像素网格；调整 `canvasZoom` 不改变 `pixelWidth / pixelHeight`。

- [ ] **Step 2: 跑测试确认失败**
  - Run: `npm test -- --run src/domain/asset-library/pixel-editor-reducer.test.ts`
  - Expected: FAIL，因为当前 reducer 仅支持预览规格变化，不支持真实尺寸模板。

- [ ] **Step 3: 最小实现 UI 与状态改造**
  - 在 Inspector 中把“预览规格”改成“素材尺寸模板”，提供 `8x8 / 16x16 / 24x24 / 32x32`。
  - 让 `PixelEditorCanvas` 根据真实 `pixelWidth / pixelHeight` 渲染更大的像素网格。
  - 保留缩放按钮，但明确它只控制视图像素大小，不改变素材真实尺寸。
  - 调整素材库布局，让更大模板下的画板可视区域明显大于当前固定 `8x8`。

- [ ] **Step 4: 复跑测试确认通过**
  - Run: `npm test -- --run src/domain/asset-library/pixel-editor-reducer.test.ts`
  - Expected: PASS

- [ ] **Step 5: 提交**
  - Commit message: `feat: support fixed pixel canvas templates in asset library`

### Task 3: 提炼共享画板与工具行为

**Files:**
- Modify: `Project/AIRPGWeb/src/domain/asset-library/pixel-editor-reducer.ts`
- Modify: `Project/AIRPGWeb/src/domain/map-editor/editor-reducer.ts`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/PixelEditorCanvas.tsx`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileCanvas.tsx`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/AssetLibraryScreen.tsx`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/MapEditorScreen.tsx`
- Test: `Project/AIRPGWeb/src/domain/asset-library/pixel-editor-reducer.test.ts`
- Test: `Project/AIRPGWeb/src/domain/map-editor/editor-reducer.test.ts`

- [ ] **Step 1: 写失败测试，锁定共享工具规则**
  - 为素材库测试补齐：画笔、橡皮、吸管、填充、矩形边框与矩形擦除的状态切换规则与地图绘制一致。
  - 为地图编辑器测试确认：现有行为保持不退化。

- [ ] **Step 2: 跑测试确认失败**
  - Run: `npm test -- --run src/domain/asset-library/pixel-editor-reducer.test.ts src/domain/map-editor/editor-reducer.test.ts`
  - Expected: 素材库侧新增断言失败。

- [ ] **Step 3: 最小实现共享状态组织**
  - 以地图绘制现有工具模型为基准，统一素材库工具组织与入口命名。
  - 能沉到共享 helper 的逻辑优先沉到 domain/helper，避免两边继续各自维护一套行为。
  - 保证缩放后的素材库仍能操作单个真实像素。

- [ ] **Step 4: 复跑测试确认通过**
  - Run: `npm test -- --run src/domain/asset-library/pixel-editor-reducer.test.ts src/domain/map-editor/editor-reducer.test.ts`
  - Expected: PASS

- [ ] **Step 5: 提交**
  - Commit message: `refactor: align asset library tools with shared editor behavior`

### Task 4: 回归地图放置尺寸与预览验证

**Files:**
- Modify: `Project/AIRPGWeb/src/domain/map-editor/tile-palette.ts`
- Modify: `Project/AIRPGWeb/src/domain/map-editor/pixel-asset-placement.ts`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/MapEditorScreen.tsx`
- Modify: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileCanvas.tsx`
- Test: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/TileCanvas.test.ts`
- Test: `Project/AIRPGWeb/src/presentation/react-shell/dev-mode/EditorLayerList.test.ts`

- [ ] **Step 1: 写失败测试，锁定“素材库尺寸 = 地图占格尺寸”**
  - 在 `TileCanvas.test.ts` 添加 `16x16`、`24x24`、`32x32` 像素素材的占格断言。
  - 确认缩放变化不影响地图实际占格。

- [ ] **Step 2: 跑测试确认失败**
  - Run: `npm test -- --run src/presentation/react-shell/dev-mode/TileCanvas.test.ts`
  - Expected: FAIL，直到地图侧完全消费新的真实尺寸模型。

- [ ] **Step 3: 最小实现地图侧回归**
  - 让 `tile-palette` 和 `MapEditorScreen` 只传播真实尺寸元数据。
  - 让 `TileCanvas` 放置、预览、渲染都基于真实像素宽高和原子格换算。
  - 确保旧素材仍能显示，不因为新模板接入而消失。

- [ ] **Step 4: 全量验证**
  - Run: `npm test -- --run`
  - Run: `npm run build`
  - Run: `npx vite preview --host 127.0.0.1 --port 4176 --strictPort`
  - Verify: 打开 `http://127.0.0.1:4176/`，确认页面可访问，并手动检查 `8x8 / 16x16 / 24x24 / 32x32` 素材放置占格是否正确。

- [ ] **Step 5: 提交**
  - Commit message: `fix: make map placement follow saved pixel asset dimensions`
