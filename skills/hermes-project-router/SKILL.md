---
name: hermes-project-router
description: Hermes 适配器 — 为 Hermes Profile 提供项目入口识别和任务包路由，桥接 Hermes 工具语义与共享工作流。
---

# Skill: hermes-project-router

## 职责

Hermes 适配器 — 路由层。为 Hermes Profile 提供项目入口识别和任务包路由，桥接 Hermes 工具语义与共享工作流。

## 项目上下文

- 共享工作流根：`AGENTS.md`、`Docs/AI`
- 任务包根：`.trae/tasks`
- 权威门禁：`.trae/scripts/task-state.ps1`、`.trae/scripts/task-guard.ps1`
- 规范 Skill 根：`E:/UEGameDevelopment/skills`

## 路由规则

本 skill 不包含领域知识（UE/Web）。领域路由由规范 Skill（`ue-project-router`、`web-fullstack` 等）负责。

### Hermes Profile → 工作流角色映射

| Hermes Profile | 工作流角色 | 规范 Skill |
|---------------|-----------|-----------|
| `jinli-planner` | Plan + Review/Verify 协调 | `金璃小天才` |
| `jinli-implementer` | 单工作包实现 | `金璃好帮手` |
| `jinli-verifier` | 只读验证 | `code-quality-reviewer` |

### 工具映射

| Hermes 概念 | 工作流对应 |
|------------|----------|
| Profile | 角色身份 + `.env` + `SOUL.md` |
| Skill Bundle | 角色特定 Skill 组合（不复制内容） |
| MCP Server | `jinli-workflow` MCP（包装共享脚本） |
| Plugin (guard) | `jinli-workflow-guard`（纵深防御） |
| Subagent | 工作包 Worker（独立上下文） |

## 输出要求

- 默认使用简体中文回复
- 仅代码、专有名词、文件路径保留英文
- 技术准确性优先于语言风格

## 禁止事项

- 不复制 `金璃小天才`/`金璃好帮手` 的领域内容
- 不绕过 `task-state.ps1`/`task-guard.ps1` 做权限判断
- 不创建独立的任务状态存储
