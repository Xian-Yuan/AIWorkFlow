# Routing — combat-sandbox（沙盒战斗测试模式）

## 路由决策

| 字段 | 值 |
|------|-----|
| 主 Skill | `web-fullstack` |
| 次 Skill | `ui-ux-pro-max` |
| 项目类型 | Web |
| 任务名 | combat-sandbox |
| 实现模式 | multi_agent |
| 确认状态 | 待用户确认 |

## 主链路

```
DeveloperModeShell.tsx (新模块注册)
  → SandboxScreen.tsx (沙盒主界面 React)
    ├── UnitCategoryPanel (分类树: NPC / 敌人 / 野兽 / Boss / 精英 / 友方)
    ├── UnitSpawnPanel (单位模板选择 + 属性预览)
    ├── SandboxMapSelector (复用 map-editor 中已保存的地图)
    ├── PlayerStatEditor (主角属性/装备编辑面板)
    ├── EquipmentAssignPanel (装备赋予面板)
    └── BattleControlPanel (战斗触发 + 回合控制)
  → SandboxScene.ts (Phaser 独立场景 — 渲染沙盒地图 + 单位)
  → Domain 层
    ├── sandbox-types.ts (新建: 沙盒单位/场景/地图类型)
    ├── sandbox-unit-templates.ts (新建: NPC/敌人/野兽/Boss 预设模板)
    ├── resolve-full-attack.ts (复用: 12 步战斗管线)
    └── equipment-types.ts (复用: 武器/防具/盾牌/品质体系)
```

## 次链路

```
ui-ux-pro-max 负责:
  - 分类面板 UX 设计 (树形分类 + 快速筛选)
  - 数值编辑器交互 (滑条/输入框混排)
  - 装备选择器 UI (从素材库选装备赋予单位)
  - 战斗日志展示面板
```

## 依赖链

```text
沙盒战斗测试模式
  ├── P0: 单位模板数据 (sandbox-unit-templates.ts) — NPC/敌人/野兽/Boss/精英/友方
  ├── P0: 沙盒类型定义 (sandbox-types.ts) — SandboxUnit / SandboxScene / SandboxMapRef
  ├── P0: SandboxScreen React 组件 (主 UI)
  ├── P0: DeveloperModeShell 新增路由 & DeveloperModeHome 新增按钮
  ├── P1: Phaser SandboxScene (独立场景，渲染沙盒地图+单位)
  ├── P1: 装备赋予 API (equip-to-unit 运行时)
  ├── P2: 战斗触发逻辑 (单位 vs 单位, 非仅玩家 vs 敌人)
  └── P2: 沙盒状态隔离 (不写入主线存档)
```

## 隐式需求

| 系统 | 是否牵动 | 说明 |
|------|---------|------|
| 存档系统 | **是** | 沙盒数据禁止写入 `save-repository.ts`，需隔离沙盒状态 |
| Phaser 场景管理 | **是** | 需新建 `SandboxScene`，不污染现有 `WorldScene` |
| 战斗系统 | **是** | 需支持 unit-vs-unit 而非仅 player-vs-enemy |
| 地图编辑系统 | **部分** | 从已发布的地图中选择，不修改原地图 |
| 设置系统 | 否 | 无需修改 |

## 架构引用

| 来源 | 方案 |
|------|------|
| `DeveloperModeShell.tsx` | 模块路由模式（`ModuleId` 联合类型 + `setActiveModule`） |
| `DeveloperModeHome.tsx` | 按钮网格布局 |
| `resolve-full-attack.ts` | 12 步攻击结算管线，直接复用 |
| `battle-runtime-service.ts` | BattleEnemy 接口 + `createBattleRuntimeService`，扩展为通用 unit |
| `equipment-types.ts` | Weapon/Armor/Shield 定义 + 品质体系，直接复用 |
| `player-defaults.ts` | `computeDerivedStats` + `INITIAL_ATTRIBUTES`，用于主角模板 |
| Phaser `create-game.ts` | `CreateGame` 入口，需注册新 Scene |

## 子 Agent 调用

| 步骤 | Skill | 职责 |
|------|-------|------|
| 主 Agent | `web-fullstack` | 领域模型 + SandboxScene + 战斗集成 + 模块路由 |
| 子 Agent | `ui-ux-pro-max` | UnitCategoryPanel / PlayerStatEditor / EquipmentAssignPanel / BattleLogPanel UI 设计 |
