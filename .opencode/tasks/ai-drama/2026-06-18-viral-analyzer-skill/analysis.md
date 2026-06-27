# Analysis: AI 爆款分析与融合创作 Skill (ai-drama-viral-analyzer)

> 调研文档: `Project/AIDramaProducer/docs/01-Planning/ViralAnalysis/01-viral-analysis-ecosystem-research.md`
> 调研范围: 12 开源项目 + 6 商业 SaaS + 8 AI 小说工具 + 2 学术论文 + 6 套方法论

## Architecture Context

### ViralAnalysis Skill 在六层架构中的位置

```
Layer 0: 创意研究层
  └─ ViralAnalysis Skill (本 Skill) ← 你在这里
      ├── 分析引擎: 视频/小说/博主 → 结构化分析报告
      ├── 创作引擎: 风格复制 + 融合创作
      └── 知识库: 钩子模式库 + 情绪曲线库 + 叙事结构库
          └─ 输出 → Layer 1 输入层
              └─ style_injection.json → Phase 2 Scriptwriter Skill
```

### 与上下游的数据契约

**上游 (用户输入)**:
- 爆款参考 URL (视频/小说/博主主页)
- 分析模式选择 (单视频/多视频对比/频道级/趋势发现)
- 创作模式选择 (风格复制/融合创作/频道风格)

**下游 (Phase 2: Scriptwriter Skill)**:
- `style_injection.json` — 风格参数注入
- `character_archetypes.json` — 角色原型参考
- `shot_pacing_reference.json` — 分镜节奏参考
- `voice_style_reference.json` — 配音风格参考

### 爆款分析领域进化路径

```
Level 1: 单视频拆解分析
  输入 URL → 输出结构化分析报告
  代表: hook-lab (9★), videoanalyzer (5★), tiktok-viral-hooks (2★)
  核心能力: 下载→抽帧→ASR→视觉分析→钩子/结构/情绪/风格拆解

Level 2: 多视频对比 + 模式提取
  分析多个视频，聚类找共性模式
  代表: viral-ops (5★), Trend-Lens (2★), ViralVision AI
  核心能力: 异常值检测(Z-score) + 模式聚类 + 频道级分析

Level 3: 分析 → 复制创作
  分析后不仅给报告，还生成可用的脚本/提示词
  代表: viral-video-analyzer (39★, 同类最高)
  核心能力: 3 类提示词(画面/文案/拍摄) + Replication Playbook

Level 4: 全链路自动化
  趋势发现 → 分析 → 创作 → 发布 → 监控
  代表: ViralMint (18★, 6 个内置 Agent)
  核心能力: Scout→Download→Analyze→Generate→Upload→Plan
```

### 8 个核心分析维度 (按出现频率排序)

| # | 维度 | 出现率 | 分析方法 | 输出物 |
|---|------|:------:|---------|--------|
| ① | **钩子分析** | 100% | 前 3 秒逐帧 + 口播文本 + 视觉冲击力评分 | Hook 类型 + 有效性评分 + 改写模板 |
| ② | **叙事结构** | 92% | 三幕剧/SCQA/英雄之旅/问题-解决 等框架匹配 | 结构分段 + 时间戳标注 + 节奏热力图 |
| ③ | **情绪曲线** | 83% | 逐段情绪标注 (8 种基本情绪) + 峰值/谷值检测 | 情绪曲线图 + 高潮分布 + 情感转折点 |
| ④ | **剪辑节奏** | 75% | 切镜频率统计 + 高潮密度分布 + 留白分析 | 节奏数据 + 镜头时长分布直方图 |
| ⑤ | **镜头语言** | 67% | 景别/运镜/构图分类 + 转场类型统计 | 镜头类型分布 + 运镜模式 + 构图规律 |
| ⑥ | **CTA 分析** | 58% | 引导行为类型 + 时机 + 参与机制 | CTA 类型 + 最佳时机 + 转化预估 |
| ⑦ | **文案/金句** | 58% | 口播文案提取 + 金句识别 + 改写模板 | 金句库 + 2 句公式化模板 |
| ⑧ | **评论区** | 42% | 评论情感分析 + 受众偏好提取 + 争议点识别 | 受众画像 + 内容偏好 + 改进方向 |

### AI 小说/文案创作领域关键发现

| 项目 | 核心能力 | 对编剧 Skill 的启示 |
|------|---------|-------------------|
| **InkAI** (14★) | 7 步结构化创作 + Big Five 人格模型 + 三幕剧结构 + 伏笔管理 | 角色设计的心理学依据 |
| **novel-writer** | 规格驱动开发(SDD) + 斜杠命令注入 + 中文优化 | 与我们的 spec 体系契合 |
| **NovelForge** | 卡片式创作 + JSON Schema 驱动 + 知识图谱一致性 | 卡片式分镜设计可借鉴 |
| **novelwriter** | World Model + 设定萃取逆向工程 + 关系热推理 | 世界观一致性维护 |
| **AIWriteX** | CrewAI 多智能体 + 黑马选题挖掘 + 去 AI 味润色 | 多 Agent 分工 + 趋势预测 |
| **唐库** | 一键生成长篇 + 爆文拆书学习 + 剧本转换 | 爆款结构逆向工程 |
| **岱宗写作** | 多 Agent 接力 + 知识图谱记忆 + 故事圣经 | Agent 接力模式 |
| **神行写作** | 29 种类型 + 15 种文风 + AI 指纹诊断 | 风格分类体系 |

### 6 种架构模式

| 模式 | 代表项目 | 核心机制 | 适用场景 |
|------|---------|---------|---------|
| **Single-Agent 直流** | viral-video-analyzer | 下载→抽帧→ASR→视觉→分析→提示词，一条线 | 单视频深度分析 |
| **Multi-Agent 协作** | ViralMint, video-break-agentkit | 不同 Agent 负责不同环节，消息队列协调 | 全链路自动化 |
| **Skill 寄生模式** | hook-lab, videoanalyzer | 寄生在 Claude Code 里，斜杠命令调用 | 轻量集成 |
| **异常值驱动** | viral-ops, Trend-Lens | Z-score 筛选超常表现，只分析异常值 | 批量扫描 + 精准分析 |
| **渐进披露** | Thothy | 批量扫描→筛选→深度分析，分层递进 | 大规模内容监控 |
| **结构镜像** | HookMafia | 保留结构换内容，不复制只提取模式 | 安全的内容借鉴 |

### 关键设计决策

1. **独立 Skill，非嵌入编剧**: ViralAnalysis 是独立 Skill，通过数据注入接口与编剧 Skill 协作。保持各自独立性和可测试性。
2. **异常值驱动分析**: 不分析所有参考内容，只分析 Z-score > 2x 的超常表现。节省 80% 分析成本。
3. **结构镜像而非内容复制**: 提取结构模式（叙事逻辑、情绪曲线、镜头节奏），而非具体内容。避免版权风险。
4. **渐进披露**: 批量扫描→筛选→深度分析。先粗筛再精析，控制 Token 成本。
5. **Skill 寄生模式**: 作为 Claude Code Skill 运行，斜杠命令触发。与项目现有 Skill 体系一致。
6. **双引擎架构**: 分析引擎 + 创作引擎分离。分析引擎输出结构化报告，创作引擎基于报告生成可注入的风格数据。
7. **知识库积累**: 钩子模式库、情绪曲线库、叙事结构库、博主风格库持续积累，形成数据飞轮。

### 与现有 scriptwriter-skill 的衔接设计

```
ViralAnalysis Skill (本 Skill)
  ├── 分析引擎
  │   ├── VideoAnalyzer → 视频级分析报告
  │   ├── NovelAnalyzer → 小说级分析报告
  │   └── ChannelAnalyzer → 频道级分析报告
  ├── 创作引擎
  │   ├── StyleCopy → 复制某爆款风格创作
  │   ├── FusionCreate → 多元融合创作
  │   └── ScriptInject → 输出给 scriptwriter-skill 的数据
  └── 知识库
      ├── hook-patterns.md
      ├── emotional-curves.md
      ├── narrative-structures.md
      └── creator-styles.md
          ↓ (数据注入)
Scriptwriter Skill (Phase 2)
  ├── --style-injection style_injection.json
  ├── --character-archetypes character_archetypes.json
  ├── --shot-pacing shot_pacing_reference.json
  └── --voice-style voice_style_reference.json
```

### Rejected Shortcuts

| 捷径 | 风险 | 替代方案 | 验证来源 |
|------|------|---------|---------|
| 把分析嵌入编剧 Skill | 职责膨胀，测试困难 | 独立 Skill + 数据注入接口 | 架构分析 |
| 分析所有参考视频 | 成本高，噪音大 | 异常值驱动: Z-score 筛选 | viral-ops |
| 直接复制爆款内容 | 版权风险 + 同质化 | 结构镜像: 提取模式换内容 | HookMafia |
| 一次性全流程深度分析 | Token 消耗大 | 渐进披露: 扫描→筛选→深度 | Thothy |
| 只用单一模型分析 | 视角单一 | Multi-Model Council | komission/Shorti |
| 不积累分析结果 | 每次从零开始 | 知识库 + 模式聚类 | tiktok-viral-hooks |
| 硬编码分析维度 | 无法适应新平台 | 可配置分析维度 + 自定义 schema | 调研共识 |

## Quality Gate

- 分析引擎必须支持至少 5 个核心维度 (钩子/结构/情绪/节奏/镜头)
- 创作引擎必须输出可直接注入编剧 Skill 的结构化 JSON
- 异常值检测必须使用统计方法 (Z-score)，而非主观判断
- 分析结果必须区分"结构模式"和"具体内容" (版权安全)
- 知识库必须支持增量更新 (每次分析追加，不覆盖)
- 支持单视频分析和批量分析两种模式
