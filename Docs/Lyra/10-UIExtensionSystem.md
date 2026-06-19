# UI 扩展系统

## 概念

Lyra 的 UI 系统基于 **CommonUI 插件**，使用 **Extension Point 模式** — 通过 GameplayTag 定位 UI 插槽，动态加载 Widget。

## 核心概念

| 概念 | 说明 |
|------|------|
| Extension Point | 用 GameplayTag 标识的 UI 插槽位置 |
| Activatable Widget | 可激活的 Widget（CommonUI 概念） |
| UIExtension Subsystem | 管理 Widget 注册和显示 |
| CommonUI | Epic 的跨平台 UI 框架 |

## 工作方式

```
HUD 布局定义 Extension Points (Tag 标识)
    ↓
GameFeature Action (AddWidget) 指定:
    ├─ Extension Point Tag (放在哪)
    └─ Widget 类 (显示什么)
    ↓
GFP 加载时 → Widget 注册到对应 Extension Point
GFP 卸载时 → Widget 自动移除
```

## 使用示例

- ShooterCore 的 `LAS_ShooterGame_StandardHUD` ActionSet
- 定义了标准 HUD Widget 的 Extension Point 注册
- 不同 Experience 可以加载不同的 HUD 布局

## 优势

- Experience 切换时自动切换 UI
- 组件间解耦 — HUD 不知道具体的 Widget 实现
- 支持跨平台 UI 自适应

## 参考链接

- CommonUI 官方文档: https://dev.epicgames.com/documentation/unreal-engine/common-user-plugin-in-unreal-engine-for-lyra-sample-game
- X157 UI 插件说明: https://x157.github.io/UE5/LyraStarterGame/Plugins/
