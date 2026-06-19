# Documentation Governance Workflow

日期：2026-06-17
状态：Active
适用范围：所有 `Project/<ProjectName>/` 下的项目代码与项目文档变更

## 1. 核心原则

项目代码和项目文档必须同步移动。

任何任务只要修改 `Project/<ProjectName>/...` 下的项目代码，就必须：

1. 在同一个项目的 `Docs/` 下更新对应文档。
2. 更新该项目的 `Project/<ProjectName>/Docs/DOCS_TREE.md`。
3. 在当前任务目录写入或更新 `doc-impact.md`。
4. 通过 `.trae/scripts/doc-guard.ps1` 检查。

根目录 `Docs/AI/` 只承载跨项目 AI 工作流、Agent 规则、全局文档治理规则，不承载某个具体项目的功能实现文档。

## 2. 新增组件

### 2.1 Skill

位置：

- `skills/doc-governance/SKILL.md`

触发场景：

- 修改项目代码。
- 新建或移动项目文档。
- 写项目 spec / plan。
- 任务涉及 `doc-impact.md`、`DOCS_TREE.md`、文档分类、文档归档。

职责：

- 告诉 Agent 如何判断文档归属。
- 要求代码变更同步文档。
- 要求文档变更同步文档树。
- 要求运行 `doc-guard.ps1`。

### 2.2 Task Evidence

位置：

- `.trae/tasks/<scope>/<task>/doc-impact.md`

模板：

- `.trae/scripts/doc-impact-template.md`

用途：

- 记录本任务影响了哪个项目。
- 记录系统或功能名。
- 记录代码路径。
- 记录文档更新路径。
- 记录文档树更新路径。

### 2.3 Project Docs Tree

位置：

- `Project/<ProjectName>/Docs/DOCS_TREE.md`

模板：

- `.trae/scripts/doc-tree-template.md`

用途：

- 作为每个项目自己的文档总览。
- 按系统和文档类型组织入口。
- 每次项目文档变更必须同步更新。

### 2.4 Mechanical Guard

位置：

- `.trae/scripts/doc-guard.ps1`

主要命令：

```powershell
& .\.trae\scripts\doc-guard.ps1 init-project "<ProjectName>"
& .\.trae\scripts\doc-guard.ps1 check-project "<ProjectName>"
& .\.trae\scripts\doc-guard.ps1 check-task "<scope>/<task>" -Stage plan
& .\.trae\scripts\doc-guard.ps1 check-task "<scope>/<task>" -Stage implement
```

回归测试：

```powershell
& .\.trae\scripts\test-doc-guard.ps1
```

## 3. 项目文档分类规则

新项目文档必须放在对应项目自己的 `Docs/` 下：

```text
Project/<ProjectName>/Docs/
  DOCS_TREE.md
  00-Overview/
  01-Planning/<System>/
  02-Design/<System>/
  03-Architecture/<System>/
  04-Implementation/<System>/
  05-Testing/<System>/
  06-Operations/<System>/
  07-Decisions/<System>/
  99-Archive/
```

分类含义：

| 目录 | 用途 |
|---|---|
| `00-Overview/` | 项目概览、入口、术语 |
| `01-Planning/<System>/` | 策划、路线、需求拆解 |
| `02-Design/<System>/` | 玩法、产品、UX、系统设计 spec |
| `03-Architecture/<System>/` | 架构、模块边界、数据流、接口契约 |
| `04-Implementation/<System>/` | 实现说明、代码映射、变更记录 |
| `05-Testing/<System>/` | 测试计划、QA、验证报告 |
| `06-Operations/<System>/` | 构建、发布、部署、运行手册 |
| `07-Decisions/<System>/` | ADR 和长期决策 |
| `99-Archive/` | 历史材料、废弃文档 |

## 4. 工作流集成

`task-guard.ps1` 已接入 `doc-guard.ps1`：

- `plan -> implement` 阶段会检查 `doc-impact.md` 是否存在，并检查 Project / System / Owner 范围是否明确。
- `implement -> review` 阶段会检查代码变更是否有同项目文档更新，以及是否列出 `DOCS_TREE.md` 更新。

这意味着文档治理不是建议，而是阶段门禁。

## 5. 通过条件

一个修改了项目代码的任务必须满足：

- `doc-impact.md` 存在。
- `Project`、`System`、`Owner` 明确，不是占位符。
- `Code Changes` 列出项目代码路径。
- `Documentation Updates` 至少包含同项目 `Project/<ProjectName>/Docs/...` 路径。
- 文档路径位于允许的分类目录下。
- `Docs Tree Updates` 包含 `Project/<ProjectName>/Docs/DOCS_TREE.md`。
- 对应项目的 `Docs/` 和 `DOCS_TREE.md` 已存在。

## 6. 失败示例

以下行为会被阻止：

- 修改 `Project/AIRPGWeb/src/...`，但只更新 `Docs/AI/...`。
- 修改项目代码但没有 `doc-impact.md`。
- 文档更新写到另一个项目的 `Docs/`。
- 新文档直接放在 `Project/<ProjectName>/Docs/foo.md`，没有进入分类目录。
- 文档更新后没有列出 `DOCS_TREE.md` 更新。

## 7. 与现有 AI 工作流关系

本规则补充而不替代：

- `Docs/AI/11-Skill-Routing-Workflow.md`
- `Docs/AI/12-MultiAgent-Workflow.md`
- `Docs/AI/21-Workflow-Regression-Checklist.md`
- `skills/spec-living/SKILL.md`

`spec-living` 记录任务执行状态；`doc-governance` 记录项目事实源同步状态。两者都应在任务交接中被保留。

