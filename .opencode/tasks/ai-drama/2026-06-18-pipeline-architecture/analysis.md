# Analysis: AI 漫剧/真人剧 管线总架构 (v2.1)

> v2.1 更新: 整合 ViralAnalysis 爆款分析调研 (12 开源项目 + 6 商业 SaaS + 8 AI 小说工具)
> 调研文档: `Project/AIDramaProducer/docs/01-Planning/ViralAnalysis/01-viral-analysis-ecosystem-research.md`

## Architecture Context

### System boundaries (v2.1 更新)
AIDramaProducer 是一个 AI 工具链编排系统，覆盖从创意研究到成片的完整管线。v2.1 新增**创意研究层**作为可选前置阶段。

```
输入: 小说/创意文本 + 风格预设 + 工具后端配置 + (可选) 爆款参考
  → [创意研究层] ViralAnalysis Skill (可选 Phase 0)
    → [编排层] Pipeline Orchestrator
      → [执行层] LLM Agent + Media Engine + TTS Engine
        → [一致性层] Global Seed + 参考图 + IP-Adapter + 骨骼绑定
          → [输出层] MP4 + SRT + 剪映草稿
```

### 五层架构 (v2.1 — 新增 Layer 0)

```
┌─────────────────────────────────────────────────┐
│  Layer 0: 创意研究层 (新增，可选)                 │
│  ViralAnalysis Skill                            │
│  - 爆款视频/小说分析 (hook/结构/情绪/风格)        │
│  - 风格参数提取 → style_injection.json           │
│  - 角色原型分析 → character_archetypes.json       │
│  - 分镜节奏参考 → shot_pacing_reference.json      │
│  参考: viral-video-analyzer + hook-lab +         │
│        ViralMint + InkAI + novel-writer          │
├─────────────────────────────────────────────────┤
│  Layer 1: 输入层                                 │
│  小说/剧本 + 风格预设 + 工具后端配置              │
│  + (可选) style_injection.json                   │
├─────────────────────────────────────────────────┤
│  Layer 2: 编排层                                 │
│  Pipeline Orchestrator                          │
├─────────────────────────────────────────────────┤
│  Layer 3: 执行层 (三层 Agent)                    │
│  决策层 → 执行层(编剧+美术+配音) → 监督层         │
├─────────────────────────────────────────────────┤
│  Layer 4: 一致性层                               │
│  Global Seed + 参考图 + IP-Adapter + 骨骼绑定    │
├─────────────────────────────────────────────────┤
│  Layer 5: 输出层                                 │
│  MP4 + SRT + 剪映草稿                            │
└─────────────────────────────────────────────────┘
```

### ViralAnalysis 调研关键发现

#### 爆款分析项目进化路径

```
Level 1: 单视频拆解分析
  输入 URL → 输出结构化分析报告
  代表: hook-lab (9★), videoanalyzer (5★)

Level 2: 多视频对比 + 模式提取
  分析多个视频，聚类找共性模式
  代表: viral-ops (5★), Trend-Lens (2★)

Level 3: 分析 → 复制创作
  分析后不仅给报告，还生成可用的脚本/提示词
  代表: viral-video-analyzer (39★, 同类最高)

Level 4: 全链路自动化
  趋势发现 → 分析 → 创作 → 发布 → 监控
  代表: ViralMint (18★, 6 个内置 Agent)
```

#### 8 个核心分析维度 (按出现频率)

| 维度 | 出现率 | 对 AIDramaProducer 的价值 |
|------|:------:|--------------------------|
| ① 钩子分析 | 100% | 编剧 Step 3 分镜设计 — 前 3 秒 hook 策略 |
| ② 叙事/结构 | 92% | 编剧 Step 1 故事分析 — 三幕剧/SCQA 等结构参考 |
| ③ 情绪曲线 | 83% | 编剧 Step 3 — 情绪节奏设计 + voice_profile emotion 映射 |
| ④ 剪辑节奏 | 75% | 编剧 Step 3 — 镜头时长分布、切镜频率 |
| ⑤ 镜头语言 | 67% | 编剧 Step 3 — 景别/运镜/构图参考 |
| ⑥ CTA 分析 | 58% | 编剧 Step 3 — 结尾引导设计 |
| ⑦ 文案/金句 | 58% | 编剧 Step 3 — 对白/旁白金句生成 |
| ⑧ 评论区 | 42% | 编剧 Step 1 — 受众偏好洞察 → 角色设计 |

#### 与 scriptwriter-skill 的数据注入映射

| scriptwriter 组件 | ViralAnalysis 可注入内容 | 注入格式 |
|-------------------|------------------------|---------|
| `styles/presets.yaml` | 从爆款分析中提取的"热门风格参数" | `style_injection.json` |
| Step 1 角色提取 | 爆款角色原型分析 (Big Five 人格模型) | `character_archetypes.json` |
| Step 2 场景拆分 | 爆款场景节奏 → 场景时长建议 | `scene_pacing_reference.json` |
| Step 3 分镜设计 | 爆款镜头语言 → 镜头类型分布参考 | `shot_language_reference.json` |
| TTS-first 策略 | 爆款配音风格分析 → voice_profile 建议 | `voice_style_reference.json` |

#### 6 种架构模式总结

| 模式 | 最佳代表 | 对 AIDramaProducer 的启示 |
|------|---------|--------------------------|
| **Single-Agent 直流** | viral-video-analyzer | 下载→抽帧→ASR→视觉→分析→提示词，一条线 |
| **Multi-Agent 协作** | ViralMint, video-break-agentkit | 不同 Agent 负责不同环节，与我们的三层 Agent 一致 |
| **Skill 寄生模式** | hook-lab, videoanalyzer | 寄生在 Claude Code 里，斜杠命令调用 — 与我们的 Skill 体系天然契合 |
| **异常值驱动** | viral-ops, Trend-Lens | 不分析所有视频，只分析超常表现的那几个 (Z-score) |
| **渐进披露** | Thothy | 先批量扫描→筛选→深度分析 |
| **结构镜像** | HookMafia | 不是改写，是保留结构换内容 |

### 关键设计决策 (v2.1 新增)

8. **ViralAnalysis 作为独立 Skill**: 不嵌入编剧 Skill，作为可选上游数据源。编剧 Skill 通过 `style_injection.json` 接收注入数据。这保持了编剧 Skill 的独立性和可测试性。
9. **异常值驱动分析**: 参考 viral-ops 的 Z-score 策略 — 不分析所有参考内容，只分析"远超创作者平均水平"的那几个。节省分析成本，聚焦真正有价值的模式。
10. **结构镜像而非内容复制**: 参考 HookMafia — 分析提取的是结构模式（叙事逻辑、情绪曲线、镜头节奏），而非具体内容。这避免了版权风险。
11. **渐进披露**: 参考 Thothy — 先批量扫描→筛选→深度分析。避免对每个参考视频都做全流程分析。

### Rejected Shortcuts (v2.1 新增)

| 捷径 | 风险 | 替代方案 | 验证来源 |
|------|------|---------|---------|
| 把爆款分析嵌入编剧 Skill | 编剧 Skill 职责膨胀，测试困难 | 独立 ViralAnalysis Skill + 数据注入接口 | 文档推荐架构 |
| 分析所有参考视频 | 成本高，噪音大 | 异常值驱动: Z-score 筛选超常表现 | viral-ops |
| 直接复制爆款内容 | 版权风险 + 同质化 | 结构镜像: 提取结构模式，换内容 | HookMafia |
| 一次性全流程深度分析 | Token 消耗大 | 渐进披露: 批量扫描→筛选→深度分析 | Thothy |

## Quality Gate (v2.1 新增)

- 管线必须支持**可选的创意研究阶段** (Phase 0: ViralAnalysis)
- 编剧 Skill 必须支持**风格注入数据**作为可选输入 (`style_injection.json`)
- 风格注入数据与风格预设不冲突 (注入数据优先级高于预设默认值)
- ViralAnalysis 输出必须包含**结构模式**而非具体内容 (避免版权风险)
