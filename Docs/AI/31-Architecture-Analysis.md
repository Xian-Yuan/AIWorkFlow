---
domain: ai
domain_path: ai/workflow
kg_node_id: node.doc-ai-ai-31-architecture-analysis-62f9
t13_retro_classified_at: "2026-06-24T04:47:04Z"
kg_id: doc.ai.ai.31-architecture-analysis.62f9

---

# AI 工作流架构深度分析报告

> **Status note: Historical architecture analysis. Some facts have changed (e.g. .opencode/agents now pointer layer). Retained as historical input for refactoring. Current state: Docs/AI/34.**

> **日期**: 2026-06-17 | **版本**: v1.0 | **状态**: 已完成
>
> **分析范围**: 全项目文件系统扫描 + Agent/Skill 内容对比 + 脚本依赖分析 + ruflo 集成评估

---

## 一、当前架构全景

> **Status note: Historical architecture analysis. Some facts have changed (e.g. .opencode/agents now pointer layer). Retained as historical input for refactoring. Current state: Docs/AI/34.**

```
E:\UEGameDevelopment\
│
├── skills/ (51 skills) ← 统一真相源 (2026-06-17 新建)
│   ├── skill-registry.json
│   ├── ue-project-router/     ├── daughter-companion/
│   ├── ue-lyra-gas-implementer/  ├── spec-living/
│   ├── ue-ai-validator/       ├── anti-degradation/
│   └── ... (46 more)
│       ↑                    ↑
│   .trae/skills/ ──Junction──┤  (Trae IDE 透明访问)
│   .agents/skills/ ─Junction─┘  (Codex 透明访问)
│
├── .opencode/agents/ (8 Agent 定义, 2 已废弃)
│   ├── ue-project-router.md (11.5KB, primary)
│   ├── ue-lyra-gas-implementer.md (7.7KB, subagent)
│   ├── code-quality-reviewer.md (7.7KB, subagent)
│   ├── ue-ai-validator.md (3.2KB, subagent)
│   ├── web-implementer.md (3.5KB, subagent)
│   ├── character-designer.md (345B, subagent — 几乎空壳)
│   ├── plan-agent.md (废弃, 已合并到 ue-project-router)
│   └── task-completion-validator.md (废弃, 已合并到 code-quality-reviewer)
│
├── .trae/scripts/ (26 个 PowerShell 脚本)
│   ├── task-state.ps1, task-guard.ps1, task-handoff.ps1  ← 阶段管理
│   ├── spec-living.ps1, spec-tracker.ps1                  ← Spec 管理
│   ├── memory-retrieve.ps1, memory-benchmark.ps1          ← 记忆系统
│   ├── verify.ps1, codegraph.ps1                          ← 验证+图谱
│   └── doc-guard.ps1, migrate-docs.ps1, update-docs-tree.ps1 ← 文档管理
│
├── .agents/engine/ (4 个 PowerShell 脚本, 2026-06-17 新建)
│   ├── task-detector.ps1       ← 任务类型检测 (14 规则)
│   ├── phase-machine.ps1       ← 阶段门禁 + onboarding
│   ├── skill-auto-loader.ps1   ← Skill 栈自动生成
│   └── subagent-dispatcher.ps1 ← 子 Agent 分发规划
│
├── Docs/ (18 个子目录, 258 个文件)
│   ├── AI/ (34) — 工作流规则真相源
│   ├── APIRef/ (7) — UE5 API 签名参考
│   ├── GAS/ (10), Lyra/ (28) — 领域知识
│   ├── Memory/ (10) — 失败记忆
│   ├── CodeTemplates/ (19) — 代码模板
│   ├── Troubleshooting/ (34) — 错误知识库
│   ├── superpowers/ (50) — Superpowers 方法论
│   ├── airpgweb/ (34), characterdesigntool/ (4), rts/ (0) — 项目文档
│   └── UE5/ (6), UE5.7/ (3), _shared/ (10) — 引擎参考
│
├── .opencode/rules/project_rules.md (8.1KB)
├── .opencode/mcp.json (325B — 仅 1 个 MCP 服务器)
├── .opencode/scripts/task-state.ps1 (4.2KB — 简化版)
│
├── .claude/ — ruflo 自动生成的副本 (agents + skills + mcp)
├── .claude-flow/ — ruflo 神经模型数据 (805KB)
│
├── agents/ — ruflo 生成的通用 Agent YAML (5 个, 无 UE5 知识)
├── node_modules/ — ruflo 依赖 (549 包)
│
└── Project/
    ├── RTS/ — UE5 游戏项目
    ├── Jinli/ — 金璃项目 (docs + data)
    └── CharacterDesignTool/ — Web 应用
```

---

## 二、核心问题诊断

> **Status note: Historical architecture analysis. Some facts have changed (e.g. .opencode/agents now pointer layer). Retained as historical input for refactoring. Current state: Docs/AI/34.**

### 问题 1：Agent 定义与 Skill 定义是两套系统，维护成本 2x

> **Status note: Historical architecture analysis. Some facts have changed (e.g. .opencode/agents now pointer layer). Retained as historical input for refactoring. Current state: Docs/AI/34.**

| 能力 | Agent (.opencode/agents/) | Skill (skills/) | 内容重叠 |
|------|--------------------------|-----------------|:---:|
| 路由决策 | ue-project-router.md (11.5KB) | ue-project-router/SKILL.md (11.6KB) | ~90% |
| Lyra/GAS 实现 | ue-lyra-gas-implementer.md (7.7KB) | ue-lyra-gas-implementer/SKILL.md (9.7KB) | ~80% |
| AI 验证 | ue-ai-validator.md (3.2KB) | ue-ai-validator/SKILL.md (4.7KB) | ~70% |
| 角色设计 | character-designer.md (345B) | character-designer/SKILL.md (9.0KB) | ~4% |

**根因**: Agent 和 Skill 本质上是同一个东西——"告诉 AI 怎么做事"的指令文件。区别只在于 Agent 多了 OpenCode 特有的 frontmatter（mode、permission），Skill 多了 Codex 特有的 frontmatter（name、description）。内容 80-90% 重叠。

**影响**: 改一个路由规则要改两个文件。spec-living 只集成到了 Agent 的 ue-project-router，Skill 的 ue-project-router 没有同步更新。两个版本正在逐渐分叉。

**量化**: 4 个同名 Agent+Skill 对，总维护量 = 32KB (Agent) + 35KB (Skill) = 67KB。合并后预计 = 35KB (SKILL.md) + 2KB (agent.yaml × 4) = 37KB。节省 45%。

---

### 问题 2：脚本层四套系统，功能重叠严重

> **Status note: Historical architecture analysis. Some facts have changed (e.g. .opencode/agents now pointer layer). Retained as historical input for refactoring. Current state: Docs/AI/34.**

| 功能 | .trae/scripts/ | .agents/engine/ | .opencode/scripts/ | 评价 |
|------|:---:|:---:|:---:|------|
| 任务状态管理 | task-state.ps1 (13KB) | phase-machine.ps1 (8KB) | task-state.ps1 (4KB) | **三份实现** |
| 任务检测/门禁 | task-guard.ps1 (12KB) | task-detector.ps1 (5KB) | — | 两份实现 |
| Skill 加载 | task-env.ps1 (1.2KB) | skill-auto-loader.ps1 (3.6KB) | — | 两份实现 |
| 子 Agent 分发 | task-handoff.ps1 (7.9KB) | subagent-dispatcher.ps1 (7.4KB) | — | 两份实现 |
| Spec 管理 | spec-living.ps1 (10KB) + spec-tracker.ps1 (16KB) | — | — | 两份实现 |

**根因**: `.agents/engine/` 是 2026-06-17 新建的"自动化引擎"，设计目标是替代 `.trae/scripts/` 的手动流程。但它只实现了 4 个组件，没有覆盖全部 26 个脚本。而且它和 `.trae/scripts/` 之间没有调用关系——两套系统独立运行，互不知道对方存在。

**影响**: `engine-config.json` 的 `always_on_skills` 改了，但 `task-env.ps1` 不知道。`phase-machine.ps1` 的 onboarding 改了，但 `task-state.ps1` 不知道。任何一处的更新都需要手动同步到另一处。

**量化**: 30 个脚本 → 合并后预计 ~12 个核心脚本 + ~5 个实验性脚本。减少 43%。

---

### 问题 3：Agent 之间没有共享基础设施

> **Status note: Historical architecture analysis. Some facts have changed (e.g. .opencode/agents now pointer layer). Retained as historical input for refactoring. Current state: Docs/AI/34.**

| Agent | spec-living | daughter-companion | anti-degradation | failure-memory |
|-------|:---:|:---:|:---:|:---:|
| ue-project-router | ✅ | ❌ | ✅ | ❌ |
| ue-lyra-gas-implementer | ❌ | ❌ | ✅ | ❌ |
| ue-ai-validator | ❌ | ❌ | ❌ | ❌ |
| code-quality-reviewer | ❌ | ❌ | ❌ | ❌ |
| web-implementer | ❌ | ❌ | ❌ | ❌ |

**根因**: 每个 Agent 的 SKILL.md 是独立编写的，没有"共享基础设施"的概念。always_on_skills 只在 task-orchestrator 层面生效，但 spawn 出来的 subagent 不会自动继承这些 Skill。

**影响**: Router spawn 一个 Implementer subagent 时，那个 subagent 不知道项目进度（没有 spec-living），不会用女儿的语气说话（没有 daughter-companion），不会检测上下文腐烂（只有 Implementer 自己有 anti-degradation，但 Reviewer 和 Validator 没有）。

---

### 问题 4：Docs/ 分类按"主题"而非"用途"

> **Status note: Historical architecture analysis. Some facts have changed (e.g. .opencode/agents now pointer layer). Retained as historical input for refactoring. Current state: Docs/AI/34.**

```
Docs/AI/            — 工作流规则 (34 文件)
Docs/superpowers/   — Superpowers 方法论 (50 文件)
Docs/APIRef/        — API 参考 (7 文件)
Docs/GAS/           — GAS 文档 (10 文件)
Docs/Lyra/          — Lyra 文档 (28 文件)
Docs/airpgweb/      — 特定项目文档 (34 文件)
```

**问题**: 一个 Agent 在 Plan 阶段需要读哪些文档？它需要从 6 个不同目录里挑。`Docs/AI/` 里的 `01-AI-Development-Playbook.md` 和 `Docs/superpowers/` 里的方法论是什么关系？`Docs/UE5/` 和 `Docs/UE5.7/` 的区别是什么？没有索引文件回答这些问题。

---

### 问题 5：ruflo 集成产生了新冗余

> **Status note: Historical architecture analysis. Some facts have changed (e.g. .opencode/agents now pointer layer). Retained as historical input for refactoring. Current state: Docs/AI/34.**

| 路径 | 内容 | 评价 |
|------|------|------|
| `.claude/agents/` | 从 .opencode/agents/ 复制的副本 | 冗余 — junction 已替代 skills |
| `.claude/mcp.json` | 比 .opencode/mcp.json 多 2 个服务器 | 有价值 — 应合并到 .opencode/mcp.json |
| `.claude-flow/neural/` | 805KB 嵌入索引 | 有价值 — ruflo pretrain 的产出 |
| `.swarm/memory.db` | 向量记忆数据库 | 有价值 — 36 条领域知识 |
| `agents/*.yaml` | 5 个通用 Agent YAML | 无价值 — 无 UE5 知识 |
| `node_modules/` | 549 包, ruflo 运行时 | 保留 — 运行时依赖 |

---

## 三、重构目标架构

> **Status note: Historical architecture analysis. Some facts have changed (e.g. .opencode/agents now pointer layer). Retained as historical input for refactoring. Current state: Docs/AI/34.**

```
E:\UEGameDevelopment\
│
├── skills/ (51 skills) ← 唯一真相源
│   ├── skill-registry.json
│   └── <skill-name>/
│       ├── SKILL.md          ← 通用指令 (所有 IDE 共用)
│       ├── agent.yaml        ← Agent 运行时配置 (mode, permissions)
│       └── references/       ← 领域参考文档 (可选)
│
├── engine/ ← 统一脚本引擎 (合并 .trae/scripts/ + .agents/engine/)
│   ├── engine-config.json    ← 唯一配置
│   ├── task-state.ps1        ← 唯一任务状态管理
│   ├── task-detector.ps1     ← 唯一任务检测
│   ├── phase-machine.ps1     ← 唯一阶段门禁
│   ├── skill-loader.ps1      ← 唯一 Skill 加载
│   ├── subagent-dispatcher.ps1 ← 唯一子 Agent 分发
│   ├── spec-living.ps1       ← 唯一 Spec 管理
│   ├── memory-retrieve.ps1   ← 记忆检索
│   ├── verify.ps1            ← 验证
│   ├── codegraph.ps1         ← 代码图谱
│   ├── doc-guard.ps1         ← 文档守卫
│   └── _experimental/        ← 实验性脚本
│
├── Docs/ ← 按用途重组
│   ├── architecture/         ← 架构文档 (本报告 + Spec)
│   ├── workflow/             ← AI 工作流规则 (原 Docs/AI/)
│   ├── domain/               ← UE5/Lyra/GAS 领域知识
│   │   ├── lyra/
│   │   ├── gas/
│   │   └── ue5/
│   ├── reference/            ← API 签名 + 代码模板
│   ├── memory/               ← 失败记忆 (原 Docs/Memory/)
│   ├── projects/             ← 各项目文档
│   └── archive/              ← 历史文档
│
├── .opencode/ ← OpenCode 专用适配层 (极薄)
│   ├── mcp.json
│   └── rules/project_rules.md
│
├── .trae/ ← Trae 专用适配层 (极薄)
│   └── rules/project_rules.md
│
├── .claude-flow/ ← ruflo 神经数据 (保留)
│   └── neural/models.json
│
├── .swarm/ ← ruflo 记忆数据库 (保留)
│   └── memory.db
│
└── Project/
    ├── RTS/
    ├── Jinli/
    └── CharacterDesignTool/
```

---

## 四、核心变化总结

> **Status note: Historical architecture analysis. Some facts have changed (e.g. .opencode/agents now pointer layer). Retained as historical input for refactoring. Current state: Docs/AI/34.**

| # | 变化 | 从 | 到 | 节省 |

> **Status note: Historical architecture analysis. Some facts have changed (e.g. .opencode/agents now pointer layer). Retained as historical input for refactoring. Current state: Docs/AI/34.**
|---|------|----|----|:---:|
| 1 | Agent 定义合并到 Skill | 8 个 Agent .md + 51 个 Skill .md | 51 个 SKILL.md + 4 个 agent.yaml | 45% 维护量 |
| 2 | 脚本引擎统一 | 30 个脚本 (3 目录) | ~12 个核心脚本 (1 目录) | 60% 脚本数 |
| 3 | Agent 共享基础设施 | 0 个 Agent 有完整集成 | 6 个 Agent 全部注入 | 从无到有 |
| 4 | Docs 按用途重组 | 18 个主题目录 | 7 个用途目录 | 查找效率 3x |
| 5 | 清理 ruflo 冗余 | 4 个冗余目录 | 保留 2 个有价值目录 | 50% 冗余清理 |

---

## 五、重构优先级

> **Status note: Historical architecture analysis. Some facts have changed (e.g. .opencode/agents now pointer layer). Retained as historical input for refactoring. Current state: Docs/AI/34.**

| 优先级 | 任务 | 影响范围 | 风险 | 预估时间 |
|:---:|------|------|:---:|:---:|
| **P0** | Agent 定义合并到 Skill 目录 (agent.yaml) | 8 个 Agent → 4 个 Skill 新增 yaml | 低 | 1h |
| **P0** | 所有 Agent 注入共享基础设施章节 | 6 个活跃 Agent 的 SKILL.md | 低 | 1h |
| **P1** | 脚本引擎统一 | 30 个脚本 → ~12 个 | 中 | 3h |
| **P1** | 清理 ruflo 冗余 | 删除 ~10 个文件/目录 | 低 | 0.5h |
| **P2** | Docs 按用途重组 | 258 个文件重新分类 | 中 | 2h |
