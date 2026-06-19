# Basic Memory Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为当前工作区落地 `Basic Memory` 第一阶段：创建 `Docs/Memory/` 目录与模板，并把 failure memory 的写入/检索规则接入现有 `Plan -> Implement -> Review -> Verify` 工作流。

**Architecture:** 第一阶段坚持“文件是真相源”的原则，不接入外部 memory service。实现分成两层：一层是 `Docs/Memory/` 的存储结构、模板、README 与索引；另一层是把 `Router / Implement / Review / Verify` 对应的读写契约写回现有 agent、skill 与规则文档，让 failure memory 成为工作流可用的辅助记忆层，而不是黑盒系统。

**Tech Stack:** Markdown, PowerShell verification, `.trae` workflow docs, `.opencode` agent prompts

---

## File Structure

### Create

- `g:\UEGameDevelopment\Docs\Memory\README.md`
- `g:\UEGameDevelopment\Docs\Memory\indexes\memory-index.md`
- `g:\UEGameDevelopment\Docs\Memory\templates\failure-memory-template.md`
- `g:\UEGameDevelopment\Docs\Memory\templates\memory-candidate-template.md`
- `g:\UEGameDevelopment\Docs\Memory\failures\.gitkeep`
- `g:\UEGameDevelopment\Docs\Memory\candidates\.gitkeep`

### Modify

- `g:\UEGameDevelopment\CLAUDE.md`
- `g:\UEGameDevelopment\Docs\AI\01-AI-Development-Playbook.md`
- `g:\UEGameDevelopment\Docs\AI\02-Project-Truth-Source.md`
- `g:\UEGameDevelopment\Docs\AI\16-DeepSeek4Pro-Workflow-Profile.md`
- `g:\UEGameDevelopment\Docs\AI\20-DeepSeek4Pro-Regression-Scenarios.md`
- `g:\UEGameDevelopment\Docs\AI\21-Workflow-Regression-Checklist.md`
- `g:\UEGameDevelopment\.trae\rules\project_rules.md`
- `g:\UEGameDevelopment\.trae\skills\ue-project-router\SKILL.md`
- `g:\UEGameDevelopment\.opencode\agents\ue-project-router.md`
- `g:\UEGameDevelopment\.opencode\agents\ue-lyra-gas-implementer.md`
- `g:\UEGameDevelopment\.opencode\agents\web-implementer.md`
- `g:\UEGameDevelopment\.opencode\agents\code-quality-reviewer.md`

### Verification

- Markdown diagnostics on all new and modified `.md` files
- Placeholder scan on new `Docs/Memory/` files and updated workflow docs
- Optional grep verification that `Docs/Memory` entry points appear in router / implementer / reviewer docs

---

### Task 1: Create Docs/Memory Scaffold

**Files:**
- Create: `g:\UEGameDevelopment\Docs\Memory\README.md`
- Create: `g:\UEGameDevelopment\Docs\Memory\indexes\memory-index.md`
- Create: `g:\UEGameDevelopment\Docs\Memory\templates\failure-memory-template.md`
- Create: `g:\UEGameDevelopment\Docs\Memory\templates\memory-candidate-template.md`
- Create: `g:\UEGameDevelopment\Docs\Memory\failures\.gitkeep`
- Create: `g:\UEGameDevelopment\Docs\Memory\candidates\.gitkeep`

- [ ] **Step 1: Write the memory README**

Write `Docs/Memory/README.md` with these sections:

```md
# Basic Memory

## Goal

`Docs/Memory/` stores high-value failure memories for the workspace. It is the Phase 1 file-based memory layer and remains human-auditable.

## Scope

- Store only failure-driven memory in Phase 1
- Keep files as the source of truth
- Support Router and Implement retrieval
- Prepare for future `Mem0` sync without making `Mem0` the source of truth

## Directory Layout

- `failures/`: promoted failure memories
- `candidates/`: pre-promotion candidate memories
- `indexes/`: lightweight retrieval index
- `templates/`: canonical write templates

## Write Triggers

- `Review FAIL`
- `Verify FAIL`
- workflow regression fail

## Promotion Gate

- observed or reproducible failure
- reusable rule
- clear verification method
- useful for `router` or `implement` retrieval

## Retrieval Rules

- Router reads `top 2`, at most `top 3`
- Implement reads `top 1`, at most `top 2`
- Summaries only; do not inject full memory files into prompts

## Prohibited

- do not write ordinary success notes here
- do not dump full chat logs
- do not let implementers write final memory entries directly
- do not treat external memory systems as the source of truth
```

- [ ] **Step 2: Write the lightweight index**

Write `Docs/Memory/indexes/memory-index.md`:

```md
# Memory Index

| ID | Title | Phase | Module | Severity | Scope | Tags | File |
|---|---|---|---|---|---|---|---|
```

Expected: no seed entries are required in Phase 1; the file starts empty except for header rows.

- [ ] **Step 3: Write the failure memory template**

Write `Docs/Memory/templates/failure-memory-template.md`:

```md
---
id: memory-<domain>-<topic>-<date>
type: failure_memory
phase: <plan|implement|review|verify>
project_type: <ue5|web|other>
module: <module-name>
tags:
  - <tag>
severity: <medium|high>
write_trigger: <review_fail|verify_fail|regression_fail>
retrieval_scope:
  - router
  - implement
token_budget: small
mem0_sync_status: not_synced
mem0_memory_id: null
memory_version: v1
---

# <Title>

## Symptom

## Root Cause

## Bad Pattern

## Correct Rule

## Retrieval Hint

## Verification
```

- [ ] **Step 4: Write the candidate template**

Write `Docs/Memory/templates/memory-candidate-template.md`:

```md
---
id: candidate-<domain>-<topic>-<date>
source: <review_fail|verify_fail|regression_fail>
status: candidate
phase: <plan|implement|review|verify>
project_type: <ue5|web|other>
module: <module-name>
severity: <medium|high>
tags:
  - <tag>
---

# Candidate: <Title>

## Failure Event

## Evidence

## Draft Root Cause

## Draft Rule

## Promotion Check
- [ ] 可复现或已被明确观察
- [ ] 可提炼成通用规则
- [ ] 有验证标准
- [ ] 值得在 Router 或 Implement 检索
```

- [ ] **Step 5: Create empty storage directories**

Create:

```text
g:\UEGameDevelopment\Docs\Memory\failures\.gitkeep
g:\UEGameDevelopment\Docs\Memory\candidates\.gitkeep
```

- [ ] **Step 6: Verify the new scaffold**

Run:

```powershell
Get-ChildItem "g:\UEGameDevelopment\Docs\Memory" -Recurse
```

Expected: `README.md`, `indexes`, `templates`, `failures`, and `candidates` all exist.

---

### Task 2: Register Docs/Memory In Truth Sources

**Files:**
- Modify: `g:\UEGameDevelopment\CLAUDE.md`
- Modify: `g:\UEGameDevelopment\Docs\AI\01-AI-Development-Playbook.md`
- Modify: `g:\UEGameDevelopment\Docs\AI\02-Project-Truth-Source.md`
- Modify: `g:\UEGameDevelopment\.trae\rules\project_rules.md`

- [ ] **Step 1: Add Docs/Memory to CLAUDE index**

Add a row under the collaboration/AI docs area in `CLAUDE.md`:

```md
| Memory | `Docs/Memory/README.md` | Basic Memory 第一阶段说明与准入规则 |
| Memory | `Docs/Memory/indexes/memory-index.md` | failure memory 轻量检索索引 |
```

Also extend the toolchain or truth-source description so agents know that `Docs/Memory/` is an auxiliary memory layer, while `Docs/AI/` remains the workflow truth source.

- [ ] **Step 2: Update Playbook trigger rules**

In `Docs/AI/01-AI-Development-Playbook.md`, add:

```md
- 若 `Review FAIL`、`Verify FAIL` 或 workflow regression fail，必须评估是否生成 `Docs/Memory/candidates/` 中的 memory candidate
- 若当前任务属于新需求分析或首次实现前，允许按 `Docs/Memory/indexes/memory-index.md` 检索少量 failure memory 摘要
- memory 检索只允许摘要注入，不允许整篇 memory 原文进入 prompt
```

- [ ] **Step 3: Update Project Truth Source**

In `Docs/AI/02-Project-Truth-Source.md`, add `Docs/Memory/` to the document truth-source area, with wording like:

```md
- `Docs/Memory/README.md`：Basic Memory 第一阶段规则
- `Docs/Memory/indexes/memory-index.md`：failure memory 检索入口
```

Keep the text clear that `Docs/Memory/` is an auxiliary memory source, not a replacement for `Docs/AI/`.

- [ ] **Step 4: Update project_rules workflow section**

In `.trae/rules/project_rules.md`, add:

```md
- `Router` 在依赖链推导前可读取 `Docs/Memory/indexes/memory-index.md`，按需提炼 `Relevant Failure Memories`
- `Implement` 在 `can-edit` 通过后、首次编辑前可读取少量相关 failure memory，输出 `Pre-Edit Failure Reminder`
- `Review FAIL` / `Verify FAIL` / workflow regression fail 可生成 memory candidate；正式 memory 仍需通过转正门槛
```

- [ ] **Step 5: Verify truth-source registration**

Run:

```powershell
rg -n "Docs/Memory|memory-index|Relevant Failure Memories|Pre-Edit Failure Reminder" "g:\UEGameDevelopment\CLAUDE.md" "g:\UEGameDevelopment\Docs\AI\01-AI-Development-Playbook.md" "g:\UEGameDevelopment\Docs\AI\02-Project-Truth-Source.md" "g:\UEGameDevelopment\.trae\rules\project_rules.md"
```

Expected: all four files mention the new memory layer correctly.

---

### Task 3: Integrate Router And Implement Retrieval Contracts

**Files:**
- Modify: `g:\UEGameDevelopment\.opencode\agents\ue-project-router.md`
- Modify: `g:\UEGameDevelopment\.trae\skills\ue-project-router\SKILL.md`
- Modify: `g:\UEGameDevelopment\.opencode\agents\ue-lyra-gas-implementer.md`
- Modify: `g:\UEGameDevelopment\.opencode\agents\web-implementer.md`
- Modify: `g:\UEGameDevelopment\Docs\AI\16-DeepSeek4Pro-Workflow-Profile.md`

- [ ] **Step 1: Add Router retrieval step to ue-project-router agent**

Insert a short subsection before or inside the dependency-analysis stage in `.opencode/agents/ue-project-router.md` with this contract:

```md
### Failure Memory Retrieval

- 在依赖链推导前，可读取 `Docs/Memory/indexes/memory-index.md`
- 仅按 `project_type`、`phase=plan`、`retrieval_scope=router`、`module/tags` 相关性选择 `top 2`，高风险最多 `top 3`
- 输出格式固定为：

```text
Relevant Failure Memories
1. <bad pattern> -> <correct rule> -> <verification>
```

- 若无高相关项，返回空，不凑满
- 禁止把整篇 memory 原文拼进 prompt
```

- [ ] **Step 2: Mirror the same rule in ue-project-router skill**

Add equivalent wording to `.trae/skills/ue-project-router/SKILL.md`, making it part of the Phase 1 planning workflow and preserving the current hard-gate rules.

- [ ] **Step 3: Add UE implementer reminder contract**

In `.opencode/agents/ue-lyra-gas-implementer.md`, after the `can-edit` pass requirement, add:

```md
- 首次编辑前可读取 `Docs/Memory/indexes/memory-index.md`
- 仅选择与当前任务最相关的 `top 1`，高风险最多 `top 2`
- 输出一个极小的 `Pre-Edit Failure Reminder`
- 只保留 `Bad Pattern / Correct Rule / Verification`
- 如果 `analysis.md` 已覆盖同一风险点，可跳过重复注入
```

- [ ] **Step 4: Add Web implementer reminder contract**

In `.opencode/agents\web-implementer.md`, add the same `Pre-Edit Failure Reminder` contract adapted for Web implementation.

- [ ] **Step 5: Update DeepSeek4Pro profile**

In `Docs/AI/16-DeepSeek4Pro-Workflow-Profile.md`, add one compact rule:

```md
- If memory retrieval is enabled for the current phase, inject summaries only; never paste full memory files into the prompt.
```

and extend the fixed order so retrieval happens after `can-edit` and before editing in implement flows.

- [ ] **Step 6: Verify Router and Implement hooks**

Run:

```powershell
rg -n "Relevant Failure Memories|Pre-Edit Failure Reminder|Docs/Memory/indexes/memory-index.md" "g:\UEGameDevelopment\.opencode\agents\ue-project-router.md" "g:\UEGameDevelopment\.trae\skills\ue-project-router\SKILL.md" "g:\UEGameDevelopment\.opencode\agents\ue-lyra-gas-implementer.md" "g:\UEGameDevelopment\.opencode\agents\web-implementer.md" "g:\UEGameDevelopment\Docs\AI\16-DeepSeek4Pro-Workflow-Profile.md"
```

Expected: all five files contain the intended memory retrieval hook.

---

### Task 4: Integrate Review, Verify, And Regression Candidate Flow

**Files:**
- Modify: `g:\UEGameDevelopment\.opencode\agents\code-quality-reviewer.md`
- Modify: `g:\UEGameDevelopment\Docs\AI\20-DeepSeek4Pro-Regression-Scenarios.md`
- Modify: `g:\UEGameDevelopment\Docs\AI\21-Workflow-Regression-Checklist.md`

- [ ] **Step 1: Add memory-candidate output contract to reviewer**

In `.opencode\agents\code-quality-reviewer.md`, add a short subsection after FAIL reporting that defines:

```md
### Memory Candidate Output

当 FAIL 具备复用价值时，可附带：

```text
MEMORY_CANDIDATE: yes
MEMORY_TYPE: <failure_memory|workflow_failure_memory>
MEMORY_REASON: ...

MEMORY_SUMMARY
- Symptom: ...
- Root Cause: ...
- Bad Pattern: ...
- Correct Rule: ...
- Verification: ...
```

- 这是 candidate 提议，不是自动转正
- reviewer 不直接写最终 memory 文件
```

- [ ] **Step 2: Tie regression scenarios to workflow memory**

In `Docs/AI/20-DeepSeek4Pro-Regression-Scenarios.md`, add a note under `S01-S05` or in a shared note section:

```md
- `S01-S04` fail -> consider `workflow_failure_memory` candidate
- `S05` fail -> treat as high-priority workflow memory candidate
```

- [ ] **Step 3: Update workflow regression checklist**

In `Docs/AI/21-Workflow-Regression-Checklist.md`, add one checklist item:

```md
- [ ] For any FAIL, assess whether a `Docs/Memory/candidates/` entry should be created
```

- [ ] **Step 4: Verify review and regression hooks**

Run:

```powershell
rg -n "MEMORY_CANDIDATE|workflow_failure_memory|Docs/Memory/candidates" "g:\UEGameDevelopment\.opencode\agents\code-quality-reviewer.md" "g:\UEGameDevelopment\Docs\AI\20-DeepSeek4Pro-Regression-Scenarios.md" "g:\UEGameDevelopment\Docs\AI\21-Workflow-Regression-Checklist.md"
```

Expected: the candidate flow is present in reviewer and regression docs.

---

### Task 5: Validate Documentation Integrity

**Files:**
- Verify: all files created or modified in Tasks 1-4

- [ ] **Step 1: Run placeholder scan**

Run:

```powershell
rg -n "TODO|TBD|PLACEHOLDER" "g:\UEGameDevelopment\Docs\Memory" "g:\UEGameDevelopment\CLAUDE.md" "g:\UEGameDevelopment\Docs\AI" "g:\UEGameDevelopment\.opencode\agents" "g:\UEGameDevelopment\.trae\rules\project_rules.md" "g:\UEGameDevelopment\.trae\skills\ue-project-router\SKILL.md"
```

Expected: no accidental placeholders in new content. Template metavariables like `<module-name>` are acceptable only inside template files.

- [ ] **Step 2: Run diagnostics on touched Markdown files**

Use diagnostics tooling on:

```text
Docs/Memory/README.md
Docs/Memory/indexes/memory-index.md
Docs/Memory/templates/failure-memory-template.md
Docs/Memory/templates/memory-candidate-template.md
CLAUDE.md
Docs/AI/01-AI-Development-Playbook.md
Docs/AI/02-Project-Truth-Source.md
Docs/AI/16-DeepSeek4Pro-Workflow-Profile.md
Docs/AI/20-DeepSeek4Pro-Regression-Scenarios.md
Docs/AI/21-Workflow-Regression-Checklist.md
.opencode/agents/ue-project-router.md
.opencode/agents/ue-lyra-gas-implementer.md
.opencode/agents/web-implementer.md
.opencode/agents/code-quality-reviewer.md
.trae/rules/project_rules.md
.trae/skills/ue-project-router/SKILL.md
```

Expected: no new diagnostics caused by this work.

- [ ] **Step 3: Review git diff scope**

Run:

```powershell
git diff --stat
```

Expected: changes are limited to workflow docs, agent prompts, and new `Docs/Memory/` files; no business-code files are touched.

- [ ] **Step 4: Commit**

```bash
git add Docs/Memory README.md CLAUDE.md Docs/AI .opencode/agents .trae/rules/project_rules.md .trae/skills/ue-project-router/SKILL.md docs/superpowers/plans/2026-05-31-basic-memory-phase1-implementation-plan.md Docs/superpowers/specs/2026-05-31-basic-memory-phase1-design.md
git commit -m "feat: add basic memory phase 1 workflow integration"
```

If you should not commit yet, stop after verification and hand the diff to the human partner.
