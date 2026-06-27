# WP05: 频道分析引擎 (ChannelAnalyzer)

Owner model: unclaimed
Difficulty: hard
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/ai-drama/2026-06-18-viral-analyzer-skill/`
- Parent task: `2026-06-18-viral-analyzer-skill`

## Allowed Paths
- `skills/ai-drama-viral-analyzer/modules/channel_analyzer/` (新建)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`

## Read First
- `routing.md`
- `analysis.md` (异常值驱动 + 渐进披露 + 模式聚类)
- `spec.md` (Module 3: ChannelAnalyzer + 输出 JSON Schema)
- `tasks.md` (WP05 section)

## Goal
实现频道分析引擎：批量扫描→Z-score 异常值检测→异常值深度分析→14 维模式聚类→博主风格画像→创作蓝图。

## Steps
- [ ] 实现 `modules/channel_analyzer/scanner.py` — 批量扫描:
  - 获取频道最近 50-100 个视频元数据 (播放量/点赞/评论/时长/标题/缩略图)
  - 支持 YouTube/TikTok/抖音/B站
- [ ] 实现 `modules/channel_analyzer/anomaly_detector.py` — 异常值检测:
  - virality_score = views / channel_avg_views
  - Z-score 计算, 默认阈值 2.0 (可配置)
  - 标记异常值视频列表
- [ ] 实现 `modules/channel_analyzer/pattern_clusterer.py` — 模式聚类:
  - 14 维加权相似度 (8 分析维度 + 6 元数据维度)
  - 自动聚类命名 (如"超高互动型"、"稳定输出型")
- [ ] 实现 `modules/channel_analyzer/style_profiler.py` — 博主风格画像:
  - 综合所有异常值分析结果
  - 输出: 签名钩子/偏好结构/情绪签名/视觉美学/音频风格/受众关系
- [ ] 实现 `modules/channel_analyzer/blueprint_generator.py` — 创作蓝图:
  - title_formula + hook_bank + structure_template + visual_rules + audio_rules + publishing_rules
- [ ] 实现 `modules/channel_analyzer/pipeline.py` — 主编排 (渐进披露: 扫描→筛选→深度→聚类→画像→蓝图)
- [ ] 编写单元测试

## Done Definition
- 输入博主主页 URL → 批量扫描 → 异常值检测 → 博主风格画像 + 创作蓝图
- Z-score 阈值可配置
- 模式聚类自动命名
- 单元测试通过

## Required Verification
- Command: `python -m pytest skills/ai-drama-viral-analyzer/tests/test_channel_analyzer.py -v`
- Expected: all tests pass

## Return Report
- Path: `reports/<agent-name>-WP05-result.md`
- Required status for merge: `done`
