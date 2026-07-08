# 分析报告：vsummary 续跑 + Obsidian 推送

## 现状盘点（2026-07-08 09:xx 实测）

### 文件系统层面

| 路径 | 内容 | 数量 |
|------|------|------|
| `E:\Obsidian\tools\vsummary\data\bilibili_fav_ai.json` | B 站收藏夹 `ai相关` (folder 3972516389) | 456 个视频 |
| `E:\Obsidian\tools\vsummary\videos\__playground__\*.mp4` | 已下载视频文件 | 452 个 |
| `E:\Obsidian\tools\vsummary\workspace\__playground__\BV*/summary.json` | 已生成 AI 总结 | 439+ 个 BV 目录 |
| `E:\ObsidianVault\JinliKG\Sources\Videos\*.md` | Obsidian 已落盘总结 | 571 个（含历史） |
| **交集**（BV id 同时在 workspace 总结 + Obsidian 文件名） | **119** | |
| **差集**（已总结但文件名未含 BV） | 452 | 历史命名格式不一致 |
| **真实 backlog**（BV 总结存在，Obsidian 找不到同名） | **~357** | 需走 classify |

### 失败分类

| BV | 类别 | 可重试？ | 原因 |
|----|------|---------|------|
| BV1chjV67EVs | no_audio | ❌ | AV1 编码无音轨 |
| BV1JY7k6aEMw | no_audio | ❌ | AV1 编码无音轨 |
| BV1cxX9BSEs3 | no_audio | ❌ | AV1 编码无音轨 |
| BV1YiEc6GE2s | audio_corrupt | 🟡 | ffmpeg exit 69，可重下 |
| BV163E76eEQQ | audio_corrupt | 🟡 | ffmpeg exit 69，可重下 |
| BV1W3X6BQE1P | llm_struct_fail | ✅ | LiteLLM 解析失败 |
| BV1AiEF6WEFJ | llm_struct_fail | ✅ | "AI 概况生成失败" |
| BV1tD7b6kEpP | ~~llm_struct_fail~~ | ✅ → ✅ | 第二次重试成功 |

### 数字为什么对不齐？

- **favorites 456** vs **workspace 476**：因为 20 个是分P视频（`BVxxx_p1`、`_p2`），同一视频多次失败重试留多个目录
- **workspace 439 已总结 vs Obsidian 119**：历史 Obsidian 命名格式不统一（部分含 BV 部分不含），需要走 classify 全量对账

## 依赖链推导

```
[下载阶段]
  backend 启动 → batch_pipeline.py --download
    → 读 bilibili_fav_ai.json (456)
    → 减 download_progress.json (已下载 452)
    → 待下 4 个 → yt-dlp 下载

[总结阶段]
  backend 启动 → workflow.py run
    → 从 favorites.json 减已总结 (439)
    → 剩余 ~17 个进入流水线
    → 跳过 3 no_audio (permanent)
    → 2 audio_corrupt 重下后试
    → 3 llm_fail 重试 (LLM 抽风而已)
    → 最后剩 ~9 个成功

[推送阶段]
  obsidian-classify.ps1 -Batch -Apply -SourceDir .../JinliKG/Sources/Videos
    → 读每个 .md 的 frontmatter (tag + domain_path)
    → 查 classification-rules.yaml 决定目标路径
    → Move-Item 到 知识/{领域}/{子类}/
    → 留 [[target-path]] redirect stub
    → 幂等：kg_id 已存在则跳过

[增强阶段] (可选)
  obsidian-evolve.ps1 -Batch -ExtractGene
  obsidian-link-discover.ps1 -Method tag-cooccurrence

[收尾]
  写 status.yaml → sync-workflow-registry.py → 归档
```

## 成熟方案验证

| 步骤 | 成熟度 | 验证 |
|------|--------|------|
| 启动后端 | ✅ 已知 | `_start_backend.bat` 已存在 |
| 下载 | ✅ 已知 | `batch_pipeline.py --download` 已跑通 452 次 |
| 总结 | ✅ 已知 | `workflow.py run` 已成功 439+ |
| Classify | ✅ 已知 | 之前跑过，571 个文件已落 |
| Evolve | ✅ 已知 | `obsidian-evolve.ps1` 已部署 |
| Link discover | ✅ 已知 | `obsidian-link-discover.ps1` 已部署 |

**结论**：mature_path_verified = yes，quality_level = mature

## 风险评估

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| 后端启动失败 (端口冲突) | 中 | 高 | `Get-NetTCPConnection 8001` 检查 + 杀进程 |
| Cookie 过期 (412 WAF) | 低 | 高 | 用 browser mode `bili_fav_ai_v3.py` 刷新 |
| Provider 全 rate_limit | 低 | 中 | 5 分钟 cooldown 后自动切换 |
| 4 个未下视频下载失败 | 中 | 低 | 跳过即可，下次再补 |
| Classify 后链接断裂 | 低 | 中 | D1 redirect stub 保证 GraphView 边不丢 |
| Gene 池爆炸 | 低 | 中 | 0.6 mean 阈值 + dedup |

## 隐含需求

- **重试时不能引入新的失败**：LLM 失败的可重试视频如果再失败，必须落 retry_report.json，不允许静默丢失
- **进度必须落盘**：每个视频处理完立即更新 batch_report.json / workflow_report.json，不能内存里堆
- **优雅退出**：SIGINT 中断时至少保留当前 batch_report.json + workflow_report.json（pipeline.py 内已实现）
- **provider 切换**：429 触发后 5 分钟 cooldown，期间自动切到 zhipu_glm4flash (free)
- **video 命名规范**：下载时文件名必须保持 `{bvid}.mp4`，避免后续 pipeline 找不到

## 决策记录

1. **跳过 3 个 AV1 无音频视频** — ffmpeg 4294967274 = AV1 编码无音轨，B 站原视频就没声音，无法修复
2. **重试 2 个 audio_corrupt** — ffmpeg exit 69 = 音轨损坏，先重下看是否 B 站端偶尔抽风
3. **重试 3 个 llm_fail** — LLM 抽风（MiniMax M1 偶尔吐 think tag 或空 segment），换 provider 即可
4. **不刷新 favorites** — 沿用 6-30 数据，避免触发新 cookie 风险；下次单独跑 `bili_fav_ai_v3.py`
5. **不全量重 summarize** — 439 个已总结不动，只补缺失；视频总结本身幂等，但 LLM 输出不稳定，全量跑反而引入新差异
6. **Classify 后再 Evolve** — 顺序固定：先分到 `知识/`，再从 `知识/` 提 Gene，否则 Gene 来源混乱