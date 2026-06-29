# 跨工具提示词翻译对照表

> 版本: v1.0 | 日期: 2026-06-29
> 状态: 可用
> 来源: lanshu-awesome-ai-video-kit(跨模型翻译概念) + 本地ai-video-tool-prompting.md(工具策略)
> 用途: 同一创意在不同AI视频工具间的提示词格式转换——不是凭直觉重写，而是查表式翻译
> 关联: ai-shortdrama-salcsq-template.md(通用骨架) / ai-video-tool-prompting.md(工具详情)

---

## 0. 核心理念

从lanshu吸收的关键洞察：跨模型翻译不是"凭AI直觉重写"，而是**查对照表做few-shot**。

翻译流程：
1. 从SALCSQ通用骨架提取语义内容
2. 查本表找到目标工具的格式规则
3. 按规则重组，保留语义，只改结构/标签/措辞

---

## 1. 格式规则对照

### 1.1 结构对比

| 工具 | 必带结构 | 标签风格 | 主体位置 | 运镜描述 | 音频处理 |
|------|---------|---------|---------|---------|---------|
| **SALCSQ通用** | S+A+L+C+S+Q | 模块标题 | Subject段开头 | Camera段 | 内嵌L/C |
| **Kling** | Scene/Characters/Action/Camera/Audio&Style/Negative | 英文标签 | Scene段开头 | camera_move=参数 | Audio&Style合并 |
| **Seedance** | [Mode]+自然语言流 | 无标签/自然流 | 开头主体 | 自然语言运镜 | 内嵌描述 |
| **Vidu** | 4段自然语言 | 无标签 | 开头主体 | 简单运镜 | 不写 |
| **Wan** | 自然语言+ControlNet描述 | 无标签/工作流 | 开头主体 | ControlNet参数 | 不写 |

### 1.2 措辞密度

| 工具 | 推荐词数 | 描述风格 | 关键差异 |
|------|---------|---------|---------|
| **SALCSQ通用** | 150-200词 | 结构化+参数化 | 中等密度，六模块清晰分隔 |
| **Kling** | 150-200词 | 场景式+标签 | Scene段合并主体+环境+动作 |
| **Seedance** | 100-150词 | 自然流+电影语言 | 开头加模式，运镜用自然语言 |
| **Vidu** | 50-100词 | 极简 | 去掉复杂运镜和细节 |
| **Wan** | 100-150词 | 参数式 | 加ControlNet/IP-Adapter描述 |

---

## 2. SALCSQ -> 工具特定 翻译规则

### 2.1 SALCSQ -> Kling

| SALCSQ模块 | Kling映射 | 示例 |
|-----------|----------|------|
| S+L环境 | Scene | Scene: A knight in chains in a candlelit dungeon, darkened plate armor with rust stains |
| S角色特征 | Characters | Characters: knight, weathered face, black plate armor |
| A | Action | Action: breathing deep and slow, eye fixed ahead, jaw clenched, suppressing tremor |
| C | Camera | Camera: 135mm f/2.8 MCU, slow lateral dolly, narrow framing, camera_move=pan_right |
| L+S | Audio & Style | Audio & Style: Khondji sodium orange key, no fill, dungeon orange palette, Fincher desaturated, Vision3 500T, 9:16 vertical |
| Q负面 | Negative | Negative: bright, cartoon, anime, blurry, deformed, watermark, no fill, crushed blacks |

**Kling运镜参数映射**:
| SALCSQ运镜 | Kling camera_move |
|-----------|------------------|
| slow dolly in | camera_move=forward |
| slow dolly out | camera_move=backward |
| lateral dolly right | camera_move=pan_right |
| lateral dolly left | camera_move=pan_left |
| orbit 360 | camera_move=orbit |
| tilt up | camera_move=up |
| tilt down | camera_move=down |
| locked | (不写camera_move) |
| handheld | (不写camera_move, 加handheld描述) |

### 2.2 SALCSQ -> Seedance

| SALCSQ模块 | Seedance映射 | 示例 |
|-----------|-------------|------|
| S+A | 开头主体+动作 | A knight in chains, weathered face, darkened plate armor, breathing deep and slow, eye fixed ahead |
| C | 中段镜头 | 135mm f/2.8 MCU, slow lateral dolly right-to-left, narrow dungeon framing |
| L | 后段光影 | Khondji sodium orange key from wall sconce, no fill, crushed blacks, dungeon orange palette, Vision3 500T |
| S | 风格锚定 | Fincher-grade desaturated, cinematic dark fantasy |
| Q | 质量后缀 | 4K ultra HD, maintaining face consistency, worn iron patina, no plastic |

**Seedance模式映射**:
| SALCSQ C模块特征 | Seedance模式 |
|-----------------|-------------|
| 锁定/极慢推+高对比+人像 | Studio |
| 手持+快速+去饱和 | Action |
| 环绕+戏剧调色+魔法 | Performance |
| 漂浮+极端调色+氛围 | Atmospheric |
| 慢推+中性暖+日常 | Narrative |

### 2.3 SALCSQ -> Vidu

| SALCSQ模块 | Vidu映射 | 示例 |
|-----------|---------|------|
| S+A | 主体+简单动作 | A knight in chains, breathing slow, looking ahead |
| C | 简单镜头 | 135mm MCU, locked |
| L | 一句话光影 | sodium orange key, dark |
| S | 风格词 | cinematic dark fantasy |
| Q | 极简负面 | Negative: blurry, deformed, watermark |

**Vidu规则**: 100词以内，只保留S+A+简单C+一句话L+S

---

## 3. 工具间互译示例

### 3.1 同一创意：骑士被宣判叛国

**SALCSQ通用骨架**:
```
S: A knight in chains, weathered face, darkened plate armor with rust stains
A: breathing deep and slow, eye fixed ahead, jaw clenched, suppressing tremor
L: Khondji sodium orange key, no fill, crushed blacks, dungeon orange palette, Vision3 500T
C: 135mm f/2.8 MCU, slow lateral dolly right-to-left, narrow dungeon framing, 9:16 vertical depth
S: Fincher-grade desaturated, cinematic dark fantasy
Q: 4K, maintaining face consistency, worn iron patina, no plastic, no beautification
```

**翻译为Kling**:
```
Scene: A knight in chains in a narrow dungeon, darkened plate armor with rust stains, sodium orange light from wall sconce
Characters: knight, weathered face, black plate armor, chains on wrists
Action: breathing deep and slow, eye fixed ahead, jaw clenched, suppressing tremor on chains
Camera: 135mm f/2.8 MCU, narrow framing, camera_move=pan_right
Audio & Style: Khondji sodium orange key, no fill, crushed blacks, dungeon orange palette, Fincher desaturated, Vision3 500T, 9:16 vertical
Negative: bright, cartoon, anime, blurry, deformed, watermark, no fill, crushed blacks, no beautification
```

**翻译为Seedance**:
```
Seedance Studio mode,
A knight in chains, weathered face, darkened plate armor with rust stains,
breathing deep and slow, eye fixed ahead, jaw clenched, suppressing tremor on chains,
135mm f/2.8 MCU, slow lateral dolly right-to-left, narrow dungeon framing,
Khondji sodium orange key from wall sconce, no fill, crushed blacks,
dungeon orange palette, Kodak Vision3 500T,
Fincher-grade desaturated, cinematic dark fantasy,
4K, ultra HD, rich detail, maintaining face consistency,
worn iron patina, no plastic, no beautification,
no watermark, no logo, no subtitles,
9:16 vertical, cinematic dark fantasy.
```

**翻译为Vidu**:
```
A knight in chains, darkened armor, breathing slow, looking ahead,
135mm MCU, locked camera, sodium orange light, dark dungeon,
cinematic dark fantasy, 9:16 vertical
Negative: blurry, deformed, watermark
```

---

## 4. 翻译自查清单

| 检查项 | Kling | Seedance | Vidu |
|--------|-------|---------|------|
| 提示词长度 | 150-200词 | 100-150词 | 50-100词 |
| 主体在句首 | Scene段开头 | 第一句 | 第一句 |
| 只有一种运镜 | camera_move=一个 | 自然语言一段 | 简单一句话 |
| 有质量后缀 | Negative段 | 结尾后缀 | 极简Negative |
| 有9:16标记 | 末尾 | 末尾 | 末尾 |
| 无矛盾词 | 检查8mm+4K等 | 同左 | 同左 |
| 有工具修复词 | worn iron patina等 | restrained等 | simple等 |

---

> v1.0 初版: 5工具格式对照+3工具翻译规则+互译示例+自查清单
