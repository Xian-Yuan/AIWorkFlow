# Tasks: AIDramaProducer 验收阻断修复 v1.0

> 关联 Task Packet: `ai-drama/2026-06-18-pipeline-architecture`, `ai-drama/2026-06-18-scriptwriter-skill`, `ai-drama/2026-06-18-viral-analyzer-skill`

## Dependency Graph

```
WP01 (包结构修复 — 不依赖任何其他修复)
  └── WP02 (核心逻辑 bug 修复 — 依赖 WP01 完成)
        └── WP03 (测试修复 + 补充 — 依赖 WP02)
              ├── WP04 (验收文档 + Verify 门禁 — 依赖 WP01-03)
              └── WP05 (P1 修复 — 可与 WP04 并行，依赖 WP01)
```

---

## WP01: 包结构修复

**目标**: 让 9 个 Skill 成为合法的 Python 包，`python -m ai_drama_*` 可执行

**依赖**: 无

- [x] **T1.1**: 重命名 9 个 Skill 目录
  - `ai-drama-orchestrator/` → `ai_drama_orchestrator/`
  - `ai-drama-scriptwriter/` → `ai_drama_scriptwriter/`
  - `ai-drama-text-preprocessor/` → `ai_drama_text_preprocessor/`
  - `ai-drama-asset-generator/` → `ai_drama_asset_generator/`
  - `ai-drama-keyframe-generator/` → `ai_drama_keyframe_generator/`
  - `ai-drama-tts-generator/` → `ai_drama_tts_generator/`
  - `ai-drama-video-generator/` → `ai_drama_video_generator/`
  - `ai-drama-compositor/` → `ai_drama_compositor/`
  - `ai-drama-viral-analyzer/` → `ai_drama_viral_analyzer/`

- [x] **T1.2**: 更新 `__init__.py` — 每个包导出主类和入口函数
  - `ai_drama_orchestrator/__init__.py`: 导出 `PipelineOrchestrator`, `main`
  - `ai_drama_scriptwriter/__init__.py`: 导出 `scriptwriter` 模块
  - 其他同理

- [x] **T1.3**: 修复包内 `import` 路径（连字符 → 下划线）
  - 搜索所有 `.py` 文件中 `from ai-drama-` / `import ai-drama-` 模式（如果存在）
  - 替换为 `from ai_drama_` / `import ai_drama_`
  - **特别注意**：`scriptwriter/` 内部有 `import sys; sys.path.append(...)` 和跨模块引用

- [x] **T1.4**: 验证 `python -m ai_drama_* --help` 可执行
  - 每个 Skill 的 CLI 入口返回 exit code 0

- [x] **T1.5**: 更新 SKILL.md 中的模块路径引用

**Acceptance Criteria 映射**: AC01

---

## WP02: 核心逻辑 Bug 修复

**目标**: 消除 B01, B05, B06, B08 共 4 个 P0 阻断

**依赖**: WP01 完成（import 路径可用）

### Orchestrator 集成（B01）

- [x] **T2.1**: 编写 `orchestrator` 的 `_build_default_handlers()` 方法 — 调用 Scriptwriter cmd_quick 管线
  - 不再在 `main()` 中注册 lambda
  - `register_handler` 默认注册真实调用:
    - `phase1_text_preprocess`: 调用 `ai_drama_text_preprocessor.build_chapter_graph`
    - `phase2_scriptwriter`: 调用 `ai_drama_scriptwriter.scriptwriter.main`（带参数）
    - `phase3_asset`: 调用 `ai_drama_asset_generator.generate_assets`
    - `phase4_keyframe`: 调用 `ai_drama_keyframe_generator.KeyframeGenerator.generate_all`
    - `phase6_tts`: 调用 `ai_drama_tts_generator.TTSGenerator.generate_all`
    - `phase5_video`: 调用 `ai_drama_video_generator.VideoGenerator.generate_all`
    - `phase7_compositor`: 调用 `ai_drama_compositor.Compositor.compose`

- [x] **T2.2**: 修复 `main()` 函数
  - 默认注册真实 handler
  - 提供 `--dry-run` 参数使用模拟 handler（用于测试）

- [x] **T2.3**: 验证 orchestrator 至少能串行过程序不报错 — 已修复数据流，管线全 7 阶段通过
  - `python -m ai_drama_orchestrator --dry-run --input test.txt --output test_out`
  - `python -m ai_drama_orchestrator --input test.txt --output test_out` → 非空 output

### 文本预处理角色追踪（B05）

- [x] **T2.4**: 实现 `_detect_characters(text, known_ids, char_map)` — 使用 char_map 查角色名，保留 regex 回退
  - 输入: 文本 + 角色 ID 列表
  - 输出: 文本中出现的角色 ID 列表
  - 算法: 遍历 known_ids 中每个 ID，在文本中搜索对应的 name（从 script 的 characters 列表获取）
  - 在 `build_chapter_graph` 中传入 `script.characters` 或通过参数传递
  - 如果没有 known_ids 传入，返回空数组（no regression）

### 视频生成 TTS-first 强制（B06）

- [x] **T2.5**: 在 `generate_video()` 开头增加 duration_source 校验
  - `if duration_source != "tts_measured": raise ValueError(...)`
  - 在 `generate_all()` 中遍历 shots 时做前置校验
  
### 合成器音频时长 Bug（B08）

- [x] **T2.6**: 修正 `_generate_srt()` 中同角色多句对白的音频匹配
  - 当前: 每句 dialogue 重新 `char_audios = [...]`，然后 `pop(0)` 只改局部
  - 修复: 用迭代器或直接从 `audio_by_shot[shot_id]` 中 `del` 已使用的条目
  - 示例: `audio_by_shot[shot_id]` 按顺序排列，每次取 `audio_by_shot[shot_id].pop(0)` 从源头移除

**Acceptance Criteria 映射**: AC02, AC03, AC04, AC05

---

## WP03: 测试修复 + 补充

**目标**: B03（scriptwriter 2 failed 修复）+ B04（7 个 Skill 新加测试）

**依赖**: WP02 完成

### Scriptwriter 测试修复

- [x] **T3.1**: 运行现有测试识别 2 failed
  - `cd Project/AIDramaProducer/skills && python -m pytest ai_drama_scriptwriter/tests/ -v`
  - 记录哪些 test failed 及其原因

- [x] **T3.2**: 修复 failed tests
  - 根据失败原因修实现或修测试用例
  - Scriptwriter 当前 28 tests all pass（含 9 个注入消费测试）

### 7 个 Skill 补充测试

- [x] **T3.3**: `ai_drama_orchestrator/tests/` — 最少 3 个测试
  - `test_orchestrator_init`: PipelineOrchestrator 能初始化
  - `test_dry_run`: 空 handler 模式执行不报错
  - `test_handler_registration`: 注册/移除 handler

- [x] **T3.4**: `ai_drama_text_preprocessor/tests/` — 最少 3 个测试
  - `test_chapter_detection`: 章节分割正确
  - `test_event_extract`: 事件提取
  - `test_character_detect`: 角色追踪（修复后）

- [x] **T3.5**: `ai_drama_asset_generator/tests/` — 最少 3 个测试
  - `test_asset_library_init`: AssetLibrary 初始化
  - `test_get_or_create_character`: 角色资产创建/缓存
  - `test_cache_hit`: 相同 hash 命中缓存

- [x] **T3.6**: `ai_drama_keyframe_generator/tests/` — 最少 2 个测试
  - `test_keyframe_generate`: 关键帧生成
  - `test_collect_ref_images`: 参考图收集

- [x] **T3.7**: `ai_drama_tts_generator/tests/` — 最少 3 个测试
  - `test_dialogue_generate`: 对白 TTS
  - `test_duration_measure`: 时长测量
  - `test_update_script_durations`: TTS-first 时长更新

- [x] **T3.8**: `ai_drama_video_generator/tests/` — 最少 3 个测试
  - `test_init`: VideoGenerator 初始化
  - `test_generate_video`: 视频生成（模拟 mode）
  - `test_tts_first_enforcement`: duration_source 校验（修复后）
  - `test_failed_retry`: 失败重试

- [x] **T3.9**: `ai_drama_compositor/tests/` — 最少 4 个测试
  - `test_srt_generation`: 字幕生成
  - `test_multi_dialogue_same_character`: 同角色多句对白（修复后核心验证）
  - `test_clip_compose`: 单镜头合成
  - `test_concat_videos`: 视频拼接

- [x] **T3.10**: `ai_drama_viral_analyzer/tests/` — 当前 21 tests，确认全部 pass

**Acceptance Criteria 映射**: AC07

---

## WP04: 验收文档 + Verify 门禁

**目标**: B10（任务勾选）+ B11（Verify 门禁）+ B12（verification-report 重写）

**依赖**: WP01, WP02, WP03 全部完成

- [ ] **T4.1**: 勾选 3 个 task packet 的 tasks.md — 已实现项已按事实勾选，但原包仍有未完成项，且要求的 worker reports 尚不存在
  - `ai-drama/2026-06-18-pipeline-architecture/tasks.md` — 根据实际完成情况勾选
  - `ai-drama/2026-06-18-scriptwriter-skill/tasks.md`
  - `ai-drama/2026-06-18-viral-analyzer-skill/tasks.md`
  - 未实现的任务标记 `[ ]` 并注明原因
  - 每个 WP 在 work-packages/*.md 末尾追加完成记录（worker report）

- [ ] **T4.2**: 更新 3 个 task packet 的 `.task.yaml`
  - 当前事实为 `phase: implement`, `review_result: fail`, `verify_result: fail`, `archived: false`
  - 只有全部原始任务、报告和机械门禁通过后，才允许使用规范值 `pass`
  - 人工批准不能覆盖失败门禁

- [x] **T4.3**: 重写 3 个 verification-report.md — 已全部重写，含实际命令输出
  - pipeline-architecture: 106 tests、7-phase dry-run、placeholder non-dry-run output
  - scriptwriter-skill: 28 tests、schema、presets、config、注入消费链
  - viral-analyzer-skill: 21 tests、kb files、config、可执行 Scriptwriter 命令
  - 所有报告包含 `python -m pytest` 真实输出、import 验证、Architecture Compliance、Test Evidence、Residual Risk

- [x] **T4.4**: 运行 Verify 门禁记录输出 — 已执行，记录如下：
  - pipeline-architecture: [BLOCKED] Tasks-All-Done ❌ + verify_result=pass ❌
  - scriptwriter-skill: [BLOCKED] Tasks-All-Done ❌ + verify_result=pass ❌
  - viral-analyzer-skill: [BLOCKED] Tasks-All-Done ❌ + verify_result=pass ❌
  - **原因**: 原始 task packet 有未实现任务（真实 AI 后端、真实 URL E2E、媒体质量指标等）
  - **验证报告质量**: 3 份全部通过 quality check ✅
  - 结论: 失败门禁保持失败，不能通过人工批准改写

- [x] **T4.5**: Verify selected mature path was implemented and no rejected shortcut was introduced
  - ✅ 包名用下划线（PEP 8）：9 个 `ai_drama_*` 目录确认
  - ✅ Orchestrator 注册真实 handler：7 个 phase handler 全为非 lambda
  - ✅ 角色检测用 char_map（非 LLM）：_detect_characters 使用 char_map + regex 回退
  - ✅ TTS-first 合约：duration_source != "tts_measured" → ValueError
  - ✅ pytest 测试覆盖：默认根入口 106 tests 全通过
  - ✅ 无被拒绝的捷径引入：
    - 没有保留连字符目录名（已重命名）
    - 没有保留空 handler（已集成）
    - 没有用 LLM 做角色检测
    - 没有用符号链接（用 shutil.copy2）
    - 没有重写所有模块（基于现有代码修补）

**Acceptance Criteria 映射**: AC08, AC09, AC10

### Automated Verification
- [x] **T4.6**: Run automated verification and record command output in verification-report.md
  - ✅ pytest 全量：106 passed（默认根入口）
  - ✅ pipeline dry-run：7 阶段全通
  - ✅ pipeline non-dry-run：exit 0，产出 script.json/final.mp4/subtitles.srt
  - ✅ task-guard.ps1 verify：已运行并记录真实 BLOCKED 输出；该项不代表门禁通过

---

## WP05: P1 修复

**目标**: B07（跨项目资产复制）+ B09（占位字节替换）

**依赖**: WP01 完成

- [x] **T5.1**: 修复全局资产复用文件复制
  - 在 `AssetLibrary.get_or_create_character()` 中
  - 当从全局库命中缓存时: 用 `shutil.copy2()` 将 ref_image 和 bone_data 复制到项目目录
  - 更新 entry 中的路径指向新位置

- [x] **T5.2**: 替换占位字节为结构化模拟数据
  - `b"PLACEHOLDER_MP4"` → 写入一个模拟 MP4 头（或最小有效文件）
  - `b"PLACEHOLDER_PNG"` → 写入一个 1x1 像素的 PNG
  - `b"PLACEHOLDER_MP3"` → 写入一个最小有效 MP3 头
  - 目的: 确保 ffprobe 等工具能解析，不阻塞后续流程

**Acceptance Criteria 映射**: AC06, (AC02 间接)
