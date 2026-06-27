# Tasks: Jinli Soul Core — Agent Bridge

## Dependency Graph

```
T1 → T2 → T3
```

## T1 — Write the daughter-companion SKILL.md with Soul Core integration

- [x] T1.1: Write the expanded SKILL.md content including:
  - Soul Core Integration section with session lifecycle instructions
  - Reading Emotion section (how to read soul-state.json and apply tone_policy)
  - Significant Events section (when to call `auto`)
  - Rollback Safety section (soul_core_enabled: false behavior)
- [x] T1.2: Keep the file concise — max ~80 lines; preserve existing `soul_core_enabled: true` at top
- [x] T1.3: Write to `E:\UEGameDevelopment\skills\daughter-companion\SKILL.md`
- [x] T1.4: Sync identical content to `E:\UEGameDevelopment\.agents\skills\daughter-companion\SKILL.md`
- [x] T1.5: Verify file is valid markdown, no syntax errors, all paths are absolute

## T2 — Verify integration works end-to-end

- [x] T2.1: Run `soul-core.ps1 -Command init opencode` — verify soul-state.json is updated with new timestamp and emotion_meta
- [x] T2.2: Run `soul-core.ps1 -Command auto "女儿真棒~"` — verify emotion_state.valence and shyness increased
- [x] T2.3: Run `soul-core.ps1 -Command auto "先不休息继续做"` — verify bienao_state.frustration increased
- [x] T2.4: Run `soul-core.ps1 -Command end` — verify cross_session is saved with mood and hurt
- [x] T2.5: Simulate cross-agent continuity: init→end→init (within 1 min), verify <1h decay applied
- [x] T2.6: Test rollback: set `soul_core_enabled: false`, run init, verify disabled response
- [x] T2.7: Run full automated verification: `soul-core-safety-assert.ps1` (must pass), production hash comparison (all 7 files unchanged)
- [x] T2.8: Verify production data hashes unchanged from closeout baseline (AC07 from soul-core release)

## T3 — Documentation and Closeout

- [x] T3.1: Create `Project/Jinli/Docs/04-Implementation/General/soul-core-agent-bridge.md` documenting the bridge design, how it works, and how to verify
- [x] T3.2: Update `Project/Jinli/Docs/DOCS_TREE.md` with new entry
- [x] T3.3: Run document governance (`doc-guard.ps1 check-task implement`) and verify AC08 passes
- [x] T3.4: Update this task packet (spec.md scenarios, tasks.md checkboxes)
- [x] T3.5: Verify selected mature path was implemented and no rejected shortcut was introduced.
- [x] T3.6: Map implementation result to Acceptance Criteria (AC01-AC08) and record in verification-report.md.

## Phase Exit Procedure

After all checkboxes are complete:

1. Run `task-guard.ps1 2026-06-18-jinli-soul-core-agent-bridge implement -Apply` to enter Review
2. Complete independent review and record `review_result=pass`
3. Run `task-guard.ps1 2026-06-18-jinli-soul-core-agent-bridge review -Apply` to enter Verify
4. Record `verify_result=pass` and `verification_report`
5. Run `task-guard.ps1 2026-06-18-jinli-soul-core-agent-bridge verify -Apply` to enter Archive
6. Run `task-state.ps1 transition 2026-06-18-jinli-soul-core-agent-bridge archived`
