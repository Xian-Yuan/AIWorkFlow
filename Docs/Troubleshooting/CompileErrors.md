# 编译错误排查指南

## 错误 1: "Unable to find type 'XXX'"

```
error: Unable to find type 'ULyraAbilitySet' for attribute 'BLUEPRINT_TYPE'
```

**原因**: 在 GFP 的 Build.cs 中缺少 LyraGame 模块依赖。

**解决**: 在 `PublicDependencyModuleNames` 中添加 `"LyraGame"`。

## 错误 2: "Cannot open include file: 'XXX.h'"

```
fatal error C1083: Cannot open include file: 'AbilitySystem/LyraAbilitySet.h': No such file or directory
```

**原因**: include 路径错误或缺少模块依赖。

**检查**:
1. Build.cs 中是否添加了 `"LyraGame"`
2. Include 路径是否正确。在 GFP 中，include 路径相对于 `Public/Private` 目录：
```cpp
// 正确 (在 Source/MyGame/Public/ 中):
#include "AbilitySystem/LyraAbilitySet.h"
// 实际文件在: LyraGame/Source/LyraGame/Public/AbilitySystem/LyraAbilitySet.h
```

## 错误 3: "UClass has no member 'XXX'"

```
error C2039: 'SetActiveSlotIndex': is not a member of 'ULyraQuickBarComponent'
```

**原因**: 调用了不存在的函数。检查：
1. 函数名拼写是否正确
2. 函数是否在正确的 UE 版本中存在
3. 是否使用了 `_Implementation` 后缀

**注意**: 带 `BlueprintCallable` 和 `BlueprintImplementableEvent` 的函数不需要 `_Implementation`，但带 `Native` 的有时需要。

## 错误 4: "Cannot derive from 'XXX' — it is not marked with UCLASS()"

```
error: Cannot derive from 'ULyraEquipmentInstance' as it is not marked with UCLASS(), or仅有 forward declaration
```

**解决**: 确保 include 了正确的头文件，并且类声明上有 `GENERATED_BODY()`。

## 错误 5: "ModuleManager: Unable to load module 'XXX'"

```
LogModuleManager: Warning: Unable to load module 'MyGame'
```

**原因**: GFP 模块无法加载。检查：
1. `.uplugin` 中的模块名与 `Build.cs` 和 `.h/.cpp` 中的 `IMPLEMENT_MODULE` 一致
2. Build.cs 的 `PublicDependencyModuleNames` 包含所有必要模块
3. 项目已重新生成解决方案

## 错误 6: "LNK2019: unresolved external symbol"

```
LNK2019: unresolved external symbol "public: void __cdecl UMyClass::MyFunction()"
```

**原因**: 函数声明了但没有实现，或实现不在编译中包含的文件中。

**检查**:
1. 函数的 `.cpp` 文件是否在 `Source/ModuleName/Private/` 中
2. `Build.cs` 的 `PrivateDefinitions` 是否拼写正确
3. 如果是 UHT 生成的函数，检查是否有 `GENERATED_BODY()` 在类中

## 错误 7: "Missing 'XXX' macro"

```
error: Missing 'GENERATED_BODY()' at end of 'UMyAttributeSet'
```

**解决**: 在每个 UClass 声明的末尾添加 `GENERATED_BODY()`。

```cpp
UCLASS()
class UMyAttributeSet : public UAttributeSet
{
    GENERATED_BODY()  // ← 必须
    // ...
};
```

## 错误 8: Lyra 特有 — "Unable to find experience"

```
LogLyraExperience: Warning: OnExperienceLoadComplete failed to find plugin URL for PluginName MyGame
```

**原因**: 
1. GFP 的 `.uplugin` 文件位置不正确 (必须在 `Plugins/GameFeatures/` 下)
2. GFP 名称在 Experience 的 `GameFeaturesToEnable` 中拼写错误
3. `.uplugin` 文件中 `Category` 不是 `"Game Features"`

**解决**:
1. 确认 GFP 在 `Plugins/GameFeatures/` 下
2. 确认 `Category: "Game Features"`
3. 检查 `GameFeaturesToEnable` 中的名字是否与文件夹名一致

## 错误 9: "Only classes with UStruct can be struct"

```
error: Only classes with UStruct can be struct in 'ATTRIBUTE_ACCESSORS'
```

**原因**: `ATTRIBUTE_ACCESSORS` 宏定义在类外或其他不正确的上下文中。

**解决**: 确保宏在 `UCLASS()` 声明内部的 `public:` 段中。

## 错误 10: "Unable to load package"

```
LogLinker: Warning: Unable to load package /Game/MyGame/Experiences/B_MyExperience
```

**原因**: AssetManager 未配置扫描该目录。

**解决**: 在 GameFeatureData 的 `PrimaryAssetTypesToScan` 中添加正确的目录。
