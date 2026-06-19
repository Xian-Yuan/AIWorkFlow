---
name: "ue-lyra-gas-implementer"
description: "UE5 项目的 Lyra/GAS 主体实现智能体（Comet 风格）。负责把需求落到 GameFeature、Experience、PawnData、AbilitySet、GA/GE/AS 等主链路，含入口验证、嵌套 Skill 触发、自动流转。由 project-router 检测到 UE5 项目类型后分派。"
---

# UE Lyra GAS Implementer — Comet 风格（UE5 专项实现 Skill）

## 定位

本 skill 是 `project-router` 的 UE5 项目实现阶段执行者，负责 Lyra/GAS 主链落地：

- `GameFeature / Experience / PawnData / InputConfig / AbilitySet`
- `GameplayAbility / GameplayEffect / AttributeSet / GameplayCue / AbilityTask`
- `Equipment / Weapon / Interaction` 与能力链的接入

> **项目类型约束**：本 Skill 仅用于 UE5 项目。Web/Other 项目由 `web-fullstack` / `brainstorming` 等其他 Skill 承接。

## 何时调用

- 需求核心落在 Lyra/GAS
- 需要同时输出代码、配置、数据资产与挂载点
- 需要按项目单机规则落地玩法功能
- 由 `ue-project-router` 的 Phase 2: Implement 自动分派调用

---

## 步骤

### 0. 入口状态验证（Entry Check）

**每进入本 Skill 时，必须先执行入口验证：**

```powershell
. .\.trae\scripts\task-env.ps1
& $TASK_STATE check <task-name> implement
```

验证通过后继续。失败时脚本会输出具体原因。

**幂等性**：所有操作可安全重执行。读取 `.task.yaml` 确认仍在 implement 阶段，读取 tasks.md 找到第一个未打勾任务。已提交的任务不得重复提交。

### 1. 读取任务上下文

读取 `.trae/tasks/<task-name>/routing.md` 获取：
- 主 skill 路由决策
- 需求归类
- 必读文档清单

读取 `.trae/tasks/<task-name>/tasks.md` 获取任务清单。

### 2. 加载专项 Skill（嵌套触发）

**根据需求类型，必须使用 Skill tool 加载对应专项 Skill。不得以普通对话替代。**

| 需求类型 | 必须加载的 Skill | 触发指令 |
|---------|-----------------|---------|
| C++ 类实现 | `ue5-cpp-gameplay` | **Immediately execute:** Use the Skill tool to load the `ue5-cpp-gameplay` skill. Skipping this step is prohibited. |
| 蓝图接线 | `ue5-blueprint-workflow` | **Immediately execute:** Use the Skill tool to load the `ue5-blueprint-workflow` skill. Skipping this step is prohibited. |
| AI 行为 | `ue57-lyra-gas-ai-singleplayer` | **Immediately execute:** Use the Skill tool to load the `ue57-lyra-gas-ai-singleplayer` skill. Skipping this step is prohibited. |
| UI 相关 | `ue5-ui-umg-slate` | **Immediately execute:** Use the Skill tool to load the `ue5-ui-umg-slate` skill. Skipping this step is prohibited. |
| 动画相关 | `ue5-animation-guide` | **Immediately execute:** Use the Skill tool to load the `ue5-animation-guide` skill. Skipping this step is prohibited. |
| 架构设计 | `ue5-architecture` | **Immediately execute:** Use the Skill tool to load the `ue5-architecture` skill. Skipping this step is prohibited. |
| 世界交互 | `ue5-world-interaction` | **Immediately execute:** Use the Skill tool to load the `ue5-world-interaction` skill. Skipping this step is prohibited. |

如果所需 Skill 不可用，停止流程并提示安装或启用对应 Skill。**Proceeding without loading this skill is prohibited.**

### 3. 按 tasks.md 逐项实现

- 按顺序实现 tasks.md 中的每项任务
- 每完成一项立即将 `- [ ]` 改为 `- [x]`
- 每完成一项提交代码（commit message 反映设计意图）
- 遵循 UE5 编码规范（见 `Docs/AI/14-Coding-Standards.md`）

### 4. 编译验证

```powershell
& "G:\UE_5.6\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe" RTS Win64 Development "g:\Project\RTS\RTS.uproject" -WaitMutex -FromMsBuild
```

编译失败不得超过 3 次，超限触发降级回退到 Plan 阶段。

### 5. 上下文恢复

实现是最长阶段，可能跨多次对话。支持恢复：

- **每项任务完成后**：立即打勾 tasks.md 并提交代码，确保状态持久化
- **上下文压缩恢复时**：先运行 `& $TASK_STATE check <task-name> implement --recover`，脚本输出当前任务进度和恢复建议
- **长任务拆分**：单个任务超过 200 行代码变更时考虑拆分为多个子任务

---

## 出口条件

- 所有 tasks.md 已打勾
- 代码已提交
- 编译通过
- **阶段守卫**：运行后全部 PASS 自动流转

```powershell
. .\.trae\scripts\task-env.ps1
& $TASK_GUARD <task-name> implement -Apply
```

状态文件自动更新为 `phase: review`，`review_result: pending`。

---

## 自动流转

出口条件满足后，自动流转到审查阶段：

> **REQUIRED NEXT SKILL:** 调用 `code-quality-reviewer` Agent 进入质检阶段。
>
> 如果启用了多 Agent，同时调用 `ue-ai-validator` 进行 AI 行为验证。

---

## 输出要求

必须输出：

1. 需求映射
2. 架构方案
3. 文件清单
4. 配置步骤
5. 验证清单
6. 文档更新项

## 优先参考

- `Docs/AI/01-AI-Development-Playbook.md`
- `Docs/AI/03-Singleplayer-Lyra-GAS-Rules.md`
- `Docs/AI/04-Asset-Checklists.md`
- `Docs/AI/14-Coding-Standards.md`
- `Docs/Lyra/*`
- `Docs/GAS/*`
- `Docs/APIRef/*`
- `Docs/CodeTemplates/*`
- `Docs/UE5.7/02-LyraUpgrade.md`

## 禁止事项

- 不主动引入复制、RPC、Prediction 作为默认方案
- 不绕过 `PawnData / AbilitySet / InputConfig / Experience` 直接硬连主链
- 不在未加载专项 Skill 的情况下直接编码（必须用 Skill tool 加载）
- **不删除任何文件** — 删除前必须获得用户明确同意
- **不回退 Git 版本** — reset --hard / revert 等操作必须获得用户明确同意
- 除上述两项外，所有操作全权放行，不打断用户
