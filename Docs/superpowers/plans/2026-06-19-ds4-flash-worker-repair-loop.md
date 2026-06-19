# DS4 Flash Worker Repair Loop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a mechanically enforced DS4 Flash worker distribution and repair loop with immutable failure evidence, narrower retry packages, per-root-cause circuit breaking, and independent final verification.

**Architecture:** A new `worker-repair-loop.ps1` owns structured repair state and artifact publication. Existing task-state and task-guard scripts expose and enforce the state without absorbing orchestration logic. Templates and handoff generation define the DS4 worker contract, while a dedicated fixture suite proves retry, scope, evidence, and verifier-independence behavior.

**Tech Stack:** PowerShell 5.1, JSON, Markdown task packets, existing Comet task-state and task-guard scripts.

---

## File Structure

| File | Responsibility |
|---|---|
| `.trae/scripts/worker-repair-loop.ps1` | Initialize, record failure, publish repair artifacts, resolve root cause, report status |
| `.trae/scripts/test-worker-repair-loop.ps1` | Isolated fixtures for the complete DS4 repair lifecycle |
| `.trae/scripts/task-state.ps1` | Expose repair fields and block direct DS4 failure transition bypass |
| `.trae/scripts/task-guard.ps1` | Enforce DS4 policy, package/report contract, circuit state, verifier independence |
| `.trae/scripts/task-handoff.ps1` | Produce DS4 package-focused handoff |
| `.trae/scripts/test-workflow-regression.ps1` | Run the dedicated repair-loop regression |
| `.trae/scripts/work-package-template.md` | General package plus DS4 contract fields |
| `.trae/scripts/agent-result-template.md` | Worker authority and context declarations |
| `.trae/scripts/verification-report-template.md` | Verifier/worker identity and independence declarations |
| `.trae/tasks/_shared/templates/repair-state-template.json` | Repair state schema example |
| `.trae/tasks/_shared/templates/repair-evidence-template.md` | Immutable failure evidence format |
| `Docs/AI/40-DS4-Flash-Worker-Repair-Loop.md` | Operational workflow and commands |

### Task 1: Add the failing repair-loop regression suite

**Files:**
- Create: `.trae/scripts/test-worker-repair-loop.ps1`
- Test: `.trae/scripts/test-worker-repair-loop.ps1`

- [ ] **Step 1: Create fixture helpers**

Implement helpers that create a temporary task packet with:

```powershell
function New-RepairFixture {
    param([string]$Name, [bool]$Ds4Policy = $true)
    # Create .task.yaml, routing.md, analysis.md, spec.md, tasks.md,
    # doc-impact.md, work-packages/, reports/, verification-history/.
}
```

The fixture uses only `.trae/tasks/_shared/__repair_*` and removes it in `finally`.

- [ ] **Step 2: Add RED scenarios**

Add assertions for:

```text
S01 missing DS4 repair policy blocks Plan
S02 weak DS4 package blocks Plan
S03 first failure creates evidence/task/package/state
S04 second repair cannot add allowed paths
S05 third same-root failure enters architecture_review
S06 separate root causes have separate counters
S07 old evidence hash remains unchanged
S08 worker authority claim blocks Implement
S09 same-context Flash verification blocks Verify
S10 fresh-context Flash fallback passes Verify
S11 Codex independent verification passes Verify
S12 non-DS4 compatibility remains unchanged
```

- [ ] **Step 3: Run RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-worker-repair-loop.ps1
```

Expected: nonzero exit because `worker-repair-loop.ps1` and DS4 guard behavior do not exist.

### Task 2: Implement repair state and publication

**Files:**
- Create: `.trae/scripts/worker-repair-loop.ps1`
- Create: `.trae/tasks/_shared/templates/repair-state-template.json`
- Create: `.trae/tasks/_shared/templates/repair-evidence-template.md`
- Test: `.trae/scripts/test-worker-repair-loop.ps1`

- [ ] **Step 1: Implement common task resolution**

Support task names in `project/task` form and roots:

```powershell
$TaskRoots = @(".trae\tasks", ".opencode\tasks", ".codex\tasks")
```

Return task directory, YAML path, repair-state path, and standard subdirectories.

- [ ] **Step 2: Implement `init`**

Create `repair-state.json` only when absent:

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

Create `verification-history`, `work-packages`, and `reports`.

- [ ] **Step 3: Implement validated failure input**

Require:

```powershell
-Stage review|verify
-RootCauseId 'RC[0-9]{2,}'
-Summary <non-empty>
-FailedCommand <non-empty>
-Expected <non-empty>
-Actual <non-empty>
-AllowedPaths <non-empty array>
-ReadFirst <non-empty array>
```

Reject unresolved placeholders and paths containing `..`.

- [ ] **Step 4: Implement immutable evidence**

Use monotonically increasing global attempt IDs:

```text
verification-history/A001-review-RC01.md
```

Open with `CreateNew` semantics. If the path exists, fail rather than overwrite.

- [ ] **Step 5: Implement repair task and package publication**

Append:

```markdown
- [ ] R01: Repair RC01 attempt 1 using `work-packages/WP02-fix-rc01-a1.md`.
```

Generate a package containing the exact DS4 sections required by the design and a unique result path:

```text
reports/ds4-flash-WP02-result.md
```

- [ ] **Step 6: Implement scope narrowing**

For repeat attempts, parse the previous package's `Allowed Paths`. Every new path must already exist in the previous set. Reject expansions before writing any artifact.

- [ ] **Step 7: Implement circuit breaker**

When the same Root Cause ID reaches attempt 3:

```text
status = architecture_review
active_package = null
```

Create evidence and Rxx architecture-review task but no new work package.

- [ ] **Step 8: Implement `resolve` and `status`**

`resolve` requires independent pass evidence, clears the active root cause/package, sets status to `resolved`, resets the consecutive counter, and preserves total counters plus history.

- [ ] **Step 9: Run focused GREEN**

Run the new suite. Expected: publication and state scenarios pass; guard integration scenarios may still fail.

### Task 3: Integrate task state and guards

**Files:**
- Modify: `.trae/scripts/task-state.ps1`
- Modify: `.trae/scripts/task-guard.ps1`
- Test: `.trae/scripts/test-worker-repair-loop.ps1`
- Test: `.trae/scripts/test-workflow-regression.ps1`

- [ ] **Step 1: Extend task-state fields**

Add initialization and set support for:

```text
worker_profile
lead_verifier
repair_loop_status
active_root_cause
active_repair_package
```

Use enums for `repair_loop_status`:

```text
idle, repair_required, architecture_review, resolved
```

- [ ] **Step 2: Block failure-transition bypass**

When `worker_profile: ds4-flash`, direct:

```text
task-state transition ... review-fail
task-state transition ... verify-fail
```

must exit nonzero and instruct the lead to run `worker-repair-loop.ps1 record-failure`.

- [ ] **Step 3: Add DS4 Plan policy validation**

When routing declares `Worker profile: ds4-flash`, require:

```text
## Worker Repair Policy
Lead/verifier: codex or ds4-flash-fresh-context
Fresh context per repair: yes
Automatic repair package generation: yes
Maximum attempts per root cause: 3
Only lead may set Review/Verify pass: yes
Worker reports required before merge: yes
```

- [ ] **Step 4: Add DS4 package validation**

Require package sections:

```text
Worker Profile
Context Budget
Root Cause Boundary
Do Not Game The Gate
Stop Conditions
```

Require `Target model: deepseek-v4-flash` and `Fresh context required: yes`.

- [ ] **Step 5: Add worker authority validation**

Worker reports must declare:

```text
Review result set by worker: no
Verify result set by worker: no
Task state changed by worker: no
Acceptance criteria changed by worker: no
Tests weakened by worker: no
```

- [ ] **Step 6: Add repair-state gate checks**

Implement and Review gates fail when:

```text
repair_loop_status = architecture_review
active_repair_package has no done report
tasks.md contains an unchecked Rxx item
```

- [ ] **Step 7: Add verifier-independence checks**

For DS4 tasks, verification report must contain:

```text
Verifier role: lead
Worker model: deepseek-v4-flash
Verifier context: independent | fresh
Independent verification run by reviewer: yes
Worker success claims accepted without verification: no
```

If verifier model is Flash, require `Verifier context: fresh`.

- [ ] **Step 8: Run GREEN and legacy regression**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-worker-repair-loop.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-workflow-regression.ps1
```

Expected: all scenarios pass.

### Task 4: Upgrade package templates and handoff

**Files:**
- Modify: `.trae/scripts/work-package-template.md`
- Modify: `.trae/scripts/agent-result-template.md`
- Modify: `.trae/scripts/verification-report-template.md`
- Modify: `.trae/scripts/task-handoff.ps1`
- Test: `.trae/scripts/test-worker-repair-loop.ps1`

- [ ] **Step 1: Extend work-package template**

Add concrete DS4 fields and explain that non-DS4 packages may mark them `not-applicable`.

- [ ] **Step 2: Extend worker-result template**

Add `Worker Authority` declarations and fresh-context identity.

- [ ] **Step 3: Extend verification template**

Add verifier role, worker model, verifier model, and context identity.

- [ ] **Step 4: Update Plan-to-Implement handoff**

When routing contains `Worker profile: ds4-flash`, list ready work packages and output:

```text
Read only the assigned package and its Read First list.
Do not re-plan architecture.
Return the exact report path.
Start a fresh context for every repair package.
```

- [ ] **Step 5: Add handoff fixture assertions**

Expected: DS4 handoff names the package and does not tell Flash to execute the full `tasks.md`.

### Task 5: Integrate documentation and main regression

**Files:**
- Create: `Docs/AI/40-DS4-Flash-Worker-Repair-Loop.md`
- Modify: `Docs/AI/24-Pro-Flash-Model-Tiering.md`
- Modify: `Docs/AI/27-AI-Workflow-Refactor-Manifest.md`
- Modify: `Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md`
- Modify: `Docs/AI/README.md`
- Modify: `Docs/AI/.cache-manifest.md`
- Modify: `AGENTS.md`
- Modify: `.trae/scripts/test-workflow-regression.ps1`

- [ ] **Step 1: Write operational documentation**

Document normal flow, failure command, generated artifacts, circuit breaker, Flash-only fallback, and verifier authority.

- [ ] **Step 2: Update model-tiering rules**

Replace "Pro fixes issues directly" as the only path with:

```text
Codex/Pro verifies independently.
Failed implementation returns through a generated DS4 repair package.
```

- [ ] **Step 3: Update task-packet workflow**

Add repair-state, verification-history, Rxx tasks, and repair package contracts.

- [ ] **Step 4: Register the active component and indexes**

Add Doc 36 and the repair-loop script to the manifest, README, and cache manifest.

- [ ] **Step 5: Run documentation and workflow regressions**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-doc-guard.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-workflow-regression.ps1
```

Expected: both exit 0.

### Task 6: Independent verification and task closure

**Files:**
- Modify: `.trae/tasks/_shared/2026-06-19-ds4-flash-worker-repair-loop/tasks.md`
- Modify: `.trae/tasks/_shared/2026-06-19-ds4-flash-worker-repair-loop/spec.md`
- Modify: `.trae/tasks/_shared/2026-06-19-ds4-flash-worker-repair-loop/verification-report.md`
- Modify: `.trae/tasks/_shared/2026-06-19-ds4-flash-worker-repair-loop/.task.yaml`

- [ ] **Step 1: Run parser checks**

Use `[System.Management.Automation.Language.Parser]::ParseFile` for every modified PowerShell file. Expected: zero errors.

- [ ] **Step 2: Run all verification**

Run the dedicated repair suite, full workflow regression, doc guard, and docs tree check.

- [ ] **Step 3: Map AC01-AC13**

Record command evidence and results in `verification-report.md`.

- [ ] **Step 4: Run phase guards**

Run Implement, Review, and Verify gates in order with the task state transitions.

- [ ] **Step 5: Final self-review**

Confirm:

```text
No direct worker acceptance authority
No overwritten failure evidence
No retry after third same-root failure
No legacy task regression
No project code changes
```
