---
id: memory-router-save-system-missing-2026-05-31
type: failure_memory
phase: plan
project_type: ue5
module: router
tags:
  - phase:plan
  - mod:router
  - dom:ue5
  - dom:save
  - pat:implicit-requirement
  - pat:under-engineering
  - sys:save-game
severity: high
write_trigger: verify_fail
retrieval_scope:
  - router
  - implement
token_budget: small
mem0_sync_status: not_synced
mem0_memory_id: null
memory_version: v1
---

# 路由阶段遗漏保存系统前置依赖

## Symptom
用户提出“退出时提醒是否保存”，agent 直接实现弹窗，没有先确认保存系统是否存在。

## Root Cause
把表层 UI 需求当成独立需求，没有反向推导 SaveGame、dirty state 和退出流程依赖。

## Bad Pattern
- 看到退出弹窗需求就直接做 UI
- 没有先追问保存系统
- 没有在 Plan 阶段识别隐式依赖

## Correct Rule
当需求涉及保存、退出确认、继续游戏或加载状态时，先确认保存系统是否存在，再决定是否实现 UI 提醒。

## Retrieval Hint
适用于 router 和 implement 阶段对 save/load/exit 类需求的预提醒。

## Verification
routing.md 或 analysis.md 必须明确保存系统依赖，或明确记录“当前无保存系统，需要用户确认”。
