# Conversational Requirements Gate Design

Date: 2026-06-21  
Status: Approved by Ba Ba  
Scope: global Plan workflow, Jinli planner, task packets, mechanical Plan gate

## Problem

The current workflow proves that clarification happened, but not that the agent and Ba Ba reached the same understanding. A task can set `clarification_status: answered`, write a technically plausible plan, and still miss the intended user experience or implicit requirements.

Ba Ba is not expected to translate product ideas into code terminology. The planner must own that translation.

## Confirmed User Decisions

1. New systems, meaningful features, workflow/UI redesigns, and ambiguous changes use deep conversational discovery.
2. Clearly bounded bug fixes and small changes may use a fast track.
3. If classification is uncertain, default to deep discovery.
4. Deep discovery has no fixed question count. It ends when important uncertainty is resolved or Ba Ba asks to move to the summary.
5. One question is asked per turn in plain language.
6. Questions should offer two or three concrete choices, include Jinli's recommendation and reason, and still allow a free-form answer.
7. After requirements are confirmed, Jinli writes the technical design, self-execution prompt, acceptance criteria, and task packet.
8. Before implementation, Ba Ba sees and confirms a short plain-language summary rather than being asked to author technical instructions.

## Selected Architecture

Add a versioned requirement-understanding layer in front of the existing Plan gate:

```text
user idea
  -> change classification
  -> deep interview OR fast-track assessment
  -> plain-language teach-back
  -> requirements.md confirmation
  -> agent-authored execution-prompt.md
  -> technical analysis/spec/tasks
  -> Plan gate
  -> implementation
```

### Deep discovery

Deep discovery covers:

- desired outcome and underlying problem
- intended user and usage context
- end-to-end user journey
- information/content/data involved
- business rules and boundaries
- empty, error, cancellation, and recovery behavior
- desired quality and experience
- integrations, future pressure, and explicit non-goals
- implicit requirements inferred by the planner
- teach-back summary and user confirmation evidence

Each turn updates a decision ledger. The planner does not ask technical questions that it can answer from repository evidence.

### Fast track

Fast track is allowed only when all are true:

- expected behavior is concrete
- change is bounded
- no architecture or data ownership decision is introduced
- no user journey is being redesigned
- no unresolved high-impact implicit requirement exists
- verification is obvious and bounded

The reason must be recorded. Uncertainty routes to deep discovery.

### Agent-authored execution prompt

After confirmation, the planner generates `execution-prompt.md`. It contains:

- role and goal
- task packet truth sources
- confirmed decisions and implicit requirements
- accepted architecture
- allowed and forbidden paths
- non-goals
- acceptance criteria
- verification commands and expected results
- stop conditions
- evidence rule

Workers and future models execute from this prompt plus the task packet, not directly from the original conversational sentence.

## Mechanical Enforcement

New tasks created by `task-state.ps1 init` receive requirement-gate metadata:

```yaml
requirements_gate_version: 1
change_profile: unclassified
requirements_status: pending
requirements_doc: null
execution_prompt: null
fast_track_reason: null
```

For version 1 task packets, `task-guard.ps1 plan` blocks:

- unclassified changes
- deep tasks without confirmed `requirements.md`
- deep tasks marked `clarification_status: not_needed`
- fast tasks without a recorded fast-track reason
- missing or incomplete `execution-prompt.md`
- unresolved placeholders in required requirement artifacts

Legacy task packets without `requirements_gate_version` retain their current behavior.

## Alternatives Considered

| Option | Benefit | Failure | Decision |
|---|---|---|---|
| Keep current clarification checkbox | No migration work | Does not prove shared understanding | Rejected |
| Require a fixed questionnaire | Predictable | Overwhelms non-technical users and asks irrelevant questions | Rejected |
| Conversational discovery plus artifacts and gate | User-friendly and enforceable | Requires templates, tests, and Skill changes | Selected |

## External References

- GitHub Spec Kit clarification workflow: prioritize ambiguity, ask focused questions, and write answers back into the specification.
- LoopEngineering: agent-owned planning and execution loops after human intent is established.
- Grill Me / interview-style skills: iterative questioning before implementation.
- Requirements-engineering research: ambiguous requirements produce divergent implementations; models do not reliably surface their own misunderstanding.

## Non-Goals

- Do not force deep interviews for typos, isolated bugs, or exact small changes.
- Do not ask Ba Ba to choose programming frameworks, class names, or implementation details the planner can determine.
- Do not replace architecture research, mature-solution evidence, Living Spec, or verification.
- Do not make the original chat message the execution contract.

