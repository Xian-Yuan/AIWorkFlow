# UEGameDevelopment — AI Agent 上下文目录

> **Harness Engineering 原则：本文件是目录，不是百科全书。深层真相在 `Docs/AI/` 和 `.trae/`。**

## 项目概况

UE5.7 单机游戏 + Web 应用多项目工作区。Comet 风格状态机驱动：Plan → Implement → Review → Verify。

| 项目 | 路径 | 类型 | 技术栈 |
|------|------|------|--------|
| RTS | `Project/RTS/` | UE5 游戏 | C++ + Blueprint + Lyra/GAS |
| CharacterDesignTool | `Project/CharacterDesignTool/` | Web 应用 | 原生 JS + Node.js + ComfyUI |

## 工作流入口

**唯一入口**：`ue-project-router` → 自动检测项目类型（UE5/Web/Other）+ 任务阶段 → 分派到对应流水线

核心命令 → `.trae/rules/project_rules.md` (工作流章节)
路由规则 → `Docs/AI/11-Skill-Routing-Workflow.md`
多Agent → `Docs/AI/12-MultiAgent-Workflow.md`

## 真相源索引

### Agent 规则（AI 读取）
| 文档 | 用途 |
|------|------|
| `.trae/rules/project_rules.md` | 全项目规则 + Harness Engineering 原则 + 编码规范 + GDD 文档体系 |
| `.trae/skills/ue-project-router/SKILL.md` | 工作流唯一入口（含项目类型检测 + 路由表） |
| `Docs/AI/01-AI-Development-Playbook.md` | 开发总纲 |

### UE5 专项 → `Docs/AI/`
| 编号 | 文档 | 用途 |
|------|------|------|
| 03 | `03-Singleplayer-Lyra-GAS-Rules.md` | Lyra/GAS 单机规范 |
| 04 | `04-Asset-Checklists.md` | 资产接线清单 |
| 05 | `05-StateTree-BT-EQS-SmartObject.md` | AI 行为选型 |
| 06 | `06-GameplayTag-Registry.md` | GameplayTag 注册表 |
| 07 | `07-Test-Checklists.md` | 测试清单 |
| 08 | `08-AntiPatterns.md` | 反模式与教训 |
| 13 | `13-File-Placement-Convention.md` | 文件放置约定 |
| 14 | `14-Coding-Standards.md` | UE5 C++ 编码规范 |
| 18 | `18-Validation-Checklist.md` | 验收清单 |
| 19 | `19-Unreal-Conventions.md` | 虚幻约定 |

### 协作规则 → `Docs/AI/`
| 编号 | 文档 | 用途 |
|------|------|------|
| 09 | `09-Agent-Handoff-Templates.md` | Agent 交接模板 |
| 10 | `10-Execution-Examples.md` | 执行示例 |
| 16 | `16-DeepSeek4Pro-Workflow-Profile.md` | DeepSeek4Pro 工作流硬门禁 profile |
| 20 | `20-DeepSeek4Pro-Regression-Scenarios.md` | DeepSeek4Pro 工作流回归场景目录 |
| 21 | `21-Workflow-Regression-Checklist.md` | 工作流回归检查清单 |
| 15 | `15-FailSafe-AntiBloat.md` | 失败安全与防膨胀 |
| 17 | `17-Self-Improving-Framework.md` | 自改进框架 |

### Memory → `Docs/Memory/`
| 路径 | 用途 |
|------|------|
| `Docs/Memory/README.md` | Basic Memory 第一阶段规则、准入门槛与检索预算 |
| `Docs/Memory/indexes/memory-index.md` | failure memory 轻量检索入口 |
| `Docs/Memory/templates/` | failure memory 与 candidate 模板 |

### Memory Tooling → `.trae/`
| 路径 | 用途 |
|------|------|
| `.trae/memory/mem0.config.json` | Mem0 本地实验配置 |
| `.trae/scripts/mem0-healthcheck.ps1` | Mem0 可用性检查 |
| `.trae/scripts/memory-retrieve.ps1` | 统一 failure memory 检索入口 |
| `.trae/scripts/mem0-sync.ps1` | 正式 memory 同步到 Mem0 |

### 工具链 → `.trae/`
| 路径 | 用途 |
|------|------|
| `.trae/scripts/task-env.ps1` | 脚本发现 |
| `.trae/scripts/task-state.ps1` | 状态机（init/get/set/transition/check） |
| `.trae/scripts/task-guard.ps1` | 阶段守卫（-Apply 自动流转） |
| `.trae/tasks/<name>/.task.yaml` | 任务状态文件 |
| `.trae/tasks/<name>/routing.md` | 路由决策（含依赖链/隐式需求/架构引用） |
| `.trae/tasks/<name>/spec.md` | 行为规范（GIVEN/WHEN/THEN） |
| `.trae/tasks/<name>/analysis.md` | 依赖链推导 + 隐式需求提醒 + 架构方案引用 |
| `.trae/tasks/<name>/tasks.md` | 任务清单（按依赖图排序） |
| `.opencode/agents/` | Agent 定义文件 |

## Agent 体系

| Agent | 职责 | 项目类型 |
|-------|------|---------|
| `ue-project-router` | **唯一入口** — 类型检测 + 路由 + Spec生成 + 状态机 | 所有 |
| `ue-lyra-gas-implementer` | Lyra/GAS 主链路实现 | UE5 |
| `web-implementer` | Web Implement 阶段执行 + can-edit 门禁 | Web |
| `ue-ai-validator` | AI 选型 + UE5 Verify 收口 | UE5 |
| `code-quality-reviewer` | 代码质检（Review） + 改动验收（Verify） — 已合并原 task-completion-validator | 所有 |

## 上下文管理（DeepSeek 缓存友好）

> **原则**：静态内容前置，动态内容追加，不修改 prompt 前缀。

- **阶段边界 /clear**：Plan 确认后、Implement 完成后、Review 完成后、Verify 完成后 → 自然结束会话。用 handover 模板（`Docs/AI/09-Agent-Handoff-Templates.md`）传递关键上下文到新会话。
- **subagent 隔离**：长时间研究型工作（搜索已有实现、分析代码库）→ 派 subagent 独立执行，只返回摘要，不污染主对话历史。
- **禁止中断规则**：不在跨文件实现进行中 /clear。不在编译验证循环中 /clear。
- **文件分批读取**：大文件（500+ 行）用 offset/limit 分批，不一次性全加载。

## Harness Engineering 核心原则

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

- `Docs/AI/` 仍然是工作流与规则真相源
- `Docs/Memory/` 是失败经验的辅助记忆层，不替代 `Docs/AI/`
- 第二阶段若接入 `Mem0`，文件仍然是真相源，`Mem0` 只做检索增强

## 编译
```powershell
# UE5
& "G:\UE_5.6\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe" RTS Win64 Development "g:\Project\RTS\RTS.uproject" -WaitMutex -FromMsBuild
```

## Git 仓库隔离
- 根目录 `.git`：管理工具链文件，不追踪项目代码
- `Project/<项目名>/.git`：各项目独立仓库
