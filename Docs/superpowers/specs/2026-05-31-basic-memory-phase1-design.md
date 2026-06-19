# Basic Memory Phase 1 Design

日期：2026-05-31
项目：`g:\UEGameDevelopment`
状态：已确认，待用户审阅

## 1. 目标

为当前工作区建立 `Basic Memory` 第一阶段方案，用最小侵入方式为 `.trae` 工作流补一层可审计、可检索、可逐步扩展的失败经验记忆系统，并为第二阶段接入 `Mem0` 预留结构化接口。

第一阶段要解决的问题不是“让 agent 全自动自我进化”，而是三个更具体的问题：

1. 当 `Review`、`Verify` 或 workflow regression 失败后，能把高价值失败经验稳定沉淀下来
2. 在 `Router` 和 `Implement` 阶段，能按需检索少量最相关的失败经验，降低重复犯错概率
3. 在不显著增加 token 消耗和工作流复杂度的前提下，让失败经验成为长期项目知识，而不是散落在会话历史里

## 2. 范围

本次范围内：

- 新增独立的 `Docs/Memory/` 目录作为第一阶段记忆层
- 设计正式 failure memory、candidate memory、模板、索引文件结构
- 规定失败后写入的准入规则
- 规定 `Router + Implement` 两阶段的检索规则与 token 预算
- 规定 `Review FAIL`、`Verify FAIL`、workflow regression fail 三类写入入口
- 为后续接入 `Mem0` 预留 frontmatter 字段和同步边界

本次范围外：

- 不直接安装或接入 `Basic Memory` 工具本身
- 不接入 `Mem0`
- 不做自动 embedding、自动 rerank、自动向量检索
- 不让 implementer 在实现过程中随手写 memory
- 不把 memory 系统变成新的黑盒真相源

## 3. 问题陈述

当前工作区已经具备：

- `Docs/AI` 真相源
- `.trae/tasks` 状态机
- `task-state.ps1` / `task-guard.ps1`
- `can-edit` 编辑前硬门禁
- `DeepSeek4Pro` profile
- workflow regression harness

但这些机制主要解决的是“当前任务怎么走流程”，还没有专门解决“过去失败经验如何跨任务复用”的问题。

这导致三个具体缺口：

- 同类失败会重复发生，但教训只留在会话里，不会稳定沉淀
- `Router` 分析需求时，无法系统性读取过去高风险失败经验
- `Implement` 动手前，无法低成本注入“别再这样写”的提醒

因此需要一个轻量、透明、文件优先的第一阶段记忆层。

## 4. 设计原则

- **文件真相源优先**：第一阶段的最终真相源是仓库里的文件，不是外部 memory service
- **失败驱动写入**：只在失败后写入，不记录普通成功经验
- **双阶段检索**：在 `Router` 与 `Implement` 两个关键时点按需检索
- **低 token 预算**：每次只注入极少量高价值记忆，不允许全量拼接
- **候选转正**：失败结果先形成 candidate，再转正为正式 memory
- **未来兼容**：frontmatter 与目录结构为第二阶段接 `Mem0` 预留空间
- **人工可审计**：所有 memory 必须能被人直接阅读、编辑、删除

## 5. 推荐方案概览

采用“独立文件目录 + 候选转正 + 双阶段检索”的方案。

### 5.1 为什么先做 Basic Memory Phase 1

相较于直接接入 `Mem0` 或更重的 agent memory platform，第一阶段先做文件化记忆层有三个优点：

- 与当前 `Docs/AI`、`.trae`、regression harness 思路一致
- 引入成本和 token 成本最低
- 失败经验可被人直接审计，不会形成“模型自己记住了什么但人看不到”的黑盒

### 5.2 为什么第二阶段再接 Mem0

第二阶段的 `Mem0` 应作为自动检索和结构化提炼层，而不是新的真相源。

也就是说：

- 第一阶段：文件是记忆真相源
- 第二阶段：`Mem0` 是检索增强层

这样既能保留透明度，又能逐步提高自动化水平。

## 6. 目录结构设计

建议新增：

```text
Docs/Memory/
  README.md
  failures/
    YYYY-MM-DD-<domain>-<topic>-memory.md
  candidates/
    YYYY-MM-DD-<domain>-<topic>-candidate.md
  indexes/
    memory-index.md
  templates/
    failure-memory-template.md
    memory-candidate-template.md
```

各目录职责如下：

- `README.md`
  - 描述 Basic Memory 第一阶段的目标、写入规则、检索规则、禁止事项
- `failures/`
  - 正式 failure memories
  - 只有满足准入门槛的高价值失败经验才进入该目录
- `candidates/`
  - 失败事件归纳后的中间产物
  - 用于从失败结果过渡到正式 memory
- `indexes/`
  - 存放轻量索引文件
  - 给 `Router` 和 `Implement` 低成本定位使用
- `templates/`
  - 固定写作模板，避免不同 memory 文件结构漂移

## 7. 正式 Failure Memory 结构

正式 memory 采用 `Markdown + frontmatter`。

建议示例：

```md
---
id: memory-router-save-system-missing-2026-06-01
type: failure_memory
phase: plan
project_type: ue5
module: save-system
tags:
  - router
  - implicit-requirement
  - save
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
用户提出“退出时提醒是否保存”，agent 直接实现弹窗，没有先追问保存系统是否已存在。

## Root Cause
把表层 UI 需求当成独立需求，没有反推依赖链，也没有识别隐式前提。

## Bad Pattern
- 看到按钮/弹窗需求就直接进入 UI 实现
- 没有检查是否牵动 SaveGame / dirty state / exit flow
- 没有在 Plan 阶段 AskUserQuestion

## Correct Rule
当需求涉及“保存”“退出确认”“继续游戏”“加载进度”等词时，先检查保存系统是否存在、状态是否可恢复、是否需要用户确认缺失前提。

## Retrieval Hint
适用于 Router 分析“设置/退出/继续游戏/加载/保存”相关需求时优先检索。

## Verification
只有当 routing.md / analysis.md 明确写出保存系统依赖或明确说明“当前无保存系统，需要用户确认”时，视为已避免复发。
```

设计要求：

- frontmatter 只存真正用于筛选和未来同步的字段
- 正文只存高密度失败经验，不存整段对话、不存长日志
- 每条 memory 必须能直接回答：
  - 这次怎么错的
  - 为什么错
  - 以后怎么避免
  - 如何验证没有再犯

## 8. Candidate Memory 结构

Candidate 是失败结果进入正式 memory 前的过渡层。

建议示例：

```md
---
id: candidate-router-save-system-missing-2026-06-01
source: verify_fail
status: candidate
phase: plan
project_type: ue5
module: router
severity: high
tags:
  - router
  - save
  - implicit-requirement
---

# Candidate: 路由阶段遗漏保存系统前置依赖

## Failure Event
简述失败发生的任务、阶段与影响。

## Evidence
- review report
- verify result
- regression result
- user correction

## Draft Root Cause
初步根因归纳。

## Draft Rule
拟提炼的规则。

## Promotion Check
- [ ] 可复现或已被明确观察
- [ ] 可提炼成通用规则
- [ ] 有验证标准
- [ ] 值得在 Router 或 Implement 检索
```

Candidate 的目的不是长期存档，而是让失败经验先被收集、再被筛选。

## 9. 写入准入规则

第一阶段严格采用“只在失败后写入”。

### 9.1 允许写入的触发源

只允许三个入口产生 candidate：

- `Review FAIL`
- `Verify FAIL`
- workflow regression fail（`S01` 至 `S05`）

### 9.2 不允许写入的内容

以下内容第一阶段不写入：

- 普通成功经验
- 一次性偶发拼写错误
- 无法泛化的局部实现细节
- 纯业务数据
- 未形成稳定规则的临时偏好

### 9.3 转正门槛

Candidate 只有满足以下条件才转正为正式 memory：

- 失败可复现或已被明确观察
- 根因可归纳
- 可提炼为通用规则
- 有明确验证标准

如果不满足以上条件，则 candidate 保留或丢弃，不进入 `failures/`

## 10. Review / Verify / Regression 的挂接

### 10.1 Review FAIL

`code-quality-reviewer` 在输出 FAIL 时，允许附带一个 `memory candidate` 提议块。

推荐结构：

```text
MEMORY_CANDIDATE: yes
MEMORY_TYPE: failure_memory
MEMORY_REASON: 该问题具有复用价值，未来在同类任务中可能重复出现

MEMORY_SUMMARY
- Symptom: ...
- Root Cause: ...
- Bad Pattern: ...
- Correct Rule: ...
- Verification: ...
```

### 10.2 Verify FAIL

以下 Verify 失败优先考虑写入：

- 测试通过但实际没修好
- 没有可见证据
- 编译/运行路径遗漏
- 路由正确但资产/配置/入口接线错误
- 真实需求链仍漏掉前提

### 10.3 Regression FAIL

workflow regression harness 失败时：

- `S01-S04` 失败 -> 生成 `workflow_failure_memory` candidate
- `S05` fail-closed 失效 -> 视为高优先级 workflow memory

regression 结果文件本身是证据，不直接充当长期记忆正文。

## 11. 检索规则

第一阶段只在两个阶段检索：

- `Router`
- `Implement`

### 11.1 Router 检索

触发时机：

- 新需求进入 `Plan`
- 项目类型判断后，依赖链推导前

目标：

- 提醒过去最容易遗漏的依赖、漏问点、高风险前提、假阳性验证风险

过滤条件建议：

- `retrieval_scope` 包含 `router`
- `phase = plan`
- `project_type` 匹配当前任务
- `module` / `tags` 与当前需求关键词相交

返回数量：

- 默认 `top 2`
- 高风险任务最多 `top 3`

### 11.2 Implement 检索

触发时机：

- `task-state.ps1 can-edit <task-name>` 通过后
- 第一次编辑前

目标：

- 提醒该模块过去最常见的坏模式、正确规则、验证点

过滤条件建议：

- `retrieval_scope` 包含 `implement`
- `severity >= medium`
- `module` / `tags` 匹配当前任务

返回数量：

- 默认 `top 1`
- 高风险实现最多 `top 2`

## 12. Token 预算

第一阶段严格控制注入量。

### Router 预算

- 最多 `2-3` 条 memory
- 总结块不超过约 `200-300` 中文字

### Implement 预算

- 最多 `1-2` 条 memory
- 总结块不超过约 `120-180` 中文字

### 注入规则

- 不注入完整原文
- 不注入原始日志
- 不注入整段对话
- 单条摘要最多 3 行
- 如果相关度不足，返回空而不是凑满

## 13. 索引结构

`Docs/Memory/indexes/memory-index.md` 第一阶段保持轻量。

建议格式：

```md
# Memory Index

| ID | Title | Phase | Module | Severity | Scope | Tags | File |
|---|---|---|---|---|---|---|---|
| memory-router-save-system-missing-2026-06-01 | 路由阶段遗漏保存系统前置依赖 | plan | router | high | router,implement | router,save,implicit-requirement | ./../failures/2026-06-01-router-save-system-missing-memory.md |
```

该索引只负责：

- 快速定位
- 低成本筛选
- 给未来工具接入一个稳定入口

该索引不负责：

- 存长摘要
- 存完整案例
- 存原始证据

## 14. 第二阶段 Mem0 预留位

第一阶段不接入 `Mem0`，但为第二阶段预留这些字段：

```yaml
mem0_sync_status: not_synced
mem0_memory_id: null
memory_version: v1
retrieval_scope:
  - router
  - implement
```

第二阶段推荐边界：

- `Docs/Memory/failures/*.md` 继续作为人类可读真相源
- `Mem0` 只同步高价值结构化摘要
- `Mem0` 用于检索增强，而不是替代文件真相源

## 15. 成功标准

第一阶段完成后，应满足：

1. 有独立 `Docs/Memory/` 目录
2. 有 failure memory / candidate / index / template 四类文件结构
3. 失败后有明确 candidate 写入入口
4. `Router + Implement` 有明确检索时机和 token 预算
5. memory 可以被人直接阅读和维护
6. 第二阶段接 `Mem0` 时不需要推翻第一阶段目录结构

## 16. 风险点

- 如果 candidate 门槛过低，memory 库会迅速变脏
- 如果 `Router` 和 `Implement` 检索量不受控，会增加 token 并污染 prompt
- 如果让 implementer 直接写正式 memory，容易产生自我美化和低质量总结
- 如果将来 `Mem0` 接入后反客为主，可能破坏“仓库是真相源”的原则

## 17. 缺失信息与默认假设

当前默认假设如下：

- 第一阶段只处理 failure memory，不处理成功经验
- 检索阶段为 `Router + Implement`
- 存储目录为 `Docs/Memory/`
- 索引文件维持轻量 Markdown，不做自动图数据库
- 第二阶段 `Mem0` 只做检索增强层

若后续要扩展到：

- 自动写入工具
- 自动 embedding / rerank
- `Mem0` 同步服务
- 成功经验或偏好记忆

应作为下一阶段独立设计。

## 18. 实现顺序建议

1. 先创建 `Docs/Memory/` 目录和模板
2. 再创建索引与 README
3. 再把 candidate -> 正式 memory 的流程接到 `Review / Verify / regression` 文档里
4. 最后再把 `Router + Implement` 检索规则写入工作流文档

这样可以先固定目录和数据结构，再把工作流接入点挂上，避免先改流程后补存储结构导致漂移。
