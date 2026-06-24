---
domain: ai
domain_path: ai/workflow
kg_node_id: node.doc-ai-ai-24-pro-flash-model-tiering-ae1d
t13_retro_classified_at: "2026-06-24T04:47:04Z"
kg_id: doc.ai.ai.24-pro-flash-model-tiering.ae1d

---

# Pro + Flash 模型分层工作流

## 目标

将 DeepSeek V4 Pro（深度推理）和 V4 Flash（快速执行）按工作流阶段分层使用，在不牺牲代码质量的前提下降低 60-80% API 成本。

---

## Quick Start（三会话工作流）

```
会话 1 [Pro]  Plan
  → 分析需求 → 拆解任务 → 输出 routing.md + tasks.md
  → 用户确认后，运行: task-handoff.ps1 <task-name>
  → /clear，切换 Flash

会话 2 [Flash] Implement
  → 粘贴 handoff → 按 tasks.md 逐项编码 → 编译验证
  → 全部完成后，运行: task-handoff.ps1 <task-name>
  → /clear，切换 Pro

会话 3 [Pro]  Review + Verify（合并，同一会话）
  → 粘贴 handoff → 审查代码 → 编译 → 修复 → 验收
  → 输出验收报告
```

### 每阶段结束时只需一条命令

```powershell
# 在终端运行（自动检测当前阶段，生成对应 handoff）
.trae\scripts\task-handoff.ps1 <task-name>
```

脚本会：
- 自动检测当前阶段（从 `.task.yaml`）
- 自动检测 git 变更文件列表
- 输出格式化的 handoff 模板（含模型切换提示）
- 同时保存到 `.trae/tasks/<task-name>/handoff-*.txt`

---

## 模型定位

| 维度 | V4 Pro | V4 Flash |
|------|--------|----------|
| 参数 | 1.6T MoE / 49B 激活 | 284B / 13B 激活 |
| 成本（输入） | $1.74/M（促销 $0.435/M） | $0.14/M |
| 成本（输出） | $3.48/M（促销 $0.87/M） | $0.28/M |
| **相对成本** | **~12x Flash** | 基准 1x |
| 强项 | 深度推理、架构决策、多文件联动、长 Agent 循环（10-20 步） | 单文件编码、快速执行、批量操作 |
| 弱项 | 简单任务"过度思考"，输出冗长 | 6-8 次工具调用后错误累积，模糊指令输出模糊 |
| 上下文窗口 | 1M token | 1M token |
| API 兼容 | 同一 endpoint，仅 model 字段不同 | 同左 |

> 数据来源：DeepSeek 官方 HuggingFace 模型卡 + ofox.ai 实测（2026.06）

---

## 阶段-模型映射

```
Phase 1: Plan              → Pro    （深度推理，占 token 10-15%）
Phase 2: Implement          → Flash  （执行密集型，占 token 60-80%）
Phase 3: Review + Verify    → Pro    （审查+编译+修复+验收，同一会话）
```

### 为什么 Implement 用 Flash？

- 编码任务中 60-80% 的 token 消耗在执行层（代码生成和编辑）
- 单文件、边界清晰的编码任务上，Pro 和 Flash 的质量差距小到难以分辨
- Flash 成本仅为 Pro 的 1/12
- Flash 在明确指令下执行质量与 Pro 差距极小

### 为什么 Review 和 Verify 合并为一个 Pro 会话？

- 两者都用 Pro，无需切换模型
- Review 发现问题 → 同一会话直接修复 → 编译验证 → 验收
- 减少一次 `/clear` + handover 往返
- Pro 既做审查又做修复，效率更高

### 为什么 Plan 用 Pro？

- 需要理解上下文、识别边界条件、评估技术风险
- token 消耗远小于 Implement，用 Pro 增加的成本有限但质量提升显著

---

## AI 提醒契约（强制）

AI 在以下时机**必须主动提醒用户**，不得跳过：

### 提醒点 1：Plan 确认后 → 切 Flash

**触发条件**：用户确认 routing.md + tasks.md 后

AI 必须输出：

```
---
## 模型切换提醒

Plan 阶段已完成。请执行以下步骤进入 Implement：

1. 在终端运行:
   PS> .trae\scripts\task-handoff.ps1 <task-name>

2. 复制输出的 handoff 内容

3. /clear 或开新会话

4. 在 Trae 设置中切换模型为: **deepseek-v4-flash**

5. 粘贴 handoff 作为新会话第一条消息
---
```

### 提醒点 2：Implement 完成后 → 切 Pro

**触发条件**：tasks.md 全部打勾 + 编译通过后

AI 必须输出：

```
---
## 模型切换提醒

Implement 阶段已完成。请执行以下步骤进入 Review+Verify：

1. 在终端运行:
   PS> .trae\scripts\task-handoff.ps1 <task-name>

2. 复制输出的 handoff 内容（含变更文件列表）

3. /clear 或开新会话

4. 在 Trae 设置中切换模型为: **deepseek-v4-pro**

5. 粘贴 handoff 作为新会话第一条消息

Pro 会话中我会自动执行：审查代码 → 编译验证 → 修复问题 → 输出验收报告
---
```

### 提醒点 3：验收完成后

**触发条件**：验收报告输出后

AI 必须输出：

```
---
## 任务完成

验收报告已输出: .trae/tasks/<task-name>/verification-report.md

如需归档: task-state.ps1 transition <task-name> archived
---
```

---

## 详细操作步骤

### 会话 1：Plan（Pro 模型）

```
1. 用户提出需求
2. ue-project-router 分析需求、搜索已有实现
3. 输出 routing.md + tasks.md + spec.md
4. 用户确认方案
   → AI 自动触发【提醒点 1】
```

### 会话 2：Implement（Flash 模型）

```
1. 读取 routing.md 了解架构决策
2. 按 tasks.md 顺序逐项执行:
   - 编写代码
   - 编译验证
   - 打勾 tasks.md
3. 全部任务完成 + 编译通过
   → AI 自动触发【提醒点 2】
```

### 会话 3：Review + Verify（Pro 模型，同一会话）

```
1. 审查 Flash 生成的代码:
   - 跨文件依赖完整性（Flash 的弱项）
   - 边界条件处理（空值、异常）
   - 代码风格一致性
   - 是否引入网络复制/RPC（UE5 项目）
2. 编译验证:
   PS> & "G:\UE_5.6\Engine\Binaries\DotNET\UnrealBuildTool\..." ...
3. 如有问题，直接在同一会话中修复
4. 运行时验证（如适用）
5. 输出验收报告到 .trae/tasks/<task-name>/verification-report.md
   → AI 自动触发【提醒点 3】
```

---

## 自动化工具

### task-handoff.ps1

```powershell
# 自动检测当前阶段，生成对应 handoff
.trae\scripts\task-handoff.ps1 <task-name>

# 指定方向
.trae\scripts\task-handoff.ps1 <task-name> -Direction plan-to-implement
.trae\scripts\task-handoff.ps1 <task-name> -Direction implement-to-review
```

功能：
- 自动读取 `.task.yaml` 获取当前阶段和项目类型
- `implement-to-review` 方向自动检测 git 变更文件列表
- 输出格式化的 handoff 模板（含模型切换提示）
- 同时保存到任务目录

---

## 成本估算

以典型 UE5 中等复杂度任务为例（~50K input tokens/阶段）：

| 阶段 | 模型 | 预估成本（促销价） | 预估成本（标准价） |
|------|------|-------------------|-------------------|
| Plan | Pro | ~$0.065 | ~$0.26 |
| Implement | Flash | ~$0.021 | ~$0.021 |
| Review+Verify | Pro | ~$0.044 | ~$0.17 |
| **合计** | **混合** | **~$0.13** | **~$0.45** |
| 对比：全 Pro | Pro | ~$0.39 | ~$1.56 |
| **节省** | | **67%** | **71%** |

> Implement 阶段实际 token 消耗通常远高于其他阶段（代码生成 + 编译迭代），实际节省比例可能更高。

---

## 子 Agent 模型分配

当启用多 Agent 协作时：

| Agent 角色 | 推荐模型 | 原因 |
|-----------|---------|------|
| 主控 Agent（路由/规划） | Pro | 需要全局上下文理解 |
| 实现 Agent（代码编写） | Flash | 执行密集型，指令明确 |
| 审查 Agent | Pro | 跨文件一致性检查 |
| 研究 Agent（搜索/分析） | Flash | 读取量大但推理浅 |

---

## 例外情况

以下情况 Implement 阶段也应使用 Pro：

- 涉及 8 个以上文件的跨模块重构
- 需要深度推理的调试任务（根因分析）
- 多文件联动且依赖关系复杂
- Flash 连续 3 次编译失败后

---

## 与现有工作流的兼容性

本方案不改变 Comet 四阶段的名称，但 DS4 Flash 任务会增加受门禁保护的修复状态：
- 合并 Review + Verify 为同一 Pro 会话
- 增加模型推荐标注
- 提供 `task-handoff.ps1` 自动化交接
- `worker_profile: ds4-flash` 启用专用发包、报告权限和独立验收门禁
- Review/Verify 失败通过 `worker-repair-loop.ps1 record-failure` 自动生成更窄的修复包
- 同一根因第三次失败进入 `architecture_review`，停止自动重发
- `authority_profile: issuer-worker-v1` 时，Flash 只能追加进度和提交结果；原 Issuer 独占任务包更新、审核、修复包发布和显式归档
- Verify 不再自动归档，Archive 必须由原 Issuer 使用签名审批单独执行

完整规则见 `Docs/AI/40-DS4-Flash-Worker-Repair-Loop.md` 和 `Docs/AI/41-Issuer-Worker-Authority-Separation.md`。
- 阻塞点不变

---

## 参考

- DeepSeek V4 Pro vs Flash: Real Cost-Quality Tradeoff (ofox.ai, 2026.06)
- DeepSeek V4 Pro + Flash 分工编程实战 (CSDN, 2026.06)
- DeepSeek V4 Pro vs Flash: Which One for Production? (WaveSpeed, 2026.04)
- CodeWhale Phase 3: Model Tiering (GitHub, 2026.04)
