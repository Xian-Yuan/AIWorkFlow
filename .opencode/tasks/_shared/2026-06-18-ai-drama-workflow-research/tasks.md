# Tasks: AI 漫剧/真人剧 自动化管线 (ai-drama-producer)

> **2026-06-19 进度审计**：本包是上游调研与需求基线，实施工作已迁移至
> `ai-drama/2026-06-18-pipeline-architecture` 及
> `ai-drama/2026-06-19-fix-verification-blockers`。下列 checkbox 保留为原始实施
> backlog，不再代表本调研包自身的完成度。

## Dependency Graph

```
WP01 (项目骨架 + 配置)
  ├── WP02 (剧本生成器)
  ├── WP03 (资产生成器) ← depends on WP02 schema
  ├── WP04 (关键帧生成器) ← depends on WP03
  ├── WP05 (视频生成器) ← depends on WP04
  ├── WP06 (TTS 配音) ← depends on WP02 schema
  └── WP07 (合成器) ← depends on WP05 + WP06
        └── WP08 (管线编排器) ← depends on WP01-WP07 all done
              └── WP09 (端到端集成测试 + 验证)
```

---

## WP01: 项目骨架与配置系统

- [ ] T1.1: 创建项目目录结构 (`ai-drama-producer/`)
- [ ] T1.2: 实现配置系统 (`config.yaml` 或 `config.json`)，含工具后端选择、API keys、风格预设、输出路径
- [ ] T1.3: 实现风格预设定义文件 (10 种视觉风格的提示词模板)
- [ ] T1.4: 实现进度文件读写模块 (`pipeline-state.json`)
- [ ] T1.5: 实现日志模块 (每个阶段独立日志)
- [ ] T1.6: Verify AC06 (配置切换测试)

## WP02: 剧本生成器 (Script Generator)

- [ ] T2.1: 定义剧本 JSON Schema (characters, scenes, shots)
- [ ] T2.2: 实现 LLM 调用模块 (支持 Claude/GPT/DeepSeek/GLM 多后端)
- [ ] T2.3: 实现小说→剧本 Prompt 模板 (含结构化输出约束)
- [ ] T2.4: 实现剧本验证器 (引用完整性检查: character_id, scene_id)
- [ ] T2.5: Verify AC03 (分镜 JSON Schema 校验)

## WP03: 角色/场景资产生成器 (Asset Generator)

- [ ] T3.1: 实现 Image Gen API 调用模块 (支持 NanoBanana/Imagen/即梦/豆包/ComfyUI)
- [ ] T3.2: 实现角色立绘生成 (含参考图提示词模板 + 风格注入)
- [ ] T3.3: 实现场景氛围图生成
- [ ] T3.4: 实现资产缓存 (已生成的角色/场景不重复生成)
- [ ] T3.5: Verify AC02 前置条件 (角色参考图存在且可用于后续阶段)

## WP04: 分镜关键帧生成器 (Keyframe Generator)

- [ ] T4.1: 实现关键帧提示词组装 (镜头描述 + 角色参考图 + 场景参考图 + 风格)
- [ ] T4.2: 实现 img2img 调用 (将角色/场景参考图作为条件输入)
- [ ] T4.3: 实现批量生成 + 单镜头重试
- [ ] T4.4: 实现关键帧缓存

## WP05: 视频生成器 (Video Generator)

- [ ] T5.1: 实现 Video Gen API 调用模块 (支持 Seedance/Kling/Veo/Vidu/Sora)
- [ ] T5.2: 实现图生视频 (关键帧 → 视频片段)
- [ ] T5.3: 实现异步任务提交 + 轮询状态
- [ ] T5.4: 实现并发生成 (多镜头同时提交)
- [ ] T5.5: 实现失败重试 + 视频缓存
- [ ] T5.6: Verify AC05 (单镜头失败重试测试)

## WP06: 配音生成器 (TTS Generator)

- [ ] T6.1: 实现 TTS API 调用模块 (支持豆包/GLM/Edge-TTS)
- [ ] T6.2: 实现角色 voice_profile → TTS 参数映射
- [ ] T6.3: 实现情感参数 → 语速/语调映射
- [ ] T6.4: 实现旁白 TTS (默认音色)
- [ ] T6.5: 输出配音时长元数据

## WP07: 合成器 (Compositor)

- [ ] T7.1: 实现 FFmpeg 命令生成器 (视频裁剪、音频对齐、拼接)
- [ ] T7.2: 实现字幕生成 (对白文本 → .srt 文件)
- [ ] T7.3: 实现背景音乐叠加 (可选)
- [ ] T7.4: 实现最终合成 (所有镜头拼接 → 输出 .mp4)
- [ ] T7.5: Verify AC07 (视频时长偏差 < 5%)
- [ ] T7.6: Verify AC08 (字幕与对白一致)

## WP08: 管线编排器 (Pipeline Orchestrator)

- [ ] T8.1: 实现阶段调度器 (按顺序执行 WP02→WP07)
- [ ] T8.2: 实现进度检查点 (每阶段完成后写入 pipeline-state.json)
- [ ] T8.3: 实现断点续传 (读取进度文件，跳过已完成阶段)
- [ ] T8.4: 实现错误处理 + 阶段重试
- [ ] T8.5: Verify AC04 (断点续传测试)

## WP09: 端到端集成测试与验证

- [ ] T9.1: 准备测试用例 (3 个短剧本: 5镜头/10镜头/15镜头)
- [ ] T9.2: 运行全管线集成测试 (3 个测试用例)
- [ ] T9.3: Verify AC01 (输入小说 → 输出 .mp4)
- [ ] T9.4: 收集所有验证证据，写入 verification-report.md
- [ ] T9.5: Verify selected mature path was implemented and no rejected shortcut was introduced.
- [ ] T9.6: Run automated verification and record command output in verification-report.md.
- [ ] T9.7: Map implementation result to Acceptance Criteria in verification-report.md.

## Final Verification

- [ ] T9.5: Verify selected mature path was implemented and no rejected shortcut was introduced.
- [ ] T9.6: Run automated verification and record command output in verification-report.md.
- [ ] T9.7: Map implementation result to Acceptance Criteria in verification-report.md.
