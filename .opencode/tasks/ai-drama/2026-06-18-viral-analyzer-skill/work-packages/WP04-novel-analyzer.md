# WP04: 小说分析引擎 (NovelAnalyzer)

Owner model: unclaimed
Difficulty: medium
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/ai-drama/2026-06-18-viral-analyzer-skill/`
- Parent task: `2026-06-18-viral-analyzer-skill`

## Allowed Paths
- `skills/ai-drama-viral-analyzer/modules/novel_analyzer/` (新建)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`

## Read First
- `routing.md`
- `analysis.md` (AI 小说创作领域 8 项目分析)
- `spec.md` (Module 2: NovelAnalyzer + 输出 JSON Schema)
- `tasks.md` (WP04 section)

## Goal
实现小说分析引擎：文本预处理→结构分析→角色分析(Big Five)→风格分析→爆款要素提取→5 维度质量评估。

## Steps
- [ ] 实现 `modules/novel_analyzer/text_preprocessor.py` — 文本预处理 (分章/分段/对白提取/字数统计)
- [ ] 实现 `modules/novel_analyzer/structure_analyzer.py` — 结构分析:
  - 框架匹配: 三幕剧/起承转合/单元剧
  - 章节点检测 (hook_points, twist_points, climax_points)
  - 伏笔追踪 (setup → payoff)
- [ ] 实现 `modules/novel_analyzer/character_analyzer.py` — 角色分析:
  - Big Five 人格模型评分 (O/C/E/A/N)
  - 角色功能分类 (主角/反派/导师/捣蛋鬼/...)
  - 角色弧光识别 (redemption/corruption/growth/fall)
  - 关系图谱构建 (ally/rival/mentor/love_interest)
- [ ] 实现 `modules/novel_analyzer/style_analyzer.py` — 风格分析:
  - 文风分类 (简洁有力/华丽铺陈/幽默讽刺/...)
  - 语言特征 (平均句长/对白比例/描写比例)
  - 节奏模式 (快-慢-快-爆发 等)
- [ ] 实现 `modules/novel_analyzer/viral_extractor.py` — 爆款要素提取:
  - 钩子类型识别
  - 爽点密度计算 (satisfaction_points_per_chapter)
  - 反转点检测
  - 悬念设置频率 (cliffhanger_frequency)
- [ ] 实现 `modules/novel_analyzer/quality_scorer.py` — 5 维度质量评估:
  - coherence (连贯性) / engagement (吸引力) / originality (原创性) / emotional_impact (情感力) / pacing (节奏感)
- [ ] 实现 `modules/novel_analyzer/pipeline.py` — 主编排
- [ ] 编写单元测试 (2 篇测试小说)

## Done Definition
- 输入小说文本 → 输出完整结构分析 + 角色 Big Five + 爆款要素 + 质量评分
- 支持 500-50000 字输入
- 单元测试通过

## Required Verification
- Command: `python -m pytest skills/ai-drama-viral-analyzer/tests/test_novel_analyzer.py -v`
- Expected: all tests pass

## Return Report
- Path: `reports/<agent-name>-WP04-result.md`
- Required status for merge: `done`
