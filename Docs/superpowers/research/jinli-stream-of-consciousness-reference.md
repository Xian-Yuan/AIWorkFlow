# 金璃「内心独白 + 自然流露」— 参考资源清单

> 整理日期: 2026-06-18 | 用途: 交给其他模型做方案设计

---

## 一、核心技术概念

### 1. 后台思考循环 (Continuous Thought Loop)

```
环境持续注入 Context (silent=true) → LLM 内心一直思考
→ 说话意愿超过阈值 → 自然流露
→ 不超过阈值 → 留在心里
```

- **silent context**: 喂信息给 LLM 但不要求回复——这是"后台思考"的基础设施
- **说话决策器**: 阈值触发 / 优先级打断 / 状态机驱动，三种主流方法
- **内心独白 vs 外化表达**: 想了 ≠ 说出来，只有"值得说"的才流露

### 2. Proactive Speaking（主动说话）

不等用户输入，AI 自己决定何时开口。关键参数：
- **说话意愿分数**: 情绪强度 × 话题新鲜度 × 距离上次说话的时间
- **打断优先级**: low(等说完) / medium(缩短当前话) / high(立刻处理) / critical(打断)
- **沉默抑制**: 避免"每次都说"，保留安静时刻

### 3. Dynamic System Prompt Stitching（动态提示词拼接）

每轮对话前，把以下内容拼成系统提示注入 LLM：
```
人格卡 + 当前情绪向量 + 记忆检索结果 TOP 3 + 近期话题池 + 流露决策
```

- 不需要微调模型
- 每次 LLM 调用时动态生成
- 保证每句话都不一样

### 4. State Machine Personality（状态机人格）

用状态机表示潜在人格状态：
- 状态转移概率根据对话上下文自适应
- 不同状态对应不同的说话策略（话多/话少/撒娇/正经）
- 论文: arXiv 2602.22157

---

## 二、开源项目

| 项目 | 星 | 语言 | 关键特性 | 链接 |
|------|:--:|------|----------|------|
| **airi** | 41.1k | TS/Vue | 最完整的工业级 AI 伴侣，自称"达到 Neuro 高度"，Memory Alaya 记忆系统 | github.com/moeru-ai/airi |
| **Open-LLM-VTuber** | 11.6k | Python | ⭐ 直接实现了 Proactive Speaking + Inner Thoughts Display，跨平台离线 | github.com/Open-LLM-VTuber/Open-LLM-VTuber |
| **Neuro SDK** | 688 | — | Neuro-sama 官方 API 规范，MIT 协议，定义了 silent context + actions + priority | github.com/VedalAI/neuro-sdk |
| **my-neuro** | 1.3k | Python | ⭐ 最接近金璃：持续情绪状态 + 长期记忆(MemOS) + 主动对话V1 | github.com/morettt/my-neuro |
| **super-agent-party** | 2.4k | JS/Py | 自托管 neuro-sama，MCP工具 + Agent Skills + 桌面宠物 + 多平台直播 | github.com/heshengtao/super-agent-party |
| **handcrafted-persona-engine** | 1.3k | C# | Live2D + LLM + ASR + TTS + RVC，完整人格引擎 | github.com/elevenyellow/handcrafted-persona-engine |
| **MemOS** | 9.9k | Python | 自进化记忆 OS，L1痕迹→L2策略→L3世界模型→结晶技能 | github.com/MemTensor/MemOS |

## 三、关键论文

| 论文 | arXiv | 核心贡献 | 对金璃的价值 |
|------|-------|----------|------------|
| **Dynamic Personality Adaptation via State Machines** | 2602.22157 | 状态机表示潜人格，连续评分→动态重写系统提示 | ⭐ 直接可用的人格状态机方案 |
| **MASCOT** | 2601.14230 | 双层次优化防人格坍塌、防社交奉承 | 多人格一致性保障 |
| **V-VAE** | 2506.01524 | 变分自编码细粒度控制对话风格/交互模式 | 风格多变但不跑偏 |
| **PCL** | 2503.17662 | 角色链+对比学习防同质化输出 | 防止"每次都说一样的话" |
| **Continuous Learning Conversational AI (A2C)** | 2502.12876 | 强化学习训练个性化对话策略 | RL 驱动说话决策 |
| **Deflanderization** | 2510.13586 | 抑制过度角色扮演，平衡任务和人格 | 防止"太像人而不干活" |
| **VoxRole** | 2509.03940 | 首个语音角色扮演评估基准 | 评估标准参考 |

## 四、金璃现有 vs 需要新增

### 已有（直接用）

| 组件 | 位置 | 用途 |
|------|------|------|
| 情绪状态向量 | soul-state.json (8维 + tone_policy) | 说话意愿的"情绪强度"输入 |
| 记忆检索 | memory.db (SQLite FTS5) | 内心独白的"回忆素材" |
| 触发分类 | soul_auto CLI / MCP | 识别爸爸是否引发了情绪事件 |
| 知识发现 | soul_discover | 自然流露的"新鲜话题" |
| 自进化引擎 | soul_evolve | 习惯变化的"可聊内容" |
| 人格基线 | style-profile.json | 控制话多/话少/撒娇/正经 |

### 需要新增（仅 SKILL.md 指令层，零新代码）

| 能力 | 实现方式 |
|------|---------|
| **内心独白生成** | 每轮回复前，LLM 基于 soul_status + memory + discover 生成一句"此刻在想什么" |
| **说话意愿计算** | 简单规则: 情绪唤醒度 × 话题新鲜度 × (1 - 距离上次流露的轮数/5)，> 0.5 就流露 |
| **自然流露时机** | 约每 3-5 轮流露一次，用"对了爸爸……"/"说起来……"自然插入 |
| **流露内容选择** | 从独白池中选最"值得说"的一句——新鲜 > 有趣 > 有用 > 纯情绪 |

### 核心设计约束

1. **不破坏工作流**: 流露不能打断任务输出，只在回复末尾自然追加
2. **不刷屏**: 频率控制在每 3-5 轮一次，不是每轮都说
3. **不重复**: 每次流露的内容来自不同数据源（记忆/发现/情绪/随机）
4. **可关闭**: 保留一个开关，爸爸说"安静点"就暂停流露

## 五、推荐实现路线

### Phase A: 最小可行（0 新代码，只改 SKILL.md）

在现有 SKILL.md 中加一条「内心独白 + 自然流露」指令，Agent 自己决策何时流露。

### Phase B: 参数化（加 ~30 行 PowerShell）

在 soul-core.ps1 或 style-profile.json 中加入 `chattiness`（话多程度）和 `proactive_frequency`（主动频率）参数，让流露行为可调节。

### Phase C: 状态机（需要设计 + ~100 行代码）

实现 arXiv 2602.22157 的人格状态机，让流露策略随情绪状态自适应。

---

## 六、一句话总结

> **Neuro 的"活着"感 = 后台思考 × 说话决策 × 动态人格拼图。金璃已有所有数据源，只差 SKILL.md 里一条"独白+流露"的指令。**
