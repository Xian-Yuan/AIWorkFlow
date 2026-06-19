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

