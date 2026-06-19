# DeepSeek4Pro Workflow Profile

## Goal

Make DeepSeek4Pro follow the workspace workflow mechanically instead of conversationally.

## Highest-Priority Rules

- Read phase and authorization from `.task.yaml`; never trust chat history alone.
- No confirmation -> no edit.
- No `can-edit` pass -> no write.
- No real skill/tool call -> no pretend execution.
- If blocked, only ask, read, search, or report the blocker.
- Do not skip `Plan -> Implement -> Review -> Verify`.

## Fixed Action Order

Use this exact order whenever implementation is requested:

1. Read state
2. Check phase
3. Run `task-state.ps1 can-edit <task-name>` if implementation is requested
4. Load the required skill
5. Read `routing.md`, `analysis.md`, `spec.md`, `tasks.md`
6. If the current phase allows memory retrieval, run `.trae/scripts/memory-retrieve.ps1` and inject summary-only failure memories
7. Only then edit

If any step fails, stop and report the blocker. Do not continue optimistically.

## Required Status Block

Emit this compact block before major task execution:

```text
PHASE: <plan|implement|review|verify>
AUTH: <blocked|allowed>
NEXT: <ask|search|read|edit|verify>
BLOCKER: <none|...>
```

## Blocked Output Contract

When authorization is blocked, use:

```text
STATUS: NEED_USER_CONFIRMATION
REASON: <missing precondition or failed gate>
NEXT_ACTION: AskUserQuestion
```

Blocked sessions may read files, search code, search docs, and ask clarifying questions. Blocked sessions may not edit files.

## Authorized Output Contract

When authorization is granted, use:

```text
STATUS: IMPLEMENT_AUTHORIZED
REASON: can-edit passed
NEXT_ACTION: load main skill and execute the next task
```

## Reasoning Mode Policy

- Use stronger reasoning for architecture, multi-file changes, root-cause analysis, and verification.
- Do not use heavy reasoning for tiny edits, format-only work, or obvious single-file fixes.
- Prefer short hard constraints over long explanatory prose.

## Model Routing Policy

> 详见 `Docs/AI/24-Pro-Flash-Model-Tiering.md`

本 Profile 适用于 **Pro 模型会话**（Plan / Review / Verify 阶段）。Implement 阶段应切换到 Flash 模型。

| 阶段 | 模型 | 本 Profile 适用 |
|------|------|----------------|
| Plan | Pro | 是 |
| Implement | Flash | 否（切换模型 + 新会话） |
| Review | Pro | 是 |
| Verify | Pro | 是 |

### 阶段边界操作

每个阶段完成后：
1. 输出对应 handover 模板（`Docs/AI/09-Agent-Handoff-Templates.md`）
2. `/clear` 或开新会话
3. 按阶段切换模型（Pro ↔ Flash）
4. 粘贴 handover 摘要到新会话

### Flash 会话提示

当检测到当前模型为 Flash 且阶段为 Implement 时：
- 严格按 tasks.md 执行，不自行决策架构变更
- 单文件编辑优先，批量操作合并
- 编译验证每完成一项任务后执行
- 遇到 3 次连续编译失败 → 切换回 Pro 做根因分析

## Tooling Policy

- Use registered tools only.
- Use real skill calls instead of describing a skill call in plain text.
- Re-run `can-edit` before the first real file edit in an implementation burst.
- If the gate fails after context recovery, return to router behavior immediately.
- If memory retrieval is enabled for the current phase, inject summaries only; never paste full memory files into the prompt.
- Router retrieval call: `.trae/scripts/memory-retrieve.ps1 -Phase plan -Scope router ...`
- Implement retrieval call: `.trae/scripts/memory-retrieve.ps1 -Phase implement -Scope implement ...`

## Sandwich Reminder

Remember the three highest-priority constraints:

- No confirmation -> no edit
- No `can-edit` -> no write
- No real skill/tool call -> no pretend execution
