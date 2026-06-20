# Conversational Requirements Gate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a conversational requirement-understanding gate that separates deep discovery from fast fixes and requires an agent-authored execution prompt before implementation.

**Architecture:** Extend the shared task-packet schema with versioned requirement metadata and two new artifacts, then enforce them in the Plan guard. Update Jinli planning Skills and global workflow docs so human intent is gathered in plain language and translated by the planner into technical execution instructions.

**Tech Stack:** PowerShell workflow scripts, Markdown Skills/templates/docs, repository regression tests.

---

### Task 1: Add failing workflow regression scenarios

**Files:**
- Modify: `.trae/scripts/test-workflow-regression.ps1`

- [ ] Add a version-1 deep task fixture without `requirements.md` and assert the Plan gate blocks it.
- [ ] Add a version-1 fast task fixture without a reason and assert the Plan gate blocks it.
- [ ] Add complete deep and fast fixtures and assert both pass.
- [ ] Run the workflow regression and confirm the new scenarios fail because the gate is not implemented.

### Task 2: Extend task state and templates

**Files:**
- Modify: `.trae/scripts/task-state.ps1`
- Create: `.trae/tasks/_shared/templates/requirements-template.md`
- Create: `.trae/tasks/_shared/templates/execution-prompt-template.md`
- Modify: `.trae/tasks/_shared/templates/task-package-prompt-template.md`

- [ ] Add versioned requirement fields to newly initialized tasks.
- [ ] Allow validated state updates for requirement classification and artifact paths.
- [ ] Add complete templates without unresolved workflow ambiguity.

### Task 3: Implement the Plan mechanical gate

**Files:**
- Modify: `.trae/scripts/task-guard.ps1`

- [ ] Validate `change_profile`.
- [ ] Validate deep discovery confirmation and required sections.
- [ ] Validate fast-track reason and assessment.
- [ ] Validate the self-authored execution prompt and stop conditions.
- [ ] Keep legacy packets compatible when the version field is absent.
- [ ] Run regression scenarios and confirm they pass.

### Task 4: Upgrade planning Skills

**Files:**
- Modify: `skills/smart-requirements/SKILL.md`
- Modify: `skills/金璃小天才/SKILL.md`
- Modify: `skills/ue-project-router/SKILL.md`
- Modify: `skills/codex-project-router/SKILL.md`

- [ ] Replace the fixed-question clarification rule with deep/fast classification.
- [ ] Require one plain-language question per turn, recommendation, teach-back, and decision ledger.
- [ ] Require implicit-needs confirmation and a final plain-language playback.
- [ ] Require the planner to author `requirements.md` and `execution-prompt.md`.
- [ ] Add rationalization counters for “the user probably means” and “the task is too small”.

### Task 5: Update authoritative workflow documentation

**Files:**
- Create: `Docs/AI/45-Conversational-Requirements-Discovery-Workflow.md`
- Modify: `Docs/AI/27-AI-Workflow-Refactor-Manifest.md`
- Modify: `Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md`
- Modify: `Docs/AI/README.md`
- Modify: `Docs/AI/.cache-manifest.md`

- [ ] Document the human/agent responsibility split.
- [ ] Document deep discovery, fast track, artifacts, and gate behavior.
- [ ] Index the new workflow and mark it volatile.

### Task 6: Verify and publish evidence

**Files:**
- Modify: `.trae/tasks/_shared/2026-06-21-conversational-requirements-gate/tasks.md`
- Create: `.trae/tasks/_shared/2026-06-21-conversational-requirements-gate/verification-report.md`

- [ ] Run focused requirement-gate regression.
- [ ] Run full workflow regression.
- [ ] Run documentation guard and docs index checks.
- [ ] Map evidence to every acceptance criterion.
- [ ] Verify selected mature path was implemented and no rejected shortcut was introduced.
- [ ] Run automated verification and record command output in verification-report.md.
- [ ] Map implementation result to Acceptance Criteria in verification-report.md.

