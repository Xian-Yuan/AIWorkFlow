# 情绪 -> SALCSQ 自动路由表

> 版本: v1.0 | 日期: 2026-06-29
> 状态: 可用
> 用途: 输入情绪关键词，自动输出SALCSQ六模块参数，实现知识库自动路由
> 融合: master-route-quickref.md + ai-prompt-to-result-patterns.md + medieval-fantasy-pattern-library.md + 速查手册情绪-导演查表
> 关联: ai-shortdrama-salcsq-template.md(模板) / director-style-kb/(详细签名)

---

## 0. 使用方法

1. 确定你要表达的**主情绪**(从下面30种中选)
2. 查表得到SALCSQ六模块的默认参数
3. 根据场景微调(可选)
4. 用SALCSQ模板组装提示词

---

## 1. 核心情绪路由(10种)

### 恐惧/窒息

| 模块 | 默认参数 | 查KB |
|------|---------|------|
| **S** | 被追猎者: 紧绷面部, 汗湿, 瞳孔放大 | medieval-fantasy-pattern-library(角色原型) |
| **A** | breathing: ragged, eye: darting, jaw: clenched, scan: frantic, control: failing | 速查19节(情绪外化) |
| **L** | Kubrick+Alcott, candle-only/no fill/crushed blacks, 诅咒绿+HP5 | horror-dark-directors |
| **C** | 35mm f/4慢推+走廊纵深+one-point perspective, 9:16 vertical depth | 速查1节(运镜)+4节(焦段) |
| **S** | horror-dark-directors(Kubrick/Eggers/Aster) | horror-dark-directors |
| **Q** | no fill, crushed blacks, let shadow be real, no beautification | ai-video-tool-prompting |

**一句话公式**: `fear, dungeon, symmetric one-point corridor, candle only, cold blue, 35mm slow push-in, Kubrick-grade, 9:16`

---

### 敬畏/崇高

| 模块 | 默认参数 | 查KB |
|------|---------|------|
| **S** | 守望者: 仰望姿态, 小比例, 剪影 | medieval-fantasy-pattern-library |
| **A** | breathing: holding, eye: glistening/fixed upward, delay: slow blink, residue: afterglow | 速查19节 |
| **L** | Villeneuve+Lubezki, overcast/natural, 冰原蓝+250D | fantasy-epic-directors |
| **C** | 14mm f/8 EWS+负空间+locked, human 5% of frame, 9:16 vast vertical | 速查1节+4节 |
| **S** | fantasy-epic-directors(Villeneuve/Tarkovsky/Malick) | fantasy-epic-directors |
| **Q** | human 5% of frame, creature fills horizon, vast scale, no fill | ai-video-tool-prompting |

**一句话公式**: `awe, vast landscape, negative space, human tiny, 14mm f/8 locked, icefield blue, Villeneuve-grade, 9:16`

---

### 孤独/隔离

| 模块 | 默认参数 | 查KB |
|------|---------|------|
| **S** | 流放者: 单人, 简朴, 疲惫 | medieval-fantasy-pattern-library |
| **A** | breathing: deep and slow, eye: distant/staring-through, jaw: relaxed, delay: slow | 速查19节 |
| **L** | Bergman+Nykvist, overcast diffused, 荒原灰+HP5 | european-masters |
| **C** | 50mm f/2.8 MS+锁定+偏置+大面积负空间, 9:16 vast emptiness | 速查1节+8节 |
| **S** | european-masters(Bergman/Malick/Tarkovsky) | european-masters |
| **Q** | no beautification, austere, single figure, vast negative space | ai-video-tool-prompting |

**一句话公式**: `loneliness, vast emptiness, single figure, 50mm f/2.8 offset, wasteland grey, Bergman-grade, 9:16`

---

### 权力/压迫

| 模块 | 默认参数 | 查KB |
|------|---------|------|
| **S** | 统治者: 居高临下, 华服, 王冠/权杖 | medieval-fantasy-pattern-library |
| **A** | breathing: controlled, eye: locked/intimidating, jaw: clenched, control: suppressing | 速查19节 |
| **L** | Nolan+van Hoytema, backlight/divine, 圣殿金光+500T | crime-thriller-directors |
| **C** | 135mm f/2.8 MCU+俯拍+centered symmetry, 9:16 power vertical | 速查1节+8节 |
| **S** | crime-thriller-directors(Nolan/Kubrick/Fincher) | crime-thriller-directors |
| **Q** | centered symmetry, no handheld, locked, divine backlight | ai-video-tool-prompting |

**一句话公式**: `power, throne room, centered low angle, divine backlight, 135mm MCU, cathedral gold, Nolan-grade, 9:16`

---

### 魔法/神秘

| 模块 | 默认参数 | 查KB |
|------|---------|------|
| **S** | 觉醒者: 微光, 瞳孔变色, 手指颤动 | medieval-fantasy-pattern-library |
| **A** | breathing: shallow, eye: glistening/color shifting, delay: 2-beat, control: failing | 速查19节 |
| **L** | del Toro+Navarro, volumetric/ethereal, 暮色紫+500T | fantasy-epic-directors |
| **C** | 50mm f/2.0 环绕+体积光, 9:16 vertical depth | 速查1节+4节 |
| **S** | fantasy-epic-directors(del Toro/Villeneuve) | fantasy-epic-directors |
| **Q** | consistent light source, illuminates face, volumetric but grounded | ai-video-tool-prompting |

**一句话公式**: `magic, ritual, 50mm orbit, volumetric light, twilight purple, del Toro-grade, 9:16`

---

### 背叛/阴谋

| 模块 | 默认参数 | 查KB |
|------|---------|------|
| **S** | 密谋者: 半脸光, 侧身, 手握暗器 | medieval-fantasy-pattern-library |
| **A** | breathing: controlled/whisper, eye: avoidant/darting, jaw: clenched, scan: sweeping | 速查19节 |
| **L** | Fincher+Khondji, sodium orange/no fill, 去饱和+500T | crime-noir-urban |
| **C** | 85mm f/2.0 锁定+半脸光+dutch angle, 9:16 narrow framing | 速查1节+8节 |
| **S** | crime-noir-urban(Fincher/Hitchcock) | crime-noir-urban |
| **Q** | desaturated, sodium orange, shadow on faces, no fill | ai-video-tool-prompting |

**一句话公式**: `betrayal, whispered conspiracy, 85mm half-face light, sodium orange, desaturated, Fincher-grade, 9:16`

---

### 牺牲/悲壮

| 模块 | 默认参数 | 查KB |
|------|---------|------|
| **S** | 殉道者: 逆光剪影, 伤痕, 微笑 | medieval-fantasy-pattern-library |
| **A** | breathing: deep and slow, eye: glistening/fixed ahead, jaw: clenched, residue: afterglow | 速查19节 |
| **L** | Malick+Deakins, backlight/silhouette, 唯一暖+250D | war-history-drama-directors |
| **C** | 85mm f/1.4 慢推+逆光剪影+长持3-5s, 9:16 vertical isolation | 速查1节+4节 |
| **S** | war-history-drama-directors(Malick/Lean/Jackson) | war-history-drama-directors |
| **Q** | backlight, sole warm in cold, slow motion, hold 3-5s, no beautification | ai-video-tool-prompting |

**一句话公式**: `sacrifice, backlit silhouette, 85mm f/1.4 slow push, sole warm in cold, Malick-grade, 9:16`

---

### 愤怒/复仇

| 模块 | 默认参数 | 查KB |
|------|---------|------|
| **S** | 复仇者: 紧握武器, 血/泥, 眼中怒火 | medieval-fantasy-pattern-library |
| **A** | breathing: ragged, eye: locked/intense, jaw: grinding, control: failing/suppressing | 速查19节 |
| **L** | Evans+Stahelski, handheld/firelight, 战火红+800T | action-martial-directors |
| **C** | 14mm f/2.8 手持+快速剪辑+crash zoom, 9:16 claustrophobic | 速查1节+4节 |
| **S** | action-martial-directors(Evans/Stahelski/Snyder) | action-martial-directors |
| **Q** | handheld rough, no beautification, speed ramp, impact felt, dirt and blood | ai-video-tool-prompting |

**一句话公式**: `anger, revenge, 14mm handheld, crash zoom, warfire red, speed ramp, Evans-grade, 9:16`

---

### 悲伤/失去

| 模块 | 默认参数 | 查KB |
|------|---------|------|
| **S** | 哀悼者: 肩膀颤抖, 泪痕, 蜷缩 | medieval-fantasy-pattern-library |
| **A** | breathing: shallow/ragged, eye: glistening/distant, jaw: relaxed, delay: slow, residue: wetness | 速查19节 |
| **L** | Tarkovsky+Doyle, overcast/silhouette, 荒原灰+500T | european-masters |
| **C** | 135mm f/2.8 锁定+长持+shallow DOF, 9:16 isolation | 速查1节+4节 |
| **S** | european-masters(Tarkovsky/Bergman/Wong Kar-wai) | european-masters |
| **Q** | long hold 3-5s, silence, no score, let silence breathe | ai-video-tool-prompting |

**一句话公式**: `sadness, loss, 135mm f/2.8 locked, shallow DOF, wasteland grey, Tarkovsky-grade, hold 5s, 9:16`

---

### 浪漫/禁忌

| 模块 | 默认参数 | 查KB |
|------|---------|------|
| **S** | 恋人: 偏轴, 前景遮挡, 暖冷交汇 | medieval-fantasy-pattern-library |
| **A** | breathing: shallow, eye: glistening/pupils dilated, control: suppressing, delay: slow | 速查19节 |
| **L** | Wong Kar-wai+Doyle, golden hour/step-printing, 暖冷交织+500T | romance-melodrama-visual |
| **C** | 50mm f/1.4 偏置+柔焦+前景遮挡, 9:16 intimate | 速查1节+8节 |
| **S** | romance-melodrama-visual(Wong Kar-wai/Sirk/Ozu) | romance-melodrama-visual |
| **Q** | step-printing, longing not touching, warm-cold split, soft focus | ai-video-tool-prompting |

**一句话公式**: `romance, forbidden, 50mm f/1.4 off-axis, soft focus, warm-cold split, Wong Kar-wai-grade, 9:16`

---

## 2. 扩展情绪路由(10种次级情绪)

| 情绪 | S(主体原型) | A(动作特征) | L(光影+调色) | C(默认镜头) | Style签名 | Q(修复词) | 一句话公式 |
|------|-----------|-----------|--------------|-----------|----------|----------|----------|
| 忠诚 | 并肩战友 | breathing: steady, eye: locked on comrade, jaw: set | 温暖侧光, 酒馆暖+500T | 35mm f/4 肩并肩+稳定 | war-history | comrade framing, shared warmth | loyalty, shoulder-to-shoulder, warm side light, 35mm, tavern warmth, 9:16 |
| 野心 | 权力渴求者 | breathing: deep, eye: intense, jaw: clenched, control: masked | 低角度+火光, 圣殿金光+500T | 85mm f/2.8 MCU+慢推+仰拍 | crime-thriller | power in eyes, slow confident push | ambition, low angle close, fire in eyes, 85mm, cathedral gold, 9:16 |
| 悔恨 | 退缩者 | breathing: ragged, eye: avoidant, delay: slow, residue: scar | 渐远光+灰, 荒原灰+500T | 50mm f/4 慢拉远+空间扩大 | european-masters | slow dolly out, space grows | regret, slow retreat, widening space, wasteland grey, 50mm, 9:16 |
| 狂热 | 旋转者 | breathing: rapid, eye: wide/ecstatic, control: failing | 手持+火金+饱和, 战火红+800T | 24mm f/2.8 手持旋转+环绕 | action-martial | ecstatic handheld, spinning, firelit | fanaticism, spinning handheld, fire+gold, saturated, 24mm, 9:16 |
| 虔诚 | 跪拜者 | breathing: slow/ritual, eye: upward/closed, control: surrender | 极低角度+光从上来, 圣殿金光+250D | 24mm f/8 极低角度+锁定 | fantasy-epic | divine light from above, worship composition | devotion, extreme low angle, divine light, 24mm, cathedral gold, 9:16 |
| 嫉妒 | 分裂者 | breathing: shallow, eye: avoidant/darting, jaw: grinding | 分割画面+暖冷分裂, 酒馆暖-诅咒绿 | 50mm f/2.8 偏轴+暖冷分割 | crime-thriller | split composition, warm-cold divide | jealousy, split frame, warm-cold divide, 50mm, tavern-cursed green, 9:16 |
| 绝望 | 空洞者 | breathing: shallow/holding, eye: staring-through, delay: frozen | 去饱和+灰+死黑, 地牢橙+500T | 135mm f/4 MCU+偏置+环境包围 | horror-dark | no warm, no hope, cold only | despair, desaturated, cold grey, crushed blacks, 135mm, dungeon orange, 9:16 |
| 崇拜 | 仰望者 | breathing: slow, eye: upward/glistening, control: surrender | 俯拍+轮廓光+金尘, 圣殿金光+250D | 14mm f/5.6 极低角度+垂直纵深 | fantasy-epic | worship composition, kneeling, divine overhead | worship, kneeling, divine overhead, rim light, 14mm, gold dust, 9:16 |
| 复仇 | 凝视者 | breathing: controlled, eye: locked/cold, jaw: clenched, control: suppressing | 急推+冷+去饱和, 铁与血+500T | 135mm f/2.8 crash zoom+锁定凝视 | action-martial | crash zoom to eyes, hard cut, red burst | vengeance, crash zoom, locked stare, 135mm, iron and blood, 9:16 |
| 顿悟 | 觉醒者 | breathing: held then release, eye: wide/opening, delay: then rush | 同机位+光线变化, 暮色紫->圣殿金 | 同机位+光线变化+表情变化 | fantasy-epic | same frame, light shift, expression change | epiphany, same frame, light change, expression shift, 50mm, 9:16 |

---

## 3. 情绪组合路由(10种复合情绪)

> 短视频最常用的不是单一情绪，而是情绪组合

| 情绪组合 | 主情绪+次情绪 | L(光影策略) | C(镜头策略) | 一句话公式 |
|---------|-------------|-----------|-----------|----------|
| 恐惧+希望 | 暗场景+唯一暖 | candle-only+远处窗光, 诅咒绿+唯一暖 | 35mm推入+暖在画面边缘 | fear+hope, candle in dark, distant warm window, 35mm push-in, 9:16 |
| 愤怒+悲伤 | 血+泪 | 战火红+荒原灰混合 | 85mm MCU+泪与血同框 | anger+sadness, blood and tears, 85mm MCU, warfire+grey, 9:16 |
| 敬畏+恐惧 | 巨物+渺小 | 冰原蓝+暗影 | 14mm EWS+人极小+巨物填空 | awe+fear, colossal creature, human tiny, 14mm EWS, icefield blue, 9:16 |
| 权力+腐败 | 金光+阴影 | 圣殿金+诅咒绿在阴影 | 50mm慢推+光面暖暗面冷 | power+corruption, gold on surface, cursed green in shadows, 50mm slow push, 9:16 |
| 孤独+自由 | 留白+风 | 荒原灰+自然光 | 24mm广角+人远+大天 | loneliness+freedom, vast sky, tiny figure, wind, 24mm, wasteland grey, 9:16 |
| 浪漫+危险 | 暖光+暗角 | 酒馆暖+诅咒绿边缘 | 85mm浅景深+暖心冷边 | romance+danger, warm center cold edge, 85mm shallow DOF, tavern+cursed, 9:16 |
| 魔法+失控 | 发光+变形 | 暮色紫+色彩溢出 | 50mm环绕+速度加快 | magic+chaos, color overflow, physics break, 50mm orbit speed-up, twilight purple, 9:16 |
| 牺牲+崇高 | 暗中唯一暖 | 唯一暖+冰原蓝 | 85mm慢动作+逆光剪影 | sacrifice+sublime, sole warm in cold blue, 85mm slow-mo, backlight, 9:16 |
| 背叛+绝望 | 冷转+黑 | 钠橙转诅咒绿+死黑 | 85mm锁定+色温渐变 | betrayal+despair, sodium orange to cursed green, 85mm locked, color shift, 9:16 |
| 恐惧+好奇 | 暗中窥视 | 极暗+窥视光源 | 50mm偏轴+前景遮挡 | fear+curiosity, peering into dark, off-axis, foreground occlusion, 50mm, 9:16 |

---

## 4. 情绪 -> Seedance模式速查

| 情绪类别 | 推荐模式 | 原因 |
|---------|---------|------|
| 恐惧/窒息/绝望 | Studio | 锁定+高对比+微表情 |
| 敬畏/崇高/崇拜 | Atmospheric | 漂浮+极端调色+氛围沉浸 |
| 孤独/悲伤/失去 | Studio 或 Atmospheric | 锁定长持 或 漂浮沉思 |
| 权力/野心/压迫 | Narrative 或 Studio | 慢推叙事 或 高对比压迫 |
| 魔法/神秘/顿悟 | Performance | 环绕+戏剧调色+魔法展示 |
| 背叛/阴谋/嫉妒 | Narrative 或 Studio | 慢推窃语 或 半脸光 |
| 牺牲/虔诚/崇拜 | Performance 或 Atmospheric | 环绕+金光 或 漂浮+神圣 |
| 愤怒/复仇/狂热 | Action | 手持+去饱和+快速 |
| 浪漫/禁忌/渴望 | Narrative 或 Studio | 慢推柔焦 或 浅景深 |
| 忠诚/悔恨/绝望 | Atmospheric 或 Studio | 漂浮渐远 或 锁定长持 |

---

> v1.0 初版: 10核心+10扩展+10组合情绪路由, 每种情绪6模块完整参数+一句话公式
