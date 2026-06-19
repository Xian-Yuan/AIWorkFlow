---
name: "ue5-animation-guide"
description: 动画蓝图模式。速度采样/四向方向/CardinalAnimSet/线程安全UpdateAnimation/RootMotion/动画混合。AnimBlueprint/状态机/RootMotion时调用。
---

# UE5 动画蓝图模式指南

## 概述

本 Skill 覆盖 UE5.7 单机项目中 AnimBlueprint 的高频模式。所有模式来自 LyraStarterGame 实战验证。

## 核心模式

### 模式 1：Thread-Safe 速度采样 + 四向方向

**场景**：需要在 AnimBlueprint 的 `Blueprint Thread Safe Update Animation` 阶段采样速度并输出四向方向。

**实现**：

```cpp
// UJMAnimInstance 中
UFUNCTION(BlueprintCallable, BlueprintThreadSafe, Category="Animation|Velocity")
void UpdateVelocityData(float DeltaTime);

UFUNCTION(BlueprintPure, BlueprintThreadSafe, Category="Animation|Velocity")
EJMCardinalDirection SelectCardinalDirectionFromAngle(
    float AngleDeg,
    EJMCardinalDirection PrevDir,
    float DeadZoneDeg) const;
```

**关键点**：
- 使用 `BlueprintThreadSafe` 确保在 ThreadSafe 阶段可用
- 角度归一化到 [-180, 180]
- Dead Zone (默认 15°) 防止边界抖动
- 低速保持上一方向 (阈值默认 5 cm/s)
- 完全本地，无网络依赖

**AnimBP 调用顺序**：
```
Blueprint Thread Safe Update Animation:
  1. UpdateLocationData(DeltaTime)
  2. UpdateRotationData(DeltaTime)
  3. UpdateVelocityData(DeltaTime)  ← 最后调用
```

**调试**：在 AnimBP 中显示 `CurrentCardinalDirection` 枚举值和 `MovementAngleDeg`。

### 模式 2：CardinalAnimSet

**场景**：为四个方向（前/后/左/右）各配置一套动画序列。

**数据结构**：
```cpp
USTRUCT(BlueprintType)
struct FJMCardinalAnimSet
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    TObjectPtr<UAnimSequenceBase> ForwardAnim;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    TObjectPtr<UAnimSequenceBase> BackwardAnim;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    TObjectPtr<UAnimSequenceBase> LeftAnim;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    TObjectPtr<UAnimSequenceBase> RightAnim;

    bool HasAnyAnim() const
    {
        return ForwardAnim || BackwardAnim || LeftAnim || RightAnim;
    }
};
```

**AnimGraph 使用**：
- Switch by `CurrentCardinalDirection` → 选择对应 AnimSequence
- Fallback：缺失方向默认用 `ForwardAnim` 或 Idle
- 配合 Camera-Directed Movement 统一参考系

### 模式 3：动画混合权重与 RootYawOffset

**场景**：需要 BlendWeight 驱动 RootYawOffset 修正。

**关键变量**：
- `BlendWeight` → 驱动旋转修正量
- `RootYawOffset` → 修正角色朝向与动画方向的对齐

**实现**：在 AnimBP 的 Event Graph 中根据 BlendWeight 差值计算 RootYawOffset，每帧 Lerp。

### 模式 4：Wall Detection Heuristic（墙壁检测启发式）

**场景**：根据角色与墙壁的关系调整动画（如贴墙行走）。

**关键输入**：
- 角色速度方向
- 前方障碍物检测（Capsule Trace）
- 墙壁法线方向

**输出**：修正的移动方向和动画选择。

### 模式 5：Jump/Fall 状态控制

**场景**：AnimBP 检测 Jump/Fall 状态并切换动画。

**关键输入**：
- `CharacterMovementComponent::IsFalling()`
- `CharacterMovementComponent::Velocity.Z`
- `bPressedJump` 事件

**实现**：在 `UpdateJumpFallData` 中采样，输出 `bJumping`/`bFalling` 布尔值。

### 模式 6：加速数据更新

**场景**：AnimBP 需要加速度数据驱动起步/停止动画。

**关键函数**：
```cpp
UFUNCTION(BlueprintCallable, BlueprintThreadSafe)
void UpdateAccelerationData(float DeltaTime);
```

**输出变量**：
- `Acceleration2D` — 平面加速度
- `bAccelerating` — 是否加速中
- `bDecelerating` — 是否减速中

### 模式 7：旋转数据更新

**场景**：AnimBP 需要角色旋转数据。

**关键函数**：
```cpp
UFUNCTION(BlueprintCallable, BlueprintThreadSafe)
void UpdateRotationData(float DeltaTime);
```

**输出变量**：
- `ViewYawDeg` — 相机朝向（度）
- `ActorYawDeg` — 角色朝向（度）
- `YawDeltaDeg` — 角色与相机朝向差值

---

## 集成规则

1. **所有 BlueprintThreadSafe 函数只做只读采样和纯计算**，不修改外部对象。
2. **Update 函数顺序**：Location → Rotation → Velocity → Acceleration。
3. **角度统一归一化到 [-180, 180]**，使用 `FindDeltaAngleDegrees` 计算最小角差。
4. **KINDA_SMALL_NUMBER 保护**：DeltaTime 和阈值判断前检查。
5. **性能**：每个 Update 函数 O(1)，< 0.02ms/帧。
6. **内存**：仅少量 float 和枚举变量，极小开销。

---

## 防幻觉检查

- `UENUM` 必须在全局作用域
- `BlueprintThreadSafe` 函数中不能调用 `BlueprintPure` 的非 ThreadSafe 函数
- 动画序列必须设置 `TObjectPtr<>` 而非裸指针
- 不使用网络复制/RPC

---

## 参考文档

- `Docs/Lyra/11-AnimationSystem.md` — Lyra 动画系统概述
- `Docs/Lyra/Camera_MovementRotationMode_Guide.md` — 相机旋转模式
- `Docs/Lyra/CameraDirectedDirection_Guide.md` — 相机导向方向
