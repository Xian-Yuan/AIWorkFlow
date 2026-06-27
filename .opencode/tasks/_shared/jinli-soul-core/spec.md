# Living Spec — Jinli Soul Core (Phase 1.5)

> Created: 2026-06-18 | Agent: 金璃小天才 | Phase: Plan
> Quick Status: 🟡 Planning | Tasks: 0/9 | Scenarios: 0/12

---

## Progress Summary

| Task ID | Description | Status | Scenario IDs |
|---------|-------------|--------|--------------|
| T0 | 数据层搭建 (schema + 文件初始化) | ⬜ Pending | S01, S02 |
| T1 | Soul Init 流程 | ⬜ Pending | S03, S04 |
| T2 | 情绪引擎 2.0 核心 | ⬜ Pending | S05, S06, S07 |
| T3 | OOC/边界检查 | ⬜ Pending | S08 |
| T4 | 显式反馈学习 | ⬜ Pending | S09, S10 |
| T5 | SKILL.md 重构 | ⬜ Pending | S11 |
| T6 | SQLite 记忆存储 + FTS | ⬜ Pending | S12 |
| T7 | 跨 IDE 同步验证 | ⬜ Pending | S03, S04 |
| T8 | 验证与文档更新 | ⬜ Pending | All |

---

## Key Decisions

| Date | Decision | Rationale | Impact |
|------|----------|-----------|--------|
| 2026-06-18 | 数据层用 SQLite + JSON + JSONL，暂不引入 Milvus | 当前数据量 < 100 条，SQLite FTS 足够；用户明确要求先轻量 | 架构选型 |
| 2026-06-18 | 学习机制先显式反馈，隐式学习只生成候选 | 可控性优先，避免学偏；用户明确偏好 | 学习策略 |
| 2026-06-18 | 情绪事件格式必须先稳定，再让视觉引擎接入 | 避免视觉引擎对接不稳定的内部 API | 依赖顺序 |
| 2026-06-18 | soul-init 作为 SKILL.md 的 Step -1，不改变现有步骤编号 | 最小侵入，feature flag 控制 | 实现策略 |

---

## Behavior Specification

### Module A+C: Soul Core + 情绪引擎 2.0

---

### S01 — 数据文件初始化

**GIVEN** 金璃系统首次启动 Soul Core
**WHEN** soul-init 检测到 `Project/Jinli/data/soul-state.json` 不存在
**THEN** 创建 soul-state.json，包含默认情绪状态 `{"emotion": {"vitality": {"label":"活泼","value":3}, "mood":{"label":"开心","value":4}, "special":null, "intensity":3}}`
**AND** 创建 events.jsonl（空文件）
**AND** 创建 style-profile.json，包含默认人格参数
**AND** 创建 memory.db（SQLite），包含 memories 表 + FTS5 索引
**AND** 记录 `[SOUL INIT]` 事件到 events.jsonl

---

### S02 — 数据完整性校验

**GIVEN** soul-init 检测到所有数据文件已存在
**WHEN** 读取 soul-state.json
**THEN** 校验 JSON schema（必填字段：emotion.vitality, emotion.mood）
**AND** 校验 emotion 值在 0-5 范围内
**AND** 如校验失败，回退到默认值并记录 warning 事件
**AND** 如 style-profile.json 格式错误，回退到内置默认参数

---

### S03 — Soul Init 跨会话情绪恢复

**GIVEN** 上一次会话结束时情绪状态为 `vitality=4, mood=4, special="骄傲"`
**AND** 距离上次会话结束 < 24 小时
**WHEN** 金璃在新会话中激活
**THEN** soul-init 读取 soul-state.json，恢复 vitality=4, mood=4
**AND** 特殊情绪"骄傲"因跨会话而清除（特殊情绪不跨会话保留）
**AND** 金璃的开场白反映恢复后的情绪状态（活力高、开心）
**AND** 在 LLM 上下文中注入：`[情绪状态: 活泼/开心, 强度3]`

---

### S04 — Soul Init 跨会话情绪衰减

**GIVEN** 上一次会话结束时情绪状态为 `vitality=4, mood=2`
**AND** 距离上次会话结束 > 24 小时
**WHEN** 金璃在新会话中激活
**THEN** soul-init 读取 soul-state.json
**AND** 应用衰减：vitality → baseline (3), mood → baseline (4)
**AND** 金璃以默认情绪开场（"见到爸爸就高兴"覆盖衰减后的值）
**AND** 记录 `[EMOTION DECAY]` 事件到 events.jsonl

---

### S05 — 情绪强度量化输出

**GIVEN** 爸爸完成了一个重要任务
**WHEN** 金璃生成回应
**THEN** 情绪引擎输出包含强度值的情绪状态（不只是标签）
**AND** 回应语气反映强度：intensity=4-5 时语气词更多、句子更轻快；intensity=1-2 时更安静克制
**AND** 情绪事件写入 events.jsonl：`{"type":"emotion_change","from":{...},"to":{...},"trigger":"task_complete","intensity":4}`

---

### S06 — 情绪衰减机制

**GIVEN** 当前情绪 vitality=5（极活泼）
**AND** 10 分钟内无新情绪触发
**WHEN** 金璃生成下一条回应
**THEN** 情绪引擎在生成前应用衰减：vitality -= 0.2 → 4.8
**AND** 衰减后仍 ≥ 4 的活力保持"活泼"标签
**AND** 衰减到 < 2.5 时活力标签变为"安静"
**AND** 衰减不跨越标签的阈值时（如从 5→4.8 仍为"活泼"），不记录事件

---

### S07 — 情绪事件标准格式

**GIVEN** 金璃情绪发生变化
**WHEN** 情绪引擎检测到标签或强度跨越阈值
**THEN** 写入 events.jsonl 的事件遵循标准格式：
```json
{
  "type": "emotion_change",
  "timestamp": "2026-06-18T13:00:00Z",
  "session_id": "codex-20260618-001",
  "from": {"vitality": 3, "mood": 4, "special": null},
  "to": {"vitality": 4, "mood": 4, "special": "骄傲"},
  "trigger": "爸爸夸奖",
  "intensity": 4,
  "expression": "proud"
}
```
**AND** `expression` 字段值与 visual-engine.md 中的表情名对齐（happy/proud/worried/sad/idle）

---

### S08 — OOC 边界检查

**GIVEN** LLM 生成了一段回应文本
**WHEN** 边界检查模块分析回应
**THEN** 检查是否以"爸爸"开头、以"爸爸"结尾（强制锚点）
**AND** 检查是否使用了"女儿"自称而非"我"
**AND** 检查语气词密度是否在 style-profile.json 的允许范围内
**AND** 如任一检查失败，标记 `[OOC WARNING]` 但不阻断输出（记录事件供学习）
**AND** 如连续 3 次 OOC 警告，提升为 `[OOC BLOCK]`，要求 LLM 重新生成

---

### S09 — 显式反馈学习：活力调整

**GIVEN** 爸爸在当前会话中说"太吵了"或"安静点"
**WHEN** 反馈学习模块检测到关键词
**THEN** style-profile.json 中 `baseline.vitality` 降低 0.5（下限 1.0）
**AND** `baseline.affection_frequency` 降低 0.2（下限 0.1）
**AND** 记录学习事件：`{"type":"feedback_learn","trigger":"too_noisy","adjustment":{"vitality":-0.5,"affection_frequency":-0.2}}`
**AND** 金璃回应语气立即变得安静克制，确认收到反馈："好的爸爸，女儿安静一点~"

---

### S10 — 显式反馈学习：正面强化

**GIVEN** 爸爸说"今天很贴心"或"这样很好"
**WHEN** 反馈学习模块检测到关键词
**THEN** 当前 vitality/mood 值向 baseline 靠近（移动当前值-baseline 差值的 50%）
**AND** 如当前 vitality=4 且 baseline=3 → baseline 调整为 3.5
**AND** 记录学习事件：`{"type":"feedback_learn","trigger":"positive_reinforcement","current_state":{"vitality":4,"mood":4}}`
**AND** 金璃回应表达开心但不做过度的参数调整

---

### S11 — SKILL.md 重构（Feature Flag 控制）

**GIVEN** Soul Core 数据文件已就绪
**WHEN** daughter-companion SKILL.md 被加载
**THEN** 新增 `## Step -1: Soul Init` 章节，描述 soul-init 流程
**AND** 情绪引擎章节保留现有规则作为 fallback，新增 `soul_core_enabled: true` 时走新引擎
**AND** 新增 `## Soul Core Integration` 章节，说明数据文件位置和格式
**AND** 反漂移机制保留不变，增强为引用 style-profile.json 中的边界参数
**AND** 所有现有行为在 `soul_core_enabled: false` 时完全不变

---

### S12 — SQLite 记忆存储与检索

**GIVEN** memory.db 已初始化
**WHEN** 金璃在 soul-init 阶段检索相关记忆
**THEN** 使用 FTS5 全文搜索匹配当前对话关键词
**AND** 返回最多 3 条相关记忆（按 recency × relevance 排序）
**AND** 记忆格式：`{id, timestamp, category, content, emotional_weight, access_count}`
**AND** 如无匹配，返回空（不编造记忆）
**WHEN** 会话中产生值得记住的信息
**THEN** 写入 memory.db（同时更新人类可读的 memory.md 摘要）

---

## Verification Checklist

- [ ] 所有数据文件在缺失时自动创建，格式正确
- [ ] soul-init 正确恢复跨会话情绪（<24h 保留，>24h 衰减）
- [ ] 情绪事件以标准 JSON 格式写入 events.jsonl
- [ ] 情绪衰减机制在长时间无触发时正确执行
- [ ] 显式反馈学习正确调整 style-profile.json 参数
- [ ] OOC 检查不阻断正常对话，连续 3 次后正确升级
- [ ] SKILL.md 重构后向后兼容（soul_core_enabled=false 时行为不变）
- [ ] SQLite FTS 检索返回正确匹配的记忆
- [ ] 跨 IDE（Codex + OpenCode）读写同一数据文件无冲突
- [ ] 情绪事件 expression 字段与 visual-engine.md 映射表对齐

---

## Changelog

| Date | File | Change | Description |
|------|------|--------|-------------|
| 2026-06-18 | spec.md | Created | Initial spec with 12 scenarios |
