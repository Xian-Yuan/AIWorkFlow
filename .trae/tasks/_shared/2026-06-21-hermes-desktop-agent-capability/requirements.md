# Requirement Understanding: Hermes Desktop Agent Capability

## Desired Outcome

Hermes Agent 能够像马维斯一样操控爸爸电脑上的应用——看到屏幕、点击按钮、输入文字、切换窗口。爸爸只需用自然语言说"帮我打开 UE5 编译一下"或"在 VS Code 里找到那个函数改一下"，Hermes 就能执行。

## Underlying Problem

Hermes 的架构（Profile/MCP/Cron/Gateway/Skill/Memory）是所有 Agent 框架里最完整的，但缺少 Windows 桌面 GUI 操控能力。当前 `computer_use` toolset 仅支持 macOS，Windows 上无法操控桌面应用。

## Intended User and Context

- Primary decision maker: Ba Ba，希望用自然语言指挥 Hermes 完成桌面操作
- Primary planner/implementer: 金璃好帮手（本 Agent）
- Downstream executors: Hermes Agent 自身（通过 MCP 工具调用）

## End-to-End Experience

1. Ba Ba 对 Hermes 说"帮我打开 UE5 项目编译一下"
2. Hermes 通过 MCP 调用桌面操控工具，激活 UE5 Editor 窗口
3. Hermes 通过 unreal-mcp 触发编译
4. 编译结果反馈给 Ba Ba
5. 如果失败，Hermes 能查看错误日志并报告

## Confirmed Decisions

- 集成优先，不自建底层：agent-desktop 已提供 a11y tree 操控，unreal-mcp 已提供 UE5 操控，DesktopCommanderMCP 已提供终端+文件控制
- 三层混合架构：pywinauto(UIA) → OCR+截图 → 视觉LLM（优先级递减）
- 只做集成胶水层 + Skill + 安全策略 + 验证，不修改 Hermes 核心代码
- Phase 1 先让基础能力跑通：agent-desktop + DesktopCommanderMCP + unreal-mcp
- 安全机制：危险操作需确认，操作日志记录，窗口白名单

## Implicit Requirements

| Requirement | Status | Reason |
|---|---|---|
| 必须在 Windows 上工作 | Confirmed | 爸爸的开发环境是 Windows |
| 不能破坏现有工作流 | Confirmed | 现有 task-state/task-guard 必须继续工作 |
| MCP Server 安装必须可逆 | Confirmed | 可以随时卸载不影响系统 |
| 操作必须有日志和确认 | Confirmed | 桌面操控涉及安全风险 |
| 必须支持无头/有头两种模式 | Confirmed | 有些操作可以纯 API，有些需要看到屏幕 |

## Boundaries and Non-Goals

- 不修改 Hermes Agent 核心代码
- 不开发新的 GUI 框架或 OCR 引擎
- 不在本次任务中配置 Gateway/Telegram（后续任务）
- 不处理 Linux/macOS 桌面操控（只关注 Windows）
- 不做自动化录制/回放（OpenAdapt 路线，后续考虑）

## Success Experience

Ba Ba 感觉 Hermes 不再只是一个"只会写文件和跑命令的终端助手"，而是能真正"看到"和"操控"电脑上运行的应用，像一个坐在电脑前的助手。

## Open Questions

None.

## Teach-Back Summary

本次任务的核心是：把已有的成熟桌面操控项目（agent-desktop、DesktopCommanderMCP、unreal-mcp）集成到 Hermes Agent 中，通过 MCP Server 配置 + Skill 编写 + 安全策略 + 验证闭环，让 Hermes 获得操控 Windows 桌面应用的能力。不做底层开发，只做集成。

## User Confirmation Evidence

- Ba Ba 说"按照当前的ai工作流，先设计方案，出任务包"
- Ba Ba 说"小璃，自己设计完任务包自己接了完成，然后自己测试审核"
- 前期需求讨论中 Ba Ba 确认核心目标是"操控电脑上的应用，就像马维斯一样"
