# T12 — 小璃人格情感扩展（任务登记）

> **任务**：T12-persona-emotion
> **执行者**：金璃好帮手（M3 subagent）
> **状态**：实施中
> **日期**：2026-06-23

## 任务入口

- **执行包**：`Project/Jinli/docs/task-packages/T12-execution-package.md`（143 行完整 spec）
- **工作目录**：`Project/Jinli/services/persona/`
- **状态文件**：`Project/Jinli/services/persona/.task-state`

## 前置依赖

- T4 spec ✅（remember() API 可调，情感状态可写入 L2）
- persona.json v1.0 存在但**只读**

## 关键交付

4 维情感向量（valence/arousal/dominance/sociability）+ 三轴关系积分（closeness/affection/trust）+ 重要日期提醒 + RationalityGuard 防止情感 override 工作流。

## 实施阶段

按 task-package §D：Scaffold → Implement → Test → Report。