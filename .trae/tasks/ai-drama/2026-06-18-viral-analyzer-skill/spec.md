# Spec: AI 爆款分析与融合创作 Skill (ai-drama-viral-analyzer)

> 调研文档: `Project/AIDramaProducer/docs/01-Planning/ViralAnalysis/01-viral-analysis-ecosystem-research.md`
> 关联任务: `.trae/tasks/ai-drama/2026-06-18-scriptwriter-skill/` (下游消费者)

## GIVEN
- 用户提供了爆款参考来源 (视频 URL / 小说文本 / 博主主页 URL)
- 用户选择了分析模式 (单内容深度分析 / 多内容对比 / 频道级分析 / 趋势发现)
- 用户选择了创作模式 (仅分析 / 风格复制 / 融合创作 / 数据注入编剧)
- 系统可访问至少一个 LLM API (Claude/GPT/DeepSeek/GLM)，推荐使用支持 Vision 的模型
- 系统有 yt-dlp + FFmpeg + Whisper 可用 (视频分析场景)
- 知识库文件 (`hook-patterns.md`, `emotional-curves.md`, `narrative-structures.md`, `creator-styles.md`) 已初始化

## WHEN
用户触发分析流程:
1. 提供参考来源 + 分析模式 + 创作模式
2. 分析引擎执行: 下载→抽帧→ASR→视觉分析→多维度拆解→模式提取
3. (可选) 创作引擎执行: 风格复制 / 融合创作 / 数据注入
4. 输出结构化分析报告 + (可选) 注入数据文件

## THEN

### 架构总览

```
ViralAnalysis Skill
├── 分析引擎 (Analyzer)
│   ├── VideoAnalyzer — 单视频深度分析
│   ├── NovelAnalyzer — 小说/文案结构分析
│   └── ChannelAnalyzer — 频道/博主级批量分析
├── 创作引擎 (Creator)
│   ├── StyleCopy — 复制某爆款风格创作
│   ├── FusionCreate — 多元融合创作
│   └── ScriptInject — 输出给 scriptwriter-skill 的数据
└── 知识库 (KnowledgeBase)
    ├── hook-patterns.md — 钩子模式库
    ├── emotional-curves.md — 情绪曲线模式库
    ├── narrative-structures.md — 叙事结构库
    └── creator-styles.md — 博主风格库
```

### Module 1: 视频分析引擎 (VideoAnalyzer)

**输入**: 视频 URL (TikTok/YouTube Shorts/Instagram Reels/抖音/B站)
**参考项目**: viral-video-analyzer (39★), videoanalyzer (5★), hook-lab (9★)

**处理流程** (Single-Agent 直流模式):
```
Step 1: 视频下载 (yt-dlp, 最高码率)
Step 2: 关键帧提取 (FFmpeg, 每秒 1 帧, 最长 180 帧)
Step 3: 场景切换检测 (FFmpeg scene detect, 标记切镜点)
Step 4: 音频分离 + ASR 转录 (Whisper, 词级时间戳)
Step 5: 视觉分析 (LLM Vision, 逐帧/逐场景)
Step 6: 多维度爆款分析 (LLM, 8 个维度)
Step 7: 提示词生成 (3 类: 画面/文案/拍摄)
```

**8 个分析维度**:

| # | 维度 | 分析方法 | 输出格式 |
|---|------|---------|---------|
| ① | 钩子分析 | 前 3 秒逐帧 + 口播文本 + 视觉冲击力 5 维评分 | Hook 类型枚举 + 有效性评分(1-10) + 改写模板(2句公式) |
| ② | 叙事结构 | 框架匹配(三幕剧/SCQA/问题-解决/英雄之旅) + 时间戳分段 | 结构类型 + 分段标注(起止时间+功能) + 节奏热力图 |
| ③ | 情绪曲线 | 逐段情绪标注(8种基本情绪) + 峰值/谷值检测 | 情绪序列数组 [{timestamp, emotion, intensity}] + 曲线特征 |
| ④ | 剪辑节奏 | 切镜频率统计 + 高潮密度 + 留白分析 | 镜头时长分布 + 平均切镜间隔 + BPM 等效节奏值 |
| ⑤ | 镜头语言 | 景别/运镜/构图分类 + 转场类型 | 镜头类型分布饼图数据 + 运镜模式序列 + 构图规律 |
| ⑥ | CTA 分析 | 引导行为类型 + 时机 + 参与机制 | CTA 类型 + 出现时间戳 + 预期转化效果 |
| ⑦ | 文案/金句 | 口播文案提取 + 金句识别 + 改写模板 | 金句列表 + 2句公式化模板(填空式) |
| ⑧ | 评论区 | 评论情感分析 + 受众偏好 + 争议点 | 受众画像 + 内容偏好标签 + 改进方向建议 |

**输出**: 结构化分析报告 JSON
```json
{
  "analysis_id": "va_20260618_001",
  "source": {"url": "...", "platform": "tiktok", "duration_sec": 45},
  "hook_analysis": {
    "hook_type": "question_shock",
    "effectiveness_score": 8.5,
    "why_it_works": "用反常识问题制造认知失调，迫使观众寻求答案",
    "rewrite_templates": [
      "你一定以为____，但真相是____",
      "如果你还在____，那你可能____"
    ]
  },
  "narrative_structure": {
    "framework": "problem_solution",
    "segments": [
      {"start_sec": 0, "end_sec": 3, "function": "hook"},
      {"start_sec": 3, "end_sec": 15, "function": "problem_setup"},
      {"start_sec": 15, "end_sec": 35, "function": "solution_reveal"},
      {"start_sec": 35, "end_sec": 45, "function": "cta"}
    ]
  },
  "emotional_curve": [
    {"timestamp_sec": 0, "emotion": "curiosity", "intensity": 0.7},
    {"timestamp_sec": 5, "emotion": "surprise", "intensity": 0.9},
    {"timestamp_sec": 20, "emotion": "satisfaction", "intensity": 0.8}
  ],
  "editing_rhythm": {
    "avg_shot_duration_sec": 2.8,
    "shot_count": 16,
    "bpm_equivalent": 128,
    "climax_density": "high"
  },
  "shot_language": {
    "shot_types": {"close-up": 0.4, "medium": 0.35, "wide": 0.15, "extreme-close-up": 0.1},
    "camera_movements": ["static", "slow-zoom", "handheld-subtle"],
    "transition_types": ["cut", "cut", "fade", "cut"]
  },
  "cta_analysis": {
    "cta_type": "comment_prompt",
    "timing_sec": 42,
    "mechanism": "ask_opinion"
  },
  "golden_lines": [
    {"text": "你省吃俭用攒的钱，正在被通胀一口一口吃掉", "pattern": "反常识+具体动词+画面感"}
  ],
  "audience_insights": {
    "dominant_emotion": "anger_at_system",
    "content_preferences": ["反常识", "实用技巧", "情感共鸣"],
    "improvement_directions": ["增加数据支撑", "缩短铺垫"]
  },
  "replication_playbook": {
    "hook_formula": "反常识问题 + 数据冲击",
    "structure_blueprint": "3秒钩子 → 15秒问题展开 → 20秒解决方案 → 7秒CTA",
    "visual_style": "高对比度 + 快速切镜 + 文字弹幕",
    "audio_style": "快节奏BGM + 激情口播 + 音效强调"
  }
}
```

### Module 2: 小说/文案分析引擎 (NovelAnalyzer)

**输入**: 小说文本 / 爆款文案 / 博主脚本文案
**参考项目**: InkAI (14★), novel-writer, NovelForge, 唐库

**处理流程**:
```
Step 1: 文本预处理 (分章/分段/对白提取)
Step 2: 结构分析 (三幕剧/起承转合/章节点检测)
Step 3: 角色分析 (Big Five 人格模型 + 角色功能 + 关系图谱)
Step 4: 风格分析 (文风分类 + 语言特征 + 节奏模式)
Step 5: 爆款要素提取 (钩子/爽点/反转/伏笔)
Step 6: 质量评估 (5 维度: 连贯性/吸引力/ originality/情感力/节奏感)
```

**输出**: 结构化小说分析报告 JSON
```json
{
  "analysis_id": "na_20260618_001",
  "source": {"title": "...", "word_count": 5000, "genre": "都市"},
  "structure_analysis": {
    "framework": "three_act",
    "act_boundaries": [
      {"act": 1, "start_chapter": 1, "end_chapter": 3, "function": "setup"},
      {"act": 2, "start_chapter": 4, "end_chapter": 8, "function": "confrontation"},
      {"act": 3, "start_chapter": 9, "end_chapter": 12, "function": "resolution"}
    ],
    "hook_points": [
      {"chapter": 1, "type": "mystery", "effectiveness": 9}
    ],
    "twist_points": [
      {"chapter": 7, "type": "identity_reveal", "impact": "high"}
    ]
  },
  "character_analysis": [
    {
      "name": "主角名",
      "big_five": {"O": 0.7, "C": 0.3, "E": 0.5, "A": 0.2, "N": 0.8},
      "archetype": "anti_hero",
      "function": "protagonist",
      "arc": "redemption",
      "relationship_map": {"ally": ["char_02"], "rival": ["char_03"]}
    }
  ],
  "style_analysis": {
    "prose_style": "简洁有力",
    "avg_sentence_length": 18,
    "dialogue_ratio": 0.45,
    "description_ratio": 0.25,
    "pacing_pattern": "快-慢-快-爆发",
    "emotional_density": "high"
  },
  "viral_elements": {
    "hook_types": ["身份反转", "打脸爽文", "金手指觉醒"],
    "satisfaction_points_per_chapter": 2.5,
    "cliffhanger_frequency": "每章结尾"
  },
  "quality_scores": {
    "coherence": 8.5,
    "engagement": 9.0,
    "originality": 7.0,
    "emotional_impact": 8.0,
    "pacing": 8.5
  }
}
### Module 3: 频道/博主分析引擎 (ChannelAnalyzer)

**输入**: 博主主页 URL (YouTube/TikTok/抖音/B站)
**参考项目**: viral-ops (5★), Trend-Lens (2★), ViralVision AI

**处理流程** (异常值驱动 + 渐进披露):
```
Step 1: 批量扫描 (获取频道最近 50-100 个视频的元数据)
Step 2: 异常值检测 (Z-score 计算每个视频的 virality score = views/channel_avg)
Step 3: 筛选异常值 (Z-score > 2x 的视频标记为"超常表现")
Step 4: 异常值深度分析 (对筛选出的视频执行 VideoAnalyzer 全流程)
Step 5: 模式聚类 (14 维加权相似度聚类，提取共性模式)
Step 6: 博主风格提炼 (综合所有异常值分析结果，输出博主风格画像)
Step 7: 生成 Blueprint (综合所有分析，输出可执行的创作蓝图)
```

**输出**: 博主风格画像 + 创作蓝图
```json
{
  "analysis_id": "ca_20260618_001",
  "channel": {"name": "...", "platform": "youtube", "subscribers": 500000},
  "scan_summary": {
    "total_videos_scanned": 80,
    "anomalies_detected": 12,
    "avg_virality_score": 1.0,
    "anomaly_threshold": 2.0
  },
  "creator_style_profile": {
    "signature_hook_types": ["question_shock", "statistic_bomb"],
    "preferred_structures": ["problem_solution", "listicle"],
    "emotional_signature": "high_energy_curiosity_spike",
    "visual_aesthetic": "dark_mode + neon_accent + fast_cuts",
    "audio_style": "electronic_bgm + fast_paced_voiceover",
    "audience_relationship": "mentor_to_student"
  },
  "pattern_clusters": [
    {
      "cluster_name": "超高互动型",
      "member_count": 5,
      "common_traits": ["争议性话题", "评论区引导", "情感共鸣结尾"],
      "avg_engagement_rate": 0.12
    }
  ],
  "creative_blueprint": {
    "title_formula": "数字 + 反常识 + 你",
    "hook_bank": ["99%的人不知道...", "如果你还在...那你..."],
    "structure_template": "Hook(3s) → Problem(15s) → Solution(20s) → CTA(7s)",
    "visual_rules": ["每 2 秒切镜", "文字弹幕强调关键词", "结尾 3 秒品牌露出"],
    "audio_rules": ["BGM 跟随情绪曲线变化", "关键句降速强调"],
    "publishing_rules": {"best_time": "weekday_20:00", "frequency": "daily"}
  }
}
```

### Module 4: 创作引擎 — StyleCopy (风格复制)

**输入**: 分析报告 (VideoAnalyzer/NovelAnalyzer/ChannelAnalyzer 输出) + 用户主题
**功能**: 基于分析报告的风格参数，用用户的新主题生成内容

**处理流程**:
```
Step 1: 提取风格参数 (从分析报告中提取 hook/结构/情绪/节奏/镜头/文案 参数)
Step 2: 用户主题注入 (将用户的新主题套入风格参数框架)
Step 3: 结构镜像生成 (保留结构，替换内容)
Step 4: 风格一致性校验 (生成内容与参考风格的相似度评分)
```

**输出**: 新主题 + 参考风格的内容脚本
```json
{
  "mode": "style_copy",
  "reference_analysis_id": "va_20260618_001",
  "user_topic": "如何用 AI 提升工作效率",
  "generated_script": {
    "hook": "你每天花 3 小时做的报表，AI 其实 30 秒就能搞定",
    "structure": "Hook(3s) → Problem(15s) → Solution(20s) → CTA(7s)",
    "key_lines": ["...", "..."],
    "visual_suggestions": ["屏幕录制", "数据对比动画", "文字弹幕"],
    "style_similarity_score": 0.85
  }
}
```

### Module 5: 创作引擎 — FusionCreate (融合创作)

**输入**: 2-5 个分析报告 + 用户主题
**功能**: 提取多个爆款的各自优势维度，融合为一个新风格

**处理流程**:
```
Step 1: 多报告优势维度提取 (每个报告在 8 个维度上的 top 特征)
Step 2: 冲突检测 (不同来源的风格参数是否冲突)
Step 3: 融合策略选择 (取最高分/加权平均/用户指定)
Step 4: 融合风格生成
Step 5: 一致性校验
```

**输出**: 融合风格参数 + 生成脚本
```json
{
  "mode": "fusion_create",
  "reference_analysis_ids": ["va_001", "va_002", "na_001"],
  "fusion_strategy": {
    "hook": {"source": "va_001", "reason": "highest_effectiveness_score"},
    "structure": {"source": "na_001", "reason": "best_narrative_flow"},
    "emotional_curve": {"source": "va_002", "reason": "most_engaging_pattern"},
    "visual_style": {"source": "va_001", "reason": "user_preference"}
  },
  "generated_script": {...},
  "fusion_consistency_score": 0.78
}
```

### Module 6: 创作引擎 — ScriptInject (数据注入编剧)

**输入**: 分析报告 (任意来源) + 目标: 生成编剧 Skill 可消费的注入数据
**功能**: 将分析结果转换为编剧 Skill 的 4 个注入文件格式

**输出**: 4 个注入数据文件

**`style_injection.json`** — 风格参数注入:
```json
{
  "source": "viral-analysis",
  "reference_analysis_ids": ["va_001"],
  "injected_params": {
    "character_keywords_override": ["sharp jawline", "trench coat", "cyberpunk neon trim"],
    "scene_keywords_override": ["rain-slicked streets", "holographic billboards", "perpetual twilight"],
    "shot_keywords_override": ["dutch angle", "high contrast lighting", "speed lines"],
    "dialogue_style_override": "快节奏对话，每句不超过15字，高频使用反问句",
    "pacing_profile": {
      "hook_duration_sec": 3,
      "avg_shot_duration_sec": 3.5,
      "climax_shot_density": "high",
      "quiet_moment_interval_sec": 25
    }
  }
}
```

**`character_archetypes.json`** — 角色原型参考:
```json
{
  "source": "viral-analysis",
  "archetypes": [
    {
      "name": "反英雄主角",
      "big_five_profile": {"openness": 0.7, "conscientiousness": 0.3, "extraversion": 0.5, "agreeableness": 0.2, "neuroticism": 0.8},
      "common_traits": ["孤僻", "机智", "道德灰色"],
      "visual_patterns": ["深色服装", "伤疤", "冷色调"],
      "voice_patterns": {"timbre": "husky", "pace": "slow", "pitch": "low"},
      "arc_patterns": ["redemption", "corruption"]
    }
  ]
}
```

**`shot_pacing_reference.json`** — 分镜节奏参考:
```json
{
  "source": "viral-analysis",
  "reference_analysis_ids": ["va_001", "va_002"],
  "pacing_data": {
    "shot_type_distribution": {"close-up": 0.35, "medium": 0.30, "wide": 0.20, "extreme-close-up": 0.10, "panorama": 0.05},
    "duration_distribution": {"p25": 2.0, "p50": 3.5, "p75": 5.0, "p95": 7.5},
    "camera_movement_distribution": {"static": 0.40, "slow-pan": 0.25, "slow-zoom": 0.20, "dolly-in": 0.10, "handheld-subtle": 0.05},
    "transition_pattern": "cut_dominant",
    "climax_placement": "golden_ratio"
  }
}
```

**`voice_style_reference.json`** — 配音风格参考:
```json
{
  "source": "viral-analysis",
  "voice_profiles": [
    {
      "role": "protagonist",
      "gender": "male",
      "age_range": "young_adult",
      "timbre": "husky",
      "pace": "moderate",
      "pitch": "medium_low",
      "emotion_default": "contemplative",
      "quirks": ["句尾降调", "偶尔冷笑"]
    }
  ]
}
```

### Module 7: 知识库 (KnowledgeBase)

**4 个知识库文件**, 每次分析后增量更新:

**`hook-patterns.md`** — 钩子模式库:
```markdown
## question_shock (反常识提问)
- 模板: "你一定以为____，但真相是____"
- 适用: 知识科普、财经、科技
- 案例: "你省吃俭用攒的钱，正在被通胀一口一口吃掉"
- 有效性: 8.5/10
- 来源: va_20260618_001

## statistic_bomb (数据炸弹)
- 模板: "____%的人不知道____"
- 适用: 健康、教育、社会
...
```

**`emotional-curves.md`** — 情绪曲线模式库:
```markdown
## high_energy_curiosity_spike
- 模式: 好奇(0s) → 惊讶(5s) → 满足(20s) → 行动欲(40s)
- 适用: 教程类、揭秘类
- 来源: va_20260618_001

## tension_release_cycle
- 模式: 紧张(0s) → 更紧张(10s) → 释放(25s) → 温馨(35s)
- 适用: 故事类、Vlog
...
```

**`narrative-structures.md`** — 叙事结构库:
```markdown
## problem_solution (问题-解决)
- 分段: Hook(3s) → Problem(15s) → Solution(20s) → CTA(7s)
- 适用: 教程、测评、科普
- 来源: va_20260618_001

## three_act (三幕剧)
- 分段: Setup(25%) → Confrontation(50%) → Resolution(25%)
- 适用: 故事、Vlog、纪录片
...
```

**`creator-styles.md`** — 博主风格库:
```markdown
## @creator_name (平台: YouTube, 粉丝: 500K)
- 签名钩子: question_shock + statistic_bomb
- 偏好结构: problem_solution
- 情绪签名: high_energy_curiosity_spike
- 视觉美学: dark_mode + neon_accent + fast_cuts
- 音频风格: electronic_bgm + fast_paced_voiceover
- 受众关系: mentor_to_student
- 分析日期: 2026-06-18
- 来源: ca_20260618_001
```

### 交互模式

**模式 A: 快速分析 (Quick Analyze)**
```
用户: "/analyze https://www.tiktok.com/@xxx/video/xxx"
  → 自动检测平台 → 下载 → 全流程分析
  → 输出分析报告 + Replication Playbook
  → 追加到知识库
```

**模式 B: 批量扫描 (Batch Scan)**
```
用户: "/scan @creator_name --platform youtube --count 50"
  → 批量获取视频元数据 → Z-score 异常值检测
  → 输出异常值列表 + 博主风格初步画像
  → 用户选择哪些异常值进行深度分析
```

**模式 C: 风格注入 (Style Inject)**
```
用户: "/inject --from analysis_001 --to scriptwriter"
  → 读取分析报告 → 转换为 4 个注入文件
  → 输出到指定目录 → 提示编剧 Skill 调用命令
```

**模式 D: 融合创作 (Fusion)**
```
用户: "/fusion --sources analysis_001 analysis_002 --topic 'AI改变生活'"
  → 多报告优势维度提取 → 冲突检测 → 融合生成
  → 输出融合脚本 + 融合风格参数
```

### 输出文件结构

```
output/viral_analysis/{analysis_id}/
  analysis_report.json          # 完整分析报告
  replication_playbook.md       # 人类可读的复制蓝图
  style_injection.json          # 风格注入数据 (给编剧 Skill)
  character_archetypes.json     # 角色原型数据 (给编剧 Skill)
  shot_pacing_reference.json    # 分镜节奏数据 (给编剧 Skill)
  voice_style_reference.json    # 配音风格数据 (给编剧 Skill)
  frames/                       # 提取的关键帧图片
  transcript.json               # ASR 转录全文 (词级时间戳)
```

## Acceptance Criteria

| AC# | Description | Verification Method |
|-----|-------------|---------------------|
| AC01 | 输入 TikTok/YouTube 视频 URL → 输出完整 8 维度分析报告 | 端到端测试 |
| AC02 | 分析报告包含 Replication Playbook (可执行的复制蓝图) | 内容校验 |
| AC03 | 钩子分析输出 Hook 类型 + 有效性评分 + 2 句改写模板 | 字段完整性检查 |
| AC04 | 叙事结构分析输出框架类型 + 分段标注(起止时间+功能) | 字段完整性检查 |
| AC05 | 情绪曲线输出逐段情绪序列 [{timestamp, emotion, intensity}] | Schema 校验 |
| AC06 | 输入小说文本 → 输出结构分析 + 角色 Big Five 分析 + 爆款要素 | 端到端测试 |
| AC07 | 输入博主主页 → 批量扫描 + Z-score 异常值检测 + 博主风格画像 | 端到端测试 |
| AC08 | StyleCopy 模式: 输入分析报告 + 新主题 → 输出风格一致的新脚本 | 风格相似度 > 0.7 |
| AC09 | FusionCreate 模式: 输入 2+ 分析报告 → 输出融合风格脚本 | 融合一致性 > 0.7 |
| AC10 | ScriptInject 模式: 输出 4 个注入文件，格式符合编剧 Skill 接口规范 | Schema 校验 |
| AC11 | 知识库增量更新: 每次分析后追加，不覆盖已有条目 | 文件 diff 检查 |
| AC12 | 异常值检测使用 Z-score 方法，阈值可配置 | 统计方法验证 |
| AC13 | 分析结果区分"结构模式"和"具体内容" (版权安全) | 内容审查 |

## Progress Summary

| Phase | Status | Key Decision |
|-------|--------|-------------|
| Plan | ✅ Completed | 独立 Skill + 双引擎(分析+创作) + 4 知识库 + 异常值驱动 + 结构镜像 |
| Implement | ✅ Completed | 26 文件: 骨架+知识库+3分析引擎+创作引擎+CLI+测试 |
| Review | ⬜ Pending | — |
| Verify | ✅ Self-verified | 13 AC 全部覆盖, verification-report.md 已写 |

## Non-Goals

- 不实现自动发布功能 (那是 ViralMint 的全链路闭环)
- 不实现实时趋势监控 (需要持续运行的爬虫服务)
- 不实现 TRIBE v2 脑反应预测 (非商业许可)
- 不实现视频渲染/生成 (那是 AIDramaProducer 管线的事)
- 不实现社交媒体账号管理
- 不实现付费订阅/商业化功能
