# AI提示词到视觉效果映射模式

> 版本: v2.0 | 日期: 2026-06-29
> 类别: AI Prompt Patterns / Prompt-to-Visual Mapping / Expected Results / Failure Fix
> 用途: 把抽象的"我要表达X情绪"翻译为具体的AI提示词+预期视觉效果+常见AI偏差修复
> 关联: prompt-assembly-guide.md(组装流程) / ai-video-tool-prompting.md(工具策略) / 镜头调度与摄影参数提示词速查手册.md(参数参考)

---

## 1. 核心映射模式(10组情绪-完整提示词链)

| 情绪 | 核心提示词 | 预期效果 | AI常见偏差 | 修复 | 焦段+光圈 | 调色板 | 构图 |
|------|-----------|---------|-----------|------|----------|--------|------|
| 恐惧 | candle-only, no fill, extreme dark, cold blue shadow | 深暗+唯一烛光+冷蓝阴影 | 过亮/加填充光 | no fill, crushed blacks, let shadow be real | 50mm f/2.8 | 诅咒绿 | 模糊图底+偏角+暗>亮 |
| 敬畏 | negative space, human 5%, slow build, silence | 人极小+巨物+空间压迫 | 人太大/物太小 | human 5% of frame, creature fills horizon | 14mm f/11 | 冰原蓝 | 极宽+深景深+开放 |
| 孤独 | vast negative space, single figure, cold, wind | 大量留白+一人孤影+冷 | 加温暖/人近 | single figure in vast emptiness, cold isolated | 200mm f/2.8 | 荒原灰 | 偏置+大面积负空间 |
| 愤怒 | handheld close, blood+mud+fire, fast cut, red | 手持+血泥火+快切+红 | 太干净/太稳 | handheld rough, no beautification | 35mm f/4 | 战火红 | 多焦点+碎片构图 |
| 悲伤 | slow motion, silhouette, solo cello, hold 3-5s | 慢动作+剪影+大提琴 | 太快/太短 | hold 3-5 seconds, silence after | 85mm f/1.4 | 荒原灰 | 极近+浅景深+暖柔光 |
| 神秘 | fog, volumetric, low light, cold blue | 雾+体积光+暗+冷蓝 | 太亮/太清 | no bright, fog density, let fog hide | 50mm f/2.8 | 暮色紫 | 偏轴+柔焦+部分遮挡 |
| 浪漫 | golden hour, soft focus, warm-cold split | 金光+柔焦+暖冷分裂 | 太直白 | longing not touching, step-printing | 85mm f/2.0 | 酒馆暖 | 极近+浅景深+暖柔光 |
| 权力 | low angle, backlight, slow push, symmetry | 仰拍+逆光+慢推+对称 | 太随意 | centered, no handheld, locked | 35mm f/4 | 圣殿金光 | 中心仰拍对称 |
| 绝望 | desaturated, cold grey, crushed blacks | 去饱和+灰+死黑 | 加暖/加希望 | no warm, no hope color, cold only | 135mm f/4 | 地牢橙 | 偏置+环境包围+窄框 |
| 魔法 | ethereal glow, impossible light, particles | 虚光+不可能光+粒子 | 光源不一致 | consistent light source, illuminates face | 28mm f/2.8 | 暮色紫 | 打破构图+新元素进入 |

---

## 2. 扩展映射(10组次级情绪)

| 情绪 | 核心提示词 | 预期效果 | AI常见偏差 | 修复 | 焦段+光圈 | 调色板 | 构图 |
|------|-----------|---------|-----------|------|----------|--------|------|
| 忠诚 | steady cam, shoulder-to-shoulder, warm side | 稳定+并肩+暖侧光 | 太孤立 | comrade framing, shared warmth, side by side | 35mm f/4 | 酒馆暖 | 对称+并肩 |
| 背叛 | over-shoulder whisper, cold shift, shadow face | 过肩低语+光转冷+影子脸 | 太明显 | subtle cold shift, shadow creeps across face | 85mm f/2.0 | 诅咒绿-荒原灰 | 偏轴+遮挡 |
| 野心 | low angle close, fire eyes, slow push | 仰拍特写+眼中火+慢推 | 太弱 | power in eyes, slow confident push, dominant | 85mm f/2.8 | 圣殿金光 | 中心仰拍 |
| 悔恨 | slow retreat, widen out, silence, grey | 慢拉远+空间扩大+沉默+灰 | 太快/太暖 | slow dolly out, space grows, no warm | 50mm f/4 | 荒原灰 | 渐远+负空间渐增 |
| 狂热 | handheld whirl, fire+gold, fast orbit, saturated | 手持旋转+火金+快环绕+饱和 | 太冷静 | ecstatic handheld, spinning, firelit, saturated | 24mm f/2.8 | 战火红 | 中心+旋转 |
| 虔诚 | extreme low angle, light from above, stone | 极低角度+光从上来+石 | 太世俗 | divine light source above, looking up, sacred | 24mm f/8 | 圣殿金光 | 崇拜构图 |
| 嫉妒 | split frame, two subjects, warm-cold divide | 分割画面+两人+暖冷分裂 | 太统一 | split composition, one warm one cold, envy | 50mm f/2.8 | 酒馆暖-诅咒绿 | 对称破缺+暖冷分裂 |
| 牺牲 | slow motion, backlit, single warm in cold | 慢动作+逆光+冷中一点暖 | 太华丽 | humble sacrifice, no glorification, just warmth in cold | 85mm f/2.0 | 冰原蓝+唯一暖点 | 孤独+唯一暖 |
| 崇拜 | kneeling, overhead, rim light, gold dust | 跪拜+俯拍+轮廓光+金尘 | 太随意 | worship composition, kneeling subject, divine overhead | 14mm f/5.6 | 圣殿金光 | 极低角度+垂直纵深 |
| 复仇 | crash zoom, red flash, locked stare, hard cut | 急推+红闪+锁定凝视+硬切 | 太柔和 | vengeance, crash zoom to eyes, hard cut, red burst | 135mm f/2.8 | 铁与血 | 逼视+压缩 |
﻿
---

## 3. 场景-情绪-提示词完整链(20个中世纪西幻核心场景)

### 3.1 战斗与冲突类

| 场景 | 情绪 | 导演签名 | 完整提示词链 | AI关键陷阱 | 修复方案 |
|------|------|---------|-------------|-----------|---------|
| 骑士冲锋 | 悲壮/崇高 | Kubrick+Deakins | 35mm f/4 low angle, Kubrick symmetry, Deakins single key, iron and blood palette, cavalry charge, slow push-in, dust and blood, crushed blacks | 马匹运动不自然/过亮 | real horse weight, grounded hooves, extreme dark, no fill |
| 围城战 | 恐惧/渺小 | Eggers | 21mm f/8 deep focus, Eggers austere, castle walls towering, tiny figures, icefield blue palette, locked camera, overwhelming architecture | 人太小看不清 | human 5% but readable silhouette, rim light on figures |
| 近身格斗 | 愤怒/绝望 | Evans/Raid | 28mm f/2.8 handheld, corridor纵深, fluorescent flicker, dungeon orange palette, tight framing, claustrophobic, blood and sweat | 打斗太干净 | dirt on face, sweat, blood spatter, handheld rough, no beautification |
| 龙焰降临 | 敬畏/恐惧 | Villeneuve | 14mm f/8 extreme wide, Villeneuve slow reveal, dragon fills sky, warfire red palette, human 3% of frame, impossible scale, volumetric fire | 龙太小/人太大 | dragon fills horizon, human 3%, overwhelming scale |
| 战场沉默 | 悲伤/虚无 | Malick | 50mm f/4 static, Malick contemplative, battlefield aftermath, wasteland grey palette, hold 5+ seconds, wind only, no music | 太短/加音乐 | hold 5+ seconds, wind only, no score, let silence breathe |

### 3.2 权力与阴谋类

| 场景 | 情绪 | 导演签名 | 完整提示词链 | AI关键陷阱 | 修复方案 |
|------|------|---------|-------------|-----------|---------|
| 王座加冕 | 权力/庄严 | Nolan+van Hoytema | 24mm f/8 IMAX wide, Nolan cold-warm split, van Hoytema divine backlight, cathedral gold palette, centered low angle, crown catching light, symmetrical | 太暗/不对称 | centered symmetry, divine backlight on crown, gold catchlight |
| 暗杀密谋 | 阴谋/不安 | Fincher+Khondji | 50mm f/2.8 selective focus, Fincher desaturated, Khondji sodium orange, dungeon orange palette, shadow faces, whispered words, no fill | 面部太亮 | shadow on faces, no fill, let darkness hide, candle only |
| 审判宣判 | 压迫/宿命 | Kubrick | 35mm f/4 symmetrical, Kubrick corridor, locked camera, two-point perspective, iron and blood palette, judge high above, accused small below | 角度不对/太温暖 | strict symmetry, low angle on judge, high angle on accused, cold |
| 宫廷宴会 | 虚伪/欲望 | Kubrick+Zhao | 28mm f/2.8 Steadicam drift, warm surface cold undertow, tavern warmth palette on faces, cursed green in shadows, false warmth, slow orbit | 只有暖色 | warm on surface, cold green undertow in shadows, false warmth |
| 权力交接 | 命运/沉重 | Lean+Deakins | 35mm f/5.6 slow push, Lean epic framing, Deakins Rembrandt light, cathedral gold palette fading to wasteland grey, crown passed, light dims | 太快/太轻 | slow deliberate push, weight of crown, light dimming, no rush |

### 3.3 旅途与探索类

| 场景 | 情绪 | 导演签名 | 完整提示词链 | AI关键陷阱 | 修复方案 |
|------|------|---------|-------------|-----------|---------|
| 踏上旅途 | 自由/未知 | Jackson+Lubezki | 24mm f/8 deep focus, Jackson epic establish, Lubezki golden hour, elvish silver palette, vast landscape, figure on horizon, natural wind | 景观太假/人太大 | real landscape scale, figure on horizon line, natural atmosphere |
| 进入地下城 | 恐惧/不安 | Eggers | 21mm f/4, entering unknown, Eggers single candle, dungeon orange palette, darkness swallowing, slow push into black, no fill | 太亮/光源太多 | single candle only, darkness ahead, no fill, let black be black |
| 森林迷路 | 神秘/迷失 | del Toro | 35mm f/2.8, del Toro atmosphere, fog between trees, cursed green palette, volumetric shafts, disoriented, no clear path | 太清/路径太明显 | dense fog, no clear path, let fog hide the way, mysterious |
| 攀登高峰 | 意志/崇高 | Tarkovsky | 28mm f/8, Tarkovsky contemplative, icefield blue palette, figure against mountain, natural elements, wind snow, long take, slow ascent | 太快/太戏剧 | contemplative pace, no dramatic music, wind and breathing only |
| 废墟发现 | 敬畏/哀伤 | Villeneuve+Deakins | 35mm f/5.6, Villeneuve slow reveal, Deakins Rembrandt, ancient parchment palette, ruins emerge from fog, history preserved, silence | 废墟太新 | weathered stone, moss, time-worn, ancient texture, patina |

### 3.4 超自然与魔法类

| 场景 | 情绪 | 导演签名 | 完整提示词链 | AI关键陷阱 | 修复方案 |
|------|------|---------|-------------|-----------|---------|
| 魔法觉醒 | 敬畏/神秘 | Villeneuve | 85mm f/2.0 orbit, Villeneuve slow orbit, twilight purple palette, ethereal glow from hands, particles rising, impossible light, face illuminated by magic | 光源不一致/太闪 | consistent magic light source, illuminates face, particles follow physics |
| 诅咒显现 | 恐惧/腐败 | del Toro | 50mm f/2.8 handheld, del Toro biological horror, cursed green palette, skin darkening, veins visible, corruption spreading, no beautification | 太干净/太美 | real skin deterioration, veins, sickly color, no beautification |
| 预言/幻象 | 混乱/超现实 | Lynch | 14mm f/2.8, Lynch surreal, dutch angle 30deg, twilight purple palette, fractured vision, multiple realities, step-printing, distorted | 太清晰/太连贯 | dream logic, fractured, step-printing, disorienting, non-linear |
| 精灵领地 | 超脱/永恒 | Tarkovsky+Lubezki | 28mm f/4 floating, Tarkovsky long take, Lubezki natural light, elvish silver palette, light through canopy, time slowed, particles, silence | 太像人间 | otherworldly, time flows differently, silver light, not human pace |
| 亡灵出现 | 恐惧/悲伤 | Eggers | 50mm f/2.8 locked, Eggers austere, moonlit blue palette, figure in mist, is it real, hold on uncertainty, no jump scare | 太恐怖/跳吓 | subtle presence, is it real, hold on ambiguity, no jump scare |

### 3.5 人物与情感类

| 场景 | 情绪 | 导演签名 | 完整提示词链 | AI关键陷阱 | 修复方案 |
|------|------|---------|-------------|-----------|---------|
| 告别 | 悲伤/不舍 | Wong Kar-wai | 85mm f/1.4, Doyle step-printing, warm-cold split, one stays one leaves, tavern warmth on one, wasteland grey on other, longing not touching | 太快/太直接 | step-printing, longing gaze, not touching, hold the pain |
| 誓言 | 忠诚/庄严 | Lean | 35mm f/5.6, Lean epic framing, cathedral gold palette, two figures, sword raised, oath in firelight, slow push, sacred weight | 太随意 | ritual solemnity, slow push, sacred firelight, weight of oath |
| 背叛揭露 | 震惊/愤怒 | Fincher | 50mm f/2.8 crash zoom, Fincher cold, progressive close-in, face realizing truth, desaturated, cold realization, hard cut to reaction | 太温和 | crash zoom to eyes, cold realization, hard cut, no soft landing |
| 独自疗伤 | 孤独/坚韧 | Malick | 85mm f/2.0, Malick contemplative, single figure, wasteland grey palette, tending wound in silence, natural light, shallow DOF on wound | 太快/有人来 | alone, no one comes, silence, wound tending, hold the solitude |
| 父子传承 | 温暖/沉重 | Jackson | 50mm f/2.8, Jackson intimate, tavern warmth palette, sword passed hand to hand, firelight on faces, shallow DOF, emotional close-up | 太冷/太快 | firelight warmth, hands on sword, weight of legacy, hold on hands |
﻿
---

## 4. AI工具特定偏差修复(深化版)

### 4.1 Kling常见偏差与修复

| 偏差 | 修复提示词 | 适用场景 | 注意事项 |
|------|-----------|---------|---------|
| 铠甲变塑料 | worn iron patina, brushed steel, real metal reflection, no plastic, oxidized | 骑士/战士 | 每次出现铠甲都要加 |
| 场景过亮 | crushed blacks, extreme dark, let shadow be real, no fill | 暗场景 | 与灯光提示词配合 |
| 人物太美 | no beautification, weathered, scarred, real, dirt on face, pores visible | 战斗/旅途 | 短视频不能太丑，适度 |
| 多余色彩 | desaturated, muted, restrained color, no oversaturation | 调色场景 | 与调色板提示词配合 |
| 运动僵硬 | weight on feet, grounded, gravity affects movement, natural momentum | 动作场景 | 配合运动速度锚定 |
| 面部崩坏 | natural skin texture, real pores, asymmetrical features, no smoothing | 特写 | 配合物理真实感检查 |
| 比例失调 | correct human proportions, anatomically accurate, realistic scale | 全身 | 配合景别提示词 |
| 背景混乱 | one-point perspective, vanishing point, depth recedes, clean background | 建筑内部 | 配合构图提示词 |

### 4.2 Seedance常见偏差与修复

| 偏差 | 修复提示词 | 适用场景 | 注意事项 |
|------|-----------|---------|---------|
| 风格过强 | restrained, subtle, less is more, not theatrical | 所有场景 | Seedance易过度风格化 |
| 面部过清 | natural skin, pores visible, imperfections, real | 特写 | 配合光圈景深 |
| 调色过度 | subtle grade, restrained, realistic color, not stylized | 调色场景 | 调色板提示词前置 |
| 运动过度 | measured movement, controlled pace, not hyperactive | 叙事场景 | 配合帧率提示词 |
| 情绪过火 | subtle emotion, internalized, restraint, not melodramatic | 情感场景 | 配合反应镜头语法 |

### 4.3 Vidu/Wan常见偏差与修复

| 偏差 | 修复提示词 | 适用场景 |
|------|-----------|---------|
| 细节丢失 | sharp details, crisp textures, high resolution | 所有场景 |
| 色彩平淡 | rich color depth, cinematic color, not flat | 调色场景 |
| 运动模糊 | clean motion, no motion blur, steady | 动作场景 |
| 空间混乱 | clear depth layers, foreground-midground-background | 构图场景 |

### 4.4 通用AI偏差修复(黄金10条)

| # | 偏差 | 修复提示词 | 优先级 |
|---|------|-----------|--------|
| 1 | 手指异常 | hands behind back, hands holding sword, hands not visible | 高 |
| 2 | 物理不自然 | weight on feet, grounded, gravity affects movement | 高 |
| 3 | 空间混乱 | one-point perspective, vanishing point, depth recedes | 中 |
| 4 | 光线矛盾 | single light source, directional, cast shadows consistent | 高 |
| 5 | 风格漂移 | consistent style throughout, same director signature, same palette | 高 |
| 6 | 服装穿越 | period-accurate medieval clothing, no modern elements, authentic fabric | 高 |
| 7 | 铠甲材质 | real iron patina, no plastic shine, weathered metal, battle-worn | 高 |
| 8 | 比例异常 | correct human proportions, realistic scale relative to environment | 中 |
| 9 | 时间感错 | consistent time of day, matching shadow direction, coherent light | 中 |
| 10 | 情绪断裂 | maintain emotional arc, consistent mood throughout clip | 高 |

---

## 5. 情绪渐变序列(从A到B的提示词过渡)

| 渐变 | 起始 | 终止 | 焦段变化 | 色温变化 | 调色板变化 | 提示词 |
|------|------|------|---------|---------|-----------|--------|
| 安全-危险 | 酒馆暖 | 诅咒绿 | 28mm-85mm | 3200K-6500K | 酒馆暖-诅咒绿 | tavern warmth fading, cold green creeping in, focal length tightening, warmth dying |
| 希望-绝望 | 精灵银 | 荒原灰 | 24mm-135mm | 4000K-8000K | 精灵银-荒原灰 | elvish silver fading to wasteland grey, hope draining, compression increasing, cold crushing |
| 恐惧-勇气 | 地牢橙 | 铁与血 | 135mm-24mm | 6500K-4500K | 地牢橙-铁与血 | dungeon orange yielding to iron and blood, fear becoming resolve, widening, fire igniting |
| 混乱-平静 | 战火红 | 精灵银 | 24mm-50mm-85mm | 2500K-6500K | 战火红-精灵银 | warfire red settling to elvish silver, chaos to stillness, smoke clearing, silence arriving |
| 孤独-归属 | 荒原灰 | 酒馆暖 | 200mm-28mm | 8000K-3200K | 荒原灰-酒馆暖 | wasteland grey warming to tavern amber, isolation to connection, focal length relaxing, firelight welcoming |
| 权力-虚无 | 圣殿金光 | 荒原灰 | 35mm-200mm | 3200K-8000K | 圣殿金光-荒原灰 | cathedral gold fading to ash grey, power crumbling, compression trapping, gold to dust |

---

## 6. 竖屏9:16适配规则(抖音专用)

### 6.1 横屏-竖屏转换法则

| 横屏要素 | 竖屏适配 | 提示词调整 |
|---------|---------|-----------|
| 左右对称 | 上下对称 | vertical symmetry, top-bottom balance, portrait frame |
| 水平运动 | 垂直运动(升/降) | vertical crane up/down, top-to-bottom reveal, portrait orientation |
| 宽景深三区 | 上中下三层 | foreground top, midground center, background bottom, vertical depth layers |
| 左右OTS | 上下分割/前后景 | vertical split, upper subject lower subject, foreground-background layering |
| 水平线构图 | 垂直线+对角线 | vertical leading lines, diagonal in portrait, no horizontal dominance |
| 环境广角 | 垂直纵深(走廊/塔) | vertical corridor, tower interior, ceiling to floor, portrait depth |

### 6.2 竖屏情绪适配

| 情绪 | 竖屏优势 | 竖屏陷阱 | 提示词 |
|------|---------|---------|--------|
| 权力 | 仰拍天然有力 | 脚下空间不足 | low angle in portrait, figure fills lower 2/3, power above, crown at top |
| 孤独 | 垂直负空间更强 | 水平空间不够 | vast vertical negative space, figure at bottom, sky fills upper 3/4 |
| 压迫 | 天花板+地面双重压 | 感觉太挤 | ceiling pressing down, floor rising up, figure compressed in center |
| 亲密 | 天然聚焦面部 | 环境丢失 | face fills upper 2/3, shallow DOF, intimate portrait framing |
| 敬畏 | 垂直巨物天然震撼 | 人太小看不清 | towering structure above, figure at bottom 1/4, silhouette readable |
﻿
---

## 7. 真实提示词示例(完整可粘贴)

### 7.1 60秒暗黑骑士出征完整提示词序列

**帧1 (0-3s) 钩子: 独眼凝视**
`
85mm f/1.4 ECU, single eye close-up, firelight reflection in pupil, iron and blood palette, no beautification, scarred weathered face, medieval knight, crushed blacks, single candle light source, no fill, shallow DOF
`

**帧2 (3-8s) 揭示: 全身铠甲**
`
35mm f/4 MS, slow dolly out revealing full armor, worn iron patina, brushed steel, battle-worn, no plastic, cathedral gold palette dimming to iron and blood, firelight from behind, rim light on armor edges, centered composition
`

**帧3 (8-15s) 环境: 城堡走廊**
`
28mm f/5.6, walking down stone corridor, Kubrick symmetry, one-point perspective, vaulted ceiling, dungeon orange palette, single torch light, shadows lengthening, steady cam following, medieval stone walls
`

**帧4 (15-25s) 出城: 大门开启**
`
14mm f/8 extreme wide, castle gate opening outward, Eggers austere, icefield blue palette, figure tiny against gate, overwhelming architecture, deep focus, locked camera, natural light from outside, silhouette against white sky
`

**帧5 (25-40s) 旅途: 荒原独行**
`
200mm f/2.8, lone rider on vast wasteland, extreme compression, wasteland grey palette, flattened planes, fatalism, horse weight on hooves, grounded, wind dust, desaturated, hold 5+ seconds
`

**帧6 (40-50s) 遭遇: 敌人出现**
`
50mm f/2.8, dutch angle 15deg, ambiguous figures on ridge, cursed green palette, fog rolling in, volumetric light shafts, tension building, no clear threat yet, hold on uncertainty
`

**帧7 (50-58s) 冲突: 拔剑**
`
85mm f/2.0, hand on sword hilt, shallow DOF, iron and blood palette, firelight on blade, decisive moment, micro-reaction on face, controlled emotion, single muscle twitch
`

**帧8 (58-60s) 悬念: 凝视远方**
`
135mm f/4 MCU, compressed isolation, figure staring into distance, warfire red palette beginning at horizon, twilight purple undertone, inescapable gaze, fatalism, hold 3 seconds, no resolution
`

### 7.2 15秒精灵女王降临极简提示词

`
0-3s: 14mm f/11, vast forest clearing, elvish silver palette, mist, no figure yet, deep focus, Tarkovsky long take, silence
3-8s: 28mm f/4, figure emerging from mist, silver robes, moonlight through canopy, slow floating camera, Lubezki natural light, ethereal particles
8-13s: 85mm f/1.4, face close-up, otherworldly beauty, violet eyes, silver hair, shallow DOF, elvish silver palette, impossible light on face
13-15s: 24mm f/8, she turns and forest responds, leaves rise, light intensifies, magic awakening, deep focus, hold
`

### 7.3 15秒背叛之夜极简提示词

`
0-3s: 50mm f/2.8, two figures by candlelight, tavern warmth palette, intimate, trust, side by side
3-8s: 85mm f/2.0, one whispers, other listens, progressive close-in, warmth still, shadow begins creeping on whisperer face
8-13s: 50mm f/2.8 dutch angle 15deg, revelation, cold shift, cursed green palette bleeding in, candle gutters, shadow face, no fill
13-15s: 135mm f/2.8, compressed isolation, knife revealed, cold realization, dungeon orange palette, hard cut to black
`

### 7.4 15秒围城之战极简提示词

`
0-3s: 14mm f/11, castle walls filling frame, overwhelming scale, human 3% at bottom, icefield blue palette, Eggers locked, silence before storm
3-8s: 35mm f/4, defenders on wall, faces in torchlight, dungeon orange palette, Kubrick symmetry, slow push-in, dread building
8-13s: 85mm f/2.0, commander face, split lighting, half fire half shadow, iron and blood palette, micro-reaction, jaw clenched
13-15s: 21mm f/8, enemy army revealed beyond wall, warfire red palette at horizon, overwhelming, deep focus, hold, no resolution
`

### 7.5 15秒魔法觉醒极简提示词

`
0-3s: 50mm f/2.8, hands trembling, dark room, single candle, dungeon orange palette, fear in eyes, shallow DOF on hands
3-8s: 28mm f/2.8, light begins emanating from palms, twilight purple palette bleeding in, particles rising, face illuminated by own magic, Villeneuve slow orbit
8-13s: 85mm f/1.4, eyes wide with power and terror, shallow DOF, twilight purple palette, ethereal glow, impossible light from within
13-15s: 14mm f/8, room transforms, light explodes outward, particles everywhere, deep focus, magic unleashed, hold
`

---

## 8. 5秒紧急映射(最简版)

恐惧 = candle-only + extreme dark + sole warm + cold blue shadow
敬畏 = negative space + human 5% + silence + slow build
孤独 = vast negative + single figure + cold + wind only
愤怒 = handheld + blood + mud + fast cut + red
悲伤 = slow motion + silhouette + cello + hold 3-5s
神秘 = fog + volumetric + low light + cold blue
浪漫 = golden hour + soft focus + warm cold split
权力 = low angle + backlight + slow push + symmetry
绝望 = desaturated + cold grey + crushed blacks
魔法 = ethereal glow + particles + impossible light
忠诚 = shoulder-to-shoulder + firelight + steady
背叛 = cold shift + shadow face + whisper + knife
野心 = low angle + fire eyes + slow push + gold
悔恨 = slow retreat + widen + silence + grey
狂热 = handheld whirl + fire + saturated + spinning
虔诚 = extreme low angle + light above + stone + sacred
嫉妒 = split frame + warm-cold divide + two subjects
牺牲 = slow motion + backlit + single warm in cold
崇拜 = kneeling + overhead + rim light + gold dust
复仇 = crash zoom + red flash + locked stare + hard cut

---

## 9. 失败诊断流程

### 9.1 视觉效果不对时的诊断路径

结果太亮 -> 检查灯光提示词(是否加了no fill/crushed blacks) -> 修复灯光
结果太美 -> 检查是否有no beautification/weathered/real -> 修复美化偏差
颜色不对 -> 检查调色板提示词(是否指定了palette) -> 添加调色板
构图太满 -> 检查是否有negative space/breathing room -> 添加负空间
运动不自然 -> 检查是否有grounded/weight on feet -> 修复物理锚定
铠甲像塑料 -> 检查是否有worn iron/real metal/no plastic -> 修复材质
风格不一致 -> 检查是否有consistent style/same director signature -> 添加风格锚定
情绪不到位 -> 检查焦段+光圈+构图是否匹配情绪 -> 查本文件1-3节映射表

### 9.2 按工具的诊断优先级

| 工具 | 首先检查 | 其次检查 | 最后检查 |
|------|---------|---------|---------|
| Kling | 铠甲材质/美化偏差 | 灯光/亮度 | 运动物理 |
| Seedance | 风格过度/调色过度 | 面部过度清晰 | 运动过度 |
| Vidu | 细节/分辨率 | 色彩深度 | 运动模糊 |
| Wan | 空间一致性 | 光线逻辑 | 整体质感 |

---

## 10. 与镜头手册的交叉引用速查

| 情绪 | 本文件节 | 镜头手册节 | KB文件 |
|------|---------|-----------|--------|
| 恐惧 | 1节(核心映射) | 9(情绪速查)+27(镜头心理)+30(构图情绪) | horror-dark-directors |
| 敬畏 | 1节+2节 | 21(构图心理)+27(镜头心理) | fantasy-epic-directors |
| 孤独 | 1节+2节 | 30(构图情绪) | european-masters |
| 权力 | 1节+2节 | 28(对切语法)+29(调色叙事) | crime-thriller-directors |
| 魔法 | 1节 | 27(镜头心理)+29(调色叙事) | fantasy-epic-directors |
| 背叛 | 2节 | 28(反应镜头)+29(色彩冲突) | crime-noir-urban |
| 牺牲 | 2节 | 27(光圈情绪)+30(前景层) | war-history-drama |
| 悲伤 | 1节 | 27(光圈情绪)+28(沉默叙事) | european-masters |
| 愤怒 | 1节 | 27(焦段序列)+30(构图公式) | action-martial |
| 神秘 | 1节 | 29(调色叙事)+30(框中框) | surrealism-dream-cinema |
| 浪漫 | 1节 | 27(光圈情绪)+30(构图公式) | arthouse-female-animation |
| 绝望 | 1节 | 29(色温曲线)+30(空间隐喻) | psychological-body-horror |
| 忠诚 | 2节 | 28(对切语法)+30(前景层) | war-history-drama |
| 复仇 | 2节 | 27(焦段序列)+29(调色叙事) | korean-cinema-deepdive |
| 崇拜 | 2节 | 27(焦段心理)+30(框中框) | fantasy-epic-directors |

---

> v2.0 更新: 从3.6KB扩充至完整版。新增: 10组次级情绪映射 + 20个核心场景完整提示词链(5大类) + 情绪渐变序列(6组A到B过渡) + 竖屏9:16适配规则 + 5个真实完整可粘贴提示词示例(60秒x1+15秒x4) + 失败诊断流程图 + 镜头手册交叉引用速查(15种情绪) + AI工具偏差修复深化(4个工具+黄金10条)