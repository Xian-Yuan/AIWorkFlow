# Routing: Hermes Desktop Agent Capability

## Entry Analysis

**用户输入**: "按照当前的ai工作流，先设计方案，出任务包" — 延续之前的桌面操控能力讨论

**项目**: UEGameDevelopment (非 UE5 游戏代码，是工作流基础设施)
**类型**: other (AI 工作流工具链)
**阶段**: Plan → 需要生成完整任务包

## Classification

- 变更类型: 新系统 (桌面操控能力层)
- change_profile: deep
- 理由: 新能力层、涉及多个 MCP Server 集成、架构决策、安全边界

## Prior Research

已完成研究，结果在 `Docs/AI/research/2026-06-21-Hermes-Desktop-Agent-Capability-Research.md`：
- GitHub 项目搜索：17+ 仓库验证
- MCP 生态调查：DesktopCommanderMCP、agent-desktop、unreal-mcp
- 学术论文：UFO 系列 (arXiv:2402.03939, 2504.14603, 2511.11332)
- 技术路线对比：Accessibility Tree vs 截图+视觉 vs 混合方案

## Key Decisions (Pre-Plan)

1. **三层混合架构**: pywinauto(UIA) → OCR+截图 → 视觉LLM
2. **优先集成现有项目**: agent-desktop + DesktopCommanderMCP + unreal-mcp
3. **最小自建**: 只开发 Hermes Profile 配置 + Skill + 集成胶水层
4. **不修改 Hermes 核心代码**: 通过 MCP/Skill/Plugin 扩展

## Architecture Decision

选择 **集成优先** 而非 **自建优先**：
- agent-desktop (Rust, 870★) 已提供 a11y tree 桌面操控
- unreal-mcp (C++, 2000★) 已提供 UE5 Editor 操控
- DesktopCommanderMCP (TS, 6188★) 已提供终端+文件控制
- 我们需要做的是：安装、配置、写 Skill、写安全策略、验证闭环

## Routed Skills

- `smart-requirements` — 需求确认
- `hermes-jinli-planner` — Plan 阶段角色
- `doc-governance` — 文档治理
- `writing-plans` — 方案撰写
