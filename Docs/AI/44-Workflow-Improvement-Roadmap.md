---
domain: ai
domain_path: ai/workflow
kg_node_id: node.doc-ai-ai-44-workflow-improvement-roadmap-d24a
t13_retro_classified_at: "2026-06-24T04:47:04Z"
kg_id: doc.ai.ai.44-workflow-improvement-roadmap.d24a

---

# 44 — AI 工作流改进路线图

> **状态**: Plan — 建议清单，等待爸爸批准后执行
> **日期**: 2026-06-20
> **真相源**: `Docs/AI/research/2026-06-20-AI-Agent-Ecosystem-Technical-Reference.md` 的分析发现
> **关联记忆**: `Docs/Memory/candidates/2026-06-20-mechanical-gate-gap.md`

---

## 目录

- [Part 1：三大系统性问题](#part-1三大系统性问题)
- [Part 2：改进建议优先级矩阵](#part-2改进建议优先级矩阵)
- [Part 3：每项建议详情](#part-3每项建议详情)
- [Part 4：Skill 自我成长差距分析](#part-4skill-自我成长差距分析)
- [Part 5：执行策略](#part-5执行策略)

---

## Part 1：三大系统性问题

### 问题 1：机械门禁缺失（Severity: ❌ 高）

| 维度 | 内容 |
|------|------|
| **现象** | 所有门禁（task-guard.ps1、task-state.ps1、doc-guard.ps1）依赖 Agent 自觉调用，没有机械层的强制执行 |
| **对比** | Claude Code 有 28 种 Hook 事件 + 5 种 Hook 类型，在 PreToolUse / UserPromptSubmit 等生命周期关键点自动触发 |
| **影响** | Codex 读到 AGENTS.md 但不一定执行 gate；Hermes MCP 包装了门禁但 Guard Plugin 仍靠 Profile 加载正确 |
| **解决方案** | 需要 Hook 层（硬门禁）补充当前的调用层（软门禁）|
| **证据** | `Docs/Memory/candidates/2026-06-20-mechanical-gate-gap.md` |

### 问题 2：Skills 体系缺少自进化闭环（Severity: ⚠️ 中）

| 维度 | 内容 |
|------|------|
| **现象** | 4 个成长机制（.memory.md、writing-skills TDD、Self-Improving Framework、Soul Core 进化）各自独立，没有形成闭环 |
| **对比** | MUSE-Autoskill 的五阶段生命周期：创建 → 记忆 → 管理 → 评估 → 优化 → 再创建 |
| **影响** | Skill 执行失败不会自动触发修复；.memory.md 不会自动催生 SKILL.md 更改；soul_evolve 不进 skill 文档 |
| **解决方案** | 先以 `.memory.md` 全覆盖为基础，再逐步建设闭环 |

### 问题 3：三平台集成并非完美一致（Severity: ⚠️ 中）

| 维度 | 内容 |
|------|------|
| **现象** | Skills 和门禁物理共享，但接入方式不同，Codex 缺少原生 Agent 角色分离，Hermes 集成需手动同步 |
| **对比** | 理想状态：三个平台在任意一个发起的 Plan 都能被另一个无缝继续 |
| **影响** | 工作流碎片化风险；配置漂移可能在手动同步不及时时发生 |
| **解决方案** | 统一运行时层抽象，减少平台特化适配器 |

---

## Part 2：改进建议优先级矩阵

```
                      Impact
                Low           Medium          High
   Effort   ┌───────────┬──────────────┬──────────────┐
   Low      │  S6(四维)  │ S2(2-Action)  │ S3(CodeGraph)│
            │           │ S5(记忆升级)  │ S1(.memory)   │
            ├───────────┼──────────────┼──────────────┤
   Medium   │  S7(自生成)│              │ S4(Hook门禁)  │
            │           │              │              │
            ├───────────┼──────────────┼──────────────┤
   High     │  S8(闭环)  │              │              │
            │           │              │              │
            └───────────┴──────────────┴──────────────┘

   S = 建议编号，详见 Part 3
```

**建议顺序**：S3(CodeGraph，已有基础设施) → S2(2-Action，快速) → S6(四维，快速) → S1(.memory.md，低投入高回报) → S5(记忆分层升级) → S4(Hook 门禁，需调研) → S7(自生成技能) → S8(闭环)

---

## Part 3：每项建议详情

### S1 — 给每个 Skill 加上 `.memory.md`

| 维度 | 内容 |
|------|------|
| **参考** | MUSE-Autoskill 的 skill-level memory |
| **当前状态** | 已试点 4 个（金璃小天才/好帮手/failure-memory/code-knowledge-graph），共 1 条经验/个 |
| **工作量** | ~30 分钟扩至核心 10 个 Skill |
| **输出** | `skills/<name>/.memory.md` — 该 Skill 的失败模式、边界情况、性能限制 |
| **前置条件** | 无 |
| **验收** | 核心 Skill 全部拥有 `.memory.md`，至少 1 条经验 |

### S2 — 在 Plan 阶段引入 2-Action Rule

| 维度 | 内容 |
|------|------|
| **参考** | planning-with-files 的 2-Action Rule：每 2 次 view/browser/search 后必须更新 findings |
| **当前状态** | 无此机制 |
| **工作量** | ~15 分钟 |
| **输出** | 在 Plan 阶段 worklist 中增加检查点 |
| **前置条件** | 无 |
| **验收** | Plan 阶段的 analysis.md 有"研究发现"子节 |

### S3 — 用 CodeGraph 做 Plan 阶段依赖分析

| 维度 | 内容 |
|------|------|
| **参考** | CodeGraph + code-knowledge-graph skill |
| **当前状态** | CodeGraph 已安装（有 `.codex-shared/codegraph/`），`code-knowledge-graph` skill 有完整 SKILL.md |
| **工作量** | ~10 分钟（确认配置，增加一步到 Plan 流程）|
| **输出** | Plan 阶段用 CodeGraph 查询受影响模块，结果写入 analysis.md |
| **前置条件** | CodeGraph MCP Server 已运行 |
| **验收** | analysis.md 的"依赖链推导"包含 CodeGraph 证据 |

### S4 — 研究 Hook 级别的机械门禁

| 维度 | 内容 |
|------|------|
| **参考** | Claude Code 28 种 Hook + 5 种类型；skill-force-eval.js（社区 50% → 84% 提升）|
| **当前状态** | 无 Hook 层 |
| **工作量** | ~1-2 天调研 + 原型 |
| **输出** | 调研报告 + 原型实现（OpenCode/Codex 的 PreToolUse 级别拦截） |
| **前置条件** | 确定 OpenCode/Codex 是否有原生 Hook 支持 |
| **验收** | 原型验证能在工具使用前自动触发门禁检查 |

### S5 — 升级 failure-memory 为分层记忆

| 维度 | 内容 |
|------|------|
| **参考** | Supermemory 五层上下文栈 + MUSE 三层次记忆 |
| **当前状态** | failure-memory 只记录 Review/Verify 失败 |
| **工作量** | ~半天 |
| **输出** | 区分短期（task 内 findings）和长期（跨 task failure pattern）+ 自动遗忘 |
| **前置条件** | S1 (.memory.md 全覆盖) |
| **验收** | 检索时可以按时间/范围分层过滤 |

### S6 — 在 Plan 阶段引入四维失败分析

| 维度 | 内容 |
|------|------|
| **参考** | SkillForge 的四维：知识/工具/澄清/风格 |
| **当前状态** | 无此检查 |
| **工作量** | ~10 分钟 |
| **输出** | analysis.md 模板增加四维检查清单 |
| **前置条件** | 无 |
| **验收** | Plan 时自动检查四维完整性 |

### S7 — 自生成技能

| 维度 | 内容 |
|------|------|
| **参考** | MUSE `skill_create` 工具 + writing-skills TDD 流程 |
| **当前状态** | writing-skills 支持 TDD 式创建，但人工引导 |
| **工作量** | ~3 天 |
| **输出** | Agent 可以在检测到重复问题时自动创建新 Skill |
| **前置条件** | S1 (.memory.md 证据积累) + S4 (Hook 自动触发) |
| **验收** | Agent 在没有人类指令的情况下创建并验证一个 Skill |

### S8 — 失败→诊断→优化闭环

| 维度 | 内容 |
|------|------|
| **参考** | SkillForge: Fail → Diagnose → Optimize |
| **当前状态** | 无此闭环 |
| **工作量** | ~1 周 |
| **输出** | Skill 执行失败自动触发诊断 → 定位 Skill 缺陷 → 最小修改 → 重验证 |
| **前置条件** | S4 (Hook 自动检测失败) + S7 (自生成技能) |
| **验收** | 模拟一次失败，系统自动完成诊断→修复→验证 |

---

## Part 4：Skill 自我成长差距分析

### 4.1 当前拥有的能力 ✅

| 能力 | 贡献者 | 覆盖范围 |
|------|--------|---------|
| **Skill 级经验积累** | `.memory.md` | 4/60+ Skills |
| **TDD 式 Skill 创建** | `writing-skills` skill | 人工引导 |
| **被动学习** | Self-Improving Framework Engine 2 | 全局 |
| **主动发现** | Self-Improving Framework Engine 3 | 全局 |
| **定期升级** | Self-Improving Framework Engine 4 | 当爸爸触发时 |
| **Agent 人格进化** | Soul Core: soul_evolve / soul_learn | Agent 风格/语气 |
| **知识缺口填补** | Soul Core: soul_discover | 搜索建议 |

### 4.2 与 MUSE 五阶段对比缺失 ❌

```
MUSE 五阶段           本地状态                  差距
──────────────────────────────────────────────────────
Skill Creation    → writing-skills (人工)    ❌ 无 skill_create 工具
Skill Memory      → .memory.md 试点          ⚠️ 4/60+ 覆盖率低
Skill Management  → skill-registry.json     ❌ 无语义搜索/合并/遗忘
Skill Evaluation  → 无                       ❌ 无单元测试门禁
Skill Refinement  → 无                       ❌ 无自动修复闭环
```

### 4.3 现有机制为什么不构成闭环

```
现有 4 个成长机制之间没有连接：

  Self-Improving          writing-skills
  Framework               (TDD创建)
     │                        │
     ▼                        ▼
  Soul Core              SKILL.md + .memory.md
  (人格进化)                (4/60+ pilot)
  
  ❌ 没有"发现缺口 → 创建 Skill → 测试 → 部署 → 监控"的管道
  ❌ soul_evolve 不进 skill 文档
  ❌ .memory.md 的经验不会自动触发 SKILL.md 更新
  ❌ Skill 执行失败不会自动进入修复流程
```

---

## Part 5：执行策略

### 5.1 分阶段执行

#### 第一阶段：基础设施夯实（P0，可并行）
- [ ] S1: `.memory.md` 扩展到全部核心 Skill
- [ ] S2: Plan 阶段 2-Action Rule
- [ ] S3: CodeGraph 深度集成
- [ ] S6: 四维失败分析检查清单

#### 第二阶段：记忆分层（P1）
- [ ] S5: failure-memory 分层升级
- [ ] 建立短期/长期记忆的自动转换规则

#### 第三阶段：机械门禁（P1-P2）
- [ ] S4: Hook 级别机械门禁调研 + 原型
- [ ] 在 PreToolUse 级别自动触发门禁检查

#### 第四阶段：自进化闭环（P2-P3）
- [ ] S7: 自生成技能工具
- [ ] S8: 失败→诊断→优化闭环

### 5.2 执行顺序逻辑

```
S3(CodeGraph) ─── 已有基础设施，先确认能用
    │
    ▼
S2(2-Action) + S6(四维) ─── 快速见效
    │
    ▼
S1(.memory.md) ─── 低投入高回报
    │
    ▼
S5(记忆分层) ─── 建立在 .memory.md 之上
    │
    ▼
S4(Hook 门禁) ─── 需调研，但最核心
    │
    ▼
S7(自生成) + S8(闭环) ─── 长期目标
```

---

> **文档状态**: Plan — 等待爸爸批准后开始执行
> **关联文件**:
> - 建议来源: `Docs/AI/research/2026-06-20-AI-Agent-Ecosystem-Technical-Reference.md`
> - 机械门禁记忆: `Docs/Memory/candidates/2026-06-20-mechanical-gate-gap.md`
> - 环境基准: `Docs/reference/local-llm-tools.md`
