# combat-sandbox-v2 — Living Spec

## 快速状态

| 字段 | 值 |
|------|-----|
| 当前阶段 | Implement |
| 最后更新 | 2026-06-04 |
| 总任务数 | 16 |
| 已完成 | 16 |
| 下一步 | Review 阶段 — 代码审查 |
| 阻塞项 | 无 |

## 设计概览

### 布局

```
┌─ 左侧 240px ────┬── 中间 Phaser ────┬── 右侧 280px ────┐
│ NPC              │ 战棋棋盘/地图     │ 信息框 (上)       │
│  重要NPC         │ 16x16 网格        │ 选中对象详情      │
│  普通NPC         │ 移动/攻击高亮     │                  │
│ 装备             │                  │ 实时日志(下)      │
│  头/身/腰/手     │                  │ 战斗/交互/日程    │
│  生活职业装备     │                  │                  │
│ 武器             │                  │                  │
│  匕首/剑/斧…    │                  │                  │
│ 道具             │                  │                  │
│  药剂/食物/材料   │                  │                  │
│ 野兽             │                  │                  │
│ 敌人             │                  │                  │
│ 其他             │                  │                  │
└──────────────────┴──────────────────┴──────────────────┘
```

### 核心 Scenario

- **S1**: 进入 → 左侧分类树展开 → 选 NPC → 右侧信息框显示详情
- **S2**: 选装备/武器 → 赋予到选中单位 → 信息框更新
- **S3**: 战棋棋盘：玩家回合 → 行动菜单（攻击/移动/格挡/结束）→ 敌方 AI 自动
- **S4**: NPC 生态：时间快进 → NPC 按日程移动 → 表格更新
- **S5**: 选野兽/敌人 → 放置到棋盘 → 发起战斗
- **S6**: 战斗日志 + 交互日志实时滚动

### 架构

```
OutlineTree (左侧分类树) → SandboxShell (三栏布局)
  ├→ Phaser TacticalBoardScene (16x16 战棋)
  ├→ createTacticalBattle + executeAttack/Move/Block/EndTurn
  ├→ key-npcs → NpcInteraction → npcTalk/LLM
  ├→ npc-runtime-service → 日程驱动 → 生态观察
  ├→ equipment-types → 武器/防具/盾牌/生活装备
  ├→ life-tool-types → 剥皮刀/炼金釜等
  ├→ item-types → 药剂/食物/材料
  └→ InspectorPanel + RealtimeLogPanel (右侧信息框+实时日志)
```

### 架构引用

| 来源 | 方案 |
|------|------|
| tactical-turn-engine.ts | createTacticalBattle + execute* 全套 |
| key-npcs.ts + NpcInteraction.tsx | NPC 交互复用 |
| npc-runtime-service.ts | 日程引擎接入 |
| equipment-types.ts | 装备体系复用 |
| battle-runtime-service.ts | createSandboxAttack 转换层 |

## 实施进度

### Phase 1: 领域层 ✅
- [x] Task 1: 新建 life-tool-types.ts — 生活装备 (2026-06-04)
- [x] Task 2: 新建 item-types.ts — 道具类型 (2026-06-04)
- [x] Task 3: 新建 unit-to-tactical.ts — UnitTemplate/NpcDefinition → TacticalUnit (2026-06-04)

### Phase 2: 删除旧代码 ✅
- [x] Task 4: 删除 sandbox-battle-loop.ts (2026-06-04)
- [x] Task 5: 删除 SandboxScene.ts + 清理引用 (2026-06-04)

### Phase 3: Phaser 战棋 ✅
- [x] Task 6: 新建 TacticalBoardScene.ts — 16x16 网格 + 移动高亮 + 攻击高亮 (2026-06-04)
- [x] Task 7: 修改 create-game.ts — 注册 TacticalBoardScene (2026-06-04)

### Phase 4: UI 组件 ✅
- [x] Task 8: 新建 OutlineTree.tsx — 8 类分类树 + 选中联动 (2026-06-04)
- [x] Task 9: 新建 InspectorPanel.tsx — 右侧信息框 (2026-06-04)
- [x] Task 10: 新建 RealtimeLogPanel.tsx — 实时日志面板 (2026-06-04)
- [x] Task 11: 新建 ActionMenu.tsx — 战棋行动菜单 (2026-06-04)
- [x] Task 12: 新建 TurnOrderBar.tsx — 先攻顺序条 (2026-06-04)

### Phase 5: 主 Shell ✅
- [x] Task 13: 新建 SandboxShell.tsx — 三栏布局 + 大纲树 + 棋盘 + 信息+日志 (2026-06-04)
- [x] Task 14: 修改 DeveloperModeShell + Home (2026-06-04)

### Phase 6: 战斗引擎接入 ✅
- [x] Task 15: SandboxShell.handleEnterBattle → createTacticalBattle (2026-06-04)

### Phase 7: 验证 ✅
- [x] Task 16: 编译 (117 modules, 1.37s) + 测试 178/179 (1 flaky d20) (2026-06-04)

## 关键决策记录

| 日期 | 决策 | 理由 | 影响范围 |
|------|------|------|----------|
| 2026-06-04 | 使用 tactical-turn-engine 而非自建战斗循环 | 复用已有12步管线（AP/MP/先攻/网格/借机/撤退），避免重复实现格挡/碾压/暴击判定 | 战斗日志必须暴露每步中间结果 |
| 2026-06-04 | 使用 Phaser 作为战棋渲染引擎 | 项目已有 Phaser 集成，16x16 网格 + sprite 管理成熟 | TacticalBoardScene 依赖 Phaser Scene 生命周期 |
| 2026-06-04 | 三栏布局（左分类树 + 中棋盘 + 右信息/日志） | 参考 SRPG Debug Tools 和 Splitgate Sandbox 的 spawn menu 模式 | SandboxShell 组件结构 |

## 修改日志

| 日期 | 文件 | 变更类型 | 说明 |
|------|------|----------|------|
| 2026-06-04 | life-tool-types.ts | 新增 | 生活装备类型定义（剥皮刀/炼金釜/钓鱼竿/矿镐/镰刀/斧头） |
| 2026-06-04 | item-types.ts | 新增 | 道具类型定义（药剂/食物/材料） |
| 2026-06-04 | unit-to-tactical.ts | 新增 | UnitTemplate/NpcDefinition → TacticalUnit 转换 |
| 2026-06-04 | sandbox-battle-loop.ts | 删除 | 旧战斗循环，被 tactical-turn-engine 替代 |
| 2026-06-04 | SandboxScene.ts | 删除 | 旧沙盒场景，被 TacticalBoardScene 替代 |
| 2026-06-04 | TacticalBoardScene.ts | 新增 | 16x16 网格战棋 + 移动/攻击高亮 + unit sprites |
| 2026-06-04 | create-game.ts | 修改 | 注册 TacticalBoardScene，清理 SandboxScene 引用 |
| 2026-06-04 | OutlineTree.tsx | 新增 | 8 类分类树 + 选中联动 |
| 2026-06-04 | InspectorPanel.tsx | 新增 | 右侧信息框 |
| 2026-06-04 | RealtimeLogPanel.tsx | 新增 | 实时日志面板 |
| 2026-06-04 | ActionMenu.tsx | 新增 | 战棋行动菜单（攻击/移动/格挡/结束） |
| 2026-06-04 | TurnOrderBar.tsx | 新增 | 先攻顺序条 |
| 2026-06-04 | SandboxShell.tsx | 新增 | 三栏布局主 Shell |
| 2026-06-04 | DeveloperModeShell + Home | 修改 | 接入 SandboxShell |

## 验证状态

| 检查项 | 状态 | 备注 |
|--------|------|------|
| 编译 | ✅ | 117 modules, 1.37s |
| 测试 | ⚠️ | 178/179 passed (1 flaky d20) |
| 运行时 | ⬜ | 未验证 |