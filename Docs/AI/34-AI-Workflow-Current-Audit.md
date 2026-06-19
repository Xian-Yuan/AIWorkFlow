# AI Workflow Current Audit

Date: 2026-06-17
Status: Active audit
Scope: Codex, OpenCode, Trae-compatible workflow, engine scripts, documentation structure

## Executive Verdict

当前 AI 工作流已经可以被 Codex 使用，但准确结论是：

| 平台 | 当前可用性 | 结论 |
|---|---|---|
| OpenCode | First-class native | `.opencode/agents` 已经是兼容指针层，真实能力收敛到 `skills/*`，并且有 `.opencode/tasks` 与 `.opencode/scripts/task-state.ps1`。 |
| Codex | Shared-runtime usable | Codex 通过 `AGENTS.md`、`skills/codex-project-router/SKILL.md`、`Docs/AI/27/29/33` 和 `.trae/tasks` 可以正常进入工作流。 |
| Codex native `.codex/tasks` | Not ready | `task-guard.ps1` 和 `doc-guard.ps1` 已预留 `.codex/tasks`，但没有 `.codex/tasks` 目录，也没有 Codex 版 `task-state`。 |
| Trae/shared layer | Current mechanical source of truth | `.trae/scripts/task-state.ps1`、`task-guard.ps1`、`doc-guard.ps1` 和回归测试是当前最可靠主链路。 |
| `engine/` unified runtime | Partially built, not authoritative | `engine/` 有统一引擎雏形和规则注册表，但还不能替代 `.trae/scripts`，其中 `engine/phase-machine.ps1` 当前解析失败。 |

一句话：**Codex 能正常用，但必须按 Codex adapter 走 `.trae/tasks` 共享运行时；不要把 `.codex/tasks` 或 `engine/` 当成已完成主链路。**

## Evidence Checked

本次审视读取或验证了以下关键入口：

- `AGENTS.md`
- `skills/codex-project-router/SKILL.md`
- `Docs/AI/27-AI-Workflow-Refactor-Manifest.md`
- `Docs/AI/29-Mature-Solution-First-Workflow.md`
- `Docs/AI/30-AI-Workflow-Compatibility-Analysis.md`
- `Docs/AI/31-Architecture-Analysis.md`
- `Docs/AI/32-Refactoring-Spec.md`
- `Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md`
- `.trae/scripts/task-state.ps1`
- `.trae/scripts/task-guard.ps1`
- `.trae/scripts/doc-guard.ps1`
- `.opencode/scripts/task-state.ps1`
- `engine/rule-enforcer.ps1`
- `engine/rule-registry.json`
- `engine/phase-machine.ps1`
- `.agents/engine/*`

## Verification Results

| Check | Result | Meaning |
|---|---:|---|
| `.trae/scripts/test-doc-guard.ps1` | PASS | 文档治理主链路可运行。 |
| `.trae/scripts/test-workflow-regression.ps1` | PASS | 成熟方案门禁、任务包、OpenCode root、验证报告门禁均可运行。 |
| `engine/rule-enforcer.ps1 validate-registry` | PASS | 规则注册表本身有效。 |
| Parser: `.trae/scripts/task-state.ps1` | PASS | 主任务状态脚本语法有效。 |
| Parser: `.trae/scripts/task-guard.ps1` | PASS | 主阶段门禁脚本语法有效。 |
| Parser: `.trae/scripts/doc-guard.ps1` | PASS | 主文档门禁脚本语法有效。 |
| Parser: `engine/rule-enforcer.ps1` | PASS | 规则执行器语法有效。 |
| Parser: `engine/task-state.ps1` | PASS | engine 版 task-state 语法有效。 |
| Parser: `engine/phase-machine.ps1` | FAIL | `engine/` 不能作为当前主链路。 |
| Parser: `.agents/engine/phase-machine.ps1` | FAIL | `.agents/engine` 旧引擎也不能作为可靠主链路。 |
| `engine/_experimental/test-doc-guard.ps1` | FAIL | 实验测试与当前 doc-guard 行为不一致。 |
| `engine/_experimental/test-workflow-regression.ps1` | FAIL | 实验回归与当前成熟方案/文档治理门禁不同步。 |

## Codex Usability

Codex 当前可用路径：

```text
AGENTS.md
-> skills/codex-project-router/SKILL.md
-> Docs/AI/27-AI-Workflow-Refactor-Manifest.md
-> Docs/AI/29-Mature-Solution-First-Workflow.md
-> Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md
-> .trae/tasks/<project>/<YYYY-MM-DD-system-feature>/
-> .trae/scripts/task-state.ps1 can-edit
-> .trae/scripts/task-guard.ps1 plan|implement|verify
```

Codex 当前不能直接依赖的路径：

```text
.codex/tasks/
engine/phase-machine.ps1
.agents/engine/phase-machine.ps1
engine/_experimental/test-*.ps1
```

原因：

- `.codex/shared` 存在，但它不是任务状态根。
- `.codex/tasks` 不存在。
- `task-state.ps1` 的权威版本仍固定解析 `.trae/tasks`。
- `task-guard.ps1` 和 `doc-guard.ps1` 虽然支持 `.codex/tasks`，但缺少对应 task-state 初始化、读写和 can-edit 适配。

所以 Codex 的当前规则应继续保持：

```text
Codex uses .trae/tasks until a native .codex/tasks adapter exists.
```

## Architecture Findings

### A1. 主链路清晰，但存在多套运行时影子

当前可靠主链路是：

```text
Docs/AI -> skills/* -> .trae/scripts -> .trae/tasks
```

但仓库同时存在：

```text
.trae/scripts/
engine/
.agents/engine/
.opencode/scripts/task-state.ps1
```

风险不是“不能工作”，而是模型容易误判哪个是权威入口。尤其 `Docs/AI/32-Refactoring-Spec.md` 描述的目标架构已经部分落地到 `engine/`，但当前实际权威仍是 `.trae/scripts`。

结论：**`engine/` 是目标/半成品，不是当前主链路。**

### A2. Agent/Skill 双轨冗余已明显改善

旧问题是 `.opencode/agents/*.md` 和 `skills/*/SKILL.md` 内容重复。现在 `.opencode/agents` 已压缩为指针层：

```text
.opencode/agents/<agent>.md -> skills/<agent>/SKILL.md + agent.yaml
```

这是正确方向。仍需补充的是自动校验：确保每个活跃 `.opencode/agents/*.md` 都只保留指针，不重新长出正文。

### A3. Codex adapter 是有效补丁，但不是原生化完成

`skills/codex-project-router/SKILL.md` 明确规定：

- Codex 读取 27/29/33。
- Codex 使用 `.trae/tasks`。
- Codex 编辑前必须跑 `task-state.ps1 can-edit`。
- Codex 完成前必须有自动验证和 `task-guard verify`。

这已经能让 Codex 正常使用当前工作流。缺口是：

- 没有 `.codex/tasks`。
- 没有 Codex-native task-state。
- 没有自动 hook 强制 Codex 每次编辑前调用 can-edit，只能通过 AGENTS/skill 约束和最终门禁约束。

### A4. 成熟方案门禁是强约束，符合用户要求

`task-guard.ps1 plan` 已检查：

- `Mature Solution Evidence`
- `Quality Gate`
- `Architecture Context`
- `Acceptance Criteria`
- `Automated Verification Plan`
- `Work Package Policy`
- 外部 worker 的 work package 和 report 质量

这会提高计划成本，但符合“不要最小落地降质方案”的强制要求。当前不建议放松门禁，应该通过模板/生成器降低填写成本。

### A5. 文档编号 30/31/32/33 的状态需要重新标注

当前角色应是：

| 文档 | 当前角色 | 问题 |
|---|---|---|
| 30 Compatibility Analysis | 历史兼容性报告 + 部分仍有效 | 描述了 Codex sync 脚本位于 `.trae/scripts`，但实际在 `engine/_experimental`；应标注为历史快照或更新。 |
| 31 Architecture Analysis | 旧架构问题分析 | 部分事实已变化，例如 `.opencode/agents` 已变成指针层；应保留为历史输入。 |
| 32 Refactoring Spec | 目标架构实施方案 | 部分实施、部分未完成；不能当作当前状态。 |
| 33 Multi-Agent Task Packet Workflow | 当前 active 规则 | 与主回归测试一致，应保留为权威。 |

### A6. 实验脚本没有隔离得足够醒目

`engine/_experimental` 里有测试、Codex sync、mem0、repomix、ollama、bolt 等脚本。实验目录本身没问题，但失败测试会误导模型以为主链路坏了。

建议给 `engine/_experimental/README.md` 明确：

- not authoritative
- not required by current workflow
- failures do not block `.trae/scripts` workflow
- promotion requires parser pass + regression pass + manifest update

## Redundancy Findings

| Redundancy | Severity | Current Impact | Recommendation |
|---|---:|---|---|
| `.trae/scripts` vs `engine` | P0 | 两套 task-state/doc-guard/spec/verify/memory 脚本并存，模型可能选错主链路。 | 在 27 manifest 中明确 `.trae/scripts` 是 current authoritative，`engine` 是 refactor candidate。 |
| `engine/phase-machine.ps1` and `.agents/engine/phase-machine.ps1` | P0 | 解析失败，不能执行。 | 修复或标记为 disabled；在修复前不要让模型调用。 |
| `engine/_experimental/test-*.ps1` vs `.trae/scripts/test-*.ps1` | P1 | 实验测试失败但主测试通过，容易制造假故障。 | 标注 experimental tests as non-blocking，或更新其路径和断言。 |
| `.opencode/scripts/task-state.ps1` vs `.trae/scripts/task-state.ps1` | P1 | OpenCode 简化版 can-edit 逻辑弱于共享主链路。 | OpenCode 继续用 `.trae/scripts/task-guard` 做强门禁；后续将 task-state 收敛到单一实现。 |
| `.trae/scripts/*.md` templates | P2 | Markdown 模板放在 scripts 目录，语义不干净，但当前可用。 | 后续迁移到 `.trae/templates/`，保留兼容转发。 |
| `spec-tracker.ps1` vs `spec-living.ps1` | P2 | 已废弃但脚本仍在。 | 保留兼容，但在脚本头部和 manifest 中继续标明 deprecated。 |
| root `agents/*.yaml` | P2 | 通用 agent yaml 没有 UE 项目上下文。 | 若未被 ruflo/engine 使用，归档或标为 external tool artifacts。 |

## Invalid Or Weak Features

### I1. `engine/phase-machine.ps1` is invalid

解析失败位置集中在：

- line 75: 正则字符串包含未转义单引号。
- line 170 起：`onboarding` switch case 结构异常。

影响：不能把 `engine/phase-machine.ps1` 当成当前阶段门禁。

### I2. `.agents/engine/phase-machine.ps1` 同样 invalid

`.agents/engine` 与 `engine` 里的 phase-machine 内容同步了同样的问题。它不是可用备份。

### I3. `engine/_experimental/test-doc-guard.ps1` 当前失败

失败项：

```text
same-project docs and docs tree pass - expected pass, got block
```

说明实验测试的 fixture 或断言没有跟当前 doc-governance 同步。

### I4. `engine/_experimental/test-workflow-regression.ps1` 当前失败

失败项：

```text
documentation-governance
mature-solution-gate-pass
```

说明实验回归已经落后于当前强门禁。主回归 `.trae/scripts/test-workflow-regression.ps1` 通过，因此这不是主链路故障。

### I5. `Docs/AI/30` 对 Codex sync 脚本位置描述陈旧

`30-AI-Workflow-Compatibility-Analysis.md` 写的是 `.trae/scripts/sync-codex-state.ps1` 和 `.trae/scripts/sync-codex-merge.py`；当前实际位置是：

```text
engine/_experimental/sync-codex-state.ps1
engine/_experimental/sync-codex-merge.py
```

且它们是会话/同步实验，不是当前工作流 phase state。

## Recommended Next Actions

### P0. 固化当前权威主链路

在 `Docs/AI/27-AI-Workflow-Refactor-Manifest.md` 增加一句硬规则：

```text
Current authoritative mechanical workflow is .trae/scripts. engine/ is refactor candidate until explicitly promoted.
```

目的：防止 Codex/OpenCode/其他模型误用 `engine/phase-machine.ps1`。

### P0. 给 Codex 做真正 native task adapter，或明确永久共享 `.trae/tasks`

二选一：

1. 实现 `.codex/tasks` + Codex task-state adapter。
2. 明确 Codex 永久使用 `.trae/tasks`，删除 `.codex/tasks` 的“未来兼容”暗示。

当前建议选 1，但不要急着复制脚本。先把 `task-state.ps1` 抽成 multi-root resolver，再让 Codex/OpenCode/Trae 都调用同一实现。

### P0. 修复或禁用 `engine/phase-machine.ps1`

在修复前，文档中不要把 `engine/phase-machine.ps1` 宣称为可用阶段门禁。

### P1. 给任务包增加初始化生成器

现在门禁很强，手写成本高。建议新增：

```text
.trae/scripts/new-task-packet.ps1
```

它应自动生成：

- `.task.yaml`
- `routing.md`
- `analysis.md`
- `spec.md`
- `tasks.md`
- `doc-impact.md`
- `work-packages/`
- `reports/`
- `verification-report.md`

目的不是降低标准，而是让高标准不靠模型记忆。

### P1. 给脚本做 active/compat/experimental 清单

建议新增：

```text
Docs/AI/35-Workflow-Tooling-Inventory.md
```

把脚本分为：

- active authoritative
- compatibility
- refactor candidate
- experimental
- one-shot migration
- deprecated

### P1. 更新 30/31/32 的状态说明

这些文档不是无效，但已经不能全部按当前事实读取。建议在文档顶部加：

```text
Status note: superseded in part by Docs/AI/33 and Docs/AI/34.
```

### P2. 清理旧回归 fixture 和 pending checklist

`.trae/tasks/_shared/regression-deepseek-*` 和 pending checklist 里仍记录旧 engine 路径问题。建议保留历史结果，但加 `archive/historical` 标记，避免当前模型误读。

## Decision Table

| Question | Answer |
|---|---|
| Codex 现在能正常使用吗？ | 能。走 `AGENTS.md` + `skills/codex-project-router` + `.trae/tasks` + `.trae/scripts`。 |
| Codex 是 first-class native 吗？ | 还不是。缺 `.codex/tasks` 和 Codex-native task-state。 |
| OpenCode 是不是唯一可用？ | 不是。OpenCode 原生化最好，但 Codex 共享运行时可用。 |
| 有没有冗余？ | 有。最大冗余是 `.trae/scripts`、`engine/`、`.agents/engine/` 三套运行时影子。 |
| 有没有无效功能？ | 有。`engine/phase-machine.ps1` 与 `.agents/engine/phase-machine.ps1` 当前解析失败；`engine/_experimental` 两个测试失败。 |
| 主工作流是否被这些无效功能破坏？ | 没有。`.trae/scripts` 主回归通过。 |
| 当前最该做什么？ | 先标明权威主链路，再修复/禁用 engine phase-machine，随后做 multi-root task-state 和任务包生成器。 |

## Current Safe Operating Rule

Until the next refactor is complete, every agent should follow this rule:

```text
Use Docs/AI/27 + Docs/AI/29 + Docs/AI/33 as workflow policy.
Use .trae/scripts as mechanical authority.
Use .trae/tasks as shared runtime task root.
Treat engine/ as refactor candidate.
Treat engine/_experimental/ as non-blocking experiments.
Codex must load skills/codex-project-router before project work.
```

