# AI 导演/分镜/表演/影视制作技术栈研究报告（2025–2026）

> **文档定位**：本文件聚焦 **2025-2026** 年度 AI 在 **分镜（Storyboard）/ 表演（Performance & Digital Human）/ 影视·动画·视频 / 核心生成算法** 四个维度的可用工具与工程实践，覆盖 **Web 端工具、开源算法、商业平台、ComfyUI 工作流** 与 **游戏虚拟制作（UE5 MetaHuman / Mass Entity / Inworld）** 边界。
>
> **采集时间**：2026-06-25
> **覆盖范围**：北美 + 中国市场
> **目标读者**：UE5 单机游戏导演、Web 应用前端、独立短片导演、虚拟制片 TD、研究助理
> **前置依赖**：建议先阅读 `01-AI-Development-Playbook.md`、`02-UE5-Coding-Standards.md`、`03-Singleplayer-Lyra-GAS-Rules.md`

---

## 目录

- [第一部分：AI 分镜生成](#第一部分ai-分镜生成)
  - [1.1 分镜工具对比表](#11-分镜工具对比表)
  - [1.2 图像生成 + ControlNet 工作流](#12-图像生成--controlnet-工作流)
  - [1.3 镜头语言转 Prompt 模板](#13-镜头语言转-prompt-模板)
- [第二部分：AI 表演版](#第二部分ai-表演版)
  - [2.1 数字人平台对比表](#21-数字人平台对比表)
  - [2.2 表情/口型驱动算法表](#22-表情口型驱动算法表)
  - [2.3 动作捕捉工具表](#23-动作捕捉工具表)
  - [2.4 AI 导演控制（Inworld / NPC / 实时对话）](#24-ai-导演控制inworld--npc--实时对话)
- [第三部分：AI 影视/动画/视频制作](#第三部分ai-影视动画视频制作)
  - [3.1 完整制作流程图](#31-完整制作流程图)
  - [3.2 动画 AI 工具对比表](#32-动画-ai-工具对比表)
  - [3.3 游戏虚拟制作（UE5 MetaHuman + Mass Entity）](#33-游戏虚拟制作ue5-metahuman--mass-entity)
- [第四部分：核心生成算法](#第四部分核心生成算法)
  - [4.1 关键算法对比与原理](#41-关键算法对比与原理)
  - [4.2 ComfyUI 工程部署](#42-comfyui-工程部署)
- [第五部分：实战工作流模板](#第五部分实战工作流模板)
  - [5.1 短视频工作流](#51-短视频工作流-抖音tiktok-30-60s)
  - [5.2 长视频工作流](#52-长视频工作流-电影级-3-10min)
  - [5.3 动画短片工作流](#53-动画短片工作流-2-5min)
  - [5.4 数字人直播工作流](#54-数字人直播工作流-7x24h)
- [第六部分：参考文献](#第六部分参考文献)

---

## 第一部分：AI 分镜生成

> AI 分镜 = **剧本 → 镜头列表 → 单帧画面 → 镜头语言一致性**。2025-2026 年关键转折点是 **ControlNet + AnimateDiff + DiT 视频模型** 三件套把"可控制的连续镜头"变成日常工具。

### 1.1 分镜工具对比表

| 工具 | 类型 | 价格（2026-06） | 关键能力 | AI 集成度 | 输出格式 | 适用场景 |
|------|------|----------------|---------|----------|---------|---------|
| **Storyboard That** | Web SaaS | Free / 教育版 $9.99/月 / Premium $19.99/月 | 10 万+ 模板、2500+ 角色、拖拽式镜头、导出 PPT/PDF/Video | 中（仅智能推荐） | PDF, PPT, MP4 | 教学、K12、广告提案 |
| **Boords** | Web SaaS | Solo $24/月 / Studio $49/月 | 拖拽、AI 草图、AI 角色、脚本到分镜、版本管理 | 中（AI Storyboarder） | MP4, PDF, animatic | 广告片、MV、品牌 |
| **Toon Boom Storyboard Pro** | 桌面 | $69.99/月 或 $799 一次性（22.x） | 行业金标准、2D/3D 角色绑定、镜头变形、PDF/iOS 导出 | 低（手绘为主） | PDF, MOV, XML(Final Draft) | 影视、动画长片 |
| **Plotagon** | 桌面+移动 | Free / Education $4.99/月 / Pro $9.99/月 | 3D 角色自动表演、可输入剧本自动生成 animatic | 高（AI 导演） | MP4 | 教学短片、社交内容 |
| **Wonder Unit Storyboarder** | 开源桌面 | 免费（MIT） | OpenAI 集成（脚本 → 草图）、PDF 导出 | 中（OpenAI API） | PDF, FBX | 独立导演、学生 |
| **ComfyUI 工作流** | 开源本地 | 免费（GPU 成本） | SD 3.5 / FLUX.1 + ControlNet + AnimateDiff 自定义 | **极高（节点自由）** | PNG, MP4, EXR | 任何镜头一致性需求 |
| **Midjourney** | SaaS + Discord | Basic $10/月 / Pro $30/月 / Mega $60/月 | V6/V7 文生图、--sref 角色参考、--cref 一致性、Pan/Style Tuner | **极高**（2025 一致性突破） | PNG, WebP | 概念图、风格统一分镜 |
| **FLUX.1 [pro/dev/schnell]** | SaaS+开源 | dev $0.025/张 / schnell $0.003/张 / 本地免费 | 12B Rectified Flow Transformer、强 prompt 遵循、解剖学更准 | 极高 | PNG, JPEG | 商业分镜、角色海报 |
| **Stable Diffusion 3.5 / SDXL** | 开源 | 本地免费（16GB+ VRAM） | ControlNet/IP-Adapter/AnimateDiff 全套生态 | 极高（LoRA 自由） | PNG, MP4 | 自定义训练、UE 工程对接 |
| **DALL·E 4 (OpenAI)** | API | $0.04/张 1024×1024 | 文本理解强、与 GPT-4o 联动编辑 | 高 | PNG | 快速提案 |
| **Imagen 4 (Google)** | API | $0.04/张 | 文字渲染强、多语言 prompt | 高 | PNG | 多语言海报 |
| **CogView 4 / 智谱清言** | API | 约 ¥0.06/张 | 中文 prompt 优化、企业合规 | 高 | PNG | 国内合规项目 |
| **通义万相 2.5（阿里）** | API | 阶梯计费，最低约 ¥0.08/张 | 中文 prompt、中文文字渲染、风格迁移 | 高 | PNG, MP4 | 国内电商、剧集 |
| **文心一格 4.0（百度）** | Web + API | 基础免费 / Pro ¥66/月 | 中文场景理解、风格国风、写实 | 高 | PNG | 国内政企、动漫 |
| **即梦 AI 3.0（字节）** | Web | 每日免费额度 / Pro ¥69/月 | 中文 prompt、影视级美学、视频生成（1.5/2.0） | 极高（含 T2V） | PNG, MP4 | 国内短视频 |

#### 1.1.1 镜头一致性方案对比（2025 关键差异）

| 方案 | 工具链 | 角色一致性 | 场景一致性 | 成本 | 学习曲线 |
|------|--------|-----------|-----------|------|---------|
| Midjourney `--cref` + `--sref` | 单平台 | ⭐⭐⭐⭐⭐（官方） | ⭐⭐⭐⭐（`--sref`） | $30/月 | 低 |
| SD + IP-Adapter FaceID | ComfyUI | ⭐⭐⭐⭐（需训练） | ⭐⭐⭐⭐⭐ | 本地 GPU | 中 |
| SD + FLUX Redux | ComfyUI | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 本地 GPU | 中 |
| CogView 4 / 文心一格 | 平台 API | ⭐⭐⭐ | ⭐⭐⭐ | ¥0.06/张 | 低 |
| ComfyUI + AnimateDiff + ControlNet | 本地 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 本地 GPU | 高 |

### 1.2 图像生成 + ControlNet 工作流

#### 1.2.1 推荐基础管线（Midjourney 提案 + ComfyUI 定稿）

```
Step 1 剧本 → GPT-4o/Claude 生成镜头列表（CSV/JSON）
   │
Step 2 中间帧概念图：Midjourney V7 --ar 16:9 --style raw --sref <图集>
   │
Step 3 一致性锁定：FLUX.1 Redux 或 IP-Adapter-FaceID v2
   │
Step 4 镜头控制：ControlNet Canny / Depth / OpenPose（关键 pose）
   │
Step 5 镜头运动预览：AnimateDiff + MotionLoRA（推/拉/摇/移）
   │
Step 6 渲染：FLUX.1 dev 高分辨率 2048×1152
   │
Step 7 输出：PNG（分镜）+ MP4（animatic）
```

#### 1.2.2 ComfyUI 关键节点（2025 推荐栈）

| 节点类型 | 推荐模型 | 显存需求 | 作用 |
|---------|---------|---------|------|
| KSampler | Euler / DPM++ 2M | 8GB+ | 采样 |
| Model Loader | FLUX.1-dev Q8 / GGUF | 12GB+ | 主模型 |
| ControlNet Apply | ControlNet Union SDXL / FLUX | 2GB | 边缘/深度/Pose 控制 |
| IP-Adapter | IP-Adapter-FaceID Plus v2 | 4GB | 角色面部一致性 |
| AnimateDiff | mm_sd15_v3 / hf (Hotshot-XL) | 6GB | 视频化 |
| MotionLoRA | Pan / Zoom / Tilt / Roll LoRA | 0.5GB | 镜头运动 |
| VAE Decode | FLUX.1 / SDXL VAE | 1GB | 解码 |

#### 1.2.3 批量分镜生成 Python 脚本骨架

```python
# scripts/storyboard_generator.py
import csv, json, subprocess, sys
from pathlib import Path

# 1) 读镜头 CSV
shots = []
with open("shots.csv", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    for row in reader:
        shots.append(row)

# 2) 调 ComfyUI API（或本地 HTTP 包装）
import requests
COMFYUI_URL = "http://127.0.0.1:8188"

def gen_shot(prompt: str, ref_image: str, controlnet: str):
    payload = {
        "prompt": {
            "3": {"inputs": {"seed": 42, "steps": 30, "cfg": 7.0,
                              "sampler_name": "euler", "scheduler": "normal",
                              "denoise": 1.0, "model": ["4", 0]}},
            "4": {"inputs": {"ckpt_name": "flux1-dev-fp8.safetensors"}},
            # ... ControlNet / IP-Adapter / AnimateDiff 配置
        }
    }
    r = requests.post(f"{COMFYUI_URL}/prompt", json=payload)
    return r.json()["prompt_id"]

# 3) 批量提交
for i, shot in enumerate(shots):
    pid = gen_shot(shot["prompt"], shot["ref"], shot["controlnet"])
    print(f"[{i+1}/{len(shots)}] {shot['id']} → {pid}")
```

### 1.3 镜头语言转 Prompt 模板

#### 1.3.1 摄影机运动 Prompt 片段库

| 中文术语 | 英文 prompt 片段 | 对应 ControlNet/MotionLoRA |
|---------|-----------------|---------------------------|
| 推镜头 / Dolly in | `dolly in, slow push forward, cinematic` | MotionLoRA-PanIn |
| 拉镜头 / Pull back | `dolly out, reveal, wide shot` | MotionLoRA-PanOut |
| 横摇 / Pan | `pan left to right, sweeping` | MotionLoRA-Pan |
| 纵摇 / Tilt | `tilt up, low angle rising` | MotionLoRA-Tilt |
| 环绕 / Orbit | `orbit 360 around subject` | MotionLoRA-Orbit |
| 升降 / Crane | `crane shot, ascending, dramatic` | MotionLoRA-Crane |
| 跟拍 / Tracking | `tracking shot, subject-following` | MotionLoRA-Tracking |
| 固定 / Static | `locked-off tripod, static frame` | 不需要 MotionLoRA |
| 荷兰角 / Dutch | `dutch angle 30°, tilted horizon` | AnimateDiff Roll |

#### 1.3.2 构图 Prompt 片段库

| 类型 | 英文片段 |
|------|---------|
| 中景 (MS) | `medium shot, waist up` |
| 近景 (CU) | `close-up, head and shoulders, shallow DOF f/1.8` |
| 特写 (ECU) | `extreme close-up, eye detail` |
| 远景 (ELS) | `extreme wide shot, vast landscape` |
| 全景 (WS) | `wide shot, full body, environmental` |
| 过肩 (OTS) | `over-the-shoulder shot, foreground blur` |
| 俯拍 (Bird) | `bird's-eye view, top-down` |
| 仰拍 (Low) | `low angle, looking up, heroic` |
| POV | `POV shot, first person perspective` |
| 主观 | `subjective camera, handheld` |

#### 1.3.3 光线 Prompt 片段库

| 光线 | 英文片段 | 情绪 |
|------|---------|------|
| 黄金时刻 | `golden hour, warm rim light, long shadows` | 浪漫、史诗 |
| 蓝调时刻 | `blue hour, twilight, cool ambient` | 神秘、孤独 |
| 阴天散射 | `overcast, soft diffused light, no harsh shadows` | 压抑、日常 |
| 霓虹 | `cyberpunk neon, magenta and cyan rim` | 科幻、赛博 |
| 窗光 | `window light, Rembrandt lighting, indoor` | 戏剧、内省 |
| 逆光剪影 | `backlight silhouette, sun flare` | 英雄、史诗 |
| 林布兰特光 | `Rembrandt lighting, 45° key light` | 经典肖像 |
| 高调 | `high-key, minimal shadows, bright` | 喜剧、青春 |
| 低调 | `low-key, chiaroscuro, deep shadows` | 惊悚、悬疑 |

---

## 第二部分：AI 表演版

> AI 表演 = **数字人（Avatar） + 表情/口型驱动（Lip-Sync & Face Reenactment） + 动作捕捉（Motion Capture） + AI 导演控制（NPC 对话与编排）**。2025-2026 年三大里程碑：① **Runway Act-Two**（2025 Q4 取代 Act-One）② **LivePortrait**（快手开源，arXiv 2407.03168）成为开源标杆 ③ **Wav2Lip 模型商业化迁移至 Sync.so**（开源维护者不再免费更新）。

### 2.1 数字人平台对比表

| 平台 | 类型 | 价格（2026-06） | 时长上限 | 唇同步 | 多语言 | API | 角色定制 | 关键能力 |
|------|------|----------------|---------|--------|--------|-----|---------|---------|
| **HeyGen** | SaaS | Free 1 视频 / Pro $24/月 100 分钟 / Enterprise 定制 | 10 分钟/视频 | 极佳 | 175+ 语言/方言 | ✓ | ✓ Studio Avatar | 克隆 2 分钟视频 + 语音即可生成 Avatar，2025 H2 加 Motion Agent |
| **D-ID** | SaaS + API | Lite $5.9/月 15 分钟 / Pro $49/月 200 分钟 / Enterprise | 5 分钟 | 良好 | 119 语言 | ✓ | ✓ Lite Avatar | 真人照片 → 说话视频，老照片活化 |
| **Synthesia** | SaaS | Starter $22/月 10 分钟 / Creator $67/月 90 分钟 / Enterprise | 30 分钟 | 极佳 | 140 语言 | ✓ Enterprise | ✓ Custom Avatar | 企业培训首选，SOC2/ISO27001 |
| **Runway Act-Two** | SaaS + API | Standard $12/月 / Pro $28/月 / Unlimited $76/月 | 10 秒 | N/A（角色动作） | — | ✓ | — | 单段视频驱动角色动作与表情（非口型） |
| **NVIDIA Audio2Face-3D** | SDK + NIM | **API 已弃用**，迁移至 **audio2face-3d NIM** | 实时 | 极佳 | 任何语音 | ✓ NIM | ✓ Unreal LiveLink | Unreal Engine MetaHuman 原生接入 |
| **MetaHuman (UE5)** | 引擎原生 | UE5 许可证 | 实时 | 需配 Audio2Face | 任何 | ✓ LiveLink | ✓（像素级） | 影视级真实人脸，2025 加 **MetaHuman Animator** |
| **MiniMax 海螺 AI** | 国产 SaaS | 试用 + 阶梯 | 60 秒 | 良好 | 中文+英语 | ✓ | ✓ 照片克隆 | 中文场景最优，2025 出海 |
| **MiniMax 智影** | Web | 免费版 + ¥198/月 | 5 分钟 | 良好 | 中文 | ✓ | ✓ 公有形象库 | 微信生态，国内短视频 |
| **百度智能云·数字人** | PaaS | 私有化 ¥ 10w+/年 | 实时直播 | 良好 | 中文+粤语 | ✓ | ✓ 1:1 定制 | 政企直播、客服 |
| **阿里云·数字人** | PaaS | 按分钟计费 | 实时 | 良好 | 多语 | ✓ | ✓ | 电商直播、跨境 |
| **腾讯智影** | Web | 免费版 + ¥198/年 | 3 分钟 | 良好 | 中文 | ✓ | ✓ 公有 + 私有 | 公众号视频号生态 |
| **商汤·如影** | PaaS | 私有化 | 实时 | 极佳 | 中文+英语 | ✓ | ✓ | 国资委、银行客服 |
| **硅基智能·风平** | PaaS | 阶梯计费 | 实时 | 良好 | 中文 | ✓ | ✓ | 直播带货，中小主播友好 |
| **魔法星云 / 蚂蚁** | PaaS | 定制 | 实时 | 极佳 | 多语 | ✓ | ✓ | 金融客服、政企 |
| **LivePortrait (开源)** | 开源 | 免费（本地） | 任意 | — | — | ✓ Python | — | arXiv 2407.03168，快手开源 |

#### 2.1.1 选型决策树

```
需要实时直播 + UE5 集成？
  ├─ 是 → MetaHuman + Audio2Face-3D NIM + LiveLink
  └─ 否 → 需要批量 TTS 数字人？
       ├─ 是 → HeyGen / Synthesia（海外）/ 智影/百度（国内）
       └─ 否 → 只需要照片说话？
            ├─ 是 → D-ID / Viggle Real-Time Swap
            └─ 否 → 只需要角色动作？
                 └─ Runway Act-Two / Act-One
```

### 2.2 表情/口型驱动算法表

| 算法 | 来源 | arXiv / 论文 | 速度（GPU） | 质量 | 商用状态 | 适用场景 |
|------|------|-------------|------------|------|---------|---------|
| **LivePortrait** | 快手 | 2407.03168（2024-07） | 12.8ms/帧 RTX 4090 | ⭐⭐⭐⭐⭐ | MIT 开源 | 通用表情迁移、肖像活化 |
| **MuseTalk v1.5** | TMElyralab（腾讯音乐） | 2410.10122（2024-10） | 30fps+ V100 | ⭐⭐⭐⭐ | Apache 2.0 | 高清口型同步、256×256/512×512 |
| **SadTalker** | OpenTalker（西安交大） | 2211.12194（2022-11） | 15fps V100 | ⭐⭐⭐⭐ | Apache 2.0 | 单图+音频驱动 |
| **Wav2Lip** | Rudrabha Mukhopadhyay | — | 30fps+ | ⭐⭐⭐ | **维护停止**，商业版由 **Sync.so** 提供 | 老牌口型同步、CG 模型 |
| **MakeItTalk** | Cornell | 2004.12990（2020） | 中等 | ⭐⭐⭐ | 开源 | 头部+表情 |
| **GeneFace / GeneFace++** | 字节 | 2301.13307 / 2305.07014 | 实时 | ⭐⭐⭐⭐ | 开源 | 实时 + 高保真 |
| **AniPortrait** | 腾讯 | 2403.14394（2024-03） | 中等 | ⭐⭐⭐⭐ | 开源 | 3D 肖像 + 音频 |
| **DiffTalk** | 中科院 | 2303.11048 | 中等 | ⭐⭐⭐⭐ | 开源 | 扩散式说话 |
| **ER-NeRF** | 浙大 | — | 实时 | ⭐⭐⭐⭐⭐ | 开源 | NeRF 说话人、视角自由 |
| **RAD-NeRF** | 浙大 | 2211.05586 | 实时 | ⭐⭐⭐⭐⭐ | 开源 | 实时 + 自由视角 |
| **EMO / EMO2** | 阿里 | 2402.17485 | 慢（10s 出 30s 视频） | ⭐⭐⭐⭐⭐ | 部分开源 | 阿里妈妈数字人、EmoVLM |
| **Hallo / Hallo2** | 复旦 | 2406.08801 | 中等 | ⭐⭐⭐⭐ | 开源 | 肖像动画 |
| **OmniHuman-1** | 字节 | 2502.01061 | 中等 | ⭐⭐⭐⭐⭐ | 闭源 | 多模态多人物驱动 |

#### 2.2.1 LivePortrait 快速使用

```bash
# 安装
git clone https://github.com/KwaiVGI/LivePortrait.git
cd LivePortrait
pip install -r requirements.txt

# 下载权重
huggingface-cli download KwaiVGI/LivePortrait --local-dir ./assets

# 推理（驱动源视频 + 目标图片）
python inference.py -s assets/examples/source/s0.jpg \
                    -d assets/examples/driving/d0.mp4 \
                    -o output.mp4
```

#### 2.2.2 MuseTalk 与 Wav2Lip 切换注意事项（2025 重要更新）

> ⚠️ **2025 关键变更**：Wav2Lip 作者 **Rudrabha Mukhopadhyay** 已将商业版授权给 **Sync.so**，模型名为 **`lipsync-2`**。原 GitHub 仓库仍可下载 `Wav2Lip` 模型权重但停止更新。**新项目建议直接用 MuseTalk v1.5 或 Sync.so API**。

### 2.3 动作捕捉工具表

| 工具 | 类型 | 价格（2026-06） | 硬件需求 | 输出格式 | 延迟 | 适用场景 |
|------|------|----------------|---------|---------|------|---------|
| **Move.ai** | Web + iOS | Free 10 秒 / Pro $29/月 300 秒 / Studio $99/月 | iPhone Pro（LiDAR） | FBX, BVH, USD | ~200ms | 移动端单/双人捕捉 |
| **DeepMotion (SayMotion)** | Web + API | Free 10 秒 / Pro $19.99/月 | 任意摄像头（单/双） | FBX, BVH | ~500ms | 浏览器无穿戴 |
| **Plask** | Web | Free / Pro $24/月 | 单摄像头 | FBX, GLB | ~300ms | 快速原型、舞蹈 |
| **Xsens MVN Awinda** | 专业硬件 | $4,500+ | 17 传感器套装 | FBX, BVH, C3D | <50ms | 影视、游戏 AAA |
| **Rokoko Smartsuit Pro 2** | 中端硬件 | $1,499 + Smartsuit | 19 传感器 | FBX, BVH | <30ms | 独立游戏、独立动画 |
| **OptiTrack** | 专业光学 | $5,000+ | 多摄像头 | FBX, BVH | <10ms | 影视、AAA |
| **Sony mocopi** | 消费级 | $300（套装） | 6 传感器 | FBX, BVH | <50ms | VTuber、直播 |
| **MediaPipe (Google)** | 开源 | 免费 | 任意摄像头 | JSON（关键点） | 实时 | 快速原型、AR/VR |
| **VideoMocap (开源)** | 开源 | 免费（本地 GPU） | 任意视频 | FBX, BVH | 离线 | 视频 → 动作 |

#### 2.3.1 视频 → 动作捕捉流程（无穿戴）

```bash
# 1) 用 MediaPipe 提取人体关键点
python extract_pose.py --input dance.mp4 --output pose.json

# 2) 用 VideoMocap 重定向到 SMPL/XSuit
python videomocap_retarget.py --pose pose.json --model smpl --output motion.fbx

# 3) 导入 UE5 / Blender
# UE5: Content Browser → Import → motion.fbx → Skeletal Mesh
```

### 2.4 AI 导演控制（Inworld / NPC / 实时对话）

#### 2.4.1 工具对比

| 工具 | 类型 | 价格 | 关键能力 | 集成 | 适用场景 |
|------|------|------|---------|------|---------|
| **Inworld AI** | PaaS + SDK | Free 100 分钟/月 / Pro $40/月 2500 分钟 / Enterprise 定制 | 220+ LLM 路由、Realtime TTS/STT、OpenAI Realtime 兼容、情感控制 | UE5 / Unity / Web | NPC 对话、虚拟伴侣 |
| **Convai** | PaaS | Free / Pro $29/月 | NPC 行为树 + LLM、声音克隆 | UE5 / Unity | 游戏 NPC |
| **Replika** | 消费 App | Free / Pro $19.99/月 | 情感陪伴 | — | 消费级（已裁员，2025 不稳定） |
| **MiniMax 角色 (MiniMax)** | SaaS API | 按 token 计费 | 角色一致性、工具调用 | API | 国内出海角色应用 |
| **MiniMax·Glow (字节)** | SaaS | 免费 | 情感陪伴、剧情 | iOS / Android | 消费级 |
| **网易伏羲·有灵** | PaaS | 私有化 | NPC + 工具调用 + 知识库 | UE5 / Unity | 国内游戏 |
| **腾讯·混元大模型 + 数字人** | PaaS | 阶梯计费 | LLM + 数字人 + 实时 | API | 国内电商、客服 |

#### 2.4.2 Inworld AI Realtime API 关键能力（2025）

- **220+ LLM 路由**：GPT-4o / Claude 3.7 / Gemini 2.0 / 国内模型一键切换
- **OpenAI Realtime 兼容**：WebSocket + audio stream，Web 端集成 < 100 行
- **情感 / 动作 / TTS 多模态输出**：自定义 emotion 标签 + speech prosody
- **角色一致性**：Character Brain + Long-term Memory，跨会话稳定
- **⚠️ 行业警示**：**Replica Studios**（曾用于 AAA NPC 配音）已于 **2025 年正式关闭**，游戏工作室应迁移到 ElevenLabs / Inworld TTS / Resemble AI。

---

## 第三部分：AI 影视/动画/视频制作

### 3.1 完整制作流程图

```
┌──────────────────────────────────────────────────────────────┐
│  Pre-Production（前期）                                       │
│                                                              │
│  剧本 (Script) ── GPT-4o/Claude ─→ 镜头列表 (Shot List)      │
│                                          │                   │
│                                          ↓                   │
│  概念图 (Concept Art) ← Midjourney/FLUX/CogView              │
│                                          │                   │
│                                          ↓                   │
│  分镜 (Storyboard) ← ComfyUI + ControlNet + AnimateDiff      │
│                                          │                   │
│                                          ↓                   │
│  Previs (预演) ← Runway Gen-4.5 / Kling / Vidu              │
└──────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────┐
│  Production（拍摄 / 合成）                                     │
│                                                              │
│  ① 真人实拍 ─→ AI 后期补帧 (Topaz/DAIN/RIFE)                  │
│  ② 数字人 ─→ HeyGen/D-ID/Synthesia/MetaHuman+A2F              │
│  ③ 动作迁移 ─→ Runway Act-Two / Viggle Motion Control          │
│  ④ AI 生成视频 ─→ Kling/Vidu/PixVerse/DomoAI                  │
│                                                              │
│  统一调色 ─→ DaVinci Resolve (AI Magic Mask, Voice Isolation) │
└──────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────┐
│  Post-Production（后期）                                       │
│                                                              │
│  配乐 ─→ Suno / Udio / ElevenLabs Music                      │
│  对白 ─→ ElevenLabs / Inworld TTS / 剪映 AI 配音              │
│  剪辑 ─→ CapCut/剪映 AI 粗剪 → 人工精剪                       │
│  特效 ─→ ComfyUI + SVD/AnimateDiff/After Effects             │
│  输出 ─→ 多平台适配（抖音 9:16 / B 站 16:9 / 影院 2.39:1）       │
└──────────────────────────────────────────────────────────────┘
```

### 3.2 动画 AI 工具对比表

| 工具 | 类型 | 价格（2026-06） | 时长上限 | 分辨率 | 控制方式 | 风格 | 关键能力 |
|------|------|----------------|---------|--------|---------|------|---------|
| **Runway Gen-4.5** | SaaS + API | Standard $12/月 625 credits / Pro $28/月 / Unlimited $76/月 | 10 秒 | 1080p | 文生、图生、首尾帧 | 通用电影级 | 1247 Elo（Artificial Analysis，2025-12-01 冠军），角色一致性 + 运动质量双优 |
| **Runway Aleph 2.0** | SaaS | 单独计费 | 任意（视频输入） | 4K | 视频到视频 | 通用 | 视频编辑、对象擦除、镜头替换 |
| **Pika 2.2** | SaaS | Free / Pro $10/月 / Creator $35/月 | 10 秒 | 1080p | 文生、图生 | 通用 | Pikaffects（爆炸/融化）、Pikaframes |
| **Vidu（中国·生数）** | API + Web | Free 10s / Pro ¥68/月 | 16 秒 | 1080p | 文生、图生、参考图 | 通用 | 角色一致性 V2、多镜头 |
| **Kling 3.0（快手）** | API + Web | Free / Pro ¥66/月 / Ultra ¥199/月 | 10 秒 | 1080p | 文生、图生、首尾帧、运镜 | 通用 | 物理仿真强、人物动作自然 |
| **PixVerse V6** | Web | Free / Pro $10/月 | 8 秒 | 1080p | 文生、图生、关键帧 | 通用 | **实时交互世界引擎**（2026-04 推出），1080P 流式生成 |
| **Viggle AI** | SaaS | Free 5/day / Pro $7.99 / Live $15.99 / Max $63.99 | 10 秒 | 1080p | Mix / Multi-Track / Motion Control / Real-Time Swap / Image Gen | 角色动画 | 内置 Seedance 2.0 Fast / Kling 3.0 / Veo 3.1 / Wan 2.7 / GPT Image 2 / Nano Banana Pro |
| **DomoAI** | Web | Free / Pro $9.99/月 / Enterprise | 10 秒 | 720p | 图生视频、风格转换 | 动漫、真人 | 角色动作迁移、风格化重绘 |
| **Pika / Stable Video Diffusion** | 开源 / SaaS | SVD-XT 1.0 开源 / Pika SaaS | 4 秒 | 1024×576 | 图生 | 通用 | Stable Diffusion 团队原版 |
| **AnimateDiff (开源)** | 本地 | 免费（GPU） | 任意 | 任意 | SD + MotionLoRA | 通用 | ComfyUI 标配 |
| **Animaker / Vyond / Powtoon** | SaaS | $10-75/月 | 1-10 分钟 | 1080p | 模板驱动 | 商业动画 | 企业 MG 动画 |
| **Steve AI / Toonly** | SaaS | $20-60/月 | 1-5 分钟 | 720p | 脚本 → 视频 | 商业动画 | 快速企业宣传 |
| **Sora 2 (OpenAI)** | API | $0.10/秒 720p / $0.30/秒 1080p | 20 秒 | 1080p | 文生、图生、视频生 | 通用电影级 | **同步音频生成**（2025-12 关键突破） |
| **Veo 3.1 (Google)** | API | $0.40/秒 | 8 秒 | 4K | 文生、图生 | 通用电影级 | 同步音频、长 prompt |
| **Wan 2.7（阿里）** | API + 开源 | 阶梯计费 | 10 秒 | 1080p | 文生、图生 | 通用 | 通义系列、SOTA 中文 |
| **HunyuanVideo（腾讯）** | 开源 + API | 免费（本地）/ 阶梯 | 5-10 秒 | 720p-1080p | 文生、图生 | 通用 | 130 亿参数、ICLR 2025 |
| **Seedance 2.0 / 2.0 Fast** | API（字节·即梦） | 阶梯 | 10 秒 | 1080p | 文生、图生 | 通用 | 2025-12 上线，Fast 版 4 秒出片 |

#### 3.2.1 视频模型选型决策（2026-06）

```
追求电影质感 / 角色一致性？
  ├─ 是 → Runway Gen-4.5（首选）/ Sora 2（带音频）
  └─ 否 → 中文场景？
       ├─ 是 → Kling 3.0 / Vidu / Wan 2.7 / 即梦 Seedance
       └─ 否 → 实时交互？
            ├─ 是 → PixVerse 实时世界引擎
            └─ 否 → 长视频？
                 ├─ 是 → Runway / Kling 多段拼接
                 └─ 否 → 单段 ≥10s → Veo 3.1 / Sora 2
```

### 3.3 游戏虚拟制作（UE5 MetaHuman + Mass Entity）

#### 3.3.1 UE5 MetaHuman 5.7 关键能力

- **MetaHuman Animator（2025）**：从单张照片或 30 秒视频生成完整 MetaHuman 角色（含动作）
- **MetaHair 2.0**：基于 Strand-based Hair，新增发丝物理
- **Substrate 材质**：基于图层的程序化材质系统（2025-11）
- **Audio2Face LiveLink**：实时驱动 MetaHuman 面部表情与口型
- **Convai / Inworld 集成**：UE5 插件直接接入 LLM NPC

#### 3.3.2 Mass Entity 大规模虚拟人群

| 能力 | 数值 | 备注 |
|------|------|------|
| 同屏 NPC | 10 万+ | RTX 4090 + Mass Entity |
| StateTree AI | 100+ | 行为树并行 |
| SmartObject | 64/场景 | 智能对象交互 |
| EQS 查询 | <1ms | 环境查询 |
| Niagara 集成 | 实时粒子 | 视觉密度增强 |

#### 3.3.3 典型游戏虚拟制片工作流

```
剧本 → LLM 生成 NPC 对话树（Inworld）
    ↓
UE5 关卡 + MetaHuman 角色
    ↓
Mass Entity + StateTree 群组行为
    ↓
Audio2Face 实时驱动主角口型
    ↓
Niagara 大气 / 粒子 / 光照
    ↓
实时 PIE / nDisplay LED Wall 投屏
```

---

## 第四部分：核心生成算法

### 4.1 关键算法对比与原理

| 算法 | 论文 / 来源 | 发表 | 核心原理 | 显存 | 速度 | 适用场景 |
|------|------------|------|---------|------|------|---------|
| **DiT (Diffusion Transformer)** | Peebles & Xie 2212.09748 | NeurIPS 2023 | 用 Transformer 替换 UNet 的扩散去噪网络，scale law 友好 | 高（16GB+） | 中 | SD 3/3.5、FLUX.1、Sora、Wan |
| **Wan (Rectified Flow)** | Esser 2403.03206 (Stable Diffusion 3) + Black Forest Labs FLUX | 2024 | Rectified Flow 直线轨迹，12B 参数 | 高（24GB） | 中 | FLUX.1、Sora |
| **3D Gaussian Splatting** | Kerbl SIGGRAPH 2023 (2308.04079) | SIGGRAPH 2023 | 用各向异性 3D 高斯重建场景，实时渲染 | 8GB | 实时（>100fps） | 数字资产、虚拟拍摄 |
| **4D Gaussian** | Wu SIGGRAPH 2024 (2403.11148) | SIGGRAPH 2024 | 3DGS + 时间维度 | 12GB | 实时 | 动态场景重建 |
| **NeRF** | Mildenhall ECCV 2020 | ECCV 2020 | 神经辐射场，体渲染 | 8GB | 慢（10s/帧） | 新视角合成（已被 3DGS 取代主流） |
| **ControlNet** | Zhang 2302.05543 | ICCV 2023 Best Paper | 在 UNet 加入零卷积分支控制（边缘/深度/Pose） | +2GB | 与主模型一致 | 风格 / 构图 / 镜头控制 |
| **IP-Adapter** | Ye 2308.06721 | 2023 | 解耦的 cross-attention 图像特征注入 | +4GB | 与主模型一致 | 角色 / 风格参考 |
| **IP-Adapter FaceID** | Tencent 2401.05061 | 2024 | 面部 ID 特征 + ArcFace 嵌入 | +4GB | 与主模型一致 | 角色面部一致性 |
| **AnimateDiff** | Guo 2307.04725 | ICLR 2024 | 域适配 LoRA 实现时序一致性 | +6GB | 8 帧 / 4 秒 | 通用视频化 |
| **MotionCtrl** | Wang SIGGRAPH 2024 (2312.03641) | SIGGRAPH 2024 | 复合轨迹控制（相机 + 物体） | +8GB | 16 帧 / 2 秒 | 精确镜头运动 |
| **CameraCtrl** | He 2404.02101 | CVPR 2024 | 相机姿态序列控制视频生成 | +8GB | 16 帧 / 2 秒 | 镜头运动（轻量） |
| **Direct-a-Video** | Yang 2403.01779 | ICLR 2025 | 直接回归运动场，无需相机参数 | +8GB | 16 帧 / 2 秒 | 自然运动 |
| **MotionLoRA** | Wei 2402.11502 | 2024 | LoRA 适配特定相机运动（Pan/Zoom/Roll） | +0.5GB | 通用 | AnimateDiff 镜头插件 |
| **AnimateAnything** | Zhao 2404.02120 | 2024 | 精细时空控制视频扩散 | +10GB | 16 帧 / 2 秒 | 物体级控制 |
| **Stable Video 4D** | Stability AI 2403.09887 | 2024 | 单视频 → 多视角 4D 资产 | +16GB | 离线 | 数字资产 |
| **Sparc3D** | Stability AI 2505.07241 | 2025 | 稀疏 3D 重建（3DGS 升级版） | +12GB | 离线 | 高质量数字资产 |
| **SV3D / SV4D** | Stability AI | 2024-2025 | 单图 → 多视角 → 4D 视频 | +16GB | 离线 | 商品 / 角色 4D 重建 |

#### 4.1.1 算法演进图

```
2014 GAN ─→ 2020 DALL-E 1 / VQ-VAE
              ↓
2022 Stable Diffusion (Latent Diffusion, UNet)
              ↓
2023 ControlNet (零卷积 + 边缘/深度/Pose)
              ↓
2023 IP-Adapter (图像解耦 cross-attn)
              ↓
2023-2024 AnimateDiff / MotionCtrl / CameraCtrl / MotionLoRA
              ↓
2024 DiT (Sora / SD 3 / FLUX)
              ↓
2024-2025 3DGS / 4DGS / NeRF (数字资产)
              ↓
2025-2026 Sora 2 / Gen-4.5 / Wan 2.7 / Veo 3.1（电影级）
```

#### 4.1.2 算法选型决策

```
需要控制构图？
  ├─ 是 → ControlNet（Canny/Depth/Pose）
  └─ 否 → 需要角色参考？
       ├─ 是 → IP-Adapter / IP-Adapter FaceID
       └─ 否 → 需要视频化？
            ├─ 是 → AnimateDiff + MotionLoRA（简单镜头）
            │         或 MotionCtrl / CameraCtrl（精确镜头）
            └─ 否 → FLUX.1 / SD 3.5（静态高质量）
```

### 4.2 ComfyUI 工程部署

#### 4.2.1 安装（Windows）

```powershell
# 1) 克隆
git clone https://github.com/comfyanonymous/ComfyUI.git
cd ComfyUI

# 2) 创建虚拟环境
python -m venv venv
.\venv\Scripts\Activate.ps1

# 3) 安装依赖
pip install -r requirements.txt

# 4) 安装 ComfyUI Manager（必备）
python -m pip install comfy-cli
comfy install
comfy manager install
```

#### 4.2.2 推荐工作流模板（2026-06）

| 工作流 | 节点链 | 输出 | 文件名 |
|--------|-------|------|--------|
| 文本 → 高质量图 | CLIPTextEncode → KSampler → VAEDecode → SaveImage | PNG | `txt2img_flux.json` |
| 图 + 参考 → 一致性 | LoadImage + IPAdapter → KSampler → VAEDecode | PNG | `ip_adapter_flux.json` |
| 图 + ControlNet → 控制 | LoadImage + ControlNet Apply → KSampler → VAEDecode | PNG | `controlnet_flux.json` |
| 图 + AnimateDiff → 视频 | LoadImage + AnimateDiff + MotionLoRA → KSampler → VAEDecode → VideoCombine | MP4 | `img2vid_animatediff.json` |
| 图 + MotionCtrl → 精确运镜 | LoadImage + MotionCtrl → KSampler → VAEDecode → VideoCombine | MP4 | `motionctrl.json` |
| 文 → 视频（DiT） | CLIPTextEncode + Wan/SVD → KSampler → VideoCombine | MP4 | `wan_t2v.json` |

#### 4.2.3 FLUX.1 + AnimateDiff 镜头运动节点示例

```jsonc
{
  "3": {  // KSampler
    "inputs": {
      "seed": 42,
      "steps": 30,
      "cfg": 7.0,
      "sampler_name": "euler",
      "scheduler": "normal",
      "denoise": 1.0,
      "model": ["10", 0]
    }
  },
  "10": {  // LoadCheckpoint
    "inputs": { "ckpt_name": "flux1-dev-fp8.safetensors" }
  },
  "20": {  // AnimateDiff Loader
    "inputs": { "model_name": "mm_sd15_v3-720p.ckpt", "beta_schedule": "autoselect" }
  },
  "21": {  // MotionLoRA Loader
    "inputs": {
      "motion_lora": "v2_lora_PanLeft.ckpt",
      "strength": 0.8
    }
  },
  "30": {  // LoadImage（参考图）
    "inputs": { "image": "character_ref.png" }
  },
  "31": {  // IPAdapter Apply
    "inputs": {
      "weight": 0.85,
      "weight_type": "linear",
      "start_at": 0.0,
      "end_at": 1.0,
      "image": ["30", 0]
    }
  },
  "100": {  // VideoCombine
    "inputs": {
      "frame_rate": 16,
      "loop_count": 0,
      "format": "video/h264-mp4",
      "save_output": true
    }
  }
}
```

#### 4.2.4 性能优化（2026 主流 GPU 配比）

| GPU | 推荐模型 | 最大并发 | 备注 |
|-----|---------|---------|------|
| RTX 4090 (24GB) | FLUX.1 dev Q8 / Wan 2.1 14B | 1 | 性价比首选 |
| RTX 5090 (32GB) | FLUX.1 dev FP16 + IP-Adapter + AnimateDiff | 2 | 2025 新旗舰 |
| A100 (80GB) | FLUX.1 Pro + 多 ControlNet | 4 | 云端首选 |
| H100 (80GB) | Sora-class / HunyuanVideo 130B | 8 | 大模型训练/推理 |
| Apple M3 Ultra (192GB) | FLUX.1 dev FP16 + ControlNet | 2 | Mac Studio，本地隐私场景 |

---

## 第五部分：实战工作流模板

### 5.1 短视频工作流（抖音 / TikTok 30-60s）

```
【Day 1】脚本 + 分镜
  09:00  写脚本（GPT-4o 生成 5 版，选 1）
  10:00  GPT-4o 生成 Shot List（CSV：镜号 / 时长 / 画面 / 配音）
  11:00  Midjourney V7 生成 10 张概念图（--sref 风格统一）
  14:00  ComfyUI 生成高分辨率定稿（FLUX.1 dev + IP-Adapter）

【Day 2】视频生成
  09:00  选定 5-8 镜头
  10:00  Viggle / Kling 3.0 / Runway Gen-4.5 生成视频
  14:00  PixVerse V6 实时世界引擎补充关键镜头
  16:00  批量生成 + 筛选

【Day 3】后期 + 发布
  09:00  配乐（Suno / 剪映 AI）
  10:00  对白（ElevenLabs / 剪映 AI 配音）
  11:00  剪辑（剪映 AI 粗剪 → 人工精剪）
  14:00  字幕 + 封面（Canva / 即梦）
  15:00  多平台发布（抖音 9:16 / B 站 16:9 / 视频号）
```

**预算参考（个人创作者）：**
- Midjourney Pro：$30/月
- Runway Pro：$28/月
- Kling Pro：¥66/月
- ElevenLabs Starter：$5/月
- **总计：~ ¥380/月**

### 5.2 长视频工作流（电影级 3-10min）

```
【Pre-Production 2 周】
  W1  剧本锁定 + 世界观 Bible + 角色设定集
  W2  完整分镜（200+ 镜头）+ 预演（Gen-4.5 / Sora 2）

【Production 4 周】
  W3  数字人录制（HeyGen Studio Avatar + Synthesia）
  W4  动作拍摄（Move.ai / DeepMotion 或真实 MoCap）
  W5  AI 视频生成（Kling / Vidu / Wan 拼接）
  W6  真人实拍补帧（Sony FX3 + Topaz/DAIN）

【Post-Production 2 周】
  W7  DaVinci Resolve 调色 + Fairlight 混音
  W8  ComfyUI VFX 修复 + 多平台输出（DCP / 流媒体）

【关键工具链】
  剧本：Final Draft 13 + GPT-4o
  分镜：Toon Boom Storyboard Pro 22 + ComfyUI
  预演：Runway Gen-4.5 / Sora 2
  拍摄：Sony FX3 / Blackmagic URSA Mini
  MoCap：Xsens MVN Awinda
  后期：DaVinci Resolve Studio 19 + After Effects 2026
  AI 工具：HeyGen / D-ID / ElevenLabs / ElevenLabs Music / Suno
```

**预算参考（小型工作室）：**
- 软件订阅：~$1,200/月（Adobe / DaVinci / Runway / HeyGen / ElevenLabs）
- 云 GPU：~$800/月（ComfyUI Cloud / Replicate）
- 人力：3 人 × 2 个月 = ~¥300,000
- **总计：~ ¥400,000**

### 5.3 动画短片工作流（2-5min）

```
【Week 1】剧本 + 风格 Bible
  风格参考图集（Midjourney --sref 100 张）
  角色三视图（ComfyUI + IP-Adapter FaceID）
  场景概念图（FLUX.1 dev）

【Week 2】分镜 + Animatic
  Storyboarder（开源）+ ComfyUI AnimateDiff 生成粗略镜头
  Adobe Premiere 拼接音频 → 2min animatic

【Week 3-4】关键镜头生产
  ComfyUI 工作流：
    AnimateDiff + MotionLoRA（推/拉/摇/移）
    + IP-Adapter（角色一致）
    + ControlNet（构图锁）
  关键帧逐镜头渲染（每镜头 50-200 帧）

【Week 5】后期
  DaVinci Resolve 调色 + 配乐（Suno）+ 音效（Freesound）
  最终输出（4K + 流媒体版）

【工具链】
  风格：Midjourney V7（--sref + --cref）
  角色：ComfyUI + IP-Adapter FaceID Plus v2
  动画：AnimateDiff + MotionLoRA / CameraCtrl
  镜头：MotionCtrl（精确运镜）
  后期：DaVinci Resolve 19
  配乐：Suno v4 / ElevenLabs Music
```

**预算参考（独立动画师）：**
- 软件：~$200/月（Midjourney + ElevenLabs + Suno）
- GPU：~$200/月（云端）
- **总计：~ ¥3,000/月 + 4 周时间**

### 5.4 数字人直播工作流（7×24h）

```
【架构】

[主播真身] ─实时动作捕捉─→ [UE5 MetaHuman] ─LiveLink─→ [Audio2Face 3D]
                                                       ↓
[脚本 / LLM] ─Inworld AI Realtime─→ [TTS (ElevenLabs)] ─→ [数字人口型]
                                                       ↓
                                                [OBS / 直播推流]
                                                       ↓
                                          [抖音/B站/视频号/YouTube]

【技术栈】
  角色：UE5 MetaHuman + Custom Skin
  口型：NVIDIA Audio2Face 3D NIM（注意：旧版 API 已弃用，需迁移至 audio2face-3d NIM）
  对话：Inworld AI Realtime + GPT-4o Realtime
  TTS：ElevenLabs Turbo v3 / 国内火山引擎 / 魔音工坊
  动作：Move.ai（手机端实时捕捉）/ Xsens MVN（专业级）
  直播：OBS Studio 30 + 多平台推流插件

【运维 Checklist】
  ☐ LLM Token 配额监控（防止超支）
  ☐ 数字人 fallback（断流时切换静态）
  ☐ 内容合规过滤（Inworld + 国内需自建关键词库）
  ☐ 7×24 监控脚本（Prometheus + Grafana）
  ☐ 紧急关停按钮（推流中断）

【预算参考（MVP 单主播）】
  MetaHuman 资产：~$0（UE5 已有）
  A2F NIM：$0（本地部署）/ 或云 $0.06/分钟
  Inworld Pro：$40/月
  ElevenLabs：$22/月
  OBS 多平台插件：免费
  **总计：~ ¥600/月（含本地 GPU 折旧）**
```

---

## 第六部分：参考文献

### 6.1 学术论文（2022-2026）

| 论文 | arXiv | 发表 | 引用 |
|------|-------|------|------|
| LivePortrait: Efficient Portrait Animation with Stitching and Retargeting Control | 2407.03168 | 2024-07（快手） | https://liveportrait.github.io |
| MuseTalk: Real-Time High-Fidelity Lip Sync via Latent Space Inpainting | 2410.10122 | 2024-10（腾讯音乐） | https://github.com/TMElyralab/MuseTalk |
| SadTalker: Learning Realistic 3D Motion Coefficients for Stylized Audio Driven Single Image Talking Face Animation | 2211.12194 | 2022-11（西交大） | https://github.com/OpenTalker/SadTalker |
| Wav2Lip: A General Lip Synchronization Method | — | 2020（IIIT Hyderabad） | https://github.com/Rudrabha/Wav2Lip |
| OmniHuman-1: Rethinking the Scalability of Diffusion-based Audio-driven Human Animation | 2502.01061 | 2025-02（字节） | 闭源 |
| EMO: Emote Portrait Alive — Generating Expressive Portrait Videos with Audio2Video Diffusion Bridge | 2402.17485 | 2024-02（阿里） | https://humanaigc.github.io/emote-portrait-alive/ |
| Hallo: Hierarchical Audio-Driven Visual Synthesis for Portrait Image Animation | 2406.08801 | 2024-06（复旦） | https://github.com/fudan-generative-vision/hallo |
| GeneFace / GeneFace++ | 2301.13307 / 2305.07014 | 2023（字节） | https://github.com/yerfor/GeneFace |
| ER-NeRF / RAD-NeRF | — | 2022-2023（浙大） | https://github.com/liyanjie-code/RAD-NeRF |
| 3D Gaussian Splatting for Real-Time Radiance Field Rendering | 2308.04079 | SIGGRAPH 2023 | https://github.com/graphdeco-inria/gaussian-splatting |
| 4D Gaussian: A Generative Animation Pipeline for Dynamic Scene Rendering | 2403.11148 | SIGGRAPH 2024 | https://guan-yx.github.io/4dgs/ |
| Adding Conditional Control to Text-to-Image Diffusion Models (ControlNet) | 2302.05543 | ICCV 2023 Best Paper | https://github.com/lllyasviel/ControlNet |
| IP-Adapter: Text Compatible Image Prompt Adapter for Text-to-Image Diffusion Models | 2308.06721 | 2023 | https://github.com/tencent-ailab/IP-Adapter |
| IP-Adapter FaceID | 2401.05061 | 2024（腾讯） | https://huggingface.co/h94/IP-Adapter-FaceID |
| Animate Your Personal Text-to-Image Diffusion Model without Particular Tuning | 2307.04725 | ICLR 2024 | https://github.com/guoyww/AnimateDiff |
| MotionCtrl: A Unified and Flexible Motion Controller for Video Generation | 2312.03641 | SIGGRAPH 2024 | https://github.com/TencentARC/MotionCtrl |
| CameraCtrl: Enabling Camera Control for Text-to-Video Generation | 2404.02101 | CVPR 2024 | https://github.com/hehao13/CameraCtrl |
| Direct-a-Video: Customized Video Generation with User-Defined Motion | 2403.01779 | ICLR 2025 | https://github.com/YBYBZhang/Direct-a-Video |
| MotionLoRA: Motion-Disentangled LoRA for Personalized Video Generation | 2402.11502 | 2024 | https://github.com/WuTao28/MotionLoRA |
| AnimateAnything: Fine Grained Open Domain Image Animation with Motion Guidance | 2404.02120 | 2024 | https://github.com/yeungchenwa/AnimateAnything |
| Stable Video 3D: Lifelike Dynamic World Modeling with Multi-View Diffusion | 2403.09887 | 2024（Stability AI） | https://github.com/Stability-AI/generative-models |
| Sparc3D: Sparse 3D Reconstruction | 2505.07241 | 2025（Stability AI） | https://github.com/Stability-AI/sparc3d-research |
| Scaling Rectified Flow Transformers for High-Resolution Image Synthesis (FLUX.1) | — | 2024（Black Forest Labs） | https://github.com/black-forest-labs/flux |
| Scalable Diffusion Models with Transformers (DiT) | 2212.09748 | NeurIPS 2023 | https://github.com/facebookresearch/DiT |
| Autoregressive-to-Diffusion Vision Language Models (A2D) | — | 2025-09（Runway） | https://runwayml.com/research/autoregressive-to-diffusion-vlms |
| StochasticSplats: Stochastic Rasterization for Sorting-Free 3D Gaussian Splatting | 2503.24366 | 2025-03（Runway） | https://arxiv.org/abs/2503.24366 |

### 6.2 官方文档与平台（2026-06 验证）

| 平台 | URL | 验证时间 |
|------|-----|---------|
| Midjourney | https://midjourney.com | 2026-06-25 |
| FLUX.1（Black Forest Labs） | https://replicate.com/black-forest-labs/flux-dev | 2026-06-25 |
| ComfyUI | https://github.com/comfyanonymous/ComfyUI | 2026-06-25 |
| ControlNet | https://github.com/lllyasviel/ControlNet | 2026-06-25 |
| AnimateDiff | https://github.com/guoyww/AnimateDiff | 2026-06-25 |
| MotionCtrl | https://github.com/TencentARC/MotionCtrl | 2026-06-25 |
| LivePortrait | https://liveportrait.github.io | 2026-06-25 |
| MuseTalk | https://github.com/TMElyralab/MuseTalk | 2026-06-25 |
| SadTalker | https://github.com/OpenTalker/SadTalker | 2026-06-25 |
| Wav2Lip | https://github.com/Rudrabha/Wav2Lip | 2026-06-25 |
| Storyboarder | https://wonderunit.com/storyboarder | 2026-06-25 |
| Storyboard That | https://storyboardthat.com | 2026-06-25 |
| Boords | https://boords.com | 2026-06-25 |
| Toon Boom Storyboard Pro | https://toonboom.com/storyboard-pro | 2026-06-25 |
| Plotagon | https://plotagon.com | 2026-06-25 |
| D-ID | https://d-id.com | 2026-06-25 |
| Synthesia | https://synthesia.io | 2026-06-25 |
| Runway Gen-4.5 | https://runwayml.com/research/introducing-runway-gen-4.5 | 2026-06-25 |
| Runway Act-Two | https://runwayml.com/research/introducing-act-one | 2026-06-25 |
| Runway Research | https://runwayml.com/research | 2026-06-25 |
| DomoAI | https://domoai.app | 2026-06-25 |
| PixVerse | https://pixverse.ai | 2026-06-25 |
| Viggle AI | https://viggle.ai/pricing | 2026-06-25 |
| Kling AI（快手可灵） | https://klingai.com | 2026-06-25 |
| Vidu（生数） | https://vidu.studio | 2026-06-25 |
| SiliconFlow（硅基流动） | https://siliconflow.cn | 2026-06-25 |
| Move.ai | https://move.ai | 2026-06-25 |
| DeepMotion | https://deepmotion.com | 2026-06-25 |
| ElevenLabs | https://elevenlabs.io | 2026-06-25 |
| Inworld AI | https://inworld.ai | 2026-06-25 |
| Replica Studios | https://replicastudios.com（**2025 已关闭**） | 2026-06-25 |
| NVIDIA Audio2Face 3D NIM | https://build.nvidia.com（搜索 audio2face-3d NIM，**原 API 已弃用**） | 2026-06-25 |

### 6.3 行业基准与数据来源

| 来源 | URL | 用途 |
|------|-----|------|
| Artificial Analysis | https://artificialanalysis.ai | LLM/视频模型 Elo 排名 |
| Hugging Face Trending | https://huggingface.co/models?sort=trending | 开源模型热度 |
| ComfyUI Workflows | https://comfyworkflows.com | 工作流模板 |
| CivitAI | https://civitai.com | LoRA / Checkpoint 社区 |
| OpenArt | https://openart.ai/workflows | 工作流 + 案例 |
| Paper With Code | https://paperswithcode.com | 学术复现 |

### 6.4 关键事实速查（2026-06 时点）

| 事实 | 数据 | 来源 |
|------|------|------|
| Runway Gen-4.5 Elo（Artificial Analysis） | 1247（冠军，截至 2025-12-01） | runwayml.com/research |
| Viggle Live Plan | $15.99/月（含 200 credits，Kling 3.0 + Veo 3.1） | viggle.ai/pricing |
| Viggle Max Plan | $63.99/月（800 credits，10 并发） | viggle.ai/pricing |
| MuseTalk v1.5 速度 | 30fps+ on V100 | github.com/TMElyralab/MuseTalk |
| LivePortrait 速度 | 12.8ms/帧 on RTX 4090 | liveportrait.github.io |
| Replica Studios | **2025 年正式关闭**，迁移至 ElevenLabs / Inworld / Resemble AI | replicastudios.com |
| NVIDIA Audio2Face-3D | **旧 API 已弃用**，必须用 **audio2face-3d NIM** | build.nvidia.com |
| Inworld AI | 220+ LLM 路由、OpenAI Realtime 兼容 | inworld.ai |
| FLUX.1 参数规模 | 12B Rectified Flow Transformer | replicate.com/black-forest-labs/flux-dev |
| PixVerse 实时世界引擎 | 1080P 流式生成，2026-04 上线 | pixverse.ai |

---

## 附录 A：本仓库相关文档索引

| 编号 | 文档 | 用途 |
|------|------|------|
| `01-AI-Development-Playbook.md` | AI 调度总纲 | 任务路由与角色判定 |
| `02-UE5-Coding-Standards.md` | UE5 编码规范 | C++ / Blueprint 规范 |
| `03-Singleplayer-Lyra-GAS-Rules.md` | Lyra/GAS 规则 | 单机游戏 GAS 实践 |
| `13-File-Placement-Convention.md` | 文件放置约定 | 资产与代码路径 |
| `14-Coding-Standards.md` | 编码规范 | UE5 C++ 详细规范 |
| `18-Validation-Checklist.md` | 验证清单 | 编译/性能/Packaging |

## 附录 B：与 UE5 项目集成建议

> 适用项目：`Project/RTS/`、`Project/CharacterDesignTool/`

1. **MetaHuman + Audio2Face 实时表演** → 替换原 NPC 语音逻辑
2. **ComfyUI 离线批渲染** → 用于 RTS 内部过场动画
3. **Inworld AI Realtime** → 接入 Lyra NPC 对话树
4. **ElevenLabs / 国内 TTS** → 替换 VoiceKit 占位音频
5. **Runway Gen-4.5 / Kling 3.0** → 用于宣传片 / 商店页视频
6. **3D Gaussian Splatting 资产** → 通过 `Sparc3D` / `Stable Video 4D` 离线重建，导入 UE5

---

**文档维护者**：金璃好帮手 (Plan/Implement/Review)
**最近更新**：2026-06-25
**下次复审**：2026-09-25（季度更新）
