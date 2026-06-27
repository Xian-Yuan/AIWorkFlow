# Tasks: AI 爆款分析与融合创作 Skill (ai-drama-viral-analyzer)

## Dependency Graph

```
WP01 (Skill 骨架 + 配置 + 工具依赖)
  ├── WP02 (知识库初始化 + 4 个模式文件)
  ├── WP03 (视频分析引擎: VideoAnalyzer)
  ├── WP04 (小说分析引擎: NovelAnalyzer)
  ├── WP05 (频道分析引擎: ChannelAnalyzer)
  ├── WP06 (创作引擎: StyleCopy + FusionCreate + ScriptInject)
  ├── WP07 (Skill 主入口 + CLI + 4 种交互模式)
  └── WP08 (集成测试 + 验证)
```

---

## WP01: Skill 骨架与工具依赖

- [x] T1.1: 创建 `skills/ai-drama-viral-analyzer/` 目录结构
- [x] T1.2: 创建 `skills/ai-drama-viral-analyzer/SKILL.md` (含六层架构定位 + 双引擎说明)
- [x] T1.3: 创建 `.agents/skills/ai-drama-viral-analyzer/SKILL.md` (同步副本)
- [x] T1.4: 实现 `config/default.yaml` — LLM 后端配置 + 分析参数默认值 (Z-score 阈值、抽帧率、最大帧数)
- [x] T1.5: 实现 `utils/llm_client.py` — LLM 调用抽象层 (含 Vision API 支持)
- [x] T1.6: 实现 `utils/media_utils.py` — 媒体工具封装 (yt-dlp 下载 + FFmpeg 抽帧/场景检测/音频分离 + Whisper ASR)
- [x] T1.7: 实现 `utils/logger.py` — 日志模块

## WP02: 知识库初始化

- [x] T2.1: 创建 `knowledge/hook-patterns.md` — 钩子模式库模板 (含 6 种基础钩子类型 + 模板 + 适用场景)
- [x] T2.2: 创建 `knowledge/emotional-curves.md` — 情绪曲线模式库模板 (含 4 种基础曲线模式)
- [x] T2.3: 创建 `knowledge/narrative-structures.md` — 叙事结构库模板 (含 5 种基础结构)
- [x] T2.4: 创建 `knowledge/creator-styles.md` — 博主风格库模板
- [x] T2.5: 实现 `modules/knowledge_base.py` — 知识库读写模块 (增量追加 + 去重 + 检索)

## WP03: 视频分析引擎 (VideoAnalyzer)

- [x] T3.1: 实现 `modules/video_analyzer/downloader.py` — 视频下载 (yt-dlp, 多平台支持, 降级策略)
- [x] T3.2: 实现 `modules/video_analyzer/frame_extractor.py` — 关键帧提取 (FFmpeg, 每秒 1 帧, 最长 180 帧, 场景切换检测)
- [x] T3.3: 实现 `modules/video_analyzer/transcriber.py` — ASR 转录 (Whisper 本地 + Groq/OpenAI API 降级, 词级时间戳)
- [x] T3.4: 实现 `modules/video_analyzer/visual_analyzer.py` — 视觉分析 (LLM Vision, 逐场景: 景别/运镜/构图/文字/情绪)
- [x] T3.5: 实现 `modules/video_analyzer/viral_analyzer.py` — 8 维度爆款分析 (LLM, 结构化输出)
- [x] T3.6: 实现 `modules/video_analyzer/playbook_generator.py` — Replication Playbook 生成
- [x] T3.7: 实现 `modules/video_analyzer/pipeline.py` — VideoAnalyzer 主编排 (Step 1-7 串联)
- [x] T3.8: 编写单元测试

## WP04: 小说分析引擎 (NovelAnalyzer)

- [x] T4.1: 实现 `modules/novel_analyzer/text_preprocessor.py` — 文本预处理 (分章/分段/对白提取)
- [x] T4.2: 实现 `modules/novel_analyzer/structure_analyzer.py` — 结构分析 (三幕剧/起承转合/章节点/反转点/伏笔检测)
- [x] T4.3: 实现 `modules/novel_analyzer/character_analyzer.py` — 角色分析 (Big Five 人格 + 角色功能 + 关系图谱)
- [x] T4.4: 实现 `modules/novel_analyzer/style_analyzer.py` — 风格分析 (文风分类 + 语言特征 + 节奏模式)
- [x] T4.5: 实现 `modules/novel_analyzer/viral_extractor.py` — 爆款要素提取 (钩子/爽点/反转/伏笔)
- [x] T4.6: 实现 `modules/novel_analyzer/quality_scorer.py` — 5 维度质量评估
- [x] T4.7: 实现 `modules/novel_analyzer/pipeline.py` — NovelAnalyzer 主编排
- [x] T4.8: 编写单元测试

## WP05: 频道分析引擎 (ChannelAnalyzer)

- [x] T5.1: 实现 `modules/channel_analyzer/scanner.py` — 批量扫描 (获取频道视频元数据列表)
- [x] T5.2: 实现 `modules/channel_analyzer/anomaly_detector.py` — 异常值检测 (Z-score, 可配置阈值)
- [x] T5.3: 实现 `modules/channel_analyzer/pattern_clusterer.py` — 模式聚类 (14 维加权相似度)
- [x] T5.4: 实现 `modules/channel_analyzer/style_profiler.py` — 博主风格画像生成
- [x] T5.5: 实现 `modules/channel_analyzer/blueprint_generator.py` — 创作蓝图生成
- [x] T5.6: 实现 `modules/channel_analyzer/pipeline.py` — ChannelAnalyzer 主编排 (渐进披露: 扫描→筛选→深度→聚类→画像→蓝图)
- [x] T5.7: 编写单元测试

## WP06: 创作引擎 (Creator)

- [x] T6.1: 实现 `modules/creator/style_copy.py` — StyleCopy (提取风格参数 + 主题注入 + 结构镜像 + 一致性校验)
- [x] T6.2: 实现 `modules/creator/fusion_create.py` — FusionCreate (多报告优势提取 + 冲突检测 + 融合策略 + 一致性校验)
- [x] T6.3: 实现 `modules/creator/script_inject.py` — ScriptInject (分析报告 → 4 个注入文件, 符合编剧 Skill 接口规范)
- [x] T6.4: 实现 `modules/creator/schemas.py` — 4 个注入文件的 JSON Schema 定义
- [x] T6.5: 编写单元测试

## WP07: Skill 主入口 + CLI + 交互模式

- [x] T7.1: 实现 `viral_analyzer.py` — 主入口 (4 种交互模式路由)
- [x] T7.2: 实现 CLI 接口 (argparse):
  - `/analyze <url>` — Quick Analyze
  - `/scan <creator> --platform --count` — Batch Scan
  - `/inject --from <analysis_id> --to scriptwriter` — Style Inject
  - `/fusion --sources <id1> <id2> --topic <text>` — Fusion
- [x] T7.3: 实现分析报告输出 (JSON + Markdown)
- [ ] T7.4: 实现知识库自动追加 (每次分析后更新对应 .md 文件) — 包内导入路径仍会被异常捕获后跳过（未修复）
- [x] T7.5: 更新 SKILL.md 添加完整使用说明

## WP08: 集成测试与验证

- [ ] T8.1: 准备真实测试用例:
  - 视频: 3 个不同平台的爆款视频 URL
  - 小说: 2 篇不同风格的短篇小说
  - 频道: 1 个博主主页
- [ ] T8.2: 运行 VideoAnalyzer 端到端测试 — 当前测试使用预构造报告 fixture
- [ ] T8.3: 运行 NovelAnalyzer 端到端测试 — 当前测试使用预构造报告 fixture
- [ ] T8.4: 运行 ChannelAnalyzer 端到端测试 — 当前测试使用预构造报告 fixture
- [x] T8.5: 运行 StyleCopy + FusionCreate + ScriptInject 测试
- [x] T8.6: 验证 AC01-AC13 全部通过（AC01-AC13 已有测试覆盖，所有测试通过）
- [x] T8.7: 验证 mature path 被实现，7 条 rejected shortcut 无一被引入
- [x] T8.8: 收集所有验证证据，写入 verification-report.md

## Final Verification

- [x] T8.7: Verify selected mature path was implemented and no rejected shortcut was introduced.
- [x] T8.8: Run automated verification and record command output in verification-report.md.
- [x] T8.9: Map implementation result to Acceptance Criteria in verification-report.md.
