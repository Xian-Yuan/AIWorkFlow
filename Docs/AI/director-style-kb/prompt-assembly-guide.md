# 综合提示词组装指南 — 全知识库工作流

> 类别: Prompt Assembly Guide / Full Workflow / All-KB Integration
> 用途: 把38个KB文件的知识整合为单一工作流，从"我想要什么感觉"到"完整可粘贴提示词"
> 关联: 所有KB文件(本指南是全知识库的使用说明书)

---

## 1. 提示词组装六步法

### 步骤1: 确定情绪/场景(30秒)

**问自己**: 这段要让观众感受到什么？

| 查询方式 | 查哪里 | 得到什么 |
|----------|--------|---------|
| 按情绪 | README路由表1 | 导演+风格组合 |
| 按场景 | README路由表2 | 导演+技法 |
| 按游戏美学 | README路由表5 | 游戏视觉参考 |
| 按西幻范式 | medieval-fantasy-pattern-library | 30种视觉范式 |
| 按角色原型 | medieval-fantasy-pattern-library | 12种角色视觉签名 |
| 按叙事弧 | narrative-structure-template | 5种西幻叙事弧 |

### 步骤2: 选择视觉签名(30秒)

| 维度 | 选择 | 查哪里 |
|------|------|--------|
| 导演 | 谁的构图/运镜/叙事逻辑 | 路由表3(导演一句话签名) |
| DP | 谁的灯光签名 | 路由表4(DP签名灯光) |
| 调色师 | 什么调色风格 | colorist-signature-grade |
| 剪辑师 | 什么节奏 | editor-signature-rhythm |
| 服装 | 什么视觉身份 | costume-armor-design |
| VFX | 什么魔法可视化 | vfx-visual-effects |

### 步骤3: 组装核心提示词(60秒)

用MCSLA六模块公式组装:

```
Subject: [角色/场景描述] (来自角色原型+场景范式)
Physical: [物理细节/材质/纹理] (来自服装铠甲+材质映射)
Lighting: [灯光签名+光源+情绪] (来自DP签名+灯光-情绪映射)
Composition: [构图+运镜+景别] (来自导演构图签名+分镜序列)
Camera: [焦距+景深+运动] (来自速查手册1-6节)
Style: [调色+胶片+风格化] (来自调色师+胶片模拟)
```

### 步骤4: 适配9:16竖屏(15秒)

| 检查项 | 规则 | 查哪里 |
|--------|------|--------|
| 安全区 | 顶2行+底3行不放关键内容 | douyin-shortform-visual 1.2节 |
| 构图转换 | 横→竖转换规则 | storyboard-visual-planning 3.3节 |
| 焦点 | 9:16只保留一个焦点 | douyin-shortform-visual 1.2节 |

### 步骤5: 添加声音设计(15秒)

| 维度 | 选择 | 查哪里 |
|------|------|--------|
| 氛围 | 环境声/天气/空间 | sound-design-emotion 1.3节 |
| 音乐 | 配器/情绪/模式 | sound-design-emotion 3.1节 |
| 沉默 | 是否用沉默/哪种 | sound-design-emotion 1.2节 |

### 步骤6: 物理真实感检查(15秒)

逐项检查速查手册16节8层清单，确保无AI糊片。

---

## 2. 完整提示词模板(可直接粘贴)

### 2.1 60秒中世纪西幻标准模板

```
# 60秒中世纪西幻AI短剧提示词

## 场景: [从20场景直出中选择或自定义]
## 情绪目标: [从12情绪→色彩映射中选择]

### 钩子(0-3秒)
- 镜头: [ECU/CU震撼画面]
- 视觉: [导演构图签名]
- 灯光: [DP签名灯光]
- 声音: [突然/沉默/环境]
- 提示词: [组装]

### 建置(3-12秒)
- 镜头: [建立序列: EWS→WS→MS]
- 视觉: [世界建立+角色]
- 灯光: [场景主光源]
- 调色: [调色师签名+胶片模拟]
- 声音: [环境声建立]
- 提示词: [组装]

### 升级(12-30秒)
- 镜头: [混合景别+动作]
- 剪辑: [剪辑师签名节奏]
- 服装: [角色服装签名]
- VFX: [魔法效果(如有)]
- 声音: [音乐+效果]
- 提示词: [组装]

### 高潮(30-48秒)
- 镜头: [快切+慢动作交替]
- 剪辑: [高潮节奏]
- VFX: [魔法高潮(如有)]
- 声音: [高潮音乐/沉默→爆发]
- 提示词: [组装]

### 收尾(48-60秒)
- 镜头: [长持+沉默]
- 声音: [大提琴/钢琴/沉默]
- 钩子: [悬念/新问题]
- 提示词: [组装]

### 全局设定
- 调色: [调色师签名+胶片模拟]
- 竖屏: [9:16安全区+焦点规则]
- 物理真实感: [8层清单检查]
- 风格锚定: [参考导演+DP+调色师组合]
```

### 2.2 15秒极简模板

```
# 15秒中世纪西幻极简提示词

## 场景: [从3个抖音模板或20场景直出中选择]
## 风格: [6大视觉模式之一: 暗黑/水彩/漫画/纪实/赛博/水墨]

shot 1: [景别+内容+时长], [灯光], [情绪]
shot 2: [景别+内容+时长], [运镜], [情绪]
shot 3: [景别+内容+时长], [构图], [情绪]
shot 4: [景别+内容+时长], [VFX], [情绪]
shot 5: [景别+内容+时长], [声音], [情绪]

grade: [调色师签名], [胶片模拟], [情绪关键词]
style: [导演+DP组合], [竖屏规则]
sound: [氛围+音乐+沉默模式]
```

---

## 3. 十大最常用组合速查

| # | 场景 | 导演+DP+调色+剪辑 | 完整提示词 |
|---|------|-------------------|----------|
| 1 | 暗黑骑士出场 | Kubrick+Alcott+Bogdanowicz+Walker | `symmetric, locked, even light, black armor, backlight silhouette, extreme dark cold blue, sole fire warm, long hold silence, dark knight entrance` |
| 2 | 魔法森林 | Malick+Lubezki+Fersti+Tichenor | `natural light, golden hour, handheld close, natural saturation green+gold, watercolor, volumetric through trees, beat-driven, elven forest` |
| 3 | 城墙攻防 | Jackson+Kaminski+Sonnenfeld+Sixel | `aerial→handheld, rain, torch, wall divider, overexpose halo, teal-orange desat high contrast, fast cut center framed, siege` |
| 4 | 诅咒发作 | Eggers+Blaschke+Bogdanowicz+Murch | `candle-only, square desat, extreme dark cold blue sole warm, breathing rhythm, dissonance, slow push-in, curse onset` |
| 5 | 骑士出发 | Leone+Doyle+Gervais+Schoonmaker | `ECU eyes, wide wasteland, backlight, warm vintage soft, music-driven, fanfare, lone rider, departure` |
| 6 | 巨龙出现 | Villeneuve+Fraser+Poole+Walker | `monochrome, slow build, sand desat, extreme desat cold grey, long hold silence, low freq progressive, dragon reveal` |
| 7 | 禁忌之恋 | Wong Kar-wai+Doyle+Gervais+Tichenor | `off-axis, step-printing, warm-cold, soft focus, warm vintage, beat-driven, candlelight, forbidden love` |
| 8 | 废墟探索 | FromSoft+Navarro+Bogdanowicz+Walker | `low angle ruins, desaturated grey-green, bonfire sole warm, environmental storytelling, extreme dark, long hold silence, Souls exploration` |
| 9 | 宝剑拔出 | Snyder+van Hoytema+Sonnenfeld+Sixel | `slow-mo, backlight, IMAX cold-warm split, teal-orange, speed ramp, metal gleam, sword draw` |
| 10 | 英雄牺牲 | Jackson+Kaminski+Gervais+Walker | `slow-mo, backlight, blood, silhouette, warm vintage soft, solo cello, long hold silence 3-5s, sacrifice` |

---

## 4. 紧急创作公式(5秒出提示词)

当时间极紧，用以下公式快速出提示词:

```
[情绪关键词] + [场景关键词] + [导演一句话签名] + [9:16竖屏]
```

示例:
- 恐惧+地牢+Kubrick对称+9:16 = `fear, dungeon, symmetric one-point corridor, cold blue, candle only, 9:16 vertical, Kubrick-grade`
- 敬畏+巨龙+Villeneuve慢建立+9:16 = `awe, dragon, slow build negative space, low freq tremor, desaturated, 9:16, Villeneuve-grade`
- 悲壮+牺牲+Snyder慢动作+9:16 = `tragic, sacrifice, slow motion backlight silhouette, blood, solo cello, 9:16, Snyder-grade`
- 神秘+魔法森林+Malick自然光+9:16 = `mystery, magic forest, natural light golden hour, volumetric, green+gold, 9:16, Malick-grade`
- 愤怒+复仇+Fincher去饱和+9:16 = `anger, revenge, desaturated cold green, precise track, sudden violence, 9:16, Fincher-grade`

---

## 5. 知识库全文件速查索引

| 领域 | 文件 | 核心内容 |
|------|------|---------|
| 导演(欧美) | crime-thriller / fantasy-epic / horror-dark / war-history-drama / scifi-special / action-martial | 25+导演签名 |
| 导演(亚洲/欧洲) | asian-drama-cinematic / european-masters / latinam-crosscultural / asian-indie | 20+导演签名 |
| 导演(补充) | quickcut-comedy-lowbudget / contemporary-absurd-sensory / classic-onetake-meta / crime-noir-urban / anxiety-contemporary-supplement / deep-supplement-directors | 20+导演/深潜 |
| 游戏 | game-aesthetic-crossover | FromSoftware/Zelda/ICO/Witcher/Dogma |
| 动画 | animation-masters / arthouse-female-animation | Shinkai/Takahata/Oshii/Yuasa/SV/Laika/Miyazaki/Kon |
| MV | music-video-visual | Fincher MV/Jonze MV/Gondry/Hype/Sigismondi |
| 技术 | storyboard-visual-planning / colorist-signature-grade / editor-signature-rhythm / sound-design-emotion / vfx-visual-effects | 分镜/调色/剪辑/声音/VFX |
| 设计 | production-designer-artdir / costume-armor-design | PD签名/服装铠甲 |
| 平台 | douyin-shortform-visual | 抖音竖屏/转场/节奏/模板 |
| 类型 | genre-grammar-deepdive | 西部/黑色/战争/恐怖/科幻→西幻 |
| 西幻 | medieval-fantasy-pattern-library / mythology-visual-roots | 30范式+12原型+20场景/4神话体系 |
| 拉片 | key-work-deepdive / key-scenes-supplement | True Detective/LOTR/GoT/Dune/Pan's/Excalibur |
| 叙事 | narrative-structure-template | 英雄之旅/五段式/5弧/5模板 |
| 路由 | README | v12.0, 5维度路由表 |


---

## 6. AI视频工具实战提示词(2026Q2更新)

### 6.1 Kling最佳提示词结构

`
[主体描述], [光线], [构图/景别], [运镜], [调色/风格], [情绪关键词], 9:16 vertical
`
示例: lone knight in dark castle corridor, candle-only practical light, low angle MS, slow push-in, extreme dark cold blue sole fire warm Bogdanowicz-grade, dread, 9:16 vertical

### 6.2 Seedance最佳提示词结构

`
[reference style], [主体+动作], [环境], [光线+调色], [运镜], [情绪], 9:16
`
示例: Kubrick-style symmetric, knight draws sword in stone hall, dark castle, even practical lighting+teal-orange grade, locked wide then slow zoom, awe, 9:16

### 6.3 Vidu最佳提示词结构(简洁)

`
[主体] [动作] in [场景], [光线], [风格关键词], 9:16
`
示例: dragon emerges from mountain, overcast natural light, Villeneuve slow-build desaturated, 9:16

### 6.4 Wan最佳提示词结构

`
[详细场景描述], [导演+DP签名], [调色师+胶片], [运镜+景别], [情绪], 9:16
`
示例: ncient monastery in snowstorm, Eggers candle-only Blaschke square, Poole extreme-desat Ilford-HP5, locked EWS then slow push-in, isolation devotion, 9:16

---

## 7. 常见AI视频失败诊断与修复

### 7.1 物理真实感失败

| 失败类型 | 症状 | 根因 | 修复提示词 |
|---------|------|------|-----------|
| 手指异常 | 多指/少指/融合 | AI对手部理解弱 | 加"hands behind back, hands not visible, holding sword grip" |
| 光线矛盾 | 多方向光/无影 | 光线指令冲突 | 加"single light source, directional light, cast shadow" |
| 材质塑料感 | 金属不反光/布无褶皱 | 材质词不够 | 加"worn iron patina, coarse wool texture, weathered leather grain" |
| 空间混乱 | 透视错误/比例失调 | 空间描述不清 | 加"one-point perspective, vanishing point center, depth recedes" |
| 运动不自然 | 滑行/浮空/不重力 | 物理词缺失 | 加"weight on feet, grounded, heavy armor affects movement, labored steps" |

### 7.2 风格一致性失败

| 失败类型 | 症状 | 根因 | 修复提示词 |
|---------|------|------|-----------|
| 风格漂移 | 每帧风格不同 | 缺少风格锚定 | 加"consistent style throughout, same director signature, same color palette" |
| 调色跳变 | 帧间调色不一致 | 调色词太复杂 | 简化为一个调色师签名+一个胶片模拟 |
| 服装变化 | 同角色服装变 | 服装描述不够 | 加"consistent armor: black plate, visor helm, no variation" |
| 环境变化 | 同场景环境变 | 环境锚定不够 | 加"consistent environment: stone walls, torches right, wooden door left" |

### 7.3 叙事逻辑失败

| 失败类型 | 症状 | 根因 | 修复提示词 |
|---------|------|------|-----------|
| 镜头顺序乱 | 建置/高潮顺序错 | 缺少镜头编号 | 加"shot 1 of 5: EWS establish, shot 2: MS..." |
| 角色不一致 | 同角色变脸 | 缺少角色锚定 | 加"same character: scarred face, black armor, red cape" |
| 时间线混乱 | 日夜突然跳 | 缺少时间锚定 | 加"continuous time: dusk, same lighting throughout sequence" |

---

## 8. 高级组合公式(10组新组合)

| # | 情绪+场景 | 组合 | 提示词公式 |
|---|----------|------|-----------|
| 1 | 孤独+北方要塞 | Trapped+Poole+Persson | lizzard, stone fortress, human 15% of frame, locked wide, ice blue+grey, extreme desat, sole warm = window candle, Persson half-face, Poole-grade, 9:16 |
| 2 | 恐惧+诅咒发作 | Lynch+Bogdanowicz+Svankmajer | 
ormal room, sudden anomaly, flicker, red shift, cursed object moves, stop-motion, extreme dark, sole warm, Lynch-surreal+Svankmajer, 9:16 |
| 3 | 敬畏+魔法仪式 | Jodorowsky+Smith+Sonnenfeld | itual circle, crowd as pattern, red+gold+black, hyper-saturated, one color per phase, teal-orange split, Jodorowsky+Smith-grade, 9:16 |
| 4 | 真相+调查 | Wiseman+Weidt+Videbaek | institutional space, no intervention, frontal observe, extreme desat cold green, fluorescent, grey-green, Wiseman+Weidt-grade, 9:16 |
| 5 | 梦境+预言 | Cocteau+Marker+Fersti | mirror threshold, reverse motion, photo-memory, push into still, green+gold watercolor, Cocteau+Marker+Fersti-grade, 9:16 |
| 6 | 暴力+复仇 | Refn-Pusher+Larry Smith+Bogdanowicz | handheld rough, countdown, neon dirty, hyper-saturated black base, extreme dark+sole warm, sudden violence, Pusher+Smith-grade, 9:16 |
| 7 | 沉默+审判 | Bron+Poole+Persson | ridge as boundary, silence gap, extreme desat cold grey, half-face Nordic window, institutional, Bron+Poole+Persson-grade, 9:16 |
| 8 | 童话+魔法集市 | Jeunet+Lucas+Gervais | whimsical, warm oversaturated, vintage soft, amber+curiosity, Kodachrome, Jeunet+Lucas+Gervais-grade, 9:16 |
| 9 | 极端+朝圣 | Herzog+Graham+Poole | 
ature 80% human 20%, extremely natural raw, volcanic red+ash grey, contemplative narration, Herzog+Graham-grade, 9:16 |
| 10 | 感官+魔法森林 | Leviathan+Fersti+Malick | 
on-human POV fisheye, sensory flow, green+gold watercolor, natural light golden hour, no narrative only sensation, Leviathan+Fersti-grade, 9:16 |

---

## 9. 完整60秒脚本示例(暗黑骑士出发)

`yaml
title: "暗黑骑士出发"
duration: 60s
emotion_arc: [dread -> resolve -> awe -> dread]

# 钩子 0-3s
shot_1:
  type: ECU
  content: "铠甲手套扣上护手, 金属咔嚓声"
  lighting: "candle-only, sole warm, Bogdanowicz-grade"
  camera: "locked, extreme close, material = devotion"
  sound: "metal click, no music, silence after"
  prompt: "armored gauntlet closing, metal click, candlelight, extreme close, material devotion, Bogdanowicz-grade, 9:16"

# 建置 3-12s
shot_2:
  type: WS
  content: "暗黑城堡走廊, 火炬列队, 骑士远端走来"
  lighting: "torchlight corridor, Kubrick symmetric, Alcott even"
  camera: "locked wide, one-point perspective, vanishing point"
  sound: "footsteps echo, armor creak, no music"
  prompt: "dark castle corridor, torches symmetric, knight distant, one-point perspective, Kubrick+Alcott-grade, 9:16"

shot_3:
  type: MS
  content: "骑士走近, 铠甲细节, 火炬光在金属上"
  lighting: "torch practical, metal reflection, Bogdanowicz extreme dark"
  camera: "slow push-in, from MS to CU"
  sound: "footsteps closer, armor weight audible"
  prompt: "knight approaching, black plate armor detail, torchlight on metal, slow push-in, extreme dark sole fire warm, Bogdanowicz-grade, 9:16"

# 升级 12-30s
shot_4:
  type: CU
  content: "骑士面部/头盔缝隙/眼睛"
  lighting: "visor slit light, only eyes visible, cold blue"
  camera: "locked CU, let eyes speak"
  sound: "breathing inside helm, low drone begins"
  prompt: "knight visor slit, eyes in darkness, cold blue, locked CU, let eyes speak, resolve, 9:16"

shot_5:
  type: WS
  content: "城堡大门打开, 外面暴雪"
  lighting: "interior torch vs exterior blizzard, two light worlds"
  camera: "locked wide, door as frame"
  sound: "door groan, wind blast, snow enters"
  prompt: "castle gate opens, blizzard outside, two light worlds, door as frame, torch vs snow, Trapped+Kubrick-grade, 9:16"

# 高潮 30-48s
shot_6:
  type: MS
  content: "骑士步入暴雪, 背影, 铠甲在雪中"
  lighting: "backlit by torch, silhouette, snow coating"
  camera: "slow track forward, following into storm"
  sound: "wind, armor in snow, no music, only nature"
  prompt: "knight into blizzard, backlit silhouette, snow on armor, slow track, Trapped isolation, nature 80%, 9:16"

shot_7:
  type: EWS
  content: "骑士在暴雪中越来越小, 自然吞没人"
  lighting: "whiteout, near-monochrome, ice blue+grey"
  camera: "locked wide, human shrinks"
  sound: "wind only, no human sound"
  prompt: "knight tiny in blizzard whiteout, human 5% of frame, locked wide, ice blue monochrome, Trapped+Poole-grade, 9:16"

# 收尾 48-60s
shot_8:
  type: CU
  content: "雪地上的足迹, 被暴雪逐渐掩埋"
  lighting: "flat snow light, near-white, footprint dark"
  camera: "locked CU, time passing in one shot"
  sound: "wind fading, solo cello begins"
  prompt: "footprints in snow, blizzard burying them, locked CU, time passing, wind fading, solo cello, 9:16"

shot_9:
  type: ECU
  content: "最后一个足迹被雪填满, 消失"
  lighting: "white, pure, nothing left"
  camera: "locked, let disappearance speak"
  sound: "cello sustain, silence"
  prompt: "last footprint filling with snow, disappearance, locked ECU, white silence, cello sustain, 9:16"

# 全局
grade: "Bogdanowicz extreme dark interior -> Trapped ice blue exterior, Poole-grade, Kodak 500T interior / Kodak 250D cold push exterior"
style_anchor: "Kubrick symmetric interior + Trapped blizzard exterior + Bogdanowicz dark+sole warm"
sound_design: "interior: echo+metal / exterior: wind+nature / transition: door=open=world change"
vertical_rules: "9:16, knight centered, door as vertical frame, footprints at bottom third"
`

---

## 10. 知识库全文件速查索引(更新版)

| 领域 | 文件 | 核心内容 | 大小 |
|------|------|---------|------|
| 导演(欧美) | crime-thriller / fantasy-epic / horror-dark / war-history-drama / scifi-special / action-martial | 25+导演签名 | 10-13KB |
| 导演(亚洲/欧洲) | asian-drama-cinematic / european-masters / latinam-crosscultural / asian-indie | 20+导演签名 | 10-16KB |
| 导演(补充) | quickcut-comedy / contemporary-absurd / classic-onetake / crime-noir-urban / anxiety-supplement / deep-supplement | 20+深潜 | 8-17KB |
| 游戏 | game-aesthetic-crossover | FromSoftware/Zelda/ICO/Witcher/Dogma | 16KB |
| 动画 | animation-masters / arthouse-female-animation | Shinkai/Takahata/Oshii/Yuasa/SV/Laika | 10-11KB |
| MV | music-video-visual | Fincher MV/Jonze MV/Gondry/Hype/Sigismondi | 10KB |
| 技术 | storyboard / colorist / editor / sound / vfx | 分镜/调色/剪辑/声音/VFX | 9-20KB |
| 设计 | production-designer / costume-armor | PD签名/服装铠甲 | 10-11KB |
| 平台 | douyin-shortform-visual | 抖音竖屏/转场/节奏/模板 | 12.6KB |
| 类型 | genre-grammar-deepdive | 西部/黑色/战争/恐怖/科幻->西幻 | 11.6KB |
| 西幻 | medieval-fantasy-pattern / mythology-visual-roots / fantasy-character-encyclopedia | 30范式+12原型+20场景/4神话/12角色 | 10-16KB |
| 拉片 | key-work-deepdive / key-scenes-supplement / true-detective-deepdive / specific-film-deepdives-v2 | 真探/LOTR/GoT/Dune/Pan/Nosferatu | 9-16KB |
| 叙事 | narrative-structure-template | 英雄之旅/五段式/5弧/5模板 | 8.5KB |
| 北欧 | nordic-crime-dark-visual | Bron/Killing/Refn/Trapped/Break/Bordertown+4DP | 26KB |
| 纪录 | documentary-essay-film / documentary-nature-observational | Varda/Marker/Resnais/Herzog/Wiseman/Morris/Leviathan | 9-19KB |
| 超现实 | surrealism-dream-cinema | Bunuel/Cocteau/Svankmajer/Jodorowsky/Lynch | 19.5KB |
| 路由 | README | v23.0, 5维度路由表 | 62KB |
