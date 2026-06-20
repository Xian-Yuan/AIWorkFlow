# Pipeline Extension Pitfalls

## Case: AIDramaProducer Orchestrator PHASES Mismatch

**Task**: `ai-drama/2026-06-20-text-first-creator-intelligence-studio-v3` WP07
**Date**: 2026-06-20

### Symptom

3 test failures in `ai_drama_orchestrator/tests/test_orchestrator.py`:

1. `test_build_default_handlers_registers_all_declared_phases` — `assert 'phase0_creator_intelligence' in orch.phase_handlers` fails
2. `test_dry_run_completes_all_phases` — `assert 7 == 9` (call_count vs len(PHASES))
3. `test_dry_run_short_text_skips_phase1_handler` — `assert 6 == 8` (same root cause)

### Root Cause (Two Layers)

**Layer 1 — `__pycache__` stale cache**: The test file had been renamed from `test_build_default_handlers_registers_seven` to `test_build_default_handlers_registers_all_declared_phases`, and the orchestrator.py had already registered 9 handlers. But `__pycache__` cached the old `.pyc` files, causing pytest to run the old test against the old module code.

**Layer 2 — Original code was actually correct**: After clearing cache, the 3 orchestrator tests passed. The actual PHASES/handler mismatch had already been fixed in a previous session; the cache was the only remaining issue.

### Fix

```bash
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null
python -m pytest skills/ai_drama_orchestrator/tests/ -v
```

Result: 9 passed in 0.17s

### Prevention

- After extending PHASES, always run: `python -m pytest skills/ai_drama_orchestrator/tests/ -v`
- Verify `len(orch.phase_handlers) == len(PHASES)` as a test invariant
- **When tests fail unexpectedly after code changes, clear `__pycache__` before debugging further**

---

## Case: pytest Module Import Failures in Multi-Package Python Project

**Date**: 2026-06-20

### Symptom

Two categories of failures:

1. `ModuleNotFoundError: No module named 'ai_drama_asset_generator'` — collection error
2. `subprocess` tests: `python -m ai_drama_xxx` fails with `No module named ai_drama_xxx`

### Root Cause

**Problem 1**: pytest's default import mode (`prepend`) doesn't resolve nested packages correctly when the rootdir is `skills/` but individual conftest.py files insert their own `SKILL_ROOT` into sys.path at position 0.

**Problem 2**: `subprocess.run` spawns a new Python process that doesn't inherit pytest's sys.path modifications.

### Fix

**Fix 1 — Root conftest.py** (`skills/conftest.py`):

```python
"""pytest configuration — root-level conftest for skills/"""
import sys
from pathlib import Path

collect_ignore = ["test_real_run.txt"]

# Ensure rootdir (skills/) is in sys.path for all test modules
_SKILLS_DIR = str(Path(__file__).parent)
if _SKILLS_DIR not in sys.path:
    sys.path.insert(0, _SKILLS_DIR)
```

**Fix 2 — subprocess tests** — add PYTHONPATH env and use absolute paths:

```python
import os
env = {**os.environ, "PYTHONPATH": str(Path(__file__).parent.parent.parent)}
fixture_path = str(Path(__file__).parent / "fixtures" / "style_pack_valid.json")
result = subprocess.run(
    [sys.executable, "-m", "ai_drama_creator_intelligence", "validate-style-pack", fixture_path],
    capture_output=True, text=True, check=False, env=env,
)
```

**Fix 3 — pytest.ini testpaths** — add new modules:

```ini
[pytest]
testpaths =
    ...
    ai_drama_creator_intelligence/tests
    ai_drama_preproduction_studio/tests
python_files = test_*.py
```

### Files Modified

| File | Change |
|------|--------|
| `skills/conftest.py` | NEW — sys.path + collect_ignore |
| `skills/pytest.ini` | Added new testpaths |
| `skills/ai_drama_creator_intelligence/tests/test_contracts.py` | subprocess: PYTHONPATH + absolute fixture path |
| `skills/ai_drama_preproduction_studio/tests/test_editorial.py` | Added `import os; from pathlib import Path`; subprocess: PYTHONPATH |
| `skills/ai_drama_scriptwriter/tests/test_injection.py` | subprocess: PYTHONPATH |

---

## AIDramaProducer Test Invocation

```bash
# Full suite (all modules, no exclusions needed after fixes)
cd E:/UEGameDevelopment/Project/AIDramaProducer
python -m pytest skills/ -v --tb=short

# Per-module
python -m pytest skills/ai_drama_creator_intelligence/tests/ -v
python -m pytest skills/ai_drama_preproduction_studio/tests/ -v
python -m pytest skills/ai_drama_orchestrator/tests/ -v
python -m pytest skills/ai_drama_viral_analyzer/tests/ -v
```

### Test Results (2026-06-20 post-fix)

| Module | Passed | Failed | Notes |
|--------|--------|--------|-------|
| creator_intelligence | 72 | 0 | Includes CLI subprocess test |
| preproduction_studio | 107 | 0 | Includes CLI subprocess test |
| orchestrator (all) | 27 | 0 | compatibility + orchestrator |
| viral_analyzer | 28 | 0 | All green |
| asset_generator | 3 | 0 | Fixed by conftest.py sys.path |
| scriptwriter | 27 | 0 | Fixed by PYTHONPATH env |
| other legacy | ~40 | 0 | All green |
| **Total** | **304** | **0** | **All green** |

### Project Structure (new skills)

- `skills/ai_drama_creator_intelligence/` — WP01-03 (contracts, source adapters, distillation, skill publisher)
- `skills/ai_drama_preproduction_studio/` — WP04-06 (intake, strategy, screenwriter, director, storyboard, art direction, editorial)
- `skills/ai_drama_orchestrator/` — WP07 (updated: text_first variant, compatibility facade)
- `skills/ai_drama_viral_analyzer/` — WP07 (updated: compatibility.py, facade.py added)

### Key Lesson: `__pycache__` Can Mask Real Fixes

When test names or assertions change but `__pycache__` caches old `.pyc` files, pytest may run the old test against new code (or new test against old code). This produces confusing failures that look like code bugs but are actually cache staleness. **Always clear `__pycache__` when test failures don't match the code you're reading.**
