# Tasks: Workflow Optimization

## Dependency Graph

```
M1 (双轨) M2 (禁用) M3 (stub) M7 (codex)  ← 并行
                 ↓
          M4 (门禁) M5 (模板)                ← 顺序（共享 AGENTS.md）
                 ↓
          M6 (semantic)                     ← 最后（外部依赖 ruflo）
```

---

## M1: Destroy Dual-Track + .agents/engine/ Cleanup

### M1a: Delete 10 Duplicate Scripts from engine/
- [ ] T1.1: Audit external references — `Select-String` across workspace for paths referencing any of the 10 duplicate scripts under `engine\`
- [ ] T1.2: Delete `engine/task-state.ps1`
- [ ] T1.3: Delete `engine/doc-guard.ps1`
- [ ] T1.4: Delete `engine/spec-living.ps1`
- [ ] T1.5: Delete `engine/memory-retrieve.ps1`
- [ ] T1.6: Delete `engine/verify.ps1`
- [ ] T1.7: Delete `engine/migrate-docs.ps1`
- [ ] T1.8: Delete `engine/codegraph.ps1`
- [ ] T1.9: Delete `engine/memory-benchmark.ps1`
- [ ] T1.10: Delete `engine/task-metrics.ps1`
- [ ] T1.11: Delete `engine/update-docs-tree.ps1`
- [ ] T1.12: Verify AC01 (overlap = 0)

### M1b: Clean Up engine/ Unique Scripts
- [ ] T1.13: Delete `engine/skill-loader.ps1` (only referenced in comment, never called)
- [ ] T1.14: Delete `engine/phase-machine.ps1` (disabled, .agents/engine/ copy retained as historical)
- [ ] T1.15: Delete `engine/subagent-dispatcher.ps1` (zero references, also delete from .agents/engine/)
- [ ] T1.16: Delete `engine/task-detector.ps1` (zero references, also delete from .agents/engine/)
- [ ] T1.17: Verify AC02 (deleted scripts absent), AC03 (rule-enforcer + rule-registry retained)

### M1c: Clean Up .agents/engine/ Legacy Source
- [ ] T1.18: Delete `.agents/engine/subagent-dispatcher.ps1`
- [ ] T1.19: Delete `.agents/engine/task-detector.ps1`
- [ ] T1.20: Delete `.agents/engine/skill-auto-loader.ps1`
- [ ] T1.21: Verify AC04 (deleted scripts absent), AC05 (phase-machine + config + README retained)

### M1d: Create Documentation
- [ ] T1.22: Create `engine/README.md` documenting remaining engine/ purpose
- [ ] T1.23: Verify AC07 (README exists)

## M2: Disable Experimental Scripts

- [ ] T2.1: Rename `engine/_experimental/test-doc-guard.ps1` → `_DISABLED.test-doc-guard.ps1`
- [ ] T2.2: Rename `engine/_experimental/test-workflow-regression.ps1` → `_DISABLED.test-workflow-regression.ps1`
- [ ] T2.3: Verify AC02 (no non-disabled test scripts remain)

## M3: Stub Expiry Policy

- [ ] T3.1: Edit `Docs/AI/document-taxonomy-inventory.md` — add stub expiry declaration to Migration Notes
- [ ] T3.2: Edit `Docs/AI/document-migration-log.md` — add expiry date reference to Notes
- [ ] T3.3: Create `.trae/scripts/cleanup-stubs.ps1` with `--dry-run` and `--execute` modes
- [ ] T3.4: Verify AC04 (expiry declared), AC05 (dry-run works), AC06 (non-stub safety)

## M4: Gate Enforcement

- [ ] T4.1: Edit `AGENTS.md` — insert `⛔ IMPLEMENT PHASE GATE` block before Implement section
- [ ] T4.2: Audit `task-guard.ps1` plan gate — add doc-impact.md existence check if missing
- [ ] T4.3: Verify AC11 (gate block in AGENTS.md)

## M5: Automated Regression Templates

- [ ] T5.1: Create `.trae/tasks/_shared/templates/` directory
- [ ] T5.2: Create `tasks-template.md` with fixed verification steps (T{N-2}: mature path check, T{N-1}: automated verify, T{N}: AC mapping)
- [ ] T5.3: Create `spec-template.md` with AC table format (AC# / Description / Verification Command / Expected Output)
- [ ] T5.4: Edit `AGENTS.md` — add template reference requirement
- [ ] T5.5: Verify AC12 (tasks template exists), AC13 (spec template exists)

## M6: Semantic Memory Integration

- [ ] T6.1: Edit `.trae/scripts/memory-retrieve.ps1` — add `-Semantic` switch, integrate ruflo, implement silent fallback
- [ ] T6.2: Edit `Docs/Memory/README.md` — document semantic search availability
- [ ] T6.3: Verify AC14 (semantic parameter works with fallback)

## M7: Codex Task Adapter

- [ ] T7.1: Create `.codex/tasks/` directory junction → `.trae/tasks/`
- [ ] T7.2: Create `.codex/tasks/README.md`
- [ ] T7.3: Edit `.agents/skills/codex-project-router/SKILL.md` — remove "until native adapter" note
- [ ] T7.4: Verify AC15 (junction resolves), AC16 (stale note removed)

## Final Verification

- [ ] T8.1: Verify selected mature path was implemented and no rejected shortcut was introduced.
- [ ] T8.2: Run automated verification (`.trae\scripts\verify.ps1`) and record output in `verification-report.md`
- [ ] T8.3: Map implementation result to Acceptance Criteria in `verification-report.md` (AC01-AC18)
- [ ] T8.4: Run `.trae\scripts\test-workflow-regression.ps1` → AC17
- [ ] T8.5: Run `.trae\scripts\update-docs-tree.ps1 -Mode check` → AC18
- [ ] T8.6: Verify all 18 ACs pass
- [ ] T8.7: Generate final `verification-report.md`
- [ ] T8.8: Mark task complete in `.task.yaml`
