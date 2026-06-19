# Analysis — combat-sandbox-v2

## 一、需求理解

全系统可扩展测试平台，三维统一：
1. 战斗测试 — 战术回合制战棋（接入已有 tactical-turn-engine）
2. NPC 交互测试 — 复用已有对话/交易/LLM
3. NPC 生态观察 — 时间驱动日程 + 好感/记忆查看
4. 装备/武器/道具/野兽/敌人 — 全部分类可生成测试

## 二、隐含需求（从已有代码反推）

| 已有代码 | 隐含需求 |
|---------|---------|
| tactical-turn-engine 含 AP/MP/先攻/网格/借机/撤退 | 战斗必须是战棋，不能是简易交替 |
| key-npcs 含日程/好感/记忆/关系/教学 | NPC 面板必须展示这些字段 |
| equipment-types 含品质/附魔/力量门槛 | 装备赋予必须展示校验结果 |
| NpcRuntimeState 含好感/记忆/金币/库存 | 生态面板必须有状态查看器 |
| npc-runtime-service 日程引擎 | 时间控制必须有快进/暂停 |

## 三、开源参考

- SRPG Debug Tools — 开发专用 debug menu 模式
- Warboard Tactics RPG — vanilla JS 战棋棋盘参考
- Splitgate Sandbox — 分类 spawn menu 参考
