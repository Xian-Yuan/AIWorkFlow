# AI 短剧知识库-工作流-提示词融合设计方案

> 版本: v1.0 | 日期: 2026-06-29
> 状态: 设计方案（待 Ba Ba 确认后实施）
> 用途: 将导演风格知识库(90+文件/1.65MB)、镜头调度速查手册(30章/102KB)、七阶段管线方法论融合为"对话即创作"的端到端工作流
> 关联: 2026-06-28-ai-comic-methodology.md / 镜头调度与摄影参数提示词速查手册.md / director-style-kb/

---

## 0. 问题诊断：当前为什么不是"融合"

| 现状 | 问题 |
|------|------|
| 知识库90+文件，路由表5维度 | 查表靠人翻，不是自动路由 |
| 速查手册30章，覆盖运镜/焦段/构图/调色 | 参数散落各章，组装靠手动拼 |
| 七阶段管线(S0-S6) | 阶段间无自动传递，知识不随管线流动 |
| MCSLA六模块公式 | 公式是静态模板，不根据场景动态填充 |
| 提示词输出格式 | 无统一标准，不同工具格式不同但无适配层 |

**核心矛盾**：知识是"百科全书"，工作流是"流水线"，提示词是"产品"——三者之间没有自动传送带。

---

## 1. 参考项目分析（已检索）

### 1.1 开源项目横向对比

| 项目 | Stars | 核心价值 | 与我们的关系 |
|------|-------|---------|------------|
| **YubAI-DramaFlow** | 139 | 五阶段工作流+9模板+风格锚定+一致性控制 | 最接近我们的方法论，但无知识库路由，无导演签名体系 |
| **lanshu-awesome-ai-video-kit** | 294 | 543条prompt+21篇方法论+7个Claude Skill+跨模型对照矩阵 | 最成熟的提示词工程体系，8要素公式+分镜时序+情绪外化表+跨模型翻译器 |
| **higgsfield-seedance2-jineng** | 636 | 15个Seedance专用Claude Skill+2秒钩子框架+摄像机运动百科 | 最专业的Seedance提示词体系，但只覆盖Seedance一个工具 |
| **vargHQ/sdk** | 325 | 多API统一网关(Kling/Seedance/Sora/ElevenLabs)+JSX声明式 | 最优雅的多工具集成方案，但不覆盖创作流程 |
| **ZJT** | 173 | 完整短剧制作平台(剧本到分镜到视频) | 最完整的端到端平台，但无导演风格知识库 |
| **seedance-mcp** | 0 | Codex MCP Server，5个工具(创建/查询/等待/下载/一步完成) | 直接可用的Seedance API接入方案 |

### 1.2 各项目的设计模式提取

| 设计模式 | 来源 | 我们是否已有 | 差距 |
|---------|------|------------|------|
| **8要素提示词公式** | lanshu | 有MCSLA(6模块) | MCSLA缺"画质后缀"和"约束条件" |
| **分镜时序法** (镜头1/2/3 + 4维度) | lanshu | 有分镜阶段 | 我们的分镜是6维度但无时间轴标注 |
| **情绪外化表** (8通道物理变化) | lanshu+我们 | 有(速查19节) | 已有，但未集成到提示词自动组装 |
| **风格锚定** (一次定义全项目复用) | YubAI | 有(6.3节) | 已有，但未固化为可传递的数据结构 |
| **跨模型提示词翻译器** | lanshu | 有工具选择决策树 | 只有"选哪个工具"，没有"同一提示词怎么适配不同工具" |
| **2秒钩子框架** (10+种钩子模式) | higgsfield | 有(5.1节6种钩子) | 我们的钩子种类少，未与Seedance时间轴对齐 |
| **质量后缀** (每条prompt必加的固定后缀) | lanshu | 无 | **缺失** -- AI输出质量的保险绳 |
| **素材角色分配** (4种功能角色) | lanshu | 有(6.4节) | 已有，但未结构化为输入规范 |
| **Claude Skill格式** (YAML frontmatter+触发规则) | higgsfield+lanshu | 无 | **缺失** -- 知识库是文档，不是可触发技能 |

### 1.3 关键洞察

1. **lanshu的8要素公式 > 我们的MCSLA** -- 多了"画质后缀"和"约束条件"，是AI视频生成的保险绳
2. **lanshu的跨模型翻译器是独创** -- 110条对照数据做few-shot，查表式转换
3. **higgsfield的2秒钩子框架最专业** -- 10+种钩子+Seedance时间轴对齐
4. **YubAI的风格锚定最实用** -- 一次定义全项目复用
5. **所有项目都没有我们的导演签名知识库** -- 90+文件的导演/DP/调色师/剪辑师签名体系是我们的独特优势


---

## 2. 融合架构设计

### 2.1 核心理念：三层融合

```
知识层(Knowledge)  ->  决策层(Decision)  ->  输出层(Output)

知识层: 90+KB文件 + 30章速查手册 + 世界观设定
  | 自动路由(情绪 -> 签名 -> 参数)
  v
决策层: 对话式创作流程(7步管线)
  | 动态组装(SALCSQ -> 工具适配)
  v
输出层: 统一格式提示词(结构化 + 工具特定)
```

### 2.2 SALCSQ 公式（升级自 MCSLA）

在现有MCSLA六模块基础上，吸收lanshu的8要素公式，升级为 **SALCSQ 六模块**：

| 模块 | 全称 | 来源 | 查什么 | 输出 |
|------|------|------|--------|------|
| **S** | Subject 精准主体 | 原M的Subject | 角色原型(KB) + 服装铠甲(KB) | 2-3个稳定识别特征 + 服装 + 道具 |
| **A** | Action 动作细节 | **新增**(from lanshu) | 情绪外化(速查19节) + 动作可行性(ai-video-tool-prompting) | 具体肢体动作 + 速度/强度 + 8通道情绪外化 |
| **L** | Lighting 光影色调 | 合并原L+原S的调色 | DP签名(KB) + 调色师(KB) + 12种西幻调色板(速查29节) | 光源 + 色温 + 方向 + 调色板 + 胶片模拟 |
| **C** | Camera 镜头运镜 | 合并原C+原Composition+原Vertical | 焦段情绪图谱(速查27节) + 运镜词汇(速查1节) + 9:16规则(速查15节) | 景别 + 焦段 + 光圈 + 运动 + 角度 + 竖屏适配 |
| **S** | Style 视觉风格 | 原S的风格锚定部分 | 导演签名(KB) + 风格锚定(速查) | 导演 + DP + 调色师签名组合 + 风格锚定词 |
| **Q** | Quality 画质约束 | **新增**(from lanshu) | 物理真实感8层(速查16节) + AI工具铁律(ai-video-tool-prompting) | 质量后缀 + 负面提示词 + 物理真实感检查项 |

**记忆口诀：SALCSQ** -- 主体 -> 动作 -> 光影 -> 镜头 -> 风格 -> 画质

**与原MCSLA的差异**：
- 合并了Camera+Composition+Vertical为C(更紧凑)
- 合并了Lighting+Color为L(光影不分家)
- 新增A(动作细节) -- 从lanshu吸收，解决"AI只会模糊动作"的问题
- 新增Q(画质约束) -- 从lanshu吸收，每条prompt必须有的保险绳
- 删除了独立的Physical和Vertical(合并到Q和C)

### 2.3 对话式创作流程（7步管线）

> 替代原有的"七阶段管线"用于即时创作场景，原有管线仍管项目级流程

```
Step 1: 创意(2分钟)   你说情绪+场景+时长，我路由到签名组合
Step 2: 风格(1分钟)   确认导演+DP+调色师签名，定风格锚定
Step 3: 分镜(5分钟)   按时长拆镜头，每镜头SALCSQ六维度
Step 4: 组装(1分钟)   自动填充SALCSQ模板，生成结构化提示词
Step 5: 适配(1分钟)   按目标工具(Kling/Seedance/Vidu)做格式转换
Step 6: 检查(1分钟)   物理真实感8层 + 竖屏规则 + 可行性检查
Step 7: 输出(30秒)    输出工具特定提示词 + 生成参数 + 素材建议
```

**对比原有七阶段(S0-S6)**：
- 原有是"大阶段"（世界观/剧本/资产/分镜/提示词/生成/合成），适合长项目
- 新7步是"对话步"（每次创作一条短视频的7个决策点），适合即时创作
- 两者不冲突：大阶段管项目，对话步管每次创作


### 2.4 统一提示词输出格式

吸收lanshu输出规范 + higgsfield Seedance格式 + 我们的导演签名体系，设计三层输出：

#### 层1：结构化提示词（所有工具通用骨架）

```
# [情绪] | [场景] | [时长]s | 9:16

## Subject
[角色名], [2-3个稳定识别特征].
[服装/铠甲描述], [道具].

## Action
[具体肢体动作], [速度/强度].
[情绪外化: breathing/eye/jaw/focus/scanning/delay/control/residue].

## Lighting
[光源], [色温], [方向], [DP签名灯光].
[调色板名称], [胶片模拟].

## Camera
[景别], [焦段]mm f/[光圈], [运镜], [角度].
[9:16竖屏适配规则].

## Style
[导演签名], [调色师签名], [风格锚定词].
[Seedance模式(如适用)].

## Quality
4K, ultra HD, rich detail, sharp clarity, cinematic textures, stable picture.
Maintaining face and clothing consistency without distortion or high detail.
[物理真实感: SSS/Fresnel/weave/contact/anatomy/atmosphere/bounce/microtexture].
Negative: [负面提示词].
```

#### 层2：工具特定格式（从层1自动转换）

**Kling 格式**：
```
Scene: [Subject+Action]
Characters: [角色描述]
Action: [动作细节]
Camera: [Camera模块]
Audio & Style: [Lighting+Style模块]
Negative: [Quality模块的负面部分]
9:16 vertical
```

**Seedance 格式**：
```
Seedance [Mode] mode,
[Subject+Action],
[Camera+Lens+Motion],
[Lighting DP-anchored],
[Color grade + Film stock],
[Quality suffix],
9:16 vertical, cinematic
Negative: [负面提示词]
```

**Vidu 格式**（简化版，100词以内）：
```
[Subject+Action], [Simple Camera], [Lighting], [Style],
9:16 vertical, cinematic
```

**分镜时序格式**（复杂剧情，从lanshu吸收）：
```
[素材分配 + 主体定义]

镜头 1：[运镜] + [主体动作与表情] + [位置/空间] + [音频]
镜头 2：[运镜切换] + [主体动作变化] + [位置变化] + [音频]
镜头 3：[运镜] + [主体动作] + [位置] + [音频]

[整体约束：风格/色调/质量/稳定性]
```

#### 层3：质量后缀（每条提示词必加，从lanshu吸收）

**通用质量后缀**：
```
4K, ultra HD, rich detail, sharp clarity, cinematic textures, stable picture.
Maintaining face and clothing consistency without distortion or high detail.
Generate the video without subtitles.
```

**中世纪西幻专属质量后缀**：
```
[工具特定修复词],
worn iron patina, no plastic, grounded, weight on feet,
consistent style, no beautification,
no watermark, no logo, no text, no subtitles
```

**工具特定修复词**：
| 工具 | 必贴修复词 |
|------|----------|
| Kling | worn iron patina, no plastic, no fill, crushed blacks, no beautification |
| Seedance | restrained, subtle, realistic color, not stylized, measured movement |
| Vidu | simple, preview, stable, no complex motion |
| Wan | ControlNet-anchored, IP-Adapter reference, consistent composition |


---

## 3. 知识库路由设计

### 3.1 情绪 -> SALCSQ 自动路由表

> 融合 master-route-quickref.md + 速查手册情绪-导演查表 + 中世纪西幻范式库

| 情绪 | S(主体原型) | A(动作特征) | L(光影+调色板) | C(默认镜头) | Style签名 | Q(修复词) |
|------|-----------|-----------|--------------|-----------|----------|----------|
| 恐惧/窒息 | 被追猎者 | 呼吸急促+瞳孔放大+扫描 | Kubrick+Alcott+诅咒绿+HP5 | 35mm f/4慢推+走廊纵深 | horror-dark | no fill, crushed blacks |
| 敬畏/崇高 | 守望者 | 屏息+仰望+僵立 | Villeneuve+Lubezki+冰原蓝+250D | 24mm f/8广角+负空间 | fantasy-epic | vast scale, tiny human |
| 孤独/隔离 | 流放者 | 深呼吸+凝视远方+肩膀微垂 | Bergman+Nykvist+荒原灰+HP5 | 50mm f/2.8锁定+负空间 | european-masters | no beautification, austere |
| 权力/压迫 | 统治者 | 下颌紧绷+目光锁定+控制姿态 | Nolan+van Hoytema+圣殿金光+500T | 135mm f/2.8 MCU+俯拍 | crime-thriller | no fill, power framing |
| 魔法/神秘 | 觉醒者 | 手指微颤+瞳孔变色+延迟反应 | del Toro+Navarro+暮色紫+500T | 50mm f/2.0环绕+体积光 | fantasy-epic | volumetric, subtle glow |
| 背叛/阴谋 | 密谋者 | 压低声音+侧目+手握暗器 | Fincher+Khondji+去饱和+500T | 85mm f/2.0锁定+半脸光 | crime-noir-urban | desaturated, sodium orange |
| 牺牲/悲壮 | 殉道者 | 缓慢呼吸+微笑+闭眼 | Malick+Deakins+唯一暖+250D | 85mm f/1.4慢推+逆光剪影 | war-history-drama | backlight, sole warm |
| 愤怒/复仇 | 复仇者 | 握拳+咬牙+暴起 | Evans+Stahelski+战火红+800T | 14mm f/2.8手持+快速剪辑 | action-martial | speed ramp, impact |
| 悲伤/失去 | 哀悼者 | 肩膀颤抖+视线失焦+延迟 | Tarkovsky+Doyle+荒原灰+500T | 135mm f/2.8锁定+长持 | european-masters | long hold, silence |
| 浪漫/禁忌 | 恋人 | 瞳孔放大+手微触+呼吸浅 | Wong Kar-wai+Doyle+暖冷交织+500T | 50mm f/1.4偏置+柔焦 | romance-melodrama | step-printing, warm cold |

### 3.2 场景 -> 默认参数路由表

| 场景类型 | Seedance模式 | 默认焦段 | 默认运镜 | 默认灯光 | KB文件 |
|---------|-------------|---------|---------|---------|--------|
| 骑士独白 | Studio | 85-135mm | 锁定/极慢推 | 单窗光+负填充 | horror-dark |
| 魔法仪式 | Performance | 50-85mm | 360度环绕 | 体积光+戏剧调色 | fantasy-epic |
| 战斗追逃 | Action | 14-24mm | 手持+快速 | 去饱和+火光 | action-martial |
| 森林漫步 | Atmospheric | 24-35mm | 漂浮 | 自然光+体积光 | fantasy-epic |
| 对话密谋 | Narrative | 35-50mm | 慢推/锁定 | 实用光源+钠橙 | crime-noir-urban |
| 地牢审讯 | Studio | 85-135mm | 锁定 | 烛光唯一+负填充 | horror-dark |
| 加冕典礼 | Performance | 50mm | 缓升 | 逆光+圣殿金 | war-history-drama |
| 废墟探索 | Atmospheric | 24-35mm | 缓推 | 篝火唯一暖+冷灰 | game-aesthetic-crossover |

### 3.3 跨工具提示词翻译规则

> 从lanshu的跨模型翻译器吸收核心理念，结合我们的工具特定提示词策略

| 转换方向 | 结构变化 | 关键适配 |
|---------|---------|---------|
| 通用->Kling | 合并为Scene/Characters/Action/Camera/Audio&Style/Negative | 加camera_move参数, 单段6s, 适中motion(40-60) |
| 通用->Seedance | 开头加Seedance [Mode] mode, 合并Subject+Action | 加质量后缀, 电影模式选择, 运镜速度锚定 |
| 通用->Vidu | 简化为100词以内, 去掉复杂运镜 | 只保留Subject+Action+SimpleCamera+Style |
| 通用->Wan | 加ControlNet/IP-Adapter描述 | 需要ComfyUI工作流描述 |
| Kling->Seedance | Scene拆为Subject+Action, 加电影模式 | camera_move转为自然语言运镜描述 |
| Seedance->Kling | 合并Subject+Action为Scene, 加camera_move | 电影模式去掉, 加Kling特有参数 |


---

## 4. 实施方案

### 4.1 需要新建/修改的文件

| 文件 | 操作 | 用途 |
|------|------|------|
| `Docs/AI/ai-shortdrama-kb-workflow-integration-design.md` | **新建(已完成)** | 本设计方案 |
| `Docs/AI/ai-shortdrama-salcsq-template.md` | **新建** | SALCSQ提示词模板+工具适配模板+质量后缀库 |
| `Docs/AI/ai-shortdrama-emotion-route-table.md` | **新建** | 情绪->SALCSQ自动路由表(3.1的完整版) |
| `Docs/AI/ai-shortdrama-scene-route-table.md` | **新建** | 场景->默认参数路由表(3.2的完整版) |
| `Docs/AI/ai-shortdrama-cross-tool-translator.md` | **新建** | 跨工具提示词翻译对照表(从lanshu吸收) |
| `Docs/AI/ai-shortdrama-quality-suffix-library.md` | **新建** | 质量后缀库(通用+工具特定+西幻专属) |
| `Docs/Analysis/2026-06-28-ai-comic-methodology.md` | **修改** | 9.4节MCSLA升级为SALCSQ，8节工作流升级 |
| `Docs/AI/镜头调度与摄影参数提示词速查手册.md` | **修改** | 新增SALCSQ索引章节(第31节) |

### 4.2 实施优先级

| 优先级 | 任务 | 工作量 | 价值 |
|--------|------|--------|------|
| P0 | 新建 SALCSQ提示词模板 | 2小时 | 统一输出格式的核心 |
| P0 | 新建 质量后缀库 | 1小时 | 解决AI输出质量不稳定 |
| P0 | 新建 情绪路由表 | 2小时 | 知识库自动路由的核心 |
| P1 | 新建 场景路由表 | 1小时 | 场景级默认参数 |
| P1 | 新建 跨工具翻译对照表 | 3小时 | 同一创意多工具适配 |
| P1 | 修改 主文档MCSLA->SALCSQ | 1小时 | 公式升级 |
| P2 | 修改 速查手册新增SALCSQ索引 | 1小时 | 查找效率提升 |

### 4.3 不做的事情

| 不做 | 原因 |
|------|------|
| 把90+KB文件重写为Claude Skill格式 | 工作量巨大，且知识库作为文档更灵活 |
| 建立数据库替代文件 | 当前规模用文件+路由表足够，不需要过度工程化 |
| 合并速查手册30章为单一模板 | 30章的细节价值在于"查"而非"背"，合并会丢失深度 |
| 替代原有七阶段管线 | 原有管线管"项目级"，新7步管"创作级"，两者互补 |

---

## 5. 使用示例：对话即创作

### 5.1 15秒短视频完整流程

**Ba Ba**: 我想做一条15秒的，骑士在地牢被宣判叛国罪

**小璃(Step1 创意)**:
- 情绪: 压迫+绝望+不可逆
- 场景: 地牢审讯
- 路由: Fincher+Khondji+去饱和+crime-noir-urban

**Ba Ba**: 确认，用Seedance生成

**小璃(Step2-7 自动组装+适配)**:

```
Seedance Studio mode,
A knight in chains, weathered face, darkened plate armor with rust stains,
half-face split by sodium orange light from a single wall sconce,
breathing: deep and slow, eye: fixed ahead, jaw: clenched, 
control: hand on chains, suppressing tremor,
135mm f/2.8 MCU, environment closing in, narrow dungeon framing,
slow lateral dolly right-to-left, space shrinking,
Khondji sodium orange key, no fill, crushed blacks,
dungeon orange palette (sodium orange + black + dark brown + iron rust),
Kodak Vision3 500T, Fincher-grade desaturated,
4K, ultra HD, rich detail, sharp clarity, cinematic textures, stable picture,
maintaining face and clothing consistency without distortion,
worn iron patina, no plastic, grounded, weight on feet,
no beautification, no watermark, no logo, no subtitles,
9:16 vertical, cinematic dark fantasy.
```

- 推荐参数: 9:16, 8秒, 1080p
- 关键技巧: 单镜头单运镜(仅lateral dolly), 铠橙半脸光制造分裂感, 135mm压缩空间制造窒息
- 可调点: 换cold blue key light可改为绝望感; 加slow push-in可增强压迫

### 5.2 对比：原MCSLA vs 新SALCSQ

**原MCSLA输出**（6模块，无动作细节，无画质约束）：
```
Subject: A knight in chains
Physical: SSS on wet skin, anisotropic weave on cloak
Lighting: Khondji sodium orange, single key, no fill
Composition: environment closing in, narrow framing
Camera: 135mm f/2.8 MCU, slow dolly in
Style: Fincher desaturated, Vision3 500T, 9:16 vertical
```

**新SALCSQ输出**（6模块，有动作细节+情绪外化+画质约束）：
```
Subject: A knight in chains, weathered face, darkened plate armor with rust stains
Action: breathing: deep and slow, eye: fixed ahead, jaw: clenched, control: suppressing tremor
Lighting: Khondji sodium orange key, no fill, crushed blacks, dungeon orange palette, Vision3 500T
Camera: 135mm f/2.8 MCU, slow lateral dolly, narrow dungeon framing, 9:16 vertical depth
Style: Fincher-grade desaturated, cinematic dark fantasy
Quality: 4K ultra HD, maintaining face consistency, worn iron patina, no plastic, no beautification, no watermark
```

**关键差异**：
- A模块让角色从"被描述"变成"在表演"——8通道情绪外化让AI知道怎么动
- Q模块是保险绳——质量后缀+负面提示词+物理真实感，防止AI翻车
- L模块合并了调色——不再分开写灯光和调色，因为它们本就是一体的

---

## 6. 下一步

1. Ba Ba 确认设计方案
2. 按P0优先级实施：SALCSQ模板 + 质量后缀库 + 情绪路由表
3. 用一条实际短视频验证完整流程
4. 根据验证结果迭代
