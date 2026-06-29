# AI视频工具提示词策略 — 工具特定最佳实践

> 类别: AI Video Tool Prompting / Platform-Specific Strategy / Kling / Seedance / Vidu / Wan / Sora
> 用途: 不同AI视频工具有不同的擅长和限制——提示词必须适配工具特性才能出最佳效果
> 关联: `prompt-assembly-guide.md`(提示词组装) / `medieval-fantasy-quickref.md`(速查) / `contemporary-trends-2024-2026.md`(AI趋势)

---

## 1. 通用原则 — 7条跨工具铁律

| 铁律 | 原因 | 做法 |
|------|------|------|
| 英文>中文 | 训练语料以英文为主 | 用英文写提示词，中文只做辅助备注 |
| <200英文词 | 视频prompt硬上限 | 60秒模板=150词左右最安全 |
| 负面提示词必填 | AI倾向生成"安全"图像 | `Negative: bright, cartoon, anime, blurry, deformed, watermark, text, logo` |
| 主体+动作先写 | AI优先处理句首信息 | 先写"A knight kneels"再写环境/光线 |
| 具体参数>形容词 | "35mm f/4"比"cinematic"更可控 | 用数值锚定而非模糊描述 |
| 单一运动/镜头 | AI难同时处理复杂运动 | 每段只描述一个运镜+一个动作 |
| 参考图>纯文本 | 图生图比文生图一致性好 | 用参考图锚定风格/角色/构图 |

---

## 2. Kling 3.0/3.1 — 最佳实践

### 2.1 Kling特性

| 特性 | 能力 | 限制 | 策略 |
|------|------|------|------|
| 运镜控制 | camera_move参数精确 | 复杂运镜不稳定 | 用简单运镜(dolly_in/pan_right) |
| 画质 | 高质量6s/10s | >10s质量下降 | 单段6s最佳 |
| 角色一致性 | IP-Adapter可用 | 需要参考图 | 重要角色必须用参考图 |
| 9:16 | 原生支持 | 横屏内容需适配 | 直接写9:16 vertical |
| 提示词 | 中英文都行 | 英文更精确 | 英文为主 |
| 运动幅度 | motion参数可调 | 高motion=高变形 | 适中motion(40-60) |

### 2.2 Kling提示词模板

**6秒叙事模板**:
```
[Subject+Action], [Camera Move], [Lighting], [Composition], 
[Style Anchor], 9:16 vertical, cinematic
Negative: bright, cartoon, anime, blurry, deformed, watermark
```

**Kling中世纪西幻示例**:
```
A knight in blackened plate armor kneels before a cathedral door, 
slow dolly in from medium-wide to close-up, 
Deakins single window key light negative fill, 
centered symmetry one-point perspective, 
cold blue crushed blacks Vision3 500T, 
9:16 vertical, cinematic dark fantasy
Negative: bright, cartoon, anime, blurry, deformed, watermark, text
```

**Kling运镜参数对照**:
| 运镜 | Kling参数 | 效果 |
|------|----------|------|
| 推入 | camera_move=forward | 聚焦 |
| 拉出 | camera_move=backward | 揭示 |
| 左横移 | camera_move=pan_left | 环境 |
| 右横移 | camera_move=pan_right | 环境 |
| 上升 | camera_move=up | 宏大 |
| 下降 | camera_move=down | 压迫 |
| 环绕 | camera_move=orbit | 英雄 |

### 2.3 Kling最容易翻车的5种场景 + 解法

| 翻车场景 | 问题 | 解法 |
|---------|------|------|
| 骑士骑马 | 马腿经常错 | 简化为"骑士站在马旁"而非骑马 |
| 双人对话 | 面部变形 | 分两段单独生成+后期合成 |
| 战斗动作 | 武器位置错 | 用参考图锚定武器位置 |
| 手部特写 | 指节数错 | 避免ECU手部，改为CU脸部+手部虚化 |
| 远景人群 | 人群模糊 | 用"single figure in vast landscape"避免多人 |

---

## 3. Seedance 2.0/2.1 — 最佳实践

### 3.1 Seedance特性

| 特性 | 能力 | 限制 | 策略 |
|------|------|------|------|
| 电影模式 | 5种预设(Narrative/Studio/Action/Performance/Atmospheric) | 模式间不能混合 | 每段选一种模式 |
| 画质 | 极高 | 生成慢 | 关键镜头用Seedance |
| 运镜 | 极精确 | 需要写清运镜速度 | 用运动速度锚定(如"like dust in honey") |
| 色彩 | 调色控制好 | 需要显式写 | 写清调色+胶片模拟 |
| 竖屏 | 原生支持 | — | 直接写9:16 |

### 3.2 Seedance电影模式速选(速查手册17节扩展)

| 模式 | 提示词开头 | 适用西幻场景 | 默认参数 |
|------|----------|------------|---------|
| Narrative | `Seedance Narrative mode,` | 对话/行走/日常 | 35-50mm, 慢推, 中性暖 |
| Studio | `Seedance Studio mode,` | 特写/独白/表情 | 85-135mm, 锁定, 高对比 |
| Action | `Seedance Action mode,` | 战斗/追逃 | 14-24mm, 手持, 去饱和 |
| Performance | `Seedance Performance mode,` | 魔法/仪式 | 50-85mm, 环绕, 戏剧调色 |
| Atmospheric | `Seedance Atmospheric mode,` | 森林/废墟/梦 | 24-35mm, 漂浮, 极端调色 |

### 3.3 Seedance提示词模板

```
Seedance [Mode] mode,
[Subject+Action], [Camera+Lens+Motion], 
[Lighting DP-anchored], [Composition Director-anchored], 
[Color grade + Film stock], 
9:16 vertical, cinematic
```

**Seedance中世纪西幻示例(魔法觉醒)**:
```
Seedance Performance mode,
A mage raises her hands as golden light streams weave from her fingers, 
slow 360 orbit, 50mm moderate DOF, 
volumetric golden light from above, Tarkovsky-style natural elements, 
warm gold with deep shadows, Kodak Portra 400, 
9:16 vertical, cinematic dark fantasy
```

---

## 4. Vidu — 最佳实践

### 4.1 Vidu特性

| 特性 | 能力 | 限制 | 策略 |
|------|------|------|------|
| 速度 | 极快 | 画质略低于Kling/Seedance | 快速迭代用Vidu |
| 一致性 | 图生图一致性好 | 纯文生图一致性一般 | 重要镜头用参考图 |
| 运镜 | 基本运镜支持 | 复杂运镜不稳定 | 简单运镜+固定机位 |
| 风格 | 写实风格好 | 风格化弱 | 避免过度风格化描述 |

### 4.2 Vidu提示词策略

- **用Vidu做快速预览**: 先用Vidu快速生成5-10个版本，选最佳构图+光线
- **再用Kling/Seedance精修**: 把Vidu输出作为参考图，用更高质量工具精修
- **Vidu提示词更简短**: 100英文词以内，去掉复杂运镜描述

**Vidu模板**:
```
[Subject+Action], [Simple Camera], [Lighting], [Style], 
9:16 vertical, cinematic
```

---

## 5. Wan 2.2 — 最佳实践

### 5.1 Wan特性

| 特性 | 能力 | 限制 | 策略 |
|------|------|------|------|
| 开源 | 完全开源可控 | 需要本地部署 | ComfyUI集成 |
| 灵活性 | ControlNet/IP-Adapter | 需要技术能力 | 需要ComfyUI技能 |
| 一致性 | 通过工作流控制 | 依赖工作流设计 | 用ComfyUI完整工作流 |
| 画质 | 高(有ControlNet) | 纯文生图一般 | 必须用ControlNet |

### 5.2 Wan+ComfyUI工作流要点

| 工作流节点 | 作用 | 西幻适配 |
|-----------|------|---------|
| IP-Adapter | 角色一致性 | 微表情身份证→IP-Adapter |
| ControlNet Depth | 构图控制 | 分镜草图→Depth→构图 |
| ControlNet Canny | 边缘控制 | 铠甲/建筑轮廓 |
| AnimateDiff | 运动控制 | 运镜路径定义 |

---

## 6. Sora / 通用最佳实践

### 6.1 Sora特性(已知)

| 特性 | 能力 | 注意 |
|------|------|------|
| 物理理解 | 更好的物理模拟 | 仍需明确描述 |
| 长视频 | 可生成长视频 | 长视频一致性仍挑战 |
| 复杂场景 | 多角色多动作 | 仍建议简化 |
| 运镜 | 精确运镜描述 | 写清每一步 |

### 6.2 通用AI视频提示词最终模板

```
[Duration]s | [Aspect Ratio] | [Style]

Camera: [Camera Move] from [Start Shot] to [End Shot].
Subject: [Who] [Doing What].
Environment: [Where] [Atmosphere].
Lighting: [DP Style] [Light Description].
Composition: [Director Style] [Composition Description].
Color: [Color Grade] [Film Stock].
Physical Realism: [Key physical details].
Motion: [Speed anchor].

Negative: bright, cartoon, anime, blurry, deformed, watermark, text, logo.
```

**完整中世纪西幻示例**:
```
6s | 9:16 | Cinematic Dark Fantasy

Camera: Slow dolly in from medium-wide to close-up.
Subject: A weathered knight in blackened plate armor kneels before a cathedral door,
sword planted in stone beside him.
Environment: Rain-soaked stone steps, distant towers in fog.
Lighting: Deakins single motivated key from doorway, negative fill, no top light.
Composition: Kubrick perfect symmetry, one-point perspective down the nave, centered.
Color: Cold blue shadows, crushed blacks, Kodak Vision3 500T.
Physical Realism: SSS on wet skin, anisotropic weave on cloak, rain on stone.
Motion: Like embers floating in still air.

Negative: bright, cartoon, anime, blurry, deformed, watermark, text, logo.
```

---

## 7. 工具选择决策树

```
需要最高画质？
├─ 是 → 关键镜头用 Seedance(Performance/Atmospheric)
└─ 否 → 需要快速迭代？
         ├─ 是 → 预览用 Vidu → 精修用 Kling
         └─ 否 → 需要精确控制？
                  ├─ 是 → Wan 2.2 + ComfyUI
                  └─ 否 → Kling 3.0(默认选择)
```

| 场景 | 推荐工具 | 模式 | 原因 |
|------|---------|------|------|
| 骑士独白 | Seedance | Studio | 最高画质+锁定+高对比 |
| 战斗场景 | Kling | Action | 运镜灵活+手持 |
| 魔法仪式 | Seedance | Performance | 环绕+戏剧调色 |
| 森林漫步 | Seedance | Atmospheric | 漂浮+氛围 |
| 对话场景 | Kling | Narrative | 慢推+中性 |
| 快速预览 | Vidu | — | 速度快 |
| 精确构图 | Wan | ComfyUI | ControlNet |

---

*AI视频工具提示词策略 v1.0 完成。通用7条铁律+Kling/Seedance/Vidu/Wan/Sora各自最佳实践+工具选择决策树+最终模板。*


---

## 8. 2026Q2 AI视频工具实际输出对比

### 8.1 中世纪西幻场景横向对比

| 场景 | Kling 3.1 | Seedance 2.1 | Vidu | Wan 2.2+ComfyUI | Sora |
|------|-----------|-------------|------|-----------------|------|
| 暗黑骑士 | 锐利+去饱和好+铠甲细节好 | 最精致+调色最准+面部最清 | 铠甲略塑料+调色偏暖 | 需ControlNet锚定+效果最可控 | 物理最好+雨滴真实 |
| 魔法森林 | 自然光好+体积光够+粒子尚可 | 粒子最好+光最美+氛围最强 | 森林写实+魔法弱 | 可精确控制魔法+需工作流 | 魔法物理最好 |
| 巨龙 | 尺度感好+火效好+阴影逻辑差 | 火最精致+尺度最好 | 龙偏小+火简单 | 可精确控制龙的位置 | 龙+人交互最好 |
| 地牢蜡烛 | 蜡烛光好+阴影尚可+锁定稳定 | 蜡烛光最准+阴影最真实 | 偏亮+阴影弱 | 可精确控制光源位置 | 蜡烛物理最真 |
| 战场 | 人多场景弱+建议单人 | 大场景弱+建议中景 | 大场景弱 | 可分层合成 | 大场景最好 |
| 诅咒发作 | 色彩偏移好+变形尚可 | 变形最好+色彩偏移可控 | 简单+变形弱 | 需特殊工作流 | 变形最自然 |

### 8.2 各工具最强场景

| 工具 | 最强场景 | 原因 |
|------|---------|------|
| Kling | 骑士/铠甲/雨天/写实 | 训练数据中这类内容丰富 |
| Seedance | 魔法/仪式/人脸/调色 | 电影模式精确+调色理解强 |
| Vidu | 快速预览/简单场景 | 速度优势 |
| Wan | 精确构图/ControlNet | 开源+可编程 |
| Sora | 物理/交互/大场景 | 训练最广+物理理解最好 |

---

## 9. AI视频工作流最佳实践(2026Q2)

### 9.1 完整制作流程

`
1. 脚本 → 查prompt-assembly-guide确定情绪/场景
2. 分镜 → 查storyboard-visual-planning确定序列
3. 工具选择 → 用本文件决策树选择工具
4. 风格锚定 → 查director/DP/colorist签名
5. 提示词编写 → 用工具模板+MCSLA公式
6. 快速预览 → Vidu生成5-10版本选最佳构图
7. 精修生成 → Kling/Seedance用参考图精修
8. 物理检查 → 检查8层物理真实感清单
9. 批量生产 → 确认风格后批量生成
10. 后期 → 调色/声音/剪辑叠加
`

### 9.2 多工具协作策略

| 策略 | 流程 | 适用场景 |
|------|------|---------|
| Vidu→Kling | 快速预览→精修 | 所有场景(默认) |
| Kling→Seedance | 通用→人脸精修 | 角色特写/对话 |
| Wan→Kling | 构图控制→质量提升 | 复杂构图 |
| Seedance单独 | 高质量一步到位 | 关键镜头/魔法/仪式 |
| Sora单独 | 复杂物理/交互 | 大场景/战斗 |

### 9.3 风格一致性跨工具策略

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| 不同工具风格不同 | 各工具有默认美学 | 用相同的风格锚定词(导演+DP+调色师) |
| 肤色跨工具不一致 | 默认肤色偏向不同 | 加"consistent skin tone, warm olive" |
| 调色跨工具不一致 | 默认调色不同 | 加相同的胶片模拟+调色师签名 |
| 角色跨工具不一致 | 默认人脸不同 | 用IP-Adapter/参考图锚定角色 |
| 环境跨工具不一致 | 默认光照不同 | 加相同的光线描述+DP签名 |

---

## 10. AI视频工具一句话速查

| 工具 | 最强场景 | 提示词关键词 |
|------|---------|------------|
| Kling 3.1 | 写实/铠甲/雨天/运镜 | Kling-grade, camera_move, 6s, cinematic |
| Seedance 2.1 | 魔法/人脸/调色/仪式 | Seedance [Mode], 50mm, film stock, cinematic |
| Vidu | 快速预览/简单场景 | Vidu-grade, simple, preview, 9:16 |
| Wan 2.2 | 精确构图/ControlNet | Wan+ComfyUI, ControlNet, IP-Adapter |
| Sora | 物理/交互/大场景 | Sora-grade, physics, interaction, cinematic |
