---
name: "anti-degradation"
description: "上下文腐烂检测与修复循环中断。检测 Agent 退化信号，强制中断无效修复循环，防止假阳性通过。"
---

# Anti-Degradation Protocol

## 定位

本 Skill 提供 Agent 上下文腐烂检测和修复循环中断机制。核心原则：上下文腐烂是 Agent 最主要的失败模式，必须主动对抗。

## 何时调用

- Implement 阶段：每次编译失败后检查
- Implement 阶段：每次开始新一轮修复前检查
- Review/Verify 阶段：验证结果有效性前检查

## 规则 1：修复循环强制中断

同一 bug 或编译错误连续修复 2 次仍未解决 → 立即停止，禁止第 3 次尝试。

中断后的操作：
1. git stash push -m "SNAPSHOT: fix-attempt-N"（保存当前状态）
2. Spawn 全新 subagent（独立上下文，不继承当前对话历史）
3. Subagent 只接收：analysis.md + spec.md + 错误日志
4. 原 Agent 等待 subagent 结果，不自行继续修复

## 规则 2：上下文腐烂检测

出现以下任一信号即视为上下文腐烂：

| # | 信号 | 说明 |
|---|------|------|
| 1 | 重新读取已修改过的文件 | Agent 忘记自己已经改过这个文件 |
| 2 | 重复解释已讨论过的概念 | 上下文窗口溢出，早期信息丢失 |
| 3 | 提出与早期已否决方案相同的方案 | 忘记了之前的决策 |
| 4 | 忽略 analysis.md 中已记录的约束 | 关键约束从上下文中掉落 |

检测到腐烂后：立即停止当前操作，输出腐烂信号摘要，建议用户 /clear 或开新会话。

## 规则 3：假阳性防御（Fail-Closed）

铁律 1："测试通过"不等于修好了。必须验证编译日志确认无 error、实际行为对照 spec.md Scenario、验证 Agent 是独立 context。

铁律 2：验证 Agent 与实现 Agent 同一 context → 验证结果无效。必须 spawn 独立 subagent 做验证。

铁律 3：证据不足 → FAIL。编译日志为空、未对照 Scenario 逐条验收、验证报告结构不完整、门禁状态不清楚，均判定为 FAIL。

## 规则 4：Git 快照

每次修复前：git stash push -m "SNAPSHOT: <方案名>"
修复失败后：git stash pop 恢复到修复前的干净状态

禁止在不清除残留代码的情况下切换方案。禁止跳过快照直接开始修复。

## 规则 5：用户手动降智恢复

当 Agent 明显退化为循环修同一个问题时，用户触发 /fix-degraded <task-name>：
1. git stash pop 恢复到上次快照
2. 重新 spawn 独立 subagent
3. Subagent 只加载 analysis.md + spec.md + 最近 git commit 的 diff
4. 原对话上下文全部丢弃


## 规则 6：上下文预算主动预警（Proactive Context Budget）

被动检测腐烂（规则 2）是最后一道防线。规则 6 提供主动预算追踪，在上下文窗口接近极限之前预警。

### 预算阈值

| 预估用量 | 状态 | 行为 |
|:--------:|------|------|
| < 60% | 正常 | 无需操作 |
| 60-80% | 警告 | 输出预算提醒，建议精简后续操作 |
| 80-95% | 危险 | 强制输出上下文摘要，建议尽快 /clear 或 handoff |
| > 95% | 临界 | 停止复杂操作，只允许 handoff 或 /clear |

### 预算估算方法

由于无法直接读取 token 计数，使用以下启发式估算：

| 信号 | 估算消耗 | 说明 |
|------|:------:|------|
| 每次工具调用（读文件/搜索） | ~2-5% | 返回内容计入上下文 |
| 每次代码编辑（apply_patch） | ~1-3% | diff 内容计入上下文 |
| 每轮对话（含 agent 输出） | ~3-8% | 取决于输出长度 |
| 加载大型 SKILL.md (>200行) | ~5-10% | 一次性加载 |
| 加载 Docs/AI 文档 (>300行) | ~8-15% | 一次性加载 |
| 编译输出 (>500行) | ~10-20% | 大量日志 |

### 预警触发条件

满足以下任意条件时，触发预算预警：

1. **工具调用计数**：当前会话工具调用超过 40 次 → 警告；超过 60 次 → 危险
2. **对话轮次**：超过 20 轮 → 警告；超过 30 轮 → 危险
3. **文件读取量**：累计读取超过 15 个文件 → 警告；超过 25 个 → 危险
4. **编译循环**：同一会话中编译超过 3 次 → 警告；超过 5 次 → 危险

### 预警输出格式

```
## Context Budget Warning

**Status:** WARNING (est. 65-75% used)
**Signals:** 35 tool calls, 18 conversation turns, 12 files read
**Recommendation:** Complete current task, then /clear before next phase.
**If continuing:** Minimize file reads, avoid loading large docs, prefer targeted edits.
```

## 规则 7：Ghost Token 检测（来自 token-optimizer + squeez）

Ghost token = 占用上下文窗口但对任务无贡献的内容。每检测到需即时清理。

### 7 类 Ghost Token 及其检测信号

| # | 类型 | 信号 | 清除动作 |
|---|------|------|---------|
| 1 | **Skill 重复注入** | 同一 Skill 被 Skill tool 加载超过 1 次 | 第二次加载视为无效，可丢弃前一次 |
| 2 | **未使用的 Skill/MCP** | 已声明但当前会话从未调用的 Skill/MCP | 从上下文提示中移除引用 |
| 3 | **过期 Memory** | MEMORY.md 条目指向超过 90 天未触及的文件/路径 | 标记为可清理 |
| 4 | **重复系统提醒** | 同一条系统规则在上下文出现 3 次以上 | 保留第一条，后续折叠 |
| 5 | **死文件引用** | 上下文中引用了已被删除/移动的文件路径 | 更新或移除引用 |
| 6 | **大文件重复读取** | 同一文件被 Read ≥2 次且未修改 | 第二次只返回 diff/摘要 |
| 7 | **冗余 MCP 结果** | MCP 工具返回与上次相同的完整 payload | 检测 payload hash，返回 `[identical to call #N]` |

### 检测频率
- SessionStart: 清除 Skill 重复注入 (#1)、过期 Memory (#3)、死文件引用 (#5)
- 每次 Read: 检测重复读取 (#6)
- 每次 MCP 调用: 检测冗余 payload (#7)
- 每次 SessionEnd: 输出 ghost token 报告

## 规则 8：Drift Guardrails（来自 governor）

当 Agent 行为偏离初始 Plan 时，需主动检测并警告。

### Drift 信号

| # | 信号 | 阈值 | 动作 |
|---|------|------|------|
| 1 | 修改了 analysis.md 未列出的文件 | ≥1 个未列出的文件 | 警告 + 询问用户是否批准范围扩展 |
| 2 | 新增了 tasks.md 未规划的步骤 | ≥1 个额外步骤 | 记录为 drift，更新 tasks.md |
| 3 | 错误指纹重复（同一类错误 ≥3 次） | FP 衰减后继续 | 中断，spawn 新 subagent 分析根因 |
| 4 | 方案大转弯（Plan A → Plan B，无用户确认） | 任何时候 | 禁止，必须询问用户 |

### Drift 响应协议
1. 检测到信号 → 输出 `## Drift Warning: <signal-type>`
2. 轻微 drift（1 个未列文件）→ 记录后继续
3. 中度 drift（3+ 未列文件或 1+ 额外步骤）→ 暂停，询问用户
4. 严重 drift（方案大转弯）→ 立即停止

## 规则 9：上下文质量评分 7-Signal（来自 token-optimizer）

替代原有 4 信号腐烂检测（规则 2），升级为 7 信号评分系统。

### 评分信号

| # | 信号 | 计算方式 | 扣分阈值 |
|---|------|---------|---------|
| 1 | 重复文件读取率 | (重复读取次数 / 总读取次数) | >30% |
| 2 | Skill 冗余注入率 | (重复注入 Skill 数 / 总 Skill 数) | >20% |
| 3 | 错误复现率 | (同一错误出现次数 / 修复尝试次数) | >40% |
| 4 | 上下文预算消耗率 | (当前预算% / 对话轮次) | >3%/轮 |
| 5 | 决策一致性 | (推翻之前决策次数 / 总决策次数) | >20% |
| 6 | MCP 调用冗余率 | (重复 payload 次数 / 总 MCP 调用次数) | >30% |
| 7 | 文件修改泄漏 | (修改了 tasks.md 未列的文件 / 总修改文件数) | >10% |

### 评分等级

| 得分 | 等级 | 建议 |
|:----:|------|------|
| 0-1 信号触发 | **GREEN** | 正常，继续 |
| 2-3 信号触发 | **YELLOW** | 警告，建议精简策略 |
| 4-5 信号触发 | **RED** | 强制输出质量报告，建议 /clear |
| 6-7 信号触发 | **CRITICAL** | 立即停止，只允许 handoff |

### 评分输出格式

```
## Context Quality Report

**Score:** YELLOW (3/7 signals triggered)
**Triggered:** 重复文件读取率 35%, 上下文预算消耗率 3.5%/轮, 错误复现率 50%
**Clean signals(4):** Skill 冗余 5%, 决策一致性 10%, MCP 冗余 8%, 文件泄漏 0%
**Recommendation:** 减少重复读取，考虑 /clear 后换 Flash 执行
```

## 规则 10：Compaction 存活性（来自 token-optimizer）

上下文压缩时，关键状态不丢失。

### Checkpoint Protocol
1. **Before compaction**: 输出 `compaction-checkpoint` 摘要到独立文件
2. 摘要包含: 当前 task 进度、关键决策列表、待解决问题、文件修改清单
3. **After compaction**: 从 checkpoint 恢复关键上下文注入系统提示

### 最少存活信息
压缩后必须保留：
- 当前 task 名称和编号
- 已完成的 task 列表
- 当前文件的修改状态和编译结果
- 最后一次编译失败的完整错误
- 用户的最后一条指令

## 集成到工作流

- Implement 阶段：每次编译失败后自动运行规则 1 检查
- Implement 阶段：每完成 3 个 task 后运行规则 2 自检
- Review/Verify 阶段：开始验证前运行规则 3 独立性检查

## 禁止事项

- 不在同一上下文中连续修复同一问题超过 2 次
- 不让实现 Agent 自我验证
- 不在上下文腐烂后继续强行工作
- 不跳过 Git 快照
- 不在上下文预算危险状态（>80%）下开始新的复杂任务
- 不在临界状态（>95%）下执行任何非 handoff 操作
