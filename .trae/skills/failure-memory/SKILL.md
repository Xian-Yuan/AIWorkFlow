---
name: "failure-memory"
description: "跨会话失败经验记忆与检索。Review/Verify 失败时记录，Plan 阶段自动检索相关教训，只注入摘要不注入全文。"
---

# Failure Memory

## 定位

本 Skill 提供跨会话的失败经验记忆层。Codex 本身没有内置的失败记忆能力，本 Skill 填补这一空白。

核心原则：
- 写入：Review FAIL / Verify FAIL / workflow regression fail 时记录
- 检索：Plan 阶段自动查询，取 top 2 摘要注入
- 注入：只注入摘要（≤3 行/条），不注入全文
- 存储：本地 Markdown 文件，与 `Docs/Memory/` 格式兼容

## 何时调用

- Plan 阶段开始时：检索相关 failure memory
- Review 或 Verify 失败时：生成 memory candidate
- 用户说"记录这个教训"或"这个错误别再犯了"

## 写入规则

### 触发条件

| 触发事件 | 写入目标 | 自动/手动 |
|---------|---------|----------|
| Review FAIL | `Docs/Memory/candidates/` | 自动生成 candidate |
| Verify FAIL | `Docs/Memory/candidates/` | 自动生成 candidate |
| workflow regression fail | `Docs/Memory/candidates/` | 自动生成 candidate |
| 用户明确要求记录 | `Docs/Memory/candidates/` | 手动 |

### Candidate 格式

```markdown
---
id: memory-<topic>-<YYYY-MM-DD>
type: failure_memory
phase: <plan|implement|review|verify>
project_type: <ue5|web|other>
module: <router|implement|validator>
tags:
  - <tag1>
  - <tag2>
severity: <high|medium|low>
write_trigger: <review_fail|verify_fail|workflow_regression_fail>
retrieval_scope:
  - router
  - implement
token_budget: small
---

# <标题>

## Symptom
<观察到的失败现象，1-2 句>

## Root Cause
<根本原因，1-2 句>

## Bad Pattern
- <错误模式 1>
- <错误模式 2>

## Correct Rule
<正确的规则或做法，1-2 句>

## Retrieval Hint
<帮助检索的关键词或场景描述>

## Verification
<如何验证该规则已被遵守>
```

### Promotion Gate（转正门槛）

Candidate 必须满足以下全部条件才能进入 `Docs/Memory/failures/`：
- observed or reproducible failure（可观察或可复现的失败）
- reusable rule（可复用的规则）
- clear verification method（明确的验证方法）
- useful for `router` or `implement` retrieval（对路由或实现阶段有检索价值）

转正操作：将文件从 `candidates/` 移动到 `failures/`，更新 `Docs/Memory/indexes/memory-index.md`。

## 检索规则

### 检索时机

| 阶段 | 检索范围 | 数量限制 |
|------|---------|---------|
| Plan（Router） | `Docs/Memory/indexes/memory-index.md` → 匹配的 failures | top 2，高风险任务 top 3 |
| Implement | `Docs/Memory/indexes/memory-index.md` → 匹配的 failures | top 1，高风险任务 top 2 |
| Review/Verify | 不检索（独立验证，避免污染） | 0 |

### 检索方法

1. 读取 `Docs/Memory/indexes/memory-index.md`
2. 根据当前任务的 `project_type`、`module`、关键词匹配相关条目
3. 读取匹配的 failure memory 文件
4. 只提取 `Symptom` + `Correct Rule` + `Verification` 三段，组成摘要

### 摘要注入格式

```text
Relevant Failure Memories
1. <Symptom 一句话> -> <Correct Rule 一句话> -> <Verification 一句话>
2. <Symptom 一句话> -> <Correct Rule 一句话> -> <Verification 一句话>
```

禁止注入整篇 memory 原文。禁止注入 candidate（未转正的）。

## 与现有 Memory 层的集成

- 读取：`Docs/Memory/README.md`（Memory 层规则）
- 索引：`Docs/Memory/indexes/memory-index.md`（检索入口）
- 写入：`Docs/Memory/candidates/`（新 candidate）
- 转正：`Docs/Memory/failures/`（promoted memories）
- 模板：`Docs/Memory/templates/`（写入模板）

## 禁止事项

- 不把普通成功经验写入 Memory（Memory 只存失败教训）
- 不注入整篇 memory 原文到 prompt
- 不让实现 Agent 直接写最终 memory 文件（只能生成 candidate）
- 不把 candidate 同步到 Mem0（只有 promoted failures 可以）
