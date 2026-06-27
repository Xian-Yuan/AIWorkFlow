# Routing — combat-sandbox-v2

| 项 | 值 |
|----|-----|
| 主 Skill | web-fullstack |
| 次 Skill | 无（单 Agent） |
| 多 Agent | 否 |

## 主链路

```
OutlineTree (左侧分类树) → SandboxShell (三栏布局)
  ├→ Phaser TacticalBoardScene (16×16 战棋)
  ├→ createTacticalBattle + executeAttack/Move/Block/EndTurn
  ├→ key-npcs → NpcInteraction → npcTalk/LLM
  ├→ npc-runtime-service → 日程驱动 → 生态观察
  ├→ equipment-types → 武器/防具/盾牌/生活装备
  ├→ life-tool-types → 剥皮刀/炼金釜等
  ├→ item-types → 药剂/食物/材料
  └→ InspectorPanel + RealtimeLogPanel (右侧信息框+实时日志)
```

## 架构引用

| 来源 | 方案 |
|------|------|
| tactical-turn-engine.ts | createTacticalBattle + execute* 全套 |
| key-npcs.ts + NpcInteraction.tsx | NPC 交互复用 |
| npc-runtime-service.ts | 日程引擎接入 |
| equipment-types.ts | 装备体系复用 |
| battle-runtime-service.ts | createSandboxAttack 转换层 |
