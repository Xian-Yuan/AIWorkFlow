# DS4 Flash Worker Repair Loop Design

Date: 2026-06-19
Status: Approved
Scope: shared multi-agent task packet workflow

## Goal

Use DeepSeek V4 Flash as a bounded implementation worker while Codex remains the lead reviewer and final verifier. When independent review fails, automatically preserve evidence, narrow the next assignment, and republish a repair package without asking Flash to reinterpret the whole architecture.

## Roles

| Role | Default owner | Authority |
|---|---|---|
| Lead | Codex | Architecture, task packet, scope, acceptance criteria |
| Worker | DS4 Flash | One bounded work package |
| Reviewer/Verifier | Codex in an independent context | Review result, verify result, archive |
| Flash-only fallback | Fresh DS4 Flash context | Independent re-verification only; never same-context self-acceptance |

Only the lead/verifier may declare Review or Verify pass. Worker reports are evidence inputs, not acceptance decisions.

## Normal Flow

```text
Lead publishes task packet and DS4 work package
-> DS4 Flash implements only the assigned package
-> DS4 Flash returns a structured report
-> Codex independently reviews and verifies
-> pass: continue to Verify/archive
-> fail: record immutable evidence and enter repair loop
```

## Repair Flow

```text
Independent failure
-> assign Root Cause ID
-> append immutable failure evidence
-> increment global and per-root-cause attempts
-> return task to Implement
-> add Rxx repair item to tasks.md
-> create narrower WPxx-fix package
-> DS4 Flash starts a fresh context and executes only that package
-> Codex independently re-verifies
```

On the third consecutive failure for the same Root Cause ID:

- no new repair package is created;
- repair status becomes `architecture_review`;
- automatic redistribution stops;
- the lead must review architecture, acceptance criteria, or task decomposition.

## State Model

Task-level fields remain in `.task.yaml`:

```yaml
worker_profile: ds4-flash
lead_verifier: codex
repair_loop_status: idle
active_root_cause: null
active_repair_package: null
fix_attempts: 0
```

Structured repair history lives in `repair-state.json`:

```json
{
  "schema_version": 1,
  "status": "idle",
  "worker_profile": "ds4-flash",
  "max_attempts_per_root_cause": 3,
  "active_root_cause": null,
  "attempts_by_root_cause": {},
  "total_attempts_by_root_cause": {},
  "latest_attempt": 0,
  "active_package": null,
  "latest_evidence": null
}
```

The JSON file is the machine-readable repair state. `.task.yaml` exposes the small set of fields needed by existing guards and agents.

## Immutable Evidence

Every failed review or verification creates:

```text
verification-history/
  A001-review-RC01.md
  A002-verify-RC01.md
```

The current `verification-report.md` receives an append-only repair-loop index pointing to those files. Existing failure evidence is never overwritten.

Each evidence file contains:

- stage;
- verifier and worker profile;
- Root Cause ID;
- attempt number;
- failed command;
- expected and actual result;
- bounded root-cause statement;
- allowed repair paths;
- generated repair package or architecture-review outcome.

## DS4 Flash Work Package Contract

Every DS4 package must include:

- `Worker Profile`;
- `Context Budget`;
- `Root Cause Boundary`;
- exact `Allowed Paths` and `Forbidden Paths`;
- minimal `Read First` files;
- one concrete goal;
- exact commands and expected results;
- `Do Not Game The Gate`;
- stop conditions;
- unique report path;
- `Extra scope taken: no`.

DS4 Flash must not:

- modify tests solely to make failures disappear;
- weaken acceptance criteria;
- set Review or Verify pass;
- edit `.task.yaml`, `verification-report.md`, or repair history;
- make architecture decisions;
- read the full repository when the package lists sufficient context.

## Scope Narrowing

For repeated failures of one Root Cause ID:

- the new allowed paths must be a subset of the previous package;
- no new acceptance criteria may be added;
- the package must contain the newest failed command and evidence;
- the package must state what was removed or narrowed;
- one package handles one root cause.

The next package may keep the same single file when the new failure narrows to a smaller function or assertion, but it may not expand to additional files.

## Mechanical Enforcement

### Plan gate

For `Worker profile: ds4-flash`, require:

- Worker Repair Policy;
- initial DS4 work package;
- explicit Codex lead/verifier;
- fresh-context requirement;
- maximum attempts set to 3;
- worker reports required.

### Implement gate

Require:

- one valid report for every work package;
- all reports declare `Status: done`;
- all reports declare `Extra scope taken: no`;
- no repair package is pending;
- repair status is not `architecture_review`;
- Flash did not claim Review or Verify authority.

### Review/Verify gates

Require independent evidence:

- verifier role is lead;
- verifier model differs from the worker, or Flash-only fallback declares a fresh context;
- worker claims were independently rerun;
- every active repair item is complete;
- repair status is `idle` or `resolved`.

## Script Interface

```powershell
.\.trae\scripts\worker-repair-loop.ps1 init <task>

.\.trae\scripts\worker-repair-loop.ps1 record-failure <task> `
  -Stage review `
  -RootCauseId RC01 `
  -Summary "Focused root cause" `
  -FailedCommand "exact command" `
  -Expected "expected result" `
  -Actual "actual result" `
  -AllowedPaths "path/a","path/b" `
  -ReadFirst "file/a","file/b"

.\.trae\scripts\worker-repair-loop.ps1 status <task>

.\.trae\scripts\worker-repair-loop.ps1 resolve <task> -RootCauseId RC01
```

`record-failure` performs the state update, evidence append, task update, and package generation atomically from the workflow's perspective. If validation fails before publication, it leaves the prior task packet unchanged.

## Testing

Regression tests cover:

1. DS4 policy missing at Plan.
2. DS4 package missing required sections.
3. First failure creates A001, R01, and a repair package.
4. Second failure creates a narrower package.
5. Expanded repair scope is blocked.
6. Third same-root failure enters architecture review and creates no package.
7. Different root causes maintain separate counters.
8. Existing evidence is never overwritten.
9. Worker report cannot claim Review or Verify pass.
10. Same-context Flash verification is rejected.
11. Fresh-context Flash fallback is accepted when explicitly configured.
12. Codex independent verification is accepted.

## Non-Goals

- Automatically invoking an external DS4 API.
- Letting workers edit architecture or acceptance criteria.
- Replacing the Comet Plan/Implement/Review/Verify phases.
- Retrying unrelated root causes in one package.
- Continuing automatic repair beyond the third same-root failure.
