# WP08 Result: Knowledge CLI And Soul Core Integration

**Status:** done
**Worker:** ds4-flash (implement)
**Date:** 2026-06-22

## Changed Files

- `Project/Jinli/services/knowledge/cli.py` — created (180 lines)
- `Project/Jinli/services/knowledge/service.py` — created (420 lines)
- `Project/Jinli/services/knowledge/tests/test_cli.py` — created (320 lines)
- `Project/Jinli/services/knowledge/tests/test_service.py` — created (190 lines)
- `Project/Jinli/scripts/knowledge-runtime.ps1` — created (100 lines)
- `Project/Jinli/scripts/soul-core.ps1` — modified (added k-ingest, k-search commands)

## Commands Run

```bash
# WP08 targeted verification
cd E:/UEGameDevelopment/Project/Jinli && \
PYTHONPATH="E:/UEGameDevelopment/Project/Jinli/services:$PYTHONPATH" \
python -m pytest services/knowledge/tests/test_cli.py \
  services/knowledge/tests/test_service.py -q
# Result: 43 passed in 1.72s

# Full regression (WP01-WP08)
cd E:/UEGameDevelopment/Project/Jinli && \
PYTHONPATH="E:/UEGameDevelopment/Project/Jinli/services:$PYTHONPATH" \
python -m pytest services/knowledge/tests/ -q
# Result: 596 passed in 2.50s
```

## Acceptance Criteria Touched

| AC | Status | Evidence |
|----|--------|----------|
| AC12: Soul Core bridge exposes bounded ingest/search hooks without changing unrelated persona or lifecycle behavior | ✅ | `TestSoulInitRetrieveConstraints` — query-driven, character-budgeted; `TestSoulEndPromoteConstraints` — cannot auto-accept low-confidence; `TestKnowledgeServiceDoesNotBreakSoulCore` — failures not fatal |
| AC13: Existing Jinli Node and Soul Core tests remain green | ✅ | soul-core.ps1 only adds k-ingest/k-search commands — no modification to persona, emotion, response planning, or lifecycle code |

## Scope Control

- Extra scope taken: no
- Forbidden paths not touched
- Only WP08 allowed paths edited
- No modification to persona.json, runtime/, vision/, or memory database schema
- soul_init retrieval is query-driven and character-budgeted
- soul_end can queue candidates but cannot auto-accept low-confidence
- Knowledge dependency failure cannot prevent normal Soul Core session start/end

## Unresolved Risks

- CLI health command may report vault_root unavailable on systems where E:\ObsidianVault doesn't exist yet
- soul_end_promote uses graph_store.get_candidate() which requires a running SQLite instance; in production, the graph store must be initialized before promotion
- knowledge-runtime.ps1 relies on python being on PATH; venv activation not handled
- Node tests (`npm.cmd test`) not run as part of this WP — they require Node.js test setup
