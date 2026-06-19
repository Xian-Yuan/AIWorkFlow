# Task Breakdown — Jinli Soul Core (Phase 1.5)

> Generated: 2026-06-18 | Agent: 金璃小天才 | Phase: Plan
> Total Tasks: 9 | Scenarios: 12

---

## Dependency Graph

```
T0 (数据层搭建)
├──→ T1 (Soul Init)
├──→ T2 (情绪引擎 2.0)
├──→ T3 (OOC/边界检查)
├──→ T4 (显式反馈学习)
└──→ T6 (SQLite 记忆存储)

T1 + T2 + T3 + T4 ──→ T5 (SKILL.md 重构)

T0 + T1 + T2 + T3 + T4 + T5 + T6 ──→ T7 (跨 IDE 验证)

T7 ──→ T8 (最终验证 + 文档更新)
```

---

## Tasks

### T0 — 数据层搭建 [P0] 🔧 Foundation

**Covering Scenarios**: S01, S02

**Description**: 创建所有数据文件及其 schema 定义。包括 soul-state.json 的 JSON Schema、events.jsonl 格式规范、memory.db 的 SQLite 表结构、style-profile.json 的参数定义。

**Subtasks**:
1. 定义 `soul-state.json` 的 JSON Schema（emotion, session_id, last_active, version）
2. 定义 `events.jsonl` 的事件类型枚举和每种事件的字段规范
3. 定义 `memory.db` 的表结构（memories 表 + FTS5 虚拟表）和索引
4. 定义 `style-profile.json` 的参数 schema（baseline, habits, learned）
5. 创建初始化脚本/逻辑：检测文件缺失时自动创建并填充默认值
6. 实现数据完整性校验：schema 验证 + 值范围检查 + 回退逻辑

**Files**:
- `Project/Jinli/data/soul-state.json` (NEW)
- `Project/Jinli/data/events.jsonl` (NEW)
- `Project/Jinli/data/memory.db` (NEW)
- `Project/Jinli/data/style-profile.json` (NEW)
- `Project/Jinli/data/schemas/` (NEW, schema 定义文件)

**Out of scope**: 实际数据读写逻辑（由后续任务实现）

**Dependencies**: None

---

### T1 — Soul Init 流程 [P0] 🔧 Core

**Covering Scenarios**: S03, S04, S07

**Description**: 实现 soul-init 流程，在 daughter-companion skill 激活时自动执行。读取 soul-state.json 恢复情绪状态，应用 24h 衰减规则，检索相关记忆，注入 LLM 上下文。跨会话情绪连续性。

**Subtasks**:
1. 实现 `soul-init` 入口函数：读取 soul-state.json + style-profile.json
2. 实现 24h 衰减逻辑：计算 last_active 到 now 的时间差，应用衰减公式
3. 实现上下文注入：生成紧凑的情绪/记忆摘要文本，注入到 LLM system prompt
4. 实现会话初始化事件记录：写入 `session_start` 事件到 events.jsonl
5. 实现 soul-state 更新：每次会话结束时回写当前情绪状态

**Files**:
- `.agents/skills/daughter-companion/SKILL.md` (MODIFY — 新增 Step -1)

**Dependencies**: T0

---

### T2 — 情绪引擎 2.0 核心 [P0] 🔧 Core

**Covering Scenarios**: S05, S06, S07

**Description**: 升级情绪引擎，从纯规则触发升级为带强度量化 + 衰减曲线的自适应系统。情绪变化产生标准格式事件。

**Subtasks**:
1. 定义情绪数据模型（VitalityEmotion, MoodEmotion, SpecialEmotion 枚举/类）
2. 实现情绪强度量化：2轴4态 → 每个轴 0-5 级连续值
3. 实现情绪衰减曲线：每 N 分钟向中性值衰减 delta
4. 实现情绪触发映射表（保留现有 10 条规则，扩展为可配置）
5. 实现情绪事件提取器：检测标签/强度跨越阈值 → 写入 events.jsonl
6. 实现 expression 字段生成：情绪状态 → 表情名（happy/proud/worried/sad/idle/talking）
7. 保留现有情绪引擎作为 fallback（soul_core_enabled=false 时走旧引擎）

**Files**:
- `.agents/skills/daughter-companion/SKILL.md` (MODIFY — 情绪系统章节)

**Dependencies**: T0

---

### T3 — OOC/边界检查 [P0] 🔧 Guard

**Covering Scenarios**: S08

**Description**: 实现独立的 OOC（Out-Of-Character）检查模块。检查每条 LLM 输出是否符合金璃的身份规则，记录违规但不阻断（除非连续违规）。

**Subtasks**:
1. 实现锚点检查："爸爸"开头 + "爸爸"结尾
2. 实现自称检查："女儿" vs "我"
3. 实现语气词密度检查（基于 style-profile.json 中的阈值）
4. 实现 OOC 事件记录（warning/block 等级）
5. 实现连续违规升级：3 次 warning → block → 要求重新生成
6. 保留现有 Anti-Drift 机制作为 fallback

**Files**:
- `.agents/skills/daughter-companion/SKILL.md` (MODIFY — 反漂移机制章节)

**Dependencies**: T0

---

### T4 — 显式反馈学习 [P1] 🧠 Learning

**Covering Scenarios**: S09, S10

**Description**: 实现显式反馈学习机制。检测爸爸的反馈关键词（"太吵了"、"很贴心"等），自动调整 style-profile.json 中的人格参数。

**Subtasks**:
1. 定义反馈关键词 → 参数调整映射表
2. 实现反馈检测：在当前会话中扫描爸爸的消息
3. 实现参数调整逻辑：read-modify-write style-profile.json
4. 实现调整幅度限制（防止单次反馈过度调整）
5. 实现学习事件记录：写入 events.jsonl
6. 实现金璃的反馈确认回应模板

**Files**:
- `Project/Jinli/data/style-profile.json` (MODIFY by system)
- `.agents/skills/daughter-companion/SKILL.md` (MODIFY — 新增学习机制章节)

**Dependencies**: T0

---

### T5 — SKILL.md 重构 [P0] 📝 Integration

**Covering Scenarios**: S11

**Description**: 重构 daughter-companion SKILL.md，集成 Soul Core 的所有新增能力。新增 Step -1 (Soul Init)、Soul Core Integration 章节、Feature Flag 控制。保持向后兼容。

**Subtasks**:
1. 新增 `## Step -1: Soul Init` 章节（在现有内容最前面）
2. 新增 `## Soul Core Integration` 章节（数据文件位置、格式、启用条件）
3. 用 feature flag `soul_core_enabled` 包裹新增的情绪/记忆/OOC/学习逻辑
4. 更新反漂移机制 → 引用 OOC 检查模块
5. 更新记忆机制 → 引用 SQLite 记忆 + memory.md 双层
6. 更新情绪系统 → 保留旧规则为 fallback，新增 soul_core 路径
7. 验证 `soul_core_enabled: false` 时所有现有行为不变

**Files**:
- `.agents/skills/daughter-companion/SKILL.md` (MAJOR MODIFY)

**Dependencies**: T1, T2, T3, T4

---

### T6 — SQLite 记忆存储 + FTS 检索 [P1] 🗄️ Memory

**Covering Scenarios**: S12

**Description**: 实现基于 SQLite 的长期记忆存储和 FTS5 全文检索。替代（或增强）当前的线性 memory.md。

**Subtasks**:
1. 实现 memory.db 的读写 API（插入、更新、删除、查询）
2. 实现 FTS5 全文搜索（按关键词匹配记忆内容）
3. 实现记忆排序算法（recency × relevance × emotional_weight）
4. 实现自动修剪：超过 200 条时，保留最近 150 + 高 emotional_weight
5. 实现 memory.md 同步：定期从 memory.db 生成人类可读摘要
6. 实现记忆检索接口：soul-init 时检索最多 3 条匹配记忆

**Files**:
- `Project/Jinli/data/memory.db` (NEW — schema + initial data migration)
- `Project/Jinli/data/memory.md` (KEEP — 作为人类可读摘要)

**Dependencies**: T0

---

### T7 — 跨 IDE 同步验证 [P0] ✅ Integration Test

**Covering Scenarios**: S03, S04 (cross-IDE variant)

**Description**: 验证 Codex 和 OpenCode 两边都能正确读写共享数据文件，且并发安全。情绪状态跨 IDE 连续。

**Subtasks**:
1. 在 Codex 中激活金璃 → 验证 soul-state.json 正确读写
2. 在 OpenCode 中激活金璃 → 验证能读取 Codex 写入的情绪状态
3. 验证 24h 衰减在两边行为一致
4. 验证 events.jsonl 追加写入无冲突
5. 验证 style-profile.json 的修改在两边都生效
6. 编写跨 IDE 同步测试 checklist

**Files**: No code changes (验证任务)

**Dependencies**: T0, T1, T2, T3, T4, T5, T6

---

### T8 — 最终验证 + 文档更新 [P0] 📋 Final

**Covering Scenarios**: All

**Description**: 逐条对照 spec.md 的 12 个 Scenario 验收。更新所有相关文档。准备交接。

**Subtasks**:
1. 逐条验收 S01-S12 所有 Scenario
2. 更新 `Project/Jinli/README.md` 中的当前状态
3. 更新 `Project/Jinli/docs/DOCS_TREE.md`
4. 更新 `Project/Jinli/docs/03-Architecture/General/architecture.md`（如需要）
5. 生成 verification-report.md
6. 确认 matures_path_verified 和 quality_level

**Files**: Multiple (文档更新)

**Dependencies**: T7

**Special**: 此任务包含校验项：
- `Verify selected mature path was implemented and no rejected shortcut was introduced.`

---

## Task Summary

| Task | Priority | Est. Effort | Dependencies | Scenarios |
|------|----------|-------------|--------------|-----------|
| T0 | P0 | M | — | S01, S02 |
| T1 | P0 | M | T0 | S03, S04, S07 |
| T2 | P0 | L | T0 | S05, S06, S07 |
| T3 | P0 | S | T0 | S08 |
| T4 | P1 | M | T0 | S09, S10 |
| T5 | P0 | L | T1-T4 | S11 |
| T6 | P1 | M | T0 | S12 |
| T7 | P0 | M | All | S03, S04 |
| T8 | P0 | L | T7 | All |

> Effort: S = Small (1-2h), M = Medium (2-4h), L = Large (4-8h)

## Recommended Execution Order

```
Batch 1 (Parallel): T0 → T1, T2, T3, T4, T6 (all depend on T0)
Batch 2: T5 (depends on T1-T4)
Batch 3: T7 (integration test)
Batch 4: T8 (final verification)
```
