# AI 短剧工作流方法论文档

> 版本: v3.14 | 更新日期: 2026-06-29
> 用途: 中世纪西幻 AI 短视频全流程创作方法论 (抖音平台)
> 基于: MCN 闭门分享会原始分析 + 多平台开源方法论搜集整合
> 关联文档: `Docs/AI/中世纪西幻AI短视频-创作参考手册.md` (模板与资源索引)
> 关联速查: `Docs/AI/镜头调度与摄影参数提示词速查手册.md` (v2.0, 20章)

---

## 变更日志

| 版本 | 日期 | 变更 |
|------|------|------|
| v1.0 | 2026-06-28 | 初版: MCN 闭门分享分析 + 评估 + 4步实操路径 |
| v2.0 | 2026-06-28 | 大幅扩展: 整合世界观架构/剧本大纲/爆点体系/美术一致性/真实性合理性五大维度方法论，形成完整工作流 |
| v3.0 | 2026-06-28 | 深度扩展9.4节: 5位DP灯光签名/5位导演构图签名/构图即权力关系/灯光即选择性照亮/集成提示词解剖公式/9:16竖屏规则/Seedance电影模式/情绪可见行为8通道/物理真实感8层/情绪→导演风格查表/速查手册同步v2.0 |
| v3.1 | 2026-06-28 | 新增导演视觉叙事体系: 构图心理学(格式塔5原则/视觉重量/8种视觉流动) + 景别亲密梯度(10级景别/6种渐进) + 帧率与时间感 + 色彩心理学(9色进化/色温叙事) + 导演视觉叙事(5层决策金字塔/6通道编码/通道冲突/三位一体工作流) + 2个新KB文件(cinematography-deep-dive/director-visual-narrative) + 速查手册升级v3.0(6个新章节) |

---

## 目录

1. [来源与可信度评估](#1-来源与可信度评估)
2. [核心方法论: 微表情身份证 + 三帧定式](#2-核心方法论-微表情身份证--三帧定式)
3. [世界观架构方法论](#3-世界观架构方法论)
4. [剧本大纲与叙事规范](#4-剧本大纲与叙事规范)
5. [短视频爆点与钩子体系](#5-短视频爆点与钩子体系)
6. [美术风格一致性设计](#6-美术风格一致性设计)
7. [世界观真实性合理性设计](#7-世界观真实性合理性设计)
8. [完整工作流: 七阶段管线](#8-完整工作流-七阶段管线)
9. [提示词工程体系](#9-提示词工程体系)
10. [AI 可行性评估与风险控制](#10-ai-可行性评估与风险控制)
11. [本地工具链与资源](#11-本地工具链与资源)
12. [开源资源索引](#12-开源资源索引)
13. [原文存档](#13-原文存档)


---

## 1. 来源与可信度评估

### 1.1 信息来源

| 来源 | 类型 | 可信度 |
|------|------|--------|
| 头部 MCN 闭门分享会 | 一手经验 | 方法论真实但非独家，是公开做法的浓缩 |
| Clipcurator 系列 (GitHub) | 开源模板 | 结构化、可操作、中性资源 |
| YubAI-DramaFlow (GitHub) | 开源方法论 | 中文、五阶段、9 模板、实践验证 |
| Prism6/WorldBuilder (GitHub) | 开源工具 | 12 要素框架、Streamlit 应用 |
| Higgsfield AI Prompt Skill (GitHub) | 专业提示词 | MCSLA 公式、170 stars、持续更新 |
| World Weaver (GitHub) | ComfyUI 工作流 | 文本继承角色一致性、29 stars |
| SkyScript-100M (学术论文) | 数据集 | 10 亿对剧本-分镜脚本、SIGGRAPH |
| 本地 AIDramaProducer | 自研管线 | 完整 9 模块、已验证 |

### 1.2 可信度分级(基于闭门分享)

| 维度 | 评分 | 说明 |
|------|------|------|
| 方法论真实性 | 4/5 | 表情编码/三帧定式是 ComfyUI + SD 圈公开成熟做法 |
| 信息密度 | 4/5 | 闭门分享案例密度高于公开教程 |
| 落地门槛 | 3/5 | 表面 prompt 可立即试，完整效果需 IP-Adapter/ControlNet 工具链 |
| 营销包装度 | 3/5 | 含部分噱头(60 个镜头清单等) |

**核心判断**: 闭门分享的价值在密度，不在稀缺。AIGC 方法论 3 个月内都会变公开知识。不为"独家"付费，为"密度高 + 可立即动手"付费。


---

## 2. 核心方法论: 微表情身份证 + 三帧定式

> 来源: MCN 闭门分享会，经评估为真干货

### 2.1 微表情身份证

**问题**: 漫剧角色在多帧之间"亲妈都认不出"(一致性崩坏)

**解法**: 把模糊情绪("害羞地笑")拆成可复用的五官动作编码，通过编码组合精确控制角色表情

**基础 5 编码** (来自分享):

| 编码 | 情绪名 | 五官动作组合 |
|------|--------|-------------|
| A-01 | 轻悦态 | 眼角弯月牙 + 嘴角上扬 + 下巴微收 |
| A-02 | 压抑态 | 唇抿线 + 眉心上抬 + 眼下斜 |
| A-03 | 压迫态 | 眉头紧锁 + 鼻翼微张 + 下颌前突 + 嘴角下撇 |
| A-04 | 顿悟态 | 眉挑高 + 眼睁圆 + 唇微张 |
| A-05 | 平静态 | 面部放松 + 目光平视 + 唇闭 |

**中世纪西幻扩展编码**:

| 编码 | 情绪名 | 五官动作组合 | 典型场景 |
|------|--------|-------------|----------|
| A-06 | 警戒态 | 眉微蹙 + 瞳孔收缩 + 唇紧闭 + 下颌微抬 | 黑暗中听到异响 |
| A-07 | 悲壮态 | 眉紧锁 + 眼眶泛红 + 嘴角下压 + 牙关紧咬 | 骑士赴死前 |
| A-08 | 威压态 | 眉压低 + 直视 + 鼻翼微张 + 唇角平直 | 国王宣判 |
| A-09 | 伪善态 | 眼不达笑 + 嘴角单侧上扬 + 眉微挑 | 宫廷阴谋家 |
| A-10 | 狂热态 | 瞳孔放大 + 眉高扬 + 唇微张露齿 | 禁忌魔法发动 |
| A-11 | 痛苦态 | 眉紧皱 + 眼紧闭 + 唇角下拉 + 额头青筋 | 魔法代价发作 |
| A-12 | 凛然态 | 眉平 + 目光坚定 + 下颌微扬 + 唇闭 | 宣誓场景 |
| A-13 | 惊骇态 | 眉高挑 + 瞳孔放大 + 唇大张 | 目睹魔物 |
| A-14 | 隐忍态 | 眼微闭 + 唇咬紧 + 下颌肌肉绷紧 | 被屈辱但不能发作 |
| A-15 | 怜悯态 | 眉微蹙 + 目光下移 + 嘴角微抿 | 看到难民 |

**写法**: 全程保持 A-07 状态，然后执行动作

**落地前提**: 纯文字 prompt 只能"接近"，要"一致"必须配合 IP-Adapter / Reference-only + 每个编码配一张参考图 + ControlNet 权重

### 2.2 起-转-收 三帧定式

**问题**: AI 难以理解"动态连续动作"，"围好围巾"这种描述会生成姿态诡异或缺失动作的图

**解法**: 把连续动作切成 3 个静态关键帧，每帧明确"接触点 + 距离 + 手部姿态"。AI 理解姿态，不理解动作。

**示例: 骑士拔剑**

| 帧 | 接触点 | 距离 | 姿态细节 |
|----|--------|------|----------|
| 起 | 右手 vs 剑柄 | 5cm | 手悬空，未触，目光直视前方 |
| 转 | 五指 vs 剑柄 | 紧握 | 剑出鞘 30 度，手腕发力，衣袖随动 |
| 收 | 剑身 vs 身侧 | 剑尖指天 | 剑完全出鞘，手自然垂落，披风被气流掀起 |

**中世纪西幻常用三帧定式**:

| 动作 | 起帧 | 转帧 | 收帧 |
|------|------|------|------|
| 骑士拔剑 | 手悬空 vs 剑柄 5cm | 五指紧握，剑出 30 度 | 剑指天，披风扬起 |
| 魔法咏唱 | 双手合十 vs 胸前 | 手指张开 vs 眉心，符文浮现 | 双臂展开 vs 两侧，魔力爆发 |
| 单膝下跪 | 双脚站直 | 右膝弯曲，手触剑柄 | 左膝着地，头低垂 |
| 举杯宣誓 | 杯 vs 桌面 | 杯 vs 胸前，手握杯脚 | 杯举过头顶，目光坚定 |
| 推开城门 | 手 vs 门面 | 手掌贴门，前倾发力 | 门开半扇，逆光涌入 |

**进阶**: 复杂动作(打斗/魔法)需要 5-7 帧，帧间用 image-to-image 串帧


---

## 3. 世界观架构方法论

### 3.1 双框架整合

**框架 A: Prism6 12 要素** (维度全面，适合初始构建)

| 要素 | 含义 | 中世纪西幻适配 |
|------|------|--------------|
| 空间 | 地理、地形、地标 | 王国疆域、城堡、战场、魔法禁地 |
| 时间 | 历史、时间线、历法 | 王朝纪年、纪元划分 |
| 生物 | 种族、人口构成 | 人类/精灵/矮人/半兽人/龙族 |
| 自然 | 气候、生态 | 黑森林/冰原/火山/魔法荒原 |
| 文化 | 艺术、传统、价值观 | 骑士精神、宫廷礼仪、禁忌 |
| 语言 | 语言体系、文字 | 古语/通用语/龙语/魔法符文 |
| 神话 | 宗教、信仰 | 七神殿/创世神话/堕落之神 |
| 哲学 | 思想、意识形态 | 骑士信条/魔法伦理/王权神授 |
| 规则 | 法则、规范 | 魔法限制/领主法典/教会律令 |
| 经济 | 贸易、货币 | 金/银/铜币 + 魔法矿石 |
| 政治 | 权力结构、外交 | 王权/领主/教会/商会博弈 |
| 能量 | 魔法、能源 | 魔力来源、魔法体系、附魔工业 |

**框架 B: Clipcurator 六层模型** (短剧导向，适合生产落地)

| 层 | 定义 | 为什么重要 |
|---|------|----------|
| Premise | 核心故事承诺和类型 | 保持系列聚焦 |
| Rules | 社会/情感/超自然规则 | 防止随机情节逻辑 |
| Locations | 关键地点和视觉锚点 | 帮助分镜和场景生成 |
| Power Map | 谁对谁有权力 | 驱动戏剧冲突 |
| Timeline | 过去事件和集数顺序 | 支撑连续性 |
| Secrets | 隐藏信息和揭露顺序 | 控制悬念 |

**整合流程**: 先用 12 要素构建完整世界观，再用六层模型提取短剧生产所需的核心约束

### 3.2 冲突引擎设计

| 引擎 | 想要 | 阻止 | 反弹 | 升级 |
|------|------|------|------|------|
| 血统引擎 | 平民想当骑士 | 只有贵族血统可受封 | 伪造血统被发现 | 被判为叛国罪 |
| 魔法引擎 | 骑士想用禁忌魔法 | 禁忌魔法代价是生命 | 使用后身体恶化 | 每用一次减寿十年 |
| 权力引擎 | 领主想独立 | 王权不许分裂 | 暗中结盟被发现 | 王军压境 |
| 信仰引擎 | 骑士质疑神谕 | 质疑等于异端 | 被教会追杀 | 发现神谕确实是假的 |

### 3.3 世界圣经模板

```markdown
## 系列前提
- Title:
- Genre: 中世纪西幻
- Core promise: [一句话观众为什么要追]
- Target audience:
- Episode length: [1-3 分钟/集]
- Season length: [5-10 集/季]

## 世界规则
| 规则 | 描述 | 故事影响 |
|---|---|---|
| 社会规则 | | |
| 魔法规则 | | |
| 权力规则 | | |
| 秘密规则 | | |

## 冲突引擎
- Main conflict:
- Repeating pressure:
- What characters want:
- What blocks them:
- What makes each episode escalate:

## 关键地点(每个地点必须有视觉锚点)
| 地点 | 视觉锚点 | 故事功能 | 复用说明 |
|---|---|---|---|

## 权力地图
| 角色 | 权力来源 | 对谁有权力 | 被谁制约 |
|---|---|---|---|

## 秘密与揭露顺序
| 秘密 | 谁知道 | 第几集揭露 | 影响 |
|---|---|---|---|

## 连续性记忆
| 集数 | 事件 | 后续必须记住 |
|---|---|---|
```


---

## 4. 剧本大纲与叙事规范

### 4.1 竖屏短剧五段结构

| 段落 | 时间 | 目的 | 中世纪西幻适配 |
|------|------:|------|--------------|
| Cold Hook | 0-5s | 制造即时好奇 | 逆光骑士跪在血泊中 / 王座上的皇冠突然碎裂 |
| Setup | 5-20s | 确立角色、地点、问题 | 铁匠铺里，平民被征召令叫走 |
| Escalation | 20-60s | 增加压力 | 训练中被贵族骑士欺辱 / 发现有魔法天赋 |
| Turn | 60-100s | 揭露新信息或反转 | 征召令上写着他的真实姓氏 / 魔法是禁忌的 |
| Cliffhanger | 最后 5-15s | 制造追看理由 | 教会审判官敲门 / 国王说出"你是我的血脉" |

### 4.2 五种剧情弧

| 弧类型 | 最适合 | 结构 | 西幻示例 |
|--------|--------|------|----------|
| Conflict Arc | 权力/地位剧 | Hook->对抗->施压->反转->悬念 | 领主与骑士的对峙 |
| Secret Arc | 身份/悬疑 | 暗示->否认->证据->揭露->新问题 | 隐藏血统的发现 |
| Power Arc | 复仇/逆袭 | 弱势->施压->隐藏筹码->反转 | 平民骑士崛起 |
| Romance Arc | 情感/禁忌恋 | 误读->冲突->脆弱->选择 | 骑士与异族女子 |
| Quest Arc | 目标驱动 | 目标->障碍->尝试->代价->下一步 | 寻找魔法圣物 |

### 4.3 五集节奏规划

1. 第1集: 确立主要承诺 + 第一个开放循环
2. 第2集: 增加压力 + 展示后果
3. 第3集: 揭露隐藏关系或秘密
4. 第4集: 强迫做出选择
5. 第5集: 反转权力或改变规则

### 4.4 场景节拍模板

| 节拍 | 最适合 | 内部运动 | 西幻适配 |
|------|--------|----------|----------|
| Confrontation | 指责、对抗 | claim->resistance->evidence->shift | 骑士质疑领主的命令 |
| Reveal | 秘密、身份 | hint->denial->proof->new truth | 发现教会隐藏的真相 |
| Emotional | 感情、背叛 | defense->wound->vulnerability->choice | 骑士在忠诚与爱情间 |
| Pressure | 期限、威胁 | request->refusal->pressure->cost | 魔法代价的最后倒计时 |
| Exit Hook | 场景结尾悬念 | conflict->partial answer->stronger question | 审判官敲门 |

### 4.5 分镜表模板

| 镜号 | 景别 | 运镜 | 画面描述 | 时长(s) | 台词/旁白 | 中文提示词 | 英文提示词 | 视频提示词 | 音效/配乐 | 备注 |
|------|------|------|----------|---------|-----------|------------|------------|------------|-----------|------|

景别: ELS/LS/FS/MS/MCU/CU/ECU | 运镜: 推/拉/摇/移/跟/环绕/固定


---

## 5. 短视频爆点与钩子体系

### 5.1 抖音专用钩子模式

**通用钩子**:

| 模式 | 模板 | 有效性原理 |
|------|------|----------|
| 反常识提问 | "你一定以为____，但真相是____" | 认知铺垫->反常识冲击 |
| 数据炸弹 | "____%的人不知道____" | 具体数字冲击力>模糊描述 3 倍 |
| 前后对比 | "从____到____" | 视觉对比不需要语言解释 |
| 结果前置 | 先展示结果，再倒叙 | 用结果吸引，再展开过程 |

**竖屏短剧专用钩子**:

| 模式 | 使用时机 | 示例帧(西幻) |
|------|----------|-------------|
| Immediate Accusation | 关系冲突核心 | "你骗了所有人——你不是骑士" |
| Visual Contradiction | 图像制造问题 | 新娘穿黑色盔甲出席婚礼 |
| Power Reversal | 状态快速变化 | 跪着的铁匠站起来，剑尖指着领主 |
| Secret Object | 道具承载秘密 | 旧剑柄里掉出一枚王室印章 |
| Interrupted Ceremony | 公众赌注很高 | 加冕典礼上，皇冠碎裂 |

### 5.2 悬念模式

| 模式 | 使用时机 | 结尾问题(西幻) |
|------|----------|---------------|
| Door Opens | 新人物入场 | 城门外站着的是谁？ |
| Message Reveal | 真相改变 | 古卷上写了什么？ |
| Identity Reveal | 身份反转 | 他到底是谁？ |
| Choice Forced | 必须抉择 | 效忠国王还是保护族人？ |
| Evidence Appears | 证据改变冲突 | 谁在剑上下了毒？ |

### 5.3 情绪曲线

| 曲线 | 情绪序列 | 适用 | BGM |
|------|----------|------|-----|
| Tension Release | 紧张->更紧张->释放->温馨 | 故事类 | 弦乐->安静->钢琴 |
| Curiosity Spike | 好奇->惊讶->满足->行动欲 | 揭秘类 | 电子->渐强->鼓点 |
| Anxiety Resolution | 焦虑->共鸣->希望->决心 | 成长类 | 沉重->明亮->激昂 |
| Rollercoaster | 笑->紧张->笑->感动->笑 | 娱乐类 | 音效+快速切换 |

### 5.4 中世纪西幻爆点适配

| 爆点 | 3 秒钩子 | 情绪曲线 | 悬念类型 |
|------|----------|----------|----------|
| 身份反转 | "你以为他只是个铁匠？" | Curiosity Spike | Identity Reveal |
| 权力翻转 | 跪地->王座，3 秒切换 | Tension Release | Power Reversal |
| 禁忌揭露 | "她不是人类——她从未是" | Anxiety Resolution | Message Reveal |
| 牺牲高潮 | 骑士举剑，逆光剪影 | Tension Release | Choice Forced |
| 阴谋揭示 | 每集揭一块碎片 | Curiosity Spike | Evidence Appears |


---

## 6. 美术风格一致性设计

### 6.1 质量权重分配

| 维度 | 质量权重 | 说明 |
|------|----------|------|
| 剧本 | 40% | 故事/节奏/情绪曲线 |
| 分镜 | 30% | 镜头语言/视觉叙事 |
| 选角参考图 | 20% | 决定"AI 理解你要画谁"的天花板 |
| Prompt 技巧 | 10% | 精细化控制，但不是决定性的 |

### 6.2 风格锚定

**核心原则**: 在开始任何制作之前，先确定风格锚定提示词。每次生图都包含相同的风格锚定。

**中世纪西幻风格定义**:

| 维度 | 选择 | 关键词 |
|------|------|--------|
| 主风格 | CG 电影风 / 暗黑奇幻 | cinematic, dark fantasy, photorealistic, medieval |
| 色调 | 暗沉压抑 / 高对比度 | dark, moody, high contrast, muted tones |
| 质感 | 油画 / 电影质感 | oil painting texture, film grain, cinematic depth |
| 参考 | GoT / LOTR / Dark Souls | HBO medieval, Peter Jackson LOTR, Dark Souls |

**风格锚定提示词**:
```
cinematic dark fantasy, medieval setting, high contrast lighting,
moody atmosphere, oil painting texture, film grain,
Game of Thrones inspired aesthetic, detailed armor and clothing,
dramatic shadows, cold blue and warm amber color grading,
photorealistic detail, 4K resolution, masterpiece quality.
```

**负面提示词**:
```
bright, cartoon, anime, chibi, low quality, blurry, deformed,
modern clothing, neon, cyberpunk, watermark, text, signature.
```

### 6.3 角色一致性三层保障

**第一层: 角色圣经(文字锚定)**

```markdown
## 角色身份
| 字段 | 内容 |
|---|---|
| Name | |
| Age range | |
| Role | 主角/反派/盟友/导师/对手 |

## 视觉锚点(不可变)
| 字段 | 内容 |
|---|---|
| Face | [具体: 轮廓/颧骨/下巴/疤痕] |
| Hair | [具体: 长度/颜色/质感/固定发型] |
| Body type | [具体: 身高/体型/姿态] |
| Signature clothing | [具体: 不可替换的标志性元素] |
| Color palette | [具体: 主色/辅色/点缀色] |
| Props | [具体: 随身武器/饰品] |
| Do not change | [明确列出绝对不变的元素] |

## 灵活区(可随场景变)
- 表情: 随情绪(A-01~A-15 编码)
- 姿势: 随动作(三帧定式)
- 光线: 随地点
- 衣柜: 随场景(但有故事原因)

## Prompt-safe 描述
[角色名] is a [年龄段] [角色] with [稳定视觉锚点].
Keep consistent: [脸、发、服装、色板、道具].
Flexible: [表情、姿势、光线].
```

**第二层: 参考图锚定(IP-Adapter / Reference-only)**
- 每个角色生成一组三视图(正面/侧面/背面)
- 每个表情编码配一张参考图
- 用 IP-Adapter 或 Reference-only 在生图时注入参考

**第三层: 串帧一致性(Image-to-Image 链)**
- 帧②参考帧①的输出，帧③参考帧②
- 保持角色面部/服装/色板的连续传递
- 搭配 ControlNet 控制姿态

### 6.4 场景一致性

每个场景必须定义:
- 固定空间布局
- 反复出现的道具
- 光线规则
- 色彩风格
- 适合拍摄的角度

### 6.5 视觉一致性红旗检查

| 红旗 | 检测方法 | 修复 |
|------|----------|------|
| 角色像不同的人 | 对比前后帧面部 | 加强 IP-Adapter 权重或重新选参考图 |
| 服装无故变化 | 对照角色圣经 | 在 prompt 中明确写出服装 |
| 场景元素消失 | 对照场景一致性表 | 在 prompt 中列出固定元素 |
| 色调跳跃 | 对照风格锚定 | 确认每次 prompt 都包含风格锚定段 |
| 道具矛盾 | 对照连续性记忆 | 建立 prop tracking 表 |


---

## 7. 世界观真实性合理性设计

### 7.1 魔法体系设计(Sanderson 三定律适配短视频)

**定律 1**: 魔法的局限性比能力更有趣 -- 3 秒展示代价/限制比展示威力更能吸引观众

**定律 2**: 限制 > 能力 > 代价

| 维度 | 定义 | 短剧影响 | 示例 |
|------|------|----------|------|
| 限制 | 谁能用、何时用 | 决定社会结构 | 只有贵族血统能学魔法 |
| 能力 | 能做什么 | 决定冲突类型 | 低级: 点火/照明 高级: 召唤/操控 |
| 代价 | 用后付出什么 | 决定情感深度 | 每次使用消耗寿命 |

**定律 3**: 扩展已有魔法比添加新魔法更好 -- 一个魔法体系 + 分层(学徒/骑士/大师/禁忌)

**魔法体系模板**:

```markdown
## 魔法体系
### 来源
[血统/学习/神赐/诅咒/契约]

### 层级
| 层级 | 名称 | 能力范围 | 学习年限 | 代价 |
|------|------|----------|----------|------|
| 1 | 学徒 | | | |
| 2 | 骑士 | | | |
| 3 | 大师 | | | |
| 4 | 禁忌 | | | |

### 限制(比能力更重要)
1.
2.
3.

### 代价(每次使用的后果)
1.
2.
```

### 7.2 社会结构

**封建六层体系**:

| 层级 | 角色 | 权力来源 | 天然冲突 |
|------|------|----------|----------|
| 王权 | 国王/女王 | 血统 + 军力 | 继承争议 |
| 领主 | 封建领主 | 土地 + 骑士团 | 领地争夺 |
| 教会 | 大主教 | 信仰 + 魔法知识 | 与王权对抗 |
| 商会 | 贸易联盟 | 财富 + 网络 | 控制资源 |
| 骑士 | 魔法使用者 | 魔力 + 剑术 | 个人崛起/堕落 |
| 平民 | 农民/工匠 | 数量 + 劳动 | 被压迫->反叛 |

核心洞察: 每两个相邻层级之间都有天然张力，不需要硬编冲突，社会结构本身就产出冲突。

### 7.3 经济系统

| 要素 | 设计 | 短剧用途 |
|------|------|----------|
| 货币 | 金币(贵族)/银币(骑士)/铜币(平民) + 魔法矿石(特殊) | 一句话展示阶层差距 |
| 贸易 | 王城->港口->矿山->魔法森林 | 地点多样性和场景变化 |
| 资源 | 魔法矿石只产于禁地 -> 控制权=权力 | 核心冲突驱动力 |

### 7.4 历史纵深

| 纪元 | 核心事件 | 对当前的影响 |
|------|----------|-------------|
| 远古纪 | 创世/魔法起源 | 魔法原始规则 |
| 旧王朝纪 | 第一王国/骑士团 | 现有权力结构起源 |
| 分裂纪 | 王国分裂/教会崛起 | 各势力历史正当性 |
| 黑暗纪 | 大灾变/魔法失控 | 魔法限制的历史原因 |
| 当前纪 | 故事发生 | 所有历史的当下体现 |

### 7.5 一致性检查清单

| 检查项 | 问题 | 通过标准 |
|--------|------|----------|
| 魔法一致性 | 规则在所有场景一致？ | 无违反规则的例外 |
| 社会一致性 | 权力结构在所有互动体现？ | 角色行为符合层级 |
| 经济一致性 | 货币/资源逻辑贯穿？ | 交易不矛盾 |
| 地理一致性 | 地点距离/路线合理？ | 旅行时间不矛盾 |
| 时间一致性 | 历史事件与当前对齐？ | 时间线无冲突 |
| 文化一致性 | 习俗/禁忌在所有对话遵守？ | 角色不违反文化规则 |
| 视觉一致性 | 场景/服装匹配设定纪元？ | 无时代错误元素 |


---

## 8. 完整工作流: 七阶段管线

> 整合: YubAI-DramaFlow 五阶段 + 本地 AIDramaProducer 管线 + 闭门分享方法论

```
S0 灵感层: 选题 -> 爆点验证 -> 风格锚定
S1 世界观层: 12要素构建 -> 六层模型提取 -> 冲突引擎 -> 世界圣经
S2 剧本层: 故事大纲 -> 起承转合 -> 五段结构 -> 场景节拍 -> 分镜表
S3 设计层: 角色圣经 -> 表情编码表 -> 三帧定式库 -> 场景设计 -> 资产库
S4 分镜层: 风格锚定提示词 -> 角色/场景提示词 -> MCSLA 视频提示词
S5 生成层: 关键帧图片 -> IP-Adapter 一致性 -> 三帧串帧 -> 视频片段
S6 合成层: TTS 配音 -> 字幕 -> BGM -> 剪辑 -> 导出
```

### 阶段间质量门控

| 阶段转换 | 门控检查 | 不通过则 |
|----------|----------|----------|
| S0->S1 | 3 秒钩子是否成立？ | 重新选题 |
| S1->S2 | 世界规则完整？冲突引擎能自动产出剧情？ | 补充规则 |
| S2->S3 | AI 可行性预检通过？ | 简化动作/减少多人场景 |
| S3->S4 | 角色圣经 + 表情编码 + 三帧定式库完成？ | 补全设计层 |
| S4->S5 | 提示词 < 200 英文词？负面提示词已填？ | 精简提示词 |
| S5->S6 | 视觉一致性红旗检查通过？ | 重新生成或调整参数 |


---

## 9. 提示词工程体系

### 9.1 MCSLA 视频提示词公式

**MCSLA(旧) -> 已升级为 SALCSQ 公式** (2026-06-29)

> 详见: [SALCSQ模板](/E:/UEGameDevelopment/Docs/AI/ai-shortdrama-salcsq-template.md) / [情绪路由表](/E:/UEGameDevelopment/Docs/AI/ai-shortdrama-emotion-route-table.md) / [场景路由表](/E:/UEGameDevelopment/Docs/AI/ai-shortdrama-scene-route-table.md) / [跨工具翻译](/E:/UEGameDevelopment/Docs/AI/ai-shortdrama-cross-tool-translator.md) / [质量后缀库](/E:/UEGameDevelopment/Docs/AI/ai-shortdrama-quality-suffix-library.md) / [融合设计方案](/E:/UEGameDevelopment/Docs/AI/ai-shortdrama-kb-workflow-integration-design.md)

**SALCSQ = Subject . Action . Lighting . Camera . Style . Quality**

1. Subject: 精准主体(2-3个稳定识别特征 + 服装 + 道具)
2. Action: 动作细节(具体肢体动作 + 8通道情绪外化)
3. Lighting: 光影色调(光源 + 色温 + DP签名 + 调色板 + 胶片模拟)
4. Camera: 镜头运镜(景别 + 焦段 + 光圈 + 运动 + 角度 + 9:16)
5. Style: 视觉风格(导演 + DP + 调色师签名 + 风格锚定)
6. Quality: 画质约束(质量后缀 + 负面提示词 + 物理真实感)

**与MCSLA的差异**: 新增A(动作细节)和Q(画质约束)，合并冗余模块

**SALCSQ完整示例**:

```
# 压迫+绝望 | 地牢审讯 | 8s | 9:16

Subject: A knight in chains, weathered face, darkened plate armor with rust stains.
Action: Breathing deep and slow, eye fixed ahead, jaw clenched, suppressing tremor.
Lighting: Khondji sodium orange key, no fill, crushed blacks, dungeon orange palette, Vision3 500T.
Camera: 135mm f/2.8 MCU, slow lateral dolly, narrow dungeon framing, 9:16 vertical depth.
Style: Fincher-grade desaturated, cinematic dark fantasy.
Quality: 4K ultra HD, maintaining face consistency, worn iron patina, no plastic, no beautification, no watermark.
```

### 9.2 中文 Prompt Sweet Spot

中文 prompt 的实际 sweet spot 不是 500-1000 英文词，是 **200-400 汉字**(英文的约 1/3)。绝大多数中文 AIGC 教程没讲清这一点。

- 生图 prompt: 中文 200-400 汉字 或 英文 500-1000 词
- 视频 prompt: <= 200 英文词(硬上限)
- 负面提示词: 必填
- 用英文 prompt (SD/ComfyUI/Midjourney 训练语料以英文为主)

### 9.3 光线-情绪映射

| 光线 | 英文提示词 | 情绪 | 西幻场景 |
|------|------------|------|----------|
| 黄金时刻 | golden hour, warm rim light | 浪漫/史诗 | 骑士出发 |
| 蓝调时刻 | blue hour, twilight, cool | 神秘/孤独 | 魔法森林 |
| 阴天散射 | overcast, soft diffused | 压抑/日常 | 围城 |
| 窗光 | window light, Rembrandt | 戏剧/内省 | 告解室 |
| 逆光剪影 | backlight silhouette | 英雄/史诗 | 骑士赴战 |
| 烛光 | candlelight, flickering glow | 中世纪/神秘 | 地牢/密谋 |
| 火把 | torchlight, warm flickering | 危险/紧张 | 地下城 |


### 9.4 镜头调度与摄影参数

> **详细参数速查手册**: [镜头调度与摄影参数提示词速查手册.md](/E:/UEGameDevelopment/Docs/AI/镜头调度与摄影参数提示词速查手册.md) (v4.0, 30章)
> **v2.0新增**: DP灯光签名(13节) / 导演构图签名(14节) / 9:16竖屏构图(15节) / 物理真实感(16节) / Seedance电影模式(17节) / 情绪-导演风格查表(18节) / 情绪可见行为编码(19节) / 结构化提示词输出格式(20节)
> **v3.0新增**: 构图心理学(21节) / 景别亲密梯度(22节) / 帧率与时间感(23节) / 色彩心理学(24节) / 导演视觉叙事(25节) / 知识库深度参考(26节)

#### 9.4.1 如何让画面表达情绪——导演思维方法论

**核心原理**: 情绪不是靠"写情绪词"传达的，而是靠**灯光选择+构图选择+运镜选择+调色选择**的组合共同编码的。观众不会"读到"情绪，但会"感受到"。

**五步导演思维流程**:

| 步骤 | 问题 | 查表位置 | 输出 |
|------|------|---------|------|
| 1. 锚定情绪 | 这段场景观众应该感受到什么？ | 速查手册18节 | 情绪关键词 |
| 2. 选导演+DP | 哪种导演风格天然表达这种情绪？ | 速查手册18节查表 | 导演+DP组合 |
| 3. 定构图+灯光 | 这种导演+DP的签名构图/灯光是什么？ | 速查手册13-14节 | 构图+灯光提示词 |
| 4. 选运镜+焦距 | 什么运镜和焦距配合这种情绪？ | 速查手册9节 | 运镜+焦距+景深 |
| 5. 定调色+胶片 | 什么调色方向强化这种情绪？ | 速查手册11-12节 | 调色+胶片模拟 |

**示例: 骑士赴死前的悲壮场景**

1. 锚定情绪: 悲壮、崇高、不可逆
2. 选导演+DP: Kubrick(秩序不可逃) + Deakins(冷静凝视)
3. 定构图+灯光: 中心对称纵深 + 单动机窗光+负填充
4. 选运镜+焦距: 缓慢推入 + 35mm广角纵深 + f/4中景深
5. 定调色+胶片: 冷蓝暗部+碎黑 + Vision3 500T

#### 9.4.2 构图即权力关系

**核心洞察**: 构图的本质是空间关系即权力关系——谁在画面中心谁就有权力，谁被边缘化谁就无力，谁被遮挡谁就被阻碍。

| 构图元素 | 表达权力/掌控 | 表达无力/被控 | 表达亲密/连接 | 表达疏离/断裂 |
|----------|-------------|-------------|-------------|-------------|
| 主体位置 | 中心/上方 | 边缘/下方 | 靠近镜头/偏轴 | 远离镜头/被裁切 |
| 空间占比 | 占据大量画面 | 被环境淹没 | 填满画面 | 被负空间包围 |
| 对称性 | 严格对称(掌控) | 破坏对称(失控) | 微微偏移(自然) | 强烈偏轴(断裂) |
| 前景 | 清晰(主导) | 遮挡(被阻挡) | 柔焦(亲密) | 锐利遮挡(隔离) |
| 地平线 | 低地平线(仰望) | 高地平线(俯视) | 无地平线(封闭) | 无限远(开放/无尽) |

#### 9.4.3 灯光即选择性照亮

**核心洞察**: 你选择照亮什么，就等于你选择观众关注什么。灯光的内涵来自选择性。

| 技法 | 英文提示词 | 内涵语义 | 西幻示例 |
|------|-----------|----------|----------|
| 选择性照亮 | selective illumination, only [X] lit, rest in shadow | 真相在光中，谎言在暗处 | 唯有剑柄上的王室徽记被光打亮 |
| 半脸光 | half-face lighting, split chiaroscuro | 角色内心分裂 | 骑士一半脸在火光中(忠诚)，一半在阴影中(背叛) |
| 眼光 | eye light, small specular reflection in eyes | 灵魂未灭 | 临死骑士眼中最后一点亮光 |
| 逆光剪影 | backlit, subject in silhouette, light source behind | 角色"挡住"了真相 | 国王逆光剪影，看不见表情 |
| 底光 | underlighting, light from below, unnatural | 超自然/邪恶 | 魔法仪式中火焰从下方照亮脸 |

#### 9.4.4 五大DP灯光签名速查

| DP | 签名灯光 | 英文公式 | 情绪内核 | 西幻适配 |
|----|---------|---------|----------|---------|
| Deakins | 单动机光源+负填充 | single motivated key, negative fill, no top light, Deakins-style | 冷静凝视、道德灰度 | 窗前独坐审判 |
| Lubezki | 自然黄金时段逆光 | golden hour backlight, handheld drift, wide close, Lubezki-style | 野性自由、与自然共存 | 穿越森林逆光 |
| Doyle | 实用光源+暖冷对比 | practical light, warm-cool color contrast, Doyle-style | 欲望迷失 | 酒馆火把vs月光 |
| Khondji | 钠灯橙+暗吞噬 | sodium-vapor orange, deep blacks, Khondji-style | 压迫窒息 | 地牢审讯 |
| van Hoytema | IMAX冷暖对分 | IMAX 70mm cold-warm split, van Hoytema-style | 史诗庄严 | 战场全景 |

#### 9.4.5 五大导演构图签名速查

| 导演 | 签名构图 | 英文公式 | 情绪内核 | 西幻适配 |
|------|---------|---------|----------|---------|
| Kubrick | 严格对称+单点透视 | perfect symmetry, one-point perspective, centered, Kubrick-style | 秩序控制、命运不可逃 | 王座厅对称走廊 |
| Wes Anderson | 平面色块+正面平拍 | flat tableau, centered, color blocking, Anderson-style | 童话秩序 | 魔法学院走廊 |
| Wong Kar-wai | 偏轴裁切+前景遮挡 | off-axis cropped, foreground obstruction, soft focus, Wong Kar-wai-style | 错失欲念 | 隔帘相望 |
| Tarkovsky | 长镜头+自然元素 | long take, natural elements, slow push-in, deep focus, Tarkovsky-style | 冥想神圣 | 朝圣路雨雾 |
| Nolan | IMAX极宽+对称破对称 | IMAX wide, symmetry then broken, epic proportion, Nolan-style | 史诗渺小vs宏大 | 两军对峙 |

#### 9.4.6 集成提示词解剖公式

一个完整的AI视频提示词由6个模块组成:

```
Prompt = Subject+Action + Physical_Realism + Lighting(DP-anchored) + Composition(Director-anchored) + Camera+Lens+Motion + Style_Anchor
```

**完整示例(骑士赴死)**:
```
# Subject + Action
A weathered knight in blackened plate armor kneels before the cathedral door,
sword planted in stone beside him.

# Physical Realism
Subsurface scattering on rain-wet skin. Anisotropic weave on torn cloak.
Contact physics: knees pressed into wet stone, weight distributed.
Atmospheric haze on distant towers. Bounce light from torch brackets.

# Lighting (Deakins-style)
Single motivated key from cathedral doorway, negative fill on shadow side,
no top light, naturalistic, Deakins-style.

# Composition (Kubrick-style)
Perfect symmetry, one-point perspective down the nave,
centered subject, wide angle depth, Kubrick-style.

# Camera + Lens
Slow dolly in, 35mm wide, moderate DOF f/4, 9:16 vertical frame,
subject in lower 40% (kneeling), upper 60% cathedral interior.

# Style Anchor
Cinematic dark fantasy, Kodak Vision3 500T, cold blue shadows,
crushed blacks, anamorphic rendering, 4K, masterpiece.
Negative: bright, cartoon, anime, blurry, deformed, watermark.
```

**快速组装(60秒提示词)**:
```
"A knight kneels in rain, Deakins single key light, Kubrick centered symmetry,
35mm slow dolly in f/4, cold blue crushed blacks, Vision3 500T,
9:16 vertical, cinematic dark fantasy"
```

#### 9.4.7 9:16竖屏专用规则

| 竖屏原则 | 替代横屏习惯 | 提示词 |
|----------|-------------|--------|
| 垂直纵深取代水平展开 | 横移->升降 | vertical depth, vanishing point above |
| 上下分割取代左右分割 | 左右双人->上下双人 | upper-lower split, vertical two-shot |
| 中心纵列取代水平三分法 | 三分法->中轴对称 | central vertical axis, vertical symmetry |
| 框中框用拱门/竖窗 | 横门框->竖拱门 | framed by archway, vertical frame-within-frame |
| 负空间上下留白 | 左右留白->上下留白 | negative space above/below, vast vertical emptiness |

#### 9.4.8 Seedance电影模式速选

| 场景类型 | 模式 | 标准 | 一句话选择 |
|----------|------|------|-----------|
| 角色对话/行走 | Narrative | 35-50mm+慢推+中性暖 | 日常叙事，中性偏暖 |
| 角色特写/独白 | Studio | 85-135mm+锁定+高对比 | 人像聚焦，极慢推入 |
| 打斗/追逃 | Action | 14-24mm+手持+去饱和 | 动态冲突，手持跟拍 |
| 魔法咏唱/仪式 | Performance | 50-85mm+环绕+戏剧调色 | 环绕弧线，表演展示 |
| 森林/废墟/梦境 | Atmospheric | 24-35mm+漂浮+极端调色 | 长镜头漂浮，氛围沉浸 |

#### 9.4.9 情绪可见行为编码速查

情绪不止是脸上表情，而是全身8通道的物理变化:

| 通道 | 英文提示词 | 示例(A-07悲壮态) |
|------|-----------|-----------------|
| 呼吸 | breathing: [shallow/deep/ragged/holding] | deep and slow, deliberate |
| 眼部 | eye behavior: [darting/fixed/glistening] | glistening, fixed ahead |
| 下颌 | jaw tension: [clenched/relaxed/grinding] | clenched, grinding |
| 失焦 | loss of focus: [present/distant/staring-through] | distant, thousand-yard stare |
| 扫描 | scanning: [sweeping/locked/avoidant] | locked forward |
| 延迟 | delayed recovery: [instant/slow/frozen] | slow blink, delayed |
| 控制 | control attempt: [suppressing/steadying/failing] | hand on sword, suppressing tremor |
| 残留 | emotional residue: [afterglow/scar/echo] | wetness in eyes, shoulders squared |

#### 9.4.10 物理真实感8层必检清单

每镜头提交前逐项检查:

- [ ] 皮肤: SSS提示词？(塑料脸=废片)
- [ ] 液体: 水/血/药水有Fresnel吗？
- [ ] 布料: 服装有编织质感？
- [ ] 接触: 手握/放置有接触物理？
- [ ] 解剖: 手部特写指节正确？
- [ ] 大气: 远景有大气透视？
- [ ] 光弹: 暗部有间接光/色溢？
- [ ] 微纹理: 铠甲/石墙有磨损/划痕？

#### 9.4.11 速查索引

| 需要查什么 | 速查手册章节 |
|-----------|-------------|
| 运镜词汇 | 1节 |
| 视角/机位 | 2节 |
| 景别/构图 | 3节 |
| 焦距/景深 | 4节 |
| 镜头行为序列 | 5节 |
| 四层运动层级 | 6节 |
| 摄影机契约 | 7节 |
| 构图规则 | 8节 |
| 情绪-运镜-焦距速查(西幻) | 9节 |
| 运动速度锚定 | 10节 |
| 色彩分级 | 11节 |
| 胶片模拟 | 12节 |
| DP灯光签名 | 13节 |
| 导演构图签名 | 14节 |
| 9:16竖屏构图 | 15节 |
| 物理真实感清单 | 16节 |
| Seedance电影模式 | 17节 |
| 情绪-导演风格查表 | 18节 |
| 情绪可见行为编码 | 19节 |
| 结构化提示词输出格式 | 20节 |
| 构图心理学/格式塔/视觉流动 | 21节 |
| 景别亲密梯度/10级景别 | 22节 |
| 帧率与时间感/慢动作设计 | 23节 |
| 色彩心理学/9色进化/色温叙事 | 24节 |
| 导演视觉叙事/5层决策/6通道 | 25节 |
| 导演风格知识库深度参考 | 26节 |
| 镜头心理学深潜/焦段情绪图谱/焦段组合序列 | 27节 |
| 反应镜头与对切语法/沉默叙事 | 28节 |
| 调色即叙事/12种西幻调色板/色温曲线 | 29节 |
| 构图即情绪/10种情绪构图公式/框中框 | 30节 |


---

#### 9.4.12 导演思维完整工作流——从情绪到提示词的七步管线

> 整合速查手册全部30章 + 知识库52文件 + 五层决策金字塔，形成从"我想表达X情绪"到"完整AI视频提示词"的端到端流程

**七步管线**:

| 步骤 | 问题 | 查什么 | 输出 |
|------|------|---------|------|
| 1. 锚定情绪 | 观众应感受到什么？ | 速查18节(情绪-导演查表) + 30节(构图即情绪) | 情绪关键词+构图公式 |
| 2. 选调色板 | 什么色彩体系天然表达这种情绪？ | 速查29节(12种西幻调色板) | 调色板+色温曲线 |
| 3. 定焦段姿态 | 观众以什么心理姿态观看？ | 速查27节(焦段情绪图谱) | 焦段+光圈+景别 |
| 4. 定构图+灯光 | 这种情绪的签名构图/灯光？ | 速查30节(构图即情绪)+13-14节(DP/导演签名) | 构图+灯光提示词 |
| 5. 定运镜+时间感 | 什么运动+什么时间感？ | 速查1节(运镜)+23节(帧率时间感) | 运镜+帧率+时间设计 |
| 6. 定反应/对切 | 对话场景如何传递情绪？ | 速查28节(对切语法+反应镜头) | 对切模式+反应策略 |
| 7. 组装+检查 | 拼装完整提示词+检查物理真实感 | 速查20节(结构化输出)+16节(物理清单) | 最终提示词 |

**完整示例: 骑士被宣判叛国罪**:

- Step 1 锚定情绪: 压迫+绝望+不可逆
- Step 2 选调色板: 地牢橙(钠灯橙+黑+暗褐+铁锈) + 压迫曲线(4000K→8000K)
- Step 3 定焦段: 135mm(被逼视的困困)+f/2.8(浅景深隔离)+MCU(心理极近)
- Step 4 定构图+灯光: 压迫构图(环境包围+窄框)+Khondji钠灯橙+半脸光(分裂)
- Step 5 定运镜: 缓慢横移(空间收窄)+24fps(经典时间)
- Step 6 定反应: 渐近对切(OTS→MCU→CU→ECU)+延迟反应(2拍)+无反应(最强)
- Step 7 组装:

```
A knight in chains, half-face split by sodium orange light,
135mm f/2.8 MCU, environment closing in, narrow dungeon framing,
slow lateral dolly, Khondji-style, dungeon orange palette,
crushed blacks, iron rust tones, oppressive composition,
9:16 vertical, cinematic dark fantasy, Kodak Vision3 500T.
Negative: bright, cartoon, anime, blurry, deformed.
```

**15秒抖音极速版(3步)**:

| 步骤 | 查 | 输出 |
|------|---|------|
| 1. 情绪→调色板 | 29节 | 一句话调色 |
| 2. 情绪→构图+焦段 | 30节即时映射表 | 一句话构图+焦段 |
| 3. 拼装 | 主体+动作+1+2+9:16 | 完整提示词 |

示例: "骑士被宣判" → 地牢橙 + 压迫构图135mm →
`A knight in chains, dungeon orange palette, 135mm f/2.8 MCU, environment closing in, Khondji-style, 9:16 vertical, cinematic dark fantasy`


## 10. AI 可行性评估与风险控制

### 10.1 可行性评分

| 评估项 | 权重 | 高风险信号 |
|--------|------|-----------|
| 人物设计 | 20% | >3 人同框、角色外观剧烈变化 |
| 场景设计 | 20% | >50% 复杂室外场景 |
| 动作设计 | 25% | 打斗/舞蹈/精细动作占比>30% |
| 运镜设计 | 15% | 复杂运镜>20% |
| 整体协调 | 20% | 风格不统一、连续性差 |

### 10.2 中世纪西幻特有风险

| 风险 | 可能性 | 影响 | 缓解 |
|------|--------|------|------|
| 铠甲/武器不一致 | 高 | 角色识别崩坏 | 铠甲作为 Do not change 项 |
| 魔法特效失败 | 高 | 视觉质量下降 | 用剪影/逆光代替直接特效 |
| 多种族角色混淆 | 中 | 观众分不清角色 | 每个种族用独特色板 |
| 历史细节错误 | 中 | 世界观可信度下降 | 一致性检查清单 |
| 城堡/场景重复感 | 中 | 视觉疲劳 | 每个场景有独特视觉锚点 |

### 10.3 Prompt 可行性规则

| 规则 | 级别 |
|------|------|
| 每镜头 prompt <= 200 英文词 | MUST |
| negative_prompt 必填 | MUST |
| 避免 >5 人同框 | MUST |
| 避免复杂光学(镜中倒影/水下) | SHOULD |
| 动作用具体动词 | MUST |
| 连续镜头角色位置/朝向连贯 | SHOULD |

---

## 11. 本地工具链与资源

### 11.1 AIDramaProducer 管线

路径: `E:/UEGameDevelopment/Project/AIDramaProducer/skills/`

| 模块 | 功能 | 对应阶段 |
|------|------|----------|
| ai_drama_scriptwriter | 剧本生成、角色提取、分镜 | S2 剧本层 |
| ai_drama_viral_analyzer | 爆款分析、风格注入 | S0 灵感层 |
| ai_drama_asset_generator | 角色/场景资产生成 | S3 设计层 |
| ai_drama_keyframe_generator | 关键帧图片生成 | S4->S5 |
| ai_drama_video_generator | 视频片段生成 | S5 生成层 |
| ai_drama_tts_generator | TTS 配音 | S6 合成层 |
| ai_drama_compositor | 视频合成导出 | S6 合成层 |
| ai_drama_orchestrator | 全流程编排 | 全阶段 |
| ai_drama_preproduction_studio | 前期制作 Web UI | S0-S4 |

### 11.2 Skill 级工具

路径: `E:/UEGameDevelopment/.agents/skills/`

| Skill | 功能 |
|-------|------|
| ai-video-creator | 六阶段: 灵感->立项->剧本->角色->分镜->视频提示词 |
| ai-video-director | 分镜剧本->平台级视频生成提示词 |
| ai-drama-scriptwriter | 故事->结构化分镜剧本 |
| ai-drama-viral-analyzer | 爆款分析+风格复制+融合创作 |

### 11.3 知识库

| 文件 | 内容 |
|------|------|
| hook-patterns.md | 6 种钩子模式 |
| narrative-structures.md | 5 种叙事结构 |
| emotional-curves.md | 4 种情绪曲线 |
| creator-styles.md | 博主风格(待填充) |

### 11.4 参考文档

| 文档 | 位置 |
|------|------|
| AI 短剧生态调研 | `Project/AIDramaProducer/docs/early-references/ai-drama-ecosystem-research.md` |
| 中世纪西幻创作参考手册 | `Docs/AI/中世纪西幻AI短视频-创作参考手册.md` |
| 镜头调度与摄影参数速查手册(v4.0, 30章) | `Docs/AI/镜头调度与摄影参数提示词速查手册.md` |

---



### 11.5 导演风格知识库

路径: `Docs/AI/director-style-kb/`

| 文件 | 领域 | 导演/风格数量 |
|------|------|---------|
| [README.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/README.md) | 路由索引(v14.0, 全维度+中国短剧+2026趋势) | 全部190+ |
| [crime-thriller-directors.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/crime-thriller-directors.md) | 犯罪/悬疑/黑色 | 5 |
| [fantasy-epic-directors.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/fantasy-epic-directors.md) | 奇幻/史诗/中世纪(最核心) | 5 |
| [horror-dark-directors.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/horror-dark-directors.md) | 恐怖/暗黑/哥特/心理 | 6(Kubrick/Eggers/Aster/Carpenter/Nosferatu-2024/Northman) + 帧级拉片 + 5场景模板 |
| [war-history-drama-directors.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/war-history-drama-directors.md) | 战争/历史/文艺/爱情 | 5 |
| [scifi-special-directors.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/scifi-special-directors.md) | 科幻/短视频/分镜师 | 3+ |
| [action-martial-directors.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/action-martial-directors.md) | 动作/武侠/格斗/追车 | 5 |
| [tv-series-novel-adaptation.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/tv-series-novel-adaptation.md) | 剧集/小说改编/长线叙事 | 6 |
| [arthouse-female-animation.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/arthouse-female-animation.md) | 文艺/女性导演/动画/风格化 | 5 |
| [european-masters.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/european-masters.md) | 欧洲/哲学/存在主义/超现实 | 4 |
| [latinam-crosscultural.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/latinam-crosscultural.md) | 拉美/跨文化/魔幻现实 | 4 |
| [asian-indie-directors.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/asian-indie-directors.md) | 亚洲深度/美国独立/极简 | 5 |
| [psychological-body-horror.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/psychological-body-horror.md) | 心理惊悚/身体恐怖/极端 | 3 |
| [contemporary-absurd-sensory.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/contemporary-absurd-sensory.md) | 当代欧洲/荒诞/感官/女性凝视 | 4 |
| [classic-onetake-meta.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/classic-onetake-meta.md) | 经典好莱坞/一镜到底/元叙事 | 5 |
| [crime-noir-urban.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/crime-noir-urban.md) | 犯罪/黑帮/都市夜景 | 3 |
| [anxiety-contemporary-supplement.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/anxiety-contemporary-supplement.md) | 焦虑/当代/女性/补充 | 5 |
| [quickcut-comedy-lowbudget.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/quickcut-comedy-lowbudget.md) | 快速剪辑/喜剧/低成本 | 3 (Wright, Rodriguez, Linklater) |
| [game-aesthetic-crossover.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/game-aesthetic-crossover.md) | 游戏/动画跨界/环境叙事(中世纪西幻核心) | 5+ (FromSoftware, Zelda, ICO, Witcher, Dogma) |
| [deep-supplement-directors.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/deep-supplement-directors.md) | 深度拉片/场景解构/导演深潜 | 7 (Kubrick/Cuaron/Tarantino/Snyder/Refn/Anderson/del Toro/Jackson深潜) |
| [documentary-nature-observational.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/documentary-nature-observational.md) | 纪录片/自然/观察/沉思 | 6 (Herzog, Wiseman, Attenborough, Leviathan, Morris, Fricke) |
| [asian-drama-cinematic.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/asian-drama-cinematic.md) | 亚洲剧集/韩国惊悚/中国作者 | 7 (Na Hong-jin, Kim Jee-woon, Lee Chang-dong, Kiyoshi Kurosawa, Diao Yinan, Lou Ye, Feng Xiaogang) |
| [animation-masters.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/animation-masters.md) | 动画大师/风格化3D/定格 | 6 (Shinkai, Takahata, Oshii, Yuasa, Spider-Verse, Laika) |
| [music-video-visual.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/music-video-visual.md) | MV视觉/节奏驱动/短视频 | 7 (Fincher MV, Jonze MV, Gondry, Hype Williams, Sigismondi, Kahn, Murai) |
| [production-designer-artdir.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/production-designer-artdir.md) | 美术指导/世界构建/场景设计 | 6 (Ferretti, Carter, Craig, Beachler, Vermette, Dyas) |
| [storyboard-visual-planning.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/storyboard-visual-planning.md) | 分镜设计/故事板/镜头序列/竖屏适配 | 5层框架+10+10序列+4位分镜师签名+竖屏9:16规则+分镜→提示词工作流 |
| [colorist-signature-grade.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/colorist-signature-grade.md) | 调色师签名/色彩分级/情绪→色彩/DaVinci节点 | 10(Sonnenfeld/Poole/Gervais/Fersti/Bogdanowicz/Weidt/Walker/Sonnet/Lucas/Graham) + 胶片模拟 + 场景级拆解 |
| [lighting-design-signatures.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/lighting-design-signatures.md) | 灯光设计签名/光即叙事/影即情绪 | 8位灯光师(Semler/Kaminski/Nykvist/Deschanel/Prieto/Alcott/Savides/Deakins) + 情绪→光映射 + 5场景模板 |
| [production-design-worldbuilding.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/production-design-worldbuilding.md) | 美术设计/世界构建/空间即叙事 | 5层世界架构+7种建筑风格+4位PD签名+一致性检查清单 |
| [editor-signature-rhythm.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/editor-signature-rhythm.md) | 剪辑师签名/剪辑节奏/切点逻辑 | 6 (Murch, Schoonmaker, Smith, Sixel, Walker, Tichenor) |
| [douyin-shortform-visual.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/douyin-shortform-visual.md) | 抖音/短视频/竖屏/平台原生 | 6+4+3 (视觉模式+节奏模式+场景模板) |
| [sound-design-emotion.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/sound-design-emotion.md) | 声音设计/沉默美学/音画协同 | 4(Burtt/Lievsay/Rydstrom/Murch) + 4部拉片 + 5场景模板 + AI声音实践 |
| [genre-grammar-deepdive.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/genre-grammar-deepdive.md) | 类型片语法→中世纪翻译 | 5类型(西部/黑色/战争/恐怖/科幻) + 5种混搭 |
| [medieval-fantasy-pattern-library.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/medieval-fantasy-pattern-library.md) | 中世纪西幻视觉范式/角色原型/场景直出 | 30范式+12角色原型+20场景提示词 |
| [costume-armor-design.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/costume-armor-design.md) | 服装/铠甲设计签名/色彩编码 | 5 (Dickson, Ishioka, Atwood, Beavan, Carter) + 9种铠甲 + 9种材质 |
| [key-work-deepdive.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/key-work-deepdive.md) | 经典作品深度拉片 | True Detective S1+LOTR Helm's Deep+GoT Red Wedding+8经典场景 |
| [narrative-structure-template.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/narrative-structure-template.md) | 叙事结构模板/节拍表 | 英雄之旅8步+五段式+三幕式+5种短视频模板+5种西幻叙事弧 |
| [vfx-visual-effects.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/vfx-visual-effects.md) | VFX/魔法可视化/AI视频特效 | 4 (Dykstra, Muren, Legato, Franklin) + 5种魔法风格 + AI VFX规则 |
| [mythology-visual-roots.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/mythology-visual-roots.md) | 神话视觉根源/文化DNA | 4体系(北欧/凯尔特/亚瑟王/日耳曼哥特) |
| [key-scenes-supplement.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/key-scenes-supplement.md) | 经典西幻场景拉片补充 | Pan's Labyrinth+Dune+Excalibur+Dark Crystal+10场景 |
| [prompt-assembly-guide.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/prompt-assembly-guide.md) | 综合提示词组装指南/AI工具实战 | 六步法+60秒/15秒模板+10大组合+5秒公式+AI失败诊断+完整60秒脚本 |
| [medieval-fantasy-quickref.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/medieval-fantasy-quickref.md) | 中世纪西幻速查手册 | 20个最常用提示词(直接粘贴)+10组最强组合+竖屏检查清单 |
| [chinese-short-drama-aesthetics.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/chinese-short-drama-aesthetics.md) | 中国短剧美学/竖屏短剧 | 6大流派+4大情绪公式+6种钩子→西幻翻译+5种角色原型 |
| [contemporary-trends-2024-2026.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/contemporary-trends-2024-2026.md) | 2024-2026最新视觉趋势 | 5大AI视频美学+6大短视频风格+新兴导演+AI最佳实践8条 |
| [cinematography-deep-dive.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/cinematography-deep-dive.md) | 摄影学深潜/构图心理学/视觉流动/镜头特性/帧率/时间感 | 格式塔5原则+视觉重量+8种流动+10级景别+镜头特性+帧率+光圈快门+滤镜 |
| [director-visual-narrative.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/director-visual-narrative.md) | 导演视觉叙事/镜头语法/色彩心理学/三位一体工作流 | 5层决策+6通道编码+通道冲突+9色进化+色温叙事+导演-分镜-剪辑+5场景示例 |
| [med-fantasy-screen-deepdive.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/med-fantasy-screen-deepdive.md) | 中世纪奇幻银幕作品深度拉片 | 10部作品(Green Knight/Northman/Nosferatu 2024/HOTD/Dune2/Excalibur/Last Kingdom/Witcher/Dark Crystal/Pan's Labyrinth) |
| [director-signature-encyclopedia.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/director-signature-encyclopedia.md) | 导演签名百科/6维度统一整合 | 36位导演完整签名(构图+光线+调色+运镜+剪辑+叙事)+一句话速查 |
| [dp-signature-extended.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/dp-signature-extended.md) | 摄影指导签名扩展/15位DP | 10位新增DP(Storaro/Willis/Kaminski/Richardson/Savides/Nykvist/Delbonnel/Yeoman/Deschanel/Walker)+15种配对 |
| [true-detective-deepdive.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/true-detective-deepdive.md) | 真探深度拉片/南方哥特/沼泽神秘 | S1完整(6分钟一镜+3场景拉片)+S2霓虹黑色+S3时间线色彩+5条原则+6种西幻映射 |
| [short-video-hook-practice.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/short-video-hook-practice.md) | 短视频钩子/节奏/转场实战 | 8种3秒钩子+15/30/60秒模板+8种竖屏转场+6条算法铁律+5个西幻脚本 |
| [recent-fantasy-tv-deepdive.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/recent-fantasy-tv-deepdive.md) | 近年奇幻剧集视觉深度拉片 | 5部(Rings of Power/Wheel of Time/Shadow and Bone/His Dark Materials/Willow)+3条核心原则 |
| [classic-sword-sorcery-film.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/classic-sword-sorcery-film.md) | 经典剑与魔法电影拉片 | 5部(Conan/13th Warrior/King Arthur 2004/Solomon Kane/Beowulf)+场景拉片 |
| [ai-video-tool-prompting.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/ai-video-tool-prompting.md) | AI视频工具提示词策略 | Kling/Seedance/Vidu/Wan/Sora各自最佳实践+7条铁律+工具选择决策树 |
| [fantasy-character-visual-encyclopedia.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/fantasy-character-visual-encyclopedia.md) | 西幻角色原型视觉百科 | 12种角色完整视觉配方(体型/服装/面部/光线/构图/调色)+13种角色组合 |
| [western-classic-deepdive.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/western-classic-deepdive.md) | 西部片经典深潜/荒原美学 | 4 (Leone/Ford/Peckinpah/Eastwood) + 西幻翻译表 |
| [musical-dance-visual.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/musical-dance-visual.md) | 音乐片/舞蹈视觉/编舞即叙事 | 4 (Fosse/Chazelle/Berkeley/Marshall) + 西幻翻译表 |
| [romance-melodrama-visual.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/romance-melodrama-visual.md) | 浪漫/情节剧/欲望即构图 | 4 (Sirk/Demy/Ozu/Wong Kar-wai浪漫) + 西幻翻译表 |
| [silent-expressionist-pioneer.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/silent-expressionist-pioneer.md) | 默片/表现主义/蒙太奇先驱 | 4 (Murnau/Lang/Eisenstein/Dreyer) + 西幻翻译表 |
| [neo-noir-modern-thriller.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/neo-noir-modern-thriller.md) | 新黑色/现代惊悚/A24美学 | Fincher深潜+Villeneuve深潜+PTA深潜+A24 + 西幻翻译表 |
| [documentary-essay-film.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/documentary-essay-film.md) | 纪录片/散文电影/观察美学 | 7(Varda+Marker+Resnais+Herzog+Wiseman+Morris+Leviathan) + 场景模板 + 西幻翻译 |
| [mystery-deduction-visual.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/mystery-deduction-visual.md) | 推理/悬疑/线索即构图 | Hitchcock深潜+Johnson+Branagh+Lynch深潜 + 西幻翻译表 |
| [epic-historical-deepdive.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/epic-historical-deepdive.md) | 史诗历史片深潜 | Scott深潜+Gibson+Boorman+Mann历史 + Excalibur语法 + 西幻翻译 |
| [surrealism-dream-cinema.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/surrealism-dream-cinema.md) | 超现实/梦境电影 | 5(Bunuel+Cocteau+Svankmajer+Jodorowsky+Lynch) + 深度拉片 + 场景模板 + 西幻翻译 |
| [korean-cinema-deepdive.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/korean-cinema-deepdive.md) | 韩国电影深潜 | Park深潜+Bong深潜+Kim深潜+Na深潜 + 西幻翻译 |
| [italian-neorealism-newhollywood.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/italian-neorealism-newhollywood.md) | 意大利新现实主义/新好莱坞 | De Sica+Coppola+Scorsese深潜+Altman + 西幻翻译 |
| [nordic-crime-dark-visual.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/nordic-crime-dark-visual.md) | 北欧犯罪/暗黑视觉 | 8(Bron/Killing/Refn-Pusher/Refn-Bleeder/Trapped/Break/Bordertown) + 4DP + 5场景模板 + 西幻翻译 |
| [specific-film-deepdives-v2.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/specific-film-deepdives-v2.md) | 关键影片帧级拉片V2 | Nosferatu 2024+Dune Part Two+Green Knight 帧级分析 |
| [master-route-quickref.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/master-route-quickref.md) | 灵感路由速查(A-AY全51节, 情绪→KB秒定位) | v9.0 |
| [ai-prompt-to-result-patterns.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/ai-prompt-to-result-patterns.md) | AI提示词-视觉效果映射/情绪-提示词-偏差修复 | 20情绪+20场景+6渐变+竖屏适配+5示例+诊断流程 |
| [ai-shortdrama-workflow-template.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/ai-shortdrama-workflow-template.md) | AI短剧完整工作流/创意到发布7阶段 | 每阶段可操作指引+决策表+速查一页纸 |
| [a24-indie-deepdive.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/a24-indie-deepdive.md) | A24美学/新锐独立导演/类型重定义 | A24六层DNA+10位A24导演+10位新锐签名+10西幻场景模板 |
| [storyboard-artist-deepdive.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/storyboard-artist-deepdive.md) | 分镜师签名/视觉规划/序列设计 | 8位分镜师+5步转化法+5序列模板 |
| [art-direction-deepdive.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/art-direction-deepdive.md) | 美术指导签名/世界构建方法论/场景设计 | 8位PD+5种世界构建+10条场景原则 |
| [genre-deepdive-extended.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/genre-deepdive-extended.md) | 类型片深化(灾难/体育/青春/传记/家庭) | 5类型+20位导演+15场景模板 |
| [asian-european-deepdive.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/asian-european-deepdive.md) | 亚洲/欧洲导演深化(日本6+韩国4+欧洲4) | 14位导演+10场景模板 |
| [shortform-creator-aesthetics.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/shortform-creator-aesthetics.md) | 短视频原生创作者美学/跨平台策略/爆款模板 | 3平台美学+10爆款模式+10西幻模板+8种视觉风格 |
| [nonwestern-cinema-dp-deepdive.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/nonwestern-cinema-dp-deepdive.md) | 非西方电影(印度/中东/非洲)+DP作品集 | 14位导演+6位DP 27部作品+15场景 |
| [transition-matchcut-encyclopedia.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/transition-matchcut-encyclopedia.md) | 转场/匹配剪辑百科 | 7大类40+变体+12条速查 |
| [specific-film-frame-analysis-v2.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/specific-film-frame-analysis-v2.md) | 中世纪西幻帧级拉片第二卷 | 5作品+10条速查 |
| [lighting-color-ai-recipes.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/lighting-color-ai-recipes.md) | 灯光与调色AI工具实战配方 | 12灯光+12调色+8修复 |





| [composition-director-emotion.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/composition-director-emotion.md) | 构图即情绪/导演构图决策/权力关系/竖屏9:16规则 | 15构图原则+10权力模式+12导演签名+6序列+15竖屏规则+10快速公式+8构图色彩协同 |
| [viral-psychology-human-hooks.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/viral-psychology-human-hooks.md) | 病毒心理/注意力经济/完播率/点击率/成瘾机制/内容安全 | 15心理钩子+10点击公式+12完播策略+8成瘾模式+10安全规则+20病毒组合+8算法铁律 |
| [novel-to-visual-grammar.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/novel-to-visual-grammar.md) | 文本到视觉翻译/叙事结构映射/叙事者→摄像机/改编技巧 | 30翻译规则+12结构映射+12叙事者类型+30情绪查表+LOTR案例+10改编规则+8导演签名+5步工作流 |
| [masterpiece-visual-essence.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/masterpiece-visual-essence.md) | 杰作精华/帧级拉片/情绪链/构图解构/导演决策/混合公式 | 15作品深潜(帧级+构图+情绪链+导演决策)+15西幻路由+10混合公式+5拍情绪链模板 |
| [color-art-emotion-expression.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/color-art-emotion-expression.md) | 调色即情绪/美术风格/色彩心理学/世界构建 | 40调色板(权力/恐惧/自然/亲密/冲突/超越/AI修复)+15世界构建风格+10色温规则 |
| [composition-narrative-grammar.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/composition-narrative-grammar.md) | 构图叙事语法/情绪构图公式/焦段世界观 | 30情绪构图公式+15运镜类型+10焦段世界观+8帧率模式+6画幅比 |
| [ai-native-director-signatures.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/ai-native-director-signatures.md) | AI原生视觉语言/新兴导演/AI趋势 | 8种AI原生视觉+15新兴导演+10趋势+7工具优势+10西幻模板 |
| [chinese-directors-aesthetics.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/chinese-directors-aesthetics.md) | 中国导演美学/第五代/第六代/香港 | 4第五代+4第六代+4香港+张艺谋5色板 |
| [horror-thriller-visual-grammar.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/horror-thriller-visual-grammar.md) | 恐怖惊悚视觉语法/恐惧构图/恐怖导演 | 7恐惧语法+15恐怖导演+10恐怖构图+8恐惧声音 |
| [new-hollywood-german-newwave.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/new-hollywood-german-newwave.md) | 新好莱坞/德国新浪潮 | Scorsese/Coppola/Altman/Friedkin/Peckinpah + Fassbinder/Herzog/Wenders |
| [editor-deepdive-signatures.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/editor-deepdive-signatures.md) | 剪辑师深度签名/短视频节奏 | 6剪辑师深潜+10短视频节奏+20切即情绪+10三位一体组合 |
| [british-cinema-tv-visual.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/british-cinema-tv-visual.md) | 英国电影电视视觉传统 | 6视觉传统+8导演+8剧集+6调色板+3场景深潜 |
| [contemporary-indie-sensory.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/contemporary-indie-sensory.md) | 当代独立/慢电影/感官电影 | 慢电影4+感官4+身份4 |
| [japanese-directors-deepdive.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/japanese-directors-deepdive.md) | 日本导演深潜 | 小津/黑泽/沟口/大岛/今村/北野/是枝/黑泽清+7天气类型+6日式美学 |
| [russian-eastern-european-visual.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/russian-eastern-european-visual.md) | 俄罗斯/东欧视觉 | 塔尔科夫斯基深潜(7签名+3场景)+兹维亚金采夫+帕拉贾诺夫+6调色板 |
| [latin-american-visual-deepdive.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/latin-american-visual-deepdive.md) | 拉美视觉深潜 | 伊纳里图深潜+卡隆深潜+格拉+6视觉传统+8调色板 |
| [viral-meme-inspiration-vault.md](/E:/UEGameDevelopment/Docs/AI/director-style-kb/viral-meme-inspiration-vault.md) | Meme/互联网美学/亚文化/神话/游戏/国潮/科学/AI原生/时尚/叙事/迷幻/废墟/身体/声音/密教/深海/人偶/混搭/跨文化/珍奇柜/舞蹈/地图/面具/仪式/材质/手势/数学/门径/幽灵学/侘寂/欧普/时间/抖音趋势(v8.0) | 973注入点, 65章节 |
**使用流程**: 确定情绪 -> 查路由表(5维度) -> 打开KB -> (可选)查游戏美学路由 -> 组装提示词 -> 适配竖屏 -> 检查物理真实感
## 12. 开源资源索引

### 12.1 方法论与模板

| 仓库 | 核心价值 |
|------|----------|
| [clipcurator/ai-short-drama-worldbuilding-kit](https://github.com/clipcurator/ai-short-drama-worldbuilding-kit) | 世界圣经模板、地点系统 |
| [clipcurator/vertical-drama-script-formats](https://github.com/clipcurator/vertical-drama-script-formats) | 竖屏短剧格式、钩子/悬念 |
| [clipcurator/ai-character-continuity-kit](https://github.com/clipcurator/ai-character-continuity-kit) | 角色圣经、视觉一致性 |
| [clipcurator/ai-storyboard-prompts](https://github.com/clipcurator/ai-storyboard-prompts) | 双语提示词包 |
| [clipcurator/ai-short-drama-production-workflows](https://github.com/clipcurator/ai-short-drama-production-workflows) | 生产流程文档 |
| [clipcurator/ai-drama-episode-arc-templates](https://github.com/clipcurator/ai-drama-episode-arc-templates) | 5 种剧情弧 |
| [clipcurator/ai-drama-scene-beat-templates](https://github.com/clipcurator/ai-drama-scene-beat-templates) | 5 种场景节拍 |
| [clipcurator/ai-drama-prompt-qa-checklist](https://github.com/clipcurator/ai-drama-prompt-qa-checklist) | 提示词 QA |
| [clipcurator/ai-short-drama-visual-continuity-prompt-pack](https://github.com/clipcurator/ai-short-drama-visual-continuity-prompt-pack) | 视觉连续性 |
| [xiaoqinyudan2022-hue/YubAI-DramaFlow](https://github.com/xiaoqinyudan2022-hue/YubAI-DramaFlow) | 五阶段+9 中文模板 |
| [Prism6/WorldBuilder](https://github.com/Prism6/WorldBuilder) | 12 要素构建工具 |
| [OSideMedia/higgsfield-ai-prompt-skill](https://github.com/OSideMedia/higgsfield-ai-prompt-skill) | MCSLA 公式 |
| [Creepybits/World_weaver](https://github.com/Creepybits/World_weaver) | 文本继承一致性 |

### 12.2 数据集

| 仓库 | 核心价值 |
|------|----------|
| [vaew/SkyScript-100M](https://github.com/vaew/SkyScript-100M) | 10 亿对剧本-分镜脚本 |

### 12.3 生产平台

| 仓库 | 定位 |
|------|------|
| [chatfire-AI/huobao-drama](https://github.com/chatfire-AI/huobao-drama) | 一站式短剧平台 |
| [waooAI/waoowaoo](https://github.com/waooAI/waoowaoo) | 工业级全流程 |
| [HBAI-Ltd/Toonflow-app](https://github.com/HBAI-Ltd/Toonflow-app) | 一站式创作工具 |
| [Forget-C/Jellyfish](https://github.com/Forget-C/Jellyfish) | 竖屏短剧生产 |

---

## 13. 原文存档

### 13.1 闭门分享原文

> 我刚从一个朋友那回来，他请了个头部 MCN 里的 AI 漫剧负责人来闭门分享，据说这人是从大厂招过去的。
>
> 两个小时讲得很实在，没画大饼。我把最干的两条记下来，大家可以参考。
>
> **第一条:微表情身份证**
>
> 别再写"她害羞地笑了一下"。AI 听不懂，只会画出一堆似笑非笑的脸。
>
> 他们的做法是把表情拆成"五点定位":
>
> - A-01 轻悦态: 眼角弯月牙 + 嘴角上扬 + 下巴微收
> - A-02 压抑态: 唇抿线 + 眉心上抬 + 眼下斜
> - A-03 压迫态: 眉头紧锁 + 鼻翼微张 + 下颌前突 + 嘴角下撇
> - A-04 顿悟态: 眉挑高 + 眼睁圆 + 唇微张
> - A-05 平静态: 面部放松 + 目光平视 + 唇闭
>
> 然后在提示词里直接写: "全程保持 A-03 状态，然后执行动作"。角色一致性立刻稳了。
>
> **第二条:连续动作别用一段 prompt**
>
> 别写"她围好了围巾"。AI 会画出她拿着围巾发呆。
>
> 拆成三张图:起、转、收。
>
> - 帧①(起): 指尖快碰到围巾尾巴，距离 3 厘米，手指悬空
> - 帧②(转): 食指中指夹住边缘，往上拉到锁骨，接触点明确
> - 帧③(收): 围巾平整盖在肩膀，手自然放下
>
> 三张分开生成，最后合成。因为 AI 理解姿态，不理解动作。

### 13.2 图片附件清单(5 张)
- d30092d9e568b6c48e453d12cc34f283.jpg -- Jellyfish GitHub 推荐
- 50a44e4cebd494e359b624a872c8f60b.jpg -- 镜头语言第 3 期
- c2afd55d020c4c18fb95600a7e22b74e.jpg -- 镜头类型清单
- 2295f114addb6bf3af586c92ccfbe83f.jpg -- 镜头类型清单(续)
- 149fe898fb29cc460ce4906dce541a03.jpg -- token 评论互动

源路径: `C:/Users/87372/Documents/Tencent Files/873725860/nt_qq/nt_data/Pic/2026-06/Ori/`

---

*文档位置*: `Docs/Analysis/2026-06-28-ai-comic-methodology.md`
*版本*: v3.0 | 完整 AI 短剧工作流方法论
*下一步*: Ba Ba 确定选题后，按七阶段管线从 S0 开始执行








