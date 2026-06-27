# T9 — 小璃主动对话 Phase 1 IDE 内（任务登记）

> **任务**：T9-proactive-p1
> **执行者**：金璃好帮手（M3 subagent）
> **状态**：实施中
> **日期**：2026-06-23

## 任务入口

- **执行包**：`Project/Jinli/docs/task-packages/T9-execution-package.md`（142 行完整 spec）
- **工作目录**：`Project/Jinli/services/proactive/p1/`
- **状态文件**：`Project/Jinli/services/proactive/p1/.task-state`

## 前置依赖

- T3-nervous-event-bus ✅（订阅 task.verify.failed / task.verify.passed / session.ended）
- T4-memory-system ✅（调用 recall(L2) 做记忆驱动再提起）

## 关键交付

Predicate 规则引擎 + APScheduler + 冷却管理 + 优先级队列 + IDE 内 dispatcher。
Phase 1 限定在 IDE 内（不接微信/QQ/Telegram，那是 T10）。

## 实施阶段

按 task-package §D：Scaffold → Implement → Test → Report。
