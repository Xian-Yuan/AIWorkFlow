---
name: "smart-requirements"
description: "Use when a user asks for a new system, meaningful feature, workflow or UI redesign, or describes an outcome with uncertain boundaries, users, behavior, or success criteria."
---

# Smart Requirements Clarification

## 核心原则

需求澄清的目标不是“收集到足够多的句子”，而是让用户和 Agent 对最终体验形成同一个理解。

**用户负责表达目标、感受和选择；Plan Agent 负责发现歧义、推导隐含需求、研究技术方案，并把确认结果翻译成设计与任务包。**

标签：`deep-discovery`、`fast-track`、`one-question-per-turn`、`no-fixed-round-limit`、`teach-back`。

## 第一步：任务分流

### 深度访谈 deep-discovery

满足任一条件必须进入深度访谈：

- 新系统、新模块或明显的新功能
- 工作流、交互方式或 UI/UX 重构
- 涉及多个系统、数据归属或架构边界
- 用户只描述结果，没有说明使用过程或成功标准
- Agent 发现高影响歧义或用户未提及的 P0/P1 隐含需求
- 无法确定是否属于快速通道

### 快速通道 fast-track

仅当以下条件全部成立时允许：

- 期望行为具体明确
- 改动范围小且边界清晰
- 不引入架构或数据归属决策
- 不改变完整用户旅程
- 没有未确认的高影响隐含需求
- 验证方式明确且范围有限

在 `routing.md#Fast-Track-Assessment` 记录逐项判断和 `fast_track_reason`。任何不确定都回到深度访谈。

## 深度访谈协议

### one-question-per-turn

每轮只问一个最重要的问题：

1. 使用用户听得懂的场景语言，不把代码术语丢给用户。
2. 优先提供 2～3 个具体选择。
3. 明确给出推荐项及推荐理由。
4. 允许用户不选预设项，直接描述想法。
5. 不问可以从仓库、官方文档或成熟方案中自行查明的技术问题。

### no-fixed-round-limit

不限制固定轮数，也不设置“最多五个问题”。每轮选择“影响最大且最不确定”的一项继续。

用户说“可以出方案了”时，不直接结束澄清；先进入最终需求回放。如果仍有未解决的高影响问题，必须明确指出并请用户决定。

### 每轮 teach-back

收到回答后，先用一句通俗话复述理解，再更新决策账本：

```text
已确认：用户决定了什么
小璃理解：这对最终体验意味着什么
可能牵动：由此推导出的隐含需求
下一问题：当前影响最大的不确定点
```

用户纠正时以最新回答为准，不维护两套相互冲突的解释。

## 需求覆盖扫描

在结束深度访谈前检查：

| 维度 | 要理解的内容 |
|---|---|
| 目标与问题 | 想得到什么，当前哪里不好 |
| 用户与场景 | 谁用、何时用、在什么环境用 |
| 完整旅程 | 从开始到完成/退出的每一步 |
| 内容与数据 | 输入、输出、保存、来源和归属 |
| 规则与边界 | 必须、禁止、权限、范围 |
| 异常与恢复 | 空状态、失败、取消、超时、重试 |
| 质量与感受 | 怎样才算好用、自然、专业或满意 |
| 集成与未来 | 现有系统、扩展压力、明确非目标 |
| 隐含需求 | Agent 推导但用户没有主动说出的需要 |

不是每个维度都要机械提问；能从上下文可靠确定的直接记录，需要用户决定的才逐轮询问。

## 最终需求回放

Plan Agent 用非技术语言展示：

- 要解决的问题
- 谁会怎样使用
- 完整使用过程
- 已确认的关键选择
- 已确认/拒绝/延期的隐含需求
- 明确不做的内容
- 怎样才算满意
- 是否仍有高影响问题

用户明确确认后，写入 `requirements.md`。沉默、未反对或过去偏好都不等于确认。

## Agent 自主技术翻译

需求确认后，Plan Agent 自行完成：

1. 项目内证据与成熟方案研究
2. 架构比较与方案选择
3. `analysis.md`、`spec.md`、`tasks.md`
4. `execution-prompt.md`
5. 验收标准、验证命令和停止条件

`execution-prompt.md` 必须引用已确认的需求事实源，包含允许/禁止路径、非目标、验收标准、验证命令、停止条件和证据规则。下游模型不得直接根据原始聊天句子重新解释需求。

## 任务包状态

深度访谈：

```yaml
requirements_gate_version: 1
change_profile: deep
requirements_status: confirmed
requirements_doc: requirements.md
execution_prompt: execution-prompt.md
clarification_status: answered
```

快速通道：

```yaml
requirements_gate_version: 1
change_profile: fast
requirements_status: not_required
execution_prompt: execution-prompt.md
fast_track_reason: <concrete reason>
```

## 常见偷跑理由

| Agent 想法 | 实际规则 |
|---|---|
| “用户大概就是这个意思” | 大概意味着仍有歧义，必须回放确认 |
| “问太多会打扰用户” | 一次只问一个关键问题，不用一次倾倒问卷 |
| “先做出来再让用户看” | 对新系统而言，返工比澄清更打扰 |
| “用户说可以开始了” | 先完成最终需求回放，再进入技术设计 |
| “这是小功能” | 必须逐项满足快速通道条件，不能凭感觉 |
| “我已经写了计划” | 技术计划不能替代用户确认的需求画像 |

## Red Flags

- 一次提出多个互不相关的问题
- 使用类名、框架名、数据库方案要求非技术用户选择
- 固定问满 N 个问题或达到 N 个就停止
- 隐含需求只写进分析而没有让用户确认
- 用 `clarification_status: answered` 代替真实证据
- 没有 `requirements.md` 就启动深度任务
- 没有 `execution-prompt.md` 就把任务交给执行模型
- 快速通道没有具体理由
