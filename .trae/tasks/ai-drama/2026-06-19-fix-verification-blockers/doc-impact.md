# Documentation Impact: AIDramaProducer 验收阻断修复

## Project Document Scope
- Project: ai-drama (AIDramaProducer)
- System: 全管线 — 9 Skill / 3 Task Packet
- Owner: 金璃小天才 (Plan) → 金璃好帮手 (Implement)

## Code Changes

### 目录重命名（9 个） — Project/AIDramaProducer/skills/
| 原路径 | 新路径 |
|--------|--------|
| `skills/ai-drama-orchestrator/` | `skills/ai_drama_orchestrator/` |
| `skills/ai-drama-scriptwriter/` | `skills/ai_drama_scriptwriter/` |
| `skills/ai-drama-text-preprocessor/` | `skills/ai_drama_text_preprocessor/` |
| `skills/ai-drama-asset-generator/` | `skills/ai_drama_asset_generator/` |
| `skills/ai-drama-keyframe-generator/` | `skills/ai_drama_keyframe_generator/` |
| `skills/ai-drama-tts-generator/` | `skills/ai_drama_tts_generator/` |
| `skills/ai-drama-video-generator/` | `skills/ai_drama_video_generator/` |
| `skills/ai-drama-compositor/` | `skills/ai_drama_compositor/` |
| `skills/ai-drama-viral-analyzer/` | `skills/ai_drama_viral_analyzer/` |
| 原路径 | 新路径 |
|--------|--------|
| `Project/AIDramaProducer/skills/ai-drama-orchestrator/` | `skills/ai_drama_orchestrator/` |
| `Project/AIDramaProducer/skills/ai-drama-scriptwriter/` | `skills/ai_drama_scriptwriter/` |
| `Project/AIDramaProducer/skills/ai-drama-text-preprocessor/` | `skills/ai_drama_text_preprocessor/` |
| `Project/AIDramaProducer/skills/ai-drama-asset-generator/` | `skills/ai_drama_asset_generator/` |
| `Project/AIDramaProducer/skills/ai-drama-keyframe-generator/` | `skills/ai_drama_keyframe_generator/` |
| `Project/AIDramaProducer/skills/ai-drama-tts-generator/` | `skills/ai_drama_tts_generator/` |
| `Project/AIDramaProducer/skills/ai-drama-video-generator/` | `skills/ai_drama_video_generator/` |
| `Project/AIDramaProducer/skills/ai-drama-compositor/` | `skills/ai_drama_compositor/` |
| `Project/AIDramaProducer/skills/ai-drama-viral-analyzer/` | `skills/ai_drama_viral_analyzer/` |

### 文件修改（预计 20+ 个）
- 9 个 `__init__.py` — 导出主入口
- `orchestrator.py` — 替换 lambda 空处理器
- `text_preprocessor.py` — 实现 `_detect_characters`
- `video_generator.py` — 添加 duration_source 校验
- `compositor.py` — 修正音频匹配逻辑
- `asset_generator.py` — 添加文件复制逻辑
- 各模块中可能的 import 路径修复

### 新文件（预计 25+ 个）
- 7 个 `skills/ai_drama_*/tests/test_*.py` — 新测试文件
- 3 个更新后的 `verification-report.md`
- 3 个更新后的 `.task.yaml`

## Documentation Updates
- 本 task packet 的 `routing.md`, `analysis.md`, `spec.md`, `tasks.md`, `doc-impact.md` — 本次创建
- `.trae/tasks/ai-drama/*/.task.yaml` — review_result/verify_result → passed
- `.trae/tasks/ai-drama/*/verification-report.md` — 重写
- `.trae/tasks/ai-drama/*/tasks.md` — 勾选更新

## Work Package Status
| WP | Name | Status | Files Changed | Notes |
|----|------|:------:|:-------------|-------|
| WP01 | 包结构修复 | pending | 20+ | 目录重命名 + import 路径修复 |
| WP02 | 核心逻辑修复 | pending | 5 | orchestrator/text-preprocess/video/compositor/asset |
| WP03 | 测试修复+补充 | pending | 25+ | 7 个新 test_*.py + scriptwriter test 修复 |
| WP04 | 验收文档 | pending | 9 | 3 task packets × (tasks.md + verification-report + .task.yaml) |
| WP05 | P1 修复 | pending | 2 | asset_generator.py + 占位替换 |
