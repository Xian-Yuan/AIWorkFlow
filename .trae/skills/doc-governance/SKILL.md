---
name: doc-governance
description: Use when changing project code, creating or moving project documents, writing specs or plans, or when documentation placement, document trees, docs-impact, or doc-guard are relevant
---

# Doc Governance

## Overview

Project code and project documentation move together. Any task that changes `Project/<ProjectName>/...` code must update same-project docs and `Project/<ProjectName>/Docs/DOCS_TREE.md`.

## Mandatory Rules

1. Identify the affected project before editing: `Project/<ProjectName>/`.
2. Put project docs under that project, not root `Docs/AI/`, unless the change is about the global AI workflow itself.
3. Classify new project docs under one of:
   - `00-Overview/`
   - `01-Planning/<System>/`
   - `02-Design/<System>/`
   - `03-Architecture/<System>/`
   - `04-Implementation/<System>/`
   - `05-Testing/<System>/`
   - `06-Operations/<System>/`
   - `07-Decisions/<System>/`
   - `99-Archive/`
4. Update `.trae/tasks/<scope>/<task>/doc-impact.md` for every task.
5. If code changed, list same-project docs under `Documentation Updates`.
6. If docs changed, list `Project/<ProjectName>/Docs/DOCS_TREE.md` under `Docs Tree Updates`.
7. Run `.trae/scripts/doc-guard.ps1 check-task <task> -Stage plan|implement` before phase transition.

## Quick Commands

```powershell
# Create project docs folders and tree
& .\.trae\scripts\doc-guard.ps1 init-project "<ProjectName>"

# Print task evidence template
& .\.trae\scripts\doc-guard.ps1 print-impact-template

# Check a task
& .\.trae\scripts\doc-guard.ps1 check-task "<scope>/<task>" -Stage implement
```

## Task Evidence

Every task needs `doc-impact.md`:

```markdown
## Project Document Scope
- Project: AIRPGWeb
- System: Combat
- Owner: implementation

## Code Changes
- Project/AIRPGWeb/src/combat/attack.ts

## Documentation Updates
- Project/AIRPGWeb/Docs/04-Implementation/Combat/attack-flow.md

## Docs Tree Updates
- Project/AIRPGWeb/Docs/DOCS_TREE.md
```

## Red Flags

| Excuse | Reality |
|---|---|
| "只是小改动，不用更新文档" | 小改动也会改变项目事实源，必须留下 doc-impact。 |
| "先写代码，最后补文档" | 可以最后提交，但任务交接前必须通过 doc-guard。 |
| "放到根 Docs 更容易找到" | 项目文档先归项目，根 Docs 只放跨项目 AI 工作流和全局规则。 |
| "DOCS_TREE 以后再整理" | 文档树是导航入口，文档变动必须同步更新。 |

## Reference

- `references/docs-only-task-flow.md` — Complete flow for docs-only tasks (no code changes): gate sequence, implementation steps, verification commands, and common pitfalls.

## Verification

Run:

```powershell
& .\.trae\scripts\test-doc-guard.ps1
```

This test covers missing `doc-impact.md`, cross-project documentation, and same-project documentation with tree updates.

