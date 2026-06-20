---
id: candidate-workflow-mechanical-gate-gap-20260620
source: analysis_finding
status: candidate
phase: plan
project_type: other
module: workflow
severity: high
tags:
  - pat:mechanical-gate
  - mod:workflow
  - dom:ai
---

# Candidate: 本地工作流缺乏 Hook 级机械门禁强制执行

## Failure Event

在分析本地工作流与 Codex / OpenCode / Hermes 的三平台集成时发现：所有门禁（task-guard.ps1、task-state.ps1、doc-guard.ps1）都依赖 Agent「自觉调用」，没有机械层的强制执行。

## Evidence

- OpenCode 的 task-guard.ps1 在 Plan/Implement 阶段需要 Agent 主动执行 PowerShell 命令
- Codex 的 codex-project-router 要求「必须运行 can-edit」但无机械阻止直接编辑
- Hermes 的 MCP Server 包装了门禁但 Guard Plugin 仅做 pre_tool_call 检查，仍依赖 Profile 加载正确
- 对比 Claude Code 的 28 种 Hook 事件 + 5 种 Hook 类型，能在 PreToolUse / UserPromptSubmit 等生命周期关键点自动触发门禁
- 对比 Manus 的 Context Engineering 设计原则中「Mask 而非 Remove」——token logits masking 才是真正的机械约束

## Draft Root Cause

项目初始设计时选择了「脚本式门禁」（PowerShell gates），而非「平台级 Hook 式门禁」。在 Trae IDE 中天然支持门禁检查，但在 Codex / OpenCode / Hermes 上缺乏 Hook 层支撑，导致门禁变成了「建议遵守」而非「必须遵守」。

## Draft Rule

任何门禁设计至少需要两层保障：
1. **调用层（软门禁）** — 人/Agent 自觉执行门禁检查（当前实现）
2. **Hook 层（硬门禁）** — 平台生命周期事件自动触发门禁检查（缺失）

在平台不支持原生 Hook 时，至少应实现 PreToolUse 级别的工具调用拦截。

## Promotion Check
- [x] Observed or reproducible failure（架构分析层面的观察）
- [ ] Reusable rule（需要验证）
- [ ] Clear verification method（可以设计一个测试脚本检查 gate 是否被绕过）
- [x] Useful for Router or Implement retrieval（Plan 阶段检索到可避免重复犯错）
