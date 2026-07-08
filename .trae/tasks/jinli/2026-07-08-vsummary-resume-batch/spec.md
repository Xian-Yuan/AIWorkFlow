# Spec: vsummary 续跑 + Obsidian 知识库推送

## GIVEN

- 时间：2026-07-08
- B 站收藏夹 `ai相关` (folder 3972516389) 共有 **456** 个视频
- 已下载：**452** 个 mp4 在 `E:\Obsidian\tools\vsummary\videos\__playground__\`
- 已总结：**439+** 个 summary.json 在 `E:\Obsidian\tools\vsummary\workspace\__playground__\`
- Obsidian 已落盘总结：**571** 个 md 在 `E:\ObsidianVault\JinliKG\Sources\Videos\`（命名格式不一致）
- 待下载：**4** 个视频（BV1q37j6QExh, BV15G7q6rEgs, BV1tp7G6oEcN, BV1HxXGBBESv）
- 待重试总结：**5** 个（2 audio_corrupt + 3 llm_fail；3 no_audio 永久跳过）
- 已总结但未在 Obsidian：**~357** 个（走 classify）
- vsummary 后端：**离线**（需要启动）
- Provider 状态：zhipu_glm4flash (free, active), nvidia_deepseek (personal, active)
- 全流程脚本 + cookie + API key：**已配置**（.env 中 5 个 key 全部到位）

## WHEN

执行以下 6 阶段串行流水线：

1. **启动后端** + 健康检查
2. **下载 4 个未下视频**
3. **重试失败总结**（跳过 3 个 no_audio）
4. **Classify 推送 backlog 到 Obsidian `知识/`**
5. **(可选) Evolve + Link discover**
6. **更新 status.yaml + sync registry**

## THEN

### Module 1: 后端启动

- 端口 `127.0.0.1:8001` 监听
- `GET /api/health` 返回 200
- 加载 provider 配置（zhipu_glm4flash + nvidia_deepseek）

### Module 2: 视频下载

- `batch_pipeline.py --download` 跑完后 download_progress.json 包含 456 个 BV
- 失败视频写 download_failed.json，下次跳过

### Module 3: 视频总结

- `workflow.py run` 跑完后，3 个 no_audio 标记 permanent_skip（不再重试）
- 2 个 audio_corrupt 重下后尝试；仍失败则写 retry_failed.json
- 3 个 llm_fail 重试一次；仍失败则写 llm_struct_failed.json
- batch_report.json + workflow_report.json 落盘

### Module 4: Obsidian Classify

- `obsidian-classify.ps1 -Batch -Apply -SourceDir E:\ObsidianVault\JinliKG\Sources\Videos`
- 每个 .md 按 frontmatter (tag + domain_path) 决定目标路径 `知识/{领域}/{子类}/`
- 老位置留 `[[target-path]]` redirect stub（GraphView 边不断）
- 已分类的（kg_id 已存在）跳过

### Module 5: Obsidian Evolve + Link

- `obsidian-evolve.ps1 -Batch -ExtractGene -Apply -SourceDir E:\ObsidianVault\知识`
- `obsidian-link-discover.ps1 -Method tag-cooccurrence -Apply -SourceDir E:\ObsidianVault\知识`
- mean ≥ 0.6 才提 Gene；gene_id dedup；Jaccard > 0.6 才关联

### Module 6: Status 更新

- `skills/vsummary/status.yaml` 写入 `last_run`、`progress: 456/456`、`provider`、`error`
- `skills/obsidian-autopoiesis/status.yaml` 写入分类统计
- `python .trae/scripts/sync-workflow-registry.py` 同步 registry.yaml

## Acceptance Criteria

| AC# | Description | Verification Command | Expected Output |
|-----|-------------|---------------------|-----------------|
| AC01 | 后端 8001 端口在线 | `Invoke-WebRequest http://127.0.0.1:8001/api/health` | 200 |
| AC02 | 4 个未下视频已下载 | 扫 `videos\__playground__\*.mp4` 数 mp4 ≥ 456 | count ≥ 456 |
| AC03 | 跳过 3 个永久 no_audio | 检查 retry queue 无 BV1chjV67EVs/BV1JY7k6aEMw/BV1cxX9BSEs3 | 通过 |
| AC04 | 5 个失败视频至少 2 个成功 | 扫 workspace summary.json 数 vs 439 | count ≥ 441 |
| AC05 | Obsidian 知识目录新增 ≥ 300 个文件 | 扫 `E:\ObsidianVault\知识\**\*.md` 数 | count ≥ 300 |
| AC06 | Gene 池新增 ≥ 50 个 | 扫 `E:\ObsidianVault\进化\genes\*.yaml` | count ≥ 50 |
| AC07 | status.yaml 已更新 | 读 `skills\vsummary\status.yaml` | last_run = today |
| AC08 | registry.yaml 已同步 | 读 `skills\ai-workflow-registry\registry.yaml` | vsummary 进度 = 456/456 |

## Non-Goals

- 不刷新 B 站 favorites 列表（cookie 风险）
- 不修改 batch_pipeline.py / workflow.py 源码
- 不删除 vsummary workspace 中任何已生成的 summary.json
- 不重命名 Obsidian 已有 .md（避免 GraphView 边断裂）
- 不执行 obsidian-dream-reflect（每周一次，由 daemon 触发）
- 不修复 cookie / API key 配置问题

## Quality Checklist

### Completeness
- [x] 所有功能需求都在 spec 中覆盖（下载/总结/classify/evolve/link 6 阶段）
- [x] 每个 Module 有明确的输入条件（前置状态）和预期输出（验收点）
- [x] AC 覆盖所有主要场景（8 项 ≥ 6 模块数）

### Clarity
- [x] GIVEN/WHEN/THEN 无歧义（具体数字 + 具体路径）
- [x] 术语明确（bvid, summary.json, kg_id, gene_id, Jaccard）
- [x] 第三方依赖标注（vsummary 后端, yt-dlp, LLM provider, ffmpeg）

### Consistency
- [x] 与 vsummary/SKILL.md pitfall 列表一致（ffmpeg 4294967274 = no_audio skip）
- [x] 与 obsidian-autopoiesis/SKILL.md 安全护栏一致（D1 zero-destructive, D7 -Apply）
- [x] 文件放置符合 Docs/AI/13-File-Placement-Convention.md（任务包在 `.trae/tasks/`）

### Scenario Coverage
- [x] 主路径：正常下载 + 总结 + classify（AC02/04/05）
- [x] 边界：3 个 no_audio 永久跳过（AC03）
- [x] 错误：后端离线 / cookie 过期 / LLM 全挂（风险表已列）

### Edge Case Coverage
- [x] 并发：vsummary 串行处理（GPU 单实例）
- [x] 资源不足：单 provider rate_limit 自动 cooldown 5min
- [x] 中断：SIGINT 时保留 batch_report.json（pipeline 内已实现）

## Progress Summary

| Phase | Status | Key Decision |
|-------|--------|-------------|
| Plan | ✅ Completed | 6 阶段流水线，成熟方案复用 |
| Implement | ⬜ Pending | 金璃好帮手执行 |
| Review | ⬜ Pending | 对照 AC01-08 验证 |
| Verify | ⬜ Pending | 最终封包 + 归档 |

## Verification & Plain-Language Summary

After AC01-08 pass, write `verification-report.md` with:

**之前 vs 现在**
- 之前：439 个视频有 AI 总结，但 357 个还堆在 workspace 没进 Obsidian；4 个新视频没下载；5 个失败待重试
- 现在：456 个视频全部下载并有 AI 总结；新增 300+ 条知识进入 Obsidian 知识库；50+ 条策略提炼成 Gene

**一句话总结**
- 把 Ba Ba B 站收藏夹里 AI 相关视频全部 AI 总结完，并自动整理成可检索的 Obsidian 知识库