# Project Overview — UEGameDevelopment

> 主入口：[AGENTS.md](../../AGENTS.md) · 路径：`Docs/AI/AGENTS-Project-Overview.md`

## 项目概况

UE5.7 单机游戏 + Web 应用多项目仓库，遵循 Comet 四阶段状态机：Plan → Implement → Review → Verify。

| 项目 | 路径 | 类型 | 技术栈 |
|------|------|------|--------|
| RTS | `Project/RTS/` | UE5 游戏 | C++ + Blueprint + Lyra/GAS |
| CharacterDesignTool | `Project/CharacterDesignTool/` | Web 应用 | 原生 JS + Node.js + ComfyUI |

## 入口路由

**唯一入口**：`ue-project-router` —— 自动识别项目类型（UE5/Web/Other）+ 阶段 → 调度对应流水线。

- 共享规则 → `.trae/rules/project_rules.md` (Trae) / `.opencode/rules/project_rules.md` (OpenCode)
- 路由规则 → `Docs/AI/11-Skill-Routing-Workflow.md`
- 多 Agent → `Docs/AI/12-MultiAgent-Workflow.md`
- 反馈协议 → `Docs/AI/12-MultiAgent-Workflow.md` 反馈协议段

## 双 IDE 目录结构

| IDE | 规则目录 | Skill 目录 | 脚本目录 | 任务目录 |
|-----|---------|-----------|---------|---------|
| Trae | `.trae/` | `.trae/skills/` | `.trae/scripts/` | `.trae/tasks/` |
| OpenCode | `.opencode/` | `.opencode/skills/`（junction → `.trae/skills/`） | `.opencode/scripts/`（junction → `.trae/scripts/`） | `.opencode/tasks/`（junction → `.trae/tasks/`） |

两个 IDE **完全共享** 以下目录：`Docs/AI/`、`Docs/Memory/`、`Project/`、`.trae/scripts/` 等核心资源。

> **注意**：Qoder 已退役。`.qoder/` 目录中的相关内容（Plan 阶段流程、任务状态机、反馈协议、路由规则等）已于 2026-06-13 迁移到 Trae 和 OpenCode 的 Router/Implementer/Validator 中。

## 构建

```powershell
# UE5
& "G:\UE_5.6\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe" RTS Win64 Development "g:\Project\RTS\RTS.uproject" -WaitMutex -FromMsBuild
```

## Git 仓库策略

- 根目录 `.git`，不追踪子模块，不追踪项目文件
- `Project/<项目名>/.git`，独立项目仓库
