---
name: vsummary
version: 2.1.0
description: "Batch video download and AI summarization from Bilibili favorites. yt-dlp download -> vsummary ASR+LLM summarization -> progress resume -> provider auto-switch."
trigger: user wants to batch download/summarize Bilibili videos, process favorites, run vsummary batch task, summarize videos
---

# vsummary Batch Video Download and AI Summarization

## Environment Prerequisites

| Component | Location/Requirement |
|-----------|---------------------|
| vsummary backend | `http://127.0.0.1:8001` |
| vsummary frontend | `http://127.0.0.1:4173` |
| vsummary venv | `E:\Obsidian\tools\vsummary\.venv\Scripts\python.exe` |
| yt-dlp | Installed in vsummary venv |
| Cookie | `E:\Obsidian\tools\vsummary\.env` -> `BILIBILI_COOKIE=...` |
| Video directory | `E:\Obsidian\tools\vsummary\videos\__playground__\` |
| Workspace directory | `E:\Obsidian\tools\vsummary\workspace\__playground__\` |
| Data directory | `E:\Obsidian\tools\vsummary\data\` |
| GPU | RTX 4060 Ti 8GB -> only 1 concurrent Whisper instance |

## Core Workflow

### Quick Start (One Command)

```bash
cd E:\Obsidian\tools\vsummary && .venv\Scripts\python.exe -u batch_pipeline.py --all
```

This runs: refresh favorites -> download -> ASR + LLM summarize -> report.

### Step-by-Step

#### Step 1: Refresh Bilibili favorites data

```bash
cd E:\Obsidian\tools\vsummary && .venv\Scripts\python.exe -c "
import httpx, json, time, random
# ... see references/bilibili-favorites-refresh.md for full script
"
```

Or use browser mode if Cookie expired:
```bash
cd E:\Obsidian\tools\vsummary && .venv\Scripts\python.exe bili_fav_ai_v3.py
```

#### Step 2: Download new videos (yt-dlp)

```bash
cd E:\Obsidian\tools\vsummary && .venv\Scripts\python.exe batch_pipeline.py --download
```

Auto-skips already-downloaded videos. Saves progress to `data/download_progress.json`.

#### Step 3: ASR + AI Summarize

```bash
cd E:\Obsidian\tools\vsummary && .venv\Scripts\python.exe -u batch_pipeline.py --summarize
```

Or use the new workflow system (recommended):
```bash
cd E:\Obsidian\tools\vsummary && .venv\Scripts\python.exe workflow.py run
```

### New Workflow System (v2, recommended)

**Location**: `E:\Obsidian\tools\vsummary\workflow.py` + `workflow/` subdirectory

**Commands**:
```bash
cd E:\Obsidian\tools\vsummary
python workflow.py status          # Check provider status
python workflow.py test            # Test all providers
python workflow.py reset           # Reset provider state
python workflow.py run             # One-click run
python workflow.py run --max-duration 600   # Custom duration threshold
```

**Modules**:
- `workflow/provider_pool.py` — 3-tier API key pool (free/personal/premium)
- `workflow/vsummary_adapter.py` — vsummary API adapter
- `workflow/pipeline.py` — Video processing pipeline (duration filter -> import -> generate -> verify)
- `workflow/notifier.py` — Multi-channel notifications
- `workflow.py` — CLI entry point

**Important**: `workflow.py` does NOT include download step. New videos must first be downloaded with `batch_pipeline.py --download`, then processed with `workflow.py run`. For the full pipeline including download, use `batch_pipeline.py --all`.

## Provider Configuration

### 3-Tier API Key Pool

| Tier | Provider | Model | API Key Location | Usage |
|------|----------|-------|-----------------|-------|
| free (priority 0) | Zhipu GLM-4-Flash | glm-4-flash | `ZHIPU_API_KEY` in .env | Free, stable, first choice |
| personal (priority 1) | NVIDIA DeepSeek V4-Pro | deepseek-ai/deepseek-v4-pro | `NVIDIA_API_KEY` in .env | Better quality, rate-limited |
| premium (priority 2) | MiniMax M1 | MiniMax-M1 | `MINIMAX_API_KEY` in .env | Best quality, paid |

**Recommended mixed strategy**:
- Primary: MiniMax M1 (best quality)
- Fallback: NVIDIA DS-V4-Pro (handles ~70% of MiniMax failures)
- Quick mode: Zhipu GLM-4-Flash (rough summaries for short videos)

### Provider State Machine

- `active` — normal available
- `rate_limited` — 429 triggered, auto-cooldown 5-10 min
- `invalid` — 401/403, permanently disabled
- `cooldown` — 3 consecutive failures, passive cooldown
- `untested` — not yet tested

State persists in `~/.vsummary/provider_state.json`.

### Switching Provider Manually

```bash
# Switch to MiniMax M1
curl -X PUT http://127.0.0.1:8001/api/provider-settings \
  -H "Content-Type: application/json" \
  -d '{"llm_provider":"minimax","openai_base_url":"https://api.minimaxi.com/v1","openai_model":"MiniMax-M1","openai_api_key":"<your-key>"}'
```

## Progress Query

```bash
# Quick stats
cd E:\Obsidian\tools\vsummary && .venv\Scripts\python.exe -c "
from pathlib import Path
ws = Path(r'E:\Obsidian\tools\vsummary\workspace\__playground__')
vd = Path(r'E:\Obsidian\tools\vsummary\videos\__playground__')
clean = [f.stem for f in vd.iterdir() if f.suffix=='.mp4' and '.f' not in f.stem and '.temp' not in f.name]
has_summary = sum(1 for d in ws.iterdir() if d.is_dir() and (d/'summary.json').exists())
print(f'Downloaded: {len(clean)}, Summarized: {has_summary}, Remaining: {len(clean)-has_summary}')
"

# Workflow status
cd E:\Obsidian\tools\vsummary && .venv\Scripts\python.exe workflow.py status
```

## Pitfall List

| Pitfall | Details |
|---------|---------|
| generate API is synchronous | Call blocks until ASR+LLM complete. Set timeout=600-1200s. Do NOT poll status API. |
| NVIDIA real rate limit ~50 videos | Not "5s limit". Triggers 429 after ~50 consecutive calls. |
| workflow.py does NOT include download | New videos MUST use `batch_pipeline.py --download` first |
| 3 no-audio videos must skip | `BV1JY7k6aEMw`, `BV1chjV67EVs`, `BV1cxX9BSEs3` — ASR will hang |
| Timeout but summary.json exists | Means actual success, count as success |
| MiniMax think tag pollution | M1 may return `<think>...</think>` wrapping content. Strip with regex. |
| MiniMax 422 new_sensitive (1027) | Retry 1-2 times usually recovers |
| Zhipu GLM-4-flash structure quality | Weaker chapter structuring, occasional empty segments. Use for short videos only. |
| GPU OOM with concurrent Whisper | Concurrency MUST = 1 on RTX 4060 Ti 8GB |
| ffmpeg exit 69 | Audio track corrupted. Skip and re-download with different codec params. |
| ffmpeg exit 4294967274 | AV1 with no audio track. Cannot fix, mark as skip. |
| B站 412 WAF | Cookie expired. Use browser mode to refresh. |
| Long videos auto-skipped | `--max-duration 1800` (30min) default. Adjust threshold for longer videos. |
| "AI 概况生成失败" empty error | LLM internal failure on certain videos. Retry once usually works. |
| VAD filter causes empty transcript | Non-speech content filtered out. Mark as bad_audio, do not retry. |

## vsummary API Quick Reference

| Endpoint | Method | Usage |
|----------|--------|-------|
| `/api/health` | GET | Health check |
| `/api/provider-settings` | GET | Current LLM config |
| `/api/linked/bilibili/resolve/video` | POST | Resolve B站 video metadata |
| `/api/videos/{sid}/{vid}/download` | POST | Download video |
| `/api/videos/{sid}/{vid}/generate` | POST | Generate AI summary (synchronous, timeout=600-1200s) |
| `/api/import/local/playground` | POST | Import local video (multipart form-data, NOT JSON) |

## Status Auto-Update

After running vsummary, update the workflow status:

```python
# Add to end of workflow.py or batch_pipeline.py
from pathlib import Path
import json
from datetime import datetime

status_file = Path(r"E:\UEGameDevelopment\skills\vsummary\status.yaml")
status = {
    "name": "vsummary",
    "last_run": datetime.now().isoformat(),
    "status": "completed",  # or "error"
    "progress": f"{done}/{total} videos summarized ({pct}%)",
    "provider": current_provider,
    "next_steps": next_steps,
    "error": None,  # or last error message
    "updated_by": "workflow.py",
    "updated_at": datetime.now().isoformat(),
}

# Write as YAML (simple format, no dependency needed)
lines = [f"{k}: \"{v}\"" if isinstance(v, str) else f"{k}: {v}" for k, v in status.items() if v is not None]
status_file.write_text("\n".join(lines) + "\n", encoding="utf-8")
```

Then sync the registry:
```bash
python E:\UEGameDevelopment\.trae\scripts\sync-workflow-registry.py
```


## Post-Summarize Hook (obsidian-autopoiesis)

After vsummary completes a batch summarization run, the following post-hook chain fires automatically to classify, evaluate, and link new knowledge:

### Hook Chain

`
vsummary completes
  -> obsidian-classify.ps1 -Batch -Apply -SourceDir "E:\ObsidianVault\JinliKG\Sources\Videos"
  -> obsidian-evolve.ps1 -Batch -ExtractGene -SourceDir "E:\ObsidianVault\知识"
  -> obsidian-link-discover.ps1 -Method tag-cooccurrence -DryRun
`

### How to Run

After workflow.py run or atch_pipeline.py --all completes:

`powershell
# Step 1: Classify new summaries into 知识/ directories
E:\UEGameDevelopment\.trae\scripts\obsidian-classify.ps1 -Batch -Apply -SourceDir "E:\ObsidianVault\JinliKG\Sources\Videos"

# Step 2: Extract Genes from high-value knowledge
E:\UEGameDevelopment\.trae\scripts\obsidian-evolve.ps1 -Batch -ExtractGene -Apply -SourceDir "E:\ObsidianVault\知识"

# Step 3: Discover cross-note associations (DryRun first, then -Apply when ready)
E:\UEGameDevelopment\.trae\scripts\obsidian-link-discover.ps1 -Method tag-cooccurrence -DryRun
`

### Idempotency

Each step is idempotent:
- **classify**: same kg_id already at target = skip (no re-classification)
- **evolve**: same gene_id (sha1 of domain:trigger) = skip (no re-extraction)
- **link-discover**: existing [[target]] in ## Related = skip (no duplicate links)

### Safety

- D1: Old files in JinliKG/ are NEVER modified or deleted (only redirect stubs created)
- D7: All destructive ops require explicit -Apply flag
- Post-hook does NOT auto-delete, auto-archive, or auto-approve anything

### Integration Point

This hook is defined in skills/obsidian-autopoiesis/SKILL.md and registered in skills/ai-workflow-registry/registry.yaml.

## Related Skills

- `ai-workflow-registry` — discovery and registration system
- `vsummary-deploy` (Hermes) — deployment and configuration details
- `jinli-memory-architecture` — Obsidian knowledge graph integration

