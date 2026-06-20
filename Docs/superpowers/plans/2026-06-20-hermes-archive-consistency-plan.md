# Hermes Archive Consistency Repair Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Repair archival state drift in the completed Hermes Workflow Integration task and make that consistency mechanically testable.

**Architecture:** A separate hotfix task owns the repair because the original packet is archived. A focused PowerShell regression checks the canonical YAML, Living Spec, verification report, and operations document without changing Hermes runtime behavior.

**Tech Stack:** PowerShell, Markdown, YAML-like task state, pytest, Hermes CLI.

---

### Task 1: Establish the hotfix packet

**Files:**
- Create: `.trae/tasks/_shared/2026-06-20-hermes-archive-consistency/*`

- [ ] Publish routing, analysis, spec, tasks, and doc-impact evidence.
- [ ] Run the Plan gate.
- [ ] Transition to Implement.
- [ ] Confirm Can-Edit passes.

### Task 2: Add the failing consistency regression

**Files:**
- Create: `.trae/scripts/test-hermes-archive-consistency.ps1`

- [ ] Assert original phase/archive/review/verify/scenario counters.
- [ ] Assert Living Spec says Archive, 7/7 scenarios, and completed T7.
- [ ] Assert verification report says final archive, 66/66, and stdio covered.
- [ ] Assert Docs/AI/39 says Archived and 23/23 Python tests.
- [ ] Run the test and confirm it fails before documentation repair.

### Task 3: Repair archived facts

**Files:**
- Modify: `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/.task.yaml`
- Modify: `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/spec.md`
- Modify: `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/verification-report.md`
- Modify: `Docs/AI/39-Hermes-Workflow-Integration.md`

- [ ] Synchronize final archive state and counters.
- [ ] Preserve historical evidence while making the final addendum authoritative.
- [ ] Remove obsolete stdio risk and record the five subprocess tests.
- [ ] Re-run the consistency regression and confirm it passes.

### Task 4: Verify and close

- [ ] Run all 66 deterministic tests.
- [ ] Run Sync Check and both Profile doctor commands.
- [ ] Run documentation governance.
- [ ] Verify original task Verify and Archive gates.
- [ ] Write the hotfix verification report and map all ACs.
- [ ] Verify selected mature path was implemented and no rejected shortcut was introduced.
- [ ] Run automated verification and record command output in verification-report.md.
- [ ] Map implementation result to Acceptance Criteria in verification-report.md.

