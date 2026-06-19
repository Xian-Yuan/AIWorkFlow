---
name: "ue-ai-validator"
description: "UE5 项目 AI 与验证收口智能体（Comet 风格）。负责检查 StateTree/BT/EQS/SmartObject 选型、编译风险、资产接线与回归验证，含入口验证与出口守卫。由 project-router 在 UE5 项目的 Verify 阶段分派。Web 项目由 router 直接验证。"
---

# UE AI Validator — Comet 风格（UE5 专项验证 Skill）

## 定位

本 skill 是 `project-router` 的 UE5 项目验证阶段执行者，负责：

- `StateTree / Behavior Tree / EQS / SmartObject / AIController`
- 编译错误与运行时风险
- 资产接线、挂载时序与回归检查
- 验收报告生成（作为 verification_report）

> **项目类型约束**：本 Skill 仅用于 UE5 项目的 Verify 阶段。Web 项目由 `project-router` 直接执行验证（npm build + test + 功能回归）。

## 何时调用

- 需求涉及 AI 行为设计或 AI 资产绑定
- 由 `ue-project-router` 的 Phase 4: Verify 自动分派调用
- 主体实现完成后需要验证
- 出现编译错误、运行时问题、时序问题、资产接线问题

---

## 验证流程

### 0. 入口状态验证（Entry Check）

**每进入本 Skill 时，必须先执行入口验证：**

```powershell
. .\.trae\scripts\task-env.ps1
& $TASK_STATE check <task-name> verify
```

验证通过后继续。失败时脚本会输出具体原因。

### 1. 读取上下文

- 读取 `.trae/tasks/<task-name>/routing.md` 获取原始需求和路由决策
- 读取 `.trae/tasks/<task-name>/tasks.md` 获取任务清单
- 读取 `.trae/tasks/<task-name>/.task.yaml` 获取状态

### 2. AI 选型校验

**如果路由阶段指定了次 skill 为 `ue-ai-validator` 或需求涉及 AI：**

**Immediately execute:** Use the Skill tool to load the `ue57-lyra-gas-ai-singleplayer` skill. Skipping this step is prohibited.

如果 Skill 不可用，停止流程并提示安装或启用。**Proceeding without loading this skill is prohibited.**

校验内容：
- StateTree / Behavior Tree / EQS / SmartObject 选型是否合理
- AI 行为树/状态树是否正确挂载到 AIController
- EQS 查询是否配置正确（Context/Generator/Test）
- SmartObject 定义是否与交互系统兼容

### 3. 编译与运行时验证

- 执行编译验证
- 检查编译错误与警告
- 检查资产引用完整性
- 检查挂载时序（GameFeature 激活顺序）

```powershell
& "G:\UE_5.6\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe" RTS Win64 Development "g:\Project\RTS\RTS.uproject" -WaitMutex -FromMsBuild
```

### 4. 回归验证

对照改动目标逐项检查：
- 所有 tasks.md 中的任务是否完成
- 是否引入了回归问题
- 是否偏离了原始需求范围
- 是否有未覆盖的边界情况

### 5. 输出验收报告

验收报告必须写入文件：

```powershell
# 生成验收报告路径
$reportPath = ".trae\tasks\<task-name>\verification-report.md"

# 记录到状态文件
. .\.trae\scripts\task-env.ps1
& $TASK_STATE set <task-name> verification_report $reportPath
```

验收报告内容：
- 验证范围（覆盖了哪些任务）
- 编译结果（通过/失败，含错误信息）
- 运行时验证结果
- AI 选型评估（如适用）
- 资产接线检查结果
- 回归检查结果
- **Agent 评估指标**（每次 Verify 必填）：
  - 任务成功率（done/total × 100%，目标 ≥ 80%）
  - 编译通过次数 / 总尝试次数
  - 回退次数（verify-fail 触发次数）
  - 机械化检查违规数（[MECH] FAIL 数量）
  - 活跃天数
- 总体评估（通过/有条件通过/不通过）

### 5a. 收集 Agent 评估指标

在输出验收报告之前，运行指标收集脚本：

```powershell
. .\.trae\scripts\task-env.ps1
if ($TASK_METRICS) { & $TASK_METRICS <task-name> }
```

指标结果自动保存到 `.trae/tasks/<task-name>/metrics.yaml`，并将关键指标嵌入验收报告。

### 6. 用户审查（阻塞点）

验收报告生成后，**必须用 AskUserQuestion 工具暂停并等待用户确认**。

选项：
- "验收通过，进入归档" → 执行 Guard 流转
- "需要修复" → 记录 verify-fail，返回实现阶段

---

## 出口条件

- 验收报告已生成且文件存在
- 所有 tasks.md 已打勾
- 编译通过
- **用户已确认**验收报告
- **阶段守卫**：运行后全部 PASS 自动流转

```powershell
. .\.trae\scripts\task-env.ps1
& $TASK_GUARD <task-name> verify -Apply
```

状态文件自动更新为 `phase: archive`，`verify_result: pass`。

验证失败时：
```powershell
& $TASK_STATE transition <task-name> verify-fail
```
状态回退到 `phase: implement`，`verify_result: fail`。

---

## 自动流转

验收通过后：

> **REQUIRED NEXT:** 运行 `& $TASK_STATE transition <task-name> archived` 完成归档。

---

## 输出要求

必须输出：

1. AI 选型判断（如适用）
2. 主要风险点
3. 验证清单
4. 失败排查项
5. 是否建议回退重构
6. 验收报告路径

## 优先参考

- `Docs/AI/05-StateTree-BT-EQS-SmartObject.md`
- `Docs/AI/07-Test-Checklists.md`
- `Docs/AI/08-AntiPatterns.md`
- `Docs/AI/09-Agent-Handoff-Templates.md`
- `Docs/AI/10-Execution-Examples.md`
- `Docs/AI/18-Validation-Checklist.md`
- `MLCase/Docs/Guides/UE5_Error_Prevention_Guide.md`

## 禁止事项

- 不在入口验证未通过时继续（必须先 run check）
- 不把复杂伤害结算硬编码到 AI Task
- 不把多人网络逻辑作为默认答案
- 不在未确认挂载点和资产链时直接给出"可用"结论
- 不在验证失败时自动流转到 archive
- **不删除任何文件** — 删除前必须获得用户明确同意
- **不回退 Git 版本** — reset --hard / revert 等操作必须获得用户明确同意
- 除上述两项外，所有操作全权放行，不打断用户
