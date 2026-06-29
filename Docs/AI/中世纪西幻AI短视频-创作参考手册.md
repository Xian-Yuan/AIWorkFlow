# 中世纪西幻 AI 短视频创作参考手册

> 搜集日期: 2026-06-28
> 目标平台: 抖音
> 题材: 中世纪西幻 (Medieval Western Fantasy)
> 用途: 为世界观设定、剧本大纲、短视频爆点、美术风格一致性、世界观真实性合理性提供方法论参考

---

## 目录

1. [世界观架构方法论](#1-世界观架构方法论)
2. [剧本大纲规范](#2-剧本大纲规范)
3. [短视频爆点与钩子体系](#3-短视频爆点与钩子体系)
4. [美术风格一致性设计](#4-美术风格一致性设计)
5. [世界观真实性合理性设计](#5-世界观真实性合理性设计)
6. [本地已有工具与资源](#6-本地已有工具与资源)
7. [开源资源索引](#7-开源资源索引)

---

## 1. 世界观架构方法论

### 1.1 Prism6 WorldBuilder -- 12要素框架

来源: [Prism6/WorldBuilder](https://github.com/Prism6/WorldBuilder) (Streamlit 应用, MIT 协议)

12要素是世界观构建的完整维度，每个要素需要具体描述且相互关联:

| 要素 | 含义 | 中世纪西幻适配 |
|------|------|--------------|
| **空间** | 地理、地形、地图、地标 | 王国疆域、城堡分布、战场位置、魔法禁地 |
| **时间** | 历史、时间线、历法体系 | 王朝纪年、纪元划分、重大战役时间节点 |
| **生物** | 种族、生命体、人口构成 | 人类/精灵/矮人/半兽人/龙族的人口比例 |
| **自然** | 气候、生态系统、自然环境 | 黑森林/冰原/火山地带/魔法荒原 |
| **文化** | 艺术、传统、习俗、价值观 | 骑士精神、宫廷礼仪、节日庆典、禁忌 |
| **语言** | 语言体系、文字、方言 | 古语/通用语/龙语/魔法符文 |
| **神话** | 宗教、神话、传说、信仰 | 七神殿/远古创世神话/堕落之神 |
| **哲学** | 思想、意识形态、世界观 | 骑士信条/魔法伦理/王权神授 |
| **规则** | 自然法则、社会规范、宗教法 | 魔法限制/领主法典/教会律令 |
| **经济** | 经济制度、贸易、货币 | 金币/银币/铜币体系、魔法矿石贸易 |
| **政治** | 政治体制、权力结构、外交 | 王权/封建领主/教会/商会的权力博弈 |
| **能量** | 魔法、科技、能源 | 魔力来源、魔法体系、附魔工业 |

**要素间关系类型**: 影响、依赖、冲突、和谐、原因、可能

**示例连接**: 空间 --> 影响 --> 文化: "山岳地形催生了封闭的部落文化，抵御外敌的传统塑造了骑士精神"

### 1.2 Clipcurator Worldbuilding Kit -- 短剧世界观六层模型

来源: [clipcurator/ai-short-drama-worldbuilding-kit](https://github.com/clipcurator/ai-short-drama-worldbuilding-kit)

| 层 | 定义什么 | 为什么重要 |
|---|--------|----------|
| Premise | 核心故事承诺和类型 | 保持系列聚焦 |
| Rules | 社会、情感或超自然规则 | 防止随机情节逻辑 |
| Locations | 关键地点和视觉锚点 | 帮助分镜和场景生成 |
| Power Map | 谁对谁有权力 | 驱动戏剧冲突 |
| Timeline | 过去事件和集数顺序 | 支撑连续性 |
| Secrets | 隐藏信息和揭露顺序 | 控制悬念 |

**生产流程**: 定义前提和类型承诺 -> 建立世界规则和冲突引擎 -> 创建反复出现的地点和视觉锚点 -> 绘制角色权力关系 -> 跟踪秘密、揭露和集数记忆 -> 在写剧本或生成分镜前使用世界圣经

### 1.3 World Bible Template (短剧专用)

```markdown
## 系列前提
- Title:
- Genre: 中世纪西幻
- Core promise:
- Target audience:
- Episode length:
- Season length:

## 世界规则
| 规则 | 描述 | 故事影响 |
|---|---|---|
| 社会规则 | | |
| 情感规则 | | |
| 权力规则 | | |
| 秘密规则 | | |

## 冲突引擎
- Main conflict:
- Repeating pressure:
- What characters want:
- What blocks them:
- What makes each episode escalate:

## 关键地点
| 地点 | 视觉锚点 | 故事功能 | 复用说明 |
|---|---|---|---|

## 秘密与揭露顺序
| 秘密 | 谁知道 | 第几集揭露 | 影响 |
|---|---|---|---|

## 连续性记忆
| 集数 | 事件 | 后续必须记住 |
|---|---|---|
```

### 1.4 Short Drama Project Bible (全项目圣经)

```markdown
## 项目
- Title:
- Genre: 中世纪西幻
- Target audience:
- Platform: 抖音
- Aspect ratio: 9:16
- Visual style:

## 概念
- One-sentence concept:
- Hook:
- Core conflict:
- Emotional promise:

## 世界
- Time:
- Location:
- Rules:
- Tone:

## 角色
| 角色 | 身份 | 动机 | 视觉规则 | 关系 |
|---|---|---|---|---|

## 集数
| 集数 | 核心事件 | 冲突 | 悬念 | 视觉焦点 |
|---|---|---|---|---|

## 生产资产
- 角色视觉:
- 场景视觉:
- 道具:
- 风格参考:

## 审查规则
- 角色一致性:
- 场景连续性:
- 剧本连贯性:
- 视频输出就绪度:
```

---

## 2. 剧本大纲规范

### 2.1 短剧故事大纲模板 (YubAI-DramaFlow)

来源: [xiaoqinyudan2022-hue/YubAI-DramaFlow](https://github.com/xiaoqinyudan2022-hue/YubAI-DramaFlow)

**核心结构**: 起承转合

| 结构 | 内容 | 集数/时间 |
|------|------|----------|
| **起**(开端) | | |
| **承**(发展) | | |
| **转**(高潮) | | |
| **合**(结局) | | |

**AI可行性预检**: 在正式进入剧本创作前，检查高风险元素:
- 复杂动作场景
- 多人同框场景
- 特效需求
- 精确道具/文字

### 2.2 竖屏短剧剧集结构 (Clipcurator)

来源: [clipcurator/vertical-drama-script-formats](https://github.com/clipcurator/vertical-drama-script-formats)

| 段落 | 时间范围 | 目的 |
|------|--------:|------|
| **Cold Hook** | 0-5s | 制造即时好奇或紧张 |
| **Setup** | 5-20s | 确立角色、地点、问题 |
| **Escalation** | 20-60s | 通过动作或对白增加压力 |
| **Turn** | 60-100s | 揭露新信息或反转权力 |
| **Cliffhanger** | 最后5-15s | 制造观看下一集的理由 |

**每场景必须包含**: 集数、场景数、地点和时间、角色列表、视觉节拍、对白、摄影/构图笔记、连续性笔记、下集钩子

### 2.3 剧情弧模板

来源: [clipcurator/ai-drama-episode-arc-templates](https://github.com/clipcurator/ai-drama-episode-arc-templates)

| 弧类型 | 最适合 | 结构 |
|--------|--------|------|
| **Conflict Arc** | 关系或地位剧 | Hook -> confrontation -> pressure -> reversal -> cliffhanger |
| **Secret Arc** | 悬疑和身份故事 | Hint -> denial -> evidence -> reveal -> new question |
| **Power Arc** | 复仇、社会层级 | Weak position -> pressure -> hidden leverage -> reversal |
| **Romance Arc** | 情感和关系剧 | Misread -> conflict -> vulnerability -> choice |
| **Quest Arc** | 目标驱动故事 | Objective -> obstacle -> attempt -> cost -> next step |

**五集节奏规划**:
1. 第1集: 确立主要承诺和第一个开放循环
2. 第2集: 增加压力并展示后果
3. 第3集: 揭露隐藏关系或秘密
4. 第4集: 强迫做出选择
5. 第5集: 反转权力或改变规则

### 2.4 场景节拍模板

来源: [clipcurator/ai-drama-scene-beat-templates](https://github.com/clipcurator/ai-drama-scene-beat-templates)

| 节拍模式 | 最适合 | 内部运动 |
|----------|--------|----------|
| **Confrontation Beat** | 指责、张力、竞争 | claim -> resistance -> evidence -> shift |
| **Reveal Beat** | 秘密、身份、背叛 | hint -> denial -> proof -> new truth |
| **Emotional Beat** | 感情、家庭、背叛 | defense -> wound -> vulnerability -> choice |
| **Pressure Beat** | 期限、威胁、权力 | request -> refusal -> pressure -> cost |
| **Exit Hook Beat** | 场景结尾悬念 | conflict -> partial answer -> stronger question |

### 2.5 分镜表模板 (YubAI-DramaFlow)

| 镜号 | 景别 | 运镜 | 画面描述 | 时长 | 台词/旁白 | 中文提示词 | 英文提示词 | 视频提示词 | 音效/配乐 | 备注 |
|------|------|------|----------|------|-----------|------------|------------|------------|-----------|------|

**景别参考**: 大远景(ELS)、远景(LS)、全景(FS)、中景(MS)、近景(MCU)、特写(CU)、大特写(ECU)
**运镜参考**: 推镜头(聚焦)、拉镜头(展现)、摇镜头(展示空间)、移镜头(平行运动)、跟镜头(动态跟随)、环绕(360展示)、固定(稳定画面)

---

## 3. 短视频爆点与钩子体系

### 3.1 钩子模式库 (本地已有)

来源: AIDramaProducer viral-analyzer knowledge

| 模式 | 模板 | 适用 | 有效性模式 |
|------|------|------|----------|
| **反常识提问** | "你一定以为____，但真相是____" | 知识科普 | 先用普遍认知铺垫，再用反常识结论冲击 |
| **数据炸弹** | "____%的人不知道____" | 话题类 | 具体数字比模糊描述冲击力高3倍 |
| **个人故事** | "我曾经____，直到____" | Vlog、情感 | 脆弱性展示产生共情 |
| **前后对比** | "从____到____，我只用了____天" | 教程、展示 | 视觉对比直接，不需要语言解释 |
| **认知矛盾** | "越____越____？" | 深度思考 | 制造认知失调，驱动寻求答案 |
| **结果前置** | "这是我____之后的结果" (先展示结果) | 测评 | 用结果截图吸引，再倒叙展开 |

### 3.2 钩子模式 (Clipcurator -- 竖屏短剧专用)

| 模式 | 使用时机 | 示例帧 |
|------|----------|--------|
| **Immediate Accusation** | 关系冲突是核心 | "You were with him last night." |
| **Visual Contradiction** | 图像制造问题 | 新娘穿着黑色礼服入场 |
| **Power Reversal** | 状态快速变化 | 助手被揭露为继承人 |
| **Secret Object** | 道具承载秘密 | 一封隐藏信件从外套掉落 |
| **Interrupted Ceremony** | 公众赌注很高 | 婚礼在誓词前停止 |

### 3.3 悬念模式 (Clipcurator -- 竖屏短剧专用)

| 模式 | 使用时机 | 结尾问题 |
|------|----------|----------|
| **Door Opens** | 新人物入场 | 谁来了？ |
| **Message Reveal** | 屏幕改变真相 | 消息说了什么？ |
| **Identity Reveal** | 有人不是看起来那样 | 他们到底是谁？ |
| **Choice Forced** | 角色必须现在决定 | 他们会选什么？ |
| **Evidence Appears** | 证据改变冲突 | 谁放置的？ |

**钩子+悬念模板**:
```
Hook:
What the audience sees:
What the audience asks:
Conflict introduced:
Cliffhanger:
Question left open:
Next episode promise:
```

### 3.4 情绪曲线模式库 (本地已有)

| 曲线 | 情绪序列 | 适用 | BGM配合 |
|------|----------|------|---------|
| **High Energy Curiosity Spike** | 好奇(0s) -> 惊讶(5s) -> 满足(20s) -> 行动欲(40s) | 教程、揭秘、科普 | 快节奏电子 -> 渐强 -> 鼓点爆发 |
| **Tension Release Cycle** | 紧张(0s) -> 更紧张(10s) -> 释放(25s) -> 温馨(35s) | 故事、Vlog、纪录片 | 悬疑缓慢 -> 安静过渡 -> 温暖钢琴 |
| **Problem Anxiety Resolution** | 焦虑(0s) -> 共鸣(10s) -> 希望(20s) -> 决心(35s) | 财经、健康、自我提升 | 沉重弦乐 -> 逐渐明亮 -> 激昂结尾 |
| **Rollercoaster Entertainment** | 笑(0s) -> 紧张(8s) -> 笑(15s) -> 感动(25s) -> 笑(35s) | 搞笑、娱乐、综艺 | 搞笑音效 + 快速切换 + 无声缓冲 |

### 3.5 叙事结构库 (本地已有)

| 结构 | 分段比例 | 适用 |
|------|----------|------|
| **问题-解决** | Hook(7%) -> Problem(33%) -> Solution(44%) -> CTA(16%) | 教程、科普 |
| **三幕剧** | Setup(25%) -> Confrontation(50%) -> Resolution(25%) | 短剧、故事 |
| **SCQA** | Situation(10%) -> Complication(20%) -> Question(5%) -> Answer(65%) | 商业分析 |
| **英雄之旅精简版** | Ordinary World(15%) -> Call(10%) -> Trials(30%) -> Transformation(25%) -> Return(20%) | 成长故事 |

### 3.6 中世纪西幻抖音爆点适配

| 爆点 | 抖音适配 | 3秒钩子示例 |
|------|----------|------------|
| **身份反转** | 身份揭露制造冲击 | "你以为他只是个铁匠？他是失落的王子" |
| **权力翻转** | 社会地位剧变 | 镜头从跪地到王座，3秒切换 |
| **禁忌揭露** | 打破世界观规则 | "她不是人类——她从未是" |
| **牺牲高潮** | 情感爆发节点 | 骑士举剑决意赴死，逆光剪影 |
| **阴谋揭示** | 真相一层层剥开 | 每集揭示一个阴谋碎片，5集完整 |

---

## 4. 美术风格一致性设计

### 4.1 风格定义模板 (YubAI-DramaFlow)

**中世纪西幻风格适配**:

| 维度 | 选择 | 提示词关键词 |
|------|------|--------------|
| **主风格** | CG电影风 / 写实 / 暗黑奇幻 | cinematic, dark fantasy, photorealistic, medieval |
| **色调偏好** | 暗沉压抑 / 高对比度 | dark, moody, high contrast, muted tones, cinematic color grading |
| **画面质感** | 厚涂 / 油画 / 电影质感 | oil painting texture, film grain, cinematic depth |
| **参考风格** | Game of Thrones / LOTR / Dark Souls | HBO medieval, Peter Jackson LOTR, Dark Souls aesthetic |

**风格锚定提示词 (必须包含在每次生图中)**:

```
# 英文版(必填)
cinematic dark fantasy, medieval setting, high contrast lighting,
moody atmosphere, oil painting texture, film grain,
Game of Thrones inspired aesthetic, detailed armor and clothing,
dramatic shadows, cold blue and warm amber color grading,
photorealistic detail, 4K resolution, masterpiece quality.

# 负面提示词
bright, cartoon, anime, chibi, low quality, blurry, deformed,
modern clothing, neon, cyberpunk, watermark, text, signature.
```

### 4.2 角色一致性检查清单 (Clipcurator)

**稳定锚点**: 
- 脸型匹配角色圣经
- 发长、发色、发型匹配
- 体型和年龄范围稳定
- 标志性服装或色板出现
- 关键道具或符号在相关时出现

**场景级灵活性**: 
- 表情可随情绪变化
- 姿势可随动作变化
- 光线可随地点变化
- 衣柜可随集数/场景变化(但需有故事原因)
- 损伤、受伤或变身必须在集数记忆中跟踪

**红旗警告**: 
- 角色看起来像不同的人
- 同一角色年龄或体型不一致
- 衣服没有故事原因就变了
- 关系或受伤被遗忘
- 生成帧与前一集矛盾

### 4.3 角色圣经模板 (Clipcurator + YubAI-DramaFlow 合并)

```markdown
## 角色身份
| 字段 | 内容 |
|---|---|
| Name | |
| Age range | |
| Role in story | 主角/反派/盟友/导师/对手 |
| Archetype | |
| First appearance | |

## 视觉锚点(稳定描述)
| 字段 | 内容 |
|---|---|
| Face | |
| Hair | |
| Body type | |
| Signature clothing | |
| Color palette | |
| Props | |
| Do not change | |

## 性格
- Core desire:
- Core fear:
- Default emotion:
- Speech style:
- Decision style:
- Moral boundary:

## 关系地图
| 角色 | 关系 | 张力 | 状态 |
|---|---|---|---|

## 集数记忆
| 集数 | 变了什么 | 后续必须记住 |
|---|---|---|

## Prompt-safe 描述
[角色名] is a [年龄段] [角色] with [稳定视觉锚点].
They usually [性格行为].
Keep consistent: [脸、发、服装、色板、道具].
Flexible: [表情、姿势、光线、场景语境].
```

### 4.4 角色提示词设计 (YubAI-DramaFlow)

**基础提示词结构**:
```
[Style Anchor] +
[角色名]，[年龄段]，[身份]。
[脸型描述]，[眼睛描述]，[发型描述]，[肤色描述]。
[体型描述]，[气质描述]。
masterpiece, best quality, 8K.
```

**三视图**: 正面(front view, symmetrical face) / 侧面(side view, profile) / 背面(back view)
**服装变体**: 日常装 / 战斗装 / 礼服装
**表情变体**: 微笑/大笑/悲伤/愤怒/惊讶/思考
**姿态变体**: 站立/行走/坐着/靠着/回头

### 4.5 场景设计模板 (YubAI-DramaFlow)

**中世纪西幻场景提示词结构**:
```
[Style Anchor]
[场景名称]，[内景/外景]。
[详细描述: 建筑风格、室内布置、重要元素]。
[光线描述]，[时间]，[天气]。
[色调描述]，[氛围]。
highly detailed, 8K, masterpiece.
```

**时间变体**: 早晨(morning light, golden hour) / 白天(daylight, bright) / 黄昏(sunset, warm orange) / 夜晚(nighttime, moonlight, cool tones)
**视角变体**: 全景(wide shot, establishing) / 中景(medium shot) / 特写(close-up, detail)

### 4.6 MCSLA 提示词公式 (Higgsfield Skill)

来源: [OSideMedia/higgsfield-ai-prompt-skill](https://github.com/OSideMedia/higgsfield-ai-prompt-skill)

**MCSLA = Model . Camera . Subject . Look . Action**

1. **Model**: 选择视频生成模型 (Kling 3.0 / Seedance 2.0 / Wan 2.2 等)
2. **Camera**: 摄影机预设名称 + 运镜方式
3. **Subject**: 主体物理描述 + 动作
4. **Look**: 风格、光线、色调、质感
5. **Action**: 发生什么变化/运动

**中世纪西幻 MCSLA 示例**:
```
Model: Kling 3.0
Aspect: 9:16 | Duration: 6s | Style: Cinematic

Camera: Slow Dolly In from medium-wide to medium close-up.
Subject: A weathered knight in blackened plate armor stands at the edge of a rain-soaked cliff.
His sword is planted in the stone, blood dripping from the blade.
Look: Cinematic. Cold blue shadows, single torch key light from behind,
crushed blacks, 2.35:1 anamorphic framing compressed to 9:16 center.
Action: Wind catches his cloak. He slowly turns his head toward the valley below.
A distant horn sounds. Smoke rises from a burning village.
```

### 4.7 摄影机语言映射 (本地 ai-video-director 已有)

| 光线 | 英文提示词 | 情绪 |
|------|------------|------|
| 黄金时刻 | golden hour, warm rim light, long shadows | 浪漫/史诗 |
| 蓝调时刻 | blue hour, twilight, cool ambient | 神秘/孤独 |
| 阴天散射 | overcast, soft diffused light | 压抑/日常 |
| 窗光 | window light, Rembrandt lighting | 戏剧/内省 |
| 逆光剪影 | backlight silhouette, sun flare | 英雄/史诗 |
| 烛光 | candlelight, flickering warm glow, deep shadows | 中世纪/神秘 |

---

## 5. 世界观真实性合理性设计

### 5.1 魔法体系设计原则 (Sanderson's Laws 适配短视频)

**第一定律**: 魔法的局限性比魔法的能力更有趣
- 明确魔法不能做什么比展示它能做什么更能制造张力
- 短视频中: 3秒展示魔法代价/限制，比展示魔法威力更能吸引观众

**第二定律**: 限制 > 能力 > 代价
- 限制(谁能用、何时用): 决定社会结构
- 能力(能做什么): 决定冲突类型
- 代价(用后付出什么): 决定情感深度
- 短视频适配: 每集揭示一个魔法限制/代价，5集揭示完整体系

**第三定律**: 扩展已有魔法比添加新魔法更好
- 在短视频中，深化一个魔法的层次比引入多种魔法更有效
- 中世纪西幻适配: 一个魔法体系 + 分层(学徒/骑士/大师/禁忌魔法)

**魔法体系模板**:

| 维度 | 定义 | 短剧影响 |
|------|------|----------|
| 来源 | 魔法从何而来(血统/学习/神赐/诅咒) | 决定谁有资格使用 |
| 限制 | 魔法不能做什么 | 制造冲突和张力 |
| 代价 | 使用魔法后的后果 | 制造情感深度 |
| 层级 | 魔法的等级划分 | 驱动权力结构 |
| 规则 | 魔法的具体运作方式 | 保证世界观内部一致性 |

### 5.2 社会结构逻辑

**封建体系适配短视频**:

| 层级 | 角色 | 权力来源 | 冲突潜能 |
|------|------|----------|----------|
| 王权 | 国王/女王 | 血统 + 军力 | 内部继承争议 |
| 领主 | 封建领主 | 土地 + 骑士团 | 领地争夺 |
| 教会 | 大主教 | 信仰 + 魔法知识 | 与王权对抗 |
| 商会 | 贸易联盟 | 财富 + 网络 | 控制资源流通 |
| 骑士 | 魔法使用者 | 魔力 + 剑术 | 个人崛起/堕落 |
| 平民 | 农民/工匠 | 数量 + 劳动 | 被压迫->反叛 |

**权力冲突引擎**: 每两个相邻层级之间都有天然张力，这是短剧的核心冲突来源

### 5.3 经济系统合理性

| 要素 | 中世纪西幻适配 | 短剧用途 |
|------|--------------|----------|
| 货币体系 | 金币(贵族)/银币(骑士)/铜币(平民) + 魔法矿石(特殊货币) | 展示阶层差距 |
| 贸易路线 | 王城->港口->矿山->魔法森林 | 地点多样性和场景变化 |
| 资源控制 | 魔法矿石只产于禁地 -> 控制权=权力 | 核心冲突驱动力 |
| 生产力 | 附魔工业(魔法辅助) vs 传统手工 | 技术冲突和阶级冲突 |

### 5.4 历史纵深设计

| 纪元 | 核心事件 | 对当前故事的影响 |
|------|----------|----------------|
| 远古纪 | 创世神话/魔法起源 | 魔法体系的原始规则 |
| 旧王朝纪 | 第一王国建立/骑士团形成 | 现有权力结构的起源 |
| 分裂纪 | 王国分裂/教会崛起 | 各势力的历史正当性 |
| 黑暗纪 | 大灾变/魔法失控 | 魔法限制的历史原因 |
| 当前纪 | 故事发生的时间 | 所有历史事件的当下体现 |

**短视频适配**: 每集背景讲述一个纪元的关键事件，5集拼出完整历史纵深

### 5.5 世界观内部一致性检查清单

| 检查项 | 问题 | 通过标准 |
|--------|------|----------|
| 魔法一致性 | 魔法规则是否在所有场景中一致执行？ | 无违反规则的例外 |
| 社会一致性 | 权力结构是否在所有互动中体现？ | 角色行为符合其层级 |
| 经济一致性 | 货币/资源逻辑是否贯穿剧情？ | 交易场景不矛盾 |
| 地理一致性 | 地点之间距离和路线是否合理？ | 旅行时间不矛盾 |
| 时间一致性 | 历史事件和当前时间是否对齐？ | 时间线无冲突 |
| 文化一致性 | 习俗/禁忌是否在所有对话中遵守？ | 角色不违反文化规则 |
| 视觉一致性 | 场景/服装是否匹配设定纪元？ | 无时代错误元素 |

---

## 6. 本地已有工具与资源

### 6.1 AIDramaProducer 完整管线

路径: `E:\UEGameDevelopment\Project\AIDramaProducer\skills\`

| 模块 | 功能 | 状态 |
|------|------|------|
| ai_drama_scriptwriter | 剧本生成、角色提取、场景拆分、分镜设计 | 已实现 |
| ai_drama_viral_analyzer | 爆款分析、风格注入、融合创作 | 已实现 |
| ai_drama_keyframe_generator | 关键帧图片生成 | 已实现 |
| ai_drama_asset_generator | 角色/场景资产生成 | 已实现 |
| ai_drama_tts_generator | TTS配音生成 | 已实现 |
| ai_drama_compositor | 视频合成导出 | 已实现 |
| ai_drama_video_generator | 视频片段生成 | 已实现 |
| ai_drama_orchestrator | 全流程编排 | 已实现 |
| ai_drama_preproduction_studio | 前期制作工作室(含Web UI) | 已实现 |

### 6.2 Skill 级工具

路径: `E:\UEGameDevelopment\.agents\skills\`

| Skill | 功能 |
|-------|------|
| ai-video-creator | 六阶段完整视频创作管线(灵感->立项->剧本->角色->分镜->视频提示词) |
| ai-video-director | 从分镜剧本到平台级视频生成提示词 |
| ai-drama-scriptwriter | 从故事创意到结构化分镜剧本 |
| ai-drama-viral-analyzer | 爆款视频/小说结构分析+风格复制+融合创作 |

### 6.3 知识库

路径: `E:\UEGameDevelopment\Project\AIDramaProducer\skills\ai_drama_viral_analyzer\knowledge\`

| 文件 | 内容 |
|------|------|
| hook-patterns.md | 6种钩子模式库 |
| narrative-structures.md | 5种叙事结构库 |
| emotional-curves.md | 4种情绪曲线模式库 |
| creator-styles.md | 博主风格库(待填充) |

### 6.4 调研报告

路径: `E:\UEGameDevelopment\Project\AIDramaProducer\docs\early-references\ai-drama-ecosystem-research.md`

完整的AI短剧生态调研报告，覆盖14+开源项目、5+学术论文、完整对比矩阵。

---

## 7. 开源资源索引

### 7.1 方法论与模板类(最相关)

| 仓库 | Stars | 核心价值 |
|------|-------|----------|
| [clipcurator/ai-short-drama-worldbuilding-kit](https://github.com/clipcurator/ai-short-drama-worldbuilding-kit) | 1 | 世界圣经模板、地点系统、连续性笔记 |
| [clipcurator/vertical-drama-script-formats](https://github.com/clipcurator/vertical-drama-script-formats) | 4 | 竖屏短剧脚本格式、钩子/悬念模式 |
| [clipcurator/ai-character-continuity-kit](https://github.com/clipcurator/ai-character-continuity-kit) | 2 | 角色圣经、视觉一致性检查清单 |
| [clipcurator/ai-storyboard-prompts](https://github.com/clipcurator/ai-storyboard-prompts) | 5 | 双语角色/场景/分镜/运镜提示词 |
| [clipcurator/ai-short-drama-production-workflows](https://github.com/clipcurator/ai-short-drama-production-workflows) | 2 | 完整生产流程文档 |
| [clipcurator/ai-drama-episode-arc-templates](https://github.com/clipcurator/ai-drama-episode-arc-templates) | 1 | 5种剧情弧模板 |
| [clipcurator/ai-drama-scene-beat-templates](https://github.com/clipcurator/ai-drama-scene-beat-templates) | 1 | 5种场景节拍模板 |
| [clipcurator/ai-drama-prompt-qa-checklist](https://github.com/clipcurator/ai-drama-prompt-qa-checklist) | 0 | 提示词QA检查清单 |
| [clipcurator/ai-short-drama-visual-continuity-prompt-pack](https://github.com/clipcurator/ai-short-drama-visual-continuity-prompt-pack) | 0 | 视觉连续性提示词包 |
| [xiaoqinyudan2022-hue/YubAI-DramaFlow](https://github.com/xiaoqinyudan2022-hue/YubAI-DramaFlow) | 138 | 五阶段完整工作流+9个中文模板 |
| [Prism6/WorldBuilder](https://github.com/Prism6/WorldBuilder) | 3 | 12要素世界观构建工具 |
| [OSideMedia/higgsfield-ai-prompt-skill](https://github.com/OSideMedia/higgsfield-ai-prompt-skill) | 170 | MCSLA提示词公式+20个子技能 |
| [Creepybits/World_weaver](https://github.com/Creepybits/World_weaver) | 29 | 文本继承角色一致性系统(ComfyUI) |

### 7.2 数据集类

| 仓库 | Stars | 核心价值 |
|------|-------|----------|
| [vaew/SkyScript-100M](https://github.com/vaew/SkyScript-100M) | 145 | 10亿对剧本-分镜脚本数据集 |

### 7.3 短剧生产平台类

| 仓库 | Stars | 定位 |
|------|-------|------|
| [chatfire-AI/huobao-drama](https://github.com/chatfire-AI/huobao-drama) | 12998 | 一站式短剧生成平台 |
| [waooAI/waoowaoo](https://github.com/waooAI/waoowaoo) | 12952 | 工业级全流程AI影视平台 |
| [HBAI-Ltd/Toonflow-app](https://github.com/HBAI-Ltd/Toonflow-app) | 10590 | 一站式AI短剧创作工具 |
| [Forget-C/Jellyfish](https://github.com/Forget-C/Jellyfish) | 4638 | AI竖屏短剧工业化生产工具 |
| [AIDC-AI/Pixelle-Video](https://github.com/AIDC-AI/Pixelle-Video) | 22900 | 一句话主题->完整短视频 |

### 7.4 本地调研报告

`E:\UEGameDevelopment\Project\AIDramaProducer\docs\early-references\ai-drama-ecosystem-research.md`