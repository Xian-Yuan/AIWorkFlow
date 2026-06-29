# AI 短剧质量后缀库 — 每条提示词必加

> 版本: v1.0 | 日期: 2026-06-29
> 状态: 可用
> 来源: lanshu-awesome-ai-video-kit(质量后缀概念) + 本地知识库(修复词) + 实战经验
> 用途: 每条AI视频提示词都必须追加质量后缀，这是防止AI翻车的保险绳
> 关联: ai-shortdrama-salcsq-template.md(SALCSQ模板) / ai-video-tool-prompting.md(工具策略)

---

## 0. 为什么质量后缀必须加

| 不加的后果 | 加了的效果 |
|-----------|----------|
| AI加填充光，暗场景变亮 | 保持你设计的灯光签名 |
| 铠甲变塑料，皮肤变蜡像 | 保持材质质感 |
| 角色面部变形/换脸 | 保持角色一致性 |
| 画面加字幕/水印/logo | 干净输出 |
| 运动过快/过大 | 受控运动 |

---

## 1. 通用质量后缀(每条必加，不可省略)

```
4K, ultra HD, rich detail, sharp clarity, cinematic textures, stable picture.
Maintaining face and clothing consistency without distortion or high detail.
Generate the video without subtitles.
```

**来源**: lanshu Seedance masterclass，实测证明这3行后缀显著提升生成质量。

---

## 2. 中世纪西幻专属后缀

### 2.1 铠甲/金属场景

```
worn iron patina, no plastic, anisotropic metal reflection,
armor scratches and dents visible, grounded weight on feet,
no beautification, no clean armor
```

### 2.2 暗场景/恐惧场景

```
no fill light, crushed blacks, let shadow be real,
extreme dark, sole warm source, no bright areas,
real darkness, no ambient fill
```

### 2.3 战斗/暴力场景

```
handheld rough, no beautification, dirt and blood,
sweat visible, grime on face, real combat weight,
impact felt, no clean fighting
```

### 2.4 魔法/超自然场景

```
consistent light source from magic, illuminates face naturally,
particles follow slow physics, not sparkle bomb,
volumetric but grounded, no lens flare overload
```

### 2.5 自然/风景场景

```
real landscape scale, atmospheric perspective on distant objects,
natural wind, real cloud movement, no oversaturated,
nature dominant human small
```

### 2.6 表情/对话场景

```
subtle micro-expression, no exaggerated emotion,
measured movement, natural blink timing,
real skin texture, no plastic face
```

---

## 3. 工具特定修复后缀

### 3.1 Kling 3.0/3.1

```
worn iron patina, no plastic, no fill, crushed blacks, no beautification,
moderate motion (40-60), 6s optimal, cinematic dark fantasy
```

**Kling最常见翻车+修复**:

| 翻车 | 修复后缀 |
|------|---------|
| 铠甲塑料感 | worn iron patina, no plastic, metal scratches |
| 暗场景过亮 | no fill, crushed blacks, let shadow be real |
| 运动过快 | moderate motion, measured movement |
| 面部美化 | no beautification, real skin texture |
| 加了填充光 | no fill light, sole warm source only |

### 3.2 Seedance 2.0/2.1

```
restrained, subtle, realistic color, not stylized,
measured movement, nuanced performance,
consistent lighting, motivated light source
```

**Seedance最常见翻车+修复**:

| 翻车 | 修复后缀 |
|------|---------|
| 过度风格化 | realistic color, not stylized, restrained |
| 动作过大 | measured movement, subtle, nuanced |
| 调色过饱和 | desaturated, restrained color grade |
| 表情夸张 | subtle micro-expression, no exaggerated emotion |
| 魔法太闪 | consistent light source, no lens flare overload |

### 3.3 Vidu

```
simple, stable, no complex motion,
single subject, basic composition,
preview quality
```

**Vidu最常见翻车+修复**:

| 翻车 | 修复后缀 |
|------|---------|
| 复杂运动失败 | no complex motion, simple movement |
| 多人场景崩坏 | single subject, one person only |
| 构图混乱 | basic composition, centered subject |

### 3.4 Wan 2.2 + ComfyUI

```
ControlNet-anchored, IP-Adapter reference,
consistent composition, character sheet reference,
workflow-controlled output
```

---

## 4. 负面提示词库

### 4.1 通用负面提示词(每条必加)

```
Negative: bright, cartoon, anime, blurry, deformed, watermark, text, logo, subtitles
```

### 4.2 中世纪西幻负面提示词

```
Negative: modern clothing, smartphone, glasses, sneakers, neon sign, car,
contemporary architecture, plastic texture, clean armor, shiny metal,
anime eyes, manga style, chibi, overexposed, flat lighting
```

### 4.3 情绪特定负面提示词

| 情绪 | 额外负面提示词 |
|------|-------------|
| 恐惧 | warm lighting, fill light, bright shadows, happy, safe |
| 敬畏 | small creature, human dominant, bright, cheerful |
| 孤独 | warm colors, crowd, company, busy, social |
| 愤怒 | clean, calm, peaceful, sanitized, beautiful |
| 悲伤 | bright, cheerful, fast motion, upbeat music |
| 魔法 | flat lighting, no glow, mundane, ordinary |
| 浪漫 | harsh light, clinical, cold, sterile |
| 权力 | casual, relaxed, informal, weak, small |

### 4.4 物理真实感负面提示词

```
Negative: plastic skin, wax figure, anime eyes, wrong finger count,
floating objects, no shadow, no ambient occlusion, flat shading,
no depth, cartoon physics, weightless, hovering
```

---

## 5. 快速查表：场景+工具 -> 完整后缀

| 场景 | 工具 | 完整后缀 |
|------|------|---------|
| 骑士独白 | Seedance | restrained, subtle, realistic color, maintaining face consistency, no beautification, no watermark |
| 魔法仪式 | Seedance | consistent light source, volumetric but grounded, maintaining face consistency, no lens flare, no subtitles |
| 战斗追逃 | Kling | worn iron patina, no plastic, no fill, crushed blacks, no beautification, moderate motion, no watermark |
| 森林漫步 | Seedance | natural light, realistic color, measured movement, maintaining consistency, no stylized, no subtitles |
| 对话密谋 | Kling | no fill, shadow on faces, sodium orange key, desaturated, no beautification, no watermark |
| 地牢审讯 | Seedance | restrained, sole warm source, crushed blacks, no fill, maintaining face consistency, no subtitles |
| 加冕典礼 | Kling | centered symmetry, divine backlight, gold catchlight, no plastic, crushed blacks, no watermark |
| 废墟探索 | Seedance | measured movement, environmental storytelling, worn stone, patina, no beautification, no subtitles |

---

> v1.0 初版: 通用+西幻+工具特定+负面提示词+场景查表，每条提示词必加
