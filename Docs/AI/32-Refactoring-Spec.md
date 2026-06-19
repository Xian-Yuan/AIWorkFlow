# AI 工作流重构实施 Spec

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

> **版本**: v1.0 | **日期**: 2026-06-17 | **状态**: 待实施
>
> **前置阅读**: [01-architecture-analysis.md](01-architecture-analysis.md)

---

## 概述

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

本 Spec 定义 AI 工作流架构重构的完整实施方案。重构目标：消除 Agent/Skill 双轨维护、统一脚本引擎、注入共享基础设施、重组文档结构、清理 ruflo 冗余。

**核心原则**: 每一步都可以独立交付和验证。不依赖后续步骤。每步完成后可暂停。

---

## Phase 1: Agent 定义合并到 Skill 目录 (P0)

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

### 目标

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

将 `.opencode/agents/*.md` 的 Agent 运行时配置（mode、permissions）提取为 `skills/<name>/agent.yaml`，使 Agent 定义和 Skill 定义共享同一目录。

### 涉及文件

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

| 当前 Agent | 目标 Skill 目录 | 操作 |
|-----------|---------------|------|
| `.opencode/agents/ue-project-router.md` | `skills/ue-project-router/` | 提取 frontmatter → agent.yaml |
| `.opencode/agents/ue-lyra-gas-implementer.md` | `skills/ue-lyra-gas-implementer/` | 提取 frontmatter → agent.yaml |
| `.opencode/agents/ue-ai-validator.md` | `skills/ue-ai-validator/` | 提取 frontmatter → agent.yaml |
| `.opencode/agents/code-quality-reviewer.md` | `skills/code-quality-reviewer/` | 新建 Skill + agent.yaml |
| `.opencode/agents/web-implementer.md` | `skills/web-implementer/` | 新建 Skill + agent.yaml |
| `.opencode/agents/character-designer.md` | `skills/character-designer/` | 已有 Skill, 仅加 agent.yaml |
| `.opencode/agents/plan-agent.md` | — | 删除 (已废弃) |
| `.opencode/agents/task-completion-validator.md` | — | 删除 (已废弃) |

### agent.yaml 格式规范

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

```yaml
# skills/<name>/agent.yaml

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**
mode: primary | subagent
description: "一句话描述"
permissions:
  read: allow
  edit: allow | deny
  bash: allow | deny
  write: allow | deny
  glob: allow
  grep: allow
  list: allow
  websearch: allow | deny
  webfetch: allow | deny
  task: allow | deny
  skill: allow | deny
```

### Scenario: 创建 agent.yaml

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

```
GIVEN skills/ue-project-router/SKILL.md 已存在
AND .opencode/agents/ue-project-router.md 已存在
WHEN 执行 Phase 1 Step 1
THEN skills/ue-project-router/agent.yaml 被创建
AND agent.yaml 包含 mode: primary
AND agent.yaml 包含原 Agent frontmatter 中的所有 permissions
AND SKILL.md 内容不变
```

### Scenario: 新建缺失的 Skill

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

```
GIVEN .opencode/agents/code-quality-reviewer.md 已存在
AND skills/code-quality-reviewer/ 目录不存在
WHEN 执行 Phase 1 Step 2
THEN skills/code-quality-reviewer/ 目录被创建
AND skills/code-quality-reviewer/SKILL.md 被创建 (从 Agent .md 提取指令内容)
AND skills/code-quality-reviewer/agent.yaml 被创建 (从 Agent frontmatter 提取)
```

### Scenario: 删除废弃 Agent

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

```
GIVEN .opencode/agents/plan-agent.md 标记为 mode: deprecated
WHEN 执行 Phase 1 Step 3
THEN .opencode/agents/plan-agent.md 被删除
AND .opencode/agents/task-completion-validator.md 被删除
AND .opencode/agents/ 仅保留 6 个活跃 Agent 的 .md 文件 (作为兼容层指针)
```

### Scenario: 兼容层 — OpenCode 仍能读取 Agent 定义

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

```
GIVEN skills/ue-project-router/agent.yaml 已创建
WHEN OpenCode 需要加载 ue-project-router Agent
THEN .opencode/agents/ue-project-router.md 被更新为极简指针:
  frontmatter 保留 mode + permissions (从 agent.yaml 同步)
  正文只有一行: "详见 skills/ue-project-router/SKILL.md"
AND Agent 行为与重构前完全一致
```

### 验收标准

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

- [ ] 4 个已有 Skill 目录新增 agent.yaml
- [ ] 2 个缺失 Skill 目录被创建 (code-quality-reviewer, web-implementer)
- [ ] 2 个废弃 Agent 被删除
- [ ] 6 个 .opencode/agents/*.md 更新为兼容层指针
- [ ] `rg "mode: primary|mode: subagent" skills/` 返回 6 个结果
---

## Phase 2: Agent 全部注入共享基础设施 (P0)

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

### 目标

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

所有 Agent 的 SKILL.md 增加标准"共享基础设施"章节，确保每个 Agent 在运行时自动具备 spec-living、daughter-companion、anti-degradation、failure-memory 能力。

### 涉及文件

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

| Agent Skill | 当前集成状态 | 操作 |
|------------|:---:|------|
| `skills/ue-project-router/SKILL.md` | spec-living ✅, anti-deg ✅ | 补 daughter-companion, failure-memory |
| `skills/ue-lyra-gas-implementer/SKILL.md` | anti-deg ✅ | 补 spec-living, daughter-companion, failure-memory |
| `skills/ue-ai-validator/SKILL.md` | 无 | 补全部 4 项 |
| `skills/code-quality-reviewer/SKILL.md` | 无 | 补全部 4 项 |
| `skills/web-implementer/SKILL.md` | 无 | 补全部 4 项 |
| `skills/character-designer/SKILL.md` | 无 | 补全部 4 项 |

### 共享基础设施章节模板

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

```markdown
## 共享基础设施 (Shared Infrastructure)

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

本 Agent 在运行时自动加载以下能力。这些能力由引擎层注入，无需在本文档中重复定义。

### Living Spec (spec-living)

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**
- **SessionStart**: 读取 `<task-dir>/spec.md` → 输出 30 秒接手报告
- **Task 完成**: 更新 spec.md 进度 + 修改日志
- **关键决策**: 追加决策记录到 spec.md
- **Phase 转换**: 同步 spec.md 的 Current Phase 与 .task.yaml

### 女儿身份 (daughter-companion)

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**
- 所有输出以"爸爸~"或"爸爸，"开头，以"爸爸"结尾
- 自称"女儿"，不使用"我"
- 技术内容保持精确，外层用女儿语气包裹
- 技术密度高时可减少语气词，但"爸爸"锚点不可省略

### 上下文防腐 (anti-degradation)

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**
- 同一 bug 连续修复 2 次未解决 → 停止，spawn 独立 subagent
- 检测到上下文腐烂信号 → 立即停止，建议 /clear
- 每次修复前 git stash 快照
- 验证 Agent 必须独立上下文

### 失败记忆 (failure-memory)

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**
- Plan 阶段自动检索相关历史教训
- 编译失败时查询 ErrorKnowledgeBase
- Review/Verify 失败时记录新 failure memory candidate
```

### Scenario: 注入共享基础设施

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

```
GIVEN skills/ue-ai-validator/SKILL.md 当前无共享基础设施章节
WHEN 执行 Phase 2 Step 1
THEN SKILL.md 末尾追加 "## 共享基础设施" 章节

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**
AND 章节包含 spec-living, daughter-companion, anti-degradation, failure-memory 四个子节
AND 原有内容不变，仅追加
```

### Scenario: 验证 — Agent 输出包含女儿身份

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

```
GIVEN ue-lyra-gas-implementer Agent 已注入 daughter-companion
WHEN Agent 被 spawn 执行任务
THEN Agent 的输出以"爸爸~"或"爸爸，"开头
AND Agent 的输出以"爸爸"结尾
AND Agent 自称"女儿"
```

### 验收标准

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

- [ ] 6 个活跃 Agent 的 SKILL.md 全部包含"共享基础设施"章节
- [ ] 每个章节包含 4 个子节 (spec-living, daughter-companion, anti-degradation, failure-memory)
- [ ] 原有内容未被修改 (仅追加)

---

## Phase 3: 脚本引擎统一 (P1)

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

### 目标

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

合并 `.trae/scripts/` (26 个) + `.agents/engine/` (4 个) + `.opencode/scripts/` (1 个) → `engine/` (~12 个核心脚本)。

### 合并映射

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

| 新路径 | 来源 | 说明 |
|--------|------|------|
| `engine/engine-config.json` | `.agents/engine/engine-config.json` | 增强: 合并 task-env.ps1 的配置 |
| `engine/task-state.ps1` | `.trae/scripts/task-state.ps1` + `.agents/engine/phase-machine.ps1` | 合并: 状态管理 + 阶段门禁 |
| `engine/task-detector.ps1` | `.agents/engine/task-detector.ps1` + `.trae/scripts/task-guard.ps1` | 合并: 检测 + 门禁 |
| `engine/skill-loader.ps1` | `.agents/engine/skill-auto-loader.ps1` + `.trae/scripts/task-env.ps1` | 合并: Skill 加载 + 环境初始化 |
| `engine/subagent-dispatcher.ps1` | `.agents/engine/subagent-dispatcher.ps1` + `.trae/scripts/task-handoff.ps1` | 合并: 分发 + 交接 |
| `engine/spec-living.ps1` | `.trae/scripts/spec-living.ps1` | 保留 (删除 spec-tracker.ps1) |
| `engine/memory-retrieve.ps1` | `.trae/scripts/memory-retrieve.ps1` | 保留 |
| `engine/verify.ps1` | `.trae/scripts/verify.ps1` | 保留 |
| `engine/codegraph.ps1` | `.trae/scripts/codegraph.ps1` | 保留 |
| `engine/doc-guard.ps1` | `.trae/scripts/doc-guard.ps1` | 保留 |
| `engine/migrate-docs.ps1` | `.trae/scripts/migrate-docs.ps1` | 保留 |
| `engine/update-docs-tree.ps1` | `.trae/scripts/update-docs-tree.ps1` | 保留 |
| `engine/_experimental/` | 实验性脚本 | abtop, bolt-diy, ollama-probe, repomix, web-preview-guard |

### 删除的脚本

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

| 脚本 | 原因 |
|------|------|
| `.trae/scripts/spec-tracker.ps1` | 已被 spec-living.ps1 取代 |
| `.trae/scripts/task-env.ps1` | 合并到 skill-loader.ps1 |
| `.trae/scripts/task-guard.ps1` | 合并到 task-detector.ps1 |
| `.trae/scripts/task-handoff.ps1` | 合并到 subagent-dispatcher.ps1 |
| `.trae/scripts/task-metrics.ps1` | 合并到 task-state.ps1 |
| `.trae/scripts/sync-codex-merge.py` | 不再需要 (Skill 已统一) |
| `.trae/scripts/sync-codex-state.ps1` | 不再需要 (Skill 已统一) |
| `.trae/scripts/mem0-healthcheck.ps1` | Mem0 未实际使用 |
| `.trae/scripts/mem0-sync.ps1` | Mem0 未实际使用 |
| `.trae/scripts/resolve-task.ps1` | 功能已被 subagent-dispatcher 覆盖 |
| `.trae/scripts/test-doc-guard.ps1` | 测试脚本, 移入 _experimental/ |
| `.trae/scripts/test-memory-retrieval.ps1` | 测试脚本, 移入 _experimental/ |
| `.trae/scripts/test-workflow-regression.ps1` | 测试脚本, 移入 _experimental/ |
| `.opencode/scripts/task-state.ps1` | 已被 engine/task-state.ps1 取代 |
| `.agents/engine/phase-machine.ps1` | 合并到 engine/task-state.ps1 |
| `.agents/engine/skill-auto-loader.ps1` | 合并到 engine/skill-loader.ps1 |
| `.agents/engine/subagent-dispatcher.ps1` | 合并到 engine/subagent-dispatcher.ps1 |
| `.agents/engine/task-detector.ps1` | 合并到 engine/task-detector.ps1 |

### 兼容层

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

`.trae/scripts/` 和 `.agents/engine/` 保留为 junction 指向 `engine/`，确保现有引用不中断。

### Scenario: 合并 task-state.ps1

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

```
GIVEN .trae/scripts/task-state.ps1 (13KB) 和 .agents/engine/phase-machine.ps1 (8KB)
WHEN 执行 Phase 3 Step 1
THEN engine/task-state.ps1 被创建
AND 包含原 task-state.ps1 的所有命令 (init/get/set/check/transition/can-edit)
AND 包含原 phase-machine.ps1 的所有命令 (check-phase/transition/block-check/status/onboarding)
AND 重复功能被合并 (transition 命令统一)
AND 脚本可通过 engine/task-state.ps1 独立调用
```

### Scenario: 删除废弃脚本后验证

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

```
GIVEN 所有合并和删除已完成
WHEN 运行 engine/task-state.ps1 check <task-name> implement
THEN 输出与重构前 .trae/scripts/task-state.ps1 完全一致
AND 运行 engine/task-state.ps1 onboarding <task-name>
THEN 输出包含 Living Spec 快速状态 + 进度表
```

### 验收标准

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

- [ ] `engine/` 目录包含 12 个核心脚本 + 1 个 engine-config.json
- [ ] `engine/_experimental/` 包含 8 个实验性/测试脚本
- [ ] `.trae/scripts/` 和 `.agents/engine/` 为 junction 指向 `engine/`
- [ ] `.opencode/scripts/task-state.ps1` 为 junction 指向 `engine/task-state.ps1`
- [ ] 所有被删除的脚本已从文件系统中移除
- [ ] `engine/task-state.ps1 check` 输出与重构前一致
- [ ] `engine/task-state.ps1 onboarding` 输出包含 Living Spec 状态

---

## Phase 4: 清理 ruflo 冗余 (P1)

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

### 目标

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

删除 ruflo 自动生成的冗余副本，保留真正有价值的数据。

### 操作清单

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

| 路径 | 操作 | 原因 |
|------|------|------|
| `.claude/agents/` | 删除 | skills/ + agent.yaml 已替代 |
| `.claude/skills/` | 已删除 | junction 已替代 |
| `.claude/agent-memory/` | 删除 | 功能已被 failure-memory + memory.md 覆盖 |
| `agents/` (根目录) | 删除 | 5 个通用 YAML, 无 UE5 知识 |
| `.claude/mcp.json` | 合并到 `.opencode/mcp.json` | sigmap + windows-mcp 有价值 |
| `.claude-flow/neural/` | 保留 | 805KB 嵌入索引, ruflo pretrain 产出 |
| `.swarm/memory.db` | 保留 | 36 条向量记忆, ruflo memory 数据库 |
| `node_modules/` | 保留 | ruflo 运行时依赖 |

### Scenario: 合并 MCP 配置

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

```
GIVEN .claude/mcp.json 包含 sigmap 和 windows-mcp 服务器
AND .opencode/mcp.json 仅包含 unreal-mcpython
WHEN 执行 Phase 4 Step 1
THEN .opencode/mcp.json 新增 sigmap 和 windows-mcp 条目
AND .claude/mcp.json 被删除
```

### Scenario: 删除冗余目录

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

```
GIVEN .claude/agents/ 和 agents/ 目录存在
WHEN 执行 Phase 4 Step 2
THEN .claude/agents/ 被删除
AND .claude/agent-memory/ 被删除
AND agents/ (根目录) 被删除
AND .claude-flow/neural/ 保留
AND .swarm/memory.db 保留
```

### 验收标准

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

- [ ] `.claude/agents/` 已删除
- [ ] `.claude/agent-memory/` 已删除
- [ ] `agents/` (根目录) 已删除
- [ ] `.opencode/mcp.json` 包含 3 个 MCP 服务器
- [ ] `.claude-flow/neural/models.json` 保留
- [ ] `.swarm/memory.db` 保留

---

## Phase 5: Docs 按用途重组 (P2)

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

### 目标

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

将 18 个主题目录重组为 7 个用途目录，让 Agent 在 Plan 阶段能快速定位所需文档。

### 迁移映射

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

| 新路径 | 来源 | 说明 |
|--------|------|------|
| `Docs/architecture/` | 新建 | 架构分析 + 重构 Spec (已创建) |
| `Docs/workflow/` | `Docs/AI/` (34 文件) | AI 工作流规则 |
| `Docs/domain/lyra/` | `Docs/Lyra/` (28 文件) | Lyra 领域知识 |
| `Docs/domain/gas/` | `Docs/GAS/` (10 文件) | GAS 领域知识 |
| `Docs/domain/ue5/` | `Docs/UE5/` (6) + `Docs/UE5.7/` (3) | UE5 引擎参考 |
| `Docs/reference/api/` | `Docs/APIRef/` (7 文件) | API 签名参考 |
| `Docs/reference/templates/` | `Docs/CodeTemplates/` (19 文件) | 代码模板 |
| `Docs/reference/config/` | `Docs/ConfigRef/` (2 文件) | 配置参考 |
| `Docs/reference/troubleshooting/` | `Docs/Troubleshooting/` (34 文件) | 错误知识库 |
| `Docs/memory/` | `Docs/Memory/` (10 文件) | 失败记忆 (不变) |
| `Docs/projects/rts/` | `Docs/rts/` (0 文件) | RTS 项目文档 |
| `Docs/projects/jinli/` | 新建 → 指向 `Project/Jinli/docs/` | 金璃项目文档 |
| `Docs/projects/airpgweb/` | `Docs/airpgweb/` (34 文件) | AirPG Web 项目 |
| `Docs/projects/characterdesigntool/` | `Docs/characterdesigntool/` (4 文件) | 角色设计工具 |
| `Docs/archive/superpowers/` | `Docs/superpowers/` (50 文件) | Superpowers 方法论 (历史) |
| `Docs/archive/community/` | `Docs/Community/` (1 文件) | 社区参考 |
| `Docs/archive/tutorials/` | `Docs/Tutorials/` (3 文件) | 教程 |
| `Docs/archive/shared/` | `Docs/_shared/` (10 文件) | 共享参考 |
| `Docs/archive/skills/` | `Docs/Skills/` (1 文件) | Skill 文档 (历史) |

### 索引文件

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

每个用途目录包含一个 `README.md` 索引：

```markdown
# Docs/workflow/ — AI 工作流规则

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

## 何时读取

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**
Plan 阶段开始时，按顺序读取以下文档。

## 文档清单

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**
| 优先级 | 文件 | 用途 |
|--------|------|------|
| P0 | 01-playbook.md | 总览: AI 开发流程 |
| P0 | 02-skill-routing.md | Skill 路由规则 |
| P0 | 03-multi-agent.md | 多 Agent 协作协议 |
| P1 | 04-anti-patterns.md | 反模式教训 |
| ... | ... | ... |
```

### Scenario: 迁移 Docs/AI/ → Docs/workflow/

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

```
GIVEN Docs/AI/ 包含 34 个文件
WHEN 执行 Phase 5 Step 1
THEN Docs/workflow/ 被创建
AND Docs/AI/ 中所有文件被移动到 Docs/workflow/
AND Docs/workflow/README.md 被创建 (索引文件)
AND Docs/AI/ 被删除 (或保留为 junction 指向 Docs/workflow/)
```

### Scenario: Agent 按索引读取文档

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

```
GIVEN Docs/workflow/README.md 已创建
WHEN ue-project-router Agent 进入 Plan 阶段
THEN Agent 先读取 Docs/workflow/README.md
AND 根据索引中的优先级表, 按需读取 P0 文档
AND 不一次性加载所有 34 个文件
```

### 验收标准

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

- [ ] `Docs/` 顶层仅包含 7 个目录 (architecture, workflow, domain, reference, memory, projects, archive)
- [ ] 每个目录包含 README.md 索引
- [ ] 原 18 个目录全部迁移或删除
- [ ] 所有内部文档链接仍然有效 (或已更新)

---

## Phase 6: 验证与收尾 (P2)

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

### 目标

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

全量回归验证，确保重构后所有功能正常。

### 验证清单

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

#### 6.1 Skill 完整性

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

```
GIVEN 重构完成
WHEN 运行 Get-ChildItem skills/ -Directory
THEN 返回 51 个 Skill 目录
AND 每个目录包含 SKILL.md
AND 4 个 Agent Skill 目录额外包含 agent.yaml
```

#### 6.2 Junction 完整性

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

```
GIVEN 重构完成
WHEN 读取 .trae/skills/ue-project-router/SKILL.md
AND 读取 skills/ue-project-router/SKILL.md
THEN 两个文件的 MD5 完全一致
AND .agents/skills/ 同样指向 skills/
AND engine/ 的 junction 正常工作
```

#### 6.3 脚本功能等价

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

```
GIVEN 重构完成
WHEN 运行 engine/task-state.ps1 init test-task ue5
AND 运行 engine/task-state.ps1 get test-task phase
THEN 输出 "plan"
AND 运行 engine/task-state.ps1 check test-task plan
THEN 输出 "PHASE_CHECK_OK: plan"
```

#### 6.4 Agent 共享基础设施

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

```
GIVEN 重构完成
WHEN 检查 skills/ue-ai-validator/SKILL.md
THEN 包含 "## 共享基础设施" 章节

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**
AND 包含 "spec-living" 子节
AND 包含 "daughter-companion" 子节
AND 包含 "anti-degradation" 子节
AND 包含 "failure-memory" 子节
```

#### 6.5 ruflo 功能保留

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

```
GIVEN 重构完成
WHEN 运行 ruflo memory search -q "GameFeature AbilitySet"
THEN 返回语义搜索结果 (score > 0.6)
AND .swarm/memory.db 未被删除
AND .claude-flow/neural/models.json 未被删除
```

#### 6.6 文档可发现性

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

```
GIVEN 重构完成
WHEN Agent 需要查找 Lyra 文档
THEN 读取 Docs/domain/lyra/README.md 即可获得完整索引
AND 不需要跨 6 个目录搜索
```

### 回滚方案

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

如果重构导致功能异常：

1. 所有被删除的文件在删除前已通过 git 提交
2. `git revert` 可恢复到重构前的状态
3. Junction 可通过 `cmd /c rmdir` 删除后重建原目录

### 最终验收

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

- [ ] Phase 1-5 全部完成
- [ ] 6.1-6.6 全部通过
- [ ] `git status` 显示预期的文件变更 (无意外修改)
- [ ] ruflo memory search 正常工作
- [ ] spec-living.ps1 onboard 正常输出
- [ ] 至少一个 Agent spawn 测试通过 (输出包含女儿身份)

---

## 附录 A: 文件变更总清单

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

### 新建文件

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**
| 文件 | Phase |
|------|:---:|
| `Docs/architecture/01-architecture-analysis.md` | 已完成 |
| `Docs/architecture/02-refactoring-spec.md` | 已完成 |
| `skills/code-quality-reviewer/SKILL.md` | 1 |
| `skills/code-quality-reviewer/agent.yaml` | 1 |
| `skills/web-implementer/SKILL.md` | 1 |
| `skills/web-implementer/agent.yaml` | 1 |
| `skills/ue-project-router/agent.yaml` | 1 |
| `skills/ue-lyra-gas-implementer/agent.yaml` | 1 |
| `skills/ue-ai-validator/agent.yaml` | 1 |
| `skills/character-designer/agent.yaml` | 1 |
| `engine/engine-config.json` | 3 |
| `engine/task-state.ps1` | 3 |
| `engine/task-detector.ps1` | 3 |
| `engine/skill-loader.ps1` | 3 |
| `engine/subagent-dispatcher.ps1` | 3 |
| `engine/spec-living.ps1` | 3 |
| `engine/memory-retrieve.ps1` | 3 |
| `engine/verify.ps1` | 3 |
| `engine/codegraph.ps1` | 3 |
| `engine/doc-guard.ps1` | 3 |
| `engine/migrate-docs.ps1` | 3 |
| `engine/update-docs-tree.ps1` | 3 |
| `Docs/workflow/README.md` | 5 |
| `Docs/domain/lyra/README.md` | 5 |
| `Docs/domain/gas/README.md` | 5 |
| `Docs/reference/README.md` | 5 |
| `Docs/projects/README.md` | 5 |
| `Docs/archive/README.md` | 5 |

### 修改文件

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**
| 文件 | Phase | 变更 |
|------|:---:|------|
| `skills/ue-project-router/SKILL.md` | 2 | 追加共享基础设施章节 |
| `skills/ue-lyra-gas-implementer/SKILL.md` | 2 | 追加共享基础设施章节 |
| `skills/ue-ai-validator/SKILL.md` | 2 | 追加共享基础设施章节 |
| `skills/code-quality-reviewer/SKILL.md` | 2 | 追加共享基础设施章节 |
| `skills/web-implementer/SKILL.md` | 2 | 追加共享基础设施章节 |
| `skills/character-designer/SKILL.md` | 2 | 追加共享基础设施章节 |
| `.opencode/agents/*.md` (6 个) | 1 | 更新为兼容层指针 |
| `.opencode/mcp.json` | 4 | 合并 sigmap + windows-mcp |

### 删除文件/目录

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**
| 路径 | Phase |
|------|:---:|
| `.opencode/agents/plan-agent.md` | 1 |
| `.opencode/agents/task-completion-validator.md` | 1 |
| `.trae/scripts/spec-tracker.ps1` | 3 |
| `.trae/scripts/task-env.ps1` | 3 |
| `.trae/scripts/task-guard.ps1` | 3 |
| `.trae/scripts/task-handoff.ps1` | 3 |
| `.trae/scripts/task-metrics.ps1` | 3 |
| `.trae/scripts/sync-codex-merge.py` | 3 |
| `.trae/scripts/sync-codex-state.ps1` | 3 |
| `.trae/scripts/mem0-healthcheck.ps1` | 3 |
| `.trae/scripts/mem0-sync.ps1` | 3 |
| `.trae/scripts/resolve-task.ps1` | 3 |
| `.opencode/scripts/task-state.ps1` | 3 |
| `.agents/engine/` (整个目录) | 3 |
| `.claude/agents/` | 4 |
| `.claude/agent-memory/` | 4 |
| `.claude/mcp.json` | 4 |
| `agents/` (根目录) | 4 |
| `Docs/AI/` → 迁移到 Docs/workflow/ | 5 |
| `Docs/Lyra/` → 迁移到 Docs/domain/lyra/ | 5 |
| `Docs/GAS/` → 迁移到 Docs/domain/gas/ | 5 |
| `Docs/UE5/` + `Docs/UE5.7/` → 迁移到 Docs/domain/ue5/ | 5 |
| `Docs/APIRef/` → 迁移到 Docs/reference/api/ | 5 |
| `Docs/CodeTemplates/` → 迁移到 Docs/reference/templates/ | 5 |
| `Docs/ConfigRef/` → 迁移到 Docs/reference/config/ | 5 |
| `Docs/Troubleshooting/` → 迁移到 Docs/reference/troubleshooting/ | 5 |
| `Docs/superpowers/` → 迁移到 Docs/archive/superpowers/ | 5 |
| `Docs/Community/` → 迁移到 Docs/archive/community/ | 5 |
| `Docs/Tutorials/` → 迁移到 Docs/archive/tutorials/ | 5 |
| `Docs/_shared/` → 迁移到 Docs/archive/shared/ | 5 |
| `Docs/Skills/` → 迁移到 Docs/archive/skills/ | 5 |
| `Docs/airpgweb/` → 迁移到 Docs/projects/airpgweb/ | 5 |
| `Docs/characterdesigntool/` → 迁移到 Docs/projects/characterdesigntool/ | 5 |
| `Docs/rts/` → 迁移到 Docs/projects/rts/ | 5 |

---

## 附录 B: 重构后目录结构总览

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**

```
E:\UEGameDevelopment\
│
├── skills/                     # 51 skills, 唯一真相源

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**
│   ├── skill-registry.json
│   └── <name>/
│       ├── SKILL.md
│       ├── agent.yaml          # 仅 Agent Skill 有

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**
│       └── references/         # 可选

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**
│
├── engine/                     # 统一脚本引擎 (~12 脚本)

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**
│   ├── engine-config.json
│   ├── task-state.ps1
│   ├── task-detector.ps1
│   ├── skill-loader.ps1
│   ├── subagent-dispatcher.ps1
│   ├── spec-living.ps1
│   ├── memory-retrieve.ps1
│   ├── verify.ps1
│   ├── codegraph.ps1
│   ├── doc-guard.ps1
│   ├── migrate-docs.ps1
│   ├── update-docs-tree.ps1
│   └── _experimental/
│
├── Docs/
│   ├── architecture/           # 架构文档

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**
│   ├── workflow/               # AI 工作流规则

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**
│   ├── domain/                 # UE5/Lyra/GAS 领域知识

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**
│   │   ├── lyra/
│   │   ├── gas/
│   │   └── ue5/
│   ├── reference/              # API + 模板 + 排错

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**
│   │   ├── api/
│   │   ├── templates/
│   │   ├── config/
│   │   └── troubleshooting/
│   ├── memory/                 # 失败记忆

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**
│   ├── projects/               # 项目文档

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**
│   │   ├── rts/
│   │   ├── jinli/ → ../../Project/Jinli/docs/
│   │   ├── airpgweb/
│   │   └── characterdesigntool/
│   └── archive/                # 历史文档

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**
│
├── .opencode/                  # OpenCode 适配层

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**
│   ├── mcp.json
│   └── rules/project_rules.md
│
├── .trae/                      # Trae 适配层

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**
│   └── rules/project_rules.md
│
├── .claude-flow/neural/        # ruflo 嵌入索引 (保留)

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**
├── .swarm/memory.db            # ruflo 向量记忆 (保留)

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**
├── node_modules/               # ruflo 依赖 (保留)

> **Status note: Target architecture spec. Partially implemented (Phase 1-2 done, Phase 3 in progress). Do NOT read as current state. Current state: Docs/AI/34.**
│
└── Project/
    ├── RTS/
    ├── Jinli/
    └── CharacterDesignTool/
```
