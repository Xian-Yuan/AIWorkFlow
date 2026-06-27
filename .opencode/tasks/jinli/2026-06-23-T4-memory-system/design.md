# T4 — 小璃记忆系统 4 层架构（任务登记）

> **任务**：T4-memory-system
> **执行者**：金璃好帮手（M3 subagent）
> **状态**：实施中
> **日期**：2026-06-23

## 任务入口

- **执行包**：`Project/Jinli/docs/task-packages/T4-execution-package.md`（537 行完整 spec）
- **记忆 spec 摘要**：`Project/Jinli/docs/task-packages/T4-memory-system-4layer-spec.md`
- **工作目录**：`Project/Jinli/services/memory/`（已存在空的 `tasks/` 子目录）
- **状态文件**：`Project/Jinli/services/memory/.task-state`
- **最终报告**：`Project/Jinli/services/memory/final-result.md`

## 前置依赖

- T3-nervous-event-bus ✅（已交付，参考 `services/nervous/`）

## 关键交付

4 层记忆：L0 工作记忆 / L1 情景记忆 / L2 语义记忆 / L3 程序记忆。
Compaction 三步流水线 + Ebbinghaus 衰减 + Subject-Aware 去重 + 统一检索 API + Obsidian 同步接口。

## 实施阶段

按 task-package §D：Scaffold → Implement → Test → Report。
