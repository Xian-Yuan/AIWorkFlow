# Test Checklists

## 目标

本文件用于把“AI 写完代码后怎么验证”标准化，避免只做语法层检查，不做功能、资产、时序和性能回归。

## 最小验证原则

每次功能交付后，至少要覆盖以下 4 类检查：

- 编译检查
- 运行时冒烟检查
- 资产接线检查
- 回归风险检查

## 编译检查

至少确认：

- 最近修改文件无明显诊断错误
- `Build.cs` 依赖完整且无明显循环依赖
- `.h/.cpp` 成对存在
- `GENERATED_BODY()`、反射宏、导出宏使用正确

## 运行时冒烟检查

至少确认：

- 目标功能可以触发
- 关键状态会正确切换
- 不会立刻报错、崩溃或空引用
- 输入、能力、AI 或交互链路至少走通一次

## 资产接线检查

至少确认：

- 新资源目录可被扫描
- `Experience / GameFeatureData / PawnData / InputConfig / AbilitySet` 已正确引用
- `StateTree / Blackboard / EQS / SmartObject` 已绑定到正确控制器或资产

## 回归检查

至少确认：

- 未破坏已有输入映射
- 未破坏已有 AbilitySet 或 PawnData
- 未新增无意义 Tick、Timer 或后台任务
- 未误引入复制、RPC 或网络依赖

## 单机项目专用检查

- 不主动增加 `Replicated`、`OnRep`、`RPC`
- 本地状态、存档、配置路径合理
- AI 逻辑可在本地完整运行

## Lyra / GAS 检查

- `OnExperienceLoaded` 时序是否正确
- `InputConfig` 与 `AbilitySet` 的 Tag 是否一致
- `GameplayAbility` 的激活条件、冷却、消耗是否合理
- `GameplayEffect` 修改的属性是否真实存在

## AI 检查

- Pawn 是否被正确 Possess
- 控制器是否绑定了正确 AI 资产
- `StateTree` 或 `Behavior Tree` 是否能进入核心状态
- `EQS` 查询与 `SmartObject` 交互是否存在失败回退

## 日志检查

建议至少检查：

- 编译输出中的首个关键错误
- 运行时错误日志
- AI 状态切换与能力触发日志
- 资源加载或 GameFeature 加载失败日志

## 交付模板

AI 在最终交付时建议附带：

- 已执行的检查项
- 未执行但建议人工验证的检查项
- 已知风险点
- 推荐下一步验证路径
