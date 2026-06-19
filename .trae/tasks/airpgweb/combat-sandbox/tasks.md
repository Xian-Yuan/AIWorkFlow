# Tasks — combat-sandbox（沙盒战斗测试模式）

## 依赖图

```
Task 1 (类型定义) ──┬── Task 2 (单位模板) ── Task 7 (生成面板)
                   │
                   ├── Task 3 (装备API) ── Task 10 (装备面板)
                   │
                   ├── Task 4 (Phaser场景) ── Task 8 (地图选择器)
                   │
                   └── Task 5 (回合战斗引擎) ── Task 12 (SandboxScreen集成)
                                               │
                   Task 6 (路由注册) ──────────┤
                                               │
                   Task 9 (主角编辑器) ────────┤
                                               │
                   Task 11 (战斗触发展示) ─────┤
                                               │
                   Task 13 (编译+测试验证) ────┘
```

## 任务清单

### Phase 1: 领域模型（主 Agent: web-fullstack）

- [x] **Task 1**: 新建 `src/domain/sandbox/sandbox-types.ts`
  - 定义 `UnitCategory`（'npc' | 'enemy' | 'beast' | 'boss' | 'elite' | 'friendly'）
  - 定义 `SandboxUnit`、`PlacedUnit`、`TurnResult`、`BattleLoopState`、`SandboxMapRef`、`UnitTemplate`
  - 依赖: 无

- [x] **Task 2**: 新建 `src/data/sandbox/sandbox-unit-templates.ts`
  - 6 分类 × 共 16 个预设模板（NPC×3 / 敌人×3 / 野兽×3 / Boss×2 / 精英×2 / 友方×2）
  - 依赖: Task 1

- [x] **Task 3**: 新建 `src/domain/sandbox/equip-to-unit.ts`
  - `equipWeapon / equipArmor / equipShield / unequipXxx / recomputeDerived`
  - 依赖: Task 1

- [x] **Task 4**: 新建 `src/domain/sandbox/sandbox-battle-loop.ts`
  - `createSandboxBattle` + `executeTurn` + `executeFullBattle`（异步迭代器，800ms 间隔）
  - 依赖: Task 1, resolve-full-attack 复用

- [x] **Task 5**: 修改 `src/runtime/battle/battle-runtime-service.ts`
  - 新增 `createSandboxAttack(attacker, defender)`，保留原有 API 兼容
  - 修复已有 unused variable 编译警告

- [x] **Task 6**: 新建 `src/presentation/phaser/scenes/SandboxScene.ts`
  - 独立 Phaser Scene（key: 'sandbox'），渲染地图瓦片 + 单位 sprites + 交互回调

- [x] **Task 7**: 修改 `src/presentation/phaser/create-game.ts`
  - `scene` 数组注册 `SandboxScene`

- [x] **Task 8**: 新建 `src/presentation/react-shell/dev-mode/UnitCategoryPanel.tsx`
  - 6 类可折叠分类树，每类显示模板名称+描述

- [x] **Task 9**: 新建 `src/presentation/react-shell/dev-mode/UnitSpawnPanel.tsx`
  - 模板属性预览 + 放置按钮 + 已放置单位列表（选中/删除）

- [x] **Task 10**: 新建 `src/presentation/react-shell/dev-mode/PlayerStatEditor.tsx`
  - 7 属性滑条+数字输入 + 衍生属性实时只读 + 重置按钮

- [x] **Task 11**: 新建 `src/presentation/react-shell/dev-mode/EquipmentAssignPanel.tsx`
  - 武器/防具/盾牌三 Tab 选择器（含预设装备工厂函数）

- [x] **Task 12**: 新建 `src/presentation/react-shell/dev-mode/BattleLogPanel.tsx`
  - 战斗日志列表（命中/闪避/招架/格挡/暴击/伤害/HP）+ 胜负提示

- [x] **Task 13**: 新建 `src/presentation/react-shell/dev-mode/SandboxScreen.tsx`
  - 三栏布局主界面，组合所有子组件，管理沙盒全局状态

- [x] **Task 14**: 新建 `src/presentation/react-shell/dev-mode/SandboxMapSelector.tsx`
  - 弹窗式地图选择器，调用 `map-asset-repository` 列出已保存地图

- [x] **Task 15**: 修改开发者模式路由与入口
  - `DeveloperModeShell.tsx` 新增 `'combat-sandbox'` 模块 + `SandboxScreen` 渲染
  - `DeveloperModeHome.tsx` 新增 `onEnterSandbox` prop + "沙盒战斗测试"按钮
  - `DeveloperModeHome.test.tsx` 更新 prop

- [x] **Task 16**: 编译验证 + 功能回归
  - Vite build: `✓ built in 1.31s`（113 modules）
  - Vitest: `122 passed / 2 failed`（2 个均为已有测试失败，非本次引入）
