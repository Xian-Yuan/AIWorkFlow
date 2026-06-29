# SALCSQ 提示词模板 — 统一输出格式

> 版本: v1.0 | 日期: 2026-06-29
> 状态: 可用
> 升级自: MCSLA六模块公式
> 用途: AI短剧提示词的统一输出格式，支持Kling/Seedance/Vidu/Wan自动适配
> 关联: ai-shortdrama-kb-workflow-integration-design.md(设计方案) / 镜头调度与摄影参数提示词速查手册.md(参数) / director-style-kb/(签名)

---

## 0. SALCSQ 速记

**S**ubject + **A**ction + **L**ighting + **C**amera + **S**tyle + **Q**uality

口诀: 主体 -> 动作 -> 光影 -> 镜头 -> 风格 -> 画质

与原MCSLA的差异:
- 新增 **A**(动作细节) -- 8通道情绪外化，解决"AI只会模糊动作"
- 新增 **Q**(画质约束) -- 质量后缀+负面提示词+物理真实感，防止AI翻车
- 合并 Camera+Composition+Vertical 为 **C**
- 合并 Lighting+Color 为 **L**

---

## 1. 通用骨架模板（所有工具通用）

```
# [情绪关键词] | [场景类型] | [时长]s | 9:16

## S - Subject 精准主体
[角色名], [2-3个稳定识别特征(脸型/发色/标志性服装/伤疤)].
[服装/铠甲完整描述], [手中道具/武器].
Stable: [不可改变的视觉锚点: 脸/发/服装/色板/道具].
Flexible: [可变化的: 表情/姿势/光线].

## A - Action 动作细节
[具体肢体动作, 用动词不用形容词].
[速度/强度: like embers in still air / like dust in honey / sudden as a gunshot].
[情绪外化8通道(选3-5个最关键的)]:
  breathing: [shallow/deep/ragged/holding/slow]
  eye: [darting/fixed/glistening/avoidant/distant]
  jaw: [clenched/relaxed/grinding/dropped]
  focus: [present/distant/staring-through/locked]
  scan: [sweeping/locked/avoidant/frantic]
  delay: [instant/slow/frozen/2-beat]
  control: [suppressing/steadying/failing/masked]
  residue: [afterglow/scar/echo/wetness]

## L - Lighting 光影色调
[光源类型+位置]: candle top-left / window behind / fireplace right / overcast sky
[色温]: 3200K warm / 5600K daylight / 8000K cold
[方向+阴影]: key from above-left, no fill, crushed blacks
[DP签名灯光]: Deakins single motivated key / Khondji sodium orange / Nykvist diffused
[调色板名称]: dungeon orange / icefield blue / cursed green / cathedral gold
[胶片模拟]: Kodak Vision3 500T / Kodak 250D / Ilford HP5 / Kodachrome

## C - Camera 镜头运镜
[景别]: ECU / CU / MCU / MS / WS / EWS
[焦段+光圈]: 14mm f/2.8 / 35mm f/4 / 85mm f/1.4 / 135mm f/2.8
[运镜]: locked / slow dolly in / lateral dolly / orbit 360 / handheld / tilt up
[角度]: eye level / low angle / high angle / dutch angle 15deg / overhead
[9:16竖屏]: vertical depth / upper-lower split / central vertical axis / framed by archway

## S - Style 视觉风格
[导演签名构图/叙事逻辑]: Kubrick symmetric / Fincher desaturated / Malick natural
[调色师签名色彩]: Bogdanowicz extreme dark / Poole austere / Fersti warm
[风格锚定词(全项目复用)]: cinematic dark fantasy / medieval gothic / sword and sorcery
[Seedance模式(如适用)]: Narrative / Studio / Action / Performance / Atmospheric

## Q - Quality 画质约束
4K, ultra HD, rich detail, sharp clarity, cinematic textures, stable picture.
Maintaining face and clothing consistency without distortion or high detail.
[物理真实感(选适用的)]:
  skin: subsurface scattering, no plastic face
  liquid: Fresnel reflection on water/blood/potion
  fabric: woven texture, anisotropic weave
  contact: hand grip physics, weight on surface
  anatomy: correct finger joints, natural proportions
  atmosphere: aerial perspective on distant objects
  bounce: indirect light, color spill in shadows
  micro: worn iron patina, stone scratches, armor dents
Negative: bright, cartoon, anime, blurry, deformed, watermark, text, logo, subtitles,
[工具特定修复词]
```

---

## 2. Seedance 格式模板

### 2.1 单镜头(5-10秒)

```
Seedance [Mode] mode,
[S-Subject], [A-Action],
[C-景别+焦段+光圈+运镜],
[L-DP签名+光源+调色板+胶片],
[S-风格锚定],
[Q-质量后缀+工具修复词],
9:16 vertical, cinematic
Negative: [Q-负面提示词]
```

### 2.2 多镜头分镜时序(10-15秒)

```
Seedance [Mode] mode,
[素材分配: @image1的[角色] + @image2的[场景]]

镜头 1：[C-运镜] + [S-主体]的[A-动作与表情] + [位置/空间] + [音频]
镜头 2：[C-运镜切换] + [A-动作变化] + [位置变化] + [音频]
镜头 3：[C-运镜] + [A-动作] + [位置] + [音频]

[L-整体光影: 风格/色调/光源规则]
[S-整体风格: 导演+风格锚定]
[Q-整体约束: 质量/稳定性/负面]
9:16 vertical, cinematic dark fantasy
```

---

## 3. Kling 格式模板

### 3.1 单镜头(6秒)

```
Scene: [S-Subject+L-Environment], [A-Action]
Characters: [S-角色稳定特征]
Action: [A-具体动作+情绪外化]
Camera: [C-运镜参数], camera_move=[参数]
Audio & Style: [L-光源+调色板], [S-导演签名+风格锚定], 9:16 vertical
Negative: [Q-负面提示词+工具修复词]
```

**Kling camera_move 对照**:

| 运镜 | 参数 |
|------|------|
| 推入 | camera_move=forward |
| 拉出 | camera_move=backward |
| 左横移 | camera_move=pan_left |
| 右横移 | camera_move=pan_right |
| 上升 | camera_move=up |
| 下降 | camera_move=down |
| 环绕 | camera_move=orbit |

---

## 4. Vidu 格式模板(简化版)

```
[S-Subject], [A-Action], [C-Simple Camera], [L-Lighting], [S-Style],
9:16 vertical, cinematic
Negative: blurry, deformed, watermark
```

**Vidu规则**: 100英文词以内，去掉复杂运镜，只保留Subject+Action+SimpleCamera+Lighting+Style

---

## 5. 中世纪西幻质量后缀库

### 5.1 通用质量后缀(每条必加)

```
4K, ultra HD, rich detail, sharp clarity, cinematic textures, stable picture.
Maintaining face and clothing consistency without distortion or high detail.
Generate the video without subtitles.
```

### 5.2 中世纪西幻专属后缀

```
worn iron patina, no plastic, grounded, weight on feet,
consistent style, no beautification,
no watermark, no logo, no text, no subtitles
```

### 5.3 工具特定修复词

| 工具 | 必贴修复词 | 含义 |
|------|----------|------|
| **Kling** | worn iron patina, no plastic, no fill, crushed blacks, no beautification | 防止铠甲塑料感、过亮、加填充光 |
| **Seedance** | restrained, subtle, realistic color, not stylized, measured movement | 防止过度风格化、动作过大 |
| **Vidu** | simple, stable, no complex motion | 防止复杂运动失败 |
| **Wan** | ControlNet-anchored, IP-Adapter reference, consistent composition | 强调ControlNet控制 |

### 5.4 场景特定修复词

| 场景 | 修复词 | 解决的问题 |
|------|--------|-----------|
| 骑士骑马 | real horse weight, grounded hooves | 马腿变形 |
| 双人对话 | separate generation + composite | 面部变形 |
| 战斗动作 | reference image anchor weapon | 武器位置错 |
| 手部特写 | avoid ECU hands, CU face + hand blur | 指节数错 |
| 远景人群 | single figure in vast landscape | 人群模糊 |
| 魔法效果 | silhouette/backlight instead of direct FX | 特效失败 |

### 5.5 情绪特定修复词

| 情绪 | 修复词 | 解决的问题 |
|------|--------|-----------|
| 恐惧/暗场景 | no fill, crushed blacks, let shadow be real | AI倾向加填充光 |
| 敬畏/巨物 | human 5% of frame, creature fills horizon | 巨物不够大 |
| 孤独/留白 | vast negative space, single figure, cold | AI倾向填满画面 |
| 愤怒/暴力 | handheld rough, no beautification, dirt | AI倾向太干净 |
| 悲伤/沉默 | hold 3-5 seconds, no score, let silence breathe | AI倾向太快 |

---

## 6. SALCSQ 快速组装公式

### 6.1 60秒标准组装(完整7帧)

```
# [情绪弧线] | [场景] | 60s | 9:16

## 钩子(0-3s) — ECU/CU震撼画面
S: [角色+2-3特征]
A: [情绪外化3通道] + [冲击动作]
L: [DP签名极端灯光]
C: [短焦+锁定或急推]
S: [导演签名+风格锚定]
Q: [质量后缀+工具修复]

## 建置(3-12s) — 建立序列 EWS->WS->MS
S: [角色在环境中]
A: [环境交互动作]
L: [场景主光源]
C: [建立序列运镜]
S: [世界建立风格]
Q: [质量后缀]

## 升级(12-30s) — 混合景别+动作
S: [角色+冲突元素]
A: [冲突动作+情绪升级]
L: [光线变化/色温偏移]
C: [混合运镜+景别变化]
S: [剪辑师签名节奏]
Q: [质量后缀+物理真实感]

## 高潮(30-48s) — 快切+慢动作交替
S: [角色极限状态]
A: [极限动作+8通道全开]
L: [极端灯光/唯一光源]
C: [快切+慢动作+手持]
S: [高潮风格+VFX]
Q: [质量后缀+特效修复]

## 收尾(48-60s) — 长持+沉默
S: [角色最终状态]
A: [残留情绪+延迟反应]
L: [最终色调定调]
C: [长持锁定或缓慢拉远]
S: [收尾风格+循环可能]
Q: [质量后缀]
```

### 6.2 15秒极简组装(4帧)

```
# [情绪] | [场景] | 15s | 9:16

帧1(0-3s)钩子: [C-景别]+[S-主体]+[A-冲击动作], [L-极端灯光], [Q-修复]
帧2(3-8s)升级: [C-运镜]+[A-冲突动作]+[L-色温偏移], [S-导演签名]
帧3(8-13s)高潮: [C-极限镜头]+[A-8通道全开]+[L-唯一光源], [Q-特效修复]
帧4(13-15s)收尾: [C-长持]+[A-残留情绪]+[L-最终色调], [Q-质量后缀]
```

### 6.3 5秒极速公式(1帧)

```
[情绪关键词] + [场景关键词] + [导演一句话签名] + [焦段+景别] + [9:16竖屏]
```

示例:
- 恐惧+地牢+Kubrick对称+35mm慢推+9:16
- 敬畏+巨龙+Villeneuve慢建立+14mm广角+9:16
- 悲壮+牺牲+Snyder慢动作+85mm逆光+9:16

---

## 7. 完整组装示例

### 7.1 骑士被宣判叛国(15秒, Seedance Studio)

**输入**: 情绪=压迫+绝望, 场景=地牢审讯

**SALCSQ分析**:
- S: knight in chains, weathered face, darkened plate armor, rust stains
- A: breathing deep and slow, eye fixed ahead, jaw clenched, hand suppressing tremor on chains
- L: Khondji sodium orange key from wall sconce, no fill, crushed blacks, dungeon orange palette, Vision3 500T
- C: 135mm f/2.8 MCU, slow lateral dolly right-to-left, narrow dungeon framing, 9:16 vertical depth
- S: Fincher-grade desaturated, cinematic dark fantasy
- Q: 4K ultra HD, maintaining face consistency, worn iron patina, no plastic, no beautification, no watermark

**Seedance输出**:
```
Seedance Studio mode,
A knight in chains, weathered face, darkened plate armor with rust stains,
breathing deep and slow, eye fixed ahead, jaw clenched, hand suppressing tremor on chains,
135mm f/2.8 MCU, slow lateral dolly right-to-left, narrow dungeon framing,
Khondji sodium orange key from wall sconce, no fill, crushed blacks,
dungeon orange palette, Kodak Vision3 500T,
Fincher-grade desaturated, cinematic dark fantasy,
4K, ultra HD, rich detail, sharp clarity, cinematic textures, stable picture,
maintaining face and clothing consistency without distortion,
worn iron patina, no plastic, grounded, weight on feet,
no beautification, no watermark, no logo, no subtitles,
9:16 vertical, cinematic dark fantasy.
```

### 7.2 巨龙出现(30秒, Kling+Seedance混合)

**SALCSQ分析**:
- S: lone knight on hill, blackened armor, sword planted
- A: breathing shallow, eye darting skyward, jaw clenched, delayed blink, control failing
- L: Villeneuve slow build, Lubezki natural, overcast turning red, icefield blue->warfire red, 250D->500T
- C: 14mm f/8 EWS -> 85mm f/1.4 ECU, locked -> slow tilt up, negative space above, 9:16
- S: Villeneuve-grade slow reveal, epic dark fantasy
- Q: 4K ultra HD, human 3% of frame, dragon fills horizon, no fill, grounded

**Kling帧1-3(钩子+建置)**:
```
Scene: Lone knight on hilltop, blackened armor, sword planted in stone, overcast sky
Characters: knight, weathered face, black plate armor
Action: standing still, looking up, breathing shallow
Camera: 14mm f/8 EWS, locked, negative space above, camera_move=none
Audio & Style: overcast icefield blue, Villeneuve slow build, epic dark fantasy, 9:16 vertical
Negative: bright, warm, cartoon, blurry, deformed, watermark, no fill, crushed blacks
```

**Seedance帧4-6(高潮+收尾)**:
```
Seedance Performance mode,
knight face lit by approaching fire, eye wide, jaw dropped, 
85mm f/1.4 ECU, slow tilt up from face to sky,
Lubezki natural, warm on face cold everywhere else, warfire red palette, Kodak 500T,
Villeneuve-grade, epic dark fantasy,
4K, ultra HD, maintaining face consistency, dragon fills horizon, human 3%,
no fill, grounded, no watermark, no subtitles,
9:16 vertical, cinematic dark fantasy.
```

---

> v1.0 初版: SALCSQ六模块+三层输出格式+质量后缀库+5种工具模板+2个完整示例
