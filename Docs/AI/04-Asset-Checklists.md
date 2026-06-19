# Asset Checklists

## 目标

本文件用于约束 AI 在生成代码后，必须同步检查 Lyra / GAS 常见数据资产与配置资源，避免“代码对了但资源没接上”。

## ExperienceDefinition

检查项：

- 是否引用了正确的 `GameFeature` 内容
- 是否启用了需要的 `ActionSet`
- 是否与目标玩法模式匹配

## GameFeatureData

检查项：

- `.uplugin` 是否位于正确目录
- `Category` 是否为 `Game Features`
- `PrimaryAssetTypesToScan` 是否覆盖新资源目录
- 依赖插件是否已启用

## PawnData

检查项：

- 是否绑定正确 `PawnClass`
- 是否引用正确 `AbilitySet`
- 是否引用正确 `InputConfig`
- 是否绑定正确相机或标签关系映射

## InputConfig

检查项：

- `GameplayTag` 与 `InputAction` 是否一一对应
- 是否与 `AbilitySet` 使用同一输入标签
- 是否避免重复或冲突映射

## AbilitySet

检查项：

- 是否包含正确能力类
- 是否设置正确输入标签
- 是否缺失被动能力、初始化能力或装备能力

## GameplayEffect

检查项：

- 修改目标属性是否存在于目标 `AttributeSet`
- 持续策略、标签需求、堆叠策略是否合理
- 是否需要 `SetByCaller`

## GameplayCue

检查项：

- Tag 是否以 `GameplayCue.` 开头
- 路径是否可被系统扫描
- 表现是否与能力或效果匹配

## AI 资产

### StateTree

- Context 是否绑定正确 Actor 或组件
- 状态切换条件是否完整
- 任务节点输入输出是否明确

### Behavior Tree

- Blackboard Key 是否与任务需求一致
- Service / Decorator / Task 职责是否清晰

### EQS

- 查询目的是否明确
- 结果是否只用于选点，不承担结算逻辑

### SmartObject

- 过滤标签是否正确
- 占位、释放、失败回退是否有路径

## 最终交付要求

AI 在完成实现时，应至少指出：

- 哪些资产需要新建
- 哪些资产需要修改
- 哪些字段必须手工确认
