# Agent System — UEGameDevelopment

> 主入口：[AGENTS.md](../../AGENTS.md) · 路径：`Docs/AI/AGENTS-Agent-System.md`

## 双 Agent 架构

OpenCode 采用 **Plan + Implement 双 Agent 架构**。详见 `.opencode/rules/project_rules.md`。

| Agent | 类型 | 职责 | 项目范围 |
|-------|------|------|---------|
| `金璃小天才` | **primary** | 入口路由、需求澄清、设计文档检索、隐性需求推导、依赖链推导、成熟方案搜索、任务拆分、spec 生成 | 全局 |
| `金璃好帮手` | subagent | 按 spec 实现代码、编译验证、重复检测、对照 spec 自检。通过动态加载 skill 切换领域知识 | 全局 |

**设计原则**：不要让 agent 的数量超过问题本身需要的认知边界数。领域知识通过 skill 动态加载，不通过 agent 静态拆分。

Agent 定义文件：`.opencode/agents/<agent-name>.md`（OpenCode），`skills/<agent-name>/SKILL.md`（Codex）。

## 已归档 Agent（`.opencode/agents/_archived/`）

`ue-project-router`、`ue-lyra-gas-implementer`、`web-implementer`、`ue-ai-validator`、`code-quality-reviewer`、`character-designer`

## 已归档 Skill（`.trae/skills/_archived/`）

`character-designer`、`prompt-compressor`、`personal-branding`、`token-optimizer`、`rag-hallucination-guard`、`bmad-auto`、`planning-with-files`、`using-superpowers`

## 已合并 Skill

- `ue57-lyra-gas-ai-singleplayer` → `ue-lyra-gas-implementer`
- `lyra-gas-dev` → `ue-lyra-gas-implementer`

## 模型分工（DeepSeek 环境友好）

> **原则**：动态约束前置，动态约束追加，不修改 prompt 前缀。

- **模型分层（Pro + Flash）**：Plan 用 Pro，Implement 用 Flash，Review + Verify 合并为同一 Pro 会话。每阶段结束后用 `task-handoff.ps1 <task-name>` 自动生成交接模板。**AI 必须在每个阶段边界主动提醒用户切换模型**。详见 `Docs/AI/24-Pro-Flash-Model-Tiering.md` 中 AI 行为约束。
- **阶段边界 /clear**：Plan 确认后、Implement 完成后、Review 完成后、Verify 完成后 → 自然会话结束，使用 handover 模板（`Docs/AI/09-Agent-Handoff-Templates.md`）携带关键信息启动新会话。
- **subagent 隔离**：耗时研究型工作（搜索、分析、设计）→ 用 subagent 独立执行，只返回摘要不污染对话历史。
- **禁止中断工作**：不在关键文件实现中间 /clear，不在验证循环中 /clear。
- **文件分段读取**：大文件（500+ 行），用 offset/limit 分段读取，不一次性全部加载。
