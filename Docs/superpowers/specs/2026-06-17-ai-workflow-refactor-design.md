# AI 工作流重构设计 Spec

日期：2026-06-17
状态：Draft，待确认后进入实现计划
负责人域：AI Workflow Harness
范围：`Docs/AI/`、`Docs/Memory/`、`skills/`、`.trae/`、`.opencode/`、任务工作流脚本

## 1. 背景

当前工作区已经形成了一套比较完整的 AI 工作流：

- `ue-project-router` 作为统一入口，负责项目类型识别、阶段判断、路由和任务初始化。
- `.task.yaml`、`routing.md`、`spec.md`、`tasks.md`、`analysis.md` 组成任务状态与交接文件。
- `task-state.ps1`、`task-guard.ps1`、`task-handoff.ps1` 负责阶段、硬门禁和交接模板。
- `Docs/AI/` 承载长期工作流规则、UE5 约束、多 Agent 协作、模型分层、回归验证等文档。
- `Docs/Memory/` 和 `failure-memory` 技能承载跨会话失败经验沉淀。

最近新增的两条线索很关键：

- `spec-living`：把任务目录中的 `spec.md` 从静态 GIVEN/WHEN/THEN 文档升级为 Living Spec，承载状态、进度、决策、变更记录和验证结果。
- `Docs/AI/26-Agent-Capability-Enhancement.md`：总结 `code-knowledge-graph`、`agent-memory-bench`、`output-compressor`、`enhanced-subagent` 四件套，代表下一轮 AI 工作流能力增强。

这些方向是对的，但现有规则散落在多个位置，部分文档、脚本和 router 说明之间已经出现漂移。本次重构的目标不是推倒重来，而是把已有能力整理成一套更清晰、更可验证、更容易被 Agent 正确读取的工作流控制面。

## 2. 当前是否已有 Spec 等文档分类机制

结论：有，但不是一套统一机制。

当前至少存在七类文档机制：

1. `Docs/AI/`：长期 AI 工作流规则和参考手册。
2. `Docs/superpowers/specs/`：正式设计 spec。
3. `Docs/superpowers/plans/`：实现计划。
4. `Docs/_shared/specs/` 与 `Docs/_shared/plans/`：共享或镜像性质的 spec / plan。
5. `.trae/tasks/<task>/` 与 `.opencode/tasks/<task>/`：运行时任务文档。
6. `skills/`、`.trae/skills/`、`.opencode/agents/`：可执行 Agent 行为说明。
7. `Docs/Memory/`：失败经验、候选记忆和索引。

问题在于：这些机制都存在，但缺少一份明确说明“谁是 canonical、谁是 mirror、谁是 runtime、谁已 deprecated、谁仍 experimental”的总表。

## 3. 现有分类规则与漂移点

### 3.1 长期 AI 工作流文档

位置：`Docs/AI/`

用途：

- AI 工作流长期规则。
- Skill 路由、多 Agent 协作、Review/Verify、模型分层。
- UE5 项目约束、编码规范、验证清单。

现有规则：

- 使用 `NN-English-Name.md` 编号命名，例如 `11-Skill-Routing-Workflow.md`。
- `Docs/AI/README.md` 作为索引。
- `Docs/AI/.cache-manifest.md` 对部分文档做 stable / volatile 分类。

漂移点：

- `Docs/AI/README.md` 没有完整索引当前所有文档。
- `Docs/AI/.cache-manifest.md` 未覆盖较新的 `25` 和 `26`。
- `Docs/AI/13-File-Placement-Convention.md` 中部分“当前最大编号”等描述已经过期。

### 3.2 正式设计 Spec

位置：

- `Docs/superpowers/specs/`
- `Docs/_shared/specs/`

用途：

- 在实现前沉淀正式设计。
- 描述目标、范围、非目标、设计方案、场景和验证策略。

现有规则：

- `skills/brainstorming/SKILL.md` 规定设计文档写入：
  - `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
- 历史上部分共享工作流 spec 也同时出现在 `Docs/_shared/specs/`。

漂移点：

- `Docs/superpowers/specs/` 与 `Docs/_shared/specs/` 的 canonical / mirror 关系未明确定义。
- 重复文档缺少同步策略，未来可能出现内容不一致。

### 3.3 实现计划

位置：

- `Docs/superpowers/plans/`
- `Docs/_shared/plans/`
- 领域目录，例如 `Docs/airpgweb/plans/`

用途：

- 在设计 spec 被确认后，拆解可执行实现步骤。
- 记录修改顺序、验证命令、风险和回滚点。

现有规则：

- `skills/writing-plans/SKILL.md` 使用带日期的 plan 文件名。
- `Docs/_shared/plans/` 保存过共享工作流实现计划。

漂移点：

- plan 应该如何从 spec 派生、何时放入 `_shared`，目前依赖隐式习惯。

### 3.4 运行时任务 Spec

位置：

- `.trae/tasks/<task-name>/spec.md`
- `.opencode/tasks/<task-name>/spec.md`

用途：

- 记录单个任务的行为契约和执行状态。
- 旧模式偏 GIVEN/WHEN/THEN 场景。
- 新模式是 Living Spec。

现有规则：

- `.opencode/tasks/README.md` 定义任务目录包含：
  - `.task.yaml`
  - `routing.md`
  - `spec.md`
  - `tasks.md`
  - `analysis.md`
- `skills/spec-living/SKILL.md` 定义 Living Spec 结构。
- `skills/spec-tracker/SKILL.md` 已标记为 deprecated。

漂移点：

- `spec-living` 是新方向，但 `skills/ue-project-router/SKILL.md` 等活动路由说明仍有 `spec-tracker.ps1` 引用。
- `spec-tracker` 的弃用状态没有完全传导到 router 和脚本调用层。

### 3.5 Agent 行为文档

位置：

- `skills/`
- `.trae/skills/`
- `.opencode/agents/`

用途：

- 定义 Agent 角色、路由规则、实现约束、验证职责。
- OpenCode Agent 与 Trae Skill 之间存在镜像或适配关系。

现有规则：

- `ue-project-router` 是唯一入口。
- 具体执行由实现、验证、质量审查等 Agent 接力。

漂移点：

- 新文档中有 `.agents/skills/...` 的引用，但当前实际活跃 skill 根更接近 `skills/...`。
- 已归档 skill 和活跃 skill 在部分说明中边界不够明显。

### 3.6 机械门禁与脚本

位置：

- `.trae/scripts/`
- `.opencode/scripts/`

用途：

- 任务状态转换。
- Can-Edit 硬门禁。
- 阶段交接。
- 回归验证。
- Memory 检索和工作流辅助。

现有规则：

- `.trae/scripts/task-state.ps1` 是较完整的状态机。
- `.opencode/scripts/task-state.ps1` 是 OpenCode 侧兼容实现。

漂移点：

- `.trae` 的 Can-Edit 检查包含 `phase`、`user_confirmed_plan`、`router_skill_loaded`、spec warning 等信息。
- `.opencode` 的 Can-Edit 逻辑更弱，主要检查 `phase != plan` 和 `user_confirmed_plan=true`，没有完全对齐 router proof 和 clarification 状态。

### 3.7 Memory 层

位置：`Docs/Memory/`

用途：

- 记录失败经验。
- 管理 memory candidate。
- 为 Plan / Review / Verify 阶段提供可检索经验。

现有规则：

- `Docs/Memory/indexes/memory-index.md` 是失败记忆索引。
- `failure-memory` skill 负责跨会话检索和记录。

漂移点：

- `agent-memory-bench` 方向已经出现，但当前 failure 样本不足，直接跑 benchmark 会得到“数据不足”，这应该被表达为健康状态，而不是模糊失败。

## 4. 问题陈述

当前 AI 工作流的问题不是“没有规则”，而是“规则太分散，且新旧机制并存”。

主要风险：

1. 发现风险：Agent 可能读到过期规则，并把 deprecated 机制当成当前机制。
2. 执行风险：Trae 与 OpenCode 对同一任务可能给出不同 Can-Edit 判断。
3. 验证风险：能力增强已经写入总结，但还没有全部进入健康检查和回归测试。
4. 分类风险：spec、plan、runtime spec、workflow doc、memory doc 的边界没有统一总表。

## 5. 目标

1. 建立一份明确的 AI 工作流文档分类规则。
2. 明确 `Docs/superpowers/specs/` 是正式设计 spec 的主位置。
3. 明确 `Docs/_shared/specs/` 是共享镜像或历史共享区，而不是默认 canonical。
4. 推动 `spec-living` 成为运行时任务 spec 的主机制。
5. 保留 `spec-tracker`，但只作为 deprecated compatibility shim。
6. 对齐 `.trae` 与 `.opencode` 的 Can-Edit 门禁语义。
7. 把四件套能力增强纳入可发现、可检查、可回归的工作流组件。
8. 更新 README、cache manifest 和 file placement 规则，减少 Agent 误读。

## 6. 非目标

- 不重写整个工作流系统。
- 不删除历史任务目录。
- 不批量迁移所有旧任务 spec。
- 不修改 UE5 或 Web 项目业务代码。
- 不在本轮引入数据库型 Memory 系统。
- 不把 `Docs/AI/01-AI-Development-Playbook.md` 直接废弃。

## 7. 设计方案

### 7.1 新增 AI 工作流重构 Manifest

新增：

- `Docs/AI/27-AI-Workflow-Refactor-Manifest.md`

用途：

- 作为本轮重构后的短入口。
- 标记 active / deprecated / experimental 组件。
- 给出文档分类总表。
- 指向当前 router、scripts、Living Spec、Memory、capability enhancement 和 regression 入口。

它不替代详细文档，只负责帮 Agent 快速选对入口。

### 7.2 统一文档分类表

采用以下分类：

| 类型 | 位置 | 用途 | 规则 |
|---|---|---|---|
| AI 工作流手册 | `Docs/AI/NN-*.md` | 长期规则和参考 | 编号命名，写入 `README.md`，进入 `.cache-manifest.md` |
| 正式设计 spec | `Docs/superpowers/specs/YYYY-MM-DD-*-design.md` | 实现前设计 | 新工作流设计默认写这里 |
| 共享 spec 镜像 | `Docs/_shared/specs/` | 跨工具共享或历史镜像 | 只有需要共享时才镜像 |
| 实现计划 | `Docs/superpowers/plans/YYYY-MM-DD-*-plan.md` | 执行步骤 | 必须链接回设计 spec |
| 共享计划镜像 | `Docs/_shared/plans/` | 跨工具共享计划 | 只有需要共享时才镜像 |
| 运行时任务文档 | `.trae/tasks/<task>/`、`.opencode/tasks/<task>/` | 单任务状态 | 包含 `.task.yaml`、`routing.md`、`spec.md`、`tasks.md`、`analysis.md` |
| Living Spec | `.trae/tasks/<task>/spec.md`、`.opencode/tasks/<task>/spec.md` | 当前任务真实状态 | 使用 `spec-living` 结构 |
| Agent 行为说明 | `skills/`、`.trae/skills/`、`.opencode/agents/` | 可执行行为规则 | 活跃路由不得默认引用 archived skill |
| 机械门禁脚本 | `.trae/scripts/`、`.opencode/scripts/` | 状态、门禁、交接、回归 | 必须可回归验证 |
| Memory 文档 | `Docs/Memory/` | 失败经验和候选记忆 | 由 memory index 和脚本检索 |

### 7.3 Living Spec 迁移

`spec-living` 成为任务 `spec.md` 的主机制。

需要调整：

- router 初始化任务时使用 `spec-living.ps1`。
- handoff 模板读取并总结 Living Spec 状态。
- active docs 不再把 `spec-tracker.ps1` 写成主路径。
- `spec-tracker` 保留在 deprecated / compatibility 章节。
- 旧 GIVEN/WHEN/THEN 场景不丢弃，迁入 Living Spec 的行为或验证章节。

### 7.4 Can-Edit 门禁对齐

`.opencode/scripts/task-state.ps1` 应对齐 `.trae/scripts/task-state.ps1` 的最小语义。

Can-Edit 至少要求：

- `phase` 不是 `plan`。
- `user_confirmed_plan` 为 true。
- `router_skill_loaded` 为 true。
- 如果存在 `clarification_status`，必须满足进入实现的状态。
- spec warning 不能在 Plan 未完成时被静默跳过。

### 7.5 能力增强健康化

`Docs/AI/26-Agent-Capability-Enhancement.md` 中四件套需要从“总结”变成“可检查组件”：

- `code-knowledge-graph`：代码知识图谱生成与漂移检查。
- `agent-memory-bench`：Memory 检索质量基准。
- `output-compressor`：长输出、handoff、上下文压缩策略。
- `enhanced-subagent`：子 Agent 派发、证据返回和隔离策略。

每个组件需要明确：

- owner 文档。
- 脚本入口。
- 健康检查命令。
- 回归场景。
- 已知失败模式。

### 7.6 回归验证扩展

扩展 `.trae/scripts/test-workflow-regression.ps1`：

- S06：`spec-living` 是活跃机制，新任务不再通过 `spec-tracker` 初始化。
- S07：OpenCode Can-Edit 在缺少 router proof 时阻止实现。
- S08：文档索引包含当前 AI workflow 文档。
- S09：code graph 能处理真实项目名，且不会把目录当源码文件读取。
- S10：memory benchmark 在数据不足时输出清晰 health state。

## 8. 行为场景

### 场景 A：Agent 能找到当前 Spec 规则

GIVEN Agent 需要创建正式工作流 spec  
WHEN 它读取文档分类规则  
THEN 它能识别 `Docs/superpowers/specs/YYYY-MM-DD-*-design.md` 是主位置  
AND 它能知道 `Docs/_shared/specs/` 只在需要共享或镜像时使用。

### 场景 B：新任务使用 Living Spec

GIVEN 一个新任务被初始化  
WHEN router 创建任务文档  
THEN `spec.md` 使用 Living Spec 结构  
AND 原有 GIVEN/WHEN/THEN 行为场景被保留在合适章节。

### 场景 C：Deprecated Spec Tracker 不再是主路径

GIVEN Agent 读取 active router 文档  
WHEN 文档描述 spec 生命周期  
THEN 它指向 `spec-living.ps1`  
AND 只在 deprecated / compatibility 语境中提到 `spec-tracker`。

### 场景 D：OpenCode 与 Trae 门禁一致

GIVEN 任务中 `user_confirmed_plan: true`  
AND `router_skill_loaded: false`  
WHEN 执行 OpenCode Can-Edit  
THEN 它必须像 Trae 一样拒绝进入实现。

### 场景 E：能力组件健康状态明确

GIVEN memory benchmark 样本不足  
WHEN 执行健康检查  
THEN 输出应明确为 insufficient-data  
AND 不应表现为脚本崩溃或未知失败。

## 9. 实现分期

### Pass 1：文档分类与入口整理

- 新增 `Docs/AI/27-AI-Workflow-Refactor-Manifest.md`。
- 更新 `Docs/AI/README.md`。
- 更新 `Docs/AI/.cache-manifest.md`。
- 修正 `Docs/AI/13-File-Placement-Convention.md` 中过期描述。

### Pass 2：Living Spec 迁移

- 将 active router / handoff 文档从 `spec-tracker` 更新到 `spec-living`。
- 保留 `spec-tracker` 的 deprecated 说明。
- 确认新任务初始化不会走旧主路径。

### Pass 3：门禁对齐

- 对齐 `.opencode/scripts/task-state.ps1` 与 `.trae/scripts/task-state.ps1` 的 Can-Edit 逻辑。
- 增加 router proof 和 clarification 状态测试。

### Pass 4：能力增强健康检查

- 修复 code graph 对真实项目名和目录枚举的处理。
- 改善 memory benchmark 数据不足输出。
- 在 manifest 中记录四件套健康检查命令。

### Pass 5：回归验证

- 扩展 workflow regression 场景。
- 跑完整回归。
- 在计划或最终验证记录中写明结果。

## 10. 验证标准

实现完成必须满足：

- `Docs/AI/27-AI-Workflow-Refactor-Manifest.md` 存在。
- `Docs/AI/README.md` 索引 `25`、`26`、`27`。
- `Docs/AI/.cache-manifest.md` 分类 `25`、`26`、`27`。
- active router 文档以 `spec-living` 为主机制。
- `spec-tracker` 只出现在 deprecated / compatibility 语境。
- `.trae` 与 `.opencode` Can-Edit 对危险状态给出一致拒绝。
- workflow regression 通过。
- code graph 针对现有项目能成功检查，或输出清晰的项目配置错误。
- memory benchmark 在样本不足时输出清晰状态。

## 11. 开放问题

1. `Docs/_shared/specs/` 应继续作为镜像区，还是收敛为历史共享归档区？
2. `Docs/AI/27-AI-Workflow-Refactor-Manifest.md` 是否要成为 `AGENTS.md` 之后的 AI 工作流第一入口？
3. 历史任务 `spec.md` 是 lazy migration，还是做一次性批量迁移？
4. `code-knowledge-graph` 是否要保留 `RTS -> LyraStarterGame - 5.7` 这类项目别名，还是彻底清理旧项目名？

## 12. 推荐决策

第一轮实现建议：

- `Docs/superpowers/specs/` 作为正式设计 spec 主位置。
- `Docs/_shared/specs/` 暂时保留为可选镜像或历史共享区。
- `Docs/AI/27-AI-Workflow-Refactor-Manifest.md` 作为本轮重构入口，不替代完整 playbook。
- 旧任务 spec 采用 lazy migration。
- active docs 和 router 调用从 `spec-tracker` 切到 `spec-living`。
- 先补回归，再做广泛清理。

