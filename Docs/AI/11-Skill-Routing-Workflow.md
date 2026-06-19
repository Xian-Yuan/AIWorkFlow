# Skill Routing Workflow

## 目标

本文件用于把“用户输入一个需求后，AI 如何先判断该用什么 skill，再按需加载相关规则与文档”的流程显式化。

目标是减少以下问题：

- 选错 skill
- 同时加载过多无关 skill
- 把单机需求误路由到多人网络方案
- 本应单 agent 解决的问题被过度拆分
- 本应多 agent 协作的问题被单 agent 硬撑

## 适用范围

适用于当前工作区内的 UE5.7 开发任务，默认前提如下：

- 项目类型：单机优先
- 技术基座：Lyra + GAS
- 常见扩展：GameFeature Plugin、Experience、PawnData、InputConfig、AbilitySet
- 常见 AI：StateTree、Behavior Tree、EQS、SmartObject

## 总流程

```text
用户输入需求
-> 判断是否为 UE / Lyra / GAS / AI 相关
-> 选择主 skill
-> 判断是否需要补充次 skill
-> 读取 Docs/AI 与相关专项文档
-> 判断是否需要多 agent 协作
-> 进入分析 / 设计 / 实现 / 验证
```

## Step 1：先判断是否为 UE 任务

满足任意一项，视为 UE 相关任务：

- 提到 UE、虚幻、Lyra、GAS、ASC、GameplayAbility、GameplayEffect
- 提到 GameFeature、Experience、PawnData、InputConfig、AbilitySet
- 提到 AIController、StateTree、Behavior Tree、EQS、SmartObject
- 提到 UMG、Slate、Blueprint、Build.cs、模块依赖、打包、编译错误

若为 UE 任务，必须先进入 skill 路由流程。

## Step 2：选择主 skill

主 skill 只选一个，用于确定本次任务的主链路。

### 主 skill 选择规则

#### 1. `ue-lyra-gas-implementer`

优先用于：

- Lyra + GAS + AI 复合需求（已合并 ue-lyra-gas-implementer
+ ue5-debug-validation
-> 适合复杂功能开发后的质量收敛

ue-lyra-gas-implementer
+ ue5-architecture
-> 适合新增模块、插件、Build.cs 依赖规划

ue-lyra-gas-implementer
+ ue5-ui-umg-slate
-> 适合战斗或交互功能同时包含 HUD / Widget 接线
```

### 不建议的情况

- 不要同时把多个主 skill 当主导者
- 不要因为“可能有用”就加载大量无关专项 skill
- 不要在单机项目里把复制/网络相关 skill 当默认次 skill

## Step 4：读取文档顺序

无论主 skill 是什么，只要进入当前项目开发，默认按以下顺序读取：

1. `Docs/AI/01-AI-Development-Playbook.md`
2. `Docs/AI/02-Project-Truth-Source.md`
3. `Docs/AI/03-Singleplayer-Lyra-GAS-Rules.md`
4. 当前任务最相关的 `Docs/AI/*`
5. `Docs/CodeTemplates/*`
6. `Docs/APIRef/*`
7. `Docs/Lyra/*` 或 `Docs/GAS/*`
8. `MLCase/Docs/Guides/UE5_Error_Prevention_Guide.md`

## Step 5：判断单 agent 还是多 agent

### 默认使用单 agent

以下任务优先单 agent：

- 单文件修改
- 单个 Ability 修改
- 单个编译错误修复
- 单个 DataAsset 调整
- 纯文档更新

### 满足以下任意两项，建议启用多 agent

- 涉及两个以上系统
- 预计改动 8 个以上文件
- 同时涉及代码、数据资产和蓝图/配置
- 需要实现、测试、性能审查并行进行
- 明显是跨 Lyra、GAS、AI 的复合需求

### 多 agent 默认结构

- 小型协作：`1 总控 + 1 实现 + 1 验证`
- 大型协作：`1 总控 + 架构 + Lyra/GAS + AI + 内容 + 测试 + 性能`

交接模板与样例参考：

- `Docs/AI/09-Agent-Handoff-Templates.md`
- `Docs/AI/10-Execution-Examples.md`

## Step 6：进入需求分类

选定主 skill 后，把需求归入以下主链路之一：

- Lyra 链：Experience、GameFeature、PawnData、InputConfig、AbilitySet
- GAS 链：Ability、Effect、Attribute、Cue、Task
- AI 链：StateTree、BT、EQS、SmartObject、AIController
- UI 链：UMG、Slate、HUD、焦点、输入模式
- 架构链：模块、插件、依赖、Build.cs
- 调试链：编译、运行时、回归、性能

如果命中多条链路，选择“最影响挂载点和实现路径”的那条作为主链路，其余作为次链路。

## Step 7：禁止误路由规则

### 单机项目默认禁止

- 因为看到 GAS 文档就默认引入复制/RPC
- 因为看到 Networking 文档就把网络同步当标准答案
- 因为任务复杂就直接上 Mass
- 因为蓝图能做就跳过 Lyra/GAS 标准挂载链

### 必须回退重新判断的情况

- 主 skill 选定后发现挂载点不清楚
- 需求横跨过多系统但缺少约束
- 当前 skill 明显不能覆盖关键实现链
- 方案与项目现有模式冲突

## 典型路由示例

### 示例 1：新增敌人技能包

```text
需求: 做一个精英敌人，带 StateTree、攻击技能、受击反馈
主 skill: ue-lyra-gas-implementer
次 skill: ue5-debug-validation
路由原因: 同时涉及 Lyra/GAS/AI，且最终需要验证收敛
```

### 示例 2：修一个 Widget 焦点问题

```text
需求: 打开背包后手柄焦点丢失
主 skill: ue5-ui-umg-slate
次 skill: ue5-debug-validation
路由原因: 主问题属于 UI 焦点与输入模式，不需要 Lyra/GAS 主链
```

### 示例 3：新建一个 GameplayAbility

```text
需求: 给玩家新增一个冲刺技能
主 skill: ue-lyra-gas-implementer
次 skill: 无，必要时补 ue5-debug-validation
路由原因: 虽然是 Ability，但通常要接 InputConfig、AbilitySet、PawnData
```

### 示例 4：不清楚需求该怎么落

```text
需求: 我想做一个战斗交互系统，但不确定挂在哪里
主 skill: ue-lyra-gas-implementer
次 skill: 无，必要时补 ue5-debug-validation
路由原因: Router 内置归类能力，直接进入主实现 skill。若涉及 AI 行为，补 ue-ai-validator
```

## 输出要求

在完成 skill 路由后，至少要向后续执行阶段明确以下内容：

- 主 skill
- 次 skill
- 主链路
- 次链路
- 推荐文档入口
- 是否启用多 agent
- 是否存在禁止误路由风险

## 维护规则

- 当新增专项 skill 时，必须更新本文件
- 当项目默认链路变化时，必须同步更新本文件
- 当发现 AI 频繁误选 skill 时，应优先修订本文件，而不是临时口头纠正
