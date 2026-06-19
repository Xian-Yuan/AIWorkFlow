// Copyright Epic Games, Inc. All Rights Reserved.

using UnrealBuildTool;

public class MyGame : ModuleRules
{
    public MyGame(ReadOnlyTargetRules Target) : base(Target)
    {
        PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;

        PublicDependencyModuleNames.AddRange(new string[] {
            "Core",
            "CoreUObject",
            "Engine",
            "GameplayAbilities",
            "GameplayTags",
            "GameplayTasks",
            "LyraGame",              // Lyra 核心模块
            "ModularGameplay",       // Modular 支持
            "CommonGame",            // CommonUI
            "CommonLoadingScreen",   // 加载画面
            "UIExtension",           // UI 扩展
            "EnhancedInput",         // 增强输入
        });

        PrivateDependencyModuleNames.AddRange(new string[] {
            "DeveloperSettings",
            "GameFeatures",
            "NetCore",
            "Slate",
            "SlateCore",
            "UMG",
        });
    }
}
