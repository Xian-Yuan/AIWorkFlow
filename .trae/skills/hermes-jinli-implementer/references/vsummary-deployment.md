# vsummary 部署参考

> Jinli Knowledge Graph spec 锁定的外部视频总结工具。固定版本 `4de6dbbd376c29d35380d8d8fcc2094821b2b3f9`。

## 部署信息

| 项目 | 值 |
|------|-----|
| 安装路径 | `E:\Obsidian\tools\vsummary` |
| Git 版本 | `4de6dbb` (detached HEAD) |
| Python 环境 | `.venv`（venv，非 conda） |
| 启动脚本 | `start-venv.bat`（双击启动） |
| 后端 | http://127.0.0.1:8001 |
| 前端 | http://127.0.0.1:4173 |
| API 文档 | http://127.0.0.1:8001/docs |

## 手动启动命令

```bash
# 后端
cd /e/Obsidian/tools/vsummary/src && /e/Obsidian/tools/vsummary/.venv/Scripts/python.exe -m backend.api.server --host 127.0.0.1 --port 8001

# 前端
cd /e/Obsidian/tools/vsummary/src/frontend && npm run dev
```

## .env 配置

文件位置：`E:\Obsidian\tools\vsummary\.env`

必填：
- `OPENAI_API_KEY` — LLM API Key（Ollama 时填 `ollama` 占位即可）
- `OPENAI_PROVIDER` — 默认 `openai_compatible`
- `OPENAI_BASE_URL` — 如用 Ollama 填 `http://localhost:11434/v1`
- `OPENAI_MODEL` — 模型名如 `qwen3:14b` 或 `deepseek-chat`

可选：
- `HF_ENDPOINT=https://hf-mirror.com` — HuggingFace 镜像
- `BILIBILI_COOKIE` — B站完整 Cookie（推荐用 cookie/init API 自动获取，见下方）
- `BILIBILI_SESSDATA` — 单 cookie 兼容入口

## 关键 API 端点

| 端点 | 用途 |
|------|------|
| `GET /api/health` | 健康检查 |
| `POST /api/linked/bilibili/resolve/video` | 解析B站视频 |
| `POST /api/linked/bilibili/resolve/series` | 解析B站合集 |
| `POST /api/linked/bilibili/cookie/init` | 初始化B站 Cookie（自动获取） |
| `GET /api/videos/{sid}/{vid}/summary` | 获取视频摘要 |
| `GET /api/videos/{sid}/{vid}/exports/summary.md` | 导出 Markdown 摘要 |
| `GET /api/videos/{sid}/{vid}/exports/transcript.md` | 导出转录文本 |
| `GET /api/videos/{sid}/{vid}/exports/mixed.md` | 导出混合 Markdown |
| `POST /api/videos/{sid}/{vid}/generate` | 触发 AI 总结生成 |
| `GET /api/rag/models` | 列出 RAG 模型 |
| `GET /api/asr/faster-whisper/models` | 列出 ASR 模型 |
| `POST /api/asr/faster-whisper/models/{id}/download` | 下载 ASR 模型 |
| `POST /api/rag/models/{key}/download` | 下载 RAG 模型 |
| `GET /api/provider-settings` | 当前 LLM 配置 |

## 与 Jinli KG 的集成边界

```
B站视频URL → vsummary (本地ASR + AI总结)
                    ↓
            workspace/ 导出 (transcript/chapters/notes/Markdown)
                    ↓
          Jinli WP03 vsummary 适配器 → 统一 transcript contract
                    ↓
          本地 LLM 丰富 → 知识图谱 → Obsidian 导出
```

**关键约束**（来自 spec）：
- vsummary 是**外部工具**，代码不 fork 进 Jinli
- Jinli 通过 adapter 边界导入 vsummary 的 workspace 产物
- vsummary 固定版本，不跟随上游更新
- Jinli 的 vsummary 适配器在 WP03 中实现

## 部署时注意事项

1. **无 conda 环境**：项目默认用 conda（`environment.yml`），但 Windows 上可用 venv 替代。从 `environment.yml` 的 pip 段提取依赖，加上 CUDA 包
2. **CUDA 依赖**：需额外安装 `nvidia-cublas-cu12 nvidia-cuda-runtime-cu12 nvidia-cuda-nvrtc-cu12 nvidia-cudnn-cu12`
3. **FFmpeg**：需在系统 PATH 中（vsummary 不自带）
4. **首次 ASR 运行**：faster-whisper 需下载 `large-v3-turbo` 模型（约 1.5GB）。**GFW 环境下自动下载会失败**，见下方 HuggingFace 下载方案
5. **首次 RAG 运行**：fastembed 会下载 `BAAI/bge-small-zh-v1.5` 嵌入模型（通过 API 触发下载通常成功）
6. **B站 Cookie**：只填 SESSDATA 会被 WAF 412 拦截，需填完整 Cookie 字符串

## B站 Cookie 配置 ⚠️

B站 WAF 需要完整 Cookie（buvid3/4/fp、b_nut、bili_jct、_uuid、DedeUserID、SESSDATA 等），只填 SESSDATA 会被 412 拦截。

**推荐方式 — 自动获取**：
```bash
curl -s --max-time 120 -X POST http://127.0.0.1:8001/api/linked/bilibili/cookie/init
```
vsummary 会自动打开浏览器（通过 DrissionPage），访问B站登录页，获取登录后的完整 Cookie 并写入 `.env` 的 `BILIBILI_COOKIE` 字段。用户需在弹出的浏览器窗口中确认已登录。

**手动方式**：
1. 浏览器登录B站
2. F12 → Network → 任意 bilibili.com 请求 → Request Headers → 复制完整 `cookie` 字段值
3. 粘贴到 `.env` 的 `BILIBILI_COOKIE=`

**验证 Cookie 生效**：
```bash
# 无 Cookie → 412 Precondition Failed
# Cookie 不完整 → 412
# Cookie 完整 → 正常返回视频信息
cd /e/Obsidian/tools/vsummary && .venv/Scripts/python.exe -c "
import yt_dlp
ydl_opts = {'quiet': False, 'cookiefile': '<cookie-file-path>'}
with yt_dlp.YoutubeDL(ydl_opts) as ydl:
    info = ydl.extract_info('https://www.bilibili.com/video/BV1GJ411x7h7', download=False)
    print(f'Title: {info.get(\"title\",\"?\")}')}
"
```

## HuggingFace 模型下载（GFW 环境）⚠️ 重要

`huggingface_hub` 库的 `HF_ENDPOINT` 环境变量**不能可靠地**将所有请求重定向到镜像。即使设置了 `HF_ENDPOINT=https://hf-mirror.com`，库仍会尝试连接 `huggingface.co`（被 GFW 阻断），导致 SSL 错误或 `LocalEntryNotFoundError`。

**不推荐**：
- `huggingface-cli download` — 在 GFW 下仍连 huggingface.co
- `snapshot_download()` — 同上，即使设了 `HF_ENDPOINT`
- vsummary 内置的下载 API（`POST /api/asr/faster-whisper/models/{id}/download`）— 底层同样走 huggingface_hub

**可靠方案 — 手动 curl 下载**：

1. 用 API 获取模型文件列表：
   ```bash
   curl -sL "https://hf-mirror.com/api/models/<org>/<model>" | python -c "import sys,json; [print(s['rfilename']) for s in json.load(sys.stdin).get('siblings',[])]"
   ```

2. 逐文件下载到目标目录：
   ```bash
   curl -L -o <filename> "https://hf-mirror.com/<org>/<model>/resolve/main/<filename>"
   ```
   注意域名是 `hf-mirror.com`（不是 `.co`，`.co` 会解析失败）。

3. faster-whisper large-v3-turbo 文件清单（`dropbox-dash/faster-whisper-large-v3-turbo`）：
   - `config.json` (2.3KB)
   - `preprocessor_config.json` (340B)
   - `tokenizer.json` (2.6MB)
   - `vocabulary.json` (1.1MB)
   - `model.bin` (1.5GB — 核心权重文件)

   目标目录：`E:\Obsidian\tools\vsummary\data\models\faster-whisper\large-v3-turbo\`

4. 下载后重启后端，vsummary 会自动识别本地模型文件（`downloaded: True`）。

## 运维注意事项

1. **Ollama 需单独启动**：vsummary 不管理 Ollama 生命周期。启动 vsummary 前需确认 Ollama 在 `localhost:11434` 运行。检查命令：`curl -s http://localhost:11434/api/tags`。若未运行：`OLLAMA_MODELS=/e/Ollama/models ollama serve`（后台）
2. **端口 8001 冲突**：若后端启动失败且无输出，检查 `netstat -ano | grep :8001`。旧进程可能仍占用端口，需 `taskkill //PID <pid> //F` 后重启
3. **Ollama API Key 占位**：Ollama 不验证 API Key，但 vsummary 要求 `OPENAI_API_KEY` 非空。填 `ollama` 即可
4. **qwen3:14b 首次推理慢**：模型加载到 VRAM 需 30-120 秒（取决于模型大小和磁盘速度）。后续推理正常速度
5. **后端重启需杀旧进程**：修改 `.env` 后需重启后端。先 `taskkill` 旧进程，等端口释放（约 2 秒），再启动新进程

## 本地视觉模型 UI 检查

当云端视觉 API 不可用或报错时，可用本地 Ollama 视觉模型（minicpm-v4.6）检查浏览器 UI 状态：

```python
import base64, httpx

with open(r'E:\UEGameDevelopment\screenshot.png', 'rb') as f:
    img_b64 = base64.b64encode(f.read()).decode()

resp = httpx.post('http://localhost:11434/api/generate', json={
    'model': 'openbmb/minicpm-v4.6:latest',
    'prompt': '描述截图中浏览器窗口的内容...',
    'images': [img_b64],
    'stream': False
}, timeout=120)
print(resp.json().get('response', ''))
```

截屏用 PowerShell（git-bash 中调用）：
```bash
powershell.exe -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; \$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds; \$bitmap = New-Object System.Drawing.Bitmap(\$screen.Width, \$screen.Height); \$graphics = [System.Drawing.Graphics]::FromImage(\$bitmap); \$graphics.CopyFromScreen(\$screen.Location, [System.Drawing.Point]::Empty, \$screen.Size); \$bitmap.Save('E:\UEGameDevelopment\screenshot.png'); \$graphics.Dispose(); \$bitmap.Dispose()"
```

**注意**：minicpm-v4.6 对复杂 UI 的理解力有限（可能误识别元素、混淆窗口），适合做大致状态判断，不适合精确 UI 自动化。优先用 API 端点验证功能状态（如 `/api/health`、`/api/provider-settings`），视觉检查仅作辅助。

## 端到端测试流程（B站视频 → AI 总结）

完整 API 调用链，可直接用于验证 vsummary 功能或处理用户提供的B站视频链接：

```bash
# 0. 前置检查：确认所有服务运行
curl -s http://127.0.0.1:8001/api/health          # 后端
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:4173/  # 前端
curl -s http://localhost:11434/api/tags             # Ollama

# 1. 解析B站视频（获取元数据）
curl -s --max-time 60 -X POST http://127.0.0.1:8001/api/linked/bilibili/resolve/video \
  -H "Content-Type: application/json" \
  -d '{"url":"https://www.bilibili.com/video/BV1UF7m68E1K/"}'
# 返回: {"id":"BV1UF7m68E1K","title":"...","status":"linked",...}

# 2. 解析为 series（用于导入工作区）
curl -s --max-time 60 -X POST http://127.0.0.1:8001/api/linked/bilibili/resolve/series \
  -H "Content-Type: application/json" \
  -d '{"url":"https://www.bilibili.com/video/BV1UF7m68E1K/"}'
# 返回: {"id":"bilibili-BV1UF7m68E1K","videos":[...],...}

# 3. 下载视频（视频自动进入 __playground__ series）
curl -s --max-time 30 -X POST http://127.0.0.1:8001/api/videos/__playground__/BV1UF7m68E1K/download
# 返回: {"status":"started","task_id":"download/__playground__/BV1UF7m68E1K"}

# 4. 监控下载进度
curl -s http://127.0.0.1:8001/api/videos/__playground__/BV1UF7m68E1K/download/progress
# 返回 SSE: data: {"status":"completed","progress":100.0,...}

# 5. 触发 AI 总结生成
curl -s --max-time 10 -X POST http://127.0.0.1:8001/api/videos/__playground__/BV1UF7m68E1K/generate
# 注意：此 API 返回空响应或超时是正常的，生成在后台进行

# 6. 监控生成进度（轮询，间隔 20-60 秒）
curl -s http://127.0.0.1:8001/api/videos/__playground__/BV1UF7m68E1K/generate/status
# 返回: {"status":"running","stage":"summarize","progress":88.0,...}
# 完成后: {"status":"completed","progress":100.0,...}

# 7. 获取总结结果
curl -s http://127.0.0.1:8001/api/videos/__playground__/BV1UF7m68E1K/summary
# 返回: {"title":"...","one_sentence_summary":"...","chapters":[...],"key_takeaways":[...]}

# 8. 导出 Markdown
curl -s http://127.0.0.1:8001/api/videos/__playground__/BV1UF7m68E1K/exports/summary.md
curl -s http://127.0.0.1:8001/api/videos/__playground__/BV1UF7m68E1K/exports/transcript.md
curl -s http://127.0.0.1:8001/api/videos/__playground__/BV1UF7m68E1K/exports/mixed.md
```

### 关键参数

| 参数 | 值 | 说明 |
|------|-----|------|
| series_id | `__playground__` | 单视频默认进入 Playground |
| video_id | BV 号 | 如 `BV1UF7m68E1K`，从 URL 提取 |
| generate 超时 | 5-10+ 分钟 | 本地 qwen3:14b 推理，89 秒视频约 5 分钟 |
| generate API 行为 | 返回空/超时 | 正常，生成异步进行，用 `/generate/status` 轮询 |

### 用户偏好

爸爸偏好**直接给视频链接让 agent 通过 API 处理**，而不是自己在 vsummary 前端网页上操作。收到B站链接后，直接走上述 API 流程，最后把总结结果展示给爸爸。

### 实测数据（2026-06-21）

- 测试视频：BV1UF7m68E1K（AI Agent 找代码还在暴力 grep？Semble 让检索省 98% Token，89 秒）
- 视频下载：3.7 秒
- ASR 转录：约 2 分钟
- AI 总结（qwen3:14b）：约 5 分钟
- 总结质量：3 个章节、6 条关键结论、完整转录分段，质量良好

## Jinli KG spec 中 vsummary 的定位

vsummary 在 Jinli Phase 2.5 知识图谱架构中的角色：

```
Sources: Docs / Tasks / Memory / CodeGraph / Videos / Obsidian
    ↓
Ingestion: File scanner, video downloader/transcriber (yt-dlp + vsummary adapter)
    ↓
Local LLM Enrichment: qwen3:14b (summaries/entities) → qwen2.5-coder:14b (JSON) → minicpm-v4.6 (visual)
    ↓
Knowledge Store: memory.db (canonical) + knowledge.db (graph) + Obsidian export (visual) + obra index (MCP/search)
    ↓
Jinli Runtime: soul_init retrieval, soul_discover ingestion, soul_end reflection
```

**WP03 视频源适配器**负责将 vsummary 的 workspace 产物映射到 Jinli 的统一 transcript contract。适配器不 fork vsummary 代码，通过文件系统读取 workspace 导出。

## vsummary Workspace 产物格式

WP03 实现中发现的实际文件格式：

### transcript.cleaned.json（主要来源）

```json
{
  "title": "BV1UF7m68E1K",
  "language": "zh",
  "duration_seconds": 89.94,
  "segments": [
    {"start_seconds": 0.0, "end_seconds": 2.06, "text": "你让AI Agent改代码"},
    {"start_seconds": 2.06, "end_seconds": 4.0, "text": "最贵的常常不是生成代码"}
  ]
}
```

- 顶层有 `title`、`language`、`duration_seconds`
- `segments` 是清洗后的 Whisper 转录，每段有 `start_seconds`、`end_seconds`、`text`

### transcript.raw.json（回退来源，位于 `.cache/whisper/`）

```json
{
  "language": "zh",
  "segments": [
    {"start_seconds": 0.0, "end_seconds": 2.06, "text": "你让AI Agent改代码"}
  ]
}
```

- 与 cleaned 格式相同但无 `title`/`duration_seconds` 顶层字段
- 可能有更多 ASR 噪声段

### summary.json（结构化摘要）

```json
{
  "title": "BV1UF7m68E1K",
  "one_sentence_summary": "一句话总结",
  "core_problem": "核心问题描述",
  "chapters": [
    {
      "id": "chapter-1",
      "title": "章节标题",
      "start_seconds": 0.0,
      "end_seconds": 22.0,
      "summary": "章节摘要",
      "key_points": ["要点1", "要点2"]
    }
  ],
  "key_takeaways": ["核心结论1", "核心结论2"]
}
```

### VsummaryAdapter 读取优先级

1. `<VIDEO_ID>/transcript.cleaned.json` → `TranscriptAcquisition.VSUMMARY_IMPORT`
2. `<VIDEO_ID>/.cache/whisper/transcript.raw.json` → `TranscriptAcquisition.WHISPER`
3. 均不存在 → `TranscriptAcquisition.UNAVAILABLE`
