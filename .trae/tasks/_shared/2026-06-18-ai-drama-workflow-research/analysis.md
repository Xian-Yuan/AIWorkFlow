# Analysis: AI 漫剧/真人剧 工作流

## Architecture Context

### System boundaries
AI 漫剧/真人剧管线是一个**纯 AI 工具链编排问题**，不涉及 UE5 或 Web 前端代码。系统边界为：

```
输入: 小说/创意文本
  → 剧本生成 (LLM)
  → 角色/场景资产生成 (Image Gen)
  → 分镜脚本 (LLM + 结构化输出)
  → 关键帧/分镜图 (Image Gen)
  → 视频生成 (Video Gen)
  → 配音 + TTS (TTS Engine)
  → 后期合成 (FFmpeg / 剪映)
输出: 完整短剧视频文件 (.mp4)
```

### Dependency map
```
LLM (GPT-5.x / Claude / DeepSeek / GLM-5.1)
  ├── 剧本生成
  ├── 分镜脚本
  └── 角色描述 → Image Gen
                    ├── NanoBanana Pro / Gemini Imagen / 即梦 / 豆包
                    ├── 角色立绘/场景图
                    └── 关键帧 → Video Gen
                                  ├── Seedance 2.0 / Kling / Veo / Vidu / Sora-2
                                  └── 视频片段 → TTS Engine
                                                  ├── 豆包 TTS / GLM-TTS / 剪映内置
                                                  └── 配音音频 → FFmpeg / 剪映
                                                                  └── 最终合成 .mp4
```

### Data and state ownership
- **剧本**: 结构化 JSON/Markdown，含角色列表、场景列表、对话
- **角色资产**: 图片文件 + 角色描述 JSON (用于一致性)
- **分镜**: 结构化 JSON，含镜头号、景别、运镜、时长、对白、参考图路径
- **视频片段**: 独立 .mp4 文件，按镜头号命名
- **配音**: 独立 .mp3/.wav 文件，按角色+镜头号命名
- **项目状态**: 管线进度文件 (JSON/YAML)，追踪每个阶段的完成状态

### Integration points
- **Claude Code Skills**: 作为编排层，调用外部 API (LLM/Image/Video/TTS)
- **Dify / n8n / OpenClaw**: 低代码编排替代方案
- **ComfyUI**: 图片/视频生成后端 (本地或 API)
- **FFmpeg**: 命令行合成，跨平台

## Mature Solution Evidence

### 已调研的开源项目 (14+ repos)

| 项目 | Stars | 成熟度 | 核心价值 |
|------|-------|--------|---------|
| [BigBanana AI Director](https://github.com/BigBananaTeam/ai-director) | 1,410 | 工业级 | 一站式平台，4-Phase 架构，Docker 部署，Web UI |
| [LocalMiniDrama](https://github.com/LocalMiniDrama/LocalMiniDrama) | 671 | 成熟 | Electron 桌面应用，完全本地离线，MIT 开源 |
| [Micro-Drama-Skills](https://github.com/micro-drama/micro-drama-skills) | 203 | 活跃 | Claude Skills 驱动，3 个 Skill，10 种视觉风格 |
| [xiakeman-ai-short-drama](https://github.com/xiakeman/ai-short-drama) | 21 | 新兴 | Seedance 2.0 专用，Docker + 桌面版 |
| [ai-drama-production](https://github.com/ai-drama/ai-drama-production) | — | 实验 | Claude Code Skill，双模式 (Film/Motion Comic) |
| [toonany](https://github.com/toonany/toonany) | — | 实验 | Claude Code Skill，小说→漫剧一站式 |
| [kais-aigc-movie](https://github.com/kais-aigc/kais-aigc-movie) | — | 工具包 | TS 工具包，ComfyUI/Kling 双后端 |
| [juben](https://github.com/juben/juben) | 77 | 成熟 | 40+ Agent 剧本创作平台 |

### 事实标准管线 (7 阶段)

所有成熟项目都遵循同一管线，差异仅在工具选择和自动化程度：

```
Phase 1: 故事/创意 → 小说原文 或 创意大纲
Phase 2: 剧本生成 → 结构化剧本 (场景/角色/对白/旁白)
Phase 3: 角色/场景资产 → 角色立绘、场景图、风格参考
Phase 4: 分镜脚本 → 镜头号/景别/运镜/时长/对白/参考图
Phase 5: 关键帧生成 → 每个镜头的起始帧/关键帧图片
Phase 6: 视频生成 → 图生视频 / 文生视频，逐镜头生成
Phase 7: 配音+合成 → TTS 配音 + FFmpeg 合成最终视频
```

### 工具生态矩阵

| 阶段 | 首选工具 | 备选工具 | 本地替代 |
|------|---------|---------|---------|
| 文本 (剧本/分镜) | Claude 4.x / GPT-5.x | DeepSeek / GLM-5.1 | Ollama + Qwen |
| 图片 (角色/场景/关键帧) | NanoBanana Pro | Gemini Imagen / 即梦 / 豆包 | ComfyUI + SDXL/Flux |
| 视频 (图生视频) | Seedance 2.0 | Kling / Veo / Vidu / Sora-2 | ComfyUI + AnimateDiff |
| TTS (配音) | 豆包 TTS | GLM-TTS / 剪映内置 | Edge-TTS / Coqui |
| 合成 | FFmpeg | 剪映 | FFmpeg |
| 编排 | Claude Code Skills | Dify / n8n / OpenClaw | 自写 Python/TS 脚本 |

### 关键设计决策 (从成熟项目中提取)

1. **角色一致性**: 所有项目都在 Phase 3 生成角色参考图后，后续所有图片/视频生成都附带该参考图作为条件输入。这是管线中最关键的 quality gate。
2. **分镜驱动**: 分镜脚本是管线的"单一真相源"。所有后续阶段 (关键帧、视频、配音) 都从分镜 JSON 派生。
3. **逐镜头处理**: 视频生成阶段按镜头逐个处理，每个镜头独立生成视频片段，最后拼接。这允许失败重试单个镜头而不影响整体进度。
4. **进度可恢复**: 管线状态持久化到文件，每个阶段完成后写入状态。中断后可从断点继续。
5. **风格预设**: Micro-Drama-Skills 的 10 种视觉风格方案值得借鉴 — 用户选择风格预设而非逐参数调整。

### Rejected Shortcuts (不应采用的简化方案)

| 捷径 | 风险 | 替代方案 |
|------|------|---------|
| 跳过角色资产阶段，直接文生视频 | 角色外观不一致，观众出戏 | 必须先生成角色参考图 |
| 跳过结构化分镜，直接生成视频 | 叙事节奏失控，镜头语言缺失 | 分镜 JSON 是管线核心 |
| 所有镜头一次性批量生成 | 失败后全部重来，成本高 | 逐镜头 + 进度文件 |
| 纯 API 调用无本地缓存 | 重复调用成本高，调试困难 | 每个阶段产物落盘 |
| 硬编码单一工具 | 供应商锁定，价格波动风险 | 工具抽象层，可替换后端 |

## Quality Gate

- 管线必须支持**角色一致性** (参考图传递)
- 管线必须支持**断点续传** (进度文件)
- 管线必须支持**逐镜头处理** (独立失败重试)
- 管线必须支持**工具可替换** (抽象层，非硬编码)
- 分镜 JSON schema 必须覆盖: 镜头号、景别、运镜、时长、对白、角色列表、参考图路径

## Automated Verification Plan

由于这是 AI 工具链编排项目 (非传统代码)，验证方式为：

1. **Schema 验证**: 分镜 JSON schema 通过 JSON Schema validator 校验
2. **管线集成测试**: 用一个短剧本 (3-5 镜头) 跑通全管线
3. **输出验证**: 最终 .mp4 文件存在、时长 > 0、分辨率符合预期
4. **进度恢复测试**: 中断后重启，从断点继续而非从头开始
