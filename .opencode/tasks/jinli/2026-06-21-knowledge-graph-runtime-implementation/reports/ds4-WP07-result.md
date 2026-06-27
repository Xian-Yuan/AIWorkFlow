# WP07 Result: Visual Candidate Extension

**Status:** done
**Worker:** ds4-flash (implement)
**Date:** 2026-06-22

## Changed Files

- `Project/Jinli/services/knowledge/keyframes.py` — created (330 lines)
- `Project/Jinli/services/knowledge/visual_enrichment.py` — created (280 lines)
- `Project/Jinli/services/knowledge/tests/test_keyframes.py` — created (470 lines)
- `Project/Jinli/services/knowledge/tests/test_visual_enrichment.py` — created (250 lines)

## Commands Run

```bash
# WP07 targeted verification
cd E:/UEGameDevelopment/Project/Jinli && \
PYTHONPATH="E:/UEGameDevelopment/Project/Jinli/services:$PYTHONPATH" \
python -m pytest services/knowledge/tests/test_keyframes.py \
  services/knowledge/tests/test_visual_enrichment.py -q
# Result: 40 passed in 0.19s

# Full regression (WP01-WP07)
cd E:/UEGameDevelopment/Project/Jinli && \
PYTHONPATH="E:/UEGameDevelopment/Project/Jinli/services:$PYTHONPATH" \
python -m pytest services/knowledge/tests/ -q
# Result: 553 passed in 2.24s
```

## Acceptance Criteria Touched

| AC | Status | Evidence |
|----|--------|----------|
| AC11: Visual analysis produces candidate observations and keyframe evidence only; it cannot directly accept graph mutations | ✅ | `TestCandidateOnly::test_observations_are_candidates` — all candidates PENDING; `TestProhibitedMethods` — no accept_candidate or export methods; `VisualEnricher._PROHIBITED_METHODS` documented constraint |

## Scope Control

- Extra scope taken: no
- Forbidden paths not touched
- Only WP07 allowed paths edited
- No modification to vision/ service or screen capture code
- No calls to graph_store.accept_candidate() from visual enrichment
- Keyframe extraction disabled by default (KeyframeConfig.enabled=False)

## Unresolved Risks

- Perceptual hash uses PIL Image.getdata() which is deprecated in Pillow 14; future migration to get_flattened_data() needed
- FFmpeg-based frame extraction depends on FFmpeg being available on PATH; tests use injected fake runner
- Visual enrichment gateway integration relies on WorkerGateway.submit_describe_keyframe_job(); real Ollama minicpm-v4.6 model may be slow or unavailable
- PGM format used in tests for fake frames; real production uses JPEG from FFmpeg
