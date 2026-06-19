# Tasks — combat-sandbox-v2

## Phase 1: 领域层 ✅

- [x] Task 1: 新建 life-tool-types.ts — 生活装备（剥皮刀/炼金釜/钓鱼竿/矿镐/镰刀/斧头）
- [x] Task 2: 新建 item-types.ts — 道具类型（药剂/食物/材料）
- [x] Task 3: 新建 unit-to-tactical.ts — UnitTemplate/NpcDefinition → TacticalUnit

## Phase 2: 删除旧代码 ✅

- [x] Task 4: 删除 sandbox-battle-loop.ts
- [x] Task 5: 删除 SandboxScene.ts + 清理引用 (create-game.ts + SandboxScreen.tsx)

## Phase 3: Phaser 战棋 ✅

- [x] Task 6: 新建 TacticalBoardScene.ts — 16×16 网格 + 移动高亮 + 攻击高亮 + unit sprites
- [x] Task 7: 修改 create-game.ts — 注册 TacticalBoardScene

## Phase 4: UI 组件 ✅

- [x] Task 8: 新建 OutlineTree.tsx — 8 类分类树 + 选中联动
- [x] Task 9: 新建 InspectorPanel.tsx — 右侧信息框
- [x] Task 10: 新建 RealtimeLogPanel.tsx — 实时日志面板
- [x] Task 11: 新建 ActionMenu.tsx — 战棋行动菜单
- [x] Task 12: 新建 TurnOrderBar.tsx — 先攻顺序条

## Phase 5: 主 Shell ✅

- [x] Task 13: 新建 SandboxShell.tsx — 三栏布局 + 大纲树 + 棋盘 + 信息+日志
- [x] Task 14: 修改 DeveloperModeShell + Home

## Phase 6: 战斗引擎接入 ✅

- [x] Task 15: SandboxShell.handleEnterBattle → createTacticalBattle

## Phase 7: 验证 ✅

- [x] Task 16: 编译 (117 modules, 1.37s) + 测试 178/179 (1 flaky d20)
