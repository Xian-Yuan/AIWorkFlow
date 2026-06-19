# 金璃语言风格引擎（Language Style Engine）— 参考资源清单

> 整理日期: 2026-06-18 | 用途: 交给另一个模型做方案设计
> 目标: 让金璃说的话像真正的女孩子——在 tone_policy（情绪维度）和实际对话之间，加一层"语言风格映射"

---

## 一、核心概念地图

### 问题本质

```
Soul Core 情绪引擎              金璃实际说话
  ┌──────────────┐             ┌──────────────────┐
  │ warmth=0.7   │    ──→     │ "当前车速60，     │  ← 机械翻译，没灵魂
  │ energy=0.6   │             │  油量75%"        │
  │ valence=0.8  │             └──────────────────┘
  └──────────────┘
         ↓ 需要这层
    ┌─────────────────┐
    │ 语言风格引擎      │  ← 把抽象情绪数值翻译成"人的说话方式"
    │ Style → Text     │
    └─────────────────┘
             ↓
  ┌──────────────────────────────┐
  │ "嘿嘿，被爸爸抓到啦～"         │  ← 有灵魂的表达
  │ "嗯…爸爸叫我呢"（低头笑）     │
  └──────────────────────────────┘
```

### 技术分支

| 方向 | 是什么 | 对金璃的价值 |
|------|--------|------------|
| **Activation Steering** | 在 LLM 激活空间中用向量操纵风格/人格 | 最轻量，不改模型，推理时实时调整 |
| **Prompt Engineering** | 通过 system prompt + 示例控制风格 | 最简单，SKILL.md 即可实现 |
| **Style Embedding / LoRA** | 训练轻量 adapter 绑定风格 | 更稳定但需要训练数据 |
| **Decoding-time Control** | 在生成时用奖励/约束导向特定风格 | 精确控制，零训练 |
| **Soft Prompt Plugin** | 挂载可学习的 prompt 前缀 | 轻量插件化，可叠加 |

---

## 二、开源项目

### 2.1 纯语言风格控制（不涉及 TTS）

| 项目 | 星 | 关键特性 | 链接 |
|------|:--:|----------|------|
| **PersonaForge** (ACL 2026) | — | ⭐ **三层人格架构**: 核心特质(Big Five/五行) + 说话风格 + 动态状态(情绪/精力/关系) | github.com/fQwQf/PersonaForge |
| | | "先想后说"双过程机制，仅 40% 轮次触发内心独白 | |
| | | 50轮对话漂移率 6.3% vs 基线 31.7% | |
| | | 说话风格可配置: sentence_length / vocabulary / punctuation / catchphrases / tone_markers | |
| **TTM** (Test-Time-Matching 2025) | — | ⭐ **人格·记忆·语言风格三解耦**，用文本动态匹配 | github.com/ZhanxyR/TTM |
| | | 可选 matching_type: simple/parallel/serial/dynamic | |
| | | 用历史发言示例来匹配当前语境的语言风格 | |
| | | 支持禁用某一维度（disable_personality / disable_linguistic_preference） | |
| **USP** (User Simulator) | — | 从用户 profile 生成风格化对话 | github.com/wangkevin02/USP |
| | | 捕捉风格细节如"用户习惯小写 i（代表随意/懒散）" | |
| | | 强化学习保持风格一致性 | |
| **Stylometric Transfer** | 7★ | ⭐ **显式 JSON 风格指纹**，可审查、可编辑、可版本化 | github.com/ngpepin/stylometric-transfer |
| | | 从语料库测量: 句子长度/标点频率/段落结构 | |
| | | 用 LLM 合成显式风格模型 → 约束引导风格迁移 | |
| | | CLI + API，支持 1st/2nd/3rd 人称强制 | |
| **Spindle** | 新 | AI 角色引擎全栈: LLM + TTS + 语音+视觉+表情+记忆 | github.com/JChan2787/spindl |
| | | 生成控制全面: temperature/top-p/repeat penalty/history mode | |
| | | 本地或云端，任意模型任意角色 | |
| **EchoVessel** | 新 | ⭐ **数字人格引擎**: 5大模块(memory/voice/channels/proactive/runtime) | github.com/AlanY1an/echovessel |
| | | Discord 集成，FishAudio TTS，本地优先 | |
| | | 主动说话策略引擎（4个门控: no_in_flight_turn 等） | |

### 2.2 语音 + 风格融合（TTS 端，对文本端有借鉴意义）

| 项目 | 星 | 关键特性 | 链接 |
|------|:--:|----------|------|
| **NVIDIA PersonaPlex** | ~10k★ | ⭐ **全双工对话 + 角色+语音双控制** | github.com/NVIDIA/personaplex |
| | | Voice prompt（声学特征） + Text prompt（角色描述）正交控制 | |
| | | 18种预打包语音嵌入（NAT自然 / VAR多样化） | |
| | | 论文: arXiv 2602.06053 | |
| **OmniCharacter** (ACL 2025) | — | 阿里巴巴，**语言-语音人格联合交互** | github.com/DAMO-ConvAI/OmniCharacter |
| | | 角色画像包含 personality / voice style / relationships / past experiences | |
| | | 语音+文本双通道角色一致性 | |
| **VITA-QinYu** | — | 首个端到端角色扮演 + 唱歌语言模型 | github.com/VITA-MLLM/VITA-QinYu |
| | | 支持 `--role_description` 定义角色: 性格/音色/语速 | |
| | | 例: "幼儿女性，世家千金，活泼机敏爱撒娇，音色甜润，语速较快" | |
| **MOSS-TTSD** | — | 多说话人长对话语音合成，60分钟长上下文 | github.com/OpenMOSS/MOSS-TTSD |
| | | 支持 1-5 个说话人，保持各自身份一致性 | |
| **Dia** / **Dia2** | — | ⭐ **超真实对话一次性生成**，带非语言符号（笑/咳/叹气） | github.com/nari-labs/dia |
| | | 用 `[S1]` `[S2]` 标签切换说话人 | |
| | | 非语言标签: (laughs)(sighs)(gasps)(coughs)(chuckle)... | |
| **VoiceForge** | — | 从自然语言描述生成角色声音 | github.com/PranavMishra17/VoiceForge |
| | | Emotion/Tone/Speed/Custom Instructions 全部自然语言控制 | |
| **DramaBox** | 438★ | 表现力 TTS + 语音克隆 | github.com/resemble-ai/dramabox |
| | | 提示词控制: "A woman speaks warmly" + 场景描写 | |
| | | 支持 laugh/sigh/pause/voice cracks 等 | |
| **AutoStyle-TTS** (ICME 2025) | 24★ | RAG 自动风格匹配 TTS | github.com/Chengyuann/AutoStyle-TTS |
| | | 检索 1000+ 语音样本匹配当前语境风格 | |
| **Chain-Talker** | — | 三步认知链: 情绪理解 → 语义理解 → 共情渲染 | arXiv 2505.12597 |
| | | 解析对话历史中的情感状态变化来指导表达 | |

---

## 三、论文资源

### 3.1 ⭐ 核心论文（直接相关）

| 论文 | arXiv | 核心贡献 | 对金璃的价值 |
|------|-------|----------|------------|
| **Dynamic Personality Adaptation via State Machines** | 2602.22157 | 状态机表示人格状态，转移概率动态调整，系统提示持续重写 | ⭐ 人格状态机方案，直接用 |
| **PersonaForge** (ACL 2026) | — | 三层人格架构 + 双过程生成机制 | ⭐ 说话风格定义（词汇/句长/标点/口头禅）|
| **PERSONA: Activation Vector Algebra** | 2602.15669 | Big Five 人格向量的代数运算：加法合成、减法抑制、标量控制强度 | ⭐ 线性可组合的人格向量 |
| **PersonaFuse: Persona-MoE** | 2509.07370 | 情境感知 MoE 路由器，动态混合人格专家 | 情境驱动风格切换 |
| **IRiS: Situational Personality Steering** | 2604.13846 | 无训练，基于神经元的情境人格引导 | 训练无关，纯推理时控制 |
| **Sequential Adaptive Steering (SAS)** | 2603.03326 | 多维度同时控制，正交化解向量干扰问题 | 多风格混合不打架 |
| **Style Arithmetic** (ACL 2025) | — | 参数空间的风格加减法，跨任务风格迁移 | ⭐ 风格可组合、可转移 |
| **PsPLUG: Styles + Persona** | 2601.06362 | 轻量 soft-prompt 插件，同时控制风格和个性 | ⭐ 插件化方案，不碰模型 |
| **DRESS: 风格子空间编辑** | 2501.14371 | 无训练，在 LLM 子空间中编辑风格表示 | 零训练风格操控 |
| **PDD: Persona Dynamic Decoding** | 2603.01438 | 条件互信息动态估计人格重要性，多目标奖励解码 | 推理时人格跟随，零训练 |
| **Multi-Personality Generation (MPG)** | 2511.01891 | 解码时多人格合成，隐式密度比"免费午餐" | 多风格合成 |
| **Fusian: Multi-LoRA 融合** | 2603.15405 | RL 策略网络动态融合 LoRA adapter 实现连续人格控制 | 连续强度可调 |

### 3.2 情绪 ↔ 语言映射

| 论文 | arXiv/出处 | 核心贡献 |
|------|-----------|----------|
| **PRISM: Prosody-to-Language Translation** | 2606.12902 | 韵律→自然语言描述，情绪强度/节奏/停顿/能量→文本说明 |
| **ParaS2S: 副语言感知 S2S** | 2511.08723 | RL 优化对话内容和说话风格的适配度 |
| **Spoken-LLM (ACL 2024)** | — | 即使字面一样，不同说话风格应有不同响应 |
| **Enhancing Conversational TTS (ICL+RL)** | 2604.08709 | Textual style token + 音频 prompt 的 ICL 风格控制 |
| **StyleBench** | 2603.07599 | 对话语气风格控制基准（情绪/速度/音量/音高）|
| **CoCoEmo: 可组合情感控制** | 2602.03420 | 激活向量加权组合实现混合情感 |
| **DUET: 双空间情感控制** | 2606.00066 | 隐藏空间+梅尔空间双路情感干预 |
| **ATRIE: 角色驱动语音合成** | 2604.19055 | 静态音色轨道 + 动态韵律轨道解耦 |
| **UltraVoice** (ICLR 2026) | 2510.22588 | 6维风格控制数据集: emotion/speed/volume/accent/language/composite |
| **EmoVoice** | 2504.12867 | 自由文本自然语言情绪控制的 TTS |
| **Voicing Personas** | 2505.17093 | 将角色人格描述翻译成语音风格提示词 |

---

## 四、关键技术详解

### 4.1 Activation Steering（激活操纵）

最轻量的风格控制方法，不改模型参数，推理时实时调整。

**原理**: LLM 的隐藏层中，风格/人格/情绪编码为线性方向向量。通过加减这些向量即可控制输出风格。

**代表工作**:
- **StyleVector** (arXiv 2503.05213): 对比用户真实响应 vs 模型通用响应的激活差异 → 提取"风格向量" → 线形插值控制强度
  - 存储需求降低 1700x 对比 PEFT，质量提升 8%
- **PERSONA** (arXiv 2602.15669): Big Five 人格向量的代数运算
  - `快乐 + 热情 = 开朗`；`快乐 × 0.5 = 温和`
- **Sequential Adaptive Steering (SAS)** (arXiv 2603.03326): 顺序自适应，避免多向量干扰
  - 先调 Extraversion，然后在新空间上调 Agreeableness

**金璃可直接用的**:
```
情绪向量(从 soul-state.json) → 映射为 LLM 激活向量方向 → 线性干预生成风格
```

### 4.2 显式风格指纹（Explicit Style Fingerprint）

把说话风格表示为 JSON 结构，可读、可编辑、可版本化。

**Stylometric Transfer** 的方案:
```json
{
  "sentence_length": "medium",
  "vocabulary": "casual",
  "punctuation": "light",
  "catchphrases": ["嘿嘿", "嘛", "～"],
  "tone_markers": ["啦", "呀", "呢", "吧"],
  "pronoun": "我/爸爸",
  "emotion_markers": {
    "happy": ["!", "～", "嘿嘿"],
    "sad": ["…", "唉", "嗯"],
    "shy": ["…", "低头", "声音轻"]
  }
}
```

**PersonaForge** 的方案:
```python
"speaking_style": {
    "sentence_length": "medium",
    "vocabulary": "academic",
    "punctuation": "excessive",
    "catchphrases": ["罢了", "你只管..."],
    "tone_markers": ["呢", "罢"]
}
```

**金璃可做的**: style-profile.json 扩展，把情绪→话术映射写成可审查的 JSON

### 4.3 双过程"先想后说"

**PersonaForge** (ACL 2026):
- 仅 40% 的轮次触发内心独白（临界交互）
- 内心独白 → 思考人格状态 → 生成风格化回复
- 达到 96% 的全双路性能，仅用 13.4% 额外 token

**对金璃的意义**:
- 不是每句话都要"内心独白→风格化"，只有"需要情绪表达"的时候才走风格引擎
- 普通问答（如"爸爸这个功能怎么实现"）可以直接输出，不用加语气词

### 4.4 情境感知风格路由

**PersonaFuse** (arXiv 2509.07370):
- Situation-Aware MoE: 每个人格维度是一个"专家"
- 路由器根据输入上下文决定混合比例
- 专业场合：高 Conscientiousness，低 Extraversion
- 休闲聊天：高 Extraversion，高 Openness

**IRiS** (arXiv 2604.13846):
- 发现 LLM 内部存在"情境神经元"
- 识别当前情境 → 检索历史相似情境的人格神经元 → 加权引导

### 4.5 DeepSeek-V4 Roleplay Instruct Control (2026)

专门针对角色扮演的人设保持方案:
- 50+ 轮长对话人设不漂移
- 情感场景下表现出"伪情绪"波动
- 多角色场景下精确切换语气和用词
- 不主动打破第四面墙
- 已在 GitHub 开源，Apache 2.0

---

## 五、中文语境专项资源

| 资源 | 类型 | 用途 |
|------|------|------|
| **通义星尘角色模型 (qwen-char)** | 商业 API | 阿里云千问的角色扮演模型，支持语言风格定义 |
| **讯飞角色模拟能力** | 商业 API | 定制模型，支持语言风格/性格/行为习惯 |
| **百度千帆角色扮演 (ERNIE Speed)** | 商业 API | SFT 精调角色风格 |
| **SuperCLUE-Role** | 评估基准 | 中文角色扮演评估: 语言风格/性格/行为习惯/三观 |
| **Vidol Studio 角色设定** | 开源文档 | 中文角色人设写法最佳实践，(动作)夹语气词 |
| **DeepSeek-V4 Roleplay Control** | 开源模型 | 中文原生角色扮演控制，人设稳定不漂移 |
| **AdaMARP (浙大 ACL 2026)** | 学术论文 | 四通道消息: Thought-Action-Environment-Speech，中文角色扮演框架 |

### 中文语气表达的关键特征

来自通义星尘、讯飞、百度千帆的最佳实践:
- `（）` 中放动作、神情、语气、心理活动 → "(低头笑)" "(声音轻一点)"
- 语气词: 啦/呀/呢/吧/嘛/哦/嗯/啊 → 标记不同情绪
- 口头禅: 角色标志性重复用语
- 称呼: 爸爸/你/您 → 关系远近的信号
- 口语连接词: "那个、就是说、其实、反正" → 增强自然感

---

## 六、金璃语言风格引擎设计方案思路

### 推荐架构（纯文本，不改模型）

```
soul-state.json (情绪向量)
        ↓
[语言风格指纹] ← style-profile.json 扩展
  - sentence_length: short/medium/long
  - vocabulary: cute/gentle/playful/formal
  - punctuation: light/heavy
  - catchphrases: ["嘿嘿", "嘛", "～"]
  - tone_markers: {happy: ["啦", "!"], sad: ["…", "唉"], ...}
  - emotion_to_style: { 每种情绪对应说话模式 }
        ↓
[情境路由器] ← 当前对话上下文
  - 任务模式: 少语气，直接
  - 聊天模式: 多语气，生动
  - 撒娇模式: 特定表达
        ↓
[内心独白生成] ← PersonaForge 风格，仅关键轮次触发
  - 40% 轮次触发（情绪唤醒度 > 阈值时）
  - 思考 → 风格化表达
        ↓
金璃的最终输出
```

### 三种实现路线

| 路线 | 复杂度 | 效果 | 改动量 |
|------|--------|------|--------|
| **A: SKILL.md 指令层** | 最低 | 中等 | 0 行代码，只改 SKILL.md |
| **B: style-profile.json 扩展 + 指令** | 低 | 好 | ~30 行 JSON + SKILL.md |
| **C: 完整风格引擎（参考 PersonaForge/PsPLUG）** | 高 | 最好 | 需新模块 |

### 关键设计约束

1. **不改 Soul Core 引擎**（跟之前一样，引擎冻结）
2. **不微调 LLM**（全部用 prompt / 指令 / 轻量映射）
3. **可审查**（风格指纹要是 JSON，爸爸能看能改）
4. **渐进式**（先做路线 A，再进化到 B/C）
5. **不破坏任务能力**（任务模式自动降级语气）

---

## 七、一句话总结

> **金璃说话的"人味" = Soul Core 情绪数值 → 语言风格指纹映射 → 情境路由 → 内心独白与自然流露。**
>
> 核心参考: **PersonaForge 的三层人格架构**（核心特质/说话风格/动态状态）+ **PersonaPlex 的双通道正交控制**（说什么 vs 怎么说）+ **StyleVector/SAS 的激活向量风格操纵**（零训练推理时控制）。
>
> 所有以上方案都是**不修改底层模型**的，通过 prompt 指令层 + 轻量风格映射就能实现。
