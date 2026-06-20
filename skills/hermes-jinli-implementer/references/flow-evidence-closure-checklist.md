# Flow Evidence Closure Checklist

Source: 2026-06-20 session where content was complete but verify failed due to flow evidence gaps.

## Problem Pattern

"Content done ≠ Flow evidence closed." Five files need state updates when implementation finishes, or `task-guard verify` will FAIL even though all deliverables exist.

## Checklist (run before `task-guard verify`)

| # | File | What to check | Common lag pattern |
|---|------|---------------|-------------------|
| 1 | `spec.md` | All Scenario `Status` fields: `[ ] pending` → `[x] done` | Scenarios left pending even after implementation |
| 2 | `tasks.md` | All tasks use `- [x]`, no `- [ ]` or blockquote alternatives | Using `> T3.x: ...` instead of `- [x] T3.x: ...` causes evidence inconsistency |
| 3 | `.task.yaml` | `spec_exists: true`, `spec_scenario_count`/`spec_scenarios_done` correct, `verification_report` points to existing file (relative to task packet root), `phase` matches current stage | `spec_exists: false`, `verification_report: null`, `phase: implement` when should be `verify` |
| 4 | `doc-impact.md` | "Planned/Future" → "Done", list actual created/modified files | Still says "Planned" after files are created |
| 5 | `verification-report.md` | Must contain all 4 standard sections: `## Automated Verification`, `## Acceptance Criteria`, `## Architecture Compliance`, `## Test Evidence` | Missing any section → task-guard rejects |
| 6 | `verification_report` path | `.task.yaml` path is relative to task packet root; file must exist at that path | Wrote report to root but yaml says `reports/verification-report.md` |

## verification-report.md Required Sections

1. **## Automated Verification** — Gate command outputs (task-guard, doc-guard, can-edit, etc.)
2. **## Acceptance Criteria** — Per-AC status + evidence (command output or file read)
3. **## Architecture Compliance** — Path conventions, ownership, no rejected shortcuts
4. **## Test Evidence** — File existence checks, command outputs, Select-String matches

## verification_report Path Rule

The `verification_report` field in `.task.yaml` is resolved relative to the task packet root directory (e.g., `.trae/tasks/_shared/2026-06-20-xxx/`). If `write_file` placed the report at the packet root, the yaml value should be `verification-report.md`, not `reports/verification-report.md`.

Verify with: `ls -la <task-packet-root>/<yaml-value>`

## tasks.md Format Rule

All completed tasks must use `- [x]` format. Do NOT use:
- Blockquote (`> T3.x: ...`) — doesn't block task-guard but creates evidence inconsistency with verification report
- `- [~]` or `- [-]` — not recognized as complete
- `- [ ] T3.x: (future)` — blocks task-guard

Future/deferred tasks that are NOT in current packet scope should be moved to `spec.md` Non-Goals or removed from `tasks.md` entirely.
