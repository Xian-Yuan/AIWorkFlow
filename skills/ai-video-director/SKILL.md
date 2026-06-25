# AI Video Director Skill (ai-video-director) v1.0

> 六层架构中的**Layer 5: 视频生成层**
> 定位: 从分镜剧本到平台级视频生成提示词的自动化导演引擎
> 上游: ai-drama-scriptwriter (script.json v2.0) + ai-drama-viral-analyzer (style_injection.json)
> 下游: 视频生成平台 API (Seedance/Kling/Hailuo/PixVerse/Veo/Runway)

## Skill Identity

- **名称**: ai-video-director
- **版本**: v1.0
- **角色**: 导演层 — 将分镜剧本翻译为平台级视频生成提示词
- **触发条件**: script.json v2.0 输入 + 平台选择 + 风格注入(可选)
- **父模块**: AIDramaProducer Pipeline Phase 5

## 核心职责

从编剧输出的 script.json，生成可直接喂给视频生成平台的提示词包。

```
输入: script.json (from ai-drama-scriptwriter)
  + style_injection.json (from ai-drama-viral-analyzer, 可选)
  + platform_config (目标平台+参数)
      ↓
  导演引擎处理:
    1. 镜头语言映射 (中文术语 → 英文prompt片段)
    2. 平台适配 (每个平台不同的prompt格式要求)
    3. 风格注入 (tone/pacing/visual_style 覆盖)
    4. 首尾帧控制 (start_frame/end_frame 提示)
    5. 角色参考图提示词
    6. 配乐/音效/配音配置
      ↓
输出: generation_manifest.json (全镜头提示词包)
```

## 平台选择决策树

```
需要中国平台？
  ├─ 是 → 需要多镜头一致性？
  │     ├─ 是 → Kling 3.0 Pro (多镜头叙事)
  │     └─ 否 → 预算优先？
  │           ├─ 低 → Hailuo-02 512p ($0.08/视频)
  │           ├─ 中 → Hailuo-2.3 768p / Seedance 2.0
  │           └─ 高 → Seedance 2.0 720p (当前Elo榜首)
  └─ 否 → 需要原生音频？
        ├─ 是 → Veo 3.1 (最佳音视频) / Kling 3.0 Omni
        └─ 否 → 预算优先？
              ├─ 低 → LTX-2.3 Fast ($2.40/min, 开源#1)
              ├─ 中 → PixVerse V6 ($6.90/min)
              └─ 高 → Veo 3.1 ($24/min)
```

## 镜头语言 → Prompt 映射库

### 摄影机运动

| 中文 | 英文 Prompt | 平台备注 |
|------|------------|---------|
| 推镜头 | dolly in, slow push forward, cinematic | Kling/Seedance: 用 camera_move=forward |
| 拉镜头 | dolly out, reveal, wide shot | Kling: camera_move=backward |
| 横摇 | pan left to right, sweeping | Seedance: motion=pan_right |
| 纵摇 | tilt up, low angle rising | |
| 环绕 | orbit 360 around subject | Kling: camera_move=orbit |
| 升降 | crane shot, ascending, dramatic | |
| 跟拍 | tracking shot, subject-following | |
| 固定 | locked-off tripod, static frame | |
| 荷兰角 | dutch angle 30deg, tilted horizon | |

### 构图

| 类型 | 英文 Prompt |
|------|------------|
| 中景 | medium shot, waist up |
| 近景 | close-up, head and shoulders, shallow DOF f/1.8 |
| 特写 | extreme close-up, eye detail |
| 远景 | extreme wide shot, vast landscape |
| 全景 | wide shot, full body, environmental |
| 过肩 | over-the-shoulder shot, foreground blur |
| 俯拍 | bird's-eye view, top-down |
| 仰拍 | low angle, looking up, heroic |
| POV | POV shot, first person perspective |

### 光线

| 光线 | 英文 Prompt | 情绪 |
|------|------------|------|
| 黄金时刻 | golden hour, warm rim light, long shadows | 浪漫/史诗 |
| 蓝调时刻 | blue hour, twilight, cool ambient | 神秘/孤独 |
| 阴天散射 | overcast, soft diffused light | 压抑/日常 |
| 霓虹 | cyberpunk neon, magenta and cyan rim | 科幻/赛博 |
| 窗光 | window light, Rembrandt lighting | 戏剧/内省 |
| 逆光剪影 | backlight silhouette, sun flare | 英雄/史诗 |

## 平台 Prompt 格式模板

### Seedance 2.0 / Dreamina

```json
{
  "prompt": "{scene_description_en}, {shot_type}, {camera_move}, {lighting}",
  "negative_prompt": "blurry, low quality, watermark, text",
  "resolution": "1280x720",
  "duration": 5,
  "seed": 42,
  "first_frame_image": "base64_or_url",
  "last_frame_image": "base64_or_url"
}
```

### Kling 3.0

```json
{
  "prompt": "{scene_description_en}, {shot_type}, {camera_move}, {lighting}",
  "negative_prompt": "",
  "mode": "std",
  "duration": "5",
  "aspect_ratio": "16:9",
  "camera_control": {
    "type": "forward",
    "speed": 0.5
  }
}
```

### Hailuo / MiniMax

```json
{
  "prompt": "{scene_description_en}, {shot_type}, {camera_move}, {lighting}",
  "model": "hailuo-2.3",
  "resolution": "768p",
  "duration": 6,
  "first_frame_image": "url",
  "last_frame_image": "url"
}
```

### PixVerse V6

```json
{
  "prompt": "{scene_description_en}, {shot_type}, {camera_move}, {lighting}",
  "negative_prompt": "",
  "model": "v6",
  "quality": "high",
  "duration": 5,
  "aspect_ratio": "16:9",
  "seed": 42
}
```

## 输出 Schema

```json
{
  "project_name": "string",
  "platform": "seedance|kling|hailuo|pixverse|veo|runway",
  "style_injection_applied": true,
  "total_shots": 0,
  "estimated_duration_sec": 0,
  "shots": [
    {
      "shot_id": "S01",
      "scene_id": "SC01",
      "duration_sec": 5,
      "shot_type": "wide|medium|close-up|...",
      "camera_move": "dolly_in|pan|orbit|static|...",
      "lighting": "golden_hour|neon|overcast|...",
      "description_zh": "中文场景描述",
      "description_en": "English scene description for generation",
      "prompt_template": "full prompt string for the target platform",
      "negative_prompt": "blurry, low quality...",
      "dialogue": "对白文本",
      "voice_profile": "narrator|character_name",
      "tts_config": {
        "provider": "elevenlabs|minimax|edgetts",
        "voice_id": "string",
        "pace": 1.0,
        "pitch": 0
      },
      "first_frame_hint": "描述首帧画面",
      "last_frame_hint": "描述末帧画面",
      "keyframe_prompt_enhancement": "给Keyframe Generator的增强提示",
      "platform_specific": {}
    }
  ],
  "music_config": {
    "mood": "epic|tense|comedic|emotional",
    "tempo_bpm": 120,
    "provider": "suno|elevenlabs_music"
  },
  "generation_order": ["S01", "S02", ...],
  "assembly_notes": "剪辑注意事项"
}
```

## 使用方式

### 从 script.json 生成提示词包

```bash
python -m ai_video_director generate \
  --script output/project/script.json \
  --platform seedance \
  --style-injection style_injection.json \
  --output output/project/manifest.json
```

### 仅生成单镜头提示词

```bash
python -m ai_video_director shot \
  --description "少女站在雨中的十字路口" \
  --shot-type close-up \
  --camera-move static \
  --lighting overcast \
  --platform kling
```

## 与上游 Skill 的数据契约

| 来源 | 数据 | 字段 |
|------|------|------|
| scriptwriter | script.json | shots[].description, shots[].duration_sec, shots[].shot_type, characters[].description |
| viral-analyzer | style_injection.json | tone, pacing, hook_style, humor_type, edit_style, visual_style, narrative_template |

## 硬约束规则

| # | 规则 | 级别 |
|---|------|------|
| 1 | 每个镜头 prompt ≤ 200 英文单词 | MUST |
| 2 | negative_prompt 必填 | MUST |
| 3 | duration_sec 必须与 TTS 时长匹配 | MUST |
| 4 | 连续镜头角色位置/朝向保持连贯 | SHOULD |
| 5 | 避免复杂光学效果（倒影/水下/强逆光） | SHOULD |
| 6 | 动作描述用具体动词 | MUST |
| 7 | 对白文本长度与 duration_sec 匹配 (中文 3-4 字/秒) | SHOULD |
| 8 | platform_specific 字段必须符合目标平台 schema | MUST |
| 9 | 风格注入只覆盖不删除 | MUST |

## 配置

编辑 `config/default.yaml` 选择默认平台和参数。
