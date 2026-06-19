# Workflow Tooling Inventory

> **Date**: 2026-06-17 | **Status**: Active | **Source**: Docs/AI/34-AI-Workflow-Current-Audit.md

## Purpose

将所有脚本按状态分类，防止模型误用已禁用/实验性脚本。

## Active Authoritative

这些脚本是当前工作流的主链路，必须可用。

| Script | Location | Purpose |
|--------|----------|---------|
| task-state.ps1 | `.trae/scripts/` | 任务状态管理 (init/get/set/check/transition/can-edit) |
| task-guard.ps1 | `.trae/scripts/` | 阶段门禁 (plan/implement/verify) + 成熟方案检查 |
| doc-guard.ps1 | `.trae/scripts/` | 文档治理门禁 |
| spec-living.ps1 | `.trae/scripts/` | Living Spec 生命周期管理 |
| memory-retrieve.ps1 | `.trae/scripts/` | 失败记忆检索 |
| verify.ps1 | `.trae/scripts/` | 编译/运行时验证 |
| codegraph.ps1 | `.trae/scripts/` | 代码知识图谱 |
| test-workflow-regression.ps1 | `.trae/scripts/` | 工作流回归测试 |
| test-doc-guard.ps1 | `.trae/scripts/` | 文档治理测试 |
| rule-enforcer.ps1 | `engine/` | 规则执行引擎 |
| rule-registry.json | `engine/` | 规则注册表 |

## Refactor Candidate

这些脚本是目标架构的一部分，但尚未完成迁移。

| Script | Location | Purpose | Status |
|--------|----------|---------|--------|
| task-state.ps1 | `engine/` | 统一任务状态管理 | 副本，待合并 |
| task-detector.ps1 | `engine/` | 任务类型检测 | 副本，待合并 |
| skill-loader.ps1 | `engine/` | Skill 自动加载 | 副本，待合并 |
| subagent-dispatcher.ps1 | `engine/` | 子 Agent 分发 | 副本，待合并 |
| spec-living.ps1 | `engine/` | Living Spec 管理 | 副本 |
| memory-retrieve.ps1 | `engine/` | 记忆检索 | 副本 |
| verify.ps1 | `engine/` | 验证 | 副本 |
| codegraph.ps1 | `engine/` | 代码图谱 | 副本 |
| doc-guard.ps1 | `engine/` | 文档治理 | 副本 |
| migrate-docs.ps1 | `engine/` | 文档迁移 | 副本 |
| update-docs-tree.ps1 | `engine/` | 文档树更新 | 副本 |
| task-metrics.ps1 | `engine/` | 任务指标 | 副本 |

## Disabled

这些脚本当前不可用，不应被任何 Agent 调用。

| Script | Location | Reason |
|--------|----------|--------|
| phase-machine.ps1 | `engine/` | 解析错误 — regex escaping + switch case nesting |
| phase-machine.ps1 | `.agents/engine/` | 同上 |

## Experimental (Non-Blocking)

这些脚本是实验性的，失败不影响主链路。

| Script | Location | Note |
|--------|----------|------|
| abtop.ps1 | `engine/_experimental/` | 实验工具 |
| bolt-diy.ps1 | `engine/_experimental/` | 实验工具 |
| ollama-probe.ps1 | `engine/_experimental/` | 实验工具 |
| repomix.ps1 | `engine/_experimental/` | 实验工具 |
| web-preview-guard.ps1 | `engine/_experimental/` | 实验工具 |
| resolve-task.ps1 | `engine/_experimental/` | 实验工具 |
| sync-codex-merge.py | `engine/_experimental/` | Codex 同步实验 |
| sync-codex-state.ps1 | `engine/_experimental/` | Codex 同步实验 |
| mem0-healthcheck.ps1 | `engine/_experimental/` | Mem0 实验 (未使用) |
| mem0-sync.ps1 | `engine/_experimental/` | Mem0 实验 (未使用) |
| test-doc-guard.ps1 | `engine/_experimental/` | 实验测试 — fixture 不同步 |
| test-workflow-regression.ps1 | `engine/_experimental/` | 实验回归 — 落后于主回归 |

## Compatibility

这些脚本保留用于向后兼容，但不应作为主要入口。

| Script | Location | Note |
|--------|----------|------|
| spec-tracker.ps1 | `.trae/scripts/` | 已废弃，被 spec-living.ps1 取代 |
| task-env.ps1 | `.trae/scripts/` | 已被 skill-loader.ps1 取代 |
| task-handoff.ps1 | `.trae/scripts/` | 已被 subagent-dispatcher.ps1 取代 |
| task-state.ps1 | `.opencode/scripts/` | OpenCode 简化版，can-edit 逻辑弱于主链路 |

## Deprecated

这些脚本/文件已不再使用，保留仅供历史参考。

| Item | Location | Note |
|------|----------|------|
| plan-agent.md | `.opencode/agents/` | 已合并到 ue-project-router |
| task-completion-validator.md | `.opencode/agents/` | 已合并到 code-quality-reviewer |
| agents/*.yaml | `agents/` (root) | ruflo 通用模板，无 UE5 知识 |

## Promotion Criteria

脚本从 experimental → refactor candidate → active authoritative 的升级条件：

1. Parser pass (PowerShell syntax valid)
2. Regression pass (`.trae/scripts/test-workflow-regression.ps1` 通过)
3. Manifest update (在本文档中更新状态)
4. Rule registry update (如果是 mechanical 规则，更新 `engine/rule-registry.json`)
