---
domain: ai
domain_path: ai/workflow
kg_node_id: node.doc-ai-ai-40-ds4-flash-worker-repair-loop-e613
t13_retro_classified_at: "2026-06-24T04:47:04Z"
kg_id: doc.ai.ai.40-ds4-flash-worker-repair-loop.e613

---

# DS4 Flash Worker Repair Loop

Date: 2026-06-19
Status: Active

## Purpose

This workflow delegates bounded implementation to DeepSeek V4 Flash while keeping architecture ownership and final acceptance with the lead verifier. A failed independent verification automatically becomes a narrower repair package instead of an open-ended request to "try again."

The default roles are:

- Lead and final verifier: Codex
- Implementation worker: `deepseek-v4-flash`
- Fallback verifier when Codex is unavailable: a new, explicitly fresh DS4 Flash context

For trusted execution, combine this profile with `authority_profile: issuer-worker-v1`. Model labels alone are not authority. See `Docs/AI/41-Issuer-Worker-Authority-Separation.md`.

## Enable The Profile

Set these task-state fields:

```yaml
worker_profile: ds4-flash
lead_verifier: codex
repair_loop_status: idle
active_root_cause: null
active_repair_package: null
```

Add this routing policy:

```markdown
## Worker Repair Policy
- Worker profile: ds4-flash
- Lead/verifier: codex
- Fresh context per repair: yes
- Automatic repair package generation: yes
- Maximum attempts per root cause: 3
- Same-context worker self-verification: forbidden
- Only lead may set Review/Verify pass: yes
```

`task-guard.ps1 plan` blocks the task when this policy or the DS4 work-package contract is incomplete.

## Worker Package Contract

Each DS4 package must:

- target `deepseek-v4-flash`;
- require a fresh context;
- contain one Root Cause ID;
- list exact Read First, Allowed Paths, and Forbidden Paths;
- define one bounded goal, an exact command, and expected output;
- forbid changes to tests, acceptance criteria, task state, verification evidence, and Review/Verify results;
- define stop conditions and one concrete return-report path.

`task-handoff.ps1` publishes only `active_repair_package` when one exists. Otherwise it lists ready DS4 packages. The worker does not receive a broad instruction to reinterpret the full task plan.

## Worker Report Contract

Legacy tasks use the Markdown declaration below. Authority-managed tasks require a signed capability and JSON submission through `worker-submit.ps1`; the Worker cannot edit task state or reports outside its exact capability path.

```markdown
## Worker Authority
- Review result set by worker: no
- Verify result set by worker: no
- Task state changed by worker: no
- Acceptance criteria changed by worker: no
- Tests weakened by worker: no
```

The Implement gate rejects missing or false declarations.

## Independent Verification

Codex independently reruns the commands and maps evidence to acceptance criteria. The verification report must declare:

- `Verifier role: lead`
- `Verifier model: codex`
- `Worker model: deepseek-v4-flash`
- `Verifier context: independent`
- `Independent verification run by reviewer: yes`
- `Worker success claims accepted without verification: no`

When Codex cannot be used, DS4 Flash may verify only from a fresh context with `Verifier context: fresh`. A same-context Flash verification is blocked.

## Failure And Automatic Repackaging

Do not use the legacy `review-fail` or `verify-fail` transition for DS4 tasks. For authority-managed tasks, only `issuer-review.ps1 reject` may record failure and publish repair work.

```powershell
.\.trae\scripts\worker-repair-loop.ps1 record-failure <task> `
  -Stage review `
  -RootCauseId RC01 `
  -Summary "Focused failure summary" `
  -FailedCommand "<exact command>" `
  -Expected "<expected result>" `
  -Actual "<actual result>" `
  -AllowedPaths "path/a;path/b" `
  -ReadFirst "spec.md;relevant/file"
```

The command:

1. appends immutable evidence under `verification-history/`;
2. increments the counter for that Root Cause ID;
3. returns the task to Implement;
4. appends an `Rxx` repair task;
5. creates a unique `WPxx-fix-<root>-aN.md`;
6. updates `repair-state.json` and task-state pointers.

Later packages for the same root cause may keep or reduce Allowed Paths, but may not add paths.

## Circuit Breaker

The third consecutive failure for one root cause:

- preserves the third evidence record;
- sets `repair_loop_status: architecture_review`;
- does not create another worker package;
- blocks the Implement gate.

The lead must then review the design or root-cause classification. A different root cause has its own counter and does not inherit another root cause's retry count.

## Resolution

After independent verification succeeds:

```powershell
.\.trae\scripts\worker-repair-loop.ps1 resolve <task> -RootCauseId RC01
```

This requires independent pass evidence, clears active repair pointers, resets the consecutive counter for that root cause, and retains total counters plus immutable history. A later recurrence begins again at consecutive attempt 1. Inspect current state with:

```powershell
.\.trae\scripts\worker-repair-loop.ps1 status <task>
```

## Automated Regression

Run:

```powershell
.\.trae\scripts\test-worker-repair-loop.ps1
.\.trae\scripts\test-workflow-regression.ps1
```

The focused suite covers policy enforcement, package quality, evidence immutability, scope narrowing, per-root counters, the three-attempt circuit breaker, worker authority, verifier independence, state-transition bypass prevention, and active-package handoff.
