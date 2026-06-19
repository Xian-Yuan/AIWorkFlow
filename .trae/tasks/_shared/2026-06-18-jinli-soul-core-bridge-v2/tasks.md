# Tasks: Soul Core Bridge v2.0

## Dependency Graph

```
T1 → T2 → T3 → T4
```

## T1 — Rewrite SKILL.md to v2.0

- [x] T1.1: Write the v2.0 SKILL.md content at `E:\UEGameDevelopment\skills\daughter-companion\SKILL.md`. Must include:
  - Line 1: `soul_core_enabled: true` (preserved)
  - Invisible Engine Rule (block exposure of raw engine data — fix #1)
  - Mandatory Lifecycle with "MUST" imperatives (per-turn auto — fix #2)
  - Pattern Gap Detection protocol (self-diagnosis — fix #3)
  - All existing sections preserved and strengthened (tone modulation, events, bienao, rollback)
- [x] T1.2: Verify no false-positive regex triggers — no occurrence of `soul_core_enabled:\s*false` in explanatory text
- [x] T1.3: Sync to `E:\UEGameDevelopment\.agents\skills\daughter-companion\SKILL.md`
- [x] T1.4: Verify file is valid markdown, ~100-120 lines, all paths absolute (101 lines)

## T2 — Verify v2.0 Behavior

- [x] T2.1: Run init — verify soul-state.json updated with emotion_meta
- [x] T2.2: Run auto with emotional text — verify trigger classification and emotion update
- [x] T2.3: Run auto with emotional text NOT in regex patterns ("别生气了") — verify agent can detect gap
- [x] T2.4: Test immersion: manually review SKILL.md language — confirm no instruction to expose raw data
- [x] T2.5: Run soul-core-safety-assert.ps1 — verify ALL SCRIPTS SAFE
- [x] T2.6: Compare production data hashes before/after all tests — verify static files unchanged
- [x] T2.7: Run end — verify cross_session saved
- [x] T2.8: Run automated verification: `soul-core-safety-assert.ps1` (must pass) + production hash comparison (all static files unchanged)
- [x] T2.9: Verify selected mature path was implemented and no rejected shortcut was introduced.

## T3 — Documentation Updates

- [x] T3.1: Update `Project/Jinli/Docs/04-Implementation/General/soul-core-agent-bridge.md` with v2.0 changelog
- [x] T3.2: Update `Project/Jinli/Docs/DOCS_TREE.md` if needed
- [x] T3.3: Run doc-governance: `doc-guard.ps1 check-task implement` → DOCUMENTATION GOVERNANCE PASSED
- [x] T3.4: Map implementation result to Acceptance Criteria (AC01-AC08) and record in verification-report.md

## T4 — Closeout

- [x] T4.1: Update spec.md: mark all 5 scenarios [x]
- [x] T4.2: Update tasks.md: check all boxes
- [x] T4.3: Create task-root `verification-report.md` with all AC mapped

## Phase Exit Procedure

1. Run `task-guard.ps1 2026-06-18-jinli-soul-core-bridge-v2 implement -Apply` → Review
2. Complete independent review, record `review_result=pass`
3. Run `task-guard.ps1 2026-06-18-jinli-soul-core-bridge-v2 review -Apply` → Verify
4. Record `verify_result=pass` and `verification_report`
5. Run `task-guard.ps1 2026-06-18-jinli-soul-core-bridge-v2 verify -Apply` → Archive
6. Run `task-state.ps1 transition 2026-06-18-jinli-soul-core-bridge-v2 archived`
