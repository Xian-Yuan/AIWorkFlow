# DataTable_Standards（数据表标准）

说明（English (中文解释)）：This guide defines schema conventions, key fields, import/export rules, versioning, localization, and bilingual notes for data tables（本文定义数据表模式约定、关键字段、导入/导出、版本化与本地化/双语注释）。

## 0. Scope（适用范围）
- 适用于所有设计相关数据（职业、血统、卡池规则、奖励、属性/词缀等）。
- 单机项目约束：仅本地数据读取与校验，不涉及网络复制。

## 1. Schema Conventions（模式约定）
- 主键（PrimaryKey）：`ID`（FName，英文命名，唯一且稳定）。
- 显示名（DisplayName）：`FText`（可本地化，双语注释：English (中文解释)）。
- 是否启用（Enabled）：`bool`，默认 true；禁用行不参与运行时逻辑。
- 版本（DataVersion）：`int32`，行级版本号，用于兼容迁移与差异比较。
- 标签（Tags）：`FGameplayTagContainer`，与 GameplayTag_Governance.md 对齐。
- 软引用（SoftReference）：`TSoftObjectPtr` / `TSoftClassPtr`（资产或类的延迟加载）。
- 备注（Note）：`FString`（English (中文解释) 双语说明）。

推荐列顺序
1) ID, DisplayName, Enabled, DataVersion, Tags, ...（其他业务字段）..., Note

## 2. Key Fields（关键字段通用定义）
- 数值范围：为所有数值字段提供 Range（最小/最大）与默认值，文档中明确。
- 枚举/模式：为匹配/过滤类字段提供枚举（如 TagMatchMode: Any/All/None）。
- 索引建议：对高频过滤字段（Tags、Level 区间）建立辅助索引（开发阶段写入工具支持）。

## 3. Import/Export（导入/导出）
- 格式支持：CSV/JSON（英文列名），避免中文列名导致编码问题。
- 单行长度控制：避免超长文本字段（超过 4KB 的文本建议拆分或外部引用）。
- 校验流程：
  - 主键唯一性检查
  - 必填字段检查（ID、Enabled、DataVersion）
  - 标签有效性检查（与 GameplayTag_Governance 对齐）
  - 数值范围检查（最小/最大/默认）

## 4. Versioning（版本化）
- 采用语义化版本号：`Major.Minor.Patch`（文档层），行级 `DataVersion` 递增。
- 迁移策略：当行结构变化时，增加 `DataVersion` 并在迁移脚本中记录映射关系（文档阶段仅记录策略）。

## 5. Localization & Bilingual（本地化与双语）
- 所有 DisplayName 字段支持本地化；术语在文档中采用 English (中文解释) 的格式说明。
- Note 字段采用英文为主＋中文解释，避免出现纯中文导致跨平台编码问题。

## 6. Validation Checklist（校验清单）
- [ ] ID 唯一且稳定（英文命名）
- [ ] Enabled 为 true 的行包含必需字段
- [ ] DataVersion 为非负整数并在变更时递增
- [ ] Tags 在命名空间内有效（Game.* 前缀）
- [ ] 数值字段有明确范围与默认值
- [ ] 无网络相关字段或标志（单机限制）

## 7. Cross References（交叉引用）
- GameplayTag_Governance.md（标签命名与校验）
- Profession_System.md（职业定义数据表）
- Class_Bloodline_System.md（血统等级规则数据表）
- Survivors_Mode_Design.md（DeckCardPoolRules 数据表）
- Meta_Progression_Design.md（存档与奖励相关数据表）
- UI_Conventions.md（呈现与术语规则）

## 8. Maintenance（维护建议）
- 新增/变更列需更新本标准文档与对应设计文档示例。
- 建议在编辑工具中集成基础校验（唯一性、范围、标签有效性）。
- 在 Saved/ 目录下保留导入前的备份快照，便于回滚（不使用 git 回档）。