# Mem0 Integration Guide (Phase 2)

## Current Status

**Phase 1 (Active):** File-based failure memory with local retrieval via `memory-retrieve.ps1`.
**Phase 2 (Planned):** Optional Mem0 vector search layer on top of file-based memory.

## Architecture

```
User Request
    |
    v
memory-retrieve.ps1 (Phase)
    |
    +---> memory-index.md (tag-based scoring, always active)
    |         |
    |         v
    |     Docs/Memory/failures/*.md (file-based, source of truth)
    |
    +---> Mem0 (optional, only if enabled + healthcheck passes)
              |
              v
          Vector search for semantically similar failures
```

## Prerequisites

1. Mem0 server running locally or remotely
2. Python 3.10+ with `mem0ai` package: `pip install mem0ai`
3. Mem0 config at `.trae/memory/mem0.config.json`

## Enable Mem0

### Step 1: Start Mem0 server

```bash
# Option A: Local Mem0 (recommended for Phase 2)
pip install mem0ai
mem0 server start --port 8888

# Option B: Docker
docker run -p 8888:8880 mem0/mem0-server
```

### Step 2: Update config

Edit `.trae/memory/mem0.config.json`:
```json
{
  "enabled": true,
  "mode": "local-experiment",
  "endpoint": "http://127.0.0.1:8888",
  "project": "UEGameDevelopment",
  "use_for_scopes": ["router", "implement"],
  "sync_only_promoted_failures": true,
  "max_results_router": 3,
  "max_results_implement": 2,
  "timeout_ms": 1500
}
```

### Step 3: Verify health

```powershell
.trae\scripts\mem0-healthcheck.ps1
# Expected: {"status": "available", ...}
```

### Step 4: Sync existing failures

```powershell
.trae\scripts\mem0-sync.ps1
# Syncs all promoted failures with mem0_sync_status: not_synced
```

### Step 5: Enable in retrieval

In `memory-retrieve.ps1` calls, set `-UseMem0 $true`:
```powershell
.trae\scripts\memory-retrieve.ps1 -Phase plan -ProjectType ue5 -Scope router -Module router -Tags @("dom:save") -Limit 2 -UseMem0 $true
```

## Sync Rules

| Rule | Description |
|------|-------------|
| Only promoted failures | Candidates are never synced to Mem0 |
| File is source of truth | Mem0 is a cache, not the authority |
| Sync on promotion | When a candidate is promoted to failure, sync to Mem0 |
| Stale detection | If file is updated after sync, mark mem0_sync_status: stale |
| Failed sync retry | Failed syncs retry on next mem0-sync.ps1 run |

## Retrieval Strategy

| Scope | Local (always) | Mem0 (if enabled) | Total |
|-------|:---:|:---:|:---:|
| Router | top 2 | top 1 | top 3 |
| Implement | top 1 | top 1 | top 2 |
| Review/Verify | 0 | 0 | 0 (independent verification) |

## Fallback Behavior

1. If Mem0 healthcheck fails -> use local only
2. If Mem0 search times out (>1500ms) -> use local only
3. If Mem0 returns 0 results -> use local only
4. Local results always take priority over Mem0 results
5. Duplicate detection: if Mem0 returns same memory as local, deduplicate

## Prohibited

- Do not sync candidates to Mem0 (only promoted failures)
- Do not treat Mem0 as source of truth (files are authoritative)
- Do not use Mem0 for Review/Verify phases (independent verification)
- Do not block on Mem0 (always fall back to local)
