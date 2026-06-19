# 特征库索引（自动维护）

> 索引由文件系统自动生成，无需手动维护。
>
> **路径规则**: `constraints/{分类目录}/{特征名}.md`
>
> 分类目录名 = 特征类别，文件名（不含 .md）= 特征值。
> 每个目录下的 .md 文件（排除 README.md）即对应一个已入库特征。

## 当前分类（15 个目录，71 个约束文件）

| 分类 | 目录 | 文件数 |
|------|------|:------:|
| 展示模版 | `constraints/template/` | 5 |
| 画质 | `constraints/quality/` | 3 |
| 渲染风格 | `constraints/rendering/` | 3 |
| 体型 | `constraints/body/` | 8 |
| 职业 | `constraints/profession/` | 4 |
| 种族 | `constraints/race/` | 4 |
| 战斗风格 | `constraints/combat_style/` | 4 |
| 武器 | `constraints/weapon/` | 6 |
| 配色 | `constraints/color/` | 3 |
| 设计流派 | `constraints/design_movement/` | 5 |
| 力量来源 | `constraints/power_source/` | 5 |
| 性格 | `constraints/personality/` | 5 |
| 发型 | `constraints/hair/` | 5 |
| 元素 | `constraints/element/` | 5 |
| 服装 | `constraints/costume/` | 5 |

> 约束文件总数可通过 `ls constraints/*/*.md | grep -v README | wc -l` 获取。
> 运行 `constraints/tools/validate_constraints.sh` 校验所有文件格式。
