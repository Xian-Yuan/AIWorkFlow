# Tasks: Hermes Desktop Agent Capability

## Dependency Graph

```text
T1 环境准备
  -> T2 agent-desktop 集成
  -> T3 DesktopCommanderMCP 集成
  -> T4 unreal-mcp 集成
  -> T5 Skill + 安全策略
  -> T6 端到端验证
  -> T7 文档更新
```

## T1: 环境准备

- [ ] T1.1 检查 Node.js/npm 版本，确保 >= 18
- [ ] T1.2 检查 Python 版本，确保 >= 3.11
- [ ] T1.3 检查 Rust/cargo 是否可用（agent-desktop 可选）
- [ ] T1.4 备份当前 Hermes Profile 配置 (config.yaml, mcp.json, .env)

## T2: agent-desktop 集成

- [ ] T2.1 安装 agent-desktop: `npm install -g agent-desktop`
- [ ] T2.2 验证 agent-desktop CLI 可用: `agent-desktop --help`
- [ ] T2.3 在 Hermes Profile mcp.json 中添加 agent-desktop MCP Server 配置
- [ ] T2.4 测试 MCP 连接: `hermes mcp test agent-desktop`
- [ ] T2.5 验证工具列表: 确认 desktop_* 工具出现在 Hermes tools list

## T3: DesktopCommanderMCP 集成

- [ ] T3.1 安装 DesktopCommanderMCP: `npm install -g @wonderwhy-er/desktop-commander`
- [ ] T3.2 在 Hermes Profile mcp.json 中添加 DesktopCommanderMCP 配置
- [ ] T3.3 测试 MCP 连接: `hermes mcp test desktop-commander`
- [ ] T3.4 验证工具列表: 确认终端/文件工具可用

## T4: unreal-mcp 集成

- [ ] T4.1 克隆 unreal-mcp 仓库到本地
- [ ] T4.2 将 UE Plugin 复制到 RTS 项目的 Plugins 目录
- [ ] T4.3 安装 Python 依赖 (mcp SDK 等)
- [ ] T4.4 在 Hermes Profile mcp.json 中添加 unreal-mcp 配置
- [ ] T4.5 测试 MCP 连接（需 UE5 Editor 运行中）

## T5: Skill + 安全策略

- [ ] T5.1 编写 `windows-desktop-control` Skill (SKILL.md)
  - 操作决策逻辑（优先 a11y tree，降级截图）
  - 常用操作模板（窗口切换、截屏、点击、输入）
  - 错误恢复流程
- [ ] T5.2 编写安全策略文档
  - 窗口白名单
  - 危险操作确认规则
  - 操作日志格式
- [ ] T5.3 更新 Hermes Profile config.yaml 安全相关配置

## T6: 端到端验证

- [ ] T6.1 验证 agent-desktop: 列出窗口 + 截屏 + 窗口切换
- [ ] T6.2 验证 DesktopCommanderMCP: 执行终端命令 + 文件搜索
- [ ] T6.3 验证 unreal-mcp: 列出 Actor（需 UE5 运行）
- [ ] T6.4 验证多 MCP 协同: agent-desktop 截屏 + DesktopCommanderMCP 执行命令
- [ ] T6.5 验证安全策略: 危险操作触发确认
- [ ] T6.6 验证降级: MCP 断连时正确报告错误

## T7: 文档更新

- [ ] T7.1 更新 AGENTS.md 反映新 MCP Server 和 Skill
- [ ] T7.2 更新 Docs/AI/ 知识资源索引
- [ ] T7.3 编写 verification-report.md
