# 抖音/短视频平台视觉语言知识库

> 类别: Douyin / Short-Form Video / Vertical Cinema / Platform-Native Visual Language
> 用途: 创作AI短剧时参考抖音平台特有的视觉语言、节奏模式和算法友好设计
> 关联: `director-style-kb/editor-signature-rhythm.md`(剪辑节奏), 主文档第5节(爆点钩子)

---

## 1. 抖音平台视觉法则

### 1.1 算法视觉偏好

| 法则 | 说明 | AI适配 |
|------|------|--------|
| 前3秒定生死 | 前3秒必须有视觉冲击/悬念/反转 | first 3 seconds: ECU or dramatic action, hook frame |
| 视觉密度 > 叙事密度 | 每秒必须有新信息/新画面 | visual density per second, no empty frames |
| 情绪曲线 > 叙事曲线 | 观众因为情绪停留不是因为故事 | emotion curve over narrative curve |
| 重复即强化 | 关键视觉/台词重复2-3次 | repetition of key visual/line 2-3 times |
| 中断即钩子 | 节奏中断=注意力重获 | rhythm interruption as attention hook |
| 面部 > 景观 | 面部特写点击率>远景2-3倍 | face close-up click rate > wide shot 2-3x |

### 1.2 9:16竖屏构图法则(补充速查手册第15节)

| 法则 | 说明 | AI提示词 |
|------|------|---------|
| 安全区法则 | 文字区(顶2行+底3行)不放关键内容 | safe zone, no key content in top 2 lines or bottom 3 lines |
| 三段式竖屏 | 上(环境)+中(人物)+下(地面/信息) | vertical thirds: top environment, mid character, bottom ground |
| 中心焦点法则 | 关键人物/物始终在中心1/3 | center 1/3 for key subject, vertical center focus |
| 纵深替代横宽 | 用纵深走廊/楼梯/道路替代横向广角 | depth replaces width, corridor/staircase/road for vertical depth |
| 天空大比例 | 天空占40-60%(竖屏天然适配) | sky 40-60%, natural vertical advantage |
| 底部人物法则 | 人物放在画面下方1/3(留出上方环境) | character in lower 1/3, environment above |

### 1.3 抖音转场技法

| 转场类型 | 操作 | AI提示词 | 情绪效果 |
|----------|------|---------|---------|
| 遮挡转场 | 手/物遮挡镜头→下一场景 | hand/obj cover lens transition | 连续/流畅 |
| 甩镜转场 | 快速横摇→下一场景 | whip pan transition | 快节奏/能量 |
| 匹配转场 | 动作/形状/颜色匹配 | match cut transition | 流畅/美感 |
| 闪白转场 | 白闪→下一场景 | flash white transition | 震惊/时间跳 |
| 闪黑转场 | 黑闪→下一场景 | flash black transition | 沉重/时间跳 |
| 变速转场 | 慢→快→切 | speed ramp transition | 节奏感 |
| 声音转场 | 声音先于画面进入 | J-cut audio transition | 预期/连接 |
| 文字转场 | 文字卡片/章节 | text card transition | 结构/间隔 |

---

## 2. 抖音热门AI短剧视觉模式(2026)

### 2.1 六大热门视觉模式

| 模式 | 视觉特征 | 代表作品 | AI提示词锚定 |
|------|---------|---------|------------|
| 电影感暗黑 | 去饱和+深暗+唯一暖光+电影宽荧幕感 | 西幻/暗黑类型 | cinematic dark, desaturated, sole warm, film-grade |
| 水彩梦幻 | 柔散+过曝+自然饱和+水彩质感 | 精灵/童话类型 | watercolor dream, soft diffusion, overexposed, natural saturation |
| 漫画风风格化 | 高对比+色块+轮廓线+极饱和 | 战斗/热血类型 | comic style, high contrast, color blocks, outline, extreme saturation |
| 纪实粗粝 | 手持+自然光+颗粒+不完美 | 末日/战争类型 | documentary gritty, handheld, natural light, grain, imperfect |
| 赛博暗夜 | 霓虹+深黑+反射+蓝红对比 | 都市奇幻类型 | cyber night, neon, deep black, reflection, blue-red contrast |
| 东方水墨 | 水墨+留白+线条+去饱和 | 仙侠/武侠类型 | ink wash, blank space, line art, desaturated, Eastern aesthetic |

### 2.2 抖音AI短剧节奏模式

| 节奏模式 | 特征 | 每分钟镜头数 | AI提示词 |
|----------|------|------------|---------|
| 极速模式 | 每镜0.5-1秒+快切+闪帧 | 40-60个/分钟 | extreme fast cut, 0.5-1s per shot, flash frames |
| 高能模式 | 每镜1-2秒+快切+动作 | 25-35个/分钟 | high energy cut, 1-2s per shot, action rhythm |
| 叙事模式 | 每镜2-3秒+混合+对话 | 15-25个/分钟 | narrative cut, 2-3s per shot, dialogue rhythm |
| 沉浸模式 | 每镜3-5秒+长镜+慢推 | 8-15个/分钟 | immersive cut, 3-5s per shot, slow push rhythm |
| 极简模式 | 每镜5-8秒+极少切+锁定 | 5-8个/分钟 | minimal cut, 5-8s per shot, locked observation |

---

## 3. 中世纪西幻抖音专用场景库

### 3.1 15秒单场景(抖音最短有效叙事)

| 场景 | 镜头分解 | 提示词公式 |
|------|---------|-----------|
| 骑士拔剑 | ECU手(0.5s)→ECU剑柄(0.5s)→CU慢拉(1s)→MS金属光(1s)→WS高举(2s) | `ECU hand→ECU hilt→CU slow draw→MS metal gleam→WS raise high, sword draw 15s` |
| 魔法施放 | CU手(0.5s)→ECU眼(0.5s)→MCU光(1s)→WS环境反应(2s)→WS全景(1s) | `CU hand→ECU eye→MCU magic light→WS environment reaction→WS full, spell cast 15s` |
| 诅咒发作 | CU正常(1s)→CU微变(1s)→CU加剧(1s)→MCU失控(2s)→CU极端(1s) | `CU normal→CU subtle shift→CU escalating→MCU out of control→CU extreme, curse 15s` |
| Boss现身 | ECU环境异变(1s)→CU地面(1s)→MS阴影(1s)→WS局部(1s)→EWS全身(1s) | `ECU environment shift→CU ground→MS shadow→WS partial→EWS full body, boss reveal 15s` |

### 3.2 60秒完整微剧(抖音标准)

| 段落 | 时间 | 镜头 | 风格参考 |
|------|------|------|---------|
| 钩子 | 0-3秒 | 2-3个快切+ECU | Sixel极速 |
| 建置 | 3-12秒 | 4-5个MS/WS | Jackson建立 |
| 升级 | 12-30秒 | 6-8个混合 | Smith交叉 |
| 高潮 | 30-48秒 | 5-7个快+慢交替 | Schoonmaker音乐驱 |
| 钩子(下集) | 48-60秒 | 2-3个长+沉默 | Walker长持+沉默 |

### 3.3 中世纪西幻抖音视觉模板

**模板A: 暗黑骑士(15秒)**
```
shot 1: ECU eye, dark, sole firelight reflection, 0.5s
shot 2: CU gauntlet clenching, metal texture, 0.5s
shot 3: MCU sword on shoulder, torchlight, 1s
shot 4: WS walking through corridor, one-point perspective, 2s
shot 5: EWS standing before dark throne, tiny figure, massive architecture, 3s
grade: Bogdanowicz-grade, extreme dark, cold blue base, sole fire warm
style: Kubrick+Eggers+FromSoft, symmetric, candle-only, environmental storytelling
```

**模板B: 精灵森林(15秒)**
```
shot 1: ECU leaf with dew, macro, backlit, 0.5s
shot 2: CU hand touching moss, natural light, 0.5s
shot 3: MS figure among ancient trees, volumetric light, 2s
shot 4: WS forest cathedral, light shafts, 3s
shot 5: EWS figure tiny in vast forest, sky 50%, 4s
grade: Fersti-grade, natural saturation, green+gold, watercolor soft
style: Malick+Miyazaki+Zelda, golden hour, natural scatter, wonder
```

**模板C: 诅咒村庄(15秒)**
```
shot 1: ECU eye wide with fear, candlelight, 0.5s
shot 2: CU hand trembling, holding cross/talisman, 0.5s
shot 3: MS dark doorway, fog entering, 2s
shot 4: WS village street, fog, yellow-green, sole window light, 3s
shot 5: EWS village surrounded by dark forest, fog, desolation, 4s
grade: Bogdanowicz-grade, desaturated yellow-green, blood red accent, corruption
style: Na Hong-jin+Eggers+Herzog, fog, multiple faiths, evil unsolvable
```

---

## 4. 抖音视觉与知识库交叉速查

| 抖音视觉需求 | 查本KB | 查其他KB |
|------------|--------|---------|
| 转场技法 | 1.3节(8种转场) | quickcut-comedy-lowbudget(Wright匹配剪辑) |
| 竖屏构图 | 1.2节(6法则) | 速查手册15节(9:16专用规则) |
| 节奏模式 | 2.2节(5种节奏) | editor-signature-rhythm(6位剪辑师) |
| 调色选择 | — | colorist-signature-grade(5位调色师) |
| 场景序列 | 3.1-3.3节(模板) | storyboard-visual-planning(10种序列+10种西幻序列) |
| 视觉风格 | 2.1节(6大模式) | 所有KB(导演风格驱动) |
| 前3秒钩子 | 1.1节+3.1节 | 主文档5.1节(抖音专用钩子模式) |


---

## 5. 竖屏优先设计方法论(2026更新)

### 5.1 竖屏不是裁切——竖屏是一种全新的视觉语法

| 横屏思维 | 竖屏思维 | 为什么要转变 |
|---------|---------|-----------|
| 水平展开叙事 | 垂直展开叙事 | 手机竖着拿，眼睛上下扫 |
| 左右双人对话 | 前后景/上下双人 | 水平空间不够 |
| 三分法(左中右) | 垂直三分(上中下) | 竖屏的三分是纵向的 |
| 宽广地平线 | 高耸纵深 | 竖屏天然适合高事物 |
| 横移展示空间 | 升降/推拉展示空间 | 9:16中横移不如升降有效 |
| 双人平等构图 | 不对等(一上一下/一前一后) | 竖屏可以强化权力不对等 |

### 5.2 竖屏视觉黄金区

| 区域 | 位置 | 百分比 | 放什么 | 避免放什么 |
|------|------|--------|--------|-----------|
| 注意力热点 | 画面上30%-60% | 30% | 人脸/表情/手部/关键动作 | 文字/水印 |
| 叙事展开区 | 画面中40%-80% | 40% | 身体/武器/动作/互动 | 重要细节(会被忽略) |
| 环境氛围区 | 画面上15%/下20% | 35% | 天空/地面/建筑顶部 | 关键剧情信息 |
| 安全区 | 上下各10%+左右各5% | 30% | 留白/背景/氛围 | 文字/人脸/关键信息 |

### 5.3 竖屏情绪构图的六种原型

| 原型 | 构图 | 情绪 | 提示词 | 西幻场景 |
|------|------|------|--------|---------|
| 瞻仰型 | 人物底部20%/建筑/天空80% | 敬畏/渺小 | figure bottom 20%, architecture sky 80%, vertical reverence, 9:16 | 骑士仰望大教堂 |
| 压迫型 | 天花板/敌人占70%/人物被压30% | 压迫/被困 | ceiling/enemy 70%, figure crushed at bottom 30%, vertical oppression, 9:16 | 审判官俯视骑士 |
| 孤独型 | 人物居中极小/负空间70% | 孤独/宿命 | figure centered tiny, negative space 70%, vertical solitude, 9:16 | 荒原上的骑士 |
| 亲密型 | 面部占60%+浅景深 | 亲密/聚焦 | face 60% frame, shallow DOF, vertical intimacy, 9:16 | 角色表情特写 |
| 旅途型 | 人物中下/道路/走廊向上延伸 | 旅途/选择 | figure mid-lower, path/corridor extends upward, vertical journey, 9:16 | 走廊尽头的光 |
| 权力型 | 人物上半/俯视下方/下方是臣民或战场 | 权力/掌控 | figure upper portion, looking down, subjects/battlefield below, vertical power, 9:16 | 国王从塔楼俯瞰 |

---

## 6. 抖音3秒钩子西幻模板(2026更新)

### 6.1 8种3秒钩子西幻版本

| 钩子类型 | 3秒画面 | 声音 | 提示词 |
|---------|---------|------|--------|
| 恐惧钩子 | ECU眼+瞳孔放大+背景阴影移动 | 低频嗡鸣+心跳 | ECU eye dilating, shadow moves behind, low drone+heartbeat, 9:16, horror hook |
| 力量钩子 | 低角度+铠甲反光+逆光+武器出现 | 金属+低弦乐 | low angle armor reflects, backlight, weapon appears, metal+low strings, 9:16, power hook |
| 悬念钩子 | 手打开古卷/门缓缓开/光从裂缝 | 吱呀+沉默 | hand opens ancient scroll, door cracks, light from gap, creak+silence, 9:16, suspense hook |
| 美学钩子 | 极饱和+奇特构图+超现实 | 音乐突起 | hyper-saturated, strange composition, surreal, music hits, 9:16, aesthetic hook |
| 反转钩子 | 正常然后不正常(微笑太长/物体自移) | 静到不和谐音 | normal then uncanny, smile too long, object moves itself, silence to dissonance, 9:16, reversal hook |
| 暴力钩子 | 突然暴力+血+极近 | 音效+沉默 | sudden violence, blood, extreme close-up, impact SFX+silence, 9:16, violence hook |
| 魔法钩子 | 手+光+环境反应(花开放/石浮起) | 魔法音效+升调 | hand+light, environment reacts, flower blooms/stone floats, magic SFX+ascending, 9:16, magic hook |
| 禁忌钩子 | 面部半明半暗+嘴唇动+说出禁词 | 耳语+回响 | half-face light, lips move, speak forbidden word, whisper+reverb, 9:16, forbidden hook |

### 6.2 60秒完整西幻脚本模板(2026版)

- 0-3s: 钩子(恐惧型) - ECU眼+阴影移动+低频嗡鸣
- 3-8s: 建立 - WS城堡+雨+闪电+冷蓝调
- 8-15s: 角色 - MCU骑士+雨湿铠甲+手握剑柄
- 15-25s: 冲突 - MS对手出现+逆光+火把光+暖冷分割
- 25-35s: 升级 - CU表情+呼吸变化+慢推入+音乐渐强
- 35-45s: 高潮 - 慢动作+魔法/剑光+极亮+色彩突变
- 45-55s: 余韵 - 静止+呼吸+极慢拉出+环境音回归
- 55-60s: 钩下集 - 一个神秘元素+黑屏+悬念音

调色板: 铁与血(深铁灰+血红+碎黑)
导演锚: Kubrick+Deakins(对称+单光)
DP灯光: Deakins窗光+负填充
运镜: 缓慢推入+锁定+最终慢拉
负面词: bright, cartoon, anime, blurry, deformed, watermark
