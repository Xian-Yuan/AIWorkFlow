# Multi-Agent Task Packet Workflow

Date: 2026-06-17
Status: Active
Scope: Codex, OpenCode, Trae-compatible shared task execution

## Purpose

This workflow makes multi-AI collaboration explicit and mechanical.

The goal is not to let every model read the whole repository. The goal is to create a **task packet** that tells each model:

- what task exists
- what system or feature it belongs to
- where the authoritative plan lives
- which files it may touch
- what evidence it must return
- which automated checks decide completion

This prevents simple worker models from guessing context, drifting scope, or silently lowering quality.

## Lead / Worker / Reviewer Split

The default token-saving collaboration mode is:

- Lead agent publishes the task packet, work packages, acceptance criteria, and automated verification commands.
- Worker models execute only the assigned work package and return evidence in `reports/`.
- Reviewer/verifier independently runs the gates and checks evidence before accepting the task.

The lead is the cryptographic Issuer. The Worker cannot update task files or formal progress. A task is accepted only when:

- the task packet passes `task-guard.ps1`;
- every required worker report exists;
- every required worker report declares `Status: done`;
- every required worker report declares `Extra scope taken: no`;
- final verification maps command output back to acceptance criteria.
- the original Issuer signs the current packet/source/evidence/acceptance hashes;
- Archive is explicitly signed after verification and is never a side effect of Verify.

## Core Rule

Every non-trivial task must be represented by a runtime task packet:

```text
.trae/tasks/<project>/<YYYY-MM-DD-system-feature>/
  .task.yaml
  routing.md
  analysis.md
  requirements.md          # required for version-1 deep discovery
  execution-prompt.md
  spec.md
  tasks.md
  doc-impact.md
  work-packages/
  claims/
  reports/
```

OpenCode may mirror this under `.opencode/tasks/`. Future Codex-native task roots may mirror it under `.codex/tasks/`. The required file contract stays the same.

## Naming Convention

Task packet names use real date + project + system + feature:

```text
<YYYY-MM-DD>-<system>-<feature-or-requirement>
```

Examples:

```text
.trae/tasks/rts/2026-06-17-ai-patrol-statetree/
.trae/tasks/characterdesigntool/2026-06-17-prompt-constraint-editor/
.trae/tasks/_shared/2026-06-17-codex-workflow-adapter/
```

Do not name tasks after the model. Name tasks after the project fact being changed.

## Authority Layers

| Layer | File | Owner | Purpose |
|---|---|---|---|
| Global rules | `Docs/AI/*` | Human + lead agent | Stable cross-project workflow truth |
| Formal design | `Docs/superpowers/specs/YYYY-MM-DD-*-design.md` | lead agent | Durable design decisions |
| Implementation plan | `Docs/superpowers/plans/YYYY-MM-DD-*-plan.md` | lead agent | Durable execution plan |
| Runtime packet | `.trae/tasks/<project>/<task>/` | lead agent | Live phase state and work queue |
| Worker package | `work-packages/WPxx-*.md` | lead agent assigns, worker executes | Small bounded task for another model |
| Worker report | `reports/<agent>-WPxx-result.md` | worker | Evidence returned to lead agent |
| Final verification | `verification-report.md` | reviewer/verifier | Acceptance and automated evidence |

## Required Task Packet Files

### `.task.yaml`

Must include:

```yaml
task_name: <YYYY-MM-DD-system-feature>
project_type: ue5 | web | other
phase: plan | implement | review | verify | archived
clarification_status: not_needed | asked | answered
user_confirmed_plan: true | false
router_skill_loaded: true | false
requirements_gate_version: 1
change_profile: unclassified | deep | fast
requirements_status: pending | confirmed | not_required
requirements_doc: null | requirements.md
execution_prompt: null | execution-prompt.md
fast_track_reason: null | <concrete bounded-change reason>
review_result: pending | pass | fail
verify_result: pending | pass | fail
verification_report: null | <path>
fix_attempts: 0
worker_profile: none | ds4-flash
lead_verifier: null | codex
repair_loop_status: idle | repair_required | architecture_review | resolved
active_root_cause: null | RCxx
active_repair_package: null | work-packages/WPxx-fix-*.md
authority_profile: none | issuer-worker-v1
authority_status: draft | issued | worker_active | repair_issued | verified | archived
issuer_key_id: null | <public-key-digest>
issuer_sid: null | <windows-sid>
packet_version: 0 | <integer>
packet_digest: null | <sha256>
legacy_trust: not_applicable | legacy_untrusted | migration_required
archive_certificate: null | approvals/archive-vNNN.json
```

### `routing.md`

Must include:

- project type
- main skill / secondary skill
- collaboration mode
- `## Quality Gate`
- `## Work Package Policy`

Required `Work Package Policy` format:

```markdown
## Work Package Policy
- External workers: yes | no
- Task packet root: .trae/tasks/<project>/<task>
- Work packages required: yes | no
- Claim files required: yes | no
- Worker reports required before merge: yes | no
```

If `External workers: yes`, at least one complete `work-packages/*.md` file must exist before Plan can move to Implement. Placeholder-only work packages are blocked.

For requirement-gate version 1, routing must also contain either:

- `## Requirement Discovery Gate` for deep tasks, including confirmed plain-language summary and no unresolved high-impact questions; or
- `## Fast Track Assessment` proving the change is concrete, bounded, architecture-neutral, journey-neutral, free of unresolved high-impact implicit requirements, and easy to verify.

### `requirements.md`

Required for version-1 `change_profile: deep`.

This is the human-readable source of intent. It must include desired outcome, user/context, end-to-end experience, confirmed decisions, implicit requirements, boundaries/non-goals, success experience, resolved open questions, teach-back summary, and confirmation evidence.

It is not a technical design document. It lets a non-technical user recognize and correct what the planner believes should be built.

### `execution-prompt.md`

Required for both deep and fast version-1 packets.

The lead planner writes it after requirement confirmation. It must contain role, goal, task-packet truth sources, decisions, accepted architecture, allowed/forbidden paths, non-goals, acceptance criteria, verification commands, stop conditions, and the evidence rule.

Workers execute from this prompt plus the packet. They do not reinterpret the original chat request.

### `analysis.md`

Must include architecture and verification evidence:

```markdown
## Architecture Context

### System boundaries
- ...

### Dependency map
- ...

### Data and state ownership
- ...

### Integration points
- ...

## Mature Solution Evidence
...

## Acceptance Criteria
- AC01: ...

## Automated Verification Plan
- Command: ...
- Expected: ...
```

These sections are mandatory because they improve Codex and worker-model architecture ability. They force the plan to name boundaries, dependencies, state ownership, and verification before any edit begins.

### `spec.md`

Must remain the living behavior contract:

- scenarios
- progress summary
- decisions
- changelog
- verification state

### `tasks.md`

Must include:

- implementation checklist
- one task that verifies mature path and rejected shortcuts
- one task that runs automated verification
- one task that maps results back to acceptance criteria

Required task text markers:

```markdown
- [ ] Verify selected mature path was implemented and no rejected shortcut was introduced.
- [ ] Run automated verification and record command output in verification-report.md.
- [ ] Map implementation result to Acceptance Criteria in verification-report.md.
```

### `doc-impact.md`

Must follow `Docs/AI/28-Documentation-Governance-Workflow.md`.

## Work Packages

Work packages are how the lead model delegates bounded work to simple models.

Use template:

```text
.trae/scripts/work-package-template.md
```

Work package rules:

- A work package must have one owner model at a time.
- It must list allowed paths and forbidden paths.
- It must list exact read-first files.
- It must define done criteria.
- It must define the required report path.
- It must not ask the worker to infer architecture.
- It must not contain unresolved `<placeholder>` text.
- It must define a concrete verification command and expected result.

### DS4 Flash Worker Profile

When `.task.yaml` declares `worker_profile: ds4-flash`, the package must also declare a fresh context, one Root Cause ID, a bounded context budget, anti-gaming rules, and stop conditions. Worker reports must include a `Worker Authority` section proving that the worker did not set Review/Verify results, edit task state or acceptance criteria, or weaken tests.

Final acceptance remains with the lead verifier. Codex must independently rerun verification. Flash fallback verification is accepted only from a declared fresh context. Failed verification must use `worker-repair-loop.ps1 record-failure`; direct legacy failure transitions are blocked. The third consecutive failure for one root cause stops redistribution and enters architecture review.

See `Docs/AI/40-DS4-Flash-Worker-Repair-Loop.md`.

### Issuer-Worker Authority Profile

`authority_profile: issuer-worker-v1` replaces prompt-based role claims with Windows SID, non-exportable CNG signatures, packet sealing, signed worker capabilities, signed Review approval, and explicit signed Archive.

The Worker:

- cannot update `.task.yaml`, `tasks.md`, `spec.md`, work packages, approval, evidence, or Archive state;
- appends progress and creates one JSON result through `worker-submit.ps1`;
- cannot obtain a strong-mode capability under the Issuer SID.

The original Issuer seals every packet version, issues capabilities, independently reviews, publishes rejected repair work, and explicitly archives.

See `Docs/AI/41-Issuer-Worker-Authority-Separation.md`.

Good worker tasks:

- update a project doc from a known design
- add or adjust focused tests
- search existing code for named APIs
- summarize logs
- make a single-file scoped change
- verify a checklist

Bad worker tasks:

- choose system architecture
- invent new data model
- modify module boundaries
- change Lyra/GAS attachment chain
- decide final acceptance
- override a rejected shortcut

## Claim Files

Workers claim work by writing:

```text
claims/<agent-name>-WPxx.md
```

Use template:

```text
.trae/scripts/agent-claim-template.md
```

Claim files prevent edit collisions:

- one work package can have one active claim
- claim must list file paths
- lead agent resolves conflicting claims before merge

## Worker Reports

Workers return evidence to:

```text
reports/<agent-name>-WPxx-result.md
```

Use template:

```text
.trae/scripts/agent-result-template.md
```

Reports must include:

- changed files
- commands run
- command results
- acceptance criteria touched
- unresolved risks
- explicit "no extra scope taken" statement

For legacy tasks, the lead reviews Markdown reports before marking `tasks.md` items done. For authority-managed tasks, the Worker cannot mark tasks; the Issuer reviews signed JSON results and updates the checklist.

## Final Verification Report

Final verification must use:

```text
.trae/scripts/verification-report-template.md
```

`task-guard.ps1 verify` must fail unless the report contains:

- `## Automated Verification`
- `## Acceptance Criteria`
- `## Architecture Compliance`
- `## Test Evidence`
- `## Residual Risk`

This turns "looks done" into "evidence says done."

## Codex-Specific Requirements

Codex must use `skills/codex-project-router/SKILL.md` before project work.

Codex-specific rules:

- Use `.trae/tasks` as the runtime task root until `.codex/tasks` exists.
- Do not edit project files until `task-state.ps1 can-edit <task>` passes.
- Do not enter Implement until `task-guard.ps1 <task> plan` passes.
- Always create `Architecture Context`, `Acceptance Criteria`, and `Automated Verification Plan`.
- Always run or explain automated verification before final response.

## Mechanical Gates

`task-guard.ps1 plan` must check:

- required task files exist
- Mature Solution Evidence exists
- Quality Gate exists
- Architecture Context exists
- Acceptance Criteria exists
- Automated Verification Plan exists
- Work Package Policy exists
- if external workers are enabled, `work-packages/*.md` exists
- if external workers are enabled, every work package has required sections and no unresolved placeholders
- tasks include automated verification and acceptance mapping
- version-1 packets declare `change_profile: deep|fast`
- deep packets contain confirmed, complete `requirements.md` and `clarification_status: answered`
- fast packets contain a concrete reason and complete fast-track assessment
- both profiles contain a complete, non-templated `execution-prompt.md`
- requirement and prompt paths resolve inside the current task packet

`task-guard.ps1 implement` must check:

- all tasks are checked
- documentation governance passes
- project-specific mechanical checks pass
- if worker reports are required, `reports/*.md` exists for the work packages
- every required worker report contains changed files, commands, acceptance criteria, scope control, and residual risk sections
- every required worker report declares `Status: done`
- every required worker report declares `Extra scope taken: no`

`task-guard.ps1 verify` must check:

- all tasks are complete
- `verify_result: pass`
- `verification_report` points to a real file
- verification report contains required evidence sections
- for authority tasks, the current issuer-signed approval matches all bound hashes
- Verify never archives

`issuer-archive.ps1 archive` separately verifies accepted approval, packet/source/evidence/AC hashes, complete scenarios, resolved repair state, and original Issuer authority.

## Regression Requirements

`test-workflow-regression.ps1` must verify:

- valid task packet passes Plan gate
- missing Mature Solution Evidence fails
- missing Architecture Context fails
- missing Work Package Policy fails
- external workers enabled but no work package fails
- external workers enabled with a placeholder work package fails
- external workers enabled but required worker reports are missing fails
- external worker report with extra scope fails
- external worker report with `Status: done` and no extra scope passes
- valid verification report passes Verify gate
- weak verification report fails Verify gate
- DS4 policy and package omissions fail Plan
- DS4 worker authority claims fail Implement
- same-context Flash verification fails Verify
- failed DS4 verification creates immutable evidence and a narrower repair package
- third same-root failure enters architecture review without another package
- legacy failure transitions cannot bypass repair orchestration
- handoff publishes only the active repair package
- Worker cannot mutate task state or claim approval
- same-SID strong-mode capability issuance fails
- packet/source/evidence mutation invalidates authority artifacts
- Verify does not archive
- only explicit original-Issuer Archive succeeds
- docs indexes include this document
- Codex adapter skill exists

## Success Criteria

The workflow is working when:

- another model can open a task packet and know exactly what to do
- Codex can discover the same packet through `AGENTS.md` and `skills/codex-project-router`
- no model can enter Implement without architecture, quality, and verification evidence
- no task can archive without an evidence-based verification report
- no new meaningful feature can enter Implement from a raw, unconfirmed user sentence
- simple models can contribute without changing architecture decisions
