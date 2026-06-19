---
name: "token-guardian"
description: "Token 消耗优化——合并 squeez/token-optimizer/governor 的 token 节省最佳实践"
---

# Token Guardian

## 定位

在 Agent 全生命周期中主动降低 token 消耗，而非等到上下文满才压缩。集成 squeez、token-optimizer、governor 的最佳模式。

## 何时调用

- **SessionStart**: 注入 token 节省提示
- **每次工具调用前**: 检查是否可以用更省 token 的方式获取相同信息
- **Plan 阶段**: 使用 codegraph 代替逐个文件读取
- **Implement 阶段**: 每次编译后压缩错误输出

## 策略 1：用图代替逐文件读取（codegraph）

```
Before: grep + read 15 个文件 → ~13,500 tokens
After:  codegraph.ps1 query → ~200 tokens + read 2 个关键文件 → ~2,000 tokens
Saving: ~85%
```

**规则**: 当需要了解超过 3 个文件的依赖关系时，先用 codegraph 查询，只 read 真正需要修改的文件。

## 策略 2：输出压缩链（squeez 模式）

每次工具输出超过 500 行时，在分析前先压缩：

### 编译错误压缩
```
Before: 800+ lines of full build output
After:  ~30 lines of unique errors grouped by file
Saving: ~96%
```

**压缩步骤**:
1. 删除重复错误（保留首次出现 + 出现次数）
2. 按源文件分组
3. 只保留 error 级别，warning 折叠
4. 每个 error 保留: 文件+行号+错误码+消息文本

### Grep 结果压缩
```
Before: 200 lines of grep matches
After:  ~15 lines: 按文件分组 + 匹配总数 + 高信号文件标注
Saving: ~92%
```

## 策略 3：避免重复读取（dedup）

| 场景 | 当前行为 | 优化后 |
|------|---------|--------|
| 读取已读过的文件 | 再次完整 read | 只读新增/修改的行（diff） |
| 连续两次 Read 同一文件 | 两次完整 read | 第二次读 cached hash + 标记 `[same as read #N]` |
| MCP 返回与上次相同 | 完整 payload | 返回 `[identical to call #N]` |

## 策略 4：自适应压缩强度

根据上下文预算动态调整：

| 预算使用率 | 模式 | 限制 |
|:---------:|------|------|
| < 60% | **宽松** | 全量输出，不做压缩 |
| 60-80% | **标准** | 输出 >500 行时压缩，重复行折叠 |
| 80-95% | **激进** | 输出 >200 行时压缩，二次去重，摘要优先 |
| > 95% | **极限** | 所有输出强制压缩到 ≤40 行摘要 |

## 策略 5：Skill/MCP 精简

| 问题 | 检测 | 修复 |
|------|------|------|
| Skill 被重复加载 | 相同 body hash 出现 2 次 | 第二次折叠为 `[squeez: identical to Skill #N]` |
| MCP 工具未使用 | 已声明但 0 次调用 | 从上下文移除引用 |
| AGENTS.md 过长 | >200 行 | 建议用 `compress-md` 精简 |

## 策略 6：Session 连续性优化

### 跨会话记忆
SessionStart 时注入上一会话摘要（≤200 tokens）:
- 已调查的文件
- 已知错误和解决方案
- 已完成和待完成的工作
- 有效时间范围（超过 7 天自动过期）

### 成本感知
- 子 Agent 每次 spawn ~200K tokens → 控制 spawn 次数
- 用 `squeez_agent_costs` 跟踪
- banner 提示: `[budget: ~N calls left before /clear]`

## 策略 7：模型选择提示

| 场景 | 推荐模型 | 原因 |
|------|---------|------|
| 单文件修改 | Flash | 简单任务，Pro 过度消耗 |
| 多文件依赖 | Pro | 需要跨文件理解 |
| 搜索/分析 | Flash | 大量读，浅分析 |
| 架构决策 | Pro | 需要深度推理 |
| 修复 2 次仍失败 | 停止 + spawn 新 Flash subagent | 上下文可能已腐烂 |

## Token 消耗仪表盘

建议周期性地（每 5 次对话或每阶段结束）输出:

```
## Token Economy Report
- Sessions this phase: 3
- Est. tokens consumed: ~85,000 input / ~12,000 output
- Top consumer: grep/read across 18 files (~45% of input)
- Savings applied: codegraph skipped 12 files, output compression -92% on compile
- Recommendation: use codegraph more aggressively in next phase
```

## 与现有 Skill 集成

- 增强 `output-compressor`: 加入 budget-driven 自适应强度
- 增强 `code-knowledge-graph`: 加入 guard (先 query 再 read)
- 增强 `anti-degradation`: ghost token 检测自动触发 Rules 3,5
- 增强 `subagent-driven-development`: 子 Agent spawn 前做成本估计
