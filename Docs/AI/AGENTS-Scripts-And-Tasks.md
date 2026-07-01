# Scripts & Tasks — UEGameDevelopment

> 主入口：[AGENTS.md](../../AGENTS.md) · 路径：`Docs/AI/AGENTS-Scripts-And-Tasks.md`

## 脚本清单 → `.trae/` + `.opencode/`

| 路径 | 用途 | 共享性 |
|------|------|--------|
| `.trae/scripts/task-env.ps1` | 环境配置 | 共享（Trae/OpenCode 共用） |
| `.trae/scripts/task-state.ps1` | 状态管理（init/get/set/transition/check） | 共享 |
| `.trae/scripts/task-guard.ps1` | 阶段守护（Plan-Apply 自动切换） | 共享 |
| `.trae/scripts/task-handoff.ps1` | 阶段交接（自动检测阶段，生成交接文件） | 共享 |
| `.trae/scripts/memory-retrieve.ps1` | 统一 failure memory 检索 | 共享 |
| `.trae/scripts/detect-duplicates.ps1` | 代码重复检测扫描 | 共享 |
| `.opencode/scripts/task-state.ps1` | OpenCode 状态管理（task-env + task-state 合并版） | OpenCode 专用 |
| `.trae/tasks/<name>/.task.yaml` | 任务状态文件 | Trae |
| `.trae/tasks/<name>/routing.md` | 路由决策（入口分析 + 形式化 + 架构决策） | Trae |
| `.trae/tasks/<name>/spec.md` | 行为规范（GIVEN/WHEN/THEN） | Trae |
| `.trae/tasks/<name>/tasks.md` | 任务清单（含依赖图） | Trae |
| `.trae/tasks/<name>/analysis.md` | 分析报告（架构分析 + 约束推导） | Trae |
| `.opencode/tasks/<name>/` | 任务状态文件 + routing + spec + tasks + analysis | OpenCode（沿用 Trae 格式） |
| `.opencode/agents/` | Agent 定义文件 | OpenCode |

## 任务目录结构

```
.trae/tasks/<project>/<YYYY-MM-DD-system-feature>/
├── .task.yaml         # 任务状态文件（机器读写）
├── routing.md         # 入口分析与形式化
├── spec.md            # GIVEN/WHEN/THEN 行为规范
├── tasks.md           # 含依赖图的任务清单
├── analysis.md        # 架构分析与约束推导
└── verification-report.md   # 自动化验证记录
```

模板源：`.trae/tasks/_shared/templates/`
- 任务清单 → `tasks-template.md`
- 规范 → `spec-template.md`

## .task.yaml 字段说明

每个任务目录下的 `.task.yaml` 是任务状态文件，由 `task-state.ps1` 自动读写。字段会随版本演进，以仓库内最新样本为准（路径：`.trae/tasks/<project>/<task>/.task.yaml`）。常用字段：

| 字段 | 含义 |
|------|------|
| `workflow` | 流程类型（如 `full` 表示完整四阶段流程） |
| `phase` | 当前阶段：`plan` / `implement` / `review` / `verify` |
| `project_type` | `ue` / `web` / `other` |
| `clarification_status` | 需求澄清状态：`not_needed` / `pending` / `done` |
| `user_confirmed_plan` | Plan 是否经用户确认 |
| `router_skill_loaded` | Router skill 是否已加载 |
| `review_result` | Review 阶段结论：`pending` / `pass` / `fail` |
| `verify_result` | Verify 阶段结论：`pending` / `pass` / `fail` |
| `verification_report` | 验证报告路径（指向 `verification-report.md`） |
| `archived` | 是否已归档 |
| `base_ref` | 基线 commit SHA（用于变更范围检测） |
| `created_at` / `verified_at` | 创建 / 验证通过时间 |
| `fix_attempts` | Review/Verify 失败后的修复尝试次数 |
| `worker_profile` | `none` / `ds4-flash` 等 Worker 档案 |
| `lead_verifier` | 主验证者 SID（issuer-worker-v1 模式） |
| `repair_loop_status` | 修复循环状态：`idle` / `running` / `awaiting_approval` |
| `authority_profile` | 权限档案：`none` / `issuer-worker-v1` |
| `authority_status` | 权限状态：`legacy` / `signed` |
| `packet_version` / `packet_digest` | 任务包版本与摘要 |
| `legacy_trust` | 旧任务信任度：`legacy_untrusted` / `legacy_trusted` |
| `spec_exists` / `spec_scenario_count` / `spec_scenarios_done` | spec 文件存在与场景完成度 |
