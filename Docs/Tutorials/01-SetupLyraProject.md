# Lyra 项目搭建

## 通过 Epic Games Launcher 下载

1. 打开 Epic Games Launcher
2. 点击 **Samples** 选项卡
3. 搜索 **Lyra Game Sample**
4. 点击 **Create Project** 创建副本
5. 选择安装位置

**注意**: Lyra 是一个完整的项目，不是模板。直接从 Launcher 获取最简单。

## 通过源码获取

1. 从 GitHub 下载 UE 源码:
   https://github.com/EpicGames/UnrealEngine
2. 在 `Samples/Games/Lyra/` 找到 Lyra
3. 需要从 Launcher 版本复制 Content 文件夹 (详见 GitHub README)

## 创建自己的游戏项目

### 步骤 1: 创建 GameFeature Plugin

```
编辑器 → 工具 → 新建插件 → Game Feature
名称如: MyGame
位置: Plugins/GameFeatures/
```

### 步骤 2: 配置 GameFeatureData

创建 `UGameFeatureData` 在 `Content/GameFeatureData/`:
- 添加扫描目录: `/Experiences/`、`/Characters/` 等
- 添加 GameplayCue 路径

### 步骤 3: 创建 Experience

- 创建 `ULyraExperienceDefinition` 数据资产
- 指定 DefaultPawnData
- 引用自己的 GFP
- 创建 ActionSets

### 步骤 4: 创建 Map

- 创建新关卡
- World Settings 中设置 Default Gameplay Experience
- 放置 LyraPlayerStart

## 参考链接

- 官方 Lyra 下载说明: https://dev.epicgames.com/documentation/unreal-engine/lyra-sample-game-in-unreal-engine
- X157 项目搭建: https://x157.github.io/UE5/LyraStarterGame/Getting-Started-Setting-Up-a-New-LyraStarterGame-Project.html
- X157 创建 GameFeature Experience: https://x157.github.io/UE5/LyraStarterGame/How-To-Create-New-GameFeature-Dev-Experience.html
