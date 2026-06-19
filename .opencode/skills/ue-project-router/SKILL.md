---
name: "ue-project-router"
description: "多项目类型工作流入口（Comet 风格）。自动检测项目类型（UE5/Web/Other）、任务阶段、分派到对应 Skill、状态机驱动流转。输入需求自动路由到 Plan → Implement → Review → Verify 四阶段流水线。"
---

# Project Router — Comet 风格多项目工作流入口

## 定位

本 skill 是**整个工作区的唯一任务入口**，不区分项目类型，负责：

- 自动检测项目类型（UE5 游戏 / Web 应用 / 其他）
- 需求归类与主/次 skill 选择
- 任务状态初始化与 `.task.yaml` 管理
- 自动阶段检测与分派
- 多阶段自动流转（Plan → Implement → Review → Verify → Archive）

**核心原则：Plan 阶段不可跳过。任何类型的需求都必须经过分析规划才能进入实现。**

DeepSeek4Pro 会话额外遵循：`Docs/AI/16-DeepSeek4Pro-Workflow-Profile.md`

---

## Decision Core（Agent 决策核心）

### Step 0：项目类型检测（最先执行）

根据用户需求内容、工作区路径、项目文件特征自动检测项目类型：

| 检测依据 | 判定为 |
|---------|--------|
| 提到 UE、虚幻、Lyra、GAS、Blueprint、Build.cs、.uproject | **UE5 项目** |
| 提到 React/Vue/Node/Express/HTML/CSS/JS/API/数据库/前后端、有 package.json/tsconfig.json | **Web 项目** |
| 提到 ComfyUI、生成式 AI 工作流、Python 脚本 | **Web 项目**（CharacterDesignTool） |
| 多项目混合需求 | 优先以用户当前打开的文件路径所在的子项目为准 |
| 无法判定 | **AskUserQuestion** 询问项目类型 |

### Step 1：活跃任务发现与意图检测

1. 扫描 `.trae/tasks/` 目录，列出所有活跃任务（`.task.yaml` 中存在且 `archived` 不为 `true`）
2. 根据用户输入判断是新任务还是继续已有任务

| 活跃任务数 | 用户输入 | 行为 |
|-----------|---------|------|
| 无 | 新需求 | → 进入 Phase 1: Plan（初始化 .task.yaml） |
| 恰好 1 个 | 新需求描述 | → **AskUserQuestion**：继续当前任务还是创建新任务 |
| 多个 | 新需求描述 | → **AskUserQuestion**：继续已有任务（列出选择）还是创建新任务 |
| 恰好 1 个 | 无描述/继续 | → 自动选中，进入 Step 2 |
| 多个 | 无描述/继续 | → 列出任务供用户选择 |

> **IMPORTANT（紧急性声明）**
>
> 当用户选择"创建新任务"时，**必须执行 Phase 1: Plan 完整流程**。不得直接调用实现 Skill。
> 跳过 Plan 阶段会导致 `.task.yaml` 缺失，破坏后续阶段检测。

**热修复（Hotfix）检测**——用户明确描述 bug 修复 + 范围 ≤ 3 文件 + 无架构变更 → 标记为 hotfix 工作流。

### Step 2：读取 `.task.yaml` 状态元数据

读取 `.trae/tasks/<task-name>/.task.yaml`，获取当前 `phase` 和 `project_type` 字段。

**恢复规则**：
- 每次上下文恢复时，重新执行 Step 0 和 Step 1；不信任对话历史中的阶段信息
- 如果 `phase: implement` 且工作区有未提交更改，先检查归属再继续
- 如果 `phase: review` 且 `review_result: fail`，进入审查失败阻塞点：暂停并询问用户修复还是接受偏差
- 如果 `phase: plan` 但 routing.md 和 tasks.md 已完成，先运行 `task-guard.ps1 <name> plan -Apply` 修复状态再继续检测

### Step 3：阶段判定（按顺序检查，第一个命中生效）

1. `archived: true` → 工作流已完成
2. `verify_result: pass` 且 `archived` 不为 `true` → 进入 Phase 5: Archive
3. `verify_result: fail` → 验证失败阻塞点（询问用户修复或接受偏差）
4. `phase: verify` 或 tasks.md 全部打勾 → 进入 Phase 4: Verify
5. `phase: review` 或代码已提交待审查 → 调用 `code-quality-reviewer` 进入 Review
6. `phase: implement` 或有 routing.md 但代码未完成 → 调用主 Skill 进入 Implement
7. `phase: plan` 或活跃任务存在但 routing.md 不完整 → 进入 Phase 1: Plan
8. 无活跃任务 → 进入 Phase 1: Plan

---

## Phase 1: Plan（增强版 — 依赖推导 + 隐式提醒 + 架构引用）

### 步骤

#### 1a. 初始化 + 项目类型

```powershell
. .\.trae\scripts\task-env.ps1
& $TASK_STATE init <task-name> full
& $TASK_STATE set <task-name> project_type <ue5|web|other>
```

#### 1b. 需求理解与澄清

模糊信号必须追问。≤5 个核心问题。边界锁定。不合理需求指出。

#### 1c. 依赖链推导（**强制步骤**）

> 从目标反向推导前提条件。不推导不允许路由。

```
用户说"退出时提醒保存"
  ├── [P0] 保存系统存在吗？还是这次一起做？
  ├── [P0] 退出触发方式？按钮/ESC/窗口关闭？
  ├── [P0] UI 对话框组件有现成的吗？
  └── [间接] 脏状态追踪？InputAction 绑定？
```

每个 P0 依赖用户未提及 → **必须 AskUserQuestion**。

#### 1d. 隐式需求提醒（**强制步骤**）

> 用户说 A，必须主动提醒可能牵动的 B/C/D。

```
可能受牵动的系统：
├── 设置系统 — "从设置按钮退出"暗示存在设置界面
├── 存档系统 — "保存"是存设置还是游戏进度？
└── UI框架 — CommonUI/UMG？
```

即使这次不做，也记录为"已知未实现"。

#### 1e. 成熟方案搜索（**强制步骤**）

> 每个技术决策必须有引用来源。不凭空发明。

| 项目类型 | 参考来源 |
|---------|---------|
| UE5 | Lyra源码、Epic文档、UE引擎源码、`Docs/AI/` |
| Web | 框架文档、GitHub开源项目、`Docs/AI/` |

搜索项目内已有实现 + 引擎/框架原生方案。不引用 = 不允许。

#### 1f. 路由决策

### UE5 项目路由表

| 主 Skill | 适用场景 |
|----------|---------|
| `ue57-lyra-gas-ai-singleplayer` | Lyra+GAS+AI+单机玩法 |
| `ue5-auto-assistant` | 需求模糊、需先归类 |
| `ue5-cpp-gameplay` | 纯 C++、Actor/Component |
| `ue5-blueprint-workflow` | 蓝图/Enhanced Input |
| `ue5-ui-umg-slate` | UMG/Slate/CommonUI |
| `ue5-architecture` | 模块边界/Build.cs |
| `ue5-animation-guide` | 动画/状态机/RootMotion |
| `ue5-world-interaction` | 拾取/生成/交互 |
| `ue5-save-load-replication` | SaveGame（存档设计） |

次 Skill：`ue-ai-validator` / `ue5-ui-umg-slate` / `ue5-performance-packaging`

### Web 项目路由表

| 主 Skill | 适用场景 |
|----------|---------|
| `web-fullstack` | 全栈、项目搭建、架构 |
| `ui-ux-pro-max` | 纯前端 UI/UX |
| `brainstorming` | 需求模糊、技术选型 |
| `systematic-debugging` | Bug、异常排查 |
| `webapp-testing` | 前端验证、自动化测试 |
| `github-project-search` | 搜索开源参考 |

### Other 路由表

| 主 Skill | 适用场景 |
|----------|---------|
| `brainstorming` | 先探索再决定 |
| `systematic-debugging` | 调试 |
| `code-simplifier` | 重构 |

#### 1g. 子Agent调用检查

| 条件 | 必须调用 |
|------|---------|
| 架构选型 2+ 方案 | 独立 subagent |
| 涉及 AI 行为 | `ue-ai-validator` |
| 涉及 Lyra 核心类 | subagent 搜索源码 |

未调用 → routing.md 无效。

#### 1h. 创建分析文档

- `analysis.md`：依赖链推导 + 隐式需求提醒 + 架构方案引用（结构化，确保实现Agent读到）
- `spec.md`：行为规范（GIVEN/WHEN/THEN Scenarios）
- `tasks.md`：按依赖图排序的任务清单
- `routing.md`：路由决策（含 dependency_chain / implicit_requirements / architecture_references / subagent_calls 字段）

#### 1i. 用户确认（阻塞点）

**必须用 AskUserQuestion**，展示：
1. 依赖链 — 这些前提条件是否已具备？
2. 隐式需求 — 这些关联系统是否本次处理？
3. 架构方案 — 这些成熟方案是否认可？

**确认状态写回（强制）**：
- 真正发起 `AskUserQuestion` 前：`clarification_status=asked`
- 如果本轮无待确认项：`clarification_status=not_needed`
- 只有用户明确确认后才写入：
  - `user_confirmed_plan=true`
  - `router_skill_loaded=true`
  - `clarification_status=answered`（仅当本轮实际提问时）
- 用户未明确确认前：
  - `user_confirmed_plan=false`
  - **禁止调用实现 Skill**
  - **禁止任何 edit/write/apply_patch**

### 出口条件

- routing.md + tasks.md + spec.md + analysis.md 已创建
- **用户已确认**
- **阶段守卫**：

```powershell
. .\.trae\scripts\task-env.ps1
& $TASK_GUARD <task-name> plan -Apply
```

> **REQUIRED NEXT SKILL**：加载 routing.md 中指定的主 Skill。

---

## Phase 2: Implement（代码实现）

### 步骤

#### 2a. 入口验证

```powershell
. .\.trae\scripts\task-env.ps1
& $TASK_STATE check <task-name> implement
& $TASK_STATE can-edit <task-name>
```

**硬门禁规则**：
- 每次首次文件编辑前都要重新运行 `can-edit`
- `can-edit` 失败时，只允许读文件、搜索、追问用户
- 不允许靠“上文已经确认过了”绕过这一步

#### 2b. 加载实现 Skill（按项目类型分派）

**Immediately execute:** Use the Skill tool to load the main skill specified in `routing.md`. Skipping this step is prohibited.

| 项目类型 | 典型主 Skill | 嵌套触发的子 Skill |
|---------|-------------|-------------------|
| UE5 | `ue-lyra-gas-implementer` / `ue5-cpp-gameplay` | 按需求细分：`ue5-blueprint-workflow`、`ue5-animation-guide`、`ue5-architecture` 等 |
| Web | `web-implementer` → `web-fullstack` / `ui-ux-pro-max` | 按需求细分：`webapp-testing`（测试） |
| Other | `brainstorming` → 按需加载 | 无固定子 Skill |

如果指定 Skill 不可用，停止流程并提示安装或启用。**Proceeding without loading this skill is prohibited.**

**DeepSeek4Pro 固定顺序**：
1. Read state
2. Check phase
3. Run `can-edit` if implementation is requested
4. Load required agent/skill
5. Read `routing.md` / `analysis.md` / `spec.md` / `tasks.md`
6. Only then edit

Web 项目在第 4 步必须先进入 `web-implementer`。

#### 2c. 按 tasks.md 逐项实现

- 按顺序实现每项任务
- 每完成一项立即将 `- [ ]` 改为 `- [x]`
- 每完成一项提交代码

#### 2d. 项目特定验证

| 项目类型 | 验证内容 |
|---------|---------|
| UE5 | 编译验证（UnrealBuildTool），失败 ≤3 次 |
| Web | `npm run build` / `npm test` / 浏览器验证 |
| Other | 按项目配置执行 |

### 出口条件

- 所有 tasks.md 已打勾
- 代码已提交
- 项目特定验证通过
- **阶段守卫**：

```powershell
. .\.trae\scripts\task-env.ps1
& $TASK_GUARD <task-name> implement -Apply
```

### 自动流转

> **REQUIRED NEXT**：调用 `code-quality-reviewer` 进入质检阶段。

---

## Phase 3: Review（代码质检 + 初步验收）

`code-quality-reviewer` 负责，**不区分项目类型**，执行两部分：

**Part A：代码质量审查**
- 框架合规（UE5: 宏/模块/Blueprint / Web: 分层/API规范）
- 冗余分析（是否与已有实现重复）
- 安全审查（UE5: 网络复制 / Web: XSS/SQL注入）

**Part B：改动目标验收**
- 逐 Scenario 对照 spec.md 验证
- 逐 Task 对照 tasks.md 验收
- 收集编译/测试/运行证据

质检通过后：
```powershell
. .\.trae\scripts\task-env.ps1
& $TASK_GUARD <task-name> review -Apply
```

> **REQUIRED NEXT**：进入 Phase 4: Verify。

---

## Phase 4: Verify（深度验收 + 指标收集）

### 步骤

#### 4a. 入口验证

```powershell
. .\.trae\scripts\task-env.ps1
& $TASK_STATE check <task-name> verify
```

#### 4b. 加载验证 Skill（按项目类型分派）

| 项目类型 | 验证 Skill | 职责 |
|---------|-----------|------|
| UE5 | `ue-ai-validator` | AI 选型校验、编译验证、资产接线检查、回归验证 |
| Web | 本 Skill（router）直接处理 | 构建验证、测试运行、功能回归、UI 截图对比 |
| Other | 本 Skill（router）直接处理 | 按 routing.md 中指定的验证方式执行 |

#### 4c. 验证内容

| 项目类型 | 验证清单 |
|---------|---------|
| UE5 | 编译通过 → 运行时验证 → AI 选型评估 → 资产接线检查 → 回归检查 |
| Web | `npm run build` 通过 → `npm test` 通过 → 功能回归 → UI 一致性 → API 响应正确 |
| Other | 按项目配置执行，无配置时手动验证 |

#### 4d. 收集 Agent 评估指标

**每次 Verify 阶段必须收集量化指标：**

```powershell
. .\.trae\scripts\task-env.ps1
& $TASK_METRICS <task-name>
```

指标清单：
| 指标 | 计算方式 | 目标值 |
|------|---------|--------|
| **任务成功率** | done_tasks / total_tasks × 100% | ≥ 80% |
| **审查通过率** | review_result: pass 的次数 | ≥ 90% |
| **回退率** | verify-fail 触发次数 / 总任务数 | ≤ 10% |
| **活跃天数** | created_at → verified_at 的天数 | 按任务规模浮动 |
| **机械化检查违规** | Implement 阶段 Guard 中 [MECH] FAIL 的数量 | 0（必须修复） |

指标保存到 `.trae/tasks/<task-name>/metrics.yaml`。

#### 4e. 输出验收报告

验收报告写入 `.trae/tasks/<task-name>/verification-report.md`：

```powershell
$reportPath = ".trae\tasks\<task-name>\verification-report.md"
. .\.trae\scripts\task-env.ps1
& $TASK_STATE set <task-name> verification_report $reportPath
```

验收报告内容（通用结构）：
- 验证范围（覆盖了哪些任务）
- 构建/编译结果
- 测试运行结果
- 功能回归结果
- 风险与边界覆盖
- 总体评估（通过/有条件通过/不通过）

#### 4f. 用户审查（阻塞点）

**必须用 AskUserQuestion 暂停并等待用户确认验收报告。**

选项：
- "验收通过，进入归档" → 执行 Guard 流转
- "需要修复" → 记录 verify-fail，返回实现阶段

### 出口条件

- 验收报告已生成且文件存在
- 所有 tasks.md 已打勾
- 项目特定验证通过
- **用户已确认**
- **阶段守卫**：

```powershell
. .\.trae\scripts\task-env.ps1
& $TASK_GUARD <task-name> verify -Apply
```

验证失败时：
```powershell
& $TASK_STATE transition <task-name> verify-fail
```

---

## Phase 5: Archive（归档）

```powershell
. .\.trae\scripts\task-env.ps1
& $TASK_STATE transition <task-name> archived
```

---

## 阶段流转总览

```
任何项目需求
  ↓ project-router (项目类型检测 + 阶段检测)
Phase 1: Plan    → task-guard plan -Apply → phase: implement
Phase 2: Implement → task-guard implement -Apply → phase: review
  ├─ UE5:  ue-lyra-gas-implementer / ue5-cpp-gameplay / ...
  ├─ Web:  web-implementer → web-fullstack / ui-ux-pro-max / ...
  └─ Other: brainstorming → 按需加载
Phase 3: Review    → task-guard review -Apply → phase: verify (code-quality-reviewer)
Phase 4: Verify    → task-guard verify -Apply → phase: archive
  ├─ UE5:  ue-ai-validator
  ├─ Web:  router 直接处理 (npm build + test + 功能回归)
  └─ Other: 按配置执行
Phase 5: Archive   → task-state transition archived
```

## 阶段转换约束（状态机硬约束）

| 转换 | 前置条件 |
|------|---------|
| plan → implement | routing.md + tasks.md 存在且非空、用户确认 |
| implement → review | tasks.md 全部完成、代码已提交、构建通过 |
| review → verify | review_result = pass |
| verify → archive | verification_report 存在、verify_result = pass |

## 阻塞点（用户决策点）

以下节点**必须使用 AskUserQuestion 工具暂停并等待用户明确回复**：

| 位置 | 决策内容 |
|------|---------|
| Step 0 | 项目类型无法自动判定时 |
| Step 1 | 活跃任务选择（继续/新建） |
| Phase 1 Plan | routing.md + tasks.md 审查确认 |
| Phase 3 Review | 审查不通过时的修复/接受决策 |
| Phase 4 Verify | 验证失败时的修复/接受决策 |
| Phase 4 Verify | 验收报告审查确认 |

## Red Flags（Agent 自我检查清单）

| Agent 想法 | 实际风险 |
|-----------|---------|
| "用户可能会同意这个方案" | 不能替用户决定——用 AskUserQuestion |
| "这只是小改动，不需要确认" | 阻塞点无大小例外——必须等待 |
| "用户上次选了 A，这次也 A" | 历史偏好不能替代当前确认 |
| "我已经解释过计划了，用户没反对" | 无反对 ≠ 同意——必须用工具获取明确选择 |
| "验证应该没问题" | 验证未通过 ≠ 通过——检查 verify_result |
| "这应该是 UE 项目" | 不确定时必须 AskUserQuestion 询问项目类型 |

## 脚本位置

```powershell
. .\.trae\scripts\task-env.ps1

& $TASK_STATE init <task-name> <full|hotfix>
& $TASK_STATE get <task-name> <field>
& $TASK_STATE set <task-name> <field> <value>
& $TASK_STATE check <task-name> <phase>
& $TASK_STATE transition <task-name> <event>
& $TASK_GUARD <task-name> <phase> -Apply
```

## 文件结构

```
.trae/
├── tasks/
│   └── <task-name>/
│       ├── .task.yaml              # 状态文件（含 project_type 字段）
│       ├── routing.md               # 路由决策
│       ├── tasks.md                 # 任务清单
│       └── verification-report.md   # 验收报告
├── scripts/
│   ├── task-env.ps1
│   ├── task-state.ps1
│   └── task-guard.ps1
└── skills/
    └── ue-project-router/           # 本 Skill（工作流唯一入口）
```

## 优先参考

- `Docs/AI/01-AI-Development-Playbook.md`
- `Docs/AI/02-Project-Truth-Source.md`
- `Docs/AI/11-Skill-Routing-Workflow.md`
- `Docs/AI/12-MultiAgent-Workflow.md`

## 禁止事项

- 不跳过 Plan 直接进入实现
- 不在 `user_confirmed_plan=true` 之前写代码
- 不在未通过 `task-state.ps1 can-edit` 前执行 edit/write/apply_patch
- 不把多项目类型的 Skill 混用（UE Skill 不用于 Web 项目，反之亦然）
- 不在阻塞点自动决策——必须用 AskUserQuestion 获取明确选择
- 不直接输出完整实现代码（Plan 阶段）
- **不删除任何文件** — 删除前必须获得用户明确同意
- **不回退 Git 版本** — 需用户明确同意
- **不推送远程** — git push 前需用户明确同意
