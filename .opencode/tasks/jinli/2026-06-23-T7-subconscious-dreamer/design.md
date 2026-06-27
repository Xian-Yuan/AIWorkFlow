# T7 — 小璃潜意识系统梦境（任务登记）

> **任务**：T7-subconscious-dreamer
> **执行者**：金璃好帮手（M3 subagent）
> **状态**：实施中
> **日期**：2026-06-23

## 任务入口

- **执行包**：`Project/Jinli/docs/task-packages/T7-execution-package.md`（142 行完整 spec）
- **工作目录**：`Project/Jinli/services/memory/dreamer/`（T4 memory/ 子目录）
- **状态文件**：`Project/Jinli/services/memory/dreamer/.task-state`

## 前置依赖

- T3-nervous-event-bus ✅（已交付，可订阅 session.ended / compaction.triggered）
- T4-memory-system ✅（已交付，recall/remember/dedup/get_timeline/invalidate API 可调）

## 关键交付

三触发机制 + 梦境沙箱 + 巩固流水线 + 梦日记 + 反射周期。

## 实施阶段

按 task-package §D：Scaffold → Implement → Test → Report。
