# Spec: Jinli Soul Core MCP Plugin

> **完整 spec 见设计文档**: `Project/Jinli/Docs/02-Design/General/soul-core-phase2-mcp-plugin-spec.md` (676 行)

## Summary
将 Soul Core 从 SKILL.md 指令级接入升级为 MCP Plugin 原生工具集。11 个 MCP 工具包装 soul-core.ps1 CLI，Agent 通过工具调用而非 PowerShell 命令操作灵魂引擎。

## Acceptance Criteria (from spec §8)
AC01-AC12: 功能验收（每个工具正确返回结构化 JSON）
NF01-NF05: 非功能验收（性能、并发、schema 验证、审查规则）

## Non-Goals
- 不修改 soul-core.ps1 引擎
- 不修改数据文件结构
- 不修改 evolve-self.ps1
