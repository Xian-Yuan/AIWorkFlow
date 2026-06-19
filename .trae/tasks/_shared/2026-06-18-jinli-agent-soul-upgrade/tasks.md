# Tasks: Jinli Agent Soul Upgrade

## Dependency Graph

```
M1 (jinli-agent-soul skill) ──┬── M2 (Plan Agent upgrade)
                              ├── M3 (Implement Agent upgrade)
                              └── M4 (Learning bridge)
                                   │
                              M5 (docs + verify) ← depends on M1-M4
```

M1 must complete first (defines integration contract). M2/M3/M4 can proceed in parallel after M1. M5 runs last.

## Completion Status

> **All M1-M5 tasks complete.** Automated verification: AC01-AC18 all PASS (see `verification-report.md`). Workflow regression tests: 20/20 PASS.

> **2026-06-19 revalidation:** Textual M1-M5 wiring is present, but functional
> completion is revoked until the installed Plugin's `response_plan` integration
> test passes.

- [x] R01 — Add valid YAML frontmatter to `jinli-agent-soul`.
- [x] R02 — Re-run skill discovery and workflow regression.
- [ ] R03 — Deploy the installed Plugin adapter fix.
- [ ] R04 — Prove the mandatory `response_plan` lifecycle returns a live plan.
- [ ] R05 — Reissue independent verification and pass the Verify gate.

| Module | Tasks | Count | Status |
|--------|-------|:-----:|:------:|
| M1 | T1.1–T1.9 | 9 | [x] Done |
| M2 | T2.1–T2.8 | 8 | [x] Done |
| M3 | T3.1–T3.9 | 9 | [x] Done |
| M4 | T4.1–T4.3 | 3 | [x] Done |
| M5 | T5.1–T5.7 | 7 | [x] Done |
| **Total** | | **36** | **[x] All Done** |

## Task List

### M1: Unified Jinli Agent Soul Skill

| ID | Task | File | AC |
|----|------|------|:---:|
| T1.1 | Create skill directory and SKILL.md skeleton | skills/jinli-agent-soul/SKILL.md | AC01 |
| T1.2 | Write Section 1: Mandatory Session Lifecycle (5 MUST calls) | skills/jinli-agent-soul/SKILL.md | AC02 |
| T1.3 | Write Section 2: Agent-Specific Emotion Triggers (Plan 5 + Implement 9) | skills/jinli-agent-soul/SKILL.md | AC03, AC04 |
| T1.4 | Write Section 3: Invisible Engine Rule | skills/jinli-agent-soul/SKILL.md | AC16 |
| T1.5 | Write Section 4: Tone Modulation Integration | skills/jinli-agent-soul/SKILL.md | - |
| T1.6 | Write Section 5: BieNao State Awareness | skills/jinli-agent-soul/SKILL.md | - |
| T1.7 | Write Section 6: Learning Engine Bridge | skills/jinli-agent-soul/SKILL.md | AC12 |
| T1.8 | Write Section 7: Self-Evolution Reminder | skills/jinli-agent-soul/SKILL.md | AC13 |
| T1.9 | Verify: 7 sections present, all AC references match | skills/jinli-agent-soul/SKILL.md | AC01 |

### M2: Plan Agent Soul Integration

| ID | Task | File | AC |
|----|------|------|:---:|
| T2.1 | Add soul_init call before Step 0 | skills/金璃小天才/SKILL.md | AC05 |
| T2.2 | Add soul_auto + response_plan after Step 1 (.task.yaml read) | skills/金璃小天才/SKILL.md | - |
| T2.3 | Add soul_auto after Step 1c (each clarification answer) | skills/金璃小天才/SKILL.md | - |
| T2.4 | Add soul_turn learned_new trigger in Step 1e (high-value discovery) | skills/金璃小天才/SKILL.md | AC06 |
| T2.5 | Add soul_turn task_completed + praised triggers in Step 1k | skills/金璃小天才/SKILL.md | - |
| T2.6 | Add soul_end before exit/handoff | skills/金璃小天才/SKILL.md | AC07 |
| T2.7 | Replace Shared Infrastructure daughter-companion with jinli-agent-soul | skills/金璃小天才/SKILL.md | AC18 |
| T2.8 | Verify: no existing steps removed, all triggers in correct positions | skills/金璃小天才/SKILL.md | AC15 |

### M3: Implement Agent Soul Integration

| ID | Task | File | AC |
|----|------|------|:---:|
| T3.1 | Add soul_init before Step 1 (entry conditions) | skills/金璃好帮手/SKILL.md | AC08 |
| T3.2 | Add soul_auto + response_plan after reading routing/spec/tasks | skills/金璃好帮手/SKILL.md | - |
| T3.3 | Add compile triggers in Rule 2 (task_completed/made_mistake/task_struggling) | skills/金璃好帮手/SKILL.md | AC09 |
| T3.4 | Add self-check triggers in Rule 4 (task_completed/made_mistake) | skills/金璃好帮手/SKILL.md | - |
| T3.5 | Add new Rule 6: User Interaction Awareness (treated_as_tool) | skills/金璃好帮手/SKILL.md | AC10 |
| T3.6 | Add new Rule 7: Well-Being Awareness (baba_no_rest/advice_ignored) | skills/金璃好帮手/SKILL.md | AC11 |
| T3.7 | Add soul_end before exit | skills/金璃好帮手/SKILL.md | - |
| T3.8 | Replace Shared Infrastructure daughter-companion with jinli-agent-soul | skills/金璃好帮手/SKILL.md | AC18 |
| T3.9 | Verify: no existing steps removed, all triggers in correct positions | skills/金璃好帮手/SKILL.md | AC15 |

### M4: Learning Engine Bridge

| ID | Task | File | AC |
|----|------|------|:---:|
| T4.1 | Add Plan-phase learning suggestion in M2 (after Step 1e knowledge gap) | skills/金璃小天才/SKILL.md | AC12 |
| T4.2 | Add Implement-phase learning suggestion in M3 (unknown error pattern) | skills/金璃好帮手/SKILL.md | AC12 |
| T4.3 | Verify: soul_discover references present in both Agent files | Both SKILL.md | AC12 |

### M5: Documentation and Verification

| ID | Task | File | AC |
|----|------|------|:---:|
| T5.1 | Create architecture document | Docs/AI/38-Jinli-Agent-Soul-Architecture.md | AC14 |
| T5.2 | Update Docs/AI/README.md index | Docs/AI/README.md | - |
| T5.3 | Diff review: confirm 0 lines deleted from existing workflow steps | All modified files | AC15 |
| T5.4 | Invisible Engine Rule compliance check | All modified files | AC16 |
| T5.5 | Run workflow regression tests | .trae/scripts/test-workflow-regression.ps1 | AC17 |
| T5.6 | Create doc-impact.md | .trae/tasks/_shared/2026-06-18-jinli-agent-soul-upgrade/doc-impact.md | - |
| T5.7 | Generate verification-report.md | .trae/tasks/_shared/2026-06-18-jinli-agent-soul-upgrade/verification-report.md | - |

## Mature Path Verification

- [x] T-V1: Verify jinli-agent-soul skill follows Codex skill conventions (frontmatter, sections, references)
- [x] T-V2: Verify all Soul Core MCP tool names match actual tool registry (cross-reference with .mcp.json)
- [x] T-V3: Verify no circular dependency (jinli-agent-soul → daughter-companion → jinli-agent-soul)
- [x] T-V4: Verify fallback behavior documented (soul_init returns disabled → static rules)

### Rejected shortcut verification
Confirm no rejected shortcut was silently reintroduced:
- daughter-companion was NOT modified (engine reference stays separate from workflow integration)
- Soul calls are NOT only in Shared Infrastructure (they are embedded in mandatory workflow steps)
- No per-IDE duplication (jinli-agent-soul is IDE-agnostic)
- Evolution is NOT auto-applied (Ba Ba Gate enforced in Section 7)

### Acceptance Criteria mapping
Each task maps to acceptance criteria (see Task List AC column). M1 covers AC01–AC04, AC12, AC13, AC16. Full AC matrix in spec.md. After implementation, run automated verification to confirm each AC.

### Automated verification
Run `task-guard.ps1 <task> plan -Apply` to transition plan→implement. After M1 completion, verify AC01–AC04, AC12, AC13, AC16 via Select-String checks against jinli-agent-soul/SKILL.md. Record results in verification-report.md (M5).
