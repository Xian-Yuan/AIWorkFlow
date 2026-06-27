# 48 — Plan 阶段检查清单

> **日期**: 2026-06-27
> **状态**: Active
> **真相源**: 本文档从 task-guard.ps1 和 doc-guard.ps1 的检查逻辑逆向提取，是 Agent 通过 Plan 门禁的完整指引
> **用途**: 当 contract-verify 或 task-guard 拦截时，Agent 应参照本清单逐项修复

---

## 1. 总览：Plan 门禁通过条件

Agent 必须同时通过以下三道门禁才能从 Plan 进入 Implement：

1. **contract-verify verify -Phase plan -Strict** — 11 项契约检查
2. **task-guard plan** — 12 项复合检查（含 doc-guard）
3. **task-state can-edit** — 10 项编辑授权检查

三者的关系：contract-verify 是子集，task-guard 是超集，can-edit 是独立检查。**建议先通过 task-guard，它通过后 contract-verify 和 can-edit 通常也通过。**

---

## 2. 必需文件清单

| 文件 | 用途 | 必须非空 |
|------|------|---------|
| `.task.yaml` | 任务状态机 | 是 |
| `routing.md` | 路由决策 | 是 |
| `analysis.md` | 架构分析与成熟方案 | 是 |
| `spec.md` | 行为规范 (GIVEN/WHEN/THEN) | 是 |
| `tasks.md` | 任务拆分 | 是 |
| `doc-impact.md` | 文档影响评估 | 是 |
| `execution-prompt.md` | 实现指令 | 是 |

---

## 3. .task.yaml 必需字段

| 字段 | fast-track 值 | deep-discovery 值 |
|------|--------------|-------------------|
| `phase` | plan | plan |
| `change_profile` | fast | deep |
| `clarification_status` | answered | answered |
| `user_confirmed_plan` | true | true |
| `router_skill_loaded` | true | true |
| `requirements_status` | not_required | confirmed |
| `fast_track_reason` | 具体理由（非空、无尖括号占位符） | 不需要 |
| `execution_prompt` | 指向非空文件 | 指向非空文件 |

---

## 4. routing.md 必需内容

### 4.1 所有任务都需要

```
## Quality Gate
- （列出质量门禁条件）

## Work Package Policy
- External workers: yes 或 no
- MVP/prototype requested by user: no
```

### 4.2 fast-track 任务额外需要

```
## Fast Track Assessment
- Expected behavior is concrete: yes
- Change is bounded: yes
- Architecture or data ownership change: no
- User journey redesign: no
- Unresolved high-impact implicit requirements: none
- Verification is bounded: yes
- Fast-track reason: （具体理由）
```

**注意**：每行的格式必须严格匹配 `- Key: value`，value 必须是 yes/no/none/具体文本，不能用占位符。

### 4.3 deep-discovery 任务额外需要

```
## Requirement Discovery Gate
- Plain-language summary confirmed: yes
- Unresolved high-impact questions: none
```

还需要 `requirements_doc` 指向一个非空的 requirements 文档，该文档必须包含以下 10 个 section：

| Section | 说明 |
|--------|------|
| Desired Outcome | 期望结果 |
| Intended User and Context | 目标用户与上下文 |
| End-to-End Experience | 端到端体验 |
| Confirmed Decisions | 已确认决策 |
| Implicit Requirements | 隐性需求 |
| Boundaries and Non-Goals | 边界与非目标 |
| Success Experience | 成功体验 |
| Open Questions | 开放问题（必须为 "None"） |
| Teach-Back Summary | 回授总结 |
| User Confirmation Evidence | 用户确认证据 |

---

## 5. analysis.md 必需内容

### 5.1 成熟方案证据（6 个 marker，缺一不可）

| Marker | 说明 |
|--------|------|
| `Mature Solution Evidence` | section 标题 |
| `Project-local evidence` | 项目内已有实现证据 |
| `Official/framework evidence` | 官方/框架证据 |
| `Options compared` | 方案对比 |
| `Rejected shortcuts` | 被拒绝的捷径 |
| `Selected mature path` | 选定的成熟路径 |

### 5.2 架构与验证（5 个 marker，缺一不可）

| Marker | 说明 |
|--------|------|
| `Architecture Context` | section 标题 |
| `System boundaries` | 系统边界 |
| `Dependency map` | 依赖图 |
| `Acceptance Criteria` | 验收标准 |
| `Automated Verification Plan` | 自动化验证计划 |

---

## 6. tasks.md 必需内容

| 要求 | 说明 |
|------|------|
| 至少一个任务 | tasks.md 不能为空 |
| 包含 "automated verification" | 自动化验证任务 |
| 包含 "Acceptance Criteria" | AC 映射任务 |
| 包含 "mature path" | 成熟路径验证任务 |
| 包含 "rejected shortcut" | 拒绝捷径验证任务 |

---

## 7. execution-prompt.md 必需 Section（12 个，缺一不可）

每个 section 必须有非空 body：

1. `## Role`
2. `## Goal`
3. `## Task Packet Truth Sources`
4. `## Confirmed Decisions`
5. `## Accepted Architecture`
6. `## Allowed Paths`
7. `## Forbidden Paths`
8. `## Non-Goals`
9. `## Acceptance Criteria`
10. `## Verification Commands`
11. `## Stop Conditions`
12. `## Evidence Rule`

**禁止使用尖括号占位符**（如 `<task>`），会被检测为模板未填写。

---

## 8. doc-impact.md 必需内容

### 8.1 Scope 字段（YAML 列表格式）

```markdown
- Project: 项目名
- System: 系统名
- Owner: 负责人/团队
```

**注意**：必须用 `- Field: value` 格式，不能用 `## Field` 标题格式。value 不能是 TODO/TBD/None/N/A 或含尖括号。

### 8.2 Code Changes

如果改动在 `Project/` 下，必须列出具体路径：

```markdown
## Code Changes
- Project/RTS/Source/RTS/Game/SomeFile.cpp
```

如果改动不在 `Project/` 下（如 .trae/scripts/），必须声明 No Code Changes 并给出理由：

```markdown
## No Code Changes
Reason: This task modifies infrastructure tooling, not project gameplay code.
```

### 8.3 如果 Code Changes 涉及 Project/

还需要：
- `Documentation Updates` section 列出同项目的文档更新
- `Docs Tree Updates` section 列出 DOCS_TREE.md 更新
- 对应项目的 `Project/项目名/Docs/DOCS_TREE.md` 必须存在

---

## 9. spec.md 要求

必须非空。建议使用 GIVEN/WHEN/THEN 格式。

---

## 10. 常见被拦原因速查

| 错误信息 | 修复方法 |
|---------|---------|
| `analysis.md missing mature-solution marker: X` | 在 analysis.md 的 Mature Solution Evidence section 中添加缺失的 marker 文本 |
| `analysis.md missing architecture/verification marker: X` | 在 analysis.md 的 Architecture Context section 中添加缺失的 marker 文本 |
| `routing.md missing Quality Gate` | 添加 `## Quality Gate` section |
| `routing.md must declare MVP/prototype requested by user: no` | 在 Work Package Policy 中添加 `- MVP/prototype requested by user: no` |
| `routing.md fast-track assessment is incomplete` | 在 routing.md 添加 `## Fast Track Assessment` section，按 4.2 格式填写 |
| `routing.md Work Package Policy must declare External workers` | 在 Work Package Policy 中添加 `- External workers: yes` 或 `- External workers: no` |
| `tasks.md missing automated verification task` | 在 tasks.md 添加包含 "automated verification" 的任务 |
| `tasks.md missing Acceptance Criteria mapping task` | 在 tasks.md 添加包含 "Acceptance Criteria" 的任务 |
| `tasks.md missing mature-path verification task` | 在 tasks.md 添加包含 "mature path" 和 "rejected shortcut" 的任务 |
| `execution prompt missing section: X` | 在 execution-prompt.md 添加对应的 `## X` section 并填写非空内容 |
| `execution prompt contains template placeholders` | 移除所有尖括号占位符（如 `<task>`），改用描述性文本 |
| `X scope is missing or placeholder` | 在 doc-impact.md 中用 `- Project: 值` 格式设置 scope |
| `no project code changes listed and no No Code Changes reason` | 在 doc-impact.md 中列出 Code Changes 或添加 No Code Changes + Reason |
| `fast task requires requirements_status: not_required` | 运行 `task-state set <task> requirements_status not_required` |
| `fast task requires a concrete fast_track_reason` | 运行 `task-state set <task> fast_track_reason "具体理由"` |
| `deep task requires requirements_status: confirmed` | 运行 `task-state set <task> requirements_status confirmed` |
| `deep discovery evidence is incomplete` | 在 routing.md 添加 `## Requirement Discovery Gate` section |

---

## 11. 快速通过 Plan 门禁的标准流程

1. 运行 `task-state init <task> full` 初始化任务
2. 运行 `contract-verify <task> init` 生成 contract.yaml
3. 运行 `contract-verify <task> scaffold` 生成带 marker 骨架的模板文件
4. 填写所有模板文件（参照本清单各 section 要求）
5. 运行 `task-state set <task> user_confirmed_plan true`
6. 运行 `task-state set <task> router_skill_loaded true`
7. 运行 `task-state set <task> change_profile fast` 或 `deep`
8. 运行 `task-state set <task> clarification_status answered`
9. 运行 `task-state set <task> requirements_status not_required`（fast）或 `confirmed`（deep）
10. 运行 `task-state set <task> fast_track_reason "具体理由"`（fast）
11. 运行 `task-guard <task> plan` 检查——通过则一切 OK
12. 如果被拦，参照本清单第 10 节修复后重试
