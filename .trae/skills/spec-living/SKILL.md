---
name: "spec-living"
description: "Living Spec 生命周期管理——把 spec.md 从静态设计文档升级为活着的项目状态文件。任何 AI 打开它就能在 30 秒内理解项目全貌。"
---

# Spec Living

## 定位

把 `.trae/tasks/<name>/spec.md`（fallback: `.opencode/tasks/<name>/spec.md`）从"静态设计文档"升级为"活着的项目状态文件"。

核心原则：**Spec is the living single source of truth. Any AI, at any time, can open it and understand the project in 30 seconds.**

## 脚本

`spec-living.ps1` 位于 `.trae/scripts/spec-living.ps1`，模板位于 `.trae/scripts/spec-living-template.md`。

## 命令速查

| 命令 | 用途 | 阶段 |
|------|------|------|
| `spec-living.ps1 init -TaskName <name>` | 从模板创建 Living Spec | Plan |
| `spec-living.ps1 task -TaskName <name> -TaskId T1 -Status done -ScenarioId S01` | 更新 task 状态 + 关联 Scenario | Implement |
| `spec-living.ps1 decide -TaskName <name> -Decision "..." -Rationale "..." -Impact "..."` | 记录关键决策 | 任何阶段 |
| `spec-living.ps1 changelog -TaskName <name> -File "..." -ChangeType Modified -Description "..."` | 记录文件变更 | Implement |
| `spec-living.ps1 verify -TaskName <name> -Check Compile -VerifyStatus pass -Detail "117 modules, 1.37s"` | 更新验证状态 | Verify |
| `spec-living.ps1 status -TaskName <name>` | 刷新进度计数 + 同步 phase | 任何阶段 |
| `spec-living.ps1 onboard -TaskName <name>` | 打印接手报告（30 秒理解全貌） | SessionStart |

## spec.md 结构（由 spec-living-template.md 定义）

```markdown
# <task-name> — Living Spec

## Quick Status (AI Entry Point)
- **Current Phase**: Plan / Implement / Review / Verify / Complete
- **Last Updated**: YYYY-MM-DD HH:MM
- **Progress**: N/M tasks done
- **Next Step**: Task X — description
- **Blockers**: None / description

## Design Overview
### Architecture
### Core Scenarios (S01, S02, ... GIVEN/WHEN/THEN)

## Implementation Progress
| Task ID | Description | Scenario | Status | Completed |

## Key Decisions
| Date | Decision | Rationale | Impact |

## Change Log
| Date | File | Change Type | Description |

## Verification Status
| Check | Status | Detail |
| Compile / Test / Runtime | PASS / FAIL / — | evidence |
```

## 操作规则

### 规则 1：创建 spec（Plan 阶段）

Router 完成 routing.md 后：
```powershell
.trae\scripts\spec-living.ps1 init -TaskName <name>
```
自动从 `spec-living-template.md` 创建，填充任务名和日期。

### 规则 2：更新进度（Implement 阶段）

每完成一个 task：
```powershell
.trae\scripts\spec-living.ps1 task -TaskName <name> -TaskId T1 -Status done -ScenarioId S01
```
自动更新：task 行状态、Scenario 状态、进度计数、Next Step、Last Updated。

### 规则 3：记录决策（任何阶段）

当做出技术选型/架构变更/方案转弯/设计约束决策时：
```powershell
.trae\scripts\spec-living.ps1 decide -TaskName <name> -Decision "StateTree 替代 BT" -Rationale "单机轻量决策" -Impact "AIController 需绑定 StateTreeComponent"
```

### 规则 4：记录变更（Implement 阶段）

每次文件修改后：
```powershell
.trae\scripts\spec-living.ps1 changelog -TaskName <name> -File "RSCharacter.h" -ChangeType Added -Description "添加 GAS 接口"
```
ChangeType: Added / Modified / Deleted

### 规则 5：更新验证（Verify 阶段）

验证完成后：
```powershell
.trae\scripts\spec-living.ps1 verify -TaskName <name> -Check Compile -VerifyStatus pass -Detail "117 modules, 1.37s"
.trae\scripts\spec-living.ps1 verify -TaskName <name> -Check Test -VerifyStatus pass -Detail "179/179"
.trae\scripts\spec-living.ps1 verify -TaskName <name> -Check Runtime -VerifyStatus fail -Detail "PIE crash on level load"
```

### 规则 6：新 Agent 接手协议（SessionStart）

任何 Agent 在 SessionStart 时必须：
```powershell
.trae\scripts\spec-living.ps1 onboard -TaskName <name>
```
输出 30 秒可读的接手报告：Phase、Progress、Next Step、Decisions 数、Scenarios 数、Blockers、验证状态。

### 规则 7：spec.md 与 .task.yaml 同步

`spec-living.ps1 status` 自动从 `.task.yaml` 读取 phase 并同步到 spec.md。不一致时以 `.task.yaml` 为准。

## 与 spec-tracker（已废弃）的区别

| 维度 | spec-tracker（旧） | spec-living（新） |
|------|-------------------|-------------------|
| 定位 | Scenario 进度追踪工具 | 项目状态全景文件 |
| 内容 | Scenario + Task 映射 | Quick Status + Design + Progress + Decisions + Change Log + Verification |
| 读取时间 | 需要读多个文件 | 30 秒理解全貌（onboard 命令） |
| 决策记录 | 无 | Key Decisions 表（日期+决策+理由+影响） |
| 修改日志 | 仅 Change Log | 文件级修改日志（含时间戳和 ChangeType） |
| 验证状态 | 无 | Compile/Test/Runtime 三维验证 |
| 脚本 | spec-tracker.ps1（未实现） | spec-living.ps1（7 命令，全部实现） |

## 集成点

| 集成对象 | 方式 |
|---------|------|
| `task-orchestrator` | always_on_skills 包含 spec-living；SessionStart 执行 onboard |
| `subagent-driven-development` | Task 完成 → spec-living task；文件变更 → spec-living changelog |
| `phase-machine` | onboarding 读 spec.md Quick Status；phase transition 时 spec-living status 同步 |
| `task-handoff.ps1` | handoff 模板包含 spec-living onboard 输出 |
| `anti-degradation` | Change Log 用于检测 drift；Decisions 用于检测方案大转弯 |
| `engine-config.json` | always_on_skills: ["spec-living"] |

## 禁止事项

- 不让 spec.md 的 Current Phase 与 .task.yaml 长期不一致
- 不做决策但不记录（任何技术选型必须写入 Key Decisions）
- 不跳过接手协议（新 Agent 必须先 spec-living onboard）
- 不让 Verification Status 长期为空
- 不删除历史决策记录（即使方案已废弃，保留作为上下文）

## 维护

- 当 spec.md 超过 500 行时，将旧决策记录归档到 `decisions-archive.md`
- 当任务完成后，spec.md 保留作为项目历史记录
- 模板变更时，更新 `.trae/scripts/spec-living-template.md`
