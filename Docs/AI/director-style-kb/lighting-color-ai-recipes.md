# 灯光与调色AI工具实战配方

> 类别: Lighting Recipes / Color Grading Recipes / AI Tool Practical / Step-by-Step
> 版本: v2.0 (深化版)
> 用途: 20种中世纪西幻灯光设置+20种调色方案的AI提示词实战配方+AI工具特定参数+常见问题修复+组合速配
> 关联: lighting-design-signatures.md(8位灯光师) / colorist-signature-grade.md(10位调色师) / 镜头调度手册(13+29节)

---

## 1. 20种中世纪西幻灯光配方

### 1.1 单烛光(恐惧/地牢/密谋)

| 参数 | 值 | 提示词 |
|------|------|--------|
| 主光 | 单烛光(3200K) | single candle key light, 3200K warm point source, no fill |
| 补光 | 无 | absolutely no fill, no ambient, let shadow be real |
| 背光 | 无 | no backlight, no rim, pure shadow |
| 环境 | 极暗 | crushed blacks, extreme dark, shadow dominant |
| 效果 | 一半脸亮一半暗+深阴影 | half-face chiaroscuro, deep shadow, fear lighting |
| AI修复 | 防止自动补光 | no fill light, no ambient lift, no auto-bright, let dark be dark |

完整提示词: candle-only lighting, single 3200K point source, no fill, crushed blacks, half-face chiaroscuro, fear, dungeon orange palette, Eggers/Khondji, 9:16

### 1.2 壁炉主光(温暖/家/酒馆)

| 参数 | 值 | 提示词 |
|------|------|--------|
| 主光 | 壁炉火光(2800K) | fireplace key light, 2800K warm broad source, flickering |
| 补光 | 极弱烛光 | minimal candle fill, just enough to see, not bright |
| 背光 | 无 | no backlight, fire is the only source |
| 环境 | 暖暗 | warm dark, tavern atmosphere, fire dominant |
| 效果 | 暖光笼罩+影子柔和+安全 | warm embrace, soft shadows, safety in firelight |

完整提示词: fireplace key, 2800K warm broad, flickering, minimal candle fill, warm dark, tavern warmth palette, Jackson intimate, 9:16

### 1.3 逆光轮廓(权力/神圣/威严)

| 参数 | 值 | 提示词 |
|------|------|--------|
| 主光 | 背后强光 | strong backlight, rim light, silhouette definition, divine outline |
| 补光 | 极弱正面 | minimal front fill, face barely visible, mystery in shadow |
| 背光 | 主光 | backlight is key, rim defines form, light from behind |
| 环境 | 暗背景 | dark background, rim pops against black, power silhouette |
| 效果 | 轮廓发光+面部暗=权力 | rim glow, face in shadow=power, divine backlight, Nolan/van Hoytema |

完整提示词: strong backlight rim light, silhouette definition, minimal front fill, dark background, rim pops, power silhouette, cathedral gold palette, Nolan, 9:16

### 1.4 伦勃朗光(肖像/尊严/深度)

| 参数 | 值 | 提示词 |
|------|------|--------|
| 主光 | 45度侧上光 | Rembrandt lighting, 45-degree side-top key, triangle on cheek |
| 补光 | 极弱 | minimal fill, shadow preserved, depth maintained |
| 背光 | 轮廓光 | subtle rim, separation from background, edge definition |
| 效果 | 三角光斑+深影+立体 | Rembrandt triangle, deep shadow, 3D modeling, Deakins portrait |

完整提示词: Rembrandt lighting, 45-degree side-top key, triangle on cheek, minimal fill, subtle rim, Deakins portrait, 85mm f/2.0, 9:16

### 1.5 自然光(旅途/自由/救赎)

| 参数 | 值 | 提示词 |
|------|------|--------|
| 主光 | 太阳/天空 | natural light only, sun or sky, no artificial, Lubezki natural |
| 补光 | 天空散射 | sky fill, open shade, natural ambient |
| 背光 | 太阳逆光(黄金时段) | golden hour backlight, sun behind subject, rim of gold |
| 效果 | 自然+温暖+自由 | natural warmth, golden rim, freedom in landscape, Malick/Lubezki |

完整提示词: natural light only, golden hour, sun behind subject, golden rim, sky fill, Lubezki natural, 24mm f/8, elvish silver palette, 9:16

### 1.6 底光(恐怖/超自然/不安)

| 参数 | 值 | 提示词 |
|------|------|--------|
| 主光 | 从下方照射 | underlighting, light from below, unnatural source, horror |
| 补光 | 无 | no fill, underlight only, shadows go up |
| 效果 | 影子向上+不自然+恐怖 | shadows cast upward, unnatural, uncanny, horror lighting, Burton/Lynch |

完整提示词: underlighting, light from below, shadows cast upward, unnatural, uncanny, horror, no fill, Burton/Lynch, 50mm f/2.8, 9:16

### 1.7 双烛对光(审讯/对峙)

| 参数 | 值 | 提示词 |
|------|------|--------|
| 主光 | 左侧烛光 | left candle key, 3200K, warm point source from left |
| 补光 | 右侧烛光(更弱) | right candle fill, weaker, 3200K, opposing warm source |
| 效果 | 双光源分裂面部=对峙 | dual source split face, two truths, interrogation, moral divide |

完整提示词: dual candle lighting, two warm point sources opposing, split face shadow, interrogation, moral divide, Fincher-grade, 9:16

### 1.8 唯一窗口光(囚室/希望)

| 参数 | 值 | 提示词 |
|------|------|--------|
| 主光 | 单侧窗口光 | single window light from side, beam of hope, directional shaft |
| 补光 | 无(暗面极暗) | no fill, dark side crushed, hope vs despair |
| 效果 | 一束光=希望+大面积暗=囚禁 | single light shaft, hope in imprisonment, contrast extreme, Deakins window |

完整提示词: single window light shaft, directional beam from side, no fill, extreme contrast, hope in imprisonment, Deakins window, 9:16

### 1.9 火+月混合(夜战/魔法)

| 参数 | 值 | 提示词 |
|------|------|--------|
| 主光 | 火光暖(左/下) | fire key light warm, 2800K, from left/below, flickering |
| 补光 | 月光冷(右/上) | moonlight fill cold, 6500K, from right/above, steady |
| 效果 | 暖冷分裂=战斗中的魔法 | warm-cold split, fire vs moon, battle night, magic fire vs natural cold |

完整提示词: fire+moonlight dual source, warm 2800K left fire, cold 6500K right moon, battle night, warm-cold split, 9:16

### 1.10 雾中体积光(神秘/森林)

| 参数 | 值 | 提示词 |
|------|------|--------|
| 主光 | 穿过雾的光束 | volumetric light shafts through fog, god rays, mist atmosphere |
| 补光 | 雾散射 | fog scatter fill, diffuse, soft, no hard shadow |
| 效果 | 体积光+神秘+不可知 | volumetric mystery, light in mist, del Toro atmosphere, forest unknown |

完整提示词: volumetric fog, light shafts through mist, god rays, del Toro atmosphere, forest mystery, diffuse fill, 9:16

### 1.11 过曝白光(天堂/死亡/升华)

| 参数 | 值 | 提示词 |
|------|------|--------|
| 主光 | 极强正面光 | extreme front overexposure, blown highlights, ethereal white |
| 补光 | 无需 | overexposed, no shadow needed, all light |
| 效果 | 白光=超越=死亡即解脱 | overexposed white, heaven, death as light, ascension, Tarkovsky |

完整提示词: overexposed white, ethereal, heaven, death as light, ascension, blown highlights, no shadow, Tarkovsky-grade, 9:16

### 1.12 荧光闪烁(地下/不安)

| 参数 | 值 | 提示词 |
|------|------|--------|
| 主光 | 不稳定荧光 | fluorescent flicker, unstable, industrial, underground, anxiety |
| 补光 | 无 | no fill, flickering only, unstable light = unstable mind |
| 效果 | 闪烁=焦虑=不可靠现实 | flickering light, unreliable reality, anxiety, industrial dread |

完整提示词: fluorescent flicker, underground, unstable light, anxiety, industrial, flickering key, 9:16

### 1.13-1.20 更多灯光配方速查

| 编号 | 灯光配方 | 场景 | 核心提示词 |
|------|---------|------|-----------|
| 1.13 | 拱顶散射光 | 大教堂/神圣空间 | cathedral vault light, diffused from above, sacred scatter, stone reflection, divine atmosphere |
| 1.14 | 火把走廊光 | 地牢走廊/密道 | torch-lit corridor, warm point sources along walls, deep shadow between, dungeon progression |
| 1.15 | 魔法光源(手持) | 施法/魔法场景 | hand-held magic light source, palm glow, twilight purple emanating from hands, no natural source |
| 1.16 | 雨中反光 | 夜雨/悲伤 | rain-wet reflection, neon/fire on wet ground, rain drop close-up, reflection as reality |
| 1.17 | 烟雾体积光 | 仪式/焚烧 | smoke volume light, incense fog, ritual haze, visible light beams in smoke, ceremonial |
| 1.18 | 镜面反射光 | 魔法/双重 | mirror-reflected light, bouncing light off polished surface, double light, duality |
| 1.19 | 极光/魔法天空 | 北境/精灵国度 | aurora borealis sky, magical light from above, elvish silver+green, otherworldly atmosphere |
| 1.20 | 无光源(纯暗) | 黑暗/虚无/死亡 | absolute darkness, no visible light source, eyes adjusting, pure black, void, death |

---

## 2. 20种调色方案AI配方

### 2.1 铁与血(战场/残酷)

| 步骤 | DaVinci概念 | AI提示词 |
|------|------------|---------|
| 基础 | 去饱和-30% | desaturated base, muted, restrained |
| 暗部 | 压黑+冷蓝偏移 | crushed blacks, cold blue shadow shift, deep iron grey |
| 中间调 | 铁灰+微红 | iron grey midtones, subtle blood red in mids |
| 高光 | 唯一暖=火/血 | sole warm highlights=fire or blood, everything else cold |
| 对比 | 高对比 | high contrast, stark, no softness, war-torn |

完整提示词: iron and blood palette, desaturated, crushed blacks with cold blue shadow shift, iron grey midtones, sole warm highlights=fire/blood, high contrast, Kubrick/Deakins war, 9:16

### 2.2 圣殿金光(权力/神圣)

| 步骤 | AI提示词 |
|------|---------|
| 基础 | warm base, golden undertone throughout |
| 暗部 | dark with gold reflection, not pure black, warm shadow |
| 中间调 | amber midtones, stone+gold, sacred weight |
| 高光 | divine gold highlights, crown catches light, divine rim |
| 对比 | moderate contrast, not harsh, sacred dignity |

完整提示词: cathedral gold palette, golden undertone, warm shadow with gold reflection, amber midtones, divine gold highlights, crown light, Nolan/van Hoytema sacred, 9:16

### 2.3-2.12 调色方案速查

| 调色板 | 基调 | 暗部 | 中间调 | 高光 | 完整提示词 |
|--------|------|------|--------|------|-----------|
| 诅咒绿 | 去饱和 | 深绿偏移 | 病绿+黄褐 | 偶尔暖 | cursed green, sickly chartreuse midtones, jaundice brown, deep green shadow shift, del Toro corruption |
| 冰原蓝 | 冷 | 纯蓝偏移 | 冰蓝+白 | 银白 | icefield blue, glacial blue midtones, white silver highlights, deep blue shadow, Eggers frozen |
| 暮色紫 | 冷暖混合 | 深紫偏移 | 暗金+酒红 | 靛蓝 | twilight purple, deep amethyst shadow, dark gold+wine red mids, indigo highlights, Villeneuve arcane |
| 酒馆暖 | 暖 | 暖棕暗部 | 琥珀+焦橙 | 烛黄 | tavern warmth, amber midtones, burnt orange, candlelight yellow highlights, Jackson hearth |
| 地牢橙 | 冷暖分裂 | 钠灯橙暗部 | 黑+暗褐 | 铁锈 | dungeon orange, sodium orange shadow, black+dark umber mids, rust highlights, Khondji oppression |
| 精灵银 | 冷 | 银蓝暗部 | 雾蓝+翠绿 | 淡紫 | elvish silver, moonlight silver highlights, mist blue+emerald mids, pale violet accent, Lubezki otherworldly |
| 战火红 | 暖 | 烟灰暗部 | 火红+焦黑 | 橙 | warfire red, blazing red midtones, smoke grey shadow, charred black, ember orange highlights, Gibson destruction |
| 古卷褐 | 暖 | 墨棕暗部 | 羊皮纸 | 锈金 | ancient parchment, vellum midtones, ink brown shadow, tarnished gold highlights, old knowledge |
| 荒原灰 | 冷 | 灰暗部 | 褐+天光白 | 暗棕 | wasteland grey, ash grey base, umber mids, sky white, dark brown highlights, Hillcoat desolation |
| 月光蓝 | 冷 | 冷蓝暗部 | 银+黑 | 淡紫 | moonlit blue, cold cerulean, silver midtones, black, pale violet highlights, nocturnal mystery |

### 2.13-2.20 新增调色方案

| 调色板 | 基调 | 暗部 | 中间调 | 高光 | 完整提示词 |
|--------|------|------|--------|------|-----------|
| 龙焰橙 | 极暖 | 纯黑+烟 | 熔岩橙+硫黄黄 | 白热 | dragonfire orange, lava orange midtones, sulfur yellow, white-hot highlights, pure black+smoke shadow, apocalyptic |
| 亡灵绿蓝 | 冷+不自然 | 死灰绿 | 尸蓝+霉菌绿 | 唯一冷白 | undead green-blue, corpse blue midtones, mold green, dead grey-green shadow, sole cold white highlights, necromantic |
| 皇家紫金 | 暖+权威 | 深紫+黑 | 皇家紫+金丝 | 金紫混合 | royal purple-gold, deep amethyst+black shadow, royal purple+gold thread midtones, gold-purple blend highlights, sovereignty |
| 森林深翠 | 自然+神秘 | 深绿+黑 | 翠绿+棕 | 穿叶光斑 | deep forest emerald, deep green+black shadow, emerald+brown mids, dappled light through leaves highlights, sylvan mystery |
| 雪原白蓝 | 极冷 | 冰蓝+黑 | 白+淡蓝 | 钻石白 | snowfield white-blue, ice blue+black shadow, white+pale blue mids, diamond white highlights, arctic desolation |
| 血月红 | 不祥+预兆 | 黑+深红 | 暗红+铜 | 血红 | blood moon red, black+deep red shadow, dark red+copper mids, blood red highlights, omen+doom |
| 铸造橙铁 | 工业+粗粝 | 黑+碳 | 橙铁+火花 | 白热金属 | forge orange-iron, black+carbon shadow, orange iron+spark mids, white-hot metal highlights, industrial medieval |
| 迷雾银灰 | 不确定+过渡 | 灰+暗 | 银灰+雾白 | 柔散白 | mist silver-grey, grey+dark shadow, silver grey+fog white mids, soft diffused white highlights, liminal uncertainty |

---

## 3. AI工具灯光/调色特定参数

### 3.1 Kling 3.0灯光参数

| 参数 | 格式 | 示例 | 说明 |
|------|------|------|------|
| 光源方向 | light from [direction] | light from left, camera right | Kling理解方向描述 |
| 光源类型 | [type] light | candle light, fireplace light, moonlight | Kling支持自然光源描述 |
| 光源强度 | [intensity] lighting | dim lighting, harsh lighting, soft lighting | 用程度词描述 |
| 阴影描述 | shadows [quality] | deep shadows, soft shadows, no shadows | 直接描述阴影特性 |
| 时间段 | [time of day] | golden hour, blue hour, midnight, dawn | Kling理解时间光 |
| 天气光 | [weather] light | overcast light, rainy diffused, foggy scatter | 天气影响光线 |

### 3.2 Seedance 2.0灯光参数

| 参数 | 格式 | 示例 | 说明 |
|------|------|------|------|
| 电影模式 | cinematic mode | cinematic lighting, movie-grade | Seedance电影模式 |
| 情绪光 | [emotion] lighting | melancholy lighting, fearful lighting | Seedance支持情绪驱动光 |
| 光比 | [ratio] contrast | high contrast chiaroscuro, low contrast flat | 描述光比 |
| 色温 | [temperature] tone | warm tone, cool tone, mixed temperature | 冷暖描述 |
| 体积效果 | volumetric [effect] | volumetric fog, volumetric dust, god rays | 大气效果 |

### 3.3 Wan 2.2灯光参数

| 参数 | 格式 | 示例 | 说明 |
|------|------|------|------|
| 中文光源 | 中文描述光源 | 单烛光/壁炉光/月光 | Wan中文友好 |
| 光影关系 | 中文描述 | 半脸光/全脸亮/逆光剪影 | 直觉描述 |
| 环境光 | 环境描述 | 极暗环境/自然散射/雾中光 | 环境驱动 |

### 3.4 调色关键词对照(AI通用)

| 调色概念 | AI提示词关键词 | 效果 |
|---------|--------------|------|
| 去饱和 | desaturated, muted, restrained, low saturation | 降低色彩纯度=严肃/压抑 |
| 冷蓝偏移 | cold blue shift, cool shadow, blue undertone | 暗部偏蓝=冷/恐惧/疏离 |
| 暖黄偏移 | warm yellow shift, golden undertone, amber base | 整体偏暖=安全/怀旧/权力 |
| 压黑 | crushed blacks, deep shadow, true black | 暗部极深=戏剧性/恐怖 |
| 高对比 | high contrast, stark, punchy | 强对比=冲突/暴力 |
| 低对比 | low contrast, flat, washed out | 弱对比=日常/记忆/疲倦 |
| 柔散 | soft diffusion, glowing highlights, halation | 高光柔散=梦幻/回忆/天堂 |
| 颗粒 | film grain, texture, organic | 胶片颗粒=质感/年代/真实 |
| 褪色 | faded, bleach bypass, cross-processed | 褪色=时间/创伤/异化 |

---

## 4. 灯光+调色组合速配(12组最强)

| 组合名 | 灯光 | 调色 | 完整提示词 | 适用场景 |
|--------|------|------|-----------|---------|
| 地牢恐惧 | 单烛光 | 地牢橙 | candle-only lighting, single 3200K point source, no fill, dungeon orange palette, crushed blacks, Khondji, 9:16 | 地牢/密室/审讯 |
| 酒馆温暖 | 壁炉主光 | 酒馆暖 | fireplace key 2800K, minimal candle fill, tavern warmth palette, amber midtones, Jackson hearth, 9:16 | 酒馆/家/安全 |
| 王座权力 | 逆光轮廓 | 圣殿金光 | strong backlight rim light, silhouette, minimal front fill, cathedral gold palette, Nolan/van Hoytema, 9:16 | 王座/加冕/神圣 |
| 战场残酷 | 火+月混合 | 铁与血 | fire+moonlight dual source, warm-cold split, iron and blood palette, desaturated, Kubrick/Deakins war, 9:16 | 战斗/战争/死亡 |
| 森林神秘 | 雾中体积光 | 森林深翠 | volumetric fog light shafts, deep forest emerald palette, dappled light, del Toro atmosphere, 9:16 | 森林/精灵/神秘 |
| 冰原绝望 | 自然冷光 | 冰原蓝 | cold natural overcast light, icefield blue palette, glacial, Eggers frozen, no warm source, 9:16 | 北境/绝望/生存 |
| 魔法觉醒 | 魔法手持光 | 暮色紫 | hand-held magic light, palm glow, twilight purple palette, Villeneuve arcane, supernatural, 9:16 | 施法/魔法/觉醒 |
| 诅咒蔓延 | 单烛光+绿渗 | 诅咒绿 | candle key, cursed green bleeding in from edges, sickly chartreuse, del Toro corruption, 9:16 | 诅咒/腐化/变异 |
| 告别黄昏 | 自然逆光 | 荒原灰+酒馆暖渐变 | golden hour backlight fading, wasteland grey bleeding in, warm-to-cold dissolve, Doyle step-print, 9:16 | 告别/离去/失去 |
| 亡灵恐怖 | 无光源+闪烁 | 亡灵绿蓝 | absolute darkness, fluorescent flicker, undead green-blue palette, corpse blue, necromantic, 9:16 | 亡灵/墓地/恐怖 |
| 龙焰末日 | 龙+火光 | 龙焰橙 | dragonfire light, extreme warm, lava orange palette, white-hot highlights, apocalyptic, 9:16 | 龙/末日/灾难 |
| 月夜孤独 | 月光+雨 | 月光蓝 | moonlight through rain, cold cerulean, moonlit blue palette, silver midtones, nocturnal isolation, 9:16 | 月夜/孤独/秘密 |

---

## 5. AI视频灯光/调色常见问题修复(20条)

| 问题 | 原因 | 修复提示词 |
|------|------|-----------|
| 场景太亮 | AI自动补光 | no fill light, no ambient, crushed blacks, let shadow be real, extreme dark |
| 色彩太饱和 | AI自动增色 | desaturated, muted, restrained color, no oversaturation, subtle grade |
| 铠甲塑料感 | AI材质错误 | worn iron patina, real metal, oxidized, no plastic, no gloss, brushed steel |
| 人物太美 | AI美颜 | no beautification, weathered, scarred, pores visible, dirt on face, real skin |
| 光线不一致 | 多帧间变化 | consistent single light source, directional shadows match, no flickering |
| 调色板漂移 | 风格不统一 | consistent palette throughout, same color grade, no style shift between frames |
| 暗部发灰 | AI提亮暗部 | crushed blacks, true black, no grey in shadows, deep shadow, let black be black |
| 暖色溢出 | 暖场景太暖 | warm on surface only, cold undertone in shadows, false warmth, restrained warm |
| 魔法光不自然 | AI默认白光 | magic light is purple/blue/green, not white, supernatural color, twilight purple glow |
| 体积光缺失 | AI不加雾 | volumetric fog, dust particles, light shafts visible, atmospheric haze, god rays |
| 火光不闪烁 | AI火光恒定 | flickering firelight, dancing shadows, unstable warm, not constant |
| 雨无反射 | AI忽略湿面 | wet ground reflection, rain on surface, mirror-like puddles, rain reflection |
| 铠甲无反光 | AI忽略金属 | metal reflects light, armor specular, steel catches firelight, metallic reflection |
| 肤色偏绿/紫 | AI调色过度 | natural skin tone, no color cast on skin, correct flesh tone, grade everything except skin |
| 深景深不够 | AI默认浅景深 | deep focus, f/8, everything sharp, deep depth of field, no bokeh, Cuaron-grade |
| 浅景深不够 | AI默认全清晰 | shallow depth of field, f/1.4, bokeh, subject isolation, dreamy blur, Deakins portrait |
| 颗粒太重 | AI加噪过度 | subtle film grain, not heavy noise, organic texture, not digital noise |
| 颗粒不够 | AI输出太干净 | film grain, 35mm texture, organic, not clinical digital, movie-grade |
| 阴影方向错 | AI不理解光源 | shadows cast [direction] from [light source position], consistent shadow direction |
| 人物浮在场景上 | 光线不匹配 | character lit by same light as environment, integrated lighting, not composited |

---

> v2.0新增: 灯光配方扩展到20种(+8种新增含拱顶散射/火把走廊/魔法手持/雨中反光/烟雾体积/镜面反射/极光天空/纯暗)+调色方案扩展到20种(+8种新增含龙焰橙/亡灵绿蓝/皇家紫金/森林深翠/雪原白蓝/血月红/铸造橙铁/迷雾银灰)+AI工具特定参数(Kling/Seedance/Wan)+调色关键词对照表+12组最强灯光调色组合速配+20条常见问题修复。与lighting-design-signatures.md/colorist-signature-grade.md/镜头调度手册配合使用。
