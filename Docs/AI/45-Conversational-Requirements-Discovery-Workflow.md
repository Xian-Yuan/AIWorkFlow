---
domain: ai
domain_path: ai/workflow
kg_node_id: node.doc-ai-ai-45-conversational-requirements-discovery-workflow-1433
t13_retro_classified_at: "2026-06-24T04:47:04Z"
kg_id: doc.ai.ai.45-conversational-requirements-discovery-workflow.1433

---

# Conversational Requirements Discovery Workflow

Date: 2026-06-21  
Status: Active  
Scope: global Plan workflow, non-technical user collaboration, task-packet requirement gate

## Purpose

This workflow prevents an agent from turning an incomplete or misunderstood request directly into code.

The human decision maker is responsible for goals, experience, boundaries, and confirmation. The Plan Agent is responsible for asking useful questions, discovering implicit needs, researching technical choices, and translating confirmed intent into a professional design and execution prompt.

`clarification_status: answered` alone is not proof of shared understanding.

## Change Classification

### Deep discovery

Use deep discovery for:

- new systems or modules
- meaningful new features
- workflow or UI/UX redesign
- architecture, integration, or data ownership changes
- multi-system changes
- unclear users, usage journey, boundaries, or success criteria
- unresolved high-impact implicit requirements

Uncertain classification defaults to deep discovery.

### Fast track

Fast track is permitted only when every condition is true:

- expected behavior is concrete
- scope is bounded
- no architecture or data ownership choice is introduced
- no complete user journey is redesigned
- no high-impact implicit requirement remains unresolved
- verification is obvious and bounded

The Plan Agent records the reason and assessment in `routing.md#Fast-Track-Assessment`. “It looks small” is not evidence.

## Deep Discovery Conversation

### One question per turn

Ask only the highest-impact unresolved question. Use plain scenario language rather than code terminology.

Prefer:

- two or three concrete choices
- a recommended choice with a reason
- permission for the user to answer freely

Do not ask the user to choose class names, frameworks, database types, or other technical details the planner can research.

### No fixed round limit

The interview ends when important uncertainty is resolved, not when a question count is reached.

If the user asks to move on, perform the final requirement playback first. Any unresolved high-impact choice must still be shown explicitly.

### Teach-back

After each answer:

1. restate the decision in ordinary language;
2. explain what it changes in the expected experience;
3. surface newly inferred implicit requirements;
4. ask the next highest-impact question.

At the end, replay the full requirement picture:

- problem and desired outcome
- intended user and context
- end-to-end experience
- confirmed choices
- confirmed, rejected, or deferred implicit requirements
- non-goals
- success experience
- remaining high-impact questions

Silence and lack of objection are not confirmation.

## Required Artifacts

### `requirements.md`

Required for deep discovery. It is the human-readable intent source and contains:

- Desired Outcome
- Intended User and Context
- End-to-End Experience
- Confirmed Decisions
- Implicit Requirements
- Boundaries and Non-Goals
- Success Experience
- Open Questions (`None.` before implementation)
- Teach-Back Summary
- User Confirmation Evidence

### `execution-prompt.md`

Required for both deep and fast version-1 task packets. It is authored by the Plan Agent after intent is known and contains:

- Role
- Goal
- Task Packet Truth Sources
- Confirmed Decisions
- Accepted Architecture
- Allowed Paths
- Forbidden Paths
- Non-Goals
- Acceptance Criteria
- Verification Commands
- Stop Conditions
- Evidence Rule

The original conversational request is not the implementation contract. Executors read the generated prompt and task packet.

## Task State Contract

New tasks initialized by `task-state.ps1` include:

```yaml
requirements_gate_version: 1
change_profile: unclassified
requirements_status: pending
requirements_doc: null
execution_prompt: null
fast_track_reason: null
```

Deep packet:

```yaml
change_profile: deep
requirements_status: confirmed
requirements_doc: requirements.md
execution_prompt: execution-prompt.md
clarification_status: answered
```

Fast packet:

```yaml
change_profile: fast
requirements_status: not_required
requirements_doc: null
execution_prompt: execution-prompt.md
fast_track_reason: <concrete bounded-change reason>
```

## Mechanical Enforcement

For `requirements_gate_version: 1`, `task-guard.ps1 plan` blocks:

- `change_profile: unclassified`
- unsupported gate versions
- deep tasks without confirmed, complete `requirements.md`
- deep tasks using `clarification_status: not_needed`
- unresolved content in `Open Questions`
- fast tasks without a concrete reason and complete assessment
- missing, empty, templated, or structurally incomplete `execution-prompt.md`
- requirement or execution artifacts that resolve outside the current task-packet directory

`task-state.ps1 can-edit` rechecks core artifact existence and status so deleting requirement evidence after Plan cannot silently retain edit authorization.

Legacy packets without `requirements_gate_version` keep the previous behavior. New packets must not omit the version to bypass the gate.

## Plan Agent Responsibility

After human confirmation, the planner—not the user—writes:

- technical option comparison
- selected mature architecture
- `analysis.md`
- `spec.md`
- `tasks.md`
- `execution-prompt.md`
- acceptance criteria
- verification plan

The user receives a short plain-language plan summary for final confirmation.

## External Basis

- GitHub Spec Kit: ambiguity prioritization, focused clarification, and specification write-back.
- LoopEngineering: human intent followed by agent-owned planning and execution loops.
- Interview-style planning Skills such as Grill Me: iterative questioning before implementation.
- Requirements-engineering research: ambiguity causes divergent implementations and cannot be reliably corrected by assuming the model will notice its own misunderstanding.

## Verification

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-workflow-regression.ps1
```

The regression includes new-task metadata, incomplete deep packet rejection, missing prompt rejection, unjustified fast-track rejection, valid deep/fast acceptance, Skill contract checks, and legacy compatibility.
