# Spec: Hermes Desktop Agent Capability

## Overview

为 Hermes Agent 集成 Windows 桌面操控能力，通过安装和配置三个 MCP Server（agent-desktop、DesktopCommanderMCP、unreal-mcp），编写配套 Skill 和安全策略，使 Hermes 能操控 Windows 桌面应用和 UE5 Editor。

## GIVEN/WHEN/THEN Scenarios

### Scenario 1: 列出桌面窗口

- **GIVEN** Hermes Agent 正在运行，agent-desktop MCP 已配置
- **WHEN** 用户说"现在打开了哪些窗口"
- **THEN** Hermes 调用 `desktop_list_windows` 返回当前所有窗口标题和 PID

### Scenario 2: 激活并操控桌面应用

- **GIVEN** VS Code 窗口已打开
- **WHEN** 用户说"帮我切换到 VS Code"
- **THEN** Hermes 调用 `desktop_activate_window("Visual Studio Code")` 激活窗口

### Scenario 3: 截屏分析

- **GIVEN** 某个应用窗口已激活
- **WHEN** 用户说"看看现在屏幕上是什么"
- **THEN** Hermes 调用 `desktop_screenshot()` 获取截图，通过 Vision 分析内容

### Scenario 4: UE5 Editor 操控

- **GIVEN** UE5 Editor 正在运行，unreal-mcp 已连接
- **WHEN** 用户说"在场景里创建一个立方体"
- **THEN** Hermes 调用 unreal-mcp 的 actor 管理工具创建立方体

### Scenario 5: 终端命令执行

- **GIVEN** DesktopCommanderMCP 已配置
- **WHEN** 用户说"运行构建命令"
- **THEN** Hermes 调用 `execute_command` 执行构建，返回输出

### Scenario 6: 安全确认

- **GIVEN** 用户要求执行危险操作（如关闭应用、删除文件）
- **WHEN** Hermes 识别到操作涉及白名单外窗口或危险动作
- **THEN** Hermes 先向用户确认，收到确认后执行

### Scenario 7: MCP 连接失败降级

- **GIVEN** agent-desktop MCP 未启动或连接失败
- **WHEN** 用户请求桌面操控
- **THEN** Hermes 报告 MCP 连接失败，建议用户启动 MCP Server 或检查配置

### Scenario 8: 多 MCP 协同

- **GIVEN** agent-desktop + unreal-mcp 都已连接
- **WHEN** 用户说"打开 UE5 并创建一个新 Blueprint"
- **THEN** Hermes 先用 agent-desktop 激活 UE5 窗口，再用 unreal-mcp 创建 Blueprint

## Acceptance Criteria

- AC01: agent-desktop MCP 安装并配置到 Hermes，工具可调用
- AC02: DesktopCommanderMCP 安装并配置到 Hermes，工具可调用
- AC03: unreal-mcp 安装到 UE5 项目，Hermes 可通过 MCP 调用
- AC04: windows-desktop-control Skill 编写完成，包含操作决策逻辑和安全策略
- AC05: 三个 MCP Server 的连接测试全部通过
- AC06: 安全策略文档完成，包含窗口白名单和危险操作确认规则
- AC07: 集成验证：至少一个端到端场景（截屏+窗口切换+终端命令）跑通
- AC08: 文档更新：AGENTS.md / Docs/AI/ 反映新能力
