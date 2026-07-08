# Task: 继续 Bilibili 收藏夹视频自动总结 + Obsidian 推送

## 入口分析

| 维度 | 判断 |
|------|------|
| 项目类型 | `jinli` (个人效率 / obsidian 知识库) |
| 主 workflow | `vsummary` (B 站收藏夹 → ASR → LLM 总结) |
| 后处理 workflow | `obsidian-autopoiesis` (classify → evolve → link-discover) |
| 启动方式 | 串行：先下完，再总结，最后分类 |
| 风险等级 | 低（流程已跑通，凭证已配置） |

## 形式化分发决策

| 子任务 | 执行者 | 入口 | 失败处理 |
|--------|--------|------|---------|
| 启动后端 + 前置检查 | 主 Agent | `Start-Process _start_backend.bat` | 自动重试 1 次 |
| 下载 4 个未下视频 | 金璃好帮手 → workflow.py | `batch_pipeline.py --download` | 跳过已存在的 |
| 重试失败总结 (7 个) | 金璃好帮手 → workflow.py | `workflow.py run` | 无音频永久跳过 |
| 推送 357 个 backlog 到 Obsidian | 金璃好帮手 → obsidian-classify | `obsidian-classify.ps1 -Batch -Apply` | 幂等：kg_id 已存在则跳过 |
| Gene 提取 + 关联发现 | 金璃好帮手 → obsidian-evolve | `obsidian-evolve.ps1 -Batch` | 跳过低分 |
| 更新 status + sync registry | 主 Agent | 写入 yaml + run sync script | 幂等 |

## 架构决策

1. **后端必须先起来** — workflow.py / batch_pipeline.py 都通过 HTTP 调用 `127.0.0.1:8001`
2. **跳过前端** — 不需要 UI，CLI 即可
3. **失败永久跳过** — 3 个 AV1 无音频视频（ffmpeg 4294967274）无解，标记 permanent_skip
4. **幂等是底线** — classify / evolve 都按 kg_id / gene_id dedup
5. **不破坏现状** — 不删不移动 JinliKG 已有文件（D1）

## 当前状态快照（截至 2026-07-08 09:xx）

```
Favorites: 456
Downloaded: 452  (4 未下：BV1q37j6QExh, BV15G7q6rEgs, BV1tp7G6oEcN, BV1HxXGBBESv)
Summarized: 439 (含 retry 成功 +1)
Workspace dirs: 476
Failed (workspace 内无 summary.json): 8
  → 3 个 no_audio (permanent skip)
  → 2 个 audio_corrupt (可重下)
  → 3 个 LLM 结构化失败 (可重试)
Summarized not in Obsidian: 357 (待 classify)
Provider: zhipu_glm4flash (free, active), nvidia_deepseek (personal, active)
Backend: 离线（需启动）
```

## 父任务路由

- 父：`jinli/2026-06-21-bilibili-favorites-knowledge-automation`（已封包）
- 子：`vsummary-resume-batch`（本任务）
- 同源：`obsidian-knowledge-autopoiesis`（classify 后处理）

## 不在本任务范围

- 不刷新 favorites 列表（沿用 2026-06-30 数据）
- 不修复 cookie / API key
- 不改 batch_pipeline.py / workflow.py 代码
- 不做 dream-reflect（每周一次，下次由 daemon 触发）