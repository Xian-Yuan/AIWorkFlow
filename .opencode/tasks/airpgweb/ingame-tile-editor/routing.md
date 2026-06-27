# Routing Decision

## Task

`AIRPGWeb` 游戏内 Tile 地图编辑器首版落地。

## Project Type

- `web`

## Main Skill

- `web-fullstack`

## Secondary Skills

- `subagent-driven-development`
- `webapp-testing`

## Main Chain

- React 壳层内新增 `开发者模式`
- 地图绘制模块入口
- `MapAsset / WorldAsset` 结构化数据
- 分层 tile 绘制与地图保存/打开
- 运行时地图桥接
- 素材库与地图编辑器共享画板系统、共享工具系统
- 固定尺寸模板驱动像素素材真实尺寸与地图占格语义

## Secondary Chain

- 相邻地图幽灵层预览
- AI 房屋布局草稿与指定层美化建议
- Playwright / Vitest / build 回归验证
- 素材库绘制缩放与单像素精细编辑
- 旧像素素材兼容读取与尺寸迁移兜底

## Why This Route

- 需求落点明确在 `Project/AIRPGWeb`
- 技术栈为 React + TypeScript + Dexie + Playwright
- 任务横跨 UI、domain、persistence、runtime、testing，多文件改动明显超过 8 个
- 不属于 UE5/Lyra/GAS 实现链路

## Required Reading

- `Docs/AI/01-AI-Development-Playbook.md`
- `Docs/AI/02-Project-Truth-Source.md`
- `Docs/AI/11-Skill-Routing-Workflow.md`
- `Docs/AI/12-MultiAgent-Workflow.md`
- `Docs/superpowers/specs/2026-05-31-airpgweb-ingame-tile-map-editor-design.md`
- `Docs/superpowers/specs/2026-05-31-airpgweb-tile-editor-open-source-research.md`
- `Docs/superpowers/plans/2026-05-31-airpgweb-ingame-tile-map-editor-plan.md`

## Collaboration Mode

- `multi-agent`
- Controller 负责状态机、任务推进、验证收口
- 实现按计划任务分发给独立上下文 agent

## Allowed Scope

- `Project/AIRPGWeb/src/App.tsx`
- `Project/AIRPGWeb/src/App.css`
- `Project/AIRPGWeb/src/domain/map-editor/*`
- `Project/AIRPGWeb/src/persistence/db/airpg-db.ts`
- `Project/AIRPGWeb/src/persistence/repositories/*`
- `Project/AIRPGWeb/src/runtime/world/*`
- `Project/AIRPGWeb/src/presentation/react-shell/*`
- `Project/AIRPGWeb/tests/*`
- 必要时同步 `Docs/superpowers/specs/2026-05-31-airpgweb-ingame-tile-map-editor-design.md`

## Forbidden Scope

- 不顺手扩展非地图主线 UI 需求
- 不引入真实联网、多人同步、远程存档方案
- 不在首版中默认接入真实模型 API，先以本地规则化 AI 草稿合同为主
- 不回退或覆盖用户现有未完成改动

## Risks

- 旧存档/继续游戏链路未完全收口，运行时地图桥接时可能暴露耦合
- Dexie schema 升级会影响现有本地数据
- 文本地图渲染与 tile 运行时桥接存在表现层兼容风险
- 开发者模式 UI 容易与现有开始界面样式发生冲突
- 当前像素素材存在“预览尺寸被理解为真实尺寸”的历史语义包袱，兼容策略要谨慎
- 共享画板系统同时影响 asset-library 与 map-editor，回归面会显著扩大

## Missing Information

- 首版 AI 辅助是否只做规则模板，后续再接真实模型
- 首版世界拼接是否只做固定相邻预览，不做自由缩放/拖拽
- 旧素材是否需要在首次打开时自动迁移尺寸元数据，还是保持兼容读取
- 固定尺寸模板当前只支持正方形 `8x8 / 16x16 / 24x24 / 32x32`，暂不扩展矩形模板
