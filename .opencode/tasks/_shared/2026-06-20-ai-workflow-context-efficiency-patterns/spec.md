# Spec: AI Workflow Context Efficiency Patterns

## GIVEN

The technical reference identified reusable workflow improvements: MUSE-style skill-level `.memory.md`, the 2-Action Rule, systematic Plan-phase CodeGraph use, and Fable/Claude-Code-style agent operating-system patterns such as evidence-backed progress claims and explicit task handoff prompts.

## WHEN

The global AI workflow is improved for context efficiency, lower drift, and better dependency analysis.

## THEN

The improvements should become task-packet-compatible workflow patterns, separate from Jinli Mentor Mode and KG/video implementation.

### S1 Skill-Level Memory
**Status**: [x] done

GIVEN a skill repeatedly succeeds, fails, or reveals boundary conditions
WHEN that experience is reusable across future tasks
THEN the skill should record concise lessons in `skills/<skill-name>/.memory.md`
AND the memory should not replace `SKILL.md` instructions.

### S2 2-Action Findings Rule
**Status**: [x] done

GIVEN an agent performs two search/read actions during Plan research
WHEN new useful evidence has been discovered
THEN the agent should record a concise finding in the task packet before continuing
AND avoid carrying all findings only in volatile chat context.

### S3 CodeGraph Plan Evidence
**Status**: [x] done

GIVEN a Plan task needs dependency or impact analysis across more than three files
WHEN CodeGraph is available for the relevant project
THEN the Plan should use CodeGraph or explicitly explain why it was not applicable
AND summarize the evidence in `analysis.md`.

### S4 Separate Workflow Ownership
**Status**: [x] done

GIVEN these patterns affect global AI workflow
WHEN they are task-packaged
THEN they should live in a `_shared` workflow packet
AND not be merged into Mentor Mode or KG/video task acceptance.

### S5 Fable/CC Lessons as Mechanisms
**Status**: [x] done

GIVEN public Fable/Claude-Code-style prompt discussions show useful long-task operating-system patterns
WHEN this workflow borrows from them
THEN it should translate them into local mechanisms such as files, gates, prompts, evidence, and checkpoints
AND must not copy public prompt text into local authoritative rules.

### S6 Task Package Prompt Contract
**Status**: [x] done

GIVEN Ba Ba or a lead model gives another model a task packet
WHEN the packet is handed off
THEN the handoff should include a copy-ready execution prompt
AND the prompt must include read-first files, allowed paths, forbidden paths, gates, verification commands, report format, and stop conditions.

### S7 Evidence-Backed Claims
**Status**: [x] done

GIVEN an agent claims a task is done, a file exists, or verification passed
WHEN the claim is made
THEN the agent should cite current-session evidence such as file reads, command output, or test results
AND unsupported progress claims should be rejected during review.

## Acceptance Criteria

| AC# | Description | Verification Command | Expected Output |
|-----|-------------|---------------------|-----------------|
| AC01 | MUSE `.memory.md`, 2-Action Rule, and CodeGraph are all captured | `Select-String -Path .trae/tasks/_shared/2026-06-20-ai-workflow-context-efficiency-patterns/spec.md -Pattern "Skill-Level Memory|2-Action|CodeGraph"` | Matches |
| AC02 | Task separation is explicit | `Select-String -Path .trae/tasks/_shared/2026-06-20-ai-workflow-context-efficiency-patterns/analysis.md -Pattern "Mentor Mode|KG/video"` | Matches |
| AC03 | State ownership is defined | `Select-String -Path .trae/tasks/_shared/2026-06-20-ai-workflow-context-efficiency-patterns/analysis.md -Pattern "Data and state ownership"` | Match |
| AC04 | Whole-repo migration shortcut is rejected | `Select-String -Path .trae/tasks/_shared/2026-06-20-ai-workflow-context-efficiency-patterns/analysis.md -Pattern "whole-repo migration|empty .memory.md"` | Match |
| AC05 | Doc governance evidence exists | `Test-Path .trae/tasks/_shared/2026-06-20-ai-workflow-context-efficiency-patterns/doc-impact.md` | True |
| AC06 | Fable/CC lessons are translated, not copied | `Select-String -Path .trae/tasks/_shared/2026-06-20-ai-workflow-context-efficiency-patterns/spec.md -Pattern "Fable/CC Lessons as Mechanisms"` | Match |
| AC07 | Task package prompt contract exists | `Select-String -Path .trae/tasks/_shared/2026-06-20-ai-workflow-context-efficiency-patterns/analysis.md -Pattern "Task Package Prompt Contract"` | Match |
| AC08 | Evidence-backed claims are required | `Select-String -Path .trae/tasks/_shared/2026-06-20-ai-workflow-context-efficiency-patterns/spec.md -Pattern "Evidence-Backed Claims"` | Match |

## Quality Checklist

### Completeness
- [x] [OK] Covers all three requested reference patterns.
- [x] [OK] Covers Fable/CC-inspired evidence, checkpoint, and prompt handoff lessons.
- [x] [OK] Defines where their state belongs.

### Clarity
- [x] [OK] Separates global workflow improvements from Jinli-specific tasks.
- [x] [OK] Makes clear that public prompt text is not copied as authoritative local rules.
- [x] [OK] Does not require whole-repo migration in the first slice.

### Consistency
- [x] [OK] Compatible with current task-packet workflow.
- [x] [OK] Compatible with Mature Solution First.

### Scenario Coverage
- [x] [OK] Includes skill memory, research findings, CodeGraph evidence, and task ownership scenarios.
- [x] [OK] Includes task-package prompt and evidence-backed claim scenarios.

### Edge Case Coverage
- [x] [OK] Tiny tasks can skip CodeGraph with explicit reason.
- [x] [OK] Empty memory-file churn is rejected.

## Progress Summary

| Phase | Status | Key Decision |
|-------|--------|-------------|
| Plan | Done | Keep as separate `_shared` workflow packet |
| Implement | Done | Bounded pilot: 43 doc + prompt template + 4 .memory.md |
| Review | Done | All 8 AC verified with command evidence |
| Verify | Pending gate | verification-report.md written, awaiting task-guard verify |

## Non-Goals

- Do not implement all `.memory.md` files in this planning packet.
- Do not alter Mentor Mode or KG/video task scope.
- Do not require CodeGraph for trivial single-file tasks.
- Do not build hook automation before the pilot is confirmed.
- Do not copy public/leaked system prompt text into local authoritative rules.
- Do not let task handoff prompts override the task packet or mechanical gates.
