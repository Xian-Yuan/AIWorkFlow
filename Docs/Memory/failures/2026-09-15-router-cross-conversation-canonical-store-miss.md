---
id: memory-router-cross-conversation-canonical-store-miss-2026-09-15
type: failure_memory
phase: plan
project_type: other
module: workspace-router
tags:
  - phase:plan
  - mod:router
  - dom:ai
  - pat:context-rot
  - pat:boundary
  - sys:codex
severity: medium
write_trigger: regression_fail
retrieval_scope:
  - router
  - implement
token_budget: small
mem0_sync_status: not_synced
mem0_memory_id: null
memory_version: v1
---

# 跨对话工作区未先定位 canonical store，导致重复搜索与时间浪费

## Symptom
用户要求把本轮失败/失误沉淀到“之前在其他对话建立的工作流失败案例”中。执行时先在当前 PixelLighting2D 仓库和 Library 内按“失败案例 / 工作流失败案例 / 复盘”等字面名称反复搜索，并一度准备在当前项目内寻找或建立对应文档；直到用户补充“我在其他对话中建立的”，才把检索范围提升到跨仓库，最终定位到 `Xian-Yuan/AIWorkFlow` 的 `Docs/Memory/failures/` canonical store。

## Root Cause
把“当前对话/当前仓库”当成默认作用域，没有在第一次本地查找无结果后先解析引用对象的持久化位置；同时过度依赖文件名字面匹配，而不是先识别用户已有的 workflow/memory 基础设施。

## Bad Pattern
- 用户说“之前 / 其他对话 / 工作区 / 仓库里有”时，仍只在当前仓库做多轮同义词搜索
- 找不到原库就准备在当前项目新建第二份经验库
- 先做大范围递归扫描，再确认 canonical repository / canonical path
- 把聊天上下文当成唯一定位入口，而不是把持久化仓库视为 source of truth

## Correct Rule
当用户明确引用“其他对话中已经建立”的工作区、知识库、失败库或规范库时：第一次当前仓库查找未命中后，必须立即切换为“定位 canonical store”任务，优先确认 repository + canonical path + existing template/index，再读取或写入内容。未确认 canonical store 前禁止新建同用途的替代库。

## Retrieval Hint
适用于 router/implement 阶段处理“以前建过”“另一个对话里”“工作区/仓库里有”“继续更新原来的”这类跨会话引用，尤其是需要持久化写回的任务。

## Verification
写入前必须能明确回答并核验：
1. canonical repository 是什么；
2. canonical path 是什么；
3. 现有模板/索引是否存在；
4. 本次是否会制造第二份同用途 source of truth。
若当前仓库首次搜索未命中且用户已提示跨对话来源，应停止重复同义词扫描并提升检索作用域。
