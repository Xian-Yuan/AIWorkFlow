# AI 视频提示词工程研究报告（2025-2026）

> **采集时间**：2026-06-25
> **覆盖范围**：GitHub 开源项目（6个深度分析 + 7个概览）、B站知识库视频、Higgsfield 官方 Skill 体系
> **目标读者**：Jinli AI Video Creator Pipeline 设计者

---

## 一、分析的开源项目

### 1.1 深度分析（已克隆到本地）

| 项目 | Stars | 语言 | 核心价值 |
|------|-------|------|---------|
| higgsfield-ai-prompt-skill | 156 | Python | 最专业的提示词方法论体系：MCSLA 公式、Seedance 六槽公式、5种 prompt 模式、Camera-Emotion Sync、20+ 子 skill |
| Open-AI-Micro-Drama-Generator | 353 | Python | 多 agent 流水线：screenwriter > character_extractor > storyboard_artist，每 shot 3-6秒 |
| pushing-creation | 7 | Python | 像导演一样写提示词：Shot on ARRI + 镜头 T-stop + STYLE_/NEG_ 块库 |
| shortdrama-pipeline | 108 | Python | CLI 门控模式：Seed 2.0>Seedream>Seedance>ffmpeg，自动拆分/合并长镜头 |
| ai-short-drama-studio | 1 | Python | 13个 Agent 串联：市场>爆款>脑洞>人设>分集>编剧>分镜>视频提示词>美术一致性>合规 |
| wind-comic | 218 | TypeScript | 多 agent pipeline：Claude/OpenAI/Minimax provider-agnostic |
| ai-character-continuity | 0 | Markdown | 角色连贯性提示词模板：Stable Identity vs Current Emotion 分离 |

---

## 二、关键发现

### 2.1 MCSLA 公式（Higgsfield）

M=Model C=Camera S=Subject L=Look A=Action
Subject > Action > Camera > Style 是最可靠的顺序
Subject + Action 必须在前 20-30 词
prompt 30-100词 不超过200词

### 2.2 Seedance 六槽公式
[Camera]+[Subject]+[Action]+[Setting]+[Style]+[Lighting]
六槽缺三以上会被过滤器拦截
不支持 negative_prompt 用正面约束替代

### 2.3 Genre Router
Product:30-50词 lead Subject | Drama:60-100词 lead Scene | Music:50-80词 lead Style | Anime:50-90词 lead Style

### 2.4 Identity/Motion 分离
Identity Block:静态外貌无时间语言
Motion Block:时序相机不重复外貌
混合写法导致 identity drift

### 2.5 Camera-Emotion Sync
愤怒:Handheld jittery broken rhythm | 平静:Handheld smooth breathing | 悲伤:Handheld slow low | 震惊:Static freeze+minimal push-in | 动作:60fps 180shutter

### 2.6 Double-Contrast Cut Rule
每次切换必须同时改变 shot size 和 camera character
不允许连续两个镜头用同一种 camera character

### 2.7 Continuation 五规则
1.Last-frame anchor 2.Identity anchor verbatim 3.Prior clip as secondary memory 4.Immediate continuation 5.No action repeat

### 2.8 Anti-Slop 词汇
禁止:beautiful stunning epic amazing dynamic | 替换:large-scale sweeping fast-tracking slow-dolly-push

### 2.9 Physics Language
拳头: fist connects sweat flies opponent head snaps back | 入场: door slams open dust erupts light floods | 愤怒: jaw clenches nostrils flare brow furrows

### 2.10 三幕动作节奏
Charge-up(蓄力) > Burst(爆发) > Aftermath(后果)

### 2.11 Seedance 引擎硬约束
3角色跨镜头追踪 | exit-frame=cut | off-screen=nonexistent | 避免反射 | 默认in medias res | age-blind

### 2.12 平台参数差异
Seedance2.0:15s 480p-4K 数值camera_control 不支持neg 21:9
Kling3.0:15s 720p-4K 预设camera_control 偏好正面措辞
Runway4.5:10s 1080p motion_bucket_id 不用neg
Sora2:20s 1080p 自然语言 支持neg 同步音频

### 2.13 shortdrama-pipeline 镜头拆分/合并
_normalize_episode_shots(): 拆长镜头(>10s) > 合并短镜头(目标10s最大15s) > 处理尾部(<4s合并)

### 2.14 pushing-creation 摄影机规格
Shot on ARRI Alexa Mini LF on Steadicam. Lens 24mm prime T1.5 f/2.8 1/48 24fps ISO160
STYLE_/NEG_ 块库: STYLE_PHOTOREAL_BASE STYLE_KODAK_VISION STYLE_ANAMORPHIC STYLE_GOLDEN_HOUR | NEG_AI_PLASTIC_SKIN NEG_AI_COMPOSITION NEG_AI_LIGHTING

### 2.15 ai-short-drama-studio 13 Agent
总导演>市场雷达>爆款拆解>脑洞策划>人设>分集大纲>编剧>台词嘴替>分镜导演>视频提示词>美术一致性>合规审核>数据复盘

### 2.16 Higgsfield 10步项目方法论
1.Start With Project not Prompt(锁9字段 consistency是承重字段)
2.Build Master Script 3.Use GPT as Creative Assistant(5角色)
4.Separate Script from Prompt 5.Create Project Bible
6.Give Every Scene One Job(6种用途) 7.Use Prompt Modules(7种类型)
8.Fix Failures Protect What Worked(80%规则)
9.Build in Passes(8pass) 10.Production Chain(Popcorn>Seedream>Animate>Recast>Lipsync>VibeMotion>Upscale>Assemble)

---

## 三、对 Jinli Pipeline 的升级建议

### 3.1 S4升级:秒级编排
每镜头拆1-3segments 每段3-10s | purpose:setup/trigger/reaction/hold/transition | Camera-Emotion Sync | Double-contrast cut rule

### 3.2 新增S4.5:连贯性规划
continuity_map | Identity+Motion分离 | reference_strategy | Continuation五规则 | audio_sync精确到秒

### 3.3 S5升级:平台感知提示词
MCSLA五层 | Seedance六槽 | Genre Router | Anti-Slop | Physics Language | 三幕节奏 | 平台差异化camera_control | Shot on摄影机规格 | 引擎硬约束

### 3.4 风格系统
STYLE_/NEG_块库 | 可组合风格模板 | 平台感知负面约束

### 3.5 迭代工作流
Generation Ledger | Pre-flight Linter | 单变量迭代 | 6-Pass Diagnostic

---

## 四、参考项目本地路径

higgsfield: E:\UEGameDevelopment\Project\Jinli\services\_research\higgsfield-ai-prompt-skill\
MicroDrama: E:\UEGameDevelopment\Project\Jinli\services\_research\Open-AI-Micro-Drama-Generator\
pushing: E:\UEGameDevelopment\Project\Jinli\services\_research\pushing-creation\
shortdrama: E:\UEGameDevelopment\Project\Jinli\services\_research\shortdrama-pipeline\
drama-studio: E:\UEGameDevelopment\Project\Jinli\services\_research\ai-short-drama-studio\
wind-comic: E:\UEGameDevelopment\Project\Jinli\services\_research\wind-comic\
character-continuity: E:\UEGameDevelopment\Project\Jinli\services\_research\ai-character-continuity\

---

## 五、知识库相关视频

BV196j36aE1L:五维度分镜提示词模板 | BV1oL6cBaEYk:NanoBanana25宫格分镜 | BV1GLVH6mEKW:MiniMax TTS+字幕 | BV1br7f6cEri:AI情绪导演---

## 六、新增发现（第三轮搜索）

### 6.1 AIYOU（122★）

AI 短剧平台，36天 VibeCoding 构建。关键发现：

- **影视分镜标准术语常量库**（storyboardTerms.ts）：8个景别(ELS/LS/FS/MS/MCU/CS/CU/ECU)、6个拍摄角度(EyeLevel/HighAngle/LowAngle/DutchAngle/OTS/BirdEye)、10+个运镜方式(Static/Truck/Tilt/Pan/Boom/Dolly/Zoom/Following/Leading/Orbit)、3种视觉风格(3D动画/REAL真人/ANIME二维)
- **AI Prompts 系统文档**（56KB）：完整的角色生成、剧本创作、视频生成、图像生成、分镜增强、风格预设等全套 prompt
- **模型优先级与自动降级系统**：Imagen 4.0 Ultra > Imagen 4.0 > Gemini 3 Pro > Gemini 2.5 Flash，连续失败3次自动跳过
- **Node Builder Skill**：Claude skill 用于交互式构建新节点
- **风格预设三种模式**：3D动画(半写实仙侠美学) / REAL真人(照片级85mm肖像) / ANIME二维(赛璐珞着色)

### 6.2 clipcurator 系列

- ai-character-continuity-prompt-library：角色连贯性提示词模板库
- ai-short-drama-visual-continuity-prompt-pack：短剧视觉连贯性 prompt-pack

### 6.3 sohowj/seedance-skill

中文 Seedance 2.0 视频提示词生成 skill，包含风格模板和参考路由（克隆超时未成功）

### 6.4 其他发现

- ugc-content-pipeline(4★)：TikTok Shop UGC视频多agent系统
- videocrew(0★)：短视频/纪录片/解说全自动流水线
- ContentForge-AI(0★)：YouTube内容创作多agent系统（idea>research>script>video）