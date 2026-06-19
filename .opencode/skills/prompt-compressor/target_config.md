# 生图模型格式适配配置

> 根据目标生图模型，将通用提示词转换为模型最优格式。
> 在步骤⑲画质选择后，可选择目标模型。

---

## Stable Diffusion (SD1.5 / SDXL / SD3)

### 正向 Prompt
```
英文, 逗号分隔, (重要特征:1.2), (次要特征:1.1)
前75个token权重更高，核心特征放最前
每段可用 BREAK 分隔不同区域（角色/背景/风格）
```

**格式**: `masterpiece, best quality, {角色描述英文}, {渲染风格}, {模版}, {画质}`

**权重示例**:
- 核心特征: `(assassin:1.2), (dark armor:1.2)`
- 次要特征: `(white short hair:1.1), (asymmetric cape:1.1)`
- 背景/风格: 不加权重

### 负向 Prompt
```
英文, 逗号分隔（与正向同格式）
通用负向: lowres, bad anatomy, bad hands, extra fingers, mutated, disfigured, ugly, watermark, text, signature
追加: {从 neg_rules.md 提取的标签}
```

### 推荐参数
| 画质 | Steps | CFG | Sampler |
|------|-------|-----|---------|
| 4K | 30-40 | 7-9 | DPM++ 2M Karras |
| HD | 20-30 | 7 | Euler a |
| Standard | 20 | 5-7 | Euler a |

---

## Midjourney (MJ v6+)

### 正向 Prompt
```
短语串联（非逗号分隔），::权重控制
/imagine prompt: {角色描述英文} --ar 3:4 --stylize 250 --v 6.1
```

**格式**: `/imagine prompt: {角色姓名}, {race} {gender} {class}, {体型}, {发型}, {服装}, {武器}, {配色}, {性格气质}, {元素效果}, {渲染风格}, {展示模版} --ar 3:4`

**权重语法**: `dark armor::2 white short hair::1 dagger::1.5` (用 `::` 而非 `()`, 权重范围0.5-2)

### 负向 Prompt
```
--no keyword1, keyword2, keyword3
注意: MJ --no 参数有字数限制, 只放最重要的5-8个
```

**格式**: `--no {从 neg_rules.md 提取的最核心5-8个标签}`

### 推荐参数
| 用途 | --ar | --stylize | --chaos | 备注 |
|------|------|-----------|---------|------|
| 角色展示图 | 3:4 | 250 | 0 | 标准角色竖构图 |
| 全设计稿 | 16:9 | 100 | 0 | 横构图容纳更多模块 |
| 三视图 | 16:9 | 50 | 0 | 降低风格化保证一致性 |
| 快速预览 | 3:4 | 100 | 20 | 加点随机性 |

---

## Flux (Flux.1)

### 正向 Prompt
```
自然英文描述，句子形式（类似当前中文输出的英文版）
Flux 对自然语言理解强，不需要逗号分隔和权重语法
```

**格式**: 
```
{Name} is a {race} {gender} {class} with {hair} and {personality} expression. 
She wears {costume} in {color} tones with {design_movement} influences. 
{Weapon} at {position}. {Element} effects on {location}. 
{Body} proportions. Rendered in {rendering} style at {quality} quality, {template} layout.
```

### 负向 Prompt
```
Flux 对负向 prompt 不敏感，可以留空或只写通用标签
(Flux的CFG很低, 1-3, 负向几乎无影响)
```

**建议**: 不输出单独负向段，在正向描述中自然避免（如"dark armor"自然会排除"bright colors"）

### 推荐参数
| 画质 | Steps | CFG | 备注 |
|------|-------|-----|------|
| 4K | 28-50 | 1-3 | Flux 步数偏高 |
| HD | 20-30 | 1-2 | |
| Standard | 15-20 | 1 | CFG=1 即忽略负向 |

---

## 输出切换逻辑

用户可在步骤⑲之后选择目标模型，或在对话中说 "用SD格式" / "用MJ格式" / "用Flux格式"。

```
默认 → 通用格式（中文正向 + 英文负向, 逗号分隔）
SD   → 英文正向(权重括号) + 英文负向 + 参数建议
MJ   → 英文正向(::权重) + --no负向 + --ar --stylize + 参数建议
Flux → 英文自然描述正向 + (负向留空) + 参数建议
```
