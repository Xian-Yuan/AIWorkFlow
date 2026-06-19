# Spec: AI 漫剧/真人剧 自动化管线 (ai-drama-producer)

## GIVEN
- 用户有一篇小说原文 或 创意大纲 (文本格式)
- 用户选择了一种视觉风格 (预设: 日漫/韩漫/美漫/写实/国风/像素/水彩/赛博朋克/胶片/极简)
- 系统可访问至少一个 LLM API (Claude/GPT/DeepSeek/GLM)、一个 Image Gen API (NanoBanana/Imagen/即梦/豆包/ComfyUI)、一个 Video Gen API (Seedance/Kling/Veo/Vidu/Sora)、一个 TTS API (豆包/GLM/Edge-TTS)
- 系统有 FFmpeg 可用

## WHEN
用户触发管线执行:
1. 提供输入文本 (小说/创意大纲)
2. 选择视觉风格预设
3. 选择工具后端 (或使用默认配置)
4. 管线自动执行 7 个阶段，产出最终视频

## THEN

### Module 1: 管线编排器 (Pipeline Orchestrator)
- 读取全局配置 (工具后端选择、输出目录、风格预设)
- 按顺序调度 7 个阶段
- 每个阶段完成后写入进度文件 (`pipeline-state.json`)
- 支持从任意阶段断点续传
- 每个阶段失败时记录错误日志，允许重试

### Module 2: 剧本生成器 (Script Generator)
- 输入: 小说原文 / 创意大纲
- 输出: 结构化剧本 JSON
  ```json
  {
    "title": "剧名",
    "style": "日漫",
    "characters": [
      {
        "id": "char_01",
        "name": "角色名",
        "description": "外观描述，用于 Image Gen 提示词",
        "voice_profile": "声线描述，用于 TTS 参数"
      }
    ],
    "scenes": [
      {
        "id": "scene_01",
        "location": "场景描述",
        "description": "场景氛围描述，用于 Image Gen 提示词"
      }
    ],
    "shots": [
      {
        "id": "shot_01",
        "scene_id": "scene_01",
        "type": "wide | medium | close-up | extreme-close-up | panorama",
        "camera_movement": "static | pan | zoom | dolly | handheld",
        "duration_sec": 5.0,
        "dialogue": [
          {"character_id": "char_01", "text": "对白内容", "emotion": "neutral | happy | sad | angry | surprised"}
        ],
        "narration": "旁白文本 (可选)",
        "description": "画面描述，用于 Image/Video Gen 提示词",
        "characters_in_shot": ["char_01"]
      }
    ]
  }
  ```
- 使用 LLM 生成，附带结构化输出约束 (JSON Schema)
- 验证: 所有 character_id 在 characters 数组中存在，所有 scene_id 在 scenes 数组中存在

### Module 3: 角色/场景资产生成器 (Asset Generator)
- 输入: 剧本 JSON 中的 characters 和 scenes
- 对每个角色: 调用 Image Gen API 生成角色立绘/参考图
  - 提示词 = 角色描述 + 风格预设关键词 + "character reference sheet, full body, consistent style"
  - 输出: `assets/characters/{char_id}.png`
- 对每个场景: 调用 Image Gen API 生成场景氛围图
  - 提示词 = 场景描述 + 风格预设关键词 + "background, environment, no characters"
  - 输出: `assets/scenes/{scene_id}.png`
- 角色参考图将作为后续所有图片/视频生成的条件输入 (保证一致性)

### Module 4: 分镜关键帧生成器 (Keyframe Generator)
- 输入: 剧本 JSON + 角色参考图 + 场景参考图
- 对每个镜头: 调用 Image Gen API 生成关键帧
  - 提示词 = 镜头描述 + 角色参考图 (作为 img2img 输入) + 场景参考图 + 风格预设
  - 输出: `keyframes/{shot_id}.png`
- 支持批量生成 + 单镜头重试

### Module 5: 视频生成器 (Video Generator)
- 输入: 关键帧图片 + 镜头描述 + 时长
- 对每个镜头: 调用 Video Gen API (图生视频)
  - 输入图 = 关键帧
  - 提示词 = 镜头描述 + 运镜描述
  - 时长 = 镜头 duration_sec
  - 输出: `videos/{shot_id}.mp4`
- 支持并发生成 (多个镜头同时提交) + 失败重试
- 轮询 API 任务状态直到完成

### Module 6: 配音生成器 (TTS Generator)
- 输入: 剧本 JSON 中的 dialogue 和 narration
- 对每句对白: 调用 TTS API
  - 角色 voice_profile 映射到 TTS 音色参数
  - 情感参数映射到 TTS 语速/语调
  - 输出: `audio/{shot_id}_{char_id}_{line_index}.mp3`
- 对旁白: 使用默认旁白音色
  - 输出: `audio/{shot_id}_narration.mp3`
- 输出配音时长元数据 (用于后续合成对齐)

### Module 7: 合成器 (Compositor)
- 输入: 视频片段 + 配音音频 + 分镜时长元数据
- 对每个镜头:
  1. 将视频片段裁剪到指定时长
  2. 将对白音频按时间轴对齐
  3. 叠加旁白 (如有)
  4. 添加背景音乐 (可选)
  5. 添加字幕 (从对白文本生成 SRT)
- 将所有镜头按顺序拼接
- 输出: `output/{title}_final.mp4`
- 使用 FFmpeg 命令行完成所有合成操作

## Acceptance Criteria

| AC# | Description | Verification Method |
|-----|-------------|---------------------|
| AC01 | 输入一篇短篇小说 (500-2000字)，输出完整 .mp4 视频 | 端到端集成测试 |
| AC02 | 同一角色在不同镜头中外貌一致 | 人工目视检查 + 角色参考图传递链路验证 |
| AC03 | 分镜 JSON 通过 Schema 校验 (所有必填字段存在，引用完整性) | JSON Schema validator |
| AC04 | 中断后重启，从断点继续而非从头开始 | 进度恢复测试: 在 Phase 5 中断，重启后 Phase 1-4 跳过 |
| AC05 | 单个镜头视频生成失败时，仅重试该镜头，不影响已完成镜头 | 失败重试测试 |
| AC06 | 工具后端可替换 (如从 Kling 切换到 Seedance)，管线其余部分不变 | 配置切换测试 |
| AC07 | 最终视频时长与分镜总时长偏差 < 5% | FFprobe 检查输出视频时长 |
| AC08 | 字幕文件 (.srt) 与对白文本一致，时间轴与配音对齐 | SRT 内容校验 + 播放验证 |

## Progress Summary

| Phase | Status | Key Decision |
|-------|--------|-------------|
| Plan | ✅ Completed | 调研 14+ 开源项目，确定 7 阶段管线 + 工具抽象层架构 |
| Implement | ⬜ Pending | 待外部模型执行 |
| Review | ⬜ Pending | — |
| Verify | ⬜ Pending | — |

## Non-Goals

- 不实现 Web UI (命令行 + Skill 接口即可)
- 不实现实时协作功能
- 不实现视频编辑器的交互式时间轴
- 不实现自有模型训练/微调 (使用现有 API)
- 不集成 UE5 Sequencer (后续可扩展，非本阶段)
- 不处理真人实拍素材 (纯 AI 生成管线)
