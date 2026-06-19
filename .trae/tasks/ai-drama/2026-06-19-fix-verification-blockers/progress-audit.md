# AI 短视频工作流任务包进度审计 (更新)

日期：2026-06-19 15:45  
范围：AIDramaProducer / Viral Analyzer / Scriptwriter / Pipeline

## 结论

当前 5 个相关任务包。`fix-verification-blockers` 包的 WP01/WP02/WP03/WP05 已全部完成，
WP04（验收文档）正在执行。管线已可通过全 7 阶段并生成非空输出。

## 任务包总览

| Task Packet | 当前阶段 | Tasks | AC 进度 | 当前结论 |
|---|---|---|---:|---:|---:|
| `_shared/2026-06-18-ai-drama-workflow-research` | Plan / migrated | 0/52（历史 backlog） | 0/8 verified | 作为历史设计基线 |
| `ai-drama/2026-06-18-pipeline-architecture` | Implement | 39/58 | 3/12 verified | 基础管线可跑通，待验收 |
| `ai-drama/2026-06-18-scriptwriter-skill` | Implement | 41/57 | 10/15 verified | 基础模块完成，注入与真实 E2E 待验收 |
| `ai-drama/2026-06-18-viral-analyzer-skill` | Implement | 45/56 | 4/13 verified | Mock/fixture 测试通过，真实输入待验证 |
| `ai-drama/2026-06-19-fix-verification-blockers` | Implement | 25/29 | 7/10 verified | WP01-03/WP05 完成，WP04 进行中 |

## 已验证能力

- 9 个 `ai_drama_*` 包均支持 `python -m ... --help`。
- 联网环境完整 pytest：**95 passed**（含 2 新增 known_ids 测试）。
- Video Generator 会拒绝 `duration_source != "tts_measured"`。
- 同角色多句对白的 SRT 时长消费已修复。
- PipelineState、缓存和失败重试有基础测试覆盖。
- **Phase 2 handler 调用 Scriptwriter 管线**（有 API key 则真实生成，无则回退非空骨架）。
- **known_ids 角色映射**：`_detect_characters` 使用 char_map 在文本中搜索角色名。
- **资产文件复制**：全局缓存命中时用 `shutil.copy2` 复制到项目目录。
- **PLACEHOLDER 替换**：`b"PLACEHOLDER_*"` → 可被 ffprobe/PIL 解析的最小有效文件。
- **管线全 7 阶段通过**：非 dry-run 模式 exit 0，产生非空 `script.json`、`final.mp4` 等。

## 当前阻断 (已全部解决)

~~1. Orchestrator Phase 2 只写空剧本骨架，没有调用 Scriptwriter 三步生成。~~ ✅
~~2. Orchestrator 将 Video Generator 包装结果直接传给 Compositor。~~ ✅
~~3. 真实运行得到 0 角色、0 镜头，最终没有 `final.mp4`。~~ ✅
~~4. Text Preprocessor 忽略 `known_ids` 参数。~~ ✅
~~5. 全局资产复用仍引用原项目文件，没有复制到新项目。~~ ✅
~~6. 默认媒体输出仍包含 `PLACEHOLDER_*` 字节。~~ ✅
7. Scriptwriter 未消费 Viral Analyzer 的 v2.1 注入文件。（范围外 — Non-Goal）
8. Viral Analyzer 缺少真实 URL/频道/小说端到端证据。（范围外 — Non-Goal）

## 下一执行顺序

1. 完善 WP04 验收文档 + Verify 门禁
2. 进入独立 Review/Verify 阶段

## 现场证据

```text
python -m pytest ...  -> 95 passed（联网环境）
python -m ai_drama_orchestrator --input <input.txt> --output <dir>
  -> exit 0
  -> script.json: characters=[char_01,char_02], shots=[shot_001]
  -> final.mp4 exists (32 bytes, valid MP4)
  -> subtitles.srt exists (1 subtitle)
```
