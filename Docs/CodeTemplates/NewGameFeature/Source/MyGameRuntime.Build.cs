// 如果你的 GFP 名称为 MyGame，UE 编辑器可能自动生成 MyGameRuntime 名称。
// 以下是去掉了 "Runtime" 后缀之前的兼容方案。
// 推荐在创建后按 X157 指南移除 "Runtime" 后缀。

using UnrealBuildTool;

public class MyGameRuntime : ModuleRules
{
    public MyGameRuntime(ReadOnlyTargetRules Target) : base(Target)
    {
        PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;

        PublicDependencyModuleNames.AddRange(new string[] {
            "Core",
            "CoreUObject",
            "Engine",
            "GameplayAbilities",
            "GameplayTags",
            "LyraGame",
            "ModularGameplay",
            "CommonGame",
        });

        PrivateDependencyModuleNames.AddRange(new string[] {
            "GameFeatures",
            "EnhancedInput",
            "UIExtension",
        });
    }
}
