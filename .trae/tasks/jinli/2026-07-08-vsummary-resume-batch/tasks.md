# 任务清单：vsummary 续跑 + Obsidian 推送

## 任务依赖图

```
T01 (启动后端)
  ↓
T02 (下载 4 个未下视频)
  ↓
T03 (重试 5 个失败总结 + 跳过 3 个 no_audio)
  ↓
T04 (Classify 357 backlog 到 Obsidian 知识/)
  ↓
T05 (Evolve 提 Gene)        T06 (Link discover)
  ↓                            ↓
T07 (更新 status + sync registry)
  ↓
T08 (Verify AC01-08 + 封包)
```

## 详细任务

### T01: 启动 vsummary 后端

- **执行者**: 金璃好帮手
- **命令**:
  ```powershell
  # 检查端口
  Get-NetTCPConnection -LocalPort 8001 -ErrorAction SilentlyContinue
  # 启动后端（后台）
  Start-Process -FilePath "E:\Obsidian\tools\vsummary\_start_backend.bat" -WindowStyle Normal
  # 等 5 秒
  Start-Sleep -Seconds 8
  # 健康检查
  Invoke-WebRequest http://127.0.0.1:8001/api/health
  ```
- **验收**: 返回 200 + `{"status":"ok"}`
- **失败处理**: 端口被占 → 杀旧进程；启动失败 → 看 `backend_run.log`

### T02: 下载 4 个未下视频

- **执行者**: 金璃好帮手
- **命令**:
  ```bash
  cd E:\Obsidian\tools\vsummary
  .venv\Scripts\python.exe -u batch_pipeline.py --download
  ```
- **目标**: BV1q37j6QExh, BV15G7q6rEgs, BV1tp7G6oEcN, BV1HxXGBBESv
- **验收**: download_progress.json 包含 456 个 BV；videos\__playground__\*.mp4 数 ≥ 456
- **失败处理**: 单视频失败 → skip；全失败 → 检查 cookie

### T03: 重试 5 个失败总结 + 跳过 3 个 no_audio

- **执行者**: 金璃好帮手
- **命令**:
  ```bash
  cd E:\Obsidian\tools\vsummary
  .venv\Scripts\python.exe -u workflow.py run
  ```
- **目标视频**:
  - ✅ 可重试：BV1W3X6BQE1P (llm), BV1AiEF6WEFJ (llm), BV1YiEc6GE2s (corrupt→重下), BV163E76eEQQ (corrupt→重下)
  - ❌ 永久跳过：BV1chjV67EVs, BV1JY7k6aEMw, BV1cxX9BSEs3 (AV1 无音频)
- **验收**: workspace summary.json 数 ≥ 441
- **失败处理**: 单个失败 → 写入 retry_failed.json，下次再试

### T04: Classify backlog 到 Obsidian

- **执行者**: 金璃好帮手
- **命令**:
  ```powershell
  .\.trae\scripts\obsidian-classify.ps1 -Batch -Apply -SourceDir "E:\ObsidianVault\JinliKG\Sources\Videos"
  ```
- **验收**: `E:\ObsidianVault\知识\**\*.md` 数 ≥ 300
- **失败处理**: 无 frontmatter → 写入 `进化/rules/_unclassified-queue.yaml`

### T05: Evolve 提取 Gene (可选)

- **执行者**: 金璃好帮手
- **命令**:
  ```powershell
  .\.trae\scripts\obsidian-evolve.ps1 -Batch -ExtractGene -Apply -SourceDir "E:\ObsidianVault\知识"
  ```
- **验收**: `E:\ObsidianVault\进化\genes\*.yaml` 数 ≥ 50
- **失败处理**: mean < 0.6 → 不提

### T06: Link discover 跨笔记关联 (可选)

- **执行者**: 金璃好帮手
- **命令**:
  ```powershell
  .\.trae\scripts\obsidian-link-discover.ps1 -Method tag-cooccurrence -Apply -SourceDir "E:\ObsidianVault\知识"
  ```
- **验收**: 至少 50 个笔记新增 `## Related` 块

### T07: 更新 status + sync registry

- **执行者**: 金璃好帮手
- **命令**:
  ```powershell
  # 写 status.yaml（手动编辑或脚本）
  # ...
  python E:\UEGameDevelopment\.trae\scripts\sync-workflow-registry.py
  ```
- **验收**: `skills\vsummary\status.yaml` progress = "456/456"; registry.yaml 同步

### T08: Verify AC + 封包

- **执行者**: 金璃小天才（原 Issuer）
- **命令**:
  ```powershell
  .\.trae\scripts\task-guard.ps1 2026-07-08-vsummary-resume-batch verify
  ```
- **验收**: AC01-08 全 PASS；生成 verification-report.md

## 文件清单

| 文件 | 状态 | 说明 |
|------|------|------|
| `.task.yaml` | 待创建 | 任务状态 |
| `routing.md` | ✅ 已写 | 路由决策 |
| `analysis.md` | ✅ 已写 | 分析报告 |
| `spec.md` | ✅ 已写 | 行为规范 |
| `tasks.md` | ✅ 当前 | 本文件 |
| `verification-report.md` | 待生成 | AC 验收报告 |
| `doc-impact.md` | 待写 | 文档影响（按 contract-verify 要求） |

## 非任务范围

- 不动 RTS / CharacterDesignTool 项目
- 不动已有 vsummary workspace 的 summary.json
- 不刷新 B 站 favorites
- 不修复 cookie / API key
- 不改 source code (batch_pipeline.py / workflow.py)