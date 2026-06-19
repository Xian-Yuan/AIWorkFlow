# Lyra 升级指南

## 核心理念

将 Lyra 视为引擎代码，**不直接修改**。通过 GameFeature Plugin 扩展功能，便于引擎升级时同步。

## 升级策略

1. 不要修改 Lyra 基础代码
2. 所有自定义内容放在 GameFeature Plugin 中
3. 使用 `ULyraExperienceActionSet` 而非子类化 Experience BP
4. 使用 CoreRedirects 处理重命名

## 版本间主要变更

| 版本 | 变更内容 |
|------|----------|
| 5.0 → 5.1 | 引入 Initialization State 系统 |
| 5.1 → 5.2 | Pawn Extension 系统改进 |
| 5.2 → 5.3 | GameplayEffect 组件架构 (5.3+) |
| 5.3 → 5.4 | 设备和扩展性配置改进 |
| 5.4 → 5.5 | GAS 组件架构完善 |
| 5.5 → 5.6 | Input 系统改进 |
| 5.6 → 5.7 | 文档整合和 API 稳定性改进 |

## 官方升级文档

https://dev.epicgames.com/documentation/en-us/unreal-engine/upgrading-the-lyra-starter-game-to-the-latest-engine-release-in-unreal-engine

## 参考链接

- X157 升级指南: https://x157.github.io/UE5/LyraStarterGame/UpgradingLyra/
- Unrealist Lyra 深度解析: https://unrealist.org/series/lyra/
