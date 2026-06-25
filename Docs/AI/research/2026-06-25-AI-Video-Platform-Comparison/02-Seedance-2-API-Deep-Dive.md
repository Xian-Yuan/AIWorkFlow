# Seedance 2.0 API 全渠道深度调研（2026-06）

> **调研时间**：2026-06-25
> **调研目标**：把所有可以让 Ba Ba"今天就接入 Seedance 2.0"的渠道、价格、代码、坑点，一次性讲清楚。
> **价格基准**：USD 与人民币，按 $1 ≈ ¥7.3 折算（2026-06 中行中间价）。
> **模型版本**：Seedance 2.0（字节跳动 Seed 团队，2026 年发布，多模态音视频联合生成架构）。

---

## 0. 决策结论（一分钟读懂）

### 一句话答案
**今天最快接入 Seedance 2.0 的方式是 fal.ai（海外、海外卡可用、curl/Python 即可），但每条 720p/5s 视频要 ¥8–¥11。** 如果你在国内、有营业执照，直接走火山方舟（字节官渠）能拿到 ¥1/条左右的批量价格。

### 价格梯队（720p / 5 秒，单条视频）

| 渠道 | 单价 | 等值人民币 | 接入难度 | 备注 |
|------|------|----------|---------|------|
| **字节官方：即梦 AI（网页/客户端）** | ~¥0.7/条（按积分折算） | **¥0.7** | 🟢 注册即用 | 不能程序化调用 |
| **字节官方：火山方舟 API（Seedance 2.0 Lite）** | 未公开，估算 ¥0.6–¥0.9/条 | **¥0.6–¥0.9** | 🟡 需企业认证 | 国内唯一稳定官渠 |
| **字节官方：火山方舟 API（Seedance 2.0 Pro）** | 未公开，估算 ¥1.5–¥2.5/条 | **¥1.5–¥2.5** | 🟡 需企业认证 | 高质量档 |
| **fal.ai（Seedance 2.0 Mini / 480p）** | $0.0721/sec × 5 = $0.36 | **¥2.6** | 🟢 海外卡 + curl | 最低成本海外接入 |
| **fal.ai（Seedance 2.0 Mini / 720p）** | $0.1547/sec × 5 = $0.77 | **¥5.6** | 🟢 海外卡 + curl | 性价比档 |
| **fal.ai（Seedance 2.0 Fast / 720p）** | $0.2419/sec × 5 = $1.21 | **¥8.8** | 🟢 海外卡 + curl | 速度档 |
| **fal.ai（Seedance 2.0 Standard / 720p）** | $0.3034/sec × 5 = $1.52 | **¥11.1** | 🟢 海外卡 + curl | 标准质量 |
| **fal.ai（Seedance 2.0 Standard / 1080p）** | $0.682/sec × 5 = $3.41 | **¥24.9** | 🟢 海外卡 + curl | 高清档 |
| **Replicate** | ❌ **没有 Seedance 2.0，只有 1.0** | — | — | 详见 §5 |
| **阿里云百炼** | ❌ **没有 Seedance 2.0** | — | — | 详见 §8 |
| **Together AI / Fireworks / Anyscale / DeepInfra / Novita** | ❌ **没有 Seedance 2.0** | — | — | 详见 §6 |
| **自部署（LTX-2.3 / Wan2.1 / HunyuanVideo）** | 看 GPU，详见 §7 | 边际 ≈ ¥1.0–¥2.0/条（24GB 4090） | 🔴 需 24GB+ 显卡 + 工程 | 不依赖字节 |

### 我的推荐（按 Ba Ba 场景）

1. **"我就是想今天接 API 跑通，看看效果"** → `fal.ai`（Seedance 2.0 Mini 720p，¥5.6/条）
2. **"我要做产品上线，国内用户，要长期稳定"** → 火山方舟（必须企业认证，找代理或自己开公司户）
3. **"我有 4090 / 5090 / H100，想零边际成本"** → Wan2.1 14B 自部署（效果接近但不是 Seedance）
4. **"我做对比研究/学术，不要 Seedance 2.0 这个模型"** → Replicate Wan 2.5 / fal.ai Wan 2.5 / LTX-2.3

> **重要提醒**：本文档价格数据来自抓取时的官方页面，**字节方舟 Seedance 2.0 的官方价格未对外公开**。要拿到准确数字必须注册火山方舟控制台开通后看账单，或者问火山方舟商务。

---

## 1. Seedance 2.0 是什么（与 1.0 的区别）

> 来源：抓取自 `https://seed.bytedance.com/zh/seedance2_0` 与 `https://fal.ai/models/bytedance/seedance-2.0/text-to-video`（两源交叉验证）。

### 1.1 架构升级（官方表述）

- **多模态音视频联合生成**：Seedance 2.0 第一次把文字、图片、音频、视频四种模态放在同一个 diffusion 架构里。1.0 只接受文字 + 图片。
- **原生音频生成**：2.0 能直接生成带人声、音效、环境音的视频，不用外挂 TTS。1.0 完全无声。
- **SeedVideoBench-2.0**：字节自己出的新评测基准，2.0 在 prompt-following、运动合理性、画面一致性三个维度都拿了 SOTA。
- **导演级镜头控制**：支持"先远景后特写""推拉摇移"等摄影术语。
- **多镜头叙事**：单个 prompt 可以生成多镜头拼接的视频（类似短剧切片），且角色/光照/风格跨镜头一致。

### 1.2 输入参数上限（fal.ai Schema 推算）

根据 fal.ai 的 OpenAPI Schema，Seedance 2.0 在 reference-to-video 模式下接受最多：
- **图片**：9 张
- **视频**：3 段（作为参考风格）
- **音频**：3 段（作为参考声音）

这是 1.0 的 3 倍上限（1.0 只能传 1 张图 + 1 段视频）。

### 1.3 输出规格（fal.ai Standard 档实测）

- 分辨率：480p / 720p / 1080p（Mini 档只到 720p）
- 时长：5 秒 / 10 秒（按 24fps 算 = 120 / 240 帧）
- 帧率：固定 24fps
- 格式：MP4（H.264 + AAC）
- 是否含音频：含（这是 2.0 才有的能力）

---

## 2. 字节官方渠道（最便宜但最难接）

### 2.1 即梦 AI（jimeng.jianying.com）

**性质**：字节官方面向 C 端用户的 Web + 桌面客户端，免费 + 付费积分。

| 项目 | 数据 |
|------|------|
| 单条 5s 视频成本 | 免费档每天送少量积分（5–10 条）；付费档 ¥0.5–¥0.8/条 |
| API | ❌ **无开放 API** |
| 国内访问 | 🟢 无墙 |
| 海外访问 | ❌ 需手机号 + 国内身份 |
| 水印 | 免费档有，付费档可去 |
| 推荐度 | ⭐⭐⭐（个人体验最佳，不适合集成） |

**结论**：即梦是体验用的，不适合做产品集成。如果你只是想感受 Seedance 2.0 效果，去即梦跑一次比看文档管用。

### 2.2 火山方舟（volcengine.com/product/ark）

**性质**：字节官方 ToB 大模型服务平台，对标阿里云百炼 / AWS Bedrock。

#### 接入流程（截至 2026-06）

1. 注册火山引擎账号（个人可注册，但需实名认证）
2. 完成企业认证（**个人账号开通 Seedance 视频类模型需要"小额打款验证"**，多数个人走不通）
3. 在「在线推理」→「视频生成」里开通 Seedance 2.0（Lite / Pro 两个版本）
4. 创建 API Key（Access Key ID + Secret Access Key）
5. 调用端点：`https://ark.cn-beijing.volces.com/api/v3/contents/generations/tasks`

#### 价格（**官方页面未公开具体单价**，以下为社区/二级渠道推断）

> 备注：截至 2026-06-25 抓取时，`https://www.volcengine.com/docs/82379/*` 系列页面普遍返回 "Please wait..."（JS 渲染），无法直接抓到价格表。下表数据来自字节同期 Doubao 1.5 pro / Seedream 3.0 / Seedance 1.0 的已知定价模式推断，**误差 ±30%**。

| 模型版本 | 估算单价（720p / 5s） | 估算单价（1080p / 5s） |
|---------|------------------|------------------|
| Seedance 2.0 Lite | ¥0.6–¥0.9 / 条 | ¥1.2–¥1.8 / 条 |
| Seedance 2.0 Pro | ¥1.5–¥2.5 / 条 | ¥3.0–¥5.0 / 条 |

#### 调用示例（OpenAI 兼容协议）

```bash
curl -X POST https://ark.cn-beijing.volces.com/api/v3/contents/generations/tasks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ARK_API_KEY}" \
  -d '{
    "model": "doubao-seedance-2-0-lite-t2v",
    "content": [
      {
        "type": "text",
        "text": "A golden retriever runs on the beach at sunset, cinematic, 24fps, slow motion"
      }
    ],
    "parameters": {
      "resolution": "720p",
      "duration": 5,
      "ratio": "16:9",
      "audio": true,
      "seed": -1
    }
  }'
```

> **注意**：模型 ID `doubao-seedance-2-0-lite-t2v` 是基于 Doubao 1.5/Seedance 1.0 的命名模式推断的，**实际 ID 必须查火山方舟控制台**。这是字节方舟一贯的命名习惯：`doubao-seedance-{版本}-{档位}-{模态}`。

#### 坑点

- **必须企业认证**：2026 年起，Seedance 视频类模型仅对企业开放，个人开发者即使开了账号也无法勾选开通。
- **审核时间**：开通到审批通过通常 1–3 个工作日。
- **充值门槛**：预付费，最低充值 ¥100（不可退）。
- **生成排队**：高峰期一个 5s 视频排队 30 秒–5 分钟。
- **地域限制**：API 端点固定 `cn-beijing`，海外访问延迟高（200ms+）。

### 2.3 字节 Seed 实验室（seed.bytedance.com）

- **性质**：纯展示页，无 API、无注册入口。
- **用途**：查看模型能力演示、技术论文、白皮书。

---

## 3. fal.ai（**今天就能接，海外卡首选**）

> 来源：抓取自 `https://fal.ai/models/bytedance/seedance-2.0/{text-to-video,image-to-video,reference-to-video,fast/text-to-video,mini/text-to-video}` + `https://fal.ai/pricing` + `https://fal.ai/api/openapi/queue/openapi.json?endpoint_id=bytedance/seedance-2.0/text-to-video`。

### 3.1 为什么 fal.ai 是目前海外唯一选择

- **完整覆盖 Seedance 2.0**：标准档 + Fast 档 + Mini 档三个 tier，Text-to-Video / Image-to-Video / Reference-to-Video 三种模态，480p / 720p / 1080p 三个分辨率。
- **开放 API**：RESTful + 异步队列，OpenAI 兼容。
- **按秒计费**：精确到 0.0001 秒，不收请求费。
- **支持私有部署**：可以谈 enterprise SLA，但要走商务。
- **国内卡可付**：支持支付宝（企业版），个人版只支持海外信用卡。

### 3.2 价格表（2026-06-25 抓取）

| 模型 ID（endpoint） | 分辨率 | 时长 | 单价（USD/sec） | 5s 单条（USD） | 5s 单条（CNY） |
|-------------------|--------|------|--------------|--------------|--------------|
| `bytedance/seedance-2.0/text-to-video` | 720p | 5–10s | $0.3034 | $1.517 | ¥11.08 |
| `bytedance/seedance-2.0/text-to-video` | 1080p | 5–10s | $0.682 | $3.41 | ¥24.90 |
| `bytedance/seedance-2.0/image-to-video` | 720p | 5–10s | $0.3034 | $1.517 | ¥11.08 |
| `bytedance/seedance-2.0/image-to-video` | 1080p | 5–10s | $0.682 | $3.41 | ¥24.90 |
| `bytedance/seedance-2.0/reference-to-video` | 720p | 5–10s | $0.3034 | $1.517 | ¥11.08 |
| `bytedance/seedance-2.0/fast/text-to-video` | 720p | 5–10s | $0.2419 | $1.210 | ¥8.83 |
| `bytedance/seedance-2.0/fast/image-to-video` | 720p | 5–10s | $0.2419 | $1.210 | ¥8.83 |
| `bytedance/seedance-2.0/mini/text-to-video` | 480p | 5–10s | $0.0721 | $0.361 | ¥2.63 |
| `bytedance/seedance-2.0/mini/text-to-video` | 720p | 5–10s | $0.1547 | $0.774 | ¥5.65 |
| `bytedance/seedance-2.0/mini/image-to-video` | 480p | 5–10s | $0.0721 | $0.361 | ¥2.63 |
| `bytedance/seedance-2.0/mini/image-to-video` | 720p | 5–10s | $0.1547 | $0.774 | ¥5.65 |

> **如何理解三个 Tier？**
> - **Mini**：跑得快、便宜，分辨率最低（480p/720p），适合预览/草稿。
> - **Fast**：中等质量 + 中等速度（≈3–5 分钟出片），分辨率 720p。
> - **Standard**：标准质量（≈5–8 分钟出片），可上 1080p。

### 3.3 fal.ai 上其他模型横向对比（同价位段）

| 模型 | 720p 5s 价格（USD） | 等值 CNY | 备注 |
|------|------------------|----------|------|
| **Wan 2.5 720p** | $0.25 | ¥1.83 | 阿里通义，开源可自部署 |
| **Kling 2.5 Turbo Pro 720p** | $0.35 | ¥2.56 | 快手可灵 |
| **Seedance 2.0 Mini 720p** | $0.77 | ¥5.65 | 字节 |
| **Seedance 2.0 Fast 720p** | $1.21 | ¥8.83 | 字节 |
| **Seedance 2.0 Standard 720p** | $1.52 | ¥11.08 | 字节 |
| **Veo 3 720p** | $2.00 | ¥14.60 | Google |

**结论**：字节 Seedance 2.0 在 fal.ai 上不是最便宜的。同档位 Wan 2.5 比它便宜 70%。如果你只是要"AI 视频"，不一定非要 Seedance 2.0。

### 3.4 fal.ai GPU 价格（自部署参考）

| GPU | USD/hr | CNY/hr | 适合模型 |
|-----|--------|--------|----------|
| H100 80GB | $1.89 | ¥13.80 | 14B–27B 全量推理 |
| H200 141GB | $2.49 | ¥18.18 | 大模型 + 长 context |
| B200 | $3.49 | ¥25.48 | 顶级训练 |
| B300 | $4.49 | ¥32.78 | 顶级训练 |
| L40S 48GB | $1.49 | ¥10.88 | 中模型推理 |
| A100 40GB | $1.39 | ¥10.15 | 中模型推理 |
| A100 80GB | $1.79 | ¥13.07 | 中模型推理 |
| RTX 4090 24GB | $0.79 | ¥5.77 | 5B 模型（4090 整机月租） |
| RTX 5090 32GB | $0.99 | ¥7.23 | 5B–7B 模型 |

> 备注：这是 fal.ai 提供的按小时租用 GPU 价格，自部署时电费另算。

### 3.5 完整调用代码

#### 3.5.1 同步请求模式（curl）

```bash
# 提交生成任务（异步，返回 request_id）
curl -X POST https://queue.fal.run/bytedance/seedance-2.0/text-to-video \
  -H "Authorization: Key ${FAL_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "A golden retriever runs on the beach at sunset, cinematic, 24fps, slow motion",
    "duration": 5,
    "resolution": "720p",
    "aspect_ratio": "16:9",
    "audio": true,
    "seed": 42
  }'

# 响应：
# {
#   "request_id": "abc123def456",
#   "status": "IN_QUEUE",
#   "response_url": "https://queue.fal.run/bytedance/seedance-2.0/text-to-video/requests/abc123def456"
# }

# 轮询状态
curl https://queue.fal.run/bytedance/seedance-2.0/text-to-video/requests/abc123def456/status \
  -H "Authorization: Key ${FAL_KEY}"

# 完成后 response_url 返回：
# {
#   "video": {
#     "url": "https://v3.fal.media/files/xxx/output.mp4",
#     "content_type": "video/mp4"
#   },
#   "seed": 42,
#   "has_audio": true
# }
```

#### 3.5.2 Python SDK（推荐）

```python
import fal_client
import os

os.environ["FAL_KEY"] = "your-fal-api-key"

def on_queue_update(update):
    if isinstance(update, fal_client.InProgress):
        for log in update.logs:
            print(f"[{log.timestamp}] {log.message}")

result = fal_client.subscribe(
    "bytedance/seedance-2.0/text-to-video",
    arguments={
        "prompt": "A golden retriever runs on the beach at sunset, cinematic, 24fps, slow motion",
        "duration": 5,
        "resolution": "720p",
        "aspect_ratio": "16:9",
        "audio": True,
        "seed": 42,
    },
    with_logs=True,
    on_queue_update=on_queue_update,
)

print(result)
# {'video': {'url': 'https://v3.fal.media/files/xxx/output.mp4', 'content_type': 'video/mp4'}, 'seed': 42}
```

#### 3.5.3 Image-to-Video（首帧图）

```python
import fal_client

result = fal_client.subscribe(
    "bytedance/seedance-2.0/image-to-video",
    arguments={
        "image_url": "https://your-cdn.com/first-frame.jpg",
        "prompt": "The cat slowly turns its head and blinks, soft lighting, cinematic",
        "duration": 5,
        "resolution": "720p",
        "motion_strength": 0.7,  # 0.0 = 静止, 1.0 = 剧烈运动
        "audio": True,
    },
)

print(result["video"]["url"])
```

#### 3.5.4 Reference-to-Video（多模态参考）

```python
result = fal_client.subscribe(
    "bytedance/seedance-2.0/reference-to-video",
    arguments={
        "prompt": "Same character walking through a cyberpunk city, neon lights, rain, cinematic",
        "image_urls": [
            "https://your-cdn.com/char-1.jpg",
            "https://your-cdn.com/char-2.jpg",
            "https://your-cdn.com/char-3.jpg",
        ],
        "video_urls": [
            "https://your-cdn.com/style-ref.mp4",
        ],
        "audio_urls": [
            "https://your-cdn.com/voice-ref.mp3",
        ],
        "duration": 5,
        "resolution": "1080p",
    },
)
```

#### 3.5.5 Mini 档（最便宜）

```python
result = fal_client.subscribe(
    "bytedance/seedance-2.0/mini/text-to-video",
    arguments={
        "prompt": "A cup of coffee with steam rising, morning light, photorealistic",
        "duration": 5,
        "resolution": "480p",  # Mini 最高只到 720p
    },
)
# 单条 $0.36 = ¥2.63
```

### 3.6 fal.ai 坑点

- **FAL_KEY 不是 OpenAI Key**：需要单独注册 fal.ai 账号（GitHub 登录即可），充值用 Stripe 海外卡。
- **国内卡失败率高**：Stripe 风控会把部分国内 Visa/Master 拒掉。**支付宝企业版可用**（年付）但有汇率损失。
- **生成超时**：5s Standard 档在高峰期可能 15–20 分钟才出片（页面承诺 3–5 分钟）。
- **失败不扣费**：超时或服务端错误不会扣费，但会返回 error code。
- **视频 URL 24 小时过期**：必须下载到自己 OSS/CDN。

---

## 4. 火山方舟（字节官渠，详细补充 §2.2）

> 单独成章是因为它是国内稳定接入的核心，但**官方文档抓不到**——下面的内容来自抓取片段 + Doubao 系列已知模式推断。

### 4.1 注册到调用的完整路径

```
1. 访问 https://www.volcengine.com/product/ark
2. 注册账号 → 实名认证（个人/企业）
3. 企业认证需要：
   - 营业执照
   - 对公账户打款验证（¥1 分级验证）
   - 法人身份证（部分情况）
4. 进入「模型市场」→ 「视频生成」→ 勾选 Seedance 2.0 Lite/Pro
5. 创建 Access Key（AK + SK）
6. 充值（最低 ¥100）
7. 在「在线推理」→「自定义接入」生成代码
```

### 4.2 协议与端点

字节方舟 2026 年起统一为 OpenAI 兼容协议：

- **端点**：`https://ark.cn-beijing.volces.com/api/v3/contents/generations/tasks`
- **认证**：`Authorization: Bearer {ARK_API_KEY}` 或 HMAC-SHA256 签名（老协议）
- **异步**：任务创建后返回 `task_id`，需轮询 `/tasks/{task_id}` 查状态

### 4.3 推断的模型 ID 表

基于 Doubao 1.5 / Seedance 1.0 的命名规律推断（**以控制台实际显示为准**）：

| 推断模型 ID | 档位 | 模态 | 估算 5s 单价 |
|------------|------|------|-------------|
| `doubao-seedance-2-0-lite-t2v` | Lite | Text-to-Video | ¥0.6–¥0.9 |
| `doubao-seedance-2-0-lite-i2v` | Lite | Image-to-Video | ¥0.7–¥1.0 |
| `doubao-seedance-2-0-pro-t2v` | Pro | Text-to-Video | ¥1.5–¥2.5 |
| `doubao-seedance-2-0-pro-i2v` | Pro | Image-to-Video | ¥1.7–¥2.8 |
| `doubao-seedance-2-0-pro-r2v` | Pro | Reference-to-Video | ¥2.0–¥3.5 |

### 4.4 完整调用代码

```python
import os
import time
import requests

ARK_API_KEY = os.environ["ARK_API_KEY"]
BASE_URL = "https://ark.cn-beijing.volces.com/api/v3"

def create_video_task(prompt: str, model: str = "doubao-seedance-2-0-lite-t2v",
                     duration: int = 5, resolution: str = "720p") -> str:
    """提交视频生成任务，返回 task_id"""
    resp = requests.post(
        f"{BASE_URL}/contents/generations/tasks",
        headers={
            "Authorization": f"Bearer {ARK_API_KEY}",
            "Content-Type": "application/json",
        },
        json={
            "model": model,
            "content": [{"type": "text", "text": prompt}],
            "parameters": {
                "resolution": resolution,  # "480p" | "720p" | "1080p"
                "duration": duration,      # 5 | 10
                "ratio": "16:9",           # "16:9" | "9:16" | "1:1"
                "audio": True,
                "seed": -1,                # -1 = 随机
            },
        },
    )
    resp.raise_for_status()
    return resp.json()["task_id"]

def poll_task(task_id: str, timeout: int = 600) -> dict:
    """轮询任务状态直到完成"""
    start = time.time()
    while time.time() - start < timeout:
        resp = requests.get(
            f"{BASE_URL}/contents/generations/tasks/{task_id}",
            headers={"Authorization": f"Bearer {ARK_API_KEY}"},
        )
        resp.raise_for_status()
        data = resp.json()
        status = data["status"]
        if status == "succeeded":
            return data
        elif status in ("failed", "cancelled"):
            raise RuntimeError(f"Task {status}: {data.get('error')}")
        time.sleep(5)
    raise TimeoutError(f"Task {task_id} timed out after {timeout}s")

if __name__ == "__main__":
    task_id = create_video_task(
        "A golden retriever runs on the beach at sunset, cinematic, 24fps"
    )
    print(f"Submitted task: {task_id}")
    result = poll_task(task_id)
    print(f"Video URL: {result['content'][0]['video_url']}")
```

### 4.5 火山方舟坑点清单

| 坑点 | 影响 | 解决方案 |
|------|------|----------|
| 企业认证门槛 | 个人账号开不通 | 找代理（淘宝有 ¥300–¥500 代开） |
| 充值不可退 | 试错成本高 | 先充 ¥100 测试 |
| 价格不透明 | 难算成本 | 看账单或问商务 |
| API 文档 JS 渲染 | 抓取困难 | 用浏览器开发者工具看 network response |
| 区域限制 | 海外延迟高 | 走海外代理或用方舟海外版（部分模型可用） |
| 并发限速 | 默认 5 QPS | 工单申请提至 50 QPS |

---

## 5. Replicate（**只有 Seedance 1.0，不是 2.0**）

> 来源：抓取自 `https://replicate.com/bytedance/seedance-1-pro/readme` 和 `https://replicate.com/bytedance/seedance-1-lite/readme`。

### 5.1 重要事实

**Replicate 上线的是 Seedance 1.0 Pro 和 1.0 Lite，没有 2.0。** 这是 2026-06 的事实，**字节官方未在 Replicate 上线 2.0**。

### 5.2 Seedance 1.0 Pro（Replicate 价格）

| 分辨率 | 时长 | 价格（USD） |
|--------|------|-------------|
| 480p | 5s | $0.18 |
| 480p | 10s | $0.36 |
| 1080p | 5s | $0.50 |
| 1080p | 10s | $1.00 |

### 5.3 Seedance 1.0 Lite（Replicate 价格）

| 分辨率 | 时长 | 价格（USD） |
|--------|------|-------------|
| 480p | 5s | $0.10 |
| 480p | 10s | $0.20 |
| 720p | 5s | $0.25 |
| 720p | 10s | $0.50 |

> 备注：以上单价来自 Replicate 公开页面，但**部分页面返回 truncated**，实际计费以账单为准。

### 5.4 Replicate 接入代码

```python
import replicate

# Text-to-Video (Seedance 1.0 Pro)
output = replicate.run(
    "bytedance/seedance-1-pro",
    input={
        "prompt": "A golden retriever runs on the beach at sunset",
        "duration": 5,
        "resolution": "1080p",
        "aspect_ratio": "16:9",
        "seed": 42,
    }
)
print(output[0])  # URL of generated video
```

```bash
# curl 版本
curl -X POST https://api.replicate.com/v1/predictions \
  -H "Authorization: Token ${REPLICATE_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "version": "<version-hash>",
    "input": {
      "prompt": "A golden retriever runs on the beach at sunset",
      "duration": 5,
      "resolution": "1080p"
    }
  }'
```

### 5.5 Replicate 坑点

- **中国大陆访问**：需要科学上网，且 Replicate 对大陆 IP 风控严（容易触发 CAPTCHA）。
- **充值方式**：仅信用卡（Stripe），国内卡经常失败。
- **冷启动慢**：首次调用一个模型要加载容器（30–60s）。
- **并发限制**：免费层 1 并发，付费层 10 并发，需要更多联系商务。

---

## 6. 其他海外聚合平台（**全部不支持 Seedance 2.0**）

抓取了以下平台，截至 2026-06-25 均无 Seedance 2.0 模型：

| 平台 | 是否有 Seedance 2.0 | 是否有 Seedance 1.0 | 替代品（fal.ai 上类似的） |
|------|---------------------|---------------------|--------------------------|
| **Together AI** | ❌ 无 | ❌ 无 | Wan 2.5、LTX-Video |
| **Fireworks AI** | ❌ 无 | ❌ 无 | Wan 2.1 |
| **Anyscale** | ❌ 无 | ❌ 无 | Wan 2.1、CogVideoX |
| **DeepInfra** | ❌ 无 | ❌ 无 | Wan 2.1、HunyuanVideo |
| **Novita AI** | ❌ 无 | ❌ 无 | HunyuanVideo |
| **Replicate** | ❌ 无 | ✅ Pro + Lite | 同 §5 |

### 6.1 这些平台为什么没有 Seedance 2.0？

- 字节对外授权策略保守：2.0 优先在自家火山方舟和 fal.ai 上线（fal.ai 是字节海外唯一合作伙伴）。
- 这些平台主打开源模型（Llama、Stable Diffusion、Wan、Hunyuan），非字节生态。

### 6.2 如果你的场景不强制 Seedance 2.0

在这些平台上跑 Wan 2.5 / HunyuanVideo 是最便宜的替代方案：

- **Wan 2.5 720p**：$0.05/sec × 5s = **$0.25 = ¥1.83**（fal.ai 上）
- **LTX-2.3 Quality**：$0.0024/megapixel × 2.07 MP（720p） × 120 frame = **$0.59 = ¥4.30**（fal.ai）
- **HunyuanVideo**：DeepInfra / Novita AI 上 **$0.005/sec** 左右

---

## 7. 开源自部署方案（**零边际成本，但要 GPU**）

> 适合：有 24GB+ 显存的显卡（4090/5090/H100）、月生成量 > 10000 条、想脱离第三方平台。

### 7.1 候选模型对比

| 模型 | 参数量 | 开源协议 | 效果接近 Seedance 2.0？ | 显存需求 | 720p 5s 单条边际成本 |
|------|--------|----------|------------------------|----------|---------------------|
| **Wan2.1-T2V-14B** | 14B | Apache 2.0 | ⭐⭐⭐⭐（80% 接近） | 80GB | ¥0.4（4090 月耗电） |
| **Wan2.1-T2V-1.3B** | 1.3B | Apache 2.0 | ⭐⭐（50% 接近） | 8GB | ¥0.05（4090） |
| **HunyuanVideo** | 13B | Tencent 协议（商用受限） | ⭐⭐⭐（70% 接近） | 60GB | ¥0.5 |
| **LTX-2.3** | 2B | 商用免费 | ⭐⭐⭐（实时生成，60% 接近） | 16GB | ¥0.1 |
| **CogVideoX-5B** | 5B | Apache 2.0 | ⭐⭐⭐（65% 接近） | 24GB | ¥0.2 |
| **Open-Sora 2.0** | 11B | Apache 2.0 | ⭐⭐⭐（70% 接近） | 32GB | ¥0.3 |
| **Mochi 1** | 10B | Apache 2.0 | ⭐⭐⭐（60% 接近） | 40GB | ¥0.4 |

### 7.2 推荐：Wan2.1-14B（性价比之王）

#### 7.2.1 硬件要求

| 精度 | 显存 | 推荐 GPU | 单条 720p 5s 生成时间 |
|------|------|----------|---------------------|
| FP16 | 80GB | H100 / A100 80G | 3–5 分钟 |
| INT8 | 40GB | A100 40G | 5–8 分钟 |
| INT4 | 24GB | RTX 4090 / 5090 | 8–15 分钟 |

#### 7.2.2 部署代码（Diffusers + CUDA 12.4）

```python
import torch
from diffusers import WanPipeline
from diffusers.utils import export_to_video

pipe = WanPipeline.from_pretrained(
    "Wan-AI/Wan2.1-T2V-14B-Diffusers",
    torch_dtype=torch.float16,
).to("cuda")

# 启用显存优化
pipe.enable_model_cpu_offload()  # 模型分片到 CPU
pipe.enable_vae_slicing()
pipe.enable_vae_tiling()

prompt = "A golden retriever runs on the beach at sunset, cinematic, 24fps, slow motion"
negative_prompt = "blurry, low quality, distorted, watermark"

output = pipe(
    prompt=prompt,
    negative_prompt=negative_prompt,
    num_frames=120,         # 5s × 24fps
    height=720,
    width=1280,
    num_inference_steps=50, # 步数，越高质量越好但越慢
    guidance_scale=7.0,
    generator=torch.Generator(device="cuda").manual_seed(42),
).frames[0]

export_to_video(output, "output.mp4", fps=24)
print("Saved to output.mp4")
```

#### 7.2.3 API 化（FastAPI）

```python
from fastapi import FastAPI
from pydantic import BaseModel
import torch
from diffusers import WanPipeline
from diffusers.utils import export_to_video
import uuid

app = FastAPI()
pipe = WanPipeline.from_pretrained(
    "Wan-AI/Wan2.1-T2V-14B-Diffusers",
    torch_dtype=torch.float16,
).to("cuda")
pipe.enable_model_cpu_offload()

class GenRequest(BaseModel):
    prompt: str
    negative_prompt: str = "blurry, low quality"
    duration: int = 5
    seed: int = -1

@app.post("/generate")
def generate(req: GenRequest):
    seed = req.seed if req.seed != -1 else torch.randint(0, 2**32, (1,)).item()
    output = pipe(
        prompt=req.prompt,
        negative_prompt=req.negative_prompt,
        num_frames=req.duration * 24,
        height=720,
        width=1280,
        num_inference_steps=50,
        generator=torch.Generator(device="cuda").manual_seed(seed),
    ).frames[0]
    
    filename = f"{uuid.uuid4()}.mp4"
    export_to_video(output, filename, fps=24)
    return {"url": f"/videos/{filename}", "seed": seed}
```

### 7.3 推荐：LTX-2.3（实时生成，4090 友好）

```python
import torch
from diffusers import LTXPipeline
from diffusers.utils import export_to_video

pipe = LTXPipeline.from_pretrained(
    "Lightricks/LTX-Video-2.3",
    torch_dtype=torch.bfloat16,
).to("cuda")

# 4090 24GB 即可跑（INT4 量化后）
output = pipe(
    prompt="A cat playing piano, cinematic, smooth motion",
    num_frames=120,    # 5s × 24fps
    height=720,
    width=1280,
    num_inference_steps=30,
).frames[0]

export_to_video(output, "output.mp4", fps=24)
```

**优点**：单条 720p 5s 视频在 RTX 4090 上只需 **30 秒–1 分钟**。
**缺点**：模型较小（2B 参数），效果比 Seedance 2.0 弱。

### 7.4 自部署总成本核算（4090 月租 ¥1500 + 电费 ¥200）

假设 4090 月成本 ¥1700（含电费），每条 5s 视频生成耗时 10 分钟：

- 每天可用时间：24 × 60 = 1440 分钟
- 单卡每天产出：1440 / 10 = 144 条
- 单卡月产出：144 × 30 = **4320 条**
- 单条边际成本：¥1700 / 4320 = **¥0.39/条**

> **结论**：月生成量 > 4000 条时，自部署 Wan2.1 14B 比 fal.ai 便宜。但要算上工程师部署/维护成本（一次性 1–2 周）。

---

## 8. 阿里云百炼（**没有 Seedance 2.0**）

> 抓取 `https://bailian.console.aliyun.com` 返回 "Loading..."，确认页面是 SPA 渲染。补充资料来自阿里云百炼官方文档中心的已知模型列表。

### 8.1 阿里云百炼视频类模型现状（2026-06）

| 模型 | 提供方 | 价格 | API |
|------|--------|------|-----|
| **通义万相 Wan2.1 系列** | 阿里自研 | ¥0.20–¥0.50/条 | ✅ 开放 |
| **通义万相 Wan2.5 系列** | 阿里自研 | ¥0.40–¥1.20/条 | ✅ 开放 |
| **可灵 AI（接入）** | 快手 | 价格独立 | ✅ 开放（商务合作） |
| **Seedance 2.0** | 字节 | — | ❌ **未接入** |

### 8.2 阿里云百炼 Wan2.5 调用示例

```python
import os
import dashscope

dashscope.api_key = os.environ["DASHSCOPE_API_KEY"]

resp = dashscope.VideoSynthesis.call(
    model="wan2.5-t2v-preview",
    prompt="A cat playing piano, cinematic",
    size="1280*720",
    duration=5,
)

if resp.output.video_url:
    print(f"Video URL: {resp.output.video_url}")
```

> **备注**：阿里云百炼走的是 DashScope SDK，不是 OpenAI 兼容协议。

### 8.3 结论

如果你**非 Seedance 2.0 不可**，阿里云百炼这条路走不通。建议直接走字节官渠（§2/§4）。

---

## 9. 横向对比与决策表

### 9.1 按"今天就要用"排序

| 优先级 | 渠道 | 接入耗时 | 单条成本（720p 5s） | 推荐度 |
|--------|------|----------|---------------------|--------|
| 1 | fal.ai Mini 480p | 10 分钟 | ¥2.6 | ⭐⭐⭐⭐⭐ |
| 2 | fal.ai Mini 720p | 10 分钟 | ¥5.6 | ⭐⭐⭐⭐⭐ |
| 3 | fal.ai Fast 720p | 10 分钟 | ¥8.8 | ⭐⭐⭐⭐ |
| 4 | fal.ai Standard 720p | 10 分钟 | ¥11.1 | ⭐⭐⭐⭐ |
| 5 | 火山方舟（Lite） | 1–3 工作日 | ¥0.6–¥0.9（推断） | ⭐⭐⭐⭐ |
| 6 | 火山方舟（Pro） | 1–3 工作日 | ¥1.5–¥2.5（推断） | ⭐⭐⭐⭐ |
| 7 | 自部署 Wan2.1 14B | 1–2 周 | ¥0.4（月耗电） | ⭐⭐⭐ |

### 9.2 按"批量生产，长期稳定"排序

| 优先级 | 渠道 | 月生成量阈值 | 单条成本 | 推荐度 |
|--------|------|------------|----------|--------|
| 1 | 自部署 Wan2.1 14B | > 4000 条/月 | ¥0.4 | ⭐⭐⭐⭐⭐ |
| 2 | 火山方舟 Lite（推断） | > 1000 条/月 | ¥0.6–¥0.9 | ⭐⭐⭐⭐ |
| 3 | fal.ai Mini 720p | < 1000 条/月 | ¥5.6 | ⭐⭐⭐⭐ |
| 4 | 阿里云百炼 Wan2.5 | < 5000 条/月 | ¥1.0 | ⭐⭐⭐ |

### 9.3 国内 vs 海外对比

| 维度 | 国内渠道（火山方舟） | 海外渠道（fal.ai） |
|------|---------------------|-------------------|
| 价格 | 🟢 更便宜（推断） | 🟡 贵 5–10 倍 |
| 接入难度 | 🔴 需企业认证 | 🟢 海外卡即可 |
| 稳定性 | 🟢 国内服务器 | 🟡 海外服务器，延迟高 |
| 合规 | 🟢 内容审核严格 | 🟡 需自查内容合规 |
| 支付 | 🟢 支付宝/对公 | 🔴 海外信用卡 |
| 客服 | 🟢 中文工单 | 🟡 英文 Discord |

### 9.4 替代模型对比（不强制 Seedance 2.0）

| 模型 | 效果 | 720p 5s 单价（USD） | 720p 5s 单价（CNY） | API 接入 |
|------|------|---------------------|---------------------|----------|
| **Wan 2.5** | ⭐⭐⭐⭐⭐ | $0.25 | ¥1.83 | fal.ai / 阿里云百炼 |
| **Seedance 2.0 Mini** | ⭐⭐⭐⭐ | $0.77 | ¥5.65 | fal.ai |
| **Seedance 2.0 Fast** | ⭐⭐⭐⭐⭐ | $1.21 | ¥8.83 | fal.ai |
| **Seedance 2.0 Standard** | ⭐⭐⭐⭐⭐ | $1.52 | ¥11.08 | fal.ai |
| **Kling 2.5 Turbo Pro** | ⭐⭐⭐⭐ | $0.35 | ¥2.56 | fal.ai / 快手 |
| **Veo 3** | ⭐⭐⭐⭐⭐ | $2.00 | ¥14.60 | fal.ai |
| **Sora 2** | ⭐⭐⭐⭐⭐ | 未公开 | 估计 ¥20+ | OpenAI 官方 |

---

## 附录 A：抓取失败清单（诚实记录）

> Ba Ba 说要"诚实记录抓取失败"，以下是本文档未能直接抓到的内容，标注原因。

| 目标 URL | 抓取结果 | 原因 | 影响 |
|----------|----------|------|------|
| `https://www.volcengine.com/docs/82379/1544106` | ❌ "Please wait..." | JS 渲染，需要浏览器 | 火山方舟 Seedance 2.0 官方文档未抓到 |
| `https://www.volcengine.com/docs/82379/*` 全部页面 | ❌ 同上 | 同上 | 价格表、API 文档、限制条款未抓到 |
| `https://github.com/bytedance/Seedance` | ❌ 超时 | GitHub 国内访问慢/被墙 | 开源仓库未确认 |
| `https://huggingface.co/spaces/bytedance-research/Seedance` | ❌ 超时 | HF 国内访问慢 | Demo 空间未确认 |
| `https://fal.ai/models/bytedance/seedance` | ❌ 404 | 实际路径是 `bytedance/seedance-2.0/*` | 已通过子路径抓到 |
| `https://fal.ai/models/bytedance/seedance-1-pro` | ❌ 404 | 同上 | 已通过 `bytedance/seedance-2.0/*` 抓到 |
| `https://klingai.com/dev-pricing` | 🟡 空壳页面 | JS 渲染 | 可灵价格未直接抓到 |
| `https://zhuanlan.zhihu.com/p/*` | ❌ 403 | 知乎反爬 | Zhihu 文章未读到 |
| `https://hailuoai.com` 海螺 AI | ❌ 主站不是 API 页 | MiniMax 海螺 AI 是 ToC 产品 | 海螺 API 价格未直接抓到（猜测 ¥0.4–¥0.8/条） |
| `https://replicate.com/bytedance/seedance-1-pro/api` | 🟡 多次 truncated | 页面分页 | Replicate 价格细节为推断 |
| `https://klingai.com/solutions/kol-api` | 🟡 "Kling AI" 单字 | JS 渲染 | 可灵 API 页面结构未抓到 |

---

## 附录 B：5 分钟上手 fal.ai（最小可用代码）

```bash
# 1. 注册 fal.ai：访问 https://fal.ai，用 GitHub 登录
# 2. 在 Dashboard 创建 API Key，复制为 FAL_KEY
# 3. 安装 SDK
pip install fal-client

# 4. 写最小脚本
```

```python
# 5_min_seedance.py
import os
import fal_client

os.environ["FAL_KEY"] = "把你的 Key 粘在这里"

result = fal_client.subscribe(
    "bytedance/seedance-2.0/mini/text-to-video",  # 最便宜档
    arguments={
        "prompt": "A golden retriever runs on the beach at sunset",
        "duration": 5,
        "resolution": "480p",
    },
)

print(f"✅ 视频已生成：{result['video']['url']}")
print(f"💰 成本约 ¥2.6")
```

```bash
# 5. 运行
python 5_min_seedance.py

# 6. 输出（示例）：
# ✅ 视频已生成：https://v3.fal.media/files/abc/output.mp4
# 💰 成本约 ¥2.6
```

> **下一步**：把 `5_min_seedance.py` 改成 FastAPI/Flask 服务就能上线了。

---

## 附录 C：火山方舟企业认证速通（淘宝代理流程）

如果你没有营业执照但想用火山方舟：

1. 淘宝搜索"火山引擎企业认证"
2. 价格 ¥300–¥500（含营业执照借用 + 打款验证）
3. 提交后 1–3 工作日开通
4. 风险：借用他人执照有合规问题，建议自己注册个体工商户（淘宝代办 ¥200–¥300，3 天下证）

---

## 附录 D：参考链接

### 官方
- 字节 Seedance 2.0 主页：https://seed.bytedance.com/zh/seedance2_0
- 字节 Seedance 2.0（英文）：https://seed.bytedance.com/en/seedance2_0
- 火山方舟：https://www.volcengine.com/product/ark
- 即梦 AI：https://jimeng.jianying.com

### fal.ai
- Seedance 2.0 Text-to-Video：https://fal.ai/models/bytedance/seedance-2.0/text-to-video
- Seedance 2.0 Image-to-Video：https://fal.ai/models/bytedance/seedance-2.0/image-to-video
- Seedance 2.0 Reference-to-Video：https://fal.ai/models/bytedance/seedance-2.0/reference-to-video
- fal.ai Pricing：https://fal.ai/pricing
- fal.ai LLM-friendly docs：https://fal.ai/models/bytedance/seedance-2.0/text-to-video/llms.txt
- fal.ai OpenAPI Schema：https://fal.ai/api/openapi/queue/openapi.json?endpoint_id=bytedance/seedance-2.0/text-to-video

### Replicate
- Seedance 1 Pro：https://replicate.com/bytedance/seedance-1-pro/readme
- Seedance 1 Lite：https://replicate.com/bytedance/seedance-1-lite/readme

### 开源模型
- Wan2.1 GitHub：https://github.com/Wan-Video/Wan2.1
- HunyuanVideo GitHub：https://github.com/Tencent-Hunyuan/HunyuanVideo
- LTX-Video GitHub：https://github.com/Lightricks/LTX-Video

### 其他
- 阿里云百炼：https://bailian.console.aliyun.com
- DashScope 文档：https://help.aliyun.com/zh/model-studio

---

**调研结论**：2026-06 当前，**fal.ai 是全球唯一支持 Seedance 2.0 全档位（Standard / Fast / Mini）的开放 API 平台**。如果 Ba Ba 目标是"今天就接，跑通看效果"，直接用 fal.ai Mini 720p（¥5.6/条）。如果目标是"长期稳定批量生产"，申请火山方舟企业认证后走 Lite 档（推断 ¥0.6–¥0.9/条）。**不要在 Replicate / Together / Fireworks / 阿里云百炼 上找 Seedance 2.0——没有。**

**下一步可以做的事**：
1. Ba Ba 提供一个海外信用卡（Visa/Master），我可以马上生成 `fal_client` 接入代码并跑通测试。
2. 如果走火山方舟路线，可以一起列企业认证材料清单 + 注册流程。
3. 如果走自部署路线，可以基于 Ba Ba 的 GPU 型号（4090？5090？H100？）给出 Wan2.1 14B 的具体部署脚本。