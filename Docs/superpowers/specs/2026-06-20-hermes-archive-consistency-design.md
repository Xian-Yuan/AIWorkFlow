# Hermes Archive Consistency Repair Design

## Goal

Make the archived Hermes Workflow Integration packet internally consistent without changing Hermes runtime behavior.

## Selected Approach

Use a separate hotfix task packet because the original task is already archived and its edit gate correctly rejects further implementation. The hotfix updates only archival facts and documentation, then verifies both the hotfix and the original archived task.

## Changes

- Synchronize the original `spec.md` to Archive, 13/13 AC, 7/7 scenarios, and completed Review/Verify.
- Set the original `.task.yaml` scenario counters to `7/7`.
- Replace the superseded verification-report addendum with a final archive addendum, record 66/66, and remove the obsolete stdio residual risk.
- Update `Docs/AI/39-Hermes-Workflow-Integration.md` to Active/Archived and 23 Python tests.
- Add an automated archive-consistency regression that fails when these facts drift.

## Non-Goals

- No Hermes runtime, MCP, plugin, profile, launcher, credential, or policy behavior changes.
- No modification of authoritative task-state or task-guard scripts.
- No Git commit, push, or provider credential mutation.

## Verification

- Archive consistency regression passes.
- Hermes deterministic suites remain 66/66.
- Both Hermes profile doctor commands exit 0.
- Documentation governance passes.
- Original task Verify and Archive gates pass.
- Hotfix task Verify and Archive gates pass.

