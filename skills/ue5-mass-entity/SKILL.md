---
name: "ue5-mass-entity"
description: Mass Entity大规模实体框架。ECS架构/EntityConfig/Processor/Trait/StateTree集成/Blueprint配置。100+单位场景使用。
---

# UE5 Mass Entity 框架全栈指南

## 概述

Mass Entity 是 UE5 的**数据驱动 ECS（Entity-Component-System）框架**，专为大规模实体（数百到上万个）设计。核心思想：将数据与逻辑分离，用连续的 Chunk 内存布局实现缓存友好、可并行化的批处理。

### 何时使用 Mass Entity

| 场景 | 决策 |
|------|------|
| 100+ 同时存在的同质化实体 | ✅ Mass Entity |
| 人群模拟、丧尸潮、战场单位 | ✅ Mass Entity |
| <50 个复杂 AI（每个有独立 BT/EQS） | ❌ 用 AIController + BehaviorTree |
| 需要复杂动画、单 Actor 逻辑 | ❌ 用普通 Actor |

---

## 核心概念

```
┌──────────────────────────────────────────────────────────────┐
│ Archetype (原型)                                              │
│   ┌─ Fragment A (数据)  ┌─ Fragment B (数据)  ┌─ Tag (标记)  │
│   │  FTransformFragment │  FMassVelocityFragment│ FMyTag      │
│   └─────────────────────┴─────────────────────┴──────────────│
├──────────────────────────────────────────────────────────────┤
│ Chunk (16KB 连续内存块，存放 64-128 个实体)                     │
│   [Entity0|Entity1|Entity2|...|EntityN]                      │
├──────────────────────────────────────────────────────────────┤
│ Processor (处理器)                                            │
│   按 Tag 查询 → 遍历 Chunk → 读/写 Fragment → 批量处理         │
└──────────────────────────────────────────────────────────────┘
```

### 术语表

| 术语 | 说明 |
|------|------|
| **Entity** | 轻量级句柄（`FMassEntityHandle`：int32 Index + int32 Serial），不包含任何数据 |
| **Fragment** | 纯数据结构（`FMassFragment`），类似 ECS 的 Component。如 `FTransformFragment`、`FMassVelocityFragment` |
| **Tag** | 零数据的标记结构体（`FMassTag`），用于快速过滤实体。如 `FLyraMassChasePlayerTag` |
| **Trait** | `UMassEntityTraitBase` 子类，用于在实体模板中批量添加 Fragment/Tag。如 `ULyraMassAgentRadiusTrait` |
| **Processor** | `UMassProcessor` 子类，按 Fragment/Tag 查询实体并执行逻辑。如 `ULyraMassChasePlayerProcessor` |
| **Archetype** | 实体数据布局的唯一签名（Fragment 组合）。相同 Archetype 的实体放在同一 Chunk 中 |
| **Chunk** | 16KB 连续内存块，以 SoA（Structure of Arrays）方式排列 Fragment 数据 |
| **MassEntityConfig** | DataAsset（`UMassEntityConfigAsset`），定义实体的 Trait 组合 |
| **MassSpawner** | Actor，从 MassEntityConfig 批量生成实体 |
| **MassEntitySubsystem** | 全局单例（`UWorldSubsystem`），管理所有实体的生命周期 |

### Fragment 基类层次

```cpp
// 数据 Fragment（有成员变量）
struct FMyDataFragment : public FMassFragment {};

// 共享 Fragment（多个实体共享同一份数据，节省内存）
struct FMySharedFragment : public FMassSharedFragment {};

// 常量共享 Fragment（只读，可跨 Chunk 共享）
struct FMyConstSharedFragment : public FMassConstSharedFragment {};

// Tag（零数据，仅标记）
struct FMyTag : public FMassTag {};
```

---

## 架构与处理阶段

### Mass 处理管线（Processing Phases）

```
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ PrePhysics   │→│ DuringPhysics│→│ PostPhysics  │
│ (移动/导航)  │  │ (物理求解)   │  │ (后处理)     │
└──────────────┘  └──────────────┘  └──────────────┘
         ↑ 推荐在此阶段处理移动和 AI 逻辑
```

### 内置常用 Processor 组

| Processor 组 | 功能 |
|-------------|------|
| `MassMovement` | 基础移动（速度、加速度、转向） |
| `MassNavigation` | 导航路径跟随 |
| `MassAvoidance` | 避障（邻居检测 + 分离力） |
| `MassLOD` | LOD 距离分级（近距=高细节，远距=低开销） |
| `MassRepresentation` | 可视化表示（ISM/HISM/SkeletalMesh 切换） |
| `MassCrowd` | 人群专用（更精细的避让与动画） |
| `MassZoneGraphNavigation` | ZoneGraph 导航（沿预定义通道移动） |
| `MassSmartObject` | SmartObject 交互 |

### 必要 Fragment 速查

| Fragment | 用途 | 通常来源 |
|----------|------|---------|
| `FTransformFragment` | 实体世界变换 | MassMovement 自动添加 |
| `FMassVelocityFragment` | 速度向量 | MassMovement |
| `FAgentRadiusFragment` | 避障半径 | MassNavigation / ULyraMassAgentRadiusTrait |
| `FMassDesiredMovementFragment` | 期望移动（速度+朝向） | 自定义 Processor 写入 |
| `FMassRepresentationFragment` | 可视表示句柄 | MassRepresentation |
| `FMassEntityLODFragment` | LOD 等级 | MassLOD |

---

## 模式 1：创建简单追逐实体（纯 C++）

```cpp
// 1. 定义 Tag
USTRUCT()
struct FLyraMassChasePlayerTag : public FMassTag
{
    GENERATED_BODY()
};

// 2. 定义 Trait（将 Tag 添加到实体模板）
UCLASS()
class ULyraMassChasePlayerTrait : public UMassEntityTraitBase
{
    GENERATED_BODY()
    
    virtual void BuildTemplate(FMassEntityTemplateBuildContext& BuildContext,
        const UWorld& World) const override
    {
        // 添加追逐标记
        BuildContext.AddTag<FLyraMassChasePlayerTag>();
        
        // 添加必要 Fragment（确保 Processor 能查询到）
        BuildContext.AddFragment<FMassVelocityFragment>();
        BuildContext.RequireFragment<FTransformFragment>();
    }
};

// 3. 定义 Processor（每帧更新）
UCLASS()
class ULyraMassChasePlayerProcessor : public UMassProcessor
{
    GENERATED_BODY()
    
public:
    ULyraMassChasePlayerProcessor()
    {
        // 注册处理阶段
        ExecutionOrder.ExecuteInGroup = UE::Mass::ProcessorGroupNames::Movement;
        ExecutionOrder.ExecuteAfter.Add(UE::Mass::ProcessorGroupNames::Avoidance);
        ProcessingPhase = EMassProcessingPhase::PrePhysics;
        bAutoRegisterWithProcessingPhases = true;
    }

    virtual void Execute(FMassEntityManager& EntityManager, FMassExecutionContext& Context) override
    {
        // 创建查询：筛选带 Tag + Fragment 的实体
        FMassEntityQuery EntityQuery;
        EntityQuery.AddTagRequirement<FLyraMassChasePlayerTag>(EMassFragmentPresence::All);
        EntityQuery.AddRequirement<FTransformFragment>(EMassFragmentAccess::ReadWrite);
        EntityQuery.AddRequirement<FMassVelocityFragment>(EMassFragmentAccess::ReadWrite);
        
        EntityQuery.ForEachEntityChunk(EntityManager, Context,
            [this](FMassExecutionContext& Context)
        {
            const int32 NumEntities = Context.GetNumEntities();
            const auto& TransformList = Context.GetFragmentView<FTransformFragment>();
            auto& VelocityList = Context.GetMutableFragmentView<FMassVelocityFragment>();
            
            for (int32 i = 0; i < NumEntities; ++i)
            {
                FVector EntityLoc = TransformList[i].GetTransform().GetLocation();
                FVector ToPlayer = (PlayerLocation - EntityLoc).GetSafeNormal();
                EntityLoc += ToPlayer * MoveSpeed * DeltaTime;
                
                TransformList[i].GetMutableTransform().SetLocation(EntityLoc);
                VelocityList[i].Value = ToPlayer * MoveSpeed;
            }
        });
    }
};
```

---

## 模式 2：蓝图创建 Mass Entity Config（不需要写 C++）

### 通过 MCP 自动化创建（推荐）

```json
// 1. 启用必需的 Mass 插件
{
  "method": "system.run_console_command",
  "params": {
    "command": "Plugin Enable MassEntity"
  }
}
// 同样启用: MassActors, MassAI, MassCrowd, MassGameplay, StateTree

// 2. 创建 MassEntityConfig DataAsset
{
  "method": "blueprint.create",
  "params": {
    "name": "DA_MassEntityConfig_Zombie",
    "path": "/Game/System/Crowd",
    "type": "MassEntityConfigAsset"
  }
}

// 3. 创建 Spawner Blueprint
{
  "method": "blueprint.create",
  "params": {
    "name": "BP_MassSpawner_Enemies",
    "path": "/Game/System/Crowd",
    "parentClass": "MassSpawner"
  }
}

// 4. 设置 Spawner 的实体配置
{
  "method": "blueprint.set_property",
  "params": {
    "blueprint": "/Game/System/Crowd/BP_MassSpawner_Enemies",
    "property": "EntityTypes",
    "value": [{"Config": "/Game/System/Crowd/DA_MassEntityConfig_Zombie", "Count": 500}]
  }
}
```

### 手动创建步骤（编辑器内）

1. **启用插件**：Edit → Plugins → 搜索并启用 `MassEntity`、`MassActors`、`MassAI`、`MassCrowd`、`StateTree`。重启编辑器。

2. **创建 MassEntityConfig DataAsset**：
   - Content Browser 右键 → Miscellaneous → Data Asset → 选 `MassEntityConfig`
   - 命名为 `DA_MassEntityConfig_Zombie`
   - 在细节面板的 Traits 数组中添加：
     - **Movement Trait**：速度 450 cm/s，加速度 600 cm/s²
     - **Avoidance Trait**：半径 45 cm，邻居上限 8
     - **LOD Trait**：`LOD 0 < 1500cm`（近距离），`LOD 1 < 5000cm`（中距离）
     - **Representation Trait**：配置 ISM 可视化（StaticMesh）
     - **自定义 Tag**：添加 `Zombie` 标签

3. **创建 StateTree（追逐-攻击循环）**：
   - Content Browser 右键 → Miscellaneous → StateTree → 命名 `ST_EnemyChasePlayer`
   - 根状态：`Root` → 子级添加两个状态：
     - `Chase`：调用 MoveTo Task（目标=玩家位置）
     - `Attack`：触发攻击 → 冷却 → 判断距离
   - Transition：`Chase → Attack` 条件 `Distance < AttackRange`；`Attack → Chase` 条件 `CooldownFinished && Distance > AttackRange`

4. **创建 BP_MassTargetProvider**：
   - 简单 Actor，Tick 中每 0.05s（20Hz）读取 `UGameplayStatics::GetPlayerCharacter(GetWorld(), 0)` 位置
   - 通过 Mass Signal 或共享 Fragment 将玩家位置写入

5. **创建 BP_MassSpawner_Enemies**（继承 `AMassSpawner`）：
   - 设置 `EntityTypes` 数组：`[{Config: DA_MassEntityConfig_Zombie, Count: 500}]`
   - 设置 `SpawnRadius`：Min 500, Max 2000
   - 设置 `bAutoSpawnOnBeginPlay = true`

---

## 模式 3：自定义 Fragment + Shared Fragment

```cpp
// 共享 Fragment — 多个实体共享同一份数据（如全局目标位置）
USTRUCT()
struct FMassTargetSharedFragment : public FMassSharedFragment
{
    GENERATED_BODY()
    FVector TargetLocation = FVector::ZeroVector;
};

// 在 Processor 中订阅共享 Fragment
EntityQuery.AddConstSharedRequirement<FMassTargetSharedFragment>();

EntityQuery.ForEachEntityChunk(EntityManager, Context,
    [](FMassExecutionContext& Context)
{
    const FVector& TargetLocation = Context.GetConstSharedFragment<FMassTargetSharedFragment>().TargetLocation;
    // 所有当前 Chunk 的实体共享同一个 TargetLocation
});
```

---

## 模式 4：Mass LOD 分层

```cpp
// 在 Trait 中配置 LOD 距离
BuildContext.AddFragment<FMassEntityLODFragment>();

// LOD Collector 自动根据距离划分：
//   LOD 0 (近): 高频率 Tick，SkeletalMesh 动画 + 完整 AI
//   LOD 1 (中): 低频率 Tick (如每次 5 帧)，StaticMesh 表示 + 简化 AI
//   LOD 2 (远): 关闭 Tick，HISM 批量渲染，无 AI

// 在 Processor 中可在 Tick 时检查 LOD
if (Context.GetFragmentView<FMassEntityLODFragment>()[i].LOD <= 1)
{
    // 只对近距离实体执行高开销逻辑
}
```

---

## 模式 5：使用 Mass Spawner 生成实体

```cpp
// 获取 Mass Spawner 子系统
UMassSpawnerSubsystem* SpawnerSubsystem = GetWorld()->GetSubsystem<UMassSpawnerSubsystem>();

// 批量生成
FMassSpawnedEntities SpawnedEntities;
SpawnerSubsystem->SpawnEntities(
    MassEntityConfig->GetOrCreateEntityTemplate(*GetWorld()),
    NumEntities,
    SpawnDataGenerators,  // 可自定义生成位置/数据
    SpawnedEntities
);
```

### Spawner 蓝图配置参数

| 参数 | 推荐值 | 说明 |
|------|--------|------|
| `EntityTypes[].Config` | DA 引用 | MassEntityConfig DataAsset |
| `EntityTypes[].Count` | 100-5000 | 生成数量 |
| `SpawnRadius.Min` | 500 cm | 最小生成距离 |
| `SpawnRadius.Max` | 2000 cm | 最大生成距离 |
| `bAutoSpawnOnBeginPlay` | true | 关卡加载时自动生成 |
| `SpawningFrequency` | 1.0s | 波次间隔 |

---

## 调试与可视化

### 控制台命令

```
# 显示 Mass 实体调试信息
Mass.Debug 1
Mass.Debug.DrawEntityBBoxes 1      # 绘制实体包围盒
Mass.Debug.DrawFragments 1         # 绘制 Fragment 数据
Mass.Debug.DrawLOD 1               # LOD 可视化（红=近, 蓝=远）
Mass.Debug.DrawAvoidance 1         # 避障可视化
Mass.Debug.DrawProcessorGraph 1    # 处理器依赖图

# 性能统计
Mass.Debug.ProcessingGraph.Stat    # 各 Processor 耗时
```

### MCP 快捷调试

```json
{"method": "system.run_console_command", "params": {"command": "Mass.Debug 1"}}
{"method": "system.run_console_command", "params": {"command": "Mass.Debug.DrawLOD 1"}}
```

---

## 常见错误速查

| 错误现象 | 原因 | 解决方案 |
|----------|------|---------|
| 实体不移动 | Processor 未注册到正确的 ProcessingPhase | 检查 `bAutoRegisterWithProcessingPhases = true` |
| 实体不显示 | 缺少 `FMassRepresentationFragment` 或 Representation Processor | 添加 Representation Trait + ISM 配置 |
| Processor 查询无结果 | 实体缺少 Processor 要求的 Fragment/Tag | 在 Trait::BuildTemplate 中添加所有必要 Fragment |
| 编译: `FMassEntityQuery` 未初始化 | UE5.6+ 需要 `EntityQuery.Initialize()` 再添加需求 | 在构造函数或 Execute 开头调用 |
| 多个实体互相穿透 | 缺少 MassAvoidance / AgentRadius | 添加 `MassNavigation` 插件 + `FAgentRadiusFragment` |
| 大规模实体帧率低 | LOD 未配置 | 添加 LOD Trait，远距离实体关闭 AI |

---

## 性能预算

| 实体数量 | LOD 策略 | 预计帧开销 |
|:---:|------|:---:|
| <100 | 全 Tick，SkeletalMesh | <0.5 ms |
| 100-500 | LOD 0(30%) + LOD 1(70%) | <1 ms |
| 500-2000 | LOD 1 + LOD 2 HISM | <2 ms |
| 2000-5000 | LOD 2 为主，10Hz 更新 | <3 ms |
| 5000+ | 仅 LOD 2，关闭 AI | 视场景复杂度 |

> 关键优化：LOD Collector 自动根据距离分级；每级可配置 Tick 频率、表示方式、AI 开销。

---

## 插件依赖

| 插件 | 必需？ | 提供 |
|------|:---:|------|
| `MassEntity` | ✅ 必需 | 核心 ECS 框架 |
| `MassActors` | ✅ 必需 | Actor 桥接（Spawner 需要） |
| `MassAI` | ✅ 推荐 | 移动/导航处理器 |
| `MassCrowd` | 可选 | 人群专用避让 + 动画 |
| `MassGameplay` | 推荐 | 蓝图集成 + 信号系统 |
| `StateTree` | 推荐 | 状态机驱动 AI |
| `ZoneGraph` | 可选 | 导航通道（复杂地图） |
| `SmartObjects` | 可选 | 交互位 |

### MCP 一键启用

```json
{"method": "system.manage_plugin", "params": {"name": "MassEntity", "action": "enable"}}
{"method": "system.manage_plugin", "params": {"name": "MassActors", "action": "enable"}}
{"method": "system.manage_plugin", "params": {"name": "MassAI", "action": "enable"}}
{"method": "system.manage_plugin", "params": {"name": "MassCrowd", "action": "enable"}}
```

---

## 防幻觉规则

1. **Mass Entity 没有 UObject 每实体开销** — 禁止对单个实体调用 `->GetClass()` 或 `Cast<AMassAgent>()`。Entity 是 int32 句柄。
2. **Processor 不是 Actor** — Processor 是 `UMassProcessor` 子类，没有 `Tick()`、没有 `BeginPlay()`。
3. **Fragment 是纯结构体** — 不继承 `UObject`，不能用 `NewObject<>()` 创建，不能用 `UPROPERTY()`。
4. **Tag 是零大小结构体** — 不能存数据，不能用 `UPROPERTY()`。
5. **必须配置 ProcessingPhase** — 忘记设 `bAutoRegisterWithProcessingPhases = true` 或手动注册会导致 Processor 永远不会执行。
6. **单机项目 = 无网络** — Mass Entity 在单机项目中没有 Replication，所有逻辑本地执行。
7. **不要和 BehaviorTree 混用** — 小规模 AI 才用 BT+AIController；Mass Entity 用 StateTree 或无状态 Processor。
8. **蓝图中不能直接创建 Mass Entity** — Entity 只能通过 MassEntitySubsystem 或 Spawner 创建。蓝图可以创建 Spawner 和 Config Asset。

---

## 项目内参考

- `Source/LyraGame/Mass/` — 生产级 Mass 代码（ChasePlayer Trait + Processor）
- `Source/LyraGame/MassTest/` — 测试级 Mass 代码（自包含测试 Actor）
- `Documentation/GameDesign/Mass/MassChase_StateTree_Design.md` — 追逐系统设计文档（164 行）
- `Plugins/UnrealAgentLink/` — MCP 插件（支持 ~60 个编辑器操作，含 Blueprint 操作）

## 推荐工作流

```
MCP 启用插件 → MCP 创建 DA_MassEntityConfig → MCP 创建 BP_Spawner
→ MCP 设置 Spawner EntityTypes → MCP 创建 StateTree → MCP 编译
→ 编辑器 PIE 测试 → 控制台 Mass.Debug 1 观察
```
