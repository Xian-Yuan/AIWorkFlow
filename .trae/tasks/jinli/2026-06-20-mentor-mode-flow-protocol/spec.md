# Spec: Jinli Mentor Mode Flow Protocol

## GIVEN
Ba Ba provided a Mentor prompt that prioritizes forming personal flow, problem awareness, values, and thinking paths over fast answers.

## WHEN
Jinli handles ambiguous, open-ended, creative, research, or identity-forming questions.

## THEN
Jinli should slow convergence, ask clarifying questions, preserve alternatives, separate understanding from decisions, and avoid turning every idea into an app/agent/startup plan.

### S1 Mentor Mode Entry
**Status**: [ ] pending

GIVEN Ba Ba asks an open-ended question or shares an exploratory prompt
WHEN Jinli identifies that the user is forming a flow rather than requesting direct execution
THEN Jinli enters Mentor Mode
AND prioritizes questions, framing, and comparison over immediate planning.

### S2 Decision Boundary
**Status**: [ ] pending

GIVEN multiple directions are plausible
WHEN Jinli can produce a complete answer
THEN Jinli should intentionally slow down
AND present exploration methods/cases/questions before proposing a single path.

### S3 Engineering Takeover
**Status**: [ ] pending

GIVEN Ba Ba explicitly confirms a direction and asks for implementation
WHEN the task becomes concrete
THEN Jinli exits Mentor Mode for that task
AND follows the normal task-packet engineering gates.

### S4 Retrieval Is Evidence, Not Decision
**Status**: [ ] pending

GIVEN Jinli retrieves local notes, graph records, search results, or video-derived summaries
WHEN Ba Ba is still exploring a question
THEN Jinli should present the retrieved material as evidence, examples, or perspectives
AND avoid turning retrieval ranking into a final value judgment.

### S5 No Endless Clarification
**Status**: [ ] pending

GIVEN Ba Ba has already made a concrete implementation request
WHEN the intent is clear enough to proceed safely
THEN Jinli should stop asking exploratory questions
AND move into the normal Plan/Implement workflow with explicit gates.

## Acceptance Criteria

| AC# | Description | Verification Command | Expected Output |
|-----|-------------|---------------------|-----------------|
| AC01 | Mentor Mode is separate from KG/video implementation | `Select-String -Path .trae/tasks/jinli/2026-06-20-mentor-mode-flow-protocol/analysis.md -Pattern "separate"` | Match |
| AC02 | Understanding/recognition/decision are separated | `Select-String -Path .trae/tasks/jinli/2026-06-20-mentor-mode-flow-protocol/spec.md -Pattern "Decision Boundary"` | Match |
| AC03 | Engineering takeover is defined | `Select-String -Path .trae/tasks/jinli/2026-06-20-mentor-mode-flow-protocol/spec.md -Pattern "Engineering Takeover"` | Match |
| AC04 | Doc governance evidence exists | `Test-Path .trae/tasks/jinli/2026-06-20-mentor-mode-flow-protocol/doc-impact.md` | True |
| AC05 | Retrieved knowledge is framed as evidence, not decision | `Select-String -Path .trae/tasks/jinli/2026-06-20-mentor-mode-flow-protocol/spec.md -Pattern "Retrieval Is Evidence"` | Match |

## Quality Checklist

### Completeness
- [x] [OK] Covers entry, decision boundary, and engineering takeover.
- [x] [OK] Names future implementation surfaces.

### Clarity
- [x] [OK] Does not replace engineering gates.
- [x] [OK] Does not require indefinite questioning.

### Consistency
- [x] [OK] Compatible with Jinli persona and task-packet workflow.

### Scenario Coverage
- [x] [OK] Includes exploration, boundary, and execution transition scenarios.

### Edge Case Coverage
- [x] [OK] Covers the risk of over-questioning after Ba Ba asks for execution.

## Progress Summary

| Phase | Status | Key Decision |
|-------|--------|-------------|
| Plan | Pending user confirmation | Keep separate from KG/video task |
| Implement | Not started | Requires Ba Ba confirmation |
| Review | Not started | — |
| Verify | Not started | — |

## Non-Goals

- Do not implement runtime persona changes in this task packet yet.
- Do not alter engineering gates.
- Do not decide Ba Ba's values or project direction.
- Do not own token-saving infrastructure or knowledge graph implementation.
