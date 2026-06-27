# 46 — LLM 强制执行框架 (Enforcement Framework)

> **日期**: 2026-06-26
> **状态**: Active
> **真相源**: 本文档定义三层强制执行架构，解决"Agent 自觉调用"不可靠的根本问题
> **核心脚本**: `.trae/scripts/contract-verify.ps1`
> **关联记忆**: `Docs/Memory/candidates/2026-06-20-mechanical-gate-gap.md`

---

## 1. 问题诊断

### 1.1 核心问题

当前 jinli 项目的所有门禁（task-guard、task-state can-edit、doc-guard）都是**软门禁**——依赖 Agent 在正确时机主动调用。没有一层代码在 Agent 尝试违规操作时拦截它。

### 1.2 三道裂缝

| 裂缝 | 表现 | 根因 |
|------|------|------|
| Agent 自觉调用 = 没有保证 | 门禁写在 Skill 文档里，LLM 可以选择不跑 | 没有平台级 Hook 拦截 |
| Skill 文档是"指导"而非"契约" | 400+ 行 SKILL.md，LLM 抓大意跳细节 | 长文档天然被压缩，没有结构化验证 |
| 没有违规检测闭环 | Agent 绕过门禁后无人发现 | audit-gate-violations 只做事后扫描，不做实时拦截 |

### 1.3 已有识别

`Docs/Memory/candidates/2026-06-20-mechanical-gate-gap.md` 已识别此问题。

---

## 2. 三层强制执行架构

```
┌─────────────────────────────────────────────────────┐
│ Layer 3: 平台 Hook 层（硬门禁）                       │
│   PreToolUse / PreEdit 拦截                          │
│   平台支持时自动触发 contract-verify                   │
│   ↕ 平台不支持时退化为 Layer 2                         │
├─────────────────────────────────────────────────────┤
│ Layer 2: 契约验证层（中门禁）— 本框架核心              │
│   contract.yaml + contract-verify.ps1                │
│   每阶段自动验证所有契约项                             │
│   违规 → 阻断 + 记录 + 报告                           │
├─────────────────────────────────────────────────────┤
│ Layer 1: Agent 纪律层（软门禁）— 已有，已强化          │
│   Skill 检查点声明 + 禁止跳步规则                      │
│   Agent 在回复中声明检查点状态                         │
│   作为 Layer 2 的审计输入                             │
└─────────────────────────────────────────────────────┘
```

### 设计原则

1. **Additive only** — 不删除、不重排任何已有步骤，只增加验证层
2. **Mechanical > Voluntary** — 能用脚本验证的，不依赖 Agent 自觉
3. **Fail-loud** — 违规必须被检测和报告，不允许静默通过
4. **Graceful degradation** — Layer 3 不可用退化为 Layer 2，Layer 2 不可用退化为 Layer 1
5. **Zero trust** — 不信任 Agent 的"我检查过了"，只信任脚本的验证结果

---

## 3. Layer 2 契约验证层（核心实现）

### 3.1 contract.yaml

每个任务包根目录自动生成契约声明文件。

**生成命令**:
```powershell
& .\.trae\scripts\contract-verify.ps1 <task-name> init
```

**结构**:
```yaml
task_name: <task-name>
project_type: ue5 | web | other
generated_at: <timestamp>

plan_contracts:
  - id: PC01
    description: "task-state initialized"
    verify_type: file_exists
    verify_path: ".task.yaml"
    blocking: true
  - id: PC02
    description: "Mature Solution Evidence"
    verify_type: content_pattern
    verify_path: "analysis.md"
    verify_pattern: "Mature Solution Evidence"
    blocking: true
  # ... 更多 Plan 阶段契约项

implement_contracts:
  - id: IC01
    description: "can-edit passed"
    verify_type: command
    verify_command: "can-edit"
    verify_expected_exit: 0
    blocking: true
  # ... 更多 Implement 阶段契约项

verify_contracts:
  - id: VC01
    description: "verification-report.md exists"
    verify_type: file_exists
    verify_path: "verification-report.md"
    blocking: true
  # ... 更多 Verify 阶段契约项
```

### 3.2 contract-verify.ps1

| 命令 | 用途 | 说明 |
|------|------|------|
| `init` | 生成 contract.yaml | 自动根据 .task.yaml 中的 project_type 生成 |
| `verify` | 验证当前阶段所有契约项 | blocking 失败 → BLOCKED 输出；-Strict 时 exit 1 |
| `report` | 生成完整验证报告 | 输出 contract-report.md，含所有契约项状态 |

### 3.3 verify_type 类型

| verify_type | 说明 | 必需字段 |
|------------|------|---------|
| `file_exists` | 文件存在且非空 | `verify_path` |
| `content_pattern` | 文件包含正则模式 | `verify_path`, `verify_pattern` |
| `content_pattern_absent` | 文件不包含模式 | `verify_path`, `verify_pattern` |
| `yaml_field` | YAML 字段匹配预期值 | `verify_path`, `verify_field`, `verify_expected` |
| `command` | 命令退出码匹配预期 | `verify_command`, `verify_expected_exit` |

### 3.4 与已有脚本的关系

contract-verify.ps1 不替代 task-guard.ps1，而是封装它：
- `verify_type: command` 可以调用 task-guard.ps1 作为验证命令
- `verify_type: yaml_field` 可以检查 .task.yaml 中的字段
- 契约验证在 task-guard 之上增加了一层声明式、可审计的验证

---

## 4. Layer 1 强化：检查点声明 + 禁止跳步

### 4.1 检查点声明

在 Plan Agent (金璃小天才) 和 Implement Agent (金璃好帮手) 的 Skill 中，Agent 必须在回复中声明检查点状态：

```markdown
## 执行检查点

| Checkpoint | 状态 | 证据 |
|-----------|------|------|
| CP-INIT | ✅/❌ | task-state init 输出 |
| CP-SEARCH | ✅/❌ | 检索到的设计文档 |
| CP-CLASSIFY | ✅/❌ | deep/fast + 理由 |
| CP-MATURE | ✅/❌ | Mature Solution Evidence |
| CP-CONFIRM | ✅/❌ | 用户原话 |
| CP-GATE | ✅/❌ | task-guard plan 输出 |
```

**任何 ❌ = Agent 不得继续下一步。**

### 4.2 禁止跳步规则

```
⛔ STEP ORDER IS MANDATORY. Skipping any step is a HARD VIOLATION.
If you cannot complete a step, STOP and report the blockage.
NEVER proceed past a failed step. NEVER silently skip a step.
```

### 4.3 虚假声明检测

如果 Agent 声明 ✅ 但 contract-verify.ps1 验证 ❌，这是最严重的违规（虚假声明）。contract-report.md 中会标记 `[FALSIFIED]`。

---

## 5. Layer 3：平台 Hook 层（未来）

### 5.1 Codex 适配

Codex 目前没有原生 Hook 系统。当前方案：
1. AGENTS.md 声明：任何文件编辑前，必须先运行 `contract-verify.ps1 <task> verify -Strict`
2. codex-project-router/SKILL.md 强化此规则
3. 未来 Codex 支持 Hook 时，自动注入

### 5.2 OpenCode 适配

如果 OpenCode 支持 PreToolUse 拦截，在工具调用前自动注入 contract-verify 检查。

### 5.3 Hermes 适配

Hermes 的 desktop-commander MCP Server 可在文件写入前增加拦截。

---

## 6. 强制执行流程

### 6.1 Plan 阶段

```
 ## 6. 完整强制执行流程（含多 Agent 协作）

 以下流程覆盖从"用户输入需求"到"验证完成"的完整链路，
 包含主 Agent 路由、Skill 按需加载、子 Agent 派发、契约验证。

 ### 6.1 入口：主 Agent（金璃小天才）接收需求

 ```
 用户输入需求
   → [Soul Init] soul_init(ide)
   → [Soul Sync] soul_auto + response_plan
   → Step 0: 项目类型检测（UE5 / Web / Other）
   → Step 1: 活跃任务发现（.trae/tasks/ 扫描）
   → Step 1a: 初始化任务包
        & task-state.ps1 init <task> full
        & contract-verify.ps1 <task> init          ← 新增：生成 contract.yaml
 ```

 ### 6.2 Plan 阶段：逐步执行 + 契约保障

 ```
 Step 1b: 设计文档检索
   → [契约保障] contract.yaml PC02 要求 analysis.md 含 "Mature Solution Evidence"
   → 检索 Docs/superpowers/specs/ + Docs/superpowers/plans/
   → 隐性需求推导 → 写入 analysis.md
   → 硬门禁: 无设计文档引用 → 禁止进入依赖链推导

 Step 1c: 需求分类（deep-discovery / fast-track）
   → [契约保障] contract.yaml PC03 要求 routing.md 含分类
   → deep-discovery: 深度访谈协议（one-question-per-turn, teach-back）
   → fast-track: 证明符合快速通道条件
   → [Soul Sync] 每次澄清后 soul_auto + response_plan

 Step 1e: 成熟方案搜索
   → [契约保障] contract.yaml PC02 要求 Mature Solution Evidence 完整（6项）
   → 搜索项目内 + 官方 + 开源参考
   → 不引用来源 = 不允许进入设计

 Step 1h: Skill 路由决策
   → 选择主 Skill（单选）：ue5-cpp-gameplay / ue5-ui-umg-slate / ...
   → 选择次 Skill（可选）
   → 按需加载：路由确定后才加载对应 SKILL.md，不预先加载所有
   → [契约保障] contract.yaml PC04/PC10 要求 routing.md 含 Quality Gate + Work Package Policy

 Step 1i: 单 Agent / 多 Agent 判断
   → 默认单 Agent
   → 满足任意两项 → 启用多 Agent：
       - 涉及两个以上系统
       - 预计改动 8 个以上文件
       - 同时涉及代码、数据资产和蓝图/配置
       - 同时涉及 Lyra、GAS、AI
       - 需要实现、验证和性能判断并行收敛
   → 多 Agent 结构: 1 总控 + 1 实现 + 1 验证
   → 写入 routing.md 的 Work Package Policy

 Step 1j: 创建分析文档
   → [契约保障] contract.yaml PC05/PC06/PC11 要求 analysis.md 含
       Architecture Context / Acceptance Criteria / Automated Verification Plan
   → [契约保障] contract.yaml PC09 要求 doc-impact.md 存在

 Step 1k: 用户确认
   → [契约保障] contract.yaml PC07/PC08 要求 user_confirmed_plan=true + router_skill_loaded=true
   → 用户未明确确认前：禁止任何 edit/write/apply_patch
 ```

 ### 6.3 Plan 阶段出口：契约验证 + 门禁

 ```
 & contract-verify.ps1 <task> verify -Phase plan -Strict
   → 任一 BLOCKING FAIL → 停止，报告缺失项，不进入 Implement
   → 全部 PASS →
       & task-guard.ps1 <task> plan -Apply
       & [Soul] soul_turn(trigger:"task_completed")
       & [Soul] soul_end
 ```

 ### 6.4 Implement 阶段：Skill 按需加载 + 子 Agent 派发

 ```
 [单 Agent 模式]
   → 金璃好帮手 直接执行
   → & contract-verify.ps1 <task> verify -Phase implement -Strict
   → [契约保障] IC01: can-edit 通过
   → [契约保障] IC02: user_confirmed_plan=true
   → [契约保障] IC03: spec.md 存在
   → 按 spec 编码 → 编译 → 自检
   → 重复检测（detect-duplicates.ps1）

 [多 Agent 模式]
   → 金璃小天才（总控）读取 tasks.md + execution-prompt.md
   → 按 Work Package Policy 派发子 Agent:
       - 子 Agent 只读 work-packages/WPxx-*.md
       - 子 Agent 只改 Allowed Paths
       - 子 Agent 返回 reports/<agent>-WPxx-result.md
   → 子 Agent 加载对应 Skill（按需，不预加载）:
       - 实现 Agent: ue5-cpp-gameplay / ue5-ui-umg-slate / ...
       - 验证 Agent: code-verifier / ue5-debug-validation
   → [契约保障] 如果 external workers: yes,
       task-guard implement 检查所有 worker report
   → [authority_profile: issuer-worker-v1] 时:
       - Worker 只通过 worker-submit.ps1 提交
       - Worker 不能修改 task packet / approval / archive
       - Issuer 独立 Review + 显式 Archive
 ```

 ### 6.5 Verify 阶段：独立验证 + 契约终检

 ```
 → 验证 Agent（独立上下文，非实现 Agent 的 context）
 → & contract-verify.ps1 <task> verify -Phase verify -Strict
   → [契约保障] VC01: verification-report.md 存在
   → [契约保障] VC02: 报告含 5 个必需 section
   → [契约保障] VC03: verify_result = pass
 → & task-guard.ps1 <task> verify
 → & contract-verify.ps1 <task> report
 → 验证通过 → Issuer 显式 Archive（不是 Verify 的副作用）
 ```

 ### 6.6 契约验证在整个流程中的位置

 | 阶段边界 | 契约验证 | 门禁脚本 | 阻断条件 |
 |---------|---------|---------|---------|
 | Plan → Implement | `contract-verify verify -Phase plan -Strict` | `task-guard plan` | 任一 blocking FAIL |
 | Implement 开始 | `contract-verify verify -Phase implement -Strict` | `task-state can-edit` | can-edit 失败 |
 | Implement → Review | Worker reports 完整性 | `task-guard implement` | 缺 report / extra scope |
 | Verify 完成 | `contract-verify verify -Phase verify -Strict` | `task-guard verify` | 缺 verification-report |
 | Archive | Issuer 显式签名 | `issuer-archive` | 非 original Issuer |
```

### 6.2 Implement 阶段

```
Agent 开始实现
  → contract-verify verify -Phase implement -Strict (含 can-edit 检查)
  → 任一 BLOCKING FAIL → 停止，不编辑任何文件
  → 全部 PASS → 开始编码
  → 编码完成 → contract-verify report
```

### 6.3 Verify 阶段

```
Agent 开始验证
  → contract-verify verify -Phase verify -Strict
  → 任一 BLOCKING FAIL → 停止，修复
  → 全部 PASS → task-guard verify
  → 验证完成 → contract-verify report
```

---

## 7. 验收标准

| AC# | 描述 | 验证方法 |
|-----|------|---------|
 | AC01 | contract-verify.ps1 语法正确 | PowerShell parser 无错 |
 | AC02 | init 命令生成 contract.yaml | Test-Path contract.yaml |
 | AC03 | verify 命令正确检测通过/失败 | 测试已知通过和失败的任务 |
 | AC04 | -Strict 模式 exit 1 | $LASTEXITCODE 验证 |
 | AC05 | report 生成完整报告 | Test-Path contract-report.md |
 | AC06 | 现有回归测试仍通过 | test-workflow-regression.ps1 |
 | AC07 | AGENTS.md 引用新框架 | Select-String |
 | AC08 | codex-project-router 引用 contract-verify | Select-String |
 | AC09 | 设计文档包含完整多 Agent 流程 | Select-String "多 Agent" |
 | AC10 | 设计文档包含 Skill 按需加载流程 | Select-String "按需加载" |
 | AC11 | 设计文档与 11/12/33 号文档对齐 | 交叉引用检查 |

## 8. 自动指引机制（2026-06-27 新增）

### 8.1 问题

Agent 被门禁拦截后，只看到 FAIL 信息，不知道怎么修。导致反复试错（实测 8 轮才能通过 Plan 门禁）。

### 8.2 三个改进

| 改进 | 实现 | 效果 |
|------|------|------|
| 集中 marker 清单 | `Docs/AI/48-Plan-Phase-Checklist.md` | Agent 一文档查所有检查项 |
| scaffold 命令 | `contract-verify scaffold` | 自动生成带所有 marker 骨架的模板文件 |
| verify 修复指引 | `REPAIR:` 输出 | 失败时告诉 Agent 具体怎么修 |

### 8.3 scaffold 命令

```powershell
& .\.trae\scripts\contract-verify.ps1 <task-name> scaffold
```

自动生成以下模板文件（仅在文件不存在时生成）：
- routing.md — 含 Quality Gate、Work Package Policy、Fast Track Assessment 骨架
- analysis.md — 含全部 11 个必需 marker 骨架
- spec.md — GIVEN/WHEN/THEN 骨架
- tasks.md — 含 automated verification、AC mapping、mature-path verification 任务
- doc-impact.md — 含 Project/System/Owner scope 和 Code Changes/No Code Changes 骨架
- execution-prompt.md — 含全部 12 个必需 section 骨架

### 8.4 verify 修复指引

当 `contract-verify verify -Strict` 拦截时，输出格式变为：

```
BLOCKED: 2 blocking contract(s) failed.
Agent MUST NOT proceed until all blocking contracts pass.

=== REPAIR GUIDANCE ===
  REPAIR PC07: Run: task-state set <task> user_confirmed_plan true
  REPAIR PC08: Run: task-state set <task> router_skill_loaded true

Run 'contract-verify scaffold' to generate template files with all required markers.
See Docs/AI/48-Plan-Phase-Checklist.md for the complete checklist.
```

每个 REPAIR 行提供具体修复命令或操作说明，Agent 可直接执行。

### 8.5 快速通过 Plan 门禁流程（改进后）

```
1. task-state init <task> full
2. contract-verify <task> init
3. contract-verify <task> scaffold          ← 新增：一步生成所有模板
4. 填写模板中的占位符内容
5. task-state set <task> user_confirmed_plan true
6. task-state set <task> router_skill_loaded true
7. task-state set <task> change_profile fast
8. task-state set <task> clarification_status answered
9. task-state set <task> requirements_status not_required
10. task-state set <task> fast_track_reason "具体理由"
11. task-state set <task> execution_prompt execution-prompt.md
12. task-guard <task> plan                  ← 一遍通过
```

对比改进前：8 轮试错修复 → 改进后：1 轮通过。
