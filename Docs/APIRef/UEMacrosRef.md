# UE 宏与核心 API 参考

## 概述

本文档覆盖 UE5 中最常用的宏以及核心 UHT 规则。AI 在生成代码时遇到宏相关编译错误，应优先参考本文档和 `Docs/Troubleshooting/ErrorKnowledgeBase/`。

---

## 1. UCLASS 宏

### 基本语法

```cpp
UCLASS([Specifier1=Value1, Specifier2, ...])
class UMyClass : public UObject
{
    GENERATED_BODY()
};
```

### 常用 Specifier

| Specifier | 说明 | 示例 |
|-----------|------|------|
| `Blueprintable` | 允许在蓝图中继承此类 | `UCLASS(Blueprintable)` |
| `BlueprintType` | 允许在蓝图作为变量类型 | `UCLASS(BlueprintType)` |
| `NotBlueprintable` | 禁止蓝图继承（默认） | `UCLASS(NotBlueprintable)` |
| `Abstract` | 不能实例化，只能继承 | `UCLASS(Abstract)` |
| `Within=ClassName` | 只能作为 ClassName 的子对象 | `UCLASS(Within=APlayerState)` |
| `config=ConfigFile` | 从配置文件中读取/写入 | `UCLASS(config=Game)` |
| `HideCategories=(Category1, Category2)` | 在细节面板隐藏分类 | `UCLASS(HideCategories=(Transform))` |
| `ShowCategories=(Category)` | 显示隐藏的分类 | |
| `ClassGroup=(GroupName)` | 编辑器中的分组 | `UCLASS(ClassGroup=(Custom))` |
| `Meta=(...)` | 元数据 | `UCLASS(Meta=(ShortTooltip="My tooltip"))` |
| `EditInlineNew` | 允许在细节面板内联创建 | `UCLASS(EditInlineNew)` |
| `DefaultToInstanced` | 属性的默认实例化方式 | `UCLASS(DefaultToInstanced)` |

### 典型组合

```cpp
// Lyra 风格：可蓝图继承，但不能实例化
UCLASS(Abstract, Blueprintable, Within=APlayerState)

// GameFeature Action
UCLASS(Abstract, Within=ULyraExperienceDefinition)
```

---

## 2. UPROPERTY 宏

### 基本语法

```cpp
UPROPERTY([Specifier1, Specifier2, ...], Meta=(Key1=Value1, ...))
TArray<AActor*> MyArray;
```

### 分类

**可见性 & 蓝图访问：**

| Specifier | 说明 |
|-----------|------|
| `BlueprintReadWrite` | 蓝图中可读可写 |
| `BlueprintReadOnly` | 蓝图中只读 |
| `VisibleAnywhere` | 编辑器可见（不可编辑） |
| `VisibleInstanceOnly` | 仅实例可见，原型不可见 |
| `VisibleDefaultsOnly` | 仅原型可见 |
| `EditAnywhere` | 编辑器可见可编辑（原型+实例） |
| `EditInstanceOnly` | 仅实例可编辑 |
| `EditDefaultsOnly` | 仅原型可编辑 |
| `EditFixedSize` | 固定数组大小（不可增删） |

**复制：**

| Specifier | 说明 |
|-----------|------|
| `Replicated` | 网络复制 |
| `ReplicatedUsing=FunctionName` | 复制后调用函数 |
| `NotReplicated` | 显式不复制 |
| `ReplicatedUsing=OnRep_Func` | 最常见模式 |

**序列化：**

| Specifier | 说明 |
|-----------|------|
| `SaveGame` | 参与存档序列化 |
| `Transient` | 不序列化 |
| `SkipSerialization` | 跳过序列化 |
| `NonTransactional` | 不参与撤销/重做 |

**其他常用：**

| Specifier | 说明 |
|-----------|------|
| `Category="CategoryName"` | 细节面板分类 |
| `AdvancedDisplay` | 折叠到高级显示 |
| `AssetRegistrySearchable` | 可在资产注册表中搜索 |
| `Interp` | 可在 Matinee/Sequencer 中关键帧控制 |
| `Config` | 从 ini 文件读写 |
| `GlobalConfig` | 从全局 ini 读写 |
| `Instanced` | 创建 UObject 属性的自动实例化 |

### Meta 修饰

| Meta Key | 说明 | 示例 |
|----------|------|------|
| `AllowPrivateAccess` | 允许蓝图访问私有属性 | `Meta=(AllowPrivateAccess=true)` |
| `ExposeOnSpawn` | 在 SpawnActor 节点显示 | `Meta=(ExposeOnSpawn=true)` |
| `MakeEditWidget` | 显示位置/旋转编辑控件 | `Meta=(MakeEditWidget)` |
| `ClampMin / ClampMax` | 数值范围限制 | `Meta=(ClampMin=0.0, ClampMax=100.0)` |
| `DisplayName` | 蓝图中显示的名称 | `Meta=(DisplayName="My Variable")` |
| `ToolTip` | 悬浮提示 | `Meta=(ToolTip="This is health")` |

### 完整示例

```cpp
UPROPERTY(BlueprintReadWrite, EditAnywhere, ReplicatedUsing=OnRep_Health,
    Category="Attributes", Meta=(ClampMin=0.0, AllowPrivateAccess=true))
float Health;
```

---

## 3. UFUNCTION 宏

### 基本语法

```cpp
UFUNCTION([Specifier1, Specifier2, ...], Meta=(...))
ReturnType FunctionName(Parameters);
```

### 分类

**蓝图交互：**

| Specifier | 说明 |
|-----------|------|
| `BlueprintCallable` | 蓝图可调用 |
| `BlueprintPure` | 蓝图纯函数（无执行引脚） |
| `BlueprintImplementableEvent` | 蓝图实现，C++ 不提供默认实现 |
| `BlueprintNativeEvent` | C++ 提供默认实现 (`_Implementation`) ，蓝图可覆盖 |

**网络：**

| Specifier | 说明 |
|-----------|------|
| `Server` | 在服务器执行（客户端调用） |
| `Client` | 在拥有者客户端执行（服务器调用） |
| `NetMulticast` | 在所有客户端和服务器执行 |
| `Reliable` | 可靠（保证到达） |
| `Unreliable` | 不可靠（可能丢失） |
| `WithValidation` | RPC 验证函数 `_Validate` |
| `BlueprintAuthorityOnly` | 仅在服务器执行的蓝图函数 |

**其他：**

| Specifier | 说明 |
|-----------|------|
| `Const` | 不修改对象状态 |
| `Static` | 静态函数 |
| `Exec` | 可作为控制台命令 |
| `CallInEditor` | 编辑器按钮 |
| `Category="..."` | 蓝图面板分类 |
| `SealedEvent` | 禁止子类覆盖 Event |
| `NetValidate` | 网络验证 |

### 常见模式

```cpp
// 纯虚（蓝图实现）
UFUNCTION(BlueprintImplementableEvent)
void OnDeath(AActor* Killer);

// C++ 默认 + 蓝图可覆盖
UFUNCTION(BlueprintNativeEvent)
void OnDamageReceived(float Damage);
virtual void OnDamageReceived_Implementation(float Damage);

// 蓝图可调用 + C++ 实现
UFUNCTION(BlueprintCallable, Category="Gameplay")
void PerformAction();

// 控制台命令
UFUNCTION(Exec)
void MyCommand(const FString& Args);

// Server RPC
UFUNCTION(Server, Reliable, WithValidation)
void Server_RequestAction();
bool Server_RequestAction_Validate();  // 验证函数
void Server_RequestAction_Implementation();  // 实现函数
```

---

## 4. USTRUCT 宏

```cpp
USTRUCT([Specifier1, ...])
struct FMyStruct
{
    GENERATED_BODY()

    UPROPERTY(...)
    float Value;
};
```

### 常用 Specifier

| Specifier | 说明 |
|-----------|------|
| `BlueprintType` | 可作为蓝图变量类型 |
| `NoExport` | 只生成声明，不生成导出代码 |
| `Atomic` | 原子结构体（单线程场景） |

### 结构体 vs 类

| 方面 | USTRUCT | UCLASS |
|------|---------|--------|
| 继承 | 不支持 | 支持 |
| GAS 属性 | 不支持 `FGameplayAttributeData` | 支持 |
| 网络复制 | 手动 | 自动 + DOREPLIFETIME |
| 性能 | 栈分配，快 | 堆分配，慢 |
| 用途 | 数据传输/配置 | 完整游戏逻辑 |

---

## 5. UENUM 宏

```cpp
UENUM([Specifier, ...])
enum class EMyEnum : uint8
{
    Value1,
    Value2 UMETA(DisplayName="Value 2"),
    Value3
};
```

### 常用 Specifier

| Specifier | 说明 |
|-----------|------|
| `BlueprintType` | 可在蓝图作为变量类型 |
| `Meta=(Bitflags)` | 位掩码枚举 |

```cpp
// 位掩码枚举
UENUM(Meta=(Bitflags))
enum class EAbilityFlags : uint8
{
    None = 0,
    CanCancel = 1 << 0,
    CanInterrupt = 1 << 1,
    IsPassive = 1 << 2
};
ENUM_CLASS_FLAGS(EAbilityFlags)  // 启用运算符重载
```

---

## 6. GENERATED_BODY 宏

### 不同位置的变体

```cpp
// UObject 派生
UCLASS()
class UMyClass : public UObject
{
    GENERATED_BODY()
};

// AActor 派生（有构造函数重载）
UCLASS()
class AMyActor : public AActor
{
    // 启用默认构造函数，不是 GENERATED_BODY 也生效
    GENERATED_BODY()
    // 或:
    // GENERATED_UCLASS_BODY()  // 不推荐，UE5 中 deprecated
};

// 使用 GENERATED_BODY() 的构造函数
AMyActor::AMyActor(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
{
}
```

### 常见编译错误

```
Missing 'GENERATED_BODY()' at end of 'UMyClass'
```
→ 见 ErrorKnowledgeBase E001

---

## 7. 模块宏

```cpp
// 标准模块实现
IMPLEMENT_MODULE(FDefaultGameModuleImpl, MyModule)

// 游戏模块
IMPLEMENT_GAME_MODULE(FDefaultGameModuleImpl, MyGame)

// 主模块
IMPLEMENT_PRIMARY_GAME_MODULE(FDefaultGameModuleImpl, MyGame, "MyGame")

// 日志类别声明（在 .h 中）
DECLARE_LOG_CATEGORY_EXTERN(LogMyGame, Log, All);

// 日志类别定义（在 .cpp 中）
DEFINE_LOG_CATEGORY(LogMyGame);
```

### 日志级别

| 宏 | 使用场景 |
|----|---------|
| `UE_LOG(LogMyGame, Log, TEXT("..."))` | 常规信息 |
| `UE_LOG(LogMyGame, Warning, TEXT("..."))` | 警告 |
| `UE_LOG(LogMyGame, Error, TEXT("..."))` | 错误 |
| `UE_LOG(LogMyGame, Fatal, TEXT("..."))` | 致命（崩溃） |
| `UE_LOG(LogMyGame, Display, TEXT("..."))` | 始终显示 |

### 格式化

```cpp
UE_LOG(LogTemp, Warning, TEXT("Health: %f, Name: %s"), Health, *CharacterName);
// %s 必须用 *TEXT 解开
```

---

## 8. 条件编译宏

```cpp
// 编辑器特有代码
#if WITH_EDITOR
    // 只在编辑器编译
#endif

// 编辑器数据（仍存在于包中）
#if WITH_EDITORONLY_DATA
    UPROPERTY()
    FString EditorComment;
#endif

// 构建配置
#if UE_BUILD_SHIPPING
    // 不包含调试代码
#elif UE_BUILD_DEBUG
    // 调试代码
#elif UE_BUILD_DEVELOPMENT
    // 开发代码
#endif

// 在 Shipping 中移除日志
#define MY_LOG(Format, ...) UE_LOG(LogMyGame, Log, TEXT(Format), ##__VA_ARGS__)
#if UE_BUILD_SHIPPING
#undef MY_LOG
#define MY_LOG(...)
#endif
```

---

## 9. GAS 专用宏

```cpp
// 在 AttributeSet 中 - 生成 GetXxx() / SetXxx() / InitXxx() 函数
ATTRIBUTE_ACCESSORS(UMyAttributeSet, Health);

// 属性复制通知宏 - 在 OnRep 函数中
GAMEPLAYATTRIBUTE_REPNOTIFY(UMyAttributeSet, Health, OldValue);

// 属性数据声明
UPROPERTY(ReplicatedUsing = OnRep_Health, Category = "Attributes")
FGameplayAttributeData Health;

// 属性修改回调
virtual void PostGameplayEffectExecute(const FGameplayEffectModCallbackData& Data) override;
```

---

## 10. 委托宏

```cpp
// 声明
DECLARE_DELEGATE(FMyDelegate)                              // 无参数
DECLARE_DELEGATE_OneParam(FMyDelegateParam, float)         // 1个参数
DECLARE_DELEGATE_TwoParams(FMyDelegateParams, float, int)  // 2个参数
DECLARE_MULTICAST_DELEGATE(FMyMulticastDelegate)           // 多播
DECLARE_DYNAMIC_MULTICAST_DELEGATE(FMyDynamicDelegate)     // 动态多播（蓝图可见）

// 事件（Actor 间解耦）
DECLARE_EVENT(AMyActor, FMyEvent)
DECLARE_EVENT_OneParam(AMyActor, FMyEventParam, float)
```

---

## 11. GAMEPLAY_ABILITIES 宏

```cpp
// 创建 GameplayEffectSpec
FGameplayEffectSpecHandle MakeOutgoingSpec(TSubclassOf<UGameplayEffect> EffectClass,
    float Level, FGameplayEffectContextHandle Context);

// 应用 GE 到目标
FActiveGameplayEffectHandle ApplyGameplayEffectToTarget(
    TSubclassOf<UGameplayEffect> EffectClass,
    const FGameplayAbilityTargetDataHandle& TargetData,
    int32 TargetIndex, int32 PredictionKey);

// 属性变化绑定
ASC->GetGameplayAttributeValueChangeDelegate(Attribute)
    .AddUObject(this, &UMyClass::OnAttributeChanged);
```

---

## 12. 容器高频模式

```cpp
// TArray — 倒序删除（见 E021）
for (int32 i = Array.Num() - 1; i >= 0; --i)
    if (Condition) Array.RemoveAt(i);

// TArray — 安全移除所有
Array.RemoveAll([](const FType& Item) { return Condition; });

// TMap — 查找
if (FType* Found = MyMap.Find(Key)) { /* 使用 *Found */ }

// TMap — 遍历
for (const TPair<FKey, FValue>& Pair : MyMap) { Pair.Key; Pair.Value; }

// TSet — 快速包含检查
if (MySet.Contains(Value)) { /* O(1) */ }

// TSubclassOf — 约束类型
UPROPERTY(EditAnywhere)
TSubclassOf<AActor> ActorClass;  // 只接受 AActor 派生类

// TWeakObjectPtr — 弱引用（防止 GC 阻止销毁）
TWeakObjectPtr<AActor> WeakActor;

// TSoftObjectPtr — 软引用（不加载资产）
UPROPERTY(EditAnywhere)
TSoftObjectPtr<UStaticMesh> SoftMesh;

// CastChecked — 断言转换（失败即崩溃，用于确定不会错）
CastChecked<UMyClass>(Object);

// Cast — 安全转换
if (UMyClass* MyObj = Cast<UMyClass>(Object)) { /* 安全使用 */ }
```

---

## 13. 前向声明最佳实践

```cpp
// ❌ 头文件中大量 #include（传播依赖）
#include "GameplayAbilitySystem.h"
#include "LyraGameplayAbility.h"

// ✅ 前向声明 + .cpp 中 #include
class ULyraGameplayAbility;
class UAbilitySystemComponent;

// 只在 .cpp 中 include
```

**规则：**
- .h 中能用前向声明就不用 `#include`
- 仅 `UCLASS()` / `USTRUCT()` 声明、参数类型、返回值类型用前向声明
- 调用函数或访问成员时必须在 .cpp 中 `#include`

---

## 14. 常见编译错误速查

| 错误现象 | 原因 | 参考 |
|----------|------|------|
| Missing GENERATED_BODY | UHT 缺少反射生成 | E001 |
| Unable to find type | Build.cs 缺少模块依赖 | E002 |
| C1083: Cannot open include | 头文件路径错误 | E003 |
| C2039: has no member | 函数不存在或拼写错误 | E004 |
| LNK2019 | 声明未实现 / 缺少模块 | E007 |
| Only classes with UStruct | ATTRIBUTE_ACCESSORS 在类外 | E008 |

---

## 15. Blueprint 互操作速查（场景 → 必须的宏组合）

> **核心原则：不同场景需要不同的 SPECIFIER 组合。少一个，蓝图里就不可用。**
> **所有 specifier 必须来自此表——禁止凭记忆组合。**

### 15.1 UFUNCTION Blueprint 互操作

| 场景 | 必须的 specifier 组合 | 缺失时的症状 |
|------|----------------------|-------------|
| **静态 BlueprintCallable 函数** | `UFUNCTION(BlueprintCallable, meta=(WorldContext="WorldContextObject"))`<br>第一个参数: `const UObject* WorldContextObject` | 蓝图中**找不到**函数节点 |
| **成员 BlueprintCallable 函数** | `UFUNCTION(BlueprintCallable)` | 无 |
| **BlueprintPure（无执行引脚）** | `UFUNCTION(BlueprintPure)` = `BlueprintCallable` + `const` | 显示为有执行引脚的节点 |
| **Latent 异步节点（Delay 类）** | `UFUNCTION(BlueprintCallable, meta=(Latent, LatentInfo="LatentInfo"))`<br>参数: `FLatentActionInfo LatentInfo` | 蓝图中显示为**普通函数**而非 latent 节点（没有时钟图标） |
| **输出类型由输入决定** | `UFUNCTION(BlueprintCallable, meta=(DeterminesOutputType="InputClass"))` | 输出引脚类型错误，或强制手动转换 |
| **动态多输出引脚** | `UFUNCTION(BlueprintCallable, meta=(ExpandEnumAsExecs="Outcome"))` | 只有一个执行引脚 |
| **编辑器内调用按钮** | `UFUNCTION(CallInEditor)` | 细节面板中无按钮 |
| **BlueprintImplementableEvent** | `UFUNCTION(BlueprintImplementableEvent)`<br>**不要**写实现 | 编译错误或 C++ 实现被忽略 |
| **BlueprintNativeEvent** | `UFUNCTION(BlueprintNativeEvent)`<br>必须写 `_Implementation` 函数 | C++ 实现不被调用 |
| **控制台命令** | `UFUNCTION(Exec)` | 控制台无此命令 |
| **Server RPC** | `UFUNCTION(Server, Reliable, WithValidation)`<br>必须写 `_Validate` + `_Implementation` | 调用无效或编译错误 |
| **Client RPC** | `UFUNCTION(Client, Reliable)` | 同上 |
| **NetMulticast RPC** | `UFUNCTION(NetMulticast, Reliable)` | 同上 |
| **BlueprintAuthorityOnly** | `UFUNCTION(BlueprintCallable, BlueprintAuthorityOnly)` | 客户端也能调用（安全风险） |
| **BlueprintCosmetic** | `UFUNCTION(BlueprintCallable, BlueprintCosmetic)` | Dedicated Server 上也会执行（浪费） |
| **隐藏特定参数引脚** | `UFUNCTION(BlueprintCallable, meta=(HidePin="ParamName"))` | 蓝图节点有多余引脚 |
| **参数折叠到 Advanced** | `UFUNCTION(BlueprintCallable, meta=(AdvancedDisplay="Param1,Param2"))` | 所有参数平铺显示 |

### 15.2 UPROPERTY Blueprint 互操作

| 场景 | 必须的 specifier 组合 | 缺失时的症状 |
|------|----------------------|-------------|
| **多播委托绑定蓝图事件** | `UPROPERTY(BlueprintAssignable)` | 蓝图中**无法绑定**事件，编译通过但逻辑不触发 |
| **属性在蓝图读写** | `UPROPERTY(BlueprintReadWrite)` | 蓝图中不可访问 |
| **属性在蓝图只读** | `UPROPERTY(BlueprintReadOnly)` | 蓝图中不可写 |
| **条件编辑** | `UPROPERTY(EditAnywhere, meta=(EditCondition="bEnableX"))` | 条件未满足时仍可编辑，导致无效配置 |
| **条件编辑+隐藏** | `UPROPERTY(EditAnywhere, meta=(EditCondition="bEnableX", EditConditionHides))` | 条件未满足时灰色显示（而非隐藏） |
| **下拉选项由函数提供** | `UPROPERTY(EditAnywhere, meta=(GetOptions="GetMyOptions"))` | 没有下拉，只能手动输入字符串 |
| **Bitmask 枚举显示** | `UPROPERTY(EditAnywhere, meta=(Bitmask, BitmaskEnum="EMyFlags"))` | 显示为普通 int，不能勾选标志位 |
| **内联显示结构体内部属性** | `UPROPERTY(EditAnywhere, meta=(ShowOnlyInnerProperties))` | 显示为折叠的结构体而不是展开的属性 |
| **数组元素标题** | `UPROPERTY(EditAnywhere, meta=(TitleProperty="Name"))` | 数组元素显示索引号而非名称 |
| **强制内联行** | `UPROPERTY(EditAnywhere, meta=(ForceInlineRow))` | DataTable 行显示为下拉框 |
| **隐藏 Reset to Default** | `UPROPERTY(EditAnywhere, meta=(NoResetToDefault))` | 属性右侧有多余的重置箭头 |
| **隐藏详情面板属性** | `UPROPERTY(EditAnywhere, meta=(HideInDetailPanel))` | 属性仍显示在面板中 |
| **简单内联显示** | `UPROPERTY(VisibleAnywhere, meta=(SimpleDisplay))` | 显示为复杂控件而非简单文本 |
| **ExposeOnSpawn（Spawn 节点显示）** | `UPROPERTY(EditAnywhere, meta=(ExposeOnSpawn=true))` | SpawnActor 节点上无此输入引脚 |
| **MakeEditWidget（3D 位置编辑控件）** | `UPROPERTY(EditAnywhere, meta=(MakeEditWidget))` | 视口中无位置编辑控件 |
| **Clamp 范围** | `UPROPERTY(EditAnywhere, meta=(ClampMin=0.0, ClampMax=100.0))` | 可以输入任意值 |

### 15.3 UCLASS Blueprint 互操作

| 场景 | 必须的 specifier 组合 | 缺失时的症状 |
|------|----------------------|-------------|
| **蓝图可继承** | `UCLASS(Blueprintable)` | 无法创建蓝图子类 |
| **蓝图可用作变量类型** | `UCLASS(BlueprintType)` | 无法在蓝图中声明该类型的变量 |
| **类选择器约束子类** | 在 `TSubclassOf<T>` 的 T 上使用 `UCLASS(BlueprintType)` | 类选择器不约束类型 |
| **显式编辑内联** | `UCLASS(EditInlineNew)` | 细节面板中 Add 按钮不显示 |
| **默认配置持久化** | `UCLASS(DefaultConfig, config=Game)` | 对象值不保存在 ini 中 |
| **独立对象配置** | `UCLASS(PerObjectConfig)` | 所有实例共享同一配置 |
| **类标记弃用** | `UCLASS(meta=(DeprecatedClass))` | 无 |
| **所有子对象实例化** | `UCLASS(DefaultToInstanced)` | 子对象属性为 nullptr |
| **最小 API 导出** | `UCLASS(MinimalAPI)` | 其他模块链接失败 |
| **隐藏功能** | `UCLASS(HideFunctions=(...))` | 蓝图右键菜单中出现不需要的函数 |
| **显示功能** | `UCLASS(ShowFunctions=(...))` | 需要的函数被隐藏 |

### 15.4 USTRUCT Blueprint 互操作

| 场景 | 必须的 specifier 组合 | 缺失时的症状 |
|------|----------------------|-------------|
| **结构体在蓝图可用** | `USTRUCT(BlueprintType)` | 无法在蓝图中声明该类型变量 |
| **结构体支持 Make/Break** | `USTRUCT(BlueprintType, meta=(HasNativeMake="...", HasNativeBreak="..."))` | 蓝图中无 Make/Break 节点 |
| **结构体禁用蓝图** | `USTRUCT()` (默认) 或 `USTRUCT(NotBlueprintType)` | 无 |

### 15.5 完整 BlueprintCallable 函数模板

```cpp
// ✅ 静态 BlueprintCallable（蓝图节点可被全局搜索到）
UFUNCTION(BlueprintCallable, Category="MyGame|Utilities",
    meta=(WorldContext="WorldContextObject"))
static void MyGlobalFunction(const UObject* WorldContextObject, float Param);

// ✅ 成员 BlueprintCallable
UFUNCTION(BlueprintCallable, Category="MyGame|Combat")
void PerformAttack(AActor* Target);

// ✅ BlueprintNativeEvent（C++ 默认实现 + 蓝图可覆盖）
UFUNCTION(BlueprintNativeEvent, Category="MyGame|Events")
void OnDamageReceived(float Damage, AActor* Instigator);
virtual void OnDamageReceived_Implementation(float Damage, AActor* Instigator);

// ✅ Latent 异步节点
UFUNCTION(BlueprintCallable, Category="MyGame|Async",
    meta=(Latent, LatentInfo="LatentInfo", WorldContext="WorldContextObject"))
static void WaitForCondition(const UObject* WorldContextObject, FLatentActionInfo LatentInfo, bool& bResult);

// ✅ Server RPC
UFUNCTION(Server, Reliable, WithValidation)
void Server_RequestAction(int32 ActionID);
bool Server_RequestAction_Validate(int32 ActionID);
void Server_RequestAction_Implementation(int32 ActionID);

// ✅ 动态输出引脚（枚举展开）
UENUM(BlueprintType)
enum class EActionOutcome : uint8 { Success, Failed, Blocked };

UFUNCTION(BlueprintCallable, Category="MyGame|Action",
    meta=(ExpandEnumAsExecs="Outcome"))
void TryAction(EActionOutcome& Outcome);
```

### 15.6 完整 Blueprint 属性模板

```cpp
// ✅ 可绑定蓝图事件的多播委托
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnHealthChanged, float, NewHealth);

UPROPERTY(BlueprintAssignable, Category="Events")
FOnHealthChanged OnHealthChanged;

// ✅ 条件编辑 + 隐藏
UPROPERTY(EditAnywhere, Category="Config",
    meta=(EditCondition="bUseCustomDamage", EditConditionHides))
float CustomDamageValue;

// ✅ Bitmask 枚举
UENUM(BlueprintType, Meta=(Bitflags))
enum class EAttackFlags : uint8
{
    None       = 0,
    Piercing   = 1 << 0,
    Splash     = 1 << 1,
    Critical   = 1 << 2
};

UPROPERTY(EditAnywhere, Category="Config",
    meta=(Bitmask, BitmaskEnum="EAttackFlags"))
int32 AttackFlags;
```

---

## 参考文档

- `Docs/APIRef/LyraCoreClasses.md` — Lyra 核心类 public 函数签名
- `Docs/APIRef/GASCoreClasses.md` — GAS 核心类 public 函数签名
- `Docs/APIRef/CommonPatterns.md` — 10 种常用代码模式
- `Docs/Troubleshooting/ErrorKnowledgeBase/` — 错误知识库
