---
name: "ue57-lyra-gas-ai-singleplayer"
description: Lyra/GAS/AI单机开发。GameFeature/Experience/PawnData/AbilitySet/GA/GE/AS主链路+StateTree/BT/EQS/SmartObject/SaveGame。角色能力/AI行为/战斗系统时调用。
---

# UE5.7 Lyra + GAS + AI Singleplayer Dev

## 定位

本技能面向当前工作区的 UE5.7 开发场景，目标不是只回答概念问题，而是把以下事项串成一条可落地的实现链：

- Lyra 架构扩展
- GAS 能力与数值系统开发
- AI 行为框架设计与实现
- 单机项目性能、时序、资源与排错控制
- 文档驱动的代码生成与回归验证

默认适用场景：

- 引擎版本：UE5.7
- 项目形态：单机游戏优先
- 目标平台：Windows
- 扩展方式：优先 GameFeature Plugin / 模块化扩展
- AI 框架：优先 StateTree，其次 Behavior Tree / EQS / Smart Object

## 何时调用

当用户需求包含以下任一情况时调用本技能：

- 提到 `Lyra`、`GameFeature`、`Experience`、`PawnData`、`AbilitySet`
- 提到 `GAS`、`ASC`、`GameplayAbility`、`GameplayEffect`、`AttributeSet`、`GameplayCue`
- 提到 `AIController`、`StateTree`、`Behavior Tree`、`EQS`、`SmartObject`
- 需要设计战斗、角色成长、武器、交互、敌人行为、Boss 技能、AI 小兵系统
- 需要在项目现有文档、模板、错误预防规则基础上直接落地代码与配置

不优先使用本技能的场景：

- 纯 UI / UMG / Slate 细节问题
- 纯 PCG 建筑生成问题
- 纯打包发布流程检查
- 纯蓝图节点接线且不涉及 Lyra/GAS/AI 架构

以上情况优先交给对应专项 skill，本技能只在存在 Lyra/GAS/AI 主链路时主导。

## 项目默认规则

### 核心原则

- 默认单机，不主动引入复制、RPC、预测同步方案
- 优先复用 UE / Lyra 已有机制，不重复造轮子
- 不直接修改 Lyra 基础代码
- 优先在 `Plugins/GameFeatures/` 或项目模块中做扩展
- 所有新增文件使用英文命名
- 输出必须同时覆盖 C++、数据资产、蓝图/编辑器配置、验证步骤

### 单机约束

- `SaveGame`、本地配置、离线进度优先于网络同步
- AI 状态与战斗逻辑以本地权威执行为前提
- 如果用户没有明确要求，禁止把多人复制作为默认方案
- 若文档中出现网络能力，只把它视为参考分支，不作为默认落地路径

### Lyra 约束

- 把 Lyra 当作“可升级基座”，不要直接改其核心源码
- 任何 Gameplay 初始化都要尊重 `OnExperienceLoaded`
- 输入绑定优先 `InputAction -> GameplayTag -> InputConfig -> AbilitySet`
- 角色能力优先通过 `PawnData`、`AbilitySet`、`Experience`、`GameFeatureData` 串起来

### 项目约束

- 修改插件后，必须同步更新插件目录内文档；若无文档，先创建再记录
- 方案设计与问题修复优先参考项目 `Docs` 与 `UE5_Error_Prevention_Guide.md`
- 若项目内已有 `StateTreeAIController`、自定义 `StateTreeTask`、`AAIController` 方案，优先沿用其模式扩展

## 文档优先级

所有实现与设计都按以下顺序取证：

```text
1. Docs/CodeTemplates/*                 -> 可编译模板
2. Docs/AI/*                            -> AI 执行规则、真相源、单机规则、资产检查表、AI 选型
3. Docs/APIRef/*                        -> 精确 API 与常用模式
4. Docs/ConfigRef/*                     -> .ini / Build / .uplugin 配置
5. Docs/Lyra/*                          -> Lyra 架构与挂载点
6. Docs/GAS/*                           -> GAS 分层与最佳实践
7. MLCase/Docs/Guides/UE5_Error_Prevention_Guide.md
8. MLCase/Docs/Development/target.md    -> 当前项目目标与性能约束
9. xg-uecpp-course references           -> Subsystem、DeveloperSettings、异步、插件依赖等底层方法论
10. 官方文档 / 社区资料                 -> 用于补足 5.7、AI、StateTree、SmartObject 最佳实践
```

## 外部参考原则

结合 Epic 官方与社区资料，默认采用以下外部共识：

- Lyra 是模块化样例工程，推荐通过 GameFeature Plugin 与 Experience 扩展
- GAS 更适合把行为、数值、状态、表现、异步步骤拆分到 Ability / Effect / Attribute / Cue / Task
- Lyra 交互系统适合通过 Ability 驱动世界交互，而不是把交互逻辑散落到角色 Tick
- StateTree 适合作为高性能分层状态机，适合单机敌人、可交互 Actor 与轻量 AI 行为
- Smart Object 适合做可预约的世界交互点，配合 GameplayTag 过滤
- Mass + StateTree + SmartObject 只在“超大量 AI 实体”场景下考虑，不作为默认第一选择

结合本地课程型知识库，默认吸收以下底层方法论，但不继承其网络项目默认假设：

- `Subsystem` 适合运行时服务组织
- `DeveloperSettings` 与 `.ini` 适合项目级配置注入
- `AsyncTask / Async / FRunnable / FGraphEvent / ParallelFor / FControlFlow` 适合不同层级的异步任务
- 插件、模块和第三方库集成要显式规划 `Build.cs` 与生命周期边界

## 输入契约

在开始方案或实现前，必须尽量收集以下信息：

1. 需求类型：新功能 / 修改 / 修复 / 重构 / 性能优化
2. 所属链路：Lyra / GAS / AI / Input / Equipment / UI / SaveGame
3. 目标对象：玩家、敌人、Boss、可交互物、世界系统
4. 行为描述：触发条件、执行过程、成功/失败结果
5. 当前挂载点：GameFeature、Experience、PawnData、组件、控制器、蓝图
6. 数据需求：是否需要 Data Asset、曲线、标签、配置、存档
7. AI 规模：单个精英敌人 / 少量敌人 / 成群实体
8. 性能约束：帧预算、内存预算、是否避免 Tick、是否避免大规模 Actor

若信息不足，优先补齐这些内容后再生成代码。

## 需求路由与决策树

### Lyra 主链

```text
Experience / GameFeature / PawnData / InputConfig / AbilitySet
-> 使用 Lyra 扩展链路
-> 生成资源配置步骤 + C++ 扩展 + 验证清单
```

### GAS 主链

```text
技能 / Buff / Debuff / 伤害 / 回复 / 被动效果
-> Ability / Effect / AttributeSet / Cue / Task 分层
-> 优先数据驱动
-> 再决定是否需要自定义 C++
```

### AI 主链

```text
轻中型单机敌人 / 关卡内行为切换
-> 优先 StateTree + AIController + 感知/查询

需要复杂决策树、已有 Blackboard 资产
-> Behavior Tree + Blackboard + EQS

需要世界交互点、占位、预约、Tag 过滤
-> Smart Object

需要成群低成本实体
-> 评估 Mass + StateTree，仅在明确大规模 AI 需求下采用
```

### 交互主链

```text
玩家与世界对象交互
-> 优先 Lyra Interaction / Ability 驱动交互
-> 需要预约占位时接 Smart Object
-> 需要战斗反馈时接 GAS Event / Cue
```

## 标准输出结构

每次交付必须产出以下 6 件套：

1. 需求映射：本次需求属于哪条链路，为什么
2. 架构方案：挂载点、模块边界、主要类与数据资产
3. 文件清单：新增/修改的 `.h`、`.cpp`、`Build.cs`、`.uplugin`、数据资产
4. 配置步骤：GameFeatureData、Experience、PawnData、InputConfig、AbilitySet、AI 资产
5. 验证清单：编译、运行时、性能、回归点
6. 文档更新项：需要同步更新的项目或插件文档

## 多智能体协作规则

当任务复杂、跨系统或适合并行拆分时，本技能可作为总控规范使用。

### 推荐角色划分

1. 架构代理：负责模块边界、挂载点、目录与命名、GameplayTag 根节点
2. Lyra/GAS 代理：负责 `Experience / PawnData / InputConfig / AbilitySet / GA / GE / AS`
3. AI 代理：负责 `StateTree / Behavior Tree / EQS / SmartObject / AIController`
4. 内容代理：负责 DataAsset、蓝图、GameFeatureData、资源接线
5. 测试代理：负责编译检查、运行时冒烟、日志检查、回归清单
6. 性能代理：负责 Tick、感知频率、异步边界、内存与运行成本审查

### 协作原则

- 一个领域一个真相源，避免多个代理同时改同一类规则
- `GameplayTag`、目录规范、父类选型优先由架构代理统一
- 代码代理不跳过内容配置，内容代理不跳过验证项
- 测试代理只负责验证与风险收敛，不负责重写主要实现
- 性能代理优先否决高 Tick、乱线程、无边界异步和无理由大规模框架引入

### 适合拆分的任务

- 新战斗系统同时涉及 Lyra、GAS、AI、UI、装备或交互
- 需要同时改 C++、数据资产、GameFeature 配置与 AI 资产
- 需要并行做实现、测试和性能审查

### 不适合拆分的任务

- 单文件小修
- 单一函数修复
- 只改一个数据资产
- 只读问题分析

## 任务交接模板

多智能体协作时，每个代理至少交付以下模板内容：

```text
任务标题:
任务类型:
所属链路: Lyra / GAS / AI / UI / SaveGame / Other

目标:
- 一句话说明最终目标

允许修改:
- 允许修改的目录、模块、资产

禁止修改:
- 不允许触碰的系统、目录、网络逻辑、核心源码

输入约束:
- 依赖的类、Tag、数据资产、插件、模块

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

### 交接最低要求

- 写清主挂载点
- 写清依赖模块
- 写清新增 Tag
- 写清新增资源
- 写清验证步骤
- 写清是否影响现有功能

多智能体协作时，优先参考：

- `Docs/AI/09-Agent-Handoff-Templates.md`
- `Docs/AI/10-Execution-Examples.md`
- `Docs/AI/11-Skill-Routing-Workflow.md`
- `Docs/AI/12-MultiAgent-Workflow.md`

当前项目推荐的最小协作闭环为：

- `ue-project-router`
- `ue-lyra-gas-implementer`
- `ue-ai-validator`

## 实现工作流

### Stage 1: 需求归类

- 确认是 Lyra、GAS、AI 还是跨链路复合需求
- 确定主入口：GameFeature / Experience / Character / Controller / Component / DataAsset
- 找到本地模板与参考文档
- 优先读取 `Docs/AI/01-AI-Development-Playbook.md` 与 `Docs/AI/02-Project-Truth-Source.md`
- 若任务描述不清或涉及路由选择，优先读取 `Docs/AI/11-Skill-Routing-Workflow.md`

### Stage 2: 方案设计

- 先给 1-3 个方案
- 明确技术可行性、性能影响、实现复杂度、维护成本、风险与缓解
- 单机项目中默认把“无网络复制版本”作为方案 1

### Stage 3: 文件与依赖规划

- 先列出文件变更清单
- 检查 `Build.cs` 模块依赖
- 检查是否需要 `GameplayAbilities`、`GameplayTags`、`GameplayTasks`、`StateTreeModule`、`AIModule`、`GameplayStateTreeModule`、`SmartObjectsModule`
- 能用前向声明就不用头文件直引
- 若新增配置或服务层逻辑，评估是否更适合 `Subsystem` 或 `DeveloperSettings`

### Stage 4: 代码与资产落地

- 先定义数据资产与标签
- 再实现最小 C++ 类对
- 再补蓝图或编辑器配置步骤
- 最后接入 Experience / PawnData / GameFeatureData / AI 资产

### Stage 5: 调试验证

- 先修编译错误，再查运行时时序
- 优先检查 `OnExperienceLoaded`、Ability 授予链、AI Possess 时机、StateTree/BT 资产绑定
- 若出现项目已知模式错误，先查错误预防文档再修
- 若涉及线程、异步或后台任务，先确认 UObject 访问是否回到 GameThread
- 若为多智能体协作任务，统一按 `Docs/AI/07-Test-Checklists.md` 收敛验证结果
- 若任务属于常见模式，优先从 `Docs/AI/10-Execution-Examples.md` 选择最近样例再改写

### Stage 6: 文档沉淀

- 更新相关项目文档
- 修改插件时同步更新插件目录文档
- 不额外创建重复报告，优先沉淀到标准文档

## Lyra + GAS 实现规则

### 角色能力链

```text
InputAction
-> GameplayTag
-> InputConfig
-> AbilitySet
-> GameplayAbility
-> GameplayEffect / Cue / Attribute
```

### 设计原则

- 玩家主动技能：优先 `ULyraGameplayAbility` 体系
- 装备相关技能：优先挂到 Equipment / Weapon 链路
- 数值修改：优先 GE 数据资产
- 持续过程：优先 AbilityTask 或状态机，不用裸 Tick 堆逻辑
- 复杂表现：逻辑留在 GAS，表现用 Cue / 动画 / UI 分层

### 常见模式

#### 新能力

```text
Ability 类
-> AbilitySet
-> InputConfig
-> PawnData
-> Experience / GameFeatureData
```

#### 新武器或装备

```text
ItemDefinition
-> EquipmentDefinition
-> WeaponInstance / EquipmentInstance
-> AbilitySet
-> HUD / Input / UI 提示
```

#### 新属性集

```text
AttributeSet
-> GE 配置
-> UI 显示
-> 伤害/恢复结算
```

## AI 设计规则

### 默认 AI 方案

优先顺序如下：

1. `StateTree + AIController`：项目当前最贴合，适合单机敌人、局部状态切换、动作组织
2. `Behavior Tree + Blackboard + EQS`：适合已有 BT 资产或复杂决策条件
3. `Smart Object`：适合可预约交互位、占位动作、环境交互
4. `Mass + StateTree`：仅适合超大规模实体

### StateTree 适用规则

- 当行为天然可拆成 `Idle / Patrol / Chase / Attack / Recover / Dead` 等分层状态时优先使用
- 当项目已有 `UStateTreeAIComponent` 和自定义 `FStateTreeTaskCommonBase` 任务时，优先继续扩展该模式
- 任务节点只做单一职责，例如“取玩家”“更新目标点”“执行攻击窗口”
- 复杂数值判定与伤害结算放回 GAS，不在 StateTree Task 中硬编码

### Behavior Tree 适用规则

- 已有 Blackboard 数据模型或大量现成 BT 资源时使用
- 需要复杂条件组合、服务轮询、成熟调试视图时使用
- 避免把战斗核心逻辑散落到多个 BT Task；BT 主要负责决策，技能执行仍交给 GAS

### EQS 适用规则

- 需要动态找掩体、找攻击位置、找最近交互点时优先使用
- 查询结果用于“选择目标位置”，不要在 EQS 中承载业务结算

### Smart Object 适用规则

- 场景中存在“可预约、可占用、可释放”的交互位时使用
- 用 GameplayTag 做过滤与匹配
- 要明确占位失败、释放时机、中断回退逻辑

### AI 与 GAS 协同

- AI 决策层决定“何时释放能力”
- GAS 负责“能力如何执行、消耗、结算、表现”
- 状态切换使用 Tag、事件或显式信号，不用跨系统互相硬引用
- Boss 与精英敌人的技能窗口优先用 Ability + Montage + Event 驱动

## 项目内参考映射

### 优先参考的本地文档

- `Docs/AI/01-AI-Development-Playbook.md`
- `Docs/AI/02-Project-Truth-Source.md`
- `Docs/AI/03-Singleplayer-Lyra-GAS-Rules.md`
- `Docs/AI/04-Asset-Checklists.md`
- `Docs/AI/05-StateTree-BT-EQS-SmartObject.md`
- `Docs/AI/06-GameplayTag-Registry.md`
- `Docs/AI/07-Test-Checklists.md`
- `Docs/AI/08-AntiPatterns.md`
- `Docs/AI/09-Agent-Handoff-Templates.md`
- `Docs/AI/10-Execution-Examples.md`
- `Docs/AI/11-Skill-Routing-Workflow.md`
- `Docs/AI/12-MultiAgent-Workflow.md`
- `Docs/Lyra/02-ExperienceSystem.md`
- `Docs/Lyra/03-GameFeaturePlugins.md`
- `Docs/Lyra/05-PawnCharacterSystem.md`
- `Docs/Lyra/09-InputSystem.md`
- `Docs/GAS/03-GameplayAbility.md`
- `Docs/GAS/04-GameplayEffect.md`
- `Docs/GAS/07-AbilityTasks.md`
- `Docs/GAS/10-BestPractices.md`
- `Docs/UE5.7/02-LyraUpgrade.md`
- `MLCase/Docs/Guides/UE5_Error_Prevention_Guide.md`

### 优先参考的模板

- `Docs/CodeTemplates/NewGameFeature/`
- `Docs/CodeTemplates/NewExperience/`
- `Docs/CodeTemplates/NewPawnData/`
- `Docs/CodeTemplates/NewInputConfig/`
- `Docs/CodeTemplates/NewGameplayAbility/`
- `Docs/CodeTemplates/NewGameplayEffect/`
- `Docs/CodeTemplates/NewAttributeSet/`
- `Docs/CodeTemplates/NewEquipmentType/`
- `Docs/CodeTemplates/NewWeaponType/`

### 可吸收的底层方法论文档

- `xg-uecpp-course/references/配置与依赖注入.md`
- `xg-uecpp-course/references/异步执行模式.md`
- `xg-uecpp-course/references/日志断言与调试.md`
- `xg-uecpp-course/references/增强输入系统.md`
- `xg-uecpp-course/references/GAS体系详解.md`

### 当前项目 AI 线索

- 若需求涉及 TwinStick AI，可参考项目已存在的 `StateTreeAIController` 与自定义 `StateTreeTask`
- 若需求涉及策略单位移动，可参考当前 `StrategyUnit` 与 `AAIController` 的移动控制方式
- 若方案与现有 AI 架构冲突，先说明冲突点，再提出渐进式迁移方案

## 质量检查清单

### UE 宏与编译

- `UCLASS/USTRUCT/UFUNCTION/UPROPERTY` 使用正确
- `.h/.cpp` 成对提供
- `GENERATED_BODY()` 完整
- `Build.cs` 依赖最小化且无循环依赖
- 编辑器专用依赖使用条件判断包裹
- 不猜函数名，先查 `Docs/APIRef/*`

### Lyra / GAS 时序

- 没有在错误时机使用 ASC
- 没有绕过 `PawnData / AbilitySet / InputConfig` 直接硬连输入
- 没有把复杂逻辑塞进 `BeginPlay` 或 Tick
- Gameplay 初始化尊重 `OnExperienceLoaded`

### AI 质量

- 控制器、Pawn、AI 资产绑定关系清晰
- StateTree/BT 节点职责单一
- 感知、查询、目标选择与技能执行分层
- 中断、死亡、失去目标、占位失败路径完整

### 单机性能

- 尽量事件驱动，避免无意义 Tick
- 尽量数据驱动，避免硬编码路径
- 小规模 AI 不提前上 Mass
- 大量计算考虑分帧或异步，但要明确线程安全边界
- 异步逻辑涉及 UObject 时必须明确切回 GameThread

### 文档与沉淀

- 修改插件后同步更新插件文档
- 修复通用错误后同步更新错误预防文档
- 更新已有标准文档，不重复造临时文档
- 若涉及新 Tag，检查 `Docs/AI/06-GameplayTag-Registry.md`
- 若为多人代理协作，交付时附带统一任务交接模板

## 常见失败排查

### 能力不生效

- Ability 是否被 `AbilitySet` 授予
- `InputTag` 是否正确映射到 `InputConfig`
- `PawnData` 和 `Experience` 是否引用正确资源
- 是否有 Tag、Cost、Cooldown、激活条件阻塞

### AI 不行动

- Pawn 是否被正确 Possess
- `AIController` 是否绑定了 StateTree / BT 资产
- 感知或目标获取节点是否返回有效对象
- 状态切换信号是否真正触发

### 交互无反应

- 交互入口是否走 Ability 或统一交互接口
- Smart Object 是否可查询、可预约、可释放
- GameplayTag 过滤是否过严

### 编译或链接错误

- 优先查 `UE5_Error_Prevention_Guide.md`
- 再查 `Docs/Troubleshooting/CompileErrors.md`
- 编辑器依赖、模块依赖、前向声明、函数签名逐项核对

### 资产接线错误

- 优先查 `Docs/AI/04-Asset-Checklists.md`
- 检查 `Experience / GameFeatureData / PawnData / InputConfig / AbilitySet`
- 检查 `StateTree / Blackboard / EQS / SmartObject` 的输入输出与绑定

### 多代理输出不一致

- 回到任务交接模板，确认目标、输入约束、输出要求是否一致
- 优先由架构代理统一 `GameplayTag`、目录规范、挂载点和父类选型
- 测试代理统一收敛最终验证与风险清单

## 输出风格要求

- 先给结论，再给实现路径
- 优先给最小可落地方案
- 代码、配置、蓝图步骤必须同时给
- 不只讲概念，必须给挂载点与文件落点
- 若存在 2 种以上合理方案，必须做矩阵对比
- 若与项目既有模式冲突，必须明确说明冲突与替代方案

## 升级与扩展策略

- 优先扩展现有 `lyra-gas-dev` 能力，而不是重复维护两套相互冲突的规则
- 当新需求落在纯 AI、纯 StateTree、纯 SmartObject 深水区时，可继续拆分出独立子 skill
- 若未来项目转向大规模群体 AI，可在本技能之上再补 `Mass AI` 专项指引

## Enemy AI 实战模式（提取自 GAS 教程）

### 模式: C++ AIController + BehaviorTree

```cpp
// AIController 核心框架
class AAuraAIController : public AAIController
{
    UPROPERTY() TObjectPtr<UBehaviorTreeComponent> BehaviorTreeComponent;
    
    virtual void OnPossess(APawn* InPawn) override
    {
        Super::OnPossess(InPawn);
        // 只在服务器运行 BT
        RunBehaviorTree(BehaviorTree);
    }
};
// Blackboard Key: TargetActor, CombatTarget, bIsRanged, bIsMelee, HomeLocation
```

### 模式: Melee Attack — Tag-Driven Socket

```cpp
// 使用 GameplayTag 驱动骨骼 Socket 选择
struct FTaggedMontage {
    UPROPERTY() TObjectPtr<UAnimMontage> Montage;
    UPROPERTY() FGameplayTag SocketTag;          // 如: CombatSocket.Weapon.RightHand
    UPROPERTY() FGameplayTag MontageTag;          // 如: Montage.Attack.Melee.Weapon1
};
TArray<FTaggedMontage> AttackMontages;            // 武器不同攻击动画

// 接口获取 Socket 位置
FVector GetCombatSocketLocation(const FGameplayTag& SocketTag);

// 近战碰撞检测
UKismetSystemLibrary::SphereOverlapActors(World, Origin, Radius, ObjectTypes, AActor::StaticClass(), IgnoreActors, OutActors);
```

### 模式: Ranged Attack — 投射物系统

```cpp
class AAuraProjectile : public AActor
{
    UPROPERTY() TObjectPtr<UProjectileMovementComponent> ProjectileMovement;
    UPROPERTY() TObjectPtr<USphereComponent> Sphere;
    TObjectPtr<UGameplayEffect> DamageEffect;
    bool bIsHoming;
    
    void BeginPlay() { Sphere->OnComponentBeginOverlap.AddDynamic(this, &AAuraProjectile::OnOverlap); }
    void OnOverlap(...) { ApplyGameplayEffectSpecToTarget(Spec, TargetASC); Destroy(); }
};

// 玩家角色 SpawnProjectile
UPROPERTY(EditDefaultsOnly) TSubclassOf<AAuraProjectile> ProjectileClass;
AAuraProjectile* Proj = GetWorld()->SpawnActorDeferred<AAuraProjectile>(ProjectileClass, Transform);
Proj->SetOwner(this);
Proj->FinishSpawning(Transform);
Proj->SetHomingTarget(TargetActor);  // 可选追踪
```

### 模式: GameplayCue — 近战打击效果

```cpp
// 在 GA 的 ActivateAbility 中
FGameplayCueParameters CueParams;
CueParams.Location = HitResult.Location;
CueParams.Normal = HitResult.Normal;
CueParams.EffectCauser = GetAvatarActor();

K2_ExecuteGameplayCueWithParams(Tag_MeleeImpact, CueParams);
// Tag 如: GameplayCue.Enemy.MeleeImpact
```

### 模式: Hit React + 死亡

```cpp
// Enemy 被击中 → 播放受击蒙太奇
UAuraAbilityTask_PlayMontageAndWait* Task = ...;
Task->OnCancelled.BindLambda([this]() { EndAbility(); });

// 检查死亡
if (AttributeSet->GetHealth() <= 0.0f) {
    // 溶解效果
    Enemy->GetMesh()->SetScalarParameterValueOnMaterials("Dissolve", 1.0f);
    Enemy->SetLifeSpan(3.0f);
}
```

### 模式: Save/Load — MVVM + Checkpoint

```cpp
// MVVM ViewModel for Save Slots
class UMVVM_LoadSlot : public UMVVMViewModelBase
{
    UPROPERTY(BlueprintReadWrite, FieldNotify) FString PlayerName;
    UPROPERTY(BlueprintReadWrite, FieldNotify) int32 PlayerLevel;
    UPROPERTY(BlueprintReadWrite, FieldNotify) bool bHasSave;
};

// Checkpoint: 保存 PlayerStart Tag
void SaveWorldState(ULoadScreenSaveGame* SaveGame) {
    SaveGame->PlayerStartTag = CurrentCheckpointTag;
    SaveGame->PlayerLevel = PlayerState->Level;
}
void LoadWorldState(ULoadScreenSaveGame* SaveGame) {
    // ChoosePlayerStart_Implementation 根据 Tag 找到对应 PlayerStart
}

// Map Travel
UGameplayStatics::OpenLevelBySoftObjectPtr(this, TargetMap);
```

遇到以下情况应主动升级为“先分析再实施”：

1. 需要修改 Lyra 核心源码
2. 需要同时重构 GameFeature、Experience、PawnData 与核心角色基类
3. 需求横跨 Lyra、GAS、AI、UI、存档多个系统且约束不清
4. 需要引擎源码改动或第三方框架深度集成
5. 需要把现有 Behavior Tree 体系整体迁移到 StateTree / Mass
