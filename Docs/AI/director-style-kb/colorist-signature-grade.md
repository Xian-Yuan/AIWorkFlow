# 调色师签名风格知识库

> 类别: Colorist / Color Grading / Tone Mapping / Emotion-to-Color Pipeline
> 用途: 创作AI短剧时参考专业调色师的签名风格，将情绪需求转化为精确的色彩参数
> 关联: `镜头调度与摄影参数提示词速查手册.md` 第11-12节(色彩分级/胶片模拟)

---

## 1. 调色核心方法论

### 1.1 情绪→色彩映射(中世纪西幻专用)

| 情绪 | 主色调 | 辅色 | 避免色 | AI提示词 |
|------|--------|------|--------|---------|
| 绝望 | 去饱和灰蓝 | 黑 | 纯白/暖色 | desaturated grey-blue, crushed blacks, no warm, despair grade |
| 敬畏 | 深蓝+金 | 紫色边缘 | 霓虹 | deep blue+gold, purple edge, no neon, awe grade |
| 愤怒 | 高饱和红+暗 | 橙 | 冷蓝 | high saturation red+dark, orange accent, anger grade |
| 禁忌欲望 | 暖金+深暗 | 红 | 绿 | warm gold+deep dark, red accent, forbidden desire grade |
| 神圣 | 过曝白+金 | 蓝 | 黑 | overexposed white+gold, blue halo, sacred grade |
| 腐败/诅咒 | 去饱和黄绿+棕 | 血红 | 蓝 | desaturated yellow-green+brown, blood red accent, corruption grade |
| 孤独 | 冷蓝+灰 | 唯一暖 | 饱和色 | cold blue+grey, sole warm point, solitude grade |
| 复仇 | 高对比+深红 | 黑 | 柔色 | high contrast+deep red, black, revenge grade |
| 魔法(白) | 过曝+柔散+蓝白 | 银 | 泥色 | overexposed+soft diffusion+blue-white, silver, white magic grade |
| 魔法(黑) | 极暗+唯一发光体+深紫 | 绿 | 暖色 | extreme dark+sole glowing object+deep purple, green accent, dark magic grade |
| 成长/希望 | 自然饱和+绿+蓝 | 金 | 去饱和 | natural saturation+green+blue, gold accent, hope grade |
| 堕落 | 暖→冷渐进+去饱和递增 | 红 | 纯色 | warm to cold progression, increasing desaturation, fall from grace grade |

### 1.2 调色三维度控制

| 维度 | 控制 | 情绪效果 | AI提示词参数 |
|------|------|---------|------------|
| 亮度(Luma) | 提升/压暗/曲线 | 明=希望 暗=恐惧 | lifted shadows / crushed blacks / S-curve |
| 饱和度(Sat) | 增/减/选择性 | 高=强烈 低=沉郁 | high saturation / desaturated / selective color |
| 色相(Hue) | 偏移/分离色调 | 暖偏=亲密 冷偏=疏离 | warm shift / cool shift / teal-orange split |

---

## 2. 调色大师签名风格

### 2.1 Stefan Sonnenfeld — 去饱和冷暖对分(BvS/300/Transformers/Mad Max:Furiosa)

| 维度 | 特征 | AI提示词 |
|------|------|---------|
| 签名 | 冷蓝暖橙对分+去饱和+高对比 | teal-orange split, desaturated, high contrast, Sonnenfeld-grade |
| 阴影 | 深蓝黑+细节保留 | deep blue-black shadows, shadow detail preserved |
| 高光 | 橙暖+过曝边缘 | orange warm highlights, overexposed edges |
| 肤色 | 偏橙+略去饱和 | slightly orange skin tone, slightly desaturated |
| 中世纪适配 | 沙漠/战场/骑士: 沙色+冷蓝底+高对比 | `teal-orange, desaturated, high contrast, Sonnenfeld-grade, medieval desert battle` |

### 2.2 Tom Poole — 重量级去饱和(The Crown/Sicario/Arrival/Blade Runner 2049)

| 维度 | 特征 | AI提示词 |
|------|------|---------|
| 签名 | 极去饱和+冷灰+唯一强调色 | extreme desaturation, cold grey, single accent color, Poole-grade |
| 阴影 | 深黑+无细节(刻意的) | deep black, no shadow detail (intentional) |
| 高光 | 冷白+轻微过曝 | cold white highlights, slight overexposure |
| 肤色 | 灰+冷 | greyish cold skin tone |
| 中世纪适配 | 地牢/审判/废墟: 极去饱和+冷灰+唯一暖光 | `extreme desaturation, cold grey, sole warm light, Poole-grade, medieval dungeon` |

### 2.3 Maxine Gervais — 温暖人文(Catch Me If You Can/Mamma Mia/Julie & Julia)

| 维度 | 特征 | AI提示词 |
|------|------|---------|
| 签名 | 暖+自然饱和+复古柔+高光柔散 | warm, natural saturation, vintage soft, soft highlights, Gervais-grade |
| 阴影 | 温暖深棕+细节丰富 | warm deep brown shadows, rich detail |
| 高光 | 柔散+暖+微过曝 | soft diffused warm, slight overexposure |
| 肤色 | 自然+暖+健康 | natural warm healthy skin tone |
| 中世纪适配 | 酒馆/集市/日常: 暖+自然饱和+复古柔 | `warm, natural saturation, vintage soft, Gervais-grade, medieval tavern` |

### 2.4 Siggy Fersti(Lesnie后继) — 吉卜力自然(Bilbo/Lord of the Rings补充)

| 维度 | 特征 | AI提示词 |
|------|------|---------|
| 签名 | 自然饱和+绿+金+柔散+水彩感 | natural saturation, green+gold, soft diffusion, watercolor feel, Fersti-grade |
| 阴影 | 绿蓝底+自然深 | green-blue shadow base, natural depth |
| 高光 | 金色+自然+不过曝 | golden natural highlights, no overexposure |
| 中世纪适配 | 魔法森林/精灵领地: 自然饱和+绿+金+水彩 | `natural saturation, green+gold, watercolor, Fersti-grade, elven forest` |

### 2.5 Jill Bogdanowicz — 暗色电影(The Batman/Joker/It) 

| 维度 | 特征 | AI提示词 |
|------|------|---------|
| 签名 | 极暗+高对比+冷底+唯一暖强调 | extreme dark, high contrast, cold base, sole warm accent, Bogdanowicz-grade |
| 阴影 | 极深+冷蓝底 | extremely deep, cold blue base shadows |
| 高光 | 唯一暖+锐利 | sole warm sharp highlights |
| 中世纪适配 | 暗黑城堡/哥特/诅咒: 极暗+冷蓝底+唯一火暖 | `extreme dark, cold blue base, sole fire warm, Bogdanowicz-grade, gothic castle` |

---

## 3. 胶片模拟→AI提示词映射(补充速查手册第12节)

| 胶片 | 特征 | AI提示词 | 适配场景 |
|------|------|---------|---------|
| Kodak Vision3 500T | 暖+颗粒+自然肤色+宽容度 | Kodak 500T warm grain natural skin latitude | 酒馆/日常/对话 |
| Kodak Vision3 250D | 日光+清透+蓝绿+自然 | Kodak 250D daylight clear blue-green natural | 森林/平原/白天 |
| Fujifilm Eterna | 冷+绿底+清透+日式 | Fujifilm Eterna cold green base clear Japanese | 精灵/东方风格 |
| Kodachrome | 极饱和+红+暖+复古 | Kodachrome extreme saturation red warm vintage | 回忆/童话/年代感 |
| Ilford HP5(B&W) | 高对比+颗粒+银 | Ilford HP5 high contrast grain silver | 严肃/哲学/审判 |
| CineStill 800T | 镜头光晕+暖+霓虹+梦幻 | CineStill 800T halation warm neon dream | 夜景/魔法/梦幻 |
| Revolog Kolor | 彩色偏移+实验+迷幻 | Revolog Kolor color shift experimental psychedelic | 魔法失控/幻觉/异次元 |

---

## 4. 中世纪西幻调色速配表

| 场景 | 推荐调色师 | 胶片模拟 | AI提示词组合 |
|------|-----------|---------|------------|
| 城堡/宫殿 | Sonnenfeld | Kodak 500T | `teal-orange split, Kodak 500T, warm grain, Sonnenfeld-grade, castle interior` |
| 地牢/地下城 | Poole | Ilford HP5 | `extreme desaturation, Ilford HP5 B&W, cold grey, sole warm, Poole-grade, dungeon` |
| 酒馆/集市 | Gervais | Kodak 500T | `warm vintage soft, Kodak 500T, natural saturation, Gervais-grade, tavern` |
| 魔法森林 | Fersti | Fujifilm Eterna | `natural saturation green+gold, Fujifilm Eterna, watercolor, Fersti-grade, elven forest` |
| 暗黑城堡 | Bogdanowicz | CineStill 800T | `extreme dark cold blue base, CineStill 800T halation, sole fire warm, Bogdanowicz-grade` |
| 战场 | Sonnenfeld | Kodak 250D | `teal-orange desaturation, Kodak 250D daylight, high contrast, Sonnenfeld-grade, battlefield` |
| 回忆/闪回 | Gervais | Kodachrome | `warm vintage Kodachrome, extreme saturation, soft diffusion, memory grade` |
| 魔法失控 | Bogdanowicz | Revolog Kolor | `extreme dark, Revolog Kolor color shift, psychedelic, magic gone wrong grade` |
| 审判/判决 | Poole | Ilford HP5 | `extreme desaturation, Ilford HP5 B&W, cold institutional, Poole-grade, trial` |
| 诅咒村庄 | Bogdanowicz | Kodak 500T | `extreme dark, desaturated yellow-green, blood red accent, corruption grade` |

---

## 5. 调色+导演+DP+PD 组合速配(终极组合)

| 风格目标 | 导演 | DP | PD | 调色师 | 提示词组合 |
|----------|------|-----|-----|--------|----------|
| 中世纪史诗 | Jackson | Kaminski | Ferretti | Sonnenfeld | `Jackson wide, Kaminski halo, Ferretti gilt decay, Sonnenfeld teal-orange, epic medieval` |
| 暗黑哥特 | Kubrick | Alcott | Ferretti | Bogdanowicz | `Kubrick symmetric, Alcott even, Ferretti iron+rust, Bogdanowicz extreme dark+sole warm, gothic` |
| 精灵森林 | Malick | Lubezki | Craig | Fersti | `Malick natural, Lubezki golden hour, Craig vertical+gothic, Fersti green+gold watercolor, elven` |
| 战场写实 | Spielberg | Kaminski | Carter | Sonnenfeld | `Spielberg reaction, Kaminski overexpose, Carter trenches, Sonnenfeld desat+contrast, war realism` |
| 诅咒地牢 | Eggers | Blaschke | Ferretti | Poole | `Eggers candle-only, Blaschke square desat, Ferretti iron, Poole extreme desat cold grey, dungeon` |
| 魔法梦幻 | del Toro | Navarro | Craig | Gervais | `del Toro amber+monster, Navarro warm+blue, Craig suspended, Gervais warm vintage soft, magic dream` |


---

## 6. 更多调色大师签名

### 6.1 Eric Weidt — Fincher的极致控制(Mindhunter/Gone Girl/Social Network)

| 维度 | 特征 | AI提示词 |
|------|------|---------|
| 签名 | 极致去饱和+冷绿+精确肤色控制+暗部不压死 | extreme desaturation, cold green, precise skin tone, shadow detail preserved, Weidt-grade |
| 阴影 | 深但保留细节/冷绿底 | deep but detailed, cold green shadow base |
| 高光 | 冷白+不过曝/精确控制 | cold white, no overexposure, precise control |
| 肤色 | 严格控制在自然范围/略去饱和 | strictly natural, slightly desaturated skin |
| 中世纪适配 | 审判/密谋/调查: 极去饱和+冷绿+精确 | extreme desat cold green precise, Weidt-grade, medieval conspiracy |

### 6.2 Joe Walker — 自然主义调色(1917/Dunkirk/Spectre)

| 维度 | 特征 | AI提示词 |
|------|------|---------|
| 签名 | 自然+不过分+日间清透+夜间冷静 | natural, not overdone, daylight clear, night calm, Walker-grade |
| 阴影 | 自然深/不压死 | natural deep, no crushed blacks |
| 高光 | 自然/不过曝/保持真实感 | natural highlights, no overexposure, realism |
| 肤色 | 完全自然/不做作 | completely natural skin tone |
| 中世纪适配 | 战场日间/行军/营地: 自然+清透+真实 | natural clear, Walker-grade, battlefield daylight, realistic medieval |

### 6.3 Stefan Sonnet — 当代暗色(The Batman补色/Se7en风格)

| 维度 | 特征 | AI提示词 |
|------|------|---------|
| 签名 | 极暗+高对比+阴影区有色偏+红底偶尔闪 | extreme dark, high contrast, shadow hue shift, red base flash, Sonnet-grade |
| 阴影 | 极深+色偏(蓝/紫底) | extremely deep, hue-shifted shadows (blue/purple base) |
| 高光 | 锐利/冷白/极少 | sharp cold white, minimal highlights |
| 中世纪适配 | 吸血鬼城堡/诅咒地牢: 极暗+色偏+红闪 | extreme dark hue-shifted, red flash, Sonnet-grade, vampire castle |

### 6.4 Yvan Lucas — 法国浪漫调色(Amelie/Delicatessen/Jeunet)

| 维度 | 特征 | AI提示词 |
|------|------|---------|
| 签名 | 暖+过饱和+梦幻+复古+奇趣 | warm, oversaturated, dreamy, vintage, whimsical, Lucas-grade |
| 阴影 | 温暖深棕/不真实 | warm deep brown, unreal |
| 高光 | 柔散+暖+金 | soft diffused warm gold |
| 肤色 | 偏暖/偏粉/不真实但美 | warm pinkish, unreal but beautiful |
| 中世纪适配 | 魔法集市/巫师店铺/童话: 暖+过饱和+奇趣 | warm oversaturated whimsical, Lucas-grade, magic market, fairy tale |

### 6.5 Tom Graham — 当代自然主义(The Revenant/Dark Knight风格)

| 维度 | 特征 | AI提示词 |
|------|------|---------|
| 签名 | 极自然+不分级感+原始+户外光 | extremely natural, no grade feel, raw, outdoor light, Graham-grade |
| 阴影 | 自然环境光/无额外填充 | natural ambient, no fill |
| 高光 | 天空自然/过曝即过曝 | natural sky, overexpose if real |
| 肤色 | 户外自然/风吹/冻 | outdoor natural, wind-burned, frozen |
| 中世纪适配 | 北方荒野/生存/追踪: 极自然+原始+户外 | extremely natural raw outdoor, Graham-grade, wilderness survival |

---

## 7. DaVinci Resolve调色逻辑->AI提示词映射

### 7.1 节点逻辑翻译

| DaVinci节点 | 功能 | AI提示词等效 | 使用场景 |
|------------|------|------------|---------|
| Primary(一级) | 全局曝光/白平衡/对比度 | global exposure, white balance, contrast | 每个镜头基础 |
| Secondary(二级) | 选择性调色/HSL限定 | selective color, HSL qualifier, skin tone protect | 人物vs背景分离 |
| Power Window | 区域调色/遮罩 | windowed grade, vignette, zone-specific | 脸部提亮/角落压暗 |
| LUT | 风格预设/胶片模拟 | Kodak 500T / Fujifilm Eterna / CineStill 800T | 全局风格锚定 |
| Curve | 精确色调控制 | S-curve contrast, lifted blacks, rolled highlights | 精细情绪调整 |
| Color Warper | 色相偏移/创意调色 | hue shift towards teal/orange, creative color bend | 风格化偏移 |

### 7.2 常见调色工作流->AI提示词

| 工作流 | 步骤 | AI提示词 |
|--------|------|---------|
| 基础校正 | 平衡曝光+白平衡 | balanced exposure, neutral white balance |
| 风格化 | 叠加LUT+曲线 | Kodak 500T LUT, S-curve, lifted shadows |
| 肤色保护 | HSL限定+隔离 | skin tone protected, HSL isolate, natural face |
| 情绪强化 | 整体偏移 | warm shift for intimacy / cool shift for isolation |
| 暗角 | Power Window | subtle vignette, edges darkened, center bright |

---

## 8. 场景级调色拆解(5个关键场景)

### 8.1 场景: 暗黑骑士进入城堡

`
Primary: crushed blacks, cold blue shadow base, low saturation
Secondary: skin tone slightly desaturated but visible, armor retains metallic sheen
Power Window: face slightly lifted, background pressed darker
LUT: Ilford HP5 B&W base with subtle color bleed
Curve: heavy S-curve, no highlight rolloff
Final: Bogdanowicz-grade, extreme dark, sole fire warm accent, gothic
`
AI提示词: crushed blacks, cold blue shadows, low saturation, skin protected, armor metallic, Ilford HP5 B&W color bleed, Bogdanowicz-grade, dark knight castle entrance, 9:16

### 8.2 场景: 精灵森林晨曦

`
Primary: lifted shadows, warm gold base, natural saturation
Secondary: greens pushed towards emerald, sky towards cyan
Power Window: sun shaft area lifted, shadow area cooled
LUT: Fujifilm Eterna as base
Curve: gentle S-curve, soft highlight rolloff
Final: Fersti-grade, green+gold watercolor, elven morning
`
AI提示词: lifted shadows, warm gold base, natural saturation, emerald greens, cyan sky, Fujifilm Eterna, Fersti-grade, elven forest morning, volumetric sun shafts, 9:16

### 8.3 场景: 战场黄昏

`
Primary: orange+teal split, desaturated mid, high contrast
Secondary: blood red accent protected, sky orange pushed
Power Window: horizon lifted, ground pressed
LUT: Kodak 500T as base
Curve: strong S-curve, crushed shadows for silhouette
Final: Sonnenfeld-grade, teal-orange desat, battlefield dusk
`
AI提示词: orange+teal split, desaturated midtones, high contrast, blood red accent, Kodak 500T, Sonnenfeld-grade, battlefield dusk, silhouette against orange sky, 9:16

### 8.4 场景: 诅咒发作/魔法失控

`
Primary: dark, low saturation base, unstable exposure
Secondary: random color shifts, skin tone drifting, chromatic aberration
Power Window: eyes/hands isolated with shifting color
LUT: Revolog Kolor as base (experimental color shift)
Curve: unstable, flickering, inconsistent
Final: experimental grade, color instability, magic失控
`
AI提示词: dark base, low saturation, random color shifts, chromatic aberration, skin tone drifting, Revolog Kolor experimental, magic out of control, unstable grade, 9:16

### 8.5 场景: 北欧寒冬(结合nordic-crime KB)

`
Primary: near-monochrome, ice blue+grey, extreme desat
Secondary: skin tone cold grey, sky pushed to steel blue
Power Window: figure slightly lifted, environment pressed cold
LUT: Kodak 250D pushed cold as base
Curve: crushed blacks, no warm rolloff
Final: Poole+Trapped hybrid, ice blue monochrome, Nordic cold
`
AI提示词: 
ear-monochrome, ice blue+grey, extreme desat, cold grey skin, steel blue sky, Kodak 250D cold push, Poole-grade, Nordic cold, blizzard, 9:16

---

## 9. AI视频工具调色最佳实践(2026Q2)

### 9.1 各工具调色能力对比

| 工具 | 调色控制 | 最佳方式 | 局限 |
|------|---------|---------|------|
| Kling | 中等/偏自然 | 提示词中明确color grading关键词 | 倾向高饱和/偏美 |
| Seedance | 较好/可控制 | 用reference image+调色词 | 风格过强时会失真 |
| Vidu | 中等/偏写实 | 简单的warm/cool指令 | 复杂调色词会被忽略 |
| Wan | 较好/理解力强 | 可用完整调色描述 | 有时过饱和 |
| Sora | 最强/理解最精确 | 可用专业调色术语 | 速度慢/成本高 |

### 9.2 AI调色铁律

1. **先风格锚定再细化**: 先给导演/DP/调色师签名，再给具体参数
2. **避免矛盾指令**: 不要同时说"high saturation"和"desaturated"
3. **肤色保护是关键**: 始终包含"natural skin tone"或"skin tone protected"
4. **测试后微调**: 先生成测试帧，确认调色方向，再批量生产
5. **胶片模拟比参数更有效**: "Kodak 500T"比"shadows+10 highlights-5"更可靠
6. **情绪词>技术词**: "despair grade"比"crushed blacks+lifted midtones"更能引导AI

### 9.3 常见AI调色失败及修复

| 失败 | 原因 | 修复 |
|------|------|------|
| 过饱和/色彩爆炸 | AI倾向加强色彩 | 加"desaturated, restrained, no oversaturation" |
| 肤色异常(绿/橙) | 调色指令影响肤色 | 加"natural skin tone, skin protected from grade" |
| 暗部死黑/无细节 | "extreme dark"被过度解读 | 加"shadow detail preserved, no crushed blacks in face" |
| 风格不一致 | 每帧随机风格 | 加"consistent grade throughout, same color palette" |
| 过度滤镜感 | LUT+调色词叠加 | 二选一: 要么LUT要么手动描述，不同时用 |

---

## 10. 调色师+导演+DP终极组合表(扩展版)

| 风格目标 | 导演 | DP | 调色师 | 胶片 | 提示词组合 |
|----------|------|-----|--------|------|----------|
| 中世纪史诗 | Jackson | Kaminski | Sonnenfeld | 500T | Jackson wide, Kaminski halo, Sonnenfeld teal-orange, Kodak 500T, epic medieval |
| 暗黑哥特 | Kubrick | Alcott | Bogdanowicz | HP5 | Kubrick symmetric, Alcott even, Bogdanowicz extreme dark+sole warm, Ilford HP5, gothic |
| 精灵森林 | Malick | Lubezki | Fersti | Eterna | Malick natural, Lubezki golden hour, Fersti green+gold watercolor, Fujifilm Eterna, elven |
| 战场写实 | Spielberg | Kaminski | Sonnenfeld | 250D | Spielberg reaction, Kaminski overexpose, Sonnenfeld desat+contrast, Kodak 250D, war |
| 诅咒地牢 | Eggers | Blaschke | Poole | HP5 | Eggers candle-only, Blaschke square desat, Poole extreme desat cold grey, Ilford HP5, dungeon |
| 魔法梦幻 | del Toro | Navarro | Gervais | 500T | del Toro amber+monster, Navarro warm+blue, Gervais warm vintage soft, Kodak 500T, magic |
| 北方寒冬 | Refn | Larry Smith | Poole | 250D | Refn neon ritual, Smith hyper-sat, Poole extreme desat cold, Kodak 250D cold push, Nordic |
| 宫廷密谋 | Fincher | Deakins | Weidt | 500T | Fincher precise track, Deakins single source, Weidt extreme desat cold green, Kodak 500T, conspiracy |
| 魔法集市 | Jeunet | Navarro | Lucas | Kodachrome | Jeunet whimsical, Navarro warm+blue, Lucas warm oversaturated whimsical, Kodachrome, market |
| 吸血鬼城堡 | Eggers | Blaschke | Sonnet | 800T | Eggers candle-only, Blaschke square, Sonnet extreme dark hue-shifted, CineStill 800T, vampire |
| 荒野生存 | Malick | Lubezki | Graham | 250D | Malick natural, Lubezki golden hour, Graham extremely natural raw, Kodak 250D, wilderness |
| 诅咒发作 | Aronofsky | Libatique | Bogdanowicz | Kolor | Aronofsky spiral, Libatique handheld, Bogdanowicz extreme dark+sole warm, Revolog Kolor, curse |
