# Lyra 项目配置文件参考

## DefaultGame.ini — AssetManager 配置

```ini
[/Script/Engine.AssetManagerSettings]
bShouldManagerDetermineTypeAndName=true
bUseAssetManager=true

+PrimaryAssetTypesToScan=(PrimaryAssetType="LyraExperienceDefinition", AssetBaseClass="/Script/LyraGame.LyraExperienceDefinition", HasBlueprintClasses=true, bHasBlueprintClasses=true, Directories=(/Game/Experiences/))
+PrimaryAssetTypesToScan=(PrimaryAssetType="LyraExperienceDefinition", AssetBaseClass="/Script/LyraGame.LyraExperienceDefinition", HasBlueprintClasses=true, bHasBlueprintClasses=true, Directories=(/Plugins/GameFeatures/))
+PrimaryAssetTypesToScan=(PrimaryAssetType="LyraUserFacingExperienceDefinition", AssetBaseClass="/Script/LyraGame.LyraUserFacingExperienceDefinition", HasBlueprintClasses=true, bHasBlueprintClasses=true, Directories=(/Game/Experiences/))
+PrimaryAssetTypesToScan=(PrimaryAssetType="LyraUserFacingExperienceDefinition", AssetBaseClass="/Script/LyraGame.LyraUserFacingExperienceDefinition", HasBlueprintClasses=true, bHasBlueprintClasses=true, Directories=(/Plugins/GameFeatures/))
+PrimaryAssetTypesToScan=(PrimaryAssetType="LyraPawnData", AssetBaseClass="/Script/LyraGame.LyraPawnData", HasBlueprintClasses=true, bHasBlueprintClasses=true, Directories=(/Game/PawnData/))
+PrimaryAssetTypesToScan=(PrimaryAssetType="LyraPawnData", AssetBaseClass="/Script/LyraGame.LyraPawnData", HasBlueprintClasses=true, bHasBlueprintClasses=true, Directories=(/Plugins/GameFeatures/))
+PrimaryAssetTypesToScan=(PrimaryAssetType="LyraInputConfig", AssetBaseClass="/Script/LyraGame.LyraInputConfig", HasBlueprintClasses=true, bHasBlueprintClasses=true, Directories=(/Game/Input/))
+PrimaryAssetTypesToScan=(PrimaryAssetType="LyraInputConfig", AssetBaseClass="/Script/LyraGame.LyraInputConfig", HasBlueprintClasses=true, bHasBlueprintClasses=true, Directories=(/Plugins/GameFeatures/))
+PrimaryAssetTypesToScan=(PrimaryAssetType="LyraAbilitySet", AssetBaseClass="/Script/LyraGame.LyraAbilitySet", HasBlueprintClasses=true, bHasBlueprintClasses=true, Directories=(/Game/Abilities/))
+PrimaryAssetTypesToScan=(PrimaryAssetType="LyraAbilitySet", AssetBaseClass="/Script/LyraGame.LyraAbilitySet", HasBlueprintClasses=true, bHasBlueprintClasses=true, Directories=(/Plugins/GameFeatures/))
```

## DefaultGame.ini — GameplayCue 路径

```ini
[/Script/GameplayAbilities.AbilitySystemGlobals]
+GameplayCueNotifyPaths=/Game/Lyra/GameplayCues/
+GameplayCueNotifyPaths=/Game/MyGame/GameplayCues/
```

## DefaultGame.ini — 游戏标签 (可选)

```ini
[/Script/GameplayTags.GameplayTagsSettings]
+GameplayTagTableList=/Game/MyGame/Tags/MyGameTags
```

## DefaultEngine.ini — 网络

```ini
[/Script/OnlineSubsystemUtils.OnlineEngineInterfaceImpl]
+NativePlatformOSS=

[/Script/Engine.GameEngine]
!NetDriverDefinitions=ClearArray
+NetDriverDefinitions=(DefName=GameNetDriver,DriverClassName=/Script/OnlineSubsystemUtils.IpNetDriver,DriverClassNameFallback=/Script/OnlineSubsystemUtils.IpNetDriver)

[/Script/OnlineSubsystem.IpNetDriver]
MaxInternetClientRate=100000
MaxClientRate=100000
ServerTravelPause=0.0
```

## DefaultEngine.ini — 输入

```ini
[/Script/Engine.InputSettings]
bEnableDynamicMusic=false
bEnableMouseSmoothing=true
bShowMouseCursor=true
DefaultViewportMouseCaptureMode=CapturePermanently_IncludingInitialMouseDown
DefaultViewportMouseLockMode=LockOnCapture
```

## Build.cs — 标准配置

```csharp
// 项目根模块
PublicDependencyModuleNames.AddRange(new string[] {
    "Core",
    "CoreUObject",
    "Engine",
    "InputCore",
    "EnhancedInput",
    "GameplayAbilities",
    "GameplayTags",
    "GameplayTasks",
    "Slate",
    "SlateCore",
    "UMG",
});

// Lyra 模块
PublicDependencyModuleNames.AddRange(new string[] {
    "LyraGame",
    "CommonGame",
    "CommonLoadingScreen",
    "ModularGameplay",
    "UIExtension",
});

// 私有模块 (如果不需要导出的 API)
PrivateDependencyModuleNames.AddRange(new string[] {
    "DeveloperSettings",
    "GameFeatures",
    "NetCore",
});
```

## .uplugin — 标准 GameFeature Plugin 配置

```json
{
  "FileVersion": 3,
  "Version": 1,
  "VersionName": "1.0.0",
  "FriendlyName": "MyGame",
  "Description": "My game features and content",
  "Category": "Game Features",
  "CanContainContent": true,
  "Modules": [
    {
      "Name": "MyGame",
      "Type": "Runtime",
      "LoadingPhase": "Default",
      "AdditionalDependencies": [ "Engine" ]
    }
  ],
  "Plugins": [
    { "Name": "CommonGame", "Enabled": true },
    { "Name": "GameFeatures", "Enabled": true },
    { "Name": "ModularGameplay", "Enabled": true }
  ]
}
```
