# WP03: 测试修复 + 补充

Owner model: 金璃好帮手
Difficulty: high（涉及 7 个新测试套件 + scriptwriter test 修复）
Status: pending
Depends on: WP02

## Goal
- 修复 scriptwriter 的 2 failed tests
- 7 个无测试 Skill 增加基础测试

## Steps

### T3.1: 识别 scriptwriter 2 failed
```powershell
cd Project/AIDramaProducer/skills
python -m pytest ai_drama_scriptwriter/tests/ -v 2>&1
```
根据输出修实现或修测试。

### T3.2: 修复后全部通过

### T3.3-T3.10: 补充测试
每个 test 文件参考现有 `ai_drama_scriptwriter/tests/test_integration.py` 的风格编写:
- 使用 `pytest` + fixture
- 测试核心逻辑而非外部依赖
- 模拟函数用 `lambda` 或 `unittest.mock`

最低测试数:
| Skill | 最少测试数 | 核心覆盖 |
|-------|:---------:|---------|
| orchestrator | 3 | init/dry_run/handler_reg |
| text-preprocessor | 3 | chapters/events/char_detect |
| asset-generator | 3 | init/create/cache |
| keyframe-generator | 2 | generate/ref_collect |
| tts-generator | 3 | dialogue/duration/update |
| video-generator | 4 | init/gen/tts_force/retry |
| compositor | 4 | srt/multi_dialogue/clip/concat |

## Verification
```powershell
python -m pytest ai_drama_orchestrator/tests/ -v
python -m pytest ai_drama_text_preprocessor/tests/ -v
python -m pytest ai_drama_asset_generator/tests/ -v
python -m pytest ai_drama_keyframe_generator/tests/ -v
python -m pytest ai_drama_tts_generator/tests/ -v
python -m pytest ai_drama_video_generator/tests/ -v
python -m pytest ai_drama_compositor/tests/ -v
python -m pytest ai_drama_scriptwriter/tests/ -v  # all pass
python -m pytest ai_drama_viral_analyzer/tests/ -v  # all pass
```
