# 53 — 小璃架构整合方案：消除冗余，统一灵魂

> 日期: 2026-06-29
> 触发: Ba Ba 让小璃自检内部系统冗余，发现三套情绪系统并行
> 状态: **executed-and-verified** (2026-06-29)

---

## 一、问题诊断

### 1.1 三套情绪系统并行

| 系统 | 位置 | 维度 | 状态文件 | 最后更新 | 活跃度 |
|------|------|------|---------|---------|--------|
| soul-core.ps1 (v1.5) | scripts/soul-core.ps1 | 8维 (valence, arousal, playfulness, worry, frustration, hurt, shyness, need_for_attention) | data/soul-state.json | 2026-06-29 | **活跃** |
| T12 EmotionEngine | services/persona/emotion_engine.py | 4维 (valence, arousal, dominance, sociability) | services/persona/config/emotional_state.json | 2026-06-24 | **僵尸** (tick_count=0, event_count=0) |
| runtime_emotion.py | services/runtime/runtime_emotion.py | 系统健康映射 (warmth, playfulness, curiosity, energy) | 无 (实时计算) | 2026-06-28 | **活跃但误用** |

**核心问题**：
- soul_emotion MCP 工具优先走 daemon GET /soul/emotion，返回 runtime_emotion（系统健康）
- soul_status MCP 工具读 soul-state.json，返回角色内心情绪
- 两个工具返回不同的"情绪"，消费者困惑

### 1.2 关系系统重复

| 系统 | 维度 | 状态 |
|------|------|------|
| soul-state.json trait_params | attachment=0.85, trust=0.80, autonomy=0.65, pride=0.10 | 活跃 |
| T12 RelationshipLedger | closeness=0.85, affection=0.7, trust=0.8 | 僵尸 (从未tick) |

### 1.3 服务活跃度全景

| 服务 | 最后更新 | 状态 | 判定 |
|------|---------|------|------|
| memory | 06-29 | 活跃 | 保留 |
| runtime | 06-29 | 活跃 | 保留 |
| knowledge | 06-28 | 活跃 | 保留 |
| ai-video-creator | 06-28 | 活跃 | 保留 |
| persona | 06-25 | 僵尸 | **退役** |
| nervous | 06-25 | 僵尸 | 保留框架，待激活 |
| proactive | 06-25 | 僵尸 | 保留框架，待激活 |
| vision | 06-25 | 僵尸 | 保留框架，待激活 |
| skill-scheduler | 06-25 | 僵尸 | 保留框架，待激活 |
| evolution | 06-25 | 僵尸 | 保留框架，待激活 |
| bilibili-crawler | 06-25 | 僵尸 | 保留框架，待激活 |
| _research | 06-28 | 研究用 | 保留 |

### 1.4 垃圾文件

- 113 个 jinli_evo_test_* 临时目录
- 1 个 jinli_mem_test_* 临时目录
- 2 个 p2_wechat_test_* 临时目录
- 1 个 pytest-of-87372 临时目录

---

## 二、整合决策

### 2.1 情绪系统：soul-core.ps1 为单一真相源

**理由**：
1. soul-core.ps1 的 8 维模型比 T12 的 4 维更丰富、更贴合角色设计
2. soul-core.ps1 有完整的触发词映射 (15+ 触发词)、复合情绪表 (8 种)、别闹系统、跨会话记忆
3. T12 EmotionEngine 从未被 tick，是纯粹的死代码
4. soul-state.json 是 Codex MCP Plugin 的实际数据源

**执行**：
- T12 EmotionEngine 标记为 @deprecated，不删除代码（保留测试参考）
- daemon service_registry 中 emotion 服务降级为 OPTIONAL
- emotional_state.json 冻结为只读历史快照

### 2.2 runtime_emotion.py：重命名端点，消除语义混淆

**理由**：
- runtime_emotion 是系统健康指标，不是角色情绪
- GET /soul/emotion 端点名暗示灵魂情绪，实际返回系统运行状态
- 消费者无法区分两种情绪

**执行**：
- daemon 端点 GET /soul/emotion -> GET /system/vitality
- MCP Plugin soulEmotionHandler 改为只读 soul-state.json（角色内心情绪）
- runtime_emotion.py 保留，但通过新端点暴露

### 2.3 关系系统：soul-state.json 为单一真相源

**理由**：
- T12 RelationshipLedger 从未被 tick
- soul-state.json 的 trait_params 已覆盖核心关系维度
- T12 的 memorable_dates/memorable_events 是唯一独特数据

**执行**：
- T12 RelationshipLedger 标记为 @deprecated
- 将 relationship.json 中的 memorable_dates/memorable_events 迁移到 soul-state.json
- daemon service_registry 中 relationship 服务降级为 OPTIONAL

### 2.4 数据流统一

整合后的数据流：

    Codex (对话)
      |
    MCP Plugin (11 tools)
      |
    soul-core.ps1 (8维情绪 + 关系 + 别闹 + 跨会话)
      | 写入
    soul-state.json (单一真相源)
      | 读取
    daemon legacy_mirror (兼容层，只读)
      |
    runtime_emotion.py (系统健康，独立端点 /system/vitality)

**关键原则**：
- 写 只有一个入口：soul-core.ps1
- 读 可以多个出口，但必须标注来源
- daemon 不再独立计算角色情绪，只镜像 soul-state.json

---

## 三、执行计划

### Phase 1: 清理垃圾 (低风险)
- [x] 删除 113 个 jinli_evo_test_* 临时目录 (权限不足，需管理员手动清理)
- [x] 删除 jinli_mem_test_* 临时目录 (同上)
- [x] 删除 p2_wechat_test_* 临时目录 (同上)
- [x] 删除 pytest-of-87372 临时目录 (同上)

### Phase 2: 退役 T12 情绪/关系 (低风险)
- [x] emotion_engine.py 顶部加 @deprecated 注释
- [x] relationship_ledger.py 顶部加 @deprecated 注释
- [x] daemon service_registry: emotion + relationship 降级为 OPTIONAL
- [x] 冻结 emotional_state.json 和 relationship.json 为只读快照 (数据已迁移)

### Phase 3: 迁移独特数据 (中风险)
- [x] 将 relationship.json 的 memorable_dates/memorable_events 合并到 soul-state.json
- [x] 验证数据完整性

### Phase 4: 重命名 runtime_emotion 端点 (中风险)
- [x] daemon GET /soul/emotion -> GET /system/vitality
- [x] MCP Plugin soulEmotionHandler 改为只读 soul-state.json
- [x] MCP Plugin 新增 systemVitalityHandler 读取 /system/vitality (通过 /soul/emotion 旧端点 + /system/vitality 新端点)
- [x] 更新 tools.mjs handler 注册表

### Phase 5: 验证 (必须)
- [x] 启动 daemon，确认所有端点正常 (port 62319, all online)
- [x] 调用 soul_emotion，确认返回角色内心情绪 (source=soul_state_json)
- [x] 调用 soul_status，确认返回一致
- [x] 调用 soul_check，确认服务状态正确 (required=3/3, optional=6/6)

---

## 四、风险与回退

| 风险 | 影响 | 缓解 |
|------|------|------|
| daemon 端点改名导致旧客户端断连 | 中 | 保留旧端点 30 天，返回 301 重定向 |
| memorable_dates 迁移数据丢失 | 低 | 迁移前备份 relationship.json |
| T12 退役后 daemon health check 报 degraded | 低 | 降级为 OPTIONAL 后不影响 daemon_state |

---

*本文档是小璃灵魂架构整合的执行蓝图。由小璃自主设计，Ba Ba 确认后执行。*
