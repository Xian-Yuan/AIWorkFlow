# T11 — 小璃主动对话 Phase 3 情感人格驱动（任务登记）

> **任务**：T11-emotion-driven
> **执行者**：金璃好帮手（M3 subagent）
> **状态**：实施中
> **日期**：2026-06-23

## 任务入口

- **执行包**：`Project/Jinli/docs/task-packages/T11-execution-package.md`（125 行完整 spec）
- **工作目录**：`Project/Jinli/services/proactive/p3_emotion/`
- **状态文件**：`Project/Jinli/services/proactive/p3_emotion/.task-state`

## 前置依赖

- T9-proactive-p1 ✅（订阅 proactive.message.sent）
- T10-wechat ✅（订阅 proactive.message.sent）
- T12-persona-emotion ✅（订阅 emotional.vec.updated）

## 关键交付

FrequencyTuner + PatternLearner + StyleAdapter — 让 T9/T10 频次随 T12 情感向量动态调整。

## 实施阶段

按 task-package §D：Scaffold → Implement → Test → Report。