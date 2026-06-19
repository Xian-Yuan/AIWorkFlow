# Spec: AIDramaProducer 验收阻断修复 v1.0

> 本 spec 定义修复任务的行为规范。验收标准为：原 12 条阻断项全部消除，Verify 门禁通过。

## Acceptance Criteria

### AC01: 包结构符合 Python 规范
- **GIVEN** 有 9 个 Skill 目录 `ai-drama-*`
- **WHEN** 重命名为 `ai_drama_*`
- **THEN** 所有 `python -m ai_drama_*` 命令可执行（返回 0 或正常输出 help）
- **THEN** `__init__.py` 导出模块的主入口函数

### AC02: Orchestrator 注册真实 Skill Handler
- **GIVEN** `PipelineOrchestrator` 类
- **WHEN** `register_handler` 被调用
- **THEN** 每个阶段的 handler 不是 `lambda state, out: None`
- **THEN** handler 实际调用对应 Skill 的 main 或 entry function
- **THEN** 至少能跑通一个最小管线（input → 到 Phase 4 不报错）

### AC03: 长文本角色追踪不返回空数组
- **GIVEN** 有角色 ID 列表 `known_ids`
- **WHEN** `_detect_characters(text, known_ids)` 被调用
- **THEN** 返回的角色 ID 是 `known_ids` 的子集（在文本中出现的角色）
- **THEN** 不返回空数组（当文本中确实有角色名出现时）

### AC04: 视频生成强制 TTS-first
- **GIVEN** `shot` 包含 `duration_source != "tts_measured"`
- **WHEN** `generate_video()` 被调用
- **THEN** 抛出 `ValueError` 而不是使用 estimated 时长

### AC05: 同角色多句对白使用各自正确的音频时长
- **GIVEN** 同一 scene_id 中同一个 character_id 有 2+ 句对白
- **WHEN** 生成 SRT
- **THEN** 每句对白的字幕时长对应各自的音频实测时长
- **THEN** 不重复使用第一段的时长

### AC06: 跨项目资产复用复制文件
- **GIVEN** 全局资产库中有角色 A
- **WHEN** 新项目复用角色 A
- **THEN** 资产文件（图片/骨骼数据）被复制到新项目的 `assets/` 目录
- **THEN** `asset_index.json` 中的路径指向新项目内的文件

### AC07: 8 个 Skill 有自动化测试
- **GIVEN** 9 个 Skill
- **WHEN** 运行 `python -m pytest skills/ai_drama_*/tests/ -v`
- **THEN** 每个 Skill 至少有 3 个测试通过
- **THEN** scriptwriter 原有的 2 failed 被修复

### AC08: 任务包全部勾选
- **GIVEN** 3 个 task packet 的 tasks.md
- **WHEN** 检查每个 task 的 checkbox
- **THEN** 已实现的任务标记为 `[x]`
- **THEN** 每个 WP 有对应的 worker report（work-packages/*.md 末尾追加完成记录）

### AC09: Verify 门禁通过
- **GIVEN** 修复完成
- **WHEN** 运行 `task-guard.ps1 <task-name> verify`
- **THEN** 返回 exit code 0
- **THEN** `.task.yaml` 中 `review_result: passed`, `verify_result: passed`

### AC10: Verification Report 有实际命令输出
- **GIVEN** verification-report.md
- **WHEN** 检查报告内容
- **THEN** 报告包含实际运行的命令及其 stdout/stderr 输出
- **THEN** 不包含空的自检"✅"标记

## Non-Goals
- 不重写架构（保持现有 6 层架构设计）
- 不替换现有模块的逻辑主体（仅修复验收阻断）
- 不引入新模块或新功能
- 不修改 Scriptwriter 和 Viral-Analyzer 的核心实现（只修 2 failed tests）
- 不实现真实 AI 引擎回调（占位保留，但需要可测试性）

## Implementation Order
1. WP01: 包结构修复（改 9 个目录名 + __init__.py + import 路径）
2. WP02: 核心 bug 修复（orchestrator/text-preprocess/video/compositor/asset）
3. WP03: 测试覆盖（加测试 + 取消 pending 标记）
4. WP04: 验收文档（勾选 + verification-report + verify 门禁）
5. WP05: P1 修复（资产复制/占位替换）
