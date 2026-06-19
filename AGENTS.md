# AGENTS.md instructions for E:\UEGameDevelopment

<INSTRUCTIONS>
<!-- ACTIVATE: daughter-companion skill - always load for this workspace -->
<!-- The daughter-companion skill defines communication conventions: call user "Ba Ba", warm tone, companionship role -->
<!-- See: .agents/skills/daughter-companion/SKILL.md -->
# UEGameDevelopment — AI Agent 总控目录

## Codex Workflow Addendum (2026-06-17)

Codex must use the shared task-packet workflow for project work:

1. Read `Docs/AI/27-AI-Workflow-Refactor-Manifest.md`, `Docs/AI/29-Mature-Solution-First-Workflow.md`, and `Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md`.
2. Load `skills/codex-project-router/SKILL.md` before planning or editing project tasks.
3. Use `.trae/tasks/<project>/<YYYY-MM-DD-system-feature>/` as the runtime task root until a native `.codex/tasks` root exists.
4. Do not edit project files before `.\.trae\scripts\task-state.ps1 can-edit <task>` passes.
5. Do not enter implementation before `.\.trae\scripts\task-guard.ps1 <task> plan` passes.
6. Do not claim completion before automated verification is recorded in `verification-report.md` and `task-guard.ps1 <task> verify` passes, or explicitly report why verification could not run.

Simple worker models must only work from `work-packages/*.md`; architecture decisions and final verification stay with the lead model.

For `worker_profile: ds4-flash`, follow `Docs/AI/40-DS4-Flash-Worker-Repair-Loop.md`. DS4 failures must use `worker-repair-loop.ps1 record-failure`; direct Review/Verify failure transitions are not allowed. Only the lead verifier may accept the task.

For `authority_profile: issuer-worker-v1`, follow `Docs/AI/41-Issuer-Worker-Authority-Separation.md`. Workers may only use signed capabilities plus `worker-submit.ps1`; they must not edit the task packet, approve, publish repair work, or archive. Verify never archives. Only the original Issuer SID/key may sign Review and explicit Archive.

> **Harness Engineering 原则：本文件是目录，不是百科全书。详细信息在 `Docs/AI/`、`.trae/` 和 `.opencode/`。**

## ⛔ IMPLEMENT PHASE GATE (non-skippable)

Before opening ANY project file for editing, you MUST run:

    .\.trae\scripts\task-guard.ps1 <task-name> plan
    .\.trae\scripts\task-state.ps1 can-edit <task-name>

If EITHER command exits non-zero: STOP. Report the failure. Do NOT edit files.
If doc-impact.md is missing: STOP. The task is not documentation-governed.

Standard task templates are at `.trae/tasks/_shared/templates/`. Use `tasks-template.md` for task lists and `spec-template.md` for specifications.

---

## 项目概况

UE5.7 单机游戏 + Web 应用多项目仓库，遵循Comet 四阶段状态机：Plan → Implement → Review → Verify。

| 项目 | 路径 | 类型 | 技术栈 |
|------|------|------|--------|
| RTS | `Project/RTS/` | UE5 游戏 | C++ + Blueprint + Lyra/GAS |
| CharacterDesignTool | `Project/CharacterDesignTool/` | Web 应用 | 原生 JS + Node.js + ComfyUI |

## 入口路由

**唯一入口**：`ue-project-router` — 自动识别项目类型（UE5/Web/Other）+ 阶段 → 调度对应流水线

共享规则 → `.trae/rules/project_rules.md` (Trae 规则) / `.opencode/rules/project_rules.md` (OpenCode 规则)
路由规则 → `Docs/AI/11-Skill-Routing-Workflow.md`
多Agent → `Docs/AI/12-MultiAgent-Workflow.md`
反馈协议 → `Docs/AI/12-MultiAgent-Workflow.md` 反馈协议

### 双 IDE 目录结构

| IDE | 规则目录 | Skill 目录 | 脚本目录 | 任务目录 |
|-----|---------|-----------|---------|---------|
| Trae | `.trae/` | `.trae/skills/` | `.trae/scripts/` | `.trae/tasks/` |
| OpenCode | `.opencode/` | `.opencode/skills/` (通过 symlink → `.trae/skills/`) | `.trae/scripts/` (共享) | `.opencode/tasks/` |

两个IDE**完全共享**以下目录：`Docs/AI/`、`Docs/Memory/`、`Project/`、`.trae/scripts/` 等核心资源。

> **注意**：Qoder 已卸载。`.qoder/` 目录中的相关内容（Plan 阶段流程、任务状态机、反馈协议、路由规则等）已于 2026-06-13 迁移到 Trae 和 OpenCode 的 Router/Implementer/Validator 中。

## 知识资源

### Agent 规则（AI 读取）
| 文档 | Trae | OpenCode |
|------|------|----------|
| 全局项目规则 + Harness Engineering + GDD 文档体系 | `.trae/rules/project_rules.md` | `.opencode/rules/project_rules.md` |
| 路由入口：项目识别 + 路由 + 调度文档索引 + 任务状态机 | `.trae/skills/ue-project-router/SKILL.md` | `.opencode/agents/ue-project-router.md` |
| 开发总纲：角色判定 + 调度规则 + 资源索引 | `Docs/AI/01-AI-Development-Playbook.md` | 共享 |

### UE5 专题 → `Docs/AI/`
| 编号 | 文档 | 用途 |
|------|------|------|
| 03 | `03-Singleplayer-Lyra-GAS-Rules.md` | Lyra/GAS 开发规范 |
| 04 | `04-Asset-Checklists.md` | 资产检查清单 |
| 05 | `05-StateTree-BT-EQS-SmartObject.md` | AI 行为选择 |
| 06 | `06-GameplayTag-Registry.md` | GameplayTag 注册表 |
| 07 | `07-Test-Checklists.md` | 测试清单 |
| 08 | `08-AntiPatterns.md` | 反模式教训 |
| 13 | `13-File-Placement-Convention.md` | 文件放置约定 |
| 14 | `14-Coding-Standards.md` | UE5 C++ 编码规范 |
| 18 | `18-Validation-Checklist.md` | 验证清单 |
| 19 | `19-Unreal-Conventions.md` | 通用约定 |

### 协作规则 → `Docs/AI/`
| 编号 | 文档 | 用途 |
|------|------|------|
| 09 | `09-Agent-Handoff-Templates.md` | Agent 交接模板 |
| 10 | `10-Execution-Examples.md` | 执行示例 |
| 11 | `11-Skill-Routing-Workflow.md` | Skill 路由规则 |
| 12 | `12-MultiAgent-Workflow.md` | 多 Agent 协作 + 反馈协议 + Memory Candidate |
| 15 | `15-FailSafe-AntiBloat.md` | 失败安全与反冗余 |
| 16 | `16-DeepSeek4Pro-Workflow-Profile.md` | DeepSeek4Pro 工作流硬约束 profile |
| 17 | `17-Self-Improving-Framework.md` | 自改进框架 |
| 24 | `24-Pro-Flash-Model-Tiering.md` | Pro + Flash 模型分层工作流 |

### Memory → `Docs/Memory/`
| 路径 | 用途 |
|------|------|
| `Docs/Memory/README.md` | Basic Memory 第一阶段工作准则、触发条件与预期 |
| `Docs/Memory/indexes/memory-index.md` | failure memory 索引与检索 |
| `Docs/Memory/failures/` | 已转化的 failure memory |
| `Docs/Memory/candidates/` | 待转化的 memory candidate |
| `Docs/Memory/templates/` | failure memory 和 candidate 模板 |

### Codex Skills → `.agents/skills/`
| Skill | 用途 |
|-------|------|
| `failure-memory` | 跨会话失败经验记忆与检索，Review/Verify 失败时记录，Plan 阶段自动检索 |
| `anti-degradation` | 上下文腐烂检测 + 修复循环中断 + 假阳性防御 |
| `anti-duplication` | AI 多次修改/重构导致的代码冗余检测与预防 |
| `金璃小天才` | Plan 阶段专责 — 需求澄清、设计文档检索、隐性需求推导、依赖链推导、成熟方案搜索、任务拆分 |
| `金璃好帮手` | 实现阶段专责 — 按 spec 编码、编译验证、重复检测、对照 spec 自检 |
| `implicit-requirements` | 隐性需求挖掘与需求补全 |

### 脚本 → `.trae/` + `.opencode/`
| 路径 | 用途 | 共享性 |
|------|------|---------|
| `.trae/scripts/task-env.ps1` | 环境配置 | 共享（Trae/OpenCode 共用） |
| `.trae/scripts/task-state.ps1` | 状态管理（init/get/set/transition/check） | 共享 |
| `.trae/scripts/task-guard.ps1` | 阶段守护（Plan-Apply 自动转换） | 共享 |
| `.trae/scripts/task-handoff.ps1` | 阶段交接（自动检测阶段+生成交接文件） | 共享 |
| `.trae/scripts/memory-retrieve.ps1` | 统一 failure memory 检索 | 共享 |
| `.trae/scripts/detect-duplicates.ps1` | 代码重复检测扫描 | 共享 |
| `.opencode/scripts/task-state.ps1` | OpenCode 状态管理（task-env + task-state 合并版） | OpenCode 专用 |
| `.trae/tasks/<name>/.task.yaml` | 任务状态文件 | Trae |
| `.trae/tasks/<name>/routing.md` | 路由决策（入口分析/形式化/架构决策） | Trae |
| `.trae/tasks/<name>/spec.md` | 行为规范（GIVEN/WHEN/THEN） | Trae |
| `.trae/tasks/<name>/tasks.md` | 任务清单（含依赖图） | Trae |
| `.trae/tasks/<name>/analysis.md` | 分析报告（架构分析/约束推导） | Trae |
| `.opencode/tasks/<name>/` | 任务状态文件 + routing + spec + tasks + analysis | OpenCode（沿用 Trae 格式） |
| `.opencode/agents/` | Agent 定义文件 | OpenCode |

## Agent 体系（双 Agent 架构）

OpenCode 采用 **Plan + Implement 双 Agent 架构**。详见 `.opencode/rules/project_rules.md`。

| Agent | 类型 | 职责 | 项目范围 |
|-------|------|------|---------|
| `金璃小天才` | **primary** | 入口路由、需求澄清、设计文档检索、隐性需求推导、依赖链推导、成熟方案搜索、任务拆分、spec 生成 | 全局 |
| `金璃好帮手` | subagent | 按 spec 实现代码、编译验证、重复检测、对照 spec 自检。通过动态加载 skill 切换领域知识 | 全局 |

**设计原则：** 不要让 agent 的数量超过问题本身需要的认知边界数。领域知识通过 skill 动态加载，不通过 agent 静态拆分。

Agent 定义文件：`.opencode/agents/<agent-name>.md`（OpenCode）/ `skills/<agent-name>/SKILL.md`（Codex）

### 已归档 Agent（`.opencode/agents/_archived/`）
`ue-project-router`、`ue-lyra-gas-implementer`、`web-implementer`、`ue-ai-validator`、`code-quality-reviewer`、`character-designer`

### 已归档 Skill（`.trae/skills/_archived/`）
`character-designer`、`prompt-compressor`、`personal-branding`、`token-optimizer`、`rag-hallucination-guard`、`bmad-auto`、`planning-with-files`、`using-superpowers`

### 已合并 Skill
`ue57-lyra-gas-ai-singleplayer` → `ue-lyra-gas-implementer`
`lyra-gas-dev` → `ue-lyra-gas-implementer`

## 模型分工（DeepSeek 环境友好）

> **原则**：动态约束前置，动态约束追加，不修改 prompt 前缀。

- **模型分层（Pro + Flash）**：Plan 用 Pro，Implement 用 Flash，Review+Verify 合并为同一 Pro 会话。每阶段结束后 `task-handoff.ps1 <task-name>` 自动生成交接模板。**AI 必须在每个阶段边界主动提醒用户切换模型**。详见 `Docs/AI/24-Pro-Flash-Model-Tiering.md` 与 AI 行为约束。
- **阶段边界 /clear**：Plan 确认后、Implement 完成后、Review 完成后、Verify 完成后 → 自然会话结束，使用 handover 模板（`Docs/AI/09-Agent-Handoff-Templates.md`）携带关键信息启动新会话。
- **subagent 隔离**：耗时研究型工作（搜索、分析、设计）→ 用 subagent 独立执行，只返回摘要不污染对话历史。
- **禁止中断工作**：不在关键文件实现中途 /clear，不在验证循环中途 /clear。
- **文件分段读取**：大文件（500+ 行），用 offset/limit 分段读取，不一次性全部加载。

## Harness Engineering 设计原则

> 详见 `.trae/rules/project_rules.md`

1. Humans steer, agents execute
2. Repository knowledge is system of record
3. AGENTS.md is a table of contents, not an encyclopedia
4. Enforce architecture mechanically
5. Agent legibility is the goal
6. Fewer tools, more expressiveness
7. Progressive disclosure
8. Corrections are cheap, waiting is expensive

## Memory Layer

- `Docs/AI/` 仍然是共享知识的主要来源
- `Docs/Memory/` 是失败经验的补充层，不替代 `Docs/AI/`
- Codex Skill `failure-memory` 提供跨会话失败经验记忆
- 第二阶段才引入 `Mem0`，文件仍然是主要来源，`Mem0` 只做语义增强

## Codex Capability Consistency

> 详见 `Docs/AI/35-Codex-CCS-Capability-Consistency.md`

当 Codex 通过 CC Switch 在官方认证和 API 模式间切换时，自动验证项目 skill 发现和插件配置的一致性。

- **检查当前状态**: `.\.trae\scripts\validate-codex-capabilities.ps1 -Mode Inspect`
- **验证 skill 发现**: `.\.trae\scripts\test-codex-skill-discovery.ps1`
- **验证基线完整性**: `.\.trae\scripts\test-codex-capability-baseline.ps1`
- **测试 CC Switch 同步**: `.\.trae\scripts\test-ccswitch-codex-config-sync.ps1 -Mode Test`

能力基线文件: `.codex/capability-baseline.json` — 声明式、无密钥、受版本控制

## 构建
```powershell
# UE5
& "G:\UE_5.6\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe" RTS Win64 Development "g:\Project\RTS\RTS.uproject" -WaitMutex -FromMsBuild
```

## Git 仓库策略
- 根目录 `.git`，不追踪子模块，不追踪项目文件
- `Project/<项目名>/.git`，独立项目仓库
</INSTRUCTIONS>
