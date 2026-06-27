# Analysis: DS4 Flash Worker Repair Loop

## Problem

The current task packet workflow validates work packages and worker reports, but independent verification failure is not a managed workflow:

- `fix_attempts` is present but is not incremented automatically;
- failures do not create immutable evidence;
- `tasks.md` is not updated with repair items;
- no narrower repair package is generated;
- the three-attempt rule is a generic block, not per-root-cause;
- task handoff sends broad task context rather than a DS4-optimized bounded package;
- worker and verifier independence is described but not mechanically proven.

## Architecture Context

### System boundaries

In scope:

- work-package templates;
- worker result and verification templates;
- task state fields and failure transitions;
- repair-loop orchestration;
- task guard policy checks;
- handoff generation;
- workflow regression fixtures;
- AI workflow documentation.

Out of scope:

- invoking DS4 APIs;
- project code;
- model routing infrastructure;
- replacing the four workflow phases.

### Dependency map

```text
templates
  -> task-guard Plan validation
  -> task-handoff DS4 instructions

worker-repair-loop.ps1
  -> task packet resolver
  -> repair-state.json
  -> verification-history/
  -> tasks.md Rxx item
  -> work-packages/WPxx-fix
  -> .task.yaml state

task-state.ps1
  -> blocks direct DS4 review-fail/verify-fail bypass

test-worker-repair-loop.ps1
  -> authoritative workflow regression
```

### Data and state ownership

| State | Owner |
|---|---|
| Architecture and acceptance criteria | Lead |
| Worker assignment | Work package |
| Worker evidence | Unique report |
| Current phase | `.task.yaml` |
| Repair counters and active root cause | `repair-state.json` |
| Failed verification evidence | `verification-history/*.md` |
| Current verification summary | `verification-report.md` |

### Integration points

- `.trae/scripts/task-state.ps1`
- `.trae/scripts/task-guard.ps1`
- `.trae/scripts/task-handoff.ps1`
- `.trae/scripts/test-workflow-regression.ps1`
- `.trae/scripts/work-package-template.md`
- `.trae/scripts/agent-result-template.md`
- `.trae/scripts/verification-report-template.md`
- `Docs/AI/24-Pro-Flash-Model-Tiering.md`
- `Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md`

## Mature Solution Evidence

### Project-local evidence

- Existing work packages already define allowed paths, forbidden paths, exact verification, and report paths.
- Existing task guard already rejects missing reports and `Extra scope taken: yes`.
- Existing state transitions return Review/Verify failures to Implement.
- Existing `fix_attempts >= 3` check proves the repository intends to interrupt repeated repair loops, but lacks per-root-cause accounting and package regeneration.

### Official/framework evidence

- The repository's established evaluator-worker pattern requires worker isolation and independent verification.
- The current Comet state machine remains the framework; this feature extends failure transitions without replacing phases.

### External mature references

- Evaluator-optimizer workflows require explicit feedback and repeated bounded improvement.
- Retry systems need immutable attempt evidence, idempotent state updates, scoped retry budgets, and circuit breakers.

### Options compared

| Option | Pros | Cons | Decision |
|---|---|---|---|
| Documentation-only Flash guidance | Small change | Easily skipped; no automatic repair | Rejected |
| Add only a DS4 template | Better initial packages | No failure state, evidence, or circuit breaker | Rejected |
| Repair-loop orchestrator plus guards and templates | End-to-end, auditable, testable | More implementation and tests | Selected |
| General workflow engine rewrite | Maximum flexibility | Unnecessary blast radius | Rejected |

### Rejected shortcuts

- Use global `fix_attempts` as the same-root counter.
- Overwrite `verification-report.md` on each failure.
- Ask Flash to reread all architecture after every failure.
- Let the worker modify tests, acceptance criteria, or task state.
- Create another package after the third same-root failure.

### Selected mature path

Add a focused repair-loop script and state file, strengthen DS4-specific package and report contracts, integrate them with existing state and guard scripts, and cover the complete loop with regression fixtures.

## Acceptance Criteria

- AC01: DS4 tasks cannot pass Plan without a complete Worker Repair Policy and DS4 package.
- AC02: DS4 packages contain bounded context, exact commands, gate-protection rules, and unique reports.
- AC03: First independent failure creates immutable evidence, Rxx task, repair state, and a repair package.
- AC04: Subsequent same-root packages never expand allowed paths.
- AC05: Third same-root failure enters architecture review and creates no package.
- AC06: Different Root Cause IDs have independent counters.
- AC07: Existing failure evidence is never overwritten.
- AC08: Worker reports cannot claim Review or Verify pass.
- AC09: Same-context Flash self-verification is rejected.
- AC10: Fresh-context Flash fallback can verify only when explicitly declared.
- AC11: Codex independent verification can pass Review/Verify.
- AC12: Existing non-DS4 task packets remain compatible.
- AC13: Workflow, doc guard, and parser regressions pass.

## Automated Verification Plan

- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-worker-repair-loop.ps1`
- Expected: all repair-loop scenarios pass.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-workflow-regression.ps1`
- Expected: existing and new workflow scenarios pass.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-doc-guard.ps1`
- Expected: documentation governance passes.
- Command: PowerShell parser checks for modified scripts.
- Expected: zero parser errors.

