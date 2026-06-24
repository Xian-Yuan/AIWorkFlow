# WP03 Result: Video Source And Transcript Adapters

**Status:** done
**Worker:** ds4-flash (implement)
**Date:** 2026-06-21

## Changed Files

| File | Action | Lines |
|------|--------|-------|
| `services/knowledge/sources/__init__.py` | created | 22 |
| `services/knowledge/sources/base.py` | created | 82 |
| `services/knowledge/sources/ytdlp_source.py` | created | 225 |
| `services/knowledge/sources/vsummary_adapter.py` | created | 225 |
| `services/knowledge/transcript.py` | created | 156 |
| `services/knowledge/requirements.txt` | modified | +1 |
| `services/knowledge/tests/fixtures/video_sources/__init__.py` | created | 0 |
| `services/knowledge/tests/fixtures/video_sources/youtube_captions.srt` | created | — |
| `services/knowledge/tests/fixtures/video_sources/youtube_captions.vtt` | created | — |
| `services/knowledge/tests/fixtures/video_sources/bilibili_captions.srt` | created | — |
| `services/knowledge/tests/fixtures/video_sources/vsummary_transcript_cleaned.json` | created | — |
| `services/knowledge/tests/fixtures/video_sources/vsummary_summary.json` | created | — |
| `services/knowledge/tests/fixtures/video_sources/vsummary_transcript_raw.json` | created | — |
| `services/knowledge/tests/fixtures/video_sources/duplicate_captions.srt` | created | — |
| `services/knowledge/tests/fixtures/video_sources/invalid_timestamps.srt` | created | — |
| `services/knowledge/tests/fixtures/video_sources/vsummary_workspace/BV1UF7m68E1K/transcript.cleaned.json` | created | — |
| `services/knowledge/tests/fixtures/video_sources/vsummary_workspace/BV1UF7m68E1K/summary.json` | created | — |
| `services/knowledge/tests/fixtures/video_sources/vsummary_workspace/BV1UF7m68E1K/.cache/whisper/transcript.raw.json` | created | — |
| `services/knowledge/tests/fixtures/video_sources/vsummary_workspace/BV1RAWONLY00/.cache/whisper/transcript.raw.json` | created | — |
| `services/knowledge/tests/test_video_sources.py` | created | 330 |
| `services/knowledge/tests/test_vsummary_adapter.py` | created | 252 |

## Commands Run

```bash
# WP03 targeted verification
cd /e/UEGameDevelopment/Project/Jinli && \
PYTHONPATH="E:/UEGameDevelopment/Project/Jinli/services:$PYTHONPATH" \
python -m pytest services/knowledge/tests/test_video_sources.py services/knowledge/tests/test_vsummary_adapter.py -q
# Result: 58 passed in 0.17s

# Full regression (WP01+WP02+WP03)
cd /e/UEGameDevelopment/Project/Jinli && \
PYTHONPATH="E:/UEGameDevelopment/Project/Jinli/services:$PYTHONPATH" \
python -m pytest services/knowledge/tests/ -q
# Result: 230 passed in 0.55s
```

## Acceptance Criteria Mapping

| AC | Status | Evidence |
|----|--------|----------|
| YouTube, Bilibili, and vsummary fixtures produce the same normalized transcript contract | ✅ | `test_all_sources_produce_same_normalized_format` — 三源归一化结构一致（start_seconds, end_seconds, text, source, language, source_hash） |
| Access denied and unsupported statuses are distinguishable | ✅ | `test_access_denied_and_unsupported_distinguishable` — ACCESS_DENIED ≠ UNSUPPORTED_SOURCE |
| No media download, login bypass, or live network runs during focused tests | ✅ | 所有 58 个测试使用 fixture 和 mock，零网络调用 |
| Source protocol with probe and acquire_transcript | ✅ | `SourceProtocol` (runtime_checkable Protocol) + `YtdlpSource` + `VsummaryAdapter` |
| yt-dlp Python API with download disabled | ✅ | `YtdlpSource` 使用 `skip_download: True` + `extract_flat: False` |
| Restrict to YouTube and Bilibili | ✅ | `classify_url()` 只识别 YouTube/Bilibili，其余返回 UNSUPPORTED |
| Map login/DRM/paywall to explicit statuses | ✅ | private → ACCESS_DENIED, DRM → ACCESS_DENIED, 不重试 |
| vsummary workspace adapter with revision | ✅ | `VSUMMARY_REVISION = "4de6dbbd376c29d35380d8d8fcc2094821b2b3f9"` |
| Normalize captions into ordered transcript entries with start/end/text/language/source/source_hash | ✅ | `normalize_transcript()` — 排序+去重+元数据+hash |
| All default tests use fixtures, no network | ✅ | 全部 58 个测试离线通过 |

## Scope Control

- **Extra scope taken:** no
- All files within Allowed Paths
- No files in Forbidden Paths touched
- No vsummary source code inspected
- No credentials, cookies, or DRM tools accessed

## Worker Authority

- Review authority: none
- Verify authority: none

## Unresolved Risks

- yt-dlp 对 B站的支持可能随 B站 API 变化而失效（上游风险，非本包可控）
- vsummary workspace 路径依赖运行时配置（`workspace_root`），需在集成时确保路径正确
- `VsummaryAdapter.acquire_transcript` 清洗转录和原始转录的语言优先级：文件内语言优先于参数传入
