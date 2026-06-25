# AI Video Creator Pipeline Skill (ai-video-creator) v1.0

> **六阶段完整 AI 视频创作流水线**
> 灵感采集 → 故事立项 → 剧本大纲 → 角色提示词 → 分镜/导演提示词 → AI视频提示词生成
> 参考 shortdrama-pipeline 的 CLI 门控模式（approve before proceed）

## Skill Identity

- **名称**: ai-video-creator
- **版本**: v1.0
- **角色**: 完整视频创作管线 — 从灵感到可执行的视频生成提示词包
- **触发条件**: 用户说"做视频"/"创作视频"/"AI视频"/"写剧本"/"分镜"/"视频提示词"等
- **父模块**: Jinli AI Video Production System
- **代码位置**: Project/Jinli/services/ai-video-creator/

## 架构总览

`
┌─────────────────────────────────────────────────────────┐
│  ai-video-creator (本 Skill)                            │
│                                                         │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐           │
│  │ S0 灵感  │──▶│ S1 立项  │──▶│ S2 剧本  │           │
│  │ 采集     │   │ 故事立项 │   │ 大纲     │           │
│  └──────────┘   └──────────┘   └──────────┘           │
│       │                              │                  │
│       │ style_injection              │                  │
│       ▼                              ▼                  │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐           │
│  │ viral-   │   │ S3 角色  │   │ S4 分镜  │           │
│  │ analyzer │   │ 提示词   │──▶│ 导演提示 │           │
│  └──────────┘   └──────────┘   └──────────┘           │
│                                     │                  │
│                                     ▼                  │
│                              ┌──────────┐             │
│                              │ S5 视频  │             │
│                              │ 提示词   │             │
│                              └──────────┘             │
│                                     │                  │
│                                     ▼                  │
│                         generation_manifest.json       │
│                         (可直接喂给视频生成平台)        │
└─────────────────────────────────────────────────────────┘
`

## 六阶段详细说明

### S0: 灵感采集
- **输入**: 主题/关键词 + (可选) style_injection.json
- **输出**: { "ideas": [...] } — 3-5 个视频创作灵感提案
- **每个提案包含**: title, premise, genre, target_audience, platform, hook, viral_potential, reference
- **风格注入**: 来自 bilibili-crawler 蒸馏的博主创作 DNA

### S1: 故事立项
- **输入**: 选定的灵感提案
- **输出**: 完整故事立项书 (project_name, logline, genre, tone, narrative_structure, story_beats, climax, theme, hook_design, ending_design)
- **叙事结构可选**: 起承转合 / 三幕式 / 英雄之旅 / 倒叙 / 环形 / 反转链 / 递进式

### S2: 剧本大纲
- **输入**: 故事立项书
- **输出**: 结构化剧本 (title, synopsis, scenes[], dialogue_plan[], narrator_lines[], transitions[])
- **每个场景包含**: scene_id, location, time, characters, description, key_action, emotion_start/end

### S3: 角色提示词
- **输入**: 剧本大纲
- **输出**: { "characters": [...] } — 每个角色的完整视觉提示词
- **每个角色包含**: appearance_prompt_en/zh, face_features, costume_details, voice_description, voice_id_suggestion, color_palette, ref_image_prompt, consistency_notes

### S4: 分镜/导演提示词
- **输入**: 剧本大纲 + 角色提示词
- **输出**: { "shots": [...], "total_duration_sec", "shot_count" }
- **每个镜头包含五维度约束**:
  1. subject_action: 主体及物理动视描述
  2. camera_spec: 焦段/景深/机位高度
  3. time_state: 时间码范围 + 主角心理/身体状态演变
  4. aesthetic_style: 美学渲染风格锚点
  5. emotion_intensity: 情绪强度(1-10)
- **镜头语言**: shot_type, camera_move, lighting, description_zh/en, first/last_frame_hint

### S5: AI视频提示词生成
- **输入**: 分镜脚本 + 角色提示词 + 平台选择
- **输出**: { "shots": [...], "platform", "assembly_order" }
- **每个镜头包含**: prompt, negative_prompt, platform_specific, first_frame_prompt, last_frame_prompt, character_ref_prompts, tts_config
- **支持平台**: Seedance 2.0 / Kling 3.0 / Hailuo 2.3 / PixVerse V6 / Veo 3.1 / Runway

## 使用方式

### 方式一：CLI 交互模式（推荐，带审核门控）
`ash
cd Project/Jinli/services/ai-video-creator
python cli.py shell
`
进入交互菜单，每个 Stage 完成后需要 approve 才能继续下一步。

### 方式二：E2E 自动模式
`ash
cd Project/Jinli/services/ai-video-creator
python e2e_full.py
`
自动跑完 6 个阶段，带重试逻辑。

### 方式三：被其他 Skill 调用
`python
import sys
sys.path.insert(0, r'Project/Jinli/services/ai-video-creator')
sys.path.insert(0, r'Project/Jinli/services/ai-video-creator/stages')

from s0_inspiration import run as run_s0
from s1_project_brief import run as run_s1
from s2_script import run as run_s2
from s3_characters import run as run_s3
from s4_storyboard import run as run_s4
from s5_video_prompts import run as run_s5

# 逐步调用，每步可审核
ideas = run_s0("我的主题", style_injection=style_data)
brief = run_s1(ideas["ideas"][0])
script = run_s2(brief)
characters = run_s3(script)
storyboard = run_s4(script, characters)
video_prompts = run_s5(storyboard, characters, platform="seedance")
`

## 与上下游 Skill 的关系

| Skill | 关系 | 交互 |
|-------|------|------|
| ai-drama-viral-analyzer | 上游 | 提供 style_injection.json（博主蒸馏风格） |
| ai-drama-scriptwriter | 互补 | 本 Skill 的 S2+S3+S4 覆盖了 scriptwriter 的功能，但更面向视频而非漫剧 |
| ai-video-director | 下游/内置 | 本 Skill 的 S5 已包含 director 的平台提示词生成能力 |
| bilibili-crawler | 上游 | 提供博主视频蒸馏数据（creator_dna + style_injection） |

## 风格注入流程

`
1. 用户指定博主 → bilibili-crawler scan + distill
2. 输出 quench_distillation.json (creator_dna + style_injection)
3. style_injection 注入 S0 + S1 + S2 的 LLM prompt
4. 整个管线的 tone/pacing/visual_style 被博主风格覆盖
`

## 平台选择决策树

`
需要中国平台？
  ├─ 是 → 需要多镜头一致性？
  │     ├─ 是 → Kling 3.0 Pro
  │     └─ 否 → 预算优先？
  │           ├─ 低 → Hailuo-02 512p
  │           ├─ 中 → Hailuo-2.3 768p / Seedance 2.0
  │           └─ 高 → Seedance 2.0 720p (当前Elo榜首)
  └─ 否 → 需要原生音频？
        ├─ 是 → Veo 3.1 / Kling 3.0 Omni
        └─ 否 → 预算优先？
              ├─ 低 → LTX-2.3 Fast
              ├─ 中 → PixVerse V6
              └─ 高 → Veo 3.1
`

## LLM 配置

- **默认**: MiniMax-M3 (api.minimaxi.com)
- **API Key**: 从 Project/Jinli/.env 的 MINIMAX_CN_API_KEY 读取
- **重试**: 5次指数退避（10→20→40→80秒），处理 429/500/529/连接错误
- **JSON提取**: 5策略（闭合代码块→未闭合代码块→平衡括号→截断恢复→全文解析）

## 硬约束规则

| # | 规则 | 级别 |
|---|------|------|
| 1 | 每阶段输出必须是 dict，不能是裸 list | MUST |
| 2 | S0 必须有 ideas key，S2 必须有 scenes key，S3 必须有 characters key，S4/S5 必须有 shots key | MUST |
| 3 | 每个镜头 prompt ≤ 200 英文单词 | MUST |
| 4 | negative_prompt 必填 | MUST |
| 5 | 风格注入只覆盖不删除原有内容 | MUST |
| 6 | 镜头时长 2-8 秒 | SHOULD |
| 7 | 连续镜头角色位置/朝向保持连贯 | SHOULD |
| 8 | 对白文本长度与 duration_sec 匹配 (中文 3-4 字/秒) | SHOULD |

## 本地知识库参考

来自 Obsidian JinliKG 的重要参考：

1. **NanoBanana Pro + Gemini 25宫格分镜** (BV1oL6cBaEYk) — Gemini 生成纯分镜脚本 → Nano Banana 生成 25 一致性分镜图 → 喂给视频工具
2. **五维度分镜提示词模板** (BV196j36aE1L) — 绝对主体/物理动视/光学摄影机调度/时间轴状态演变/美学渲染参数
3. **MiniMax TTS + 字幕自动生成** (BV1GLVH6mEKW) — 三层处理(代码规则→AI判断→审核Agent)，词级字幕
4. **AI情绪导演** (BV1br7f6cEri) — 导演阐述式分镜脚本，面部表情/身体动作/情绪层次/情感强度四重维度

## 开源项目参考

1. **shortdrama-pipeline** (108★) — CLI 门控模式，Seed 2.0→Seedream→Seedance→ffmpeg。**本 Skill 的架构参考**
2. **BigBanana AI Director** (1446★) — Script→Asset→Keyframe 4阶段，现已闭源
3. **ai_story** (976★) — Django+Celery，text→storyboard→images→video