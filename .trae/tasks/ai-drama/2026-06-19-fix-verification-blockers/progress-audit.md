# AI 短视频工作流任务包进度审计

日期：2026-06-20
事实来源：代码、默认 pytest 入口、任务清单、机械门禁

## 总结

局部修复和测试基础已经建立，但三个原始产品任务包仍包含真实后端、真实输入 E2E 和媒体质量指标等未完成工作，因此保持 Implement/Fail。人工批准不能覆盖机械门禁。

## 当前状态

| Task Packet | Tasks | Verified AC | Mechanical state |
|---|---:|---:|---|
| pipeline-architecture | 45/59 | 3/12 production-level | implement / fail / fail |
| scriptwriter-skill | 50/57 | 12/15 local behavior | implement / fail / fail |
| viral-analyzer-skill | 51/56 | 4/13 real-input level | implement / fail / fail |
| fix-verification-blockers | 27/29 | 7 pass / 1 partial / 2 fail | implement / fail / fail |
| verification-truth-closure | active | pending independent verification | implement / pending / pending |

## Fresh local evidence

```text
python -m pytest -q
106 passed in 1.47s

python -m ai_drama_scriptwriter quick --help
--style-injection
--character-archetypes
--shot-pacing
--voice-style

python -m ai_drama_orchestrator --help
--style-injection
```

## Completed local capabilities

- Nine importable Python packages and CLIs.
- Stable character IDs when `known_ids` and `char_map` are provided.
- Regex display-name fallback when no mapping is provided.
- Viral injection bundle validation and Step 1/2/3 prompt consumption.
- Orchestrator Phase 2 injection-path pass-through.
- TTS-first duration-source rejection.
- SRT per-dialogue audio consumption.
- Cross-project asset copy implementation.
- Canonical root pytest discovery.

## Still open

- Real Image/Video provider adapters and async provider polling.
- Multi-provider production TTS evidence.
- Real URL/channel/novel Viral Analyzer E2E.
- 5/10/15-shot and long-text production pipeline cases.
- SSIM, final-video duration error, and audio/video sync measurement.
- Scriptwriter incremental editing, summary, feasibility report, and TTS plan outputs.
- Required worker reports for the legacy external-worker packets.

## Authority rule

Task state follows actual implementation, tests, signed evidence, and mechanical gates. User approval may change scope through a new plan, but cannot convert a failed gate into a pass.
