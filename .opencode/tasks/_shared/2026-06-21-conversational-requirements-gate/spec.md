# Spec: Conversational Requirements Gate

## GIVEN

- Ba Ba may express product intent without technical terminology.
- Future tasks may be new systems, meaningful features, redesigns, ambiguous requests, or bounded fixes.
- Existing legacy task packets do not contain requirement-gate metadata.

## WHEN

A planner creates a new task packet and attempts to move from Plan to Implement.

## THEN

### S01 Deep discovery classification

GIVEN a new system, meaningful feature, redesign, or unresolved ambiguity  
WHEN the planner classifies the task  
THEN `change_profile` is `deep`, and uncertainty never routes to fast track.

### S02 Conversational elicitation

GIVEN a deep task  
WHEN Jinli discusses it with Ba Ba  
THEN Jinli asks one plain-language question per turn, offers concrete choices and a recommendation, permits free-form correction, and does not stop at a fixed question count.

### S03 Shared-understanding evidence

GIVEN important decisions and implicit requirements are resolved  
WHEN discovery closes  
THEN `requirements.md` contains confirmed decisions, implicit requirements, non-goals, no unresolved high-impact question, teach-back summary, and confirmation evidence.

### S04 Agent-authored execution prompt

GIVEN requirements are confirmed  
WHEN technical planning begins  
THEN the planner writes `execution-prompt.md` containing truth sources, accepted architecture, scope, acceptance criteria, verification, stop conditions, and evidence rule.

### S05 Deep gate rejection

GIVEN a version-1 deep packet lacks confirmed or structurally complete requirement evidence  
WHEN `task-guard.ps1 <task> plan` runs  
THEN the gate exits non-zero and implementation is blocked.

### S06 Fast-track rejection

GIVEN a version-1 fast packet lacks a concrete reason or fast-track assessment  
WHEN the Plan gate runs  
THEN it exits non-zero.

### S07 Valid packet acceptance

GIVEN either a complete deep packet or a complete bounded fast packet  
WHEN the Plan gate runs  
THEN the requirement-understanding checks pass.

### S08 Legacy compatibility

GIVEN a pre-versioned task packet without `requirements_gate_version`  
WHEN its Plan gate runs  
THEN existing gate behavior remains unchanged.

## Acceptance Criteria

| AC# | Description | Verification Command | Expected Output |
|---|---|---|---|
| AC01 | New initialization includes metadata | focused task-state inspection in regression | fields present |
| AC02 | Incomplete deep task blocks | workflow regression | blocked |
| AC03 | Unjustified fast task blocks | workflow regression | blocked |
| AC04 | Complete deep and fast tasks pass | workflow regression | allowed |
| AC05 | Execution prompt required | workflow regression | missing prompt blocked |
| AC06 | Planner Skills implement conversation rules | content assertions / review | all required rules present |
| AC07 | Legacy compatibility retained | existing valid packet scenario | allowed |
| AC08 | Full workflow and docs checks pass | full command set | exit 0 |

## Quality Checklist

### Completeness
- [x] [OK] Deep and fast routes are both covered.
- [x] [OK] Human interaction and mechanical enforcement are both covered.
- [x] [OK] Acceptance criteria map to scenarios.

### Clarity
- [x] [OK] “Deep” and “fast” have explicit conditions.
- [x] [OK] The human and planner responsibilities are separate.
- [x] [OK] Legacy behavior is explicit.

### Consistency
- [x] [OK] Task packet remains the runtime truth source.
- [x] [OK] Existing mature-solution and verification gates remain.
- [x] [OK] New artifacts have single ownership.

### Scenario Coverage
- [x] [OK] Happy path covered.
- [x] [OK] Incomplete deep and fast packets covered.
- [x] [OK] Legacy compatibility covered.

### Edge Case Coverage
- [x] [OK] Uncertain classification defaults to deep.
- [x] [OK] User-requested early stop still requires teach-back confirmation.
- [x] [OK] Missing prompt and unresolved questions are blocked.

## Progress Summary

| Phase | Status | Key Decision |
|---|---|---|
| Plan | Complete | Versioned deep/fast requirement gate |
| Implement | Complete | Regression-first script, Skill, template, and docs changes |
| Review | Complete | Legacy compatibility and task-local artifact confinement checked |
| Verify | Complete | Full workflow, docs, Hermes, syntax, and gate evidence recorded |

## Non-Goals

- Full migration of legacy packets.
- Application code changes.
- Fixed-length questionnaires.
- Asking Ba Ba to author technical prompts.
