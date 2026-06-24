---
domain: ai
domain_path: ai/workflow
kg_node_id: node.doc-ai-ai-09-agent-handoff-templates-c551
t13_retro_classified_at: "2026-06-24T04:47:04Z"
kg_id: doc.ai.ai.09-agent-handoff-templates.c551

---

# Agent Handoff Templates

## 目标

本文件用于把多智能体协作中的交接物固定下来，避免不同代理在目标、Tag、挂载点、资产、验证口径上出现偏差。

## 使用时机

适用于以下情况：

- 一个需求同时涉及 Lyra、GAS、AI、UI、存档、内容配置
- 需要多个代理并行产出并最终汇总
- 需要把“设计、实现、内容、测试、性能”拆分为不同角色

## 通用交接模板

```text
任务标题:
任务类型: 新功能 / 修改 / 修复 / 重构 / 性能优化
所属链路: Lyra / GAS / AI / UI / SaveGame / Other

目标:
- 一句话说明最终目标

背景:
- 用户想解决什么问题
- 当前已有实现是什么

允许修改:
- 允许修改的目录、模块、资产

禁止修改:
- 不允许触碰的系统、目录、网络逻辑、核心源码

输入约束:
- 依赖的类
- 依赖的 GameplayTag
- 依赖的数据资产
- 依赖的插件 / 模块

输出要求:
- 变更文件列表
- 新增/修改 Tag 列表
- 新增/修改资产列表
- 配置步骤
- 验证清单

风险备注:
- 编译风险
- 时序风险
- 资源引用风险
- 回归风险
```

## 架构代理模板

适用职责：

- 模块边界
- 挂载点
- 命名规则
- GameplayTag 根节点

额外交付：

- 推荐主挂载点
- 不建议采用的替代路径
- 是否存在循环依赖风险

## Lyra/GAS 代理模板

适用职责：

- `Experience / PawnData / InputConfig / AbilitySet / GA / GE / AS`

额外交付：

- 角色能力链
- 资源配置链
- 是否涉及新 Tag、新 GE、新 AbilitySet

## AI 代理模板

适用职责：

- `StateTree / Behavior Tree / EQS / SmartObject / AIController`

额外交付：

- 选型依据
- 主状态或主黑板键
- 与 GAS 的协同边界
- 失败回退路径

## 内容代理模板

适用职责：

- DataAsset
- 蓝图接线
- GameFeatureData
- 资源目录与命名

额外交付：

- 需要新建的资产
- 需要修改的资产
- 需要人工确认的字段

## 测试代理模板

适用职责：

- 编译检查
- 运行时冒烟
- 回归验证

额外交付：

- 已执行检查项
- 建议人工验证项
- 已知风险点

## 性能代理模板

适用职责：

- Tick、感知频率、异步边界、内存与运行成本

额外交付：

- 主要运行成本来源
- 是否新增 Tick / Timer / 后台线程
- 可接受的临时风险

## 汇总规则

总控代理在汇总多个代理结果时，至少应统一：

- 最终主挂载点
- 最终 GameplayTag 变更表
- 最终资产清单
- 最终验证清单
- 最终风险清单

---

## Context Snapshot 上下文快照

> **目标**：让下一个接手的 Agent 在 60 秒内了解当前任务全貌。在每次 Agent 交接（Plan→Implement、Implement→Review、会话中断后恢复）时使用。

### 何时填写

- **Session 结束时**：即将 `/clear` 或切换 Agent 前
- **阶段交接时**：Plan→Implement、Implement→Review 切换点
- **上下文恢复时**：新 Agent 接手会话时读取此快照

### 快照模板

```markdown
## Context Snapshot

### Active Decisions（活跃决策）
| 决策 | 选项 | 选定方案 | 理由 |
|------|------|---------|------|
| <决策标题> | <选项列表> | <最终选择> | <简短理由> |

### Open Questions（未决问题）
| 问题 | 影响范围 | 需要的输入 | 阻塞状态 |
|------|---------|-----------|---------|
| <问题描述> | <影响的模块或文件> | <需要的决策或信息> | 🔴 阻塞 / 🟡 待确认 / ⚪ 信息性 |

### Known Constraints（已知约束）
- <技术约束，如"不能引入新依赖"、"必须兼容 UE5.6" 等>
- <架构约束，如"不允许绕过 PawnData 直接接线" 等>
- <环境约束，如"无 GitHub 网络访问"、"UE5 编辑器不支持" 等>

### Changed Files Summary（变更文件摘要）
| 文件 | 操作 | 内容摘要 |
|------|------|---------|
| <路径> | 新增/修改/删除 | <做了什么> |

### Risk Notes（风险备注）
- <编译风险>：<说明>
- <时序风险>：<说明>
- <回归风险>：<说明>

### Verification Status（验证状态）
- 编译状态：通过 / 未通过（附错误数）
- AC 通过数：<通过数>/<总数>
- 已知问题：<列表>
```

### 填写示例

```markdown
## Context Snapshot

### Active Decisions
| 决策 | 选项 | 选定方案 | 理由 |
|------|------|---------|------|
| Quality Checklist 格式 | Gherkin / Checklist / Freeform | Checklist | 与现有 spec 模板一致，低认知负担 |
| 多平台搜索优先级 | Agent-Reach / websearch / GitHub | GitHub > websearch > Agent-Reach | Agent-Reach 受限网络 |

### Open Questions
| 问题 | 影响范围 | 需要的输入 | 阻塞状态 |
|------|---------|-----------|---------|
| Graphify 是否集成到 Plan 阶段 | analysis.md 搜索流程 | UE5 C++ 宏解析验证结果 | 🟡 待确认 |

### Known Constraints
- 无网络访问 GitHub，Agent-Reach 不可安装
- 所有修改必须是纯文档/模板，不可引入新依赖

### Changed Files Summary
| 文件 | 操作 | 内容摘要 |
|------|------|---------|
| spec-template.md | 修改 | 增加 Quality Checklist 5 类检查项 |
| SKILL.md | 修改 | 增加多平台搜索策略和标准格式 |
| 09-Agent-Handoff-Templates.md | 修改 | 增加 Context Snapshot 小节 |

### Verification Status
- 编译状态：N/A（纯文档修改）
- AC 通过数：5/7（待回归测试）
- 已知问题：无
```

### 注意事项

1. **简洁优先**：每个字段控制在 1-2 句内，"60 秒法则"——下一个 Agent 读完应能直接开始工作
2. **只传关键信息**：不转储对话历史，只传"不能从文件自动恢复"的信息（决策理由、阻塞原因、未记录的知识）
3. **与 failure-memory 联动**：如果任务中踩过坑但未记录到 failure memory，在 Risk Notes 中标注
4. **与 Living Spec 互补**：spec.md 记录"项目做什么"，Context Snapshot 记录"当前会话在哪里"
5. **恢复时必读**：新 Agent 接手时先读 Context Snapshot，再读 spec.md Progress Summary

---

## 模型分层交接模板（Pro ↔ Flash）

> 详见 `Docs/AI/24-Pro-Flash-Model-Tiering.md`
> **自动化**：每阶段结束运行 `.trae\scripts\task-handoff.ps1 <task-name>` 自动生成以下模板，无需手写。

### Pro → Flash（Plan → Implement）

从 Pro 会话切换到 Flash 会话时使用。输出此模板后 `/clear`，切换模型，粘贴到新会话。

```text
# Handover: Plan → Implement

## 任务标识
- 任务名: <task-name>
- 项目类型: ue5 / web / other
- 状态文件: .trae/tasks/<task-name>/.task.yaml

## 当前阶段
- 当前: implement（切换到 **Flash 模型**）
- 上一阶段: plan（已完成，用户已确认）

## 关键上下文
- routing.md: .trae/tasks/<task-name>/routing.md
- tasks.md: .trae/tasks/<task-name>/tasks.md
- spec.md: .trae/tasks/<task-name>/spec.md

## 执行指令（粘贴到新 Flash 会话）
1. 读取 routing.md 了解架构决策
2. 按 tasks.md 顺序逐项执行代码编写
3. 每完成一项立即打勾 tasks.md
4. 编译验证后再标记完成
5. 全部完成后，运行: `task-handoff.ps1 <task-name>` 生成交接模板

## 禁止事项
- 不修改 Plan 阶段的架构决策（除非发现阻塞性错误）
- 不跳过编译验证
- 不新增 tasks.md 以外的功能
```

### Flash → Pro（Implement → Review+Verify）

从 Flash 会话切换回 Pro 会话时使用。**Review 和 Verify 合并为同一 Pro 会话**。

```text
# Handover: Implement → Review+Verify

## 任务标识
- 任务名: <task-name>
- 项目类型: ue5 / web / other

## 当前阶段
- 当前: review+verify（切换到 **Pro 模型**）
- 上一阶段: implement（已完成）

## 变更摘要
- 新增文件: <列表>
- 修改文件: <列表>
- 编译状态: 通过 / 失败（附错误摘要）

## Pro 会话执行指令（粘贴到新 Pro 会话）
1. **审查代码** — 检查跨文件依赖、边界条件、代码风格
2. **编译验证** — 运行编译命令
3. **修复问题** — 如有编译错误或审查问题，直接在同一会话修复
4. **输出验收报告** — 总结通过项、修复项、已知风险

## 审查重点
- 跨文件依赖完整性（Flash 的弱项）
- 边界条件处理（空值、异常、并发）
- 与已有代码风格一致性
- 是否引入网络复制/RPC（UE5 项目）
```
