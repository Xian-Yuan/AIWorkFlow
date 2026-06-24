# T6 — 小璃"记住"流程 + 记忆 Gate（任务登记）

> **任务**：T6-memory-gate
> **执行者**：金璃好帮手（M3 subagent）
> **状态**：实施中
> **日期**：2026-06-23

## 任务入口

- **执行包**：`Project/Jinli/docs/task-packages/T6-execution-package.md`（156 行完整 spec）
- **工作目录**：`Project/Jinli/services/memory/keeper/`（T4 memory/ 子目录）
- **状态文件**：`Project/Jinli/services/memory/keeper/.task-state`

## 前置依赖

- T1-apply-task ✅
- T2-skill-scheduler ✅（routing）
- T3-nervous-event-bus ✅（memory.write.requested）
- T4-memory-system ✅（remember/strengthen/invalidate API）

## 关键交付

Worker+Lead 二段记忆流程 + 触发关键词检测 + State Machine Memory Gate（patch 到 task-state.ps1）。

## 实施阶段

按 task-package §D：Scaffold → Implement → Test → Report。