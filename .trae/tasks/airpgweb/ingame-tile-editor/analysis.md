# Analysis

## Goal

在 `AIRPGWeb` 中交付一个首版可用的游戏内 tile 地图编辑器，支持：

- 开发者模式入口
- 分层绘制
- tile palette 按层过滤
- 地图保存、打开、重新编辑
- 多地图拼接与相邻地图幽灵层
- 运行时读取编辑器发布地图
- AI 房屋布局草稿与美化建议

## Dependency Chain

### P0

- `开发者模式` 入口必须先存在，否则地图编辑器无法进入
- 统一 `MapAsset` 数据模型必须先定，否则绘制、保存、运行时桥接会各自漂移
- 编辑器 reducer 必须先定，否则工具栏、图层列表、画布和撤销重做无法共享状态
- Dexie 表必须扩展 `mapAssets / worldAssets`，否则没有保存/打开/发布链路
- 运行时桥接必须定义 `RuntimeMapLoader`，否则“游戏显示自己绘制的地图”无法闭环

### P1

- 相邻地图幽灵层依赖 `WorldPlacement` 与世界组合数据
- AI 草稿层依赖稳定的房屋区域类型、门位和图层命名
- Playwright E2E 依赖稳定的按钮命名和 `data-testid`

## Implicit Requirements

- 图层切换时，只展示当前层可绘制 tile，避免误画层
- tile 数据和最终美术表现分离，后续可切换 `blueprint / microPixel`
- AI 只能输出草稿建议层，不能直接覆盖正式地图
- 多地图世界先支持相邻参考和发布，不把首版范围扩展到完整世界编辑器
- 开发者模式必须能回到主界面，不影响现有正常游戏入口

## Architecture Notes

- UI 壳层：`App.tsx` + `StartScreen.tsx` + `dev-mode/*`
- 编辑器域模型：`src/domain/map-editor/*`
- 持久化：`src/persistence/db/airpg-db.ts` + repositories
- 运行时桥接：`src/runtime/world/runtime-map-loader.ts` + `world-runtime-service.ts`
- 游戏显示接入：`GameShell.tsx` + `TextMapView.tsx`

## Implementation Order Rationale

1. 先打通入口和壳层，建立独立开发者模式路由
2. 再建立 `MapAsset` 与 palette 基础类型，锁定后续所有子系统的共享模型
3. 再做 reducer 和基础编辑器 UI，形成最小可编辑闭环
4. 然后补持久化与 reopen 流程
5. 再做世界拼接与幽灵层
6. 最后桥接运行时显示与 AI 草稿能力

## Open-Source References Absorbed

- `Tiled`：多地图世界组织、相邻地图显示、layer + properties 思路
- 轻量 Web tile editor：左中右三栏编辑器骨架
- autotile 思路：墙体 family 先于单张表现
- runtime bridge：编辑数据与运行时渲染分离

## Risks To Watch

- `App.tsx` 状态增多后容易让开始界面分支继续膨胀
- `TextMapView` 当前如果强依赖静态地图，接入 `mapOverride` 时可能产生双源问题
- Dexie 升版后旧数据兼容需要关注，但本轮先优先首版能力闭环
- 预览服务当前跑在 `http://127.0.0.1:4173`，每次前端改动后要确认最新实例已刷新

## Shared Canvas Refactor Extension

### Goal

把素材库与地图绘制统一到一套画板系统与工具系统，修正当前“`previewTileSize` 只是预览规格、不是素材真实尺寸”的语义断裂，确保：

- 素材库选择 `8x8 / 16x16 / 24x24 / 32x32` 时，保存下来的素材真实尺寸就是对应像素尺寸
- 地图绘制放置素材时，真实占用范围与素材库绘制尺寸 `1:1` 对齐
- 缩放只影响绘制视图，不改变单像素编辑语义
- 素材库画板不再固定只有 `8x8` 原子像素，而是支持固定模板尺寸与更大的可视画板

### Dependency Chain

#### P0

- `PixelAsset` 必须区分“真实尺寸模板”和“视图缩放”，否则素材尺寸与绘制倍率会继续混淆
- 素材库画板必须允许按固定模板重建像素网格，否则无法保存 `16x16 / 24x24 / 32x32` 的真实素材
- 地图 palette 与 `TileCanvas` 必须继续消费真实 `pixelWidth / pixelHeight`，禁止再从预览字段推导占格
- 素材库和地图编辑器必须抽出共享工具/画板配置模型，否则两边行为会继续漂移

#### P1

- 旧素材兼容策略必须明确，否则已有 `8x8` 素材在新系统下可能表现异常
- Inspector 文案与交互必须改成“素材尺寸模板 + 画板缩放”，避免再次误导用户
- 测试需要覆盖“尺寸模板决定地图占格、缩放不改变像素坐标语义”

### Implicit Requirements

- 固定尺寸模板当前只支持正方形：`8x8 / 16x16 / 24x24 / 32x32`
- 绘制时无论缩放多少，都必须能编辑单个真实像素
- 地图绘制与素材库共享工具模型时，要以地图绘制当前行为为准
- 旧素材若缺少新字段，默认按现有真实 `pixelWidth / pixelHeight` 读取，不强制删除或重建

### Architecture Notes

- 资产模型入口：`src/domain/asset-library/asset-library-types.ts`
- 素材库状态机：`src/domain/asset-library/pixel-editor-reducer.ts`
- 共享尺寸换算：`src/domain/map-editor/pixel-asset-placement.ts`
- 素材库 UI：`src/presentation/react-shell/dev-mode/AssetLibraryScreen.tsx`、`PixelEditorCanvas.tsx`、`PixelEditorInspector.tsx`
- 地图落地链路：`src/presentation/react-shell/dev-mode/MapEditorScreen.tsx`、`TileCanvas.tsx`、`src/domain/map-editor/tile-palette.ts`

### Implementation Order Rationale

1. 先修正资产模型命名与尺寸语义，锁定“真实尺寸 vs 视图缩放”
2. 再让素材库画板支持固定尺寸模板，形成正确保存链路
3. 再抽共享画板/工具配置，减少素材库与地图编辑器重复逻辑
4. 最后做地图侧回归和旧素材兼容验证，避免放置逻辑再次漂移

### Risks To Watch

- 当前数据库中的素材记录可能只依赖旧的 `previewTileSize` 交互认知，需要兼容旧数据读取
- 共享画板系统会同时波及 reducer、画布、inspector、地图 palette 和测试，改动面大
- 若把缩放和真实尺寸重新耦合，仍会再次出现“看起来是 32x32，实际只有 8x8”的回归
