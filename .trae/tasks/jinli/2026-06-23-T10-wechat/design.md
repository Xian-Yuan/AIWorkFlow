# T10 — 小璃主动对话 Phase 2 微信接入（任务登记）

> **任务**：T10-wechat
> **执行者**：金璃好帮手（M3 subagent）
> **状态**：实施中
> **日期**：2026-06-23

## 任务入口

- **执行包**：`Project/Jinli/docs/task-packages/T10-execution-package.md`（111 行完整 spec）
- **工作目录**：`Project/Jinli/services/proactive/p2_wechat/`
- **状态文件**：`Project/Jinli/services/proactive/p2_wechat/.task-state`

## 前置依赖

- T9-proactive-p1 ✅（订阅 proactive.message.requested topic）

## 关键交付

LangBot SDK 接入 + WeChatDispatcher + RateLimiter + DNDGuard + 凭证模板（不入仓库）。

## 实施阶段

按 task-package §D：Scaffold → Implement → Test → Report。