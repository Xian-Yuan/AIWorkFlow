# Analysis — combat-sandbox（沙盒战斗测试模式）

## 一、需求摘要

在现有开发者模式中新增"沙盒战斗测试模式"，允许：
1. 按类别（NPC / 敌人 / 野兽 / Boss / 精英 / 友方）选择单位生成
2. 从地图编辑器已保存的地图中选择独立测试地图
3. 编辑主角属性数值模板和装备
4. 触发回合制战斗（沿用在 `resolve-full-attack.ts` 12 步管线）
5. 沙盒数据完全隔离，不写入主线存档

## 二、依赖链推导 (P0 前提条件)

```text
沙盒战斗测试模式
  ├── P0 ✅ 战斗系统存在 → resolve-full-attack.ts (12 步管线) + battle-runtime-service.ts
  ├── P0 ✅ 装备体系存在 → equipment-types.ts (武器/防具/盾牌/品质/技能)
  ├── P0 ✅ 主角属性体系存在 → player-types.ts + player-defaults.ts
  ├── P0 ✅ 开发者模式入口存在 → DeveloperModeShell.tsx + DeveloperModeHome.tsx
  ├── P0 ❌ 单位模板数据缺失 → 需新建 sandbox-unit-templates.ts
  ├── P0 ❌ 沙盒类型定义缺失 → 需新建 sandbox-types.ts
  ├── P0 ❌ 装备运行时赋予 API 缺失 → 需新建 equip-to-unit 运行时函数
  ├── P1 ❌ 战斗系统仅支持 player-vs-enemy → 需改造为 unit-vs-unit
  └── P1 ❌ Phaser 沙盒场景不存在 → 需新建 SandboxScene.ts
```

## 三、隐式需求提醒

| 受牵动系统 | 当前状态 | 本次处理 | 说明 |
|-----------|---------|---------|------|
| 存档系统 | `save-repository.ts` 管理全部存档 | **隔离** | 沙盒状态必须完全独立，不能污染 `save-repository` |
| Phaser 场景 | 仅 `BootScene` + `WorldScene` | **新建 Scene** | `SandboxScene` 独立场景，不修改 `WorldScene` |
| 战斗系统 | `battle-runtime-service.ts` 支持 player-vs-enemy | **扩展** | 新增 `unit-vs-unit` 模式 |
| 地图系统 | `IRONHOLLOW_MAP` + `runtime-map-loader` | **复用** | 从已发布地图选择，只读不写 |
| 开发者模式 | 3 个模块（地图绘制/绘制素材/素材库） | **新增第 4 模块** | 沙盒战斗测试 |

## 四、成熟方案引用

### 4.1 模块路由模式（复用现有）

```text
DeveloperModeShell.tsx:
  type ModuleId = 'home' | 'map-editor' | 'drawing-assets' | 'asset-browser'
  → 新增: | 'combat-sandbox'

DeveloperModeHome.tsx:
  三按钮网格 → 新增第四按钮 "沙盒战斗测试"
```

### 4.2 战斗管线（直接复用）

`resolve-full-attack.ts` 的 `AttackContext` 输入为 `attacker` + `defender`，类型已足够泛化，无需修改核心管线。

当前 `battle-runtime-service.ts` 的 `BattleEnemy` 接口：
```ts
{ instanceId, name, hp, maxHp, strength, luck, agility,
  armors, shield, isBlocking, dodgeRate, parrySkillLevel,
  skill, weapon }
```

改造方向：抽象为 `SandboxUnit`，使 player 和 enemy 都是该类型的实例。

### 4.3 地图选择（复用）

`map-editor` 中 `editor-reducer.ts` 已有 `MapAsset` 类型。通过 `asset-library-repository.ts` / `map-asset-repository.ts` 读取已保存地图列表，供沙盒选择。

### 4.4 单位模板方案（参考行业实践）

采用数据驱动方式，每种单位类型一个 JSON 模板文件：

```ts
// sandbox-unit-templates.ts
type UnitTemplate = {
  id: string
  name: string
  category: UnitCategory // 'npc' | 'enemy' | 'beast' | 'boss' | 'elite' | 'friendly'
  attributes: PrimaryAttributes  // 复用 player-types
  weapon?: WeaponDefinition       // 复用 equipment-types
  armors?: ArmorDefinition[]      // 复用 equipment-types
  shield?: ShieldDefinition       // 复用 equipment-types
  combatSkill?: CombatSkill       // 复用 equipment-types
  description: string
}
```

## 五、文件改动预估

| 操作 | 文件 | 用途 |
|------|------|------|
| **新建** | `src/domain/sandbox/sandbox-types.ts` | 沙盒类型定义 |
| **新建** | `src/data/sandbox/sandbox-unit-templates.ts` | 单位预设模板（6 类） |
| **新建** | `src/domain/sandbox/equip-to-unit.ts` | 装备赋予运行时 |
| **新建** | `src/presentation/react-shell/dev-mode/SandboxScreen.tsx` | 沙盒主 UI |
| **新建** | `src/presentation/react-shell/dev-mode/UnitCategoryPanel.tsx` | 分类面板 |
| **新建** | `src/presentation/react-shell/dev-mode/UnitSpawnPanel.tsx` | 单位生成面板 |
| **新建** | `src/presentation/react-shell/dev-mode/PlayerStatEditor.tsx` | 主角数值编辑器 |
| **新建** | `src/presentation/react-shell/dev-mode/EquipmentAssignPanel.tsx` | 装备赋予面板 |
| **新建** | `src/presentation/react-shell/dev-mode/BattleLogPanel.tsx` | 战斗日志面板 |
| **新建** | `src/presentation/react-shell/dev-mode/SandboxMapSelector.tsx` | 地图选择器 |
| **新建** | `src/presentation/phaser/scenes/SandboxScene.ts` | Phaser 沙盒场景 |
| **修改** | `src/presentation/react-shell/dev-mode/DeveloperModeShell.tsx` | 新增 `combat-sandbox` 路由 |
| **修改** | `src/presentation/react-shell/dev-mode/DeveloperModeHome.tsx` | 新增按钮 |
| **修改** | `src/presentation/phaser/create-game.ts` | 注册 SandboxScene |
| **修改** | `src/runtime/battle/battle-runtime-service.ts` | 扩展为 unit-vs-unit |

共：新建 12 文件 + 修改 5 文件 = **17 处改动**

> 满足多 Agent 条件：2+ 系统（UI + Domain + Phaser）、8+ 文件、代码+数据+配置

## 六、风险点

| 风险 | 级别 | 缓解措施 |
|------|------|---------|
| Phaser Scene 独立渲染 | 中 | SandboxScene 完全独立，可在 dev-mode 中创建专用 Phaser 实例 |
| 战斗系统扩展 | 中 | `resolve-full-attack` 输入已是泛化 `AttackContext`，只需外层改造 |
| 装备运行时绑定 | 低 | 新建 `equipToUnit()` 纯函数，不改现有类型 |
| 沙盒数据泄露到主线存档 | 高 | 沙盒不调用 `save-repository`，状态仅存 React state |
| 地图选择器复用 | 低 | 读取已发布地图列表（只读），不触发编辑器 reducer |
