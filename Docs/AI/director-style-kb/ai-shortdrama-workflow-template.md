# AI短剧完整工作流提示词模板

> 版本: v1.0 | 日期: 2026-06-29
> 类别: Workflow Template / Integrated Pipeline / Creation-to-Output
> 用途: 从零开始制作一条中世纪西幻AI短视频的完整工作流，每一步都有可粘贴的提示词
> 关联: ai-prompt-to-result-patterns.md(情绪-提示词映射) / prompt-assembly-guide.md(六步法) / 镜头调度与摄影参数提示词速查手册.md(参数参考) / short-video-hook-practice.md(钩子实战)

---

## 0. 工作流总览

`
创意(情绪+场景) → 路由(查KB找风格) → 分镜(每帧构图) → 提示词(组装+适配) → 生成(AI工具) → 修复(偏差诊断) → 发布(竖屏+节奏)
`

每一步对应本模板的一个章节，从章节1开始逐步执行即可。

---

## 1. 创意阶段: 确定情绪+场景(2分钟)

### 1.1 从20种核心情绪中选择

| 类别 | 情绪列表 |
|------|---------|
| 核心情绪(查ai-prompt-to-result-patterns第1节) | 恐惧/敬畏/孤独/愤怒/悲伤/神秘/浪漫/权力/绝望/魔法 |
| 次级情绪(查第2节) | 忠诚/背叛/野心/悔恨/狂热/虔诚/嫉妒/牺牲/崇拜/复仇 |

### 1.2 从20种核心场景中选择

| 类别 | 场景列表 |
|------|---------|
| 战斗与冲突 | 骑士冲锋/围城战/近身格斗/龙焰降临/战场沉默 |
| 权力与阴谋 | 王座加冕/暗杀密谋/审判宣判/宫廷宴会/权力交接 |
| 旅途与探索 | 踏上旅途/进入地下城/森林迷路/攀登高峰/废墟发现 |
| 超自然与魔法 | 魔法觉醒/诅咒显现/预言幻象/精灵领地/亡灵出现 |
| 人物与情感 | 告别/誓言/背叛揭露/独自疗伤/父子传承 |

### 1.3 快速创意公式

`
[情绪] + [场景] + [时长] = 创意种子
例: 背叛 + 暗杀密谋 + 15秒 = "黑暗中的低语"
`

---

## 2. 路由阶段: 查KB找风格(3分钟)

### 2.1 情绪→导演签名速查

| 情绪 | 导演签名 | DP签名 | 调色板 | KB文件 |
|------|---------|--------|--------|--------|
| 恐惧 | Kubrick+Eggers | Deakins | 诅咒绿 | horror-dark-directors |
| 敬畏 | Villeneuve+Tarkovsky | Lubezki | 冰原蓝 | fantasy-epic-directors |
| 孤独 | Bergman+Malick | Nykvist | 荒原灰 | european-masters |
| 权力 | Nolan+Kubrick | van Hoytema | 圣殿金光 | crime-thriller-directors |
| 魔法 | Villeneuve+del Toro | - | 暮色紫 | fantasy-epic-directors |
| 背叛 | Fincher+Hitchcock | Khondji | 诅咒绿-荒原灰 | crime-noir-urban |
| 牺牲 | Malick+Lean | Deakins | 冰原蓝+唯一暖 | war-history-drama |
| 悲伤 | Tarkovsky+Wong Kar-wai | Doyle | 荒原灰 | european-masters |
| 愤怒 | Evans+Stahelski | - | 战火红 | action-martial |
| 神秘 | del Toro+Lynch | Navarro | 暮色紫 | surrealism-dream-cinema |

### 2.2 场景→完整提示词链速查

直接查 ai-prompt-to-result-patterns.md 第3节(20个场景完整链)

---

## 3. 分镜阶段: 每帧构图设计(10分钟)

### 3.1 时长→帧数规划

| 时长 | 钩子帧 | 建置帧 | 升级帧 | 高潮帧 | 收尾帧 |
|------|--------|--------|--------|--------|--------|
| 60秒 | 1帧(0-3s) | 2帧(3-12s) | 3帧(12-30s) | 2帧(30-48s) | 1帧(48-60s) |
| 15秒 | 1帧(0-3s) | 1帧(3-6s) | 1帧(6-10s) | 1帧(10-13s) | 1帧(13-15s) |

### 3.2 每帧决策清单

对每一帧，填入以下6项:

| 决策维度 | 选项来源 | 对应镜头手册章节 |
|---------|---------|---------------|
| 1.景别 | ECU/CU/MCU/MS/WS/EWS | 第3节+第22节 |
| 2.焦段+光圈 | 14-200mm + f/1.4-f/16 | 第4节+第27节 |
| 3.运镜 | 推/拉/移/升/环绕/手持/锁定 | 第1节 |
| 4.构图 | 中心/偏置/框中框/负空间/对称 | 第8节+第21节+第30节 |
| 5.灯光 | 烛光/逆光/伦勃朗/顶光/底光 | 第13节 |
| 6.调色板 | 12种西幻调色板 | 第29节 |

### 3.3 竖屏9:16适配检查

每帧设计完成后检查:
- [ ] 水平运动改为垂直运动(升/降)
- [ ] 左右对称改为上下对称
- [ ] 横向三分法改为纵向三分法
- [ ] OTS对切改为上下分层
- [ ] 环境广角改为垂直纵深

---

## 4. 提示词组装阶段(5分钟)

### 4.1 单帧提示词标准格式

`
[焦段] [光圈] [景别], [主体描述], [运镜], [灯光], [调色板], [导演签名], [AI偏差修复], [竖屏标记], 9:16
`

### 4.2 组装示例

**创意**: 背叛 + 暗杀密谋 + 15秒

帧1 (0-3s) 钩子:
`
85mm f/2.0 MCU, two figures in candlelit room, locked camera, Khondji sodium orange, tavern warmth palette, Fincher desaturated, no beautification, 9:16
`

帧2 (3-8s) 升级:
`
50mm f/2.8, one whispers in other's ear, progressive close-in, candle gutters, warm surface cold undertow, 9:16
`

帧3 (8-13s) 高潮:
`
85mm f/1.4, dutch angle 15deg, knife revealed, cold shift, cursed green palette bleeding in, shadow on face, no fill, 9:16
`

帧4 (13-15s) 收尾:
`
135mm f/2.8, compressed isolation, cold realization, dungeon orange palette, hard cut to black, 9:16
`

### 4.3 AI偏差修复速贴

每次组装完提示词后，根据使用的AI工具粘贴对应修复词:

**Kling必贴**: worn iron patina, no plastic, no fill, crushed blacks, no beautification
**Seedance必贴**: 
estrained, subtle, realistic color, not stylized, measured movement
**通用必贴**: consistent style, same director signature, same palette, grounded, weight on feet

---

## 5. 生成阶段(5分钟)

### 5.1 工具选择决策

| 需求 | 首选工具 | 原因 |
|------|---------|------|
| 暗场景/强风格 | Kling | 风格化能力强 |
| 写实/微妙情绪 | Seedance | 电影质感好 |
| 快速迭代 | Vidu | 速度快 |
| 广角大场景 | Wan | 场景理解好 |

### 5.2 每个工具的最佳提示词结构

**Kling**: 场景描述 + 风格标记 + 导演签名 + 调色板 + 修复词
**Seedance**: 电影模式 + 焦段光圈 + 微妙情绪 + 修复词
**Vidu**: 简洁描述 + 核心关键词
**Wan**: 场景+氛围+构图

详见 ai-video-tool-prompting.md

---

## 6. 修复阶段: 偏差诊断(3分钟)

### 6.1 常见问题快速诊断

| 问题 | 首先检查 | 修复 |
|------|---------|------|
| 太亮 | 是否有no fill/crushed blacks | 添加灯光修复词 |
| 太美 | 是否有no beautification | 添加真实感修复词 |
| 铠甲塑料 | 是否有worn iron/no plastic | 添加材质修复词 |
| 颜色不对 | 是否指定了调色板 | 添加调色板提示词 |
| 运动假 | 是否有grounded/weight on feet | 添加物理锚定词 |
| 风格漂移 | 是否有consistent style | 添加风格锚定词 |

### 6.2 情绪不对时的深度诊断

1. 查 ai-prompt-to-result-patterns.md 第1-3节: 焦段+光圈+构图+调色板是否匹配
2. 查镜头手册第27节: 焦段是否对应了正确的心理姿态
3. 查镜头手册第30节: 构图公式是否匹配目标情绪
4. 查镜头手册第29节: 调色板是否匹配情绪DNA

---

## 7. 发布阶段: 竖屏+节奏(2分钟)

### 7.1 3秒钩子检查

- [ ] 第一帧是否有强烈视觉钩子(ECU/极暗/巨物/剪影)
- [ ] 前3秒是否建立了情绪基调
- [ ] 是否避免了缓慢开场(短视频前3秒决定留存)

### 7.2 节奏检查

| 时长 | 节奏模式 | 检查项 |
|------|---------|--------|
| 15秒 | 钩子-升级-高潮-悬念 | 3s-6s-10s-13s |
| 30秒 | 钩子-建置-升级-高潮-收尾 | 3s-8s-15s-22s-28s |
| 60秒 | 钩子-建置-升级-高潮-收尾 | 3s-12s-30s-48s-58s |

### 7.3 竖屏最终检查

- [ ] 所有提示词包含9:16标记
- [ ] 水平运动已转为垂直运动
- [ ] 人物在画面中有足够大小(竖屏人更小)
- [ ] 垂直纵深利用充分(走廊/塔/树)

---

## 8. 全流程速查一页纸

`
1. 创意: [情绪]+[场景]+[时长] ← 本模板1节
2. 路由: 查KB找导演+DP+调色板 ← 本模板2节/README路由表
3. 分镜: 每帧6维度(景别/焦段/运镜/构图/灯光/调色) ← 本模板3节
4. 组装: 焦段+光圈+景别+主体+运镜+灯光+调色板+签名+修复+9:16 ← 本模板4节
5. 生成: 选工具+贴修复词 ← 本模板5节
6. 修复: 诊断问题+查映射表 ← 本模板6节
7. 发布: 钩子+节奏+竖屏 ← 本模板7节
`

---

> v1.0 初版: 完整7阶段工作流，从创意到发布每一步都有可操作指引。与ai-prompt-to-result-patterns.md(映射表)+prompt-assembly-guide.md(六步法)+镜头调度手册(参数)配合使用。

---

## 9. 情绪弧线设计模板(10种)

> 核心原则: 每条短视频都是一条情绪弧线，不是画面堆叠

### 9.1 经典情绪弧线(5种)

| 弧线类型 | 情绪走向 | 适用时长 | 提示词编码 | 西幻场景 |
|---------|---------|---------|-----------|---------|
| 上升弧(英雄崛起) | 低→高→最高 | 30-60s | emotional arc: low→high→peak, rising, triumph | 骑士觉醒/加冕/拔剑 |
| 下降弧(悲剧坠落) | 高→低→最低 | 30-60s | emotional arc: high→low→abyss, falling, tragedy | 背叛/牺牲/王国陨落 |
| V弧(黑暗后黎明) | 高→最低→高 | 30-60s | emotional arc: high→nadir→rise, dark before dawn | 囚禁→逃脱/失败→觉醒 |
| 倒V弧(繁华后崩塌) | 低→最高→低 | 30-60s | emotional arc: low→peak→crash, hubris fall | 胜利→诅咒/加冕→疯狂 |
| 波浪弧(循环呼吸) | 起→伏→起→伏 | 60s | emotional arc: wave, rise-fall-rise-fall, cyclical | 旅途/探索/修行 |

### 9.2 短视频爆款情绪弧线(5种)

| 弧线类型 | 情绪走向 | 适用时长 | 提示词编码 | 爆款原理 |
|---------|---------|---------|-----------|---------|
| 钩子-悬念弧 | 震惊→好奇→更震惊→断 | 15s | hook-suspense arc, shock→curiosity→shock→cut | 好奇心驱动完播 |
| 反转弧 | A→B→反转B | 15-30s | reversal arc, A→B→reverse B, twist | 反转=讨论=传播 |
| 情绪炸弹 | 平→平→爆 | 15s | emotion bomb arc, flat→flat→burst, delayed climax | 延迟满足=爆发力 |
| 禁忌弧 | 偷窥→紧张→暴露 | 15-30s | forbidden arc, voyeur→tension→exposure | 禁忌=吸引力 |
| 循环弧 | 结尾=开头 | 15s | loop arc, end=beginning, infinite cycle | 循环播放=高完播 |

---

## 10. 完整场景工作流实例(3条)

> 从创意到发布的完整实战演示

### 10.1 实例1: 背叛(15秒)

**创意种子**: 背叛 + 暗杀密谋 + 15秒 = 黑暗中的低语

| 阶段 | 输出 |
|------|------|
| 路由 | 导演: Fincher + DP: Khondji + 调色板: 去饱和+钠橙 + KB: crime-noir-urban |
| 帧1(0-3s)钩子 | 85mm f/2.0 MCU, two figures in candlelit room, locked camera, Khondji sodium orange, tavern warmth palette, Fincher desaturated, no beautification, 9:16 |
| 帧2(3-8s)升级 | 50mm f/2.8, one whispers in other ear, progressive close-in, candle gutters, warm surface cold undertow, 9:16 |
| 帧3(8-13s)高潮 | 85mm f/1.4, dutch angle 15deg, knife revealed, cold shift, cursed green palette bleeding in, shadow on face, no fill, 9:16 |
| 帧4(13-15s)收尾 | 135mm f/2.8, compressed isolation, cold realization, dungeon orange palette, hard cut to black, 9:16 |
| 生成 | Kling(暗场景首选), 贴: worn iron patina, no plastic, no fill, crushed blacks, no beautification |
| 修复检查 | 太亮?→+no fill; 太美?→+no beautification; 颜色偏?→+Khondji sodium orange |
| 发布 | 3s钩子: 蜡烛+暗室+窃语; 节奏: 钩子-悬念弧; 竖屏: 垂直纵深走廊 |

### 10.2 实例2: 龙吼逼近(30秒)

**创意种子**: 敬畏 + 龙焰降临 + 30秒 = 天空在燃烧

| 阶段 | 输出 |
|------|------|
| 路由 | 导演: Villeneuve + DP: Lubezki + 调色板: 冰原蓝+唯一暖 + KB: fantasy-epic-directors |
| 帧1(0-3s)钩子 | 24mm f/8 WS, sky darkening, lone figure on hill, locked, Villeneuve slow build, ice blue sky, 9:16 |
| 帧2(3-8s)建置 | 35mm f/4 MS, knight looking up, slow tilt up, sky turning red at horizon, Lubezki natural, 9:16 |
| 帧3(8-18s)升级 | 50mm f/2.8, ground tremor, horse panics, negative space above, sub-bass rumble, sky split by fire, 9:16 |
| 帧4(18-23s)反转 | 85mm f/1.4 ECU, knight face lit by approaching fire, warm on face cold everywhere else, speed ramp to slow, 9:16 |
| 帧5(23-27s)高潮 | 14mm f/2.8 EWS, dragon silhouette against burning sky, colossal scale, tiny human, jaw opening, 9:16 |
| 帧6(27-30s)收尾 | 200mm f/2.8, compressed fire, ECU knight eyes reflecting flame, cut to black, 9:16 |
| 生成 | Wan(广角大场景首选), Kling(高潮帧) |
| 发布 | 钩子-悬念弧+巨物镜头 |

### 10.3 实例3: 魔法觉醒(60秒)

**创意种子**: 魔法 + 魔法觉醒 + 60秒 = 她不知道自己是什么

| 阶段 | 输出 |
|------|------|
| 路由 | 导演: del Toro + DP: Navarro + 调色板: 暮色紫+琥珀 + KB: fantasy-epic-directors |
| 帧1(0-3s)钩子 | 85mm f/1.4 ECU, closed eyes, single candle, Navarro amber, del Toro tactile, 9:16 |
| 帧2(3-8s)建置 | 50mm f/2.8 MCU, girl in ancient library, locked, dusty tomes, candle rows, twilight purple, 9:16 |
| 帧3(8-18s)升级 | 35mm f/2.0, hands touching glowing rune, progressive close, light from book, warm cold intersection, 9:16 |
| 帧4(18-28s)发展 | 24mm f/4, room shifting, books floating, particles rising, volumetric light bloom, prismatic, 9:16 |
| 帧5(28-38s)转折 | 50mm f/2.8, her face half-lit half-shadow, eyes opening, gold iris, power awakening, 9:16 |
| 帧6(38-48s)高潮 | 14mm f/2.8, entire room transformed, light explosion, overexposed center, particles everywhere, 9:16 |
| 帧7(48-55s)释放 | 85mm f/1.4 ECU, her face serene, power controlled, soft glow, gold+purple, 9:16 |
| 帧8(55-60s)收尾 | 135mm f/2.8, library restored, single book glowing, hold, loop-connect to candle, 9:16 |
| 生成 | Seedance(微妙情绪帧)+Kling(魔法效果帧) |
| 发布 | V弧(压抑→觉醒→释放)+循环结尾 |

---

## 11. AI工具差异化工单模板

> 每个AI工具的性格不同，同一个创意需要不同工单

### 11.1 Kling专用工单

`
[场景描述], [风格标记: cinematic dark fantasy / medieval gothic / sword sorcery],
[导演签名], [调色板], [灯光: sole warm source, no fill, crushed blacks],
[材质: worn iron patina, no plastic, scratched metal],
[修复: no beautification, grounded, weight on feet, consistent style]
9:16 vertical
`

**Kling强项**: 暗场景/强风格/魔法效果/铠甲质感
**Kling弱项**: 微妙表情/缓慢运动/写实光影
**Kling必贴修复词**: worn iron patina, no plastic, no fill, crushed blacks, no beautification

### 11.2 Seedance专用工单

`
cinematic mode, [焦段] [光圈] [景别],
[微妙情绪描述], [演员式指导],
[灯光: practical light motivated, motivated source],
[调色: restrained, realistic color, not stylized],
[修复: measured movement, subtle performance]
9:16 vertical
`

**Seedance强项**: 微妙情绪/写实质感/电影光/演员式表演
**Seedance弱项**: 大范围魔法效果/极端暗场景/高速运动
**Seedance必贴修复词**: restrained, subtle, realistic color, not stylized, measured movement

### 11.3 Wan专用工单

`
[场景+氛围], [构图: wide angle, aerial, vast landscape],
[环境: castle, dungeon, forest, mountain],
[规模: tiny human in vast space, colossal architecture],
[调色: natural, desaturated],
9:16 vertical
`

**Wan强项**: 广角大场景/环境理解/建筑空间/史诗感
**Wan弱项**: 人物表演/暗场景/风格化

### 11.4 Vidu专用工单

`
[简洁描述+核心关键词], [动作: simple clear action],
[风格: cinematic / realistic / stylized],
9:16 vertical
`

**Vidu强项**: 快速迭代/简单动作/人物运动
**Vidu弱项**: 复杂场景/强风格

---

## 12. 品控检查清单(7项)

> 每条视频发布前逐项检查

### 12.1 视觉一致性检查

| # | 检查项 | 通过标准 | 不通过修复 |
|---|--------|---------|-----------|
| 1 | 调色板一致 | 全片同一种调色板关键词 | 重查第29节调色板表 |
| 2 | 导演签名一致 | 全片同一导演签名组合 | 重查KB路由表 |
| 3 | 材质一致 | 铠甲/布料/石墙质感统一 | 添加worn iron/no plastic |
| 4 | 光源逻辑一致 | 光源方向和色温可追溯 | 重新设计灯光词 |
| 5 | 人物一致 | 同一角色外观无漂移 | 添加character consistency锚点 |

### 12.2 情绪完整性检查

| # | 检查项 | 通过标准 | 不通过修复 |
|---|--------|---------|-----------|
| 6 | 情绪弧线完整 | 有清晰的起承转合 | 重查情绪弧线模板 |
| 7 | 钩子有效 | 前3秒有强烈视觉冲击 | 重查3s钩子检查 |

### 12.3 竖屏适配检查

| # | 检查项 | 通过标准 | 不通过修复 |
|---|--------|---------|-----------|
| 8 | 所有帧9:16 | 每帧提示词含9:16 | 批量添加 |
| 9 | 垂直纵深利用 | 有走廊/塔/树等垂直元素 | 替换水平元素 |
| 10 | 人物大小足够 | 竖屏中人物不小于画面1/4 | 调整景别+焦段 |

---

## 13. 进阶技巧: 跨帧一致性锚定

> 核心问题: AI生成的每一帧都是独立的，如何让它们属于"同一部电影"

### 13.1 一致性锚定5层

| 层 | 锚定方法 | 提示词 |
|----|---------|--------|
| 1.调色板锚 | 全片同一调色板关键词 | same palette: dungeon orange desaturated |
| 2.导演锚 | 全片同一导演签名 | same director: Fincher+Khondji signature |
| 3.灯光锚 | 全片同一灯光逻辑 | same lighting: sole candle, no fill, motivated |
| 4.材质锚 | 全片同一材质描述 | same material: worn iron, no plastic, scratched |
| 5.空间锚 | 全片同一空间描述 | same location: stone dungeon corridor, wet walls, torch |

### 13.2 锚定组合模板

**暗黑权力剧锚定包**:
`
same palette: dungeon orange desaturated, same director: Kubrick+Eggers+Deakins,
same lighting: sole warm source no fill crushed blacks, same material: worn iron patina no plastic,
same location: stone castle throne room, consistent style, 9:16
`

**精灵梦幻锚定包**:
`
same palette: forest green gold soft, same director: Malick+Miyazaki+Lubezki,
same lighting: natural diffused volumetric canopy, same material: organic natural elven,
same location: ancient forest glade, consistent style, 9:16
`

**冰原维京锚定包**:
`
same palette: ice blue white desaturated, same director: Eggers+Lubezki+Deakins,
same lighting: overcast no warmth snow reflection, same material: fur leather iron frost,
same location: arctic tundra viking settlement, consistent style, 9:16
`

---

> v2.0 深化版: +情绪弧线设计模板(10种)+完整场景工作流实例(3条)+AI工具差异化工单模板(4种)+品控检查清单(10项)+跨帧一致性锚定(5层+3锚定包)
