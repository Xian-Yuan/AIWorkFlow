---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
---

# Verification Before Completion

## Overview

Claiming work is complete without verification is dishonesty, not efficiency.

**Core principle:** Evidence before claims, always.

**Violating the letter of this rule is violating the spirit of this rule.**

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you cannot claim it passes.

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |

## Red Flags - STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", etc.)
- About to commit/push/PR without verification
- Trusting agent success reports
- Relying on partial verification
- Thinking "just this once"
- Tired and wanting work over
- **ANY wording implying success without having run verification**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler |
| "Agent said success" | Verify independently |
| "I'm tired" | Exhaustion ≠ excuse |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |

## Key Patterns

**Tests:**
```
✅ [Run test command] [See: 34/34 pass] "All tests pass"
❌ "Should pass now" / "Looks correct"
```

**Regression tests (TDD Red-Green):**
```
✅ Write → Run (pass) → Revert fix → Run (MUST FAIL) → Restore → Run (pass)
❌ "I've written a regression test" (without red-green verification)
```

**Build:**
```
✅ [Run build] [See: exit 0] "Build passes"
❌ "Linter passed" (linter doesn't check compilation)
```

**Requirements:**
```
✅ Re-read plan → Create checklist → Verify each → Report gaps or completion
❌ "Tests pass, phase complete"
```

**Agent delegation:**
```
✅ Agent reports success → Check VCS diff → Verify changes → Report actual state
❌ Trust agent report
```

## Why This Matters

From 24 failure memories:
- your human partner said "I don't believe you" - trust broken
- Undefined functions shipped - would crash
- Missing requirements shipped - incomplete features
- Time wasted on false completion → redirect → rework
- Violates: "Honesty is a core value. If you lie, you'll be replaced."

## When To Apply

**ALWAYS before:**
- ANY variation of success/completion claims
- ANY expression of satisfaction
- ANY positive statement about work state
- Committing, PR creation, task completion
- Moving to next task
- Delegating to agents

**Rule applies to:**
- Exact phrases
- Paraphrases and synonyms
- Implications of success
- ANY communication suggesting completion/correctness

## Multi-package pytest suites

When a project has multiple sibling Python packages under one root directory (e.g. `skills/pkg_a/`, `skills/pkg_b/`), pytest can fail in subtle ways:

### Pitfall: Stale `__pycache__` causes false test failures

Renamed test methods or modules leave old `.pyc` files behind. pytest may load the cached bytecode instead of the new source, causing `AssertionError` on old test names or missing new tests.

**Fix:** Before investigating test failures, clear `__pycache__`:
```bash
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null
find . -name "*.pyc" -delete 2>/dev/null
```
Then re-run. If failures disappear, the root cause was stale bytecode, not a code bug.

### Pitfall: `subprocess.run([sys.executable, "-m", <module>])` loses sys.path

Tests that launch a child Python process to verify CLI entrypoints (e.g. `python -m my_package validate`) fail with `ModuleNotFoundError` because the child process does not inherit pytest's `sys.path`.

**Fix:** Pass `PYTHONPATH` explicitly:
```python
import os
from pathlib import Path

skills_dir = str(Path(__file__).parent.parent.parent)  # adjust to project layout
env = {**os.environ, "PYTHONPATH": skills_dir}
result = subprocess.run(
    [sys.executable, "-m", "my_package", "validate", arg],
    capture_output=True, text=True, check=False, env=env,
)
```

### Pitfall: Root `conftest.py` needed for multi-package imports

When pytest's `rootdir` contains sibling packages, a root-level `conftest.py` is needed for:
1. Adding rootdir to `sys.path` so `from my_package import ...` works
2. `collect_ignore` to exclude non-test files (e.g. `test_real_run.txt`)

```python
# conftest.py at rootdir level
import sys
from pathlib import Path

collect_ignore = ["test_real_run.txt"]

_SKILLS_DIR = str(Path(__file__).parent)
if _SKILLS_DIR not in sys.path:
    sys.path.insert(0, _SKILLS_DIR)
```

### Pitfall: `pytest.ini` testpaths must include all new packages

When new packages are added, their test directories must be listed in `testpaths`. Missing entries cause `pytest -q` to skip those tests silently when run from root.

## The Bottom Line

**No shortcuts for verification.**

Run the command. Read the output. THEN claim the result.

This is non-negotiable.

## Third-Party Reports Are Not Evidence

When someone (another agent, a user, a CI log summary) tells you "all tests pass" or "task is complete", that is a **claim**, not evidence. You must still verify independently.

| Input | Wrong Response | Right Response |
|-------|---------------|----------------|
| "验证全部通过" | "✅ 任务完成！" | Read verification-report.md, check .task.yaml phase, confirm AC mapping |
| "27/27 tests pass" | "Great, all good!" | Run the test command yourself or read the actual output |
| User summarizes results | Echo the summary as confirmed | Read the source files, cross-check each claim |

**Why:** Trusting a summary without reading the underlying evidence is the same as skipping verification. The person summarizing may have missed a detail, the report may be stale, or the claim may not match the actual file state.

## Plain-Language Summary (通俗易懂总结)

After every verification, before closing the task, the verifier MUST provide a plain-language summary to Ba Ba:

**Format:**

1. **之前 vs 现在** — 用大白话对比"做之前是什么状态"和"做之后是什么状态"，不用任何技术术语
2. **一句话总结** — 用日常语言概括核心变化

**Rules:**

- No jargon. Write like explaining to a friend who doesn't code.
- Focus on *what Ba Ba can now do that they couldn't before*, not on implementation details.
- This is NOT optional. It is part of the verification gate.
- Write this summary AFTER all AC checks pass, as the final thing before marking the task complete.

**Example:**

> **之前：** 226 个视频总结存在磁盘上，但对话时完全看不到，每次从零开始。
> **现在：** 那些总结被读进数据库了，搜索"Token优化"能直接翻出相关视频段落。
> **一句话：** 视频总结从"死的文件"变成了"活的知识"。

This summary must also be appended to the task's verification-report.md under a `## Plain-Language Summary` section.