# CommonUI 系统

## 概念

CommonUI 是 Epic 提供的跨平台 UI 框架，为 Lyra 和 Fortnite 的 UI 系统基础。

## 核心特性

- **ActivatableWidget**: 可激活/停用的 Widget 基类
- **CommonButton**: 多功能按钮基类
- **CommonTextBlock**: 文本组件
- **CommonActionWidget**: 操作提示（动态显示按键图标）
- **UIExtension**: Extension Point 模式
- **Input Action Binding**: 输入操作绑定

## Lyra 中的使用

- UI 布局通过 Extension Point 组织
- GameFeature Action 动态添加 Widget
- 不同 Experience 可以加载不同 UI
- 跨平台适配：PC/主机/移动端

## 参考链接

- CommonUser Plugin 文档: https://dev.epicgames.com/documentation/unreal-engine/common-user-plugin-in-unreal-engine-for-lyra-sample-game
- CommonUI 官方文档: https://dev.epicgames.com/documentation/unreal-engine/common-ui
