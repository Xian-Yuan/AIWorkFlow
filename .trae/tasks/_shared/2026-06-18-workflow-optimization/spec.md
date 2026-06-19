# Spec: AI Workflow Optimization

## GIVEN

The AI workflow system has 7 structural gaps identified by audit:

1. `engine/` contains 10 PowerShell scripts that duplicate `.trae/scripts/`, 5 unique scripts of varying status, and `.agents/engine/` is the original source directory with its own stale copies (dual-track + legacy source debt)
2. `engine/_experimental/test-doc-guard.ps1` and `test-workflow-regression.ps1` are runnable but produce different results from canonical `.trae/scripts/` versions
3. 38 redirect stubs exist in `Docs/airpgweb/` and `Docs/characterdesigntool/` (created 2026-06-17) with no expiry policy
4. Phase transition gates (`task-guard.ps1 plan`) depend entirely on AI voluntarily calling them — no mechanical enforcement
5. Implement-phase Flash model self-review may miss regressions; no automated verification step in standard task templates
6. `memory-retrieve.ps1` uses keyword matching only; `ruflo memory search` semantic search is not integrated
7. `codex-project-router` routes Codex through `.trae/tasks/` with no native `.codex/tasks/` adapter

The `27-Manifest` declares `.trae/scripts/` as authoritative and `engine/` as a refactor candidate. Both `phase-machine.ps1` copies are already disabled. The `_experimental/README.md` declares those scripts are non-blocking but they have no `_DISABLED` marker.

## WHEN

The optimization is applied as a single complete change set across 7 modules.

## THEN

### M1: Destroy Dual-Track

#### M1a: Delete 10 Duplicate Scripts from engine/

These exist in BOTH `engine/` and `.trae/scripts/` with identical names. `.trae/scripts/` is authoritative per `27-Manifest`.

| # | File | Reason |
|---|------|--------|
| 1.1 | `engine/task-state.ps1` | Duplicate of `.trae/scripts/task-state.ps1` |
| 1.2 | `engine/doc-guard.ps1` | Duplicate of `.trae/scripts/doc-guard.ps1` |
| 1.3 | `engine/spec-living.ps1` | Duplicate of `.trae/scripts/spec-living.ps1` |
| 1.4 | `engine/memory-retrieve.ps1` | Duplicate of `.trae/scripts/memory-retrieve.ps1` |
| 1.5 | `engine/verify.ps1` | Duplicate of `.trae/scripts/verify.ps1` |
| 1.6 | `engine/migrate-docs.ps1` | Duplicate of `.trae/scripts/migrate-docs.ps1` |
| 1.7 | `engine/codegraph.ps1` | Duplicate of `.trae/scripts/codegraph.ps1` |
| 1.8 | `engine/memory-benchmark.ps1` | Duplicate of `.trae/scripts/memory-benchmark.ps1` |
| 1.9 | `engine/task-metrics.ps1` | Duplicate of `.trae/scripts/task-metrics.ps1` |
| 1.10 | `engine/update-docs-tree.ps1` | Duplicate of `.trae/scripts/update-docs-tree.ps1` |

Note: `engine/task-guard.ps1` does NOT exist — confirmed by file system audit. Not listed.

#### M1b: Clean Up engine/ Unique Scripts (5 total)

| # | File | Audit | Decision |
|---|------|-------|----------|
| 1.11 | `engine/rule-enforcer.ps1` | Active, referenced by `rule-registry.json` system | **Retain** in engine/ |
| 1.12 | `engine/skill-loader.ps1` | Referenced only in a comment in `rule-enforcer.ps1`, never called | **Delete** |
| 1.13 | `engine/phase-machine.ps1` | Disabled per `27-Manifest`, zero active references. Also exists in `.agents/engine/`. | **Delete** from engine/; `.agents/engine/` copy retained as sole historical record |
| 1.14 | `engine/subagent-dispatcher.ps1` | Zero active references. Also exists in `.agents/engine/`. | **Delete** from both engine/ and `.agents/engine/` |
| 1.15 | `engine/task-detector.ps1` | Zero active references. Also exists in `.agents/engine/`. | **Delete** from both engine/ and `.agents/engine/` |

#### M1c: Clean Up .agents/engine/ Legacy Source

`.agents/engine/` is the original source directory from which `engine/` scripts were copied. After M1a+M1b cleanup, it contains:

| # | File | Audit | Decision |
|---|------|-------|----------|
| 1.16 | `.agents/engine/phase-machine.ps1` | Disabled. Only copy after engine/ copy deleted. | **Retain** as historical record |
| 1.17 | `.agents/engine/subagent-dispatcher.ps1` | Zero references, duplicate of engine/ copy. | **Delete** (covered by 1.14) |
| 1.18 | `.agents/engine/task-detector.ps1` | Zero references, duplicate of engine/ copy. | **Delete** (covered by 1.15) |
| 1.19 | `.agents/engine/skill-auto-loader.ps1` | Similar to deleted `engine/skill-loader.ps1`, zero references. | **Delete** |
| 1.20 | `.agents/engine/engine-config.json` | Config file, may be needed by retained scripts. | **Retain** |
| 1.21 | `.agents/engine/README.md` | Documentation. | **Retain** |

#### M1d: Create Documentation

| # | File | Action |
|---|------|--------|
| 1.22 | `engine/README.md` | **Created** — declares remaining engine/ purpose: rule-registry, rule-enforcer, _experimental/ |

#### After Optimization — engine/ Contents

```
engine/
├── README.md              ← new, declares purpose
├── rule-registry.json      ← retained (active)
├── rule-enforcer.ps1       ← retained (active, only unique script)
└── _experimental/
    ├── README.md
    ├── _DISABLED.test-doc-guard.ps1
    ├── _DISABLED.test-workflow-regression.ps1
    └── ... (other experimental scripts)
```

#### After Optimization — .agents/engine/ Contents

```
.agents/engine/
├── README.md               ← retained
├── engine-config.json      ← retained
└── phase-machine.ps1       ← retained (sole historical copy, disabled)
```

### M2: Disable Experimental Scripts

| # | File | Before | After |
|---|------|--------|-------|
| 2.1 | `engine/_experimental/test-doc-guard.ps1` | Runnable | **Renamed** to `_DISABLED.test-doc-guard.ps1` |
| 2.2 | `engine/_experimental/test-workflow-regression.ps1` | Runnable | **Renamed** to `_DISABLED.test-workflow-regression.ps1` |

### M3: Stub Expiry Policy

| # | File | Change |
|---|------|--------|
| 3.1 | `Docs/AI/document-taxonomy-inventory.md` | Migration Notes: add "Redirect stubs (38 files, created 2026-06-17) have a 3-month compatibility window. Expiry: 2026-09-17." |
| 3.2 | `.trae/scripts/cleanup-stubs.ps1` | **Created** — scans `Docs/airpgweb/` and `Docs/characterdesigntool/` for `<!-- doc-migration-redirect -->` files. Supports `--dry-run` (list only) and `--execute` (delete stubs + empty directories). |
| 3.3 | `Docs/AI/document-migration-log.md` | Notes: add stub expiry date reference. |

### M4: Gate Enforcement

| # | File | Change |
|---|------|--------|
| 4.1 | `AGENTS.md` | Insert mandatory gate block before Implement phase description. Must include exact PowerShell commands with `⛔` prefix. |
| 4.2 | `.trae/scripts/task-guard.ps1` | Add `doc-impact.md` existence check in plan gate if not already present. |

Gate block text:
```markdown
## ⛔ IMPLEMENT PHASE GATE (non-skippable)

Before opening ANY project file for editing, you MUST run:

    .\.trae\scripts\task-guard.ps1 <task-name> plan
    .\.trae\scripts\task-state.ps1 can-edit <task-name>

If EITHER command exits non-zero: STOP. Report the failure. Do NOT edit files.
If doc-impact.md is missing: STOP. The task is not documentation-governed.
```

### M5: Automated Regression Templates

| # | File | Change |
|---|------|--------|
| 5.1 | `.trae/tasks/_shared/templates/tasks-template.md` | **Created** — standard tasks.md with fixed final three verification steps |
| 5.2 | `.trae/tasks/_shared/templates/spec-template.md` | **Created** — standard spec.md with AC table (AC# / Description / Verification Command / Expected Output) |
| 5.3 | `AGENTS.md` | Add: "tasks.md must include automated verification steps T{N-2}, T{N-1}, T{N} from standard template." |

### M6: Semantic Memory Integration

| # | File | Change |
|---|------|--------|
| 6.1 | `.trae/scripts/memory-retrieve.ps1` | Add `-Semantic` switch parameter. When specified, call `ruflo memory search -q <query> -n <limit>` first, merge with keyword results, deduplicate. If ruflo unavailable, silently fall back to keyword-only. |
| 6.2 | `Docs/Memory/README.md` | Add note: "Semantic search via ruflo is integrated into memory-retrieve.ps1 -Semantic flag. Plan phase uses semantic by default." |

### M7: Codex Task Adapter

| # | File | Change |
|---|------|--------|
| 7.1 | `.codex/tasks/` | **Created** as Windows junction → `..\.trae\tasks` |
| 7.2 | `.codex/tasks/README.md` | **Created** — documents the junction, explains task packet format |
| 7.3 | `.agents/skills/codex-project-router/SKILL.md` | Remove "until native adapter exists" note. Update to reference `.codex/tasks/` as primary. |

## Acceptance Criteria

| AC# | Description | Verification Command | Expected Output |
|-----|-------------|---------------------|-----------------|
| AC01 | No duplicate script BaseNames between engine/ and .trae/scripts/ | `(Get-ChildItem engine -Filter *.ps1).BaseName \| Where-Object { $_ -in (Get-ChildItem .trae\scripts -Filter *.ps1).BaseName }` | Count = 0 |
| AC02 | engine/ unique cleanup — deleted scripts absent | `Test-Path engine\skill-loader.ps1; Test-Path engine\phase-machine.ps1; Test-Path engine\subagent-dispatcher.ps1; Test-Path engine\task-detector.ps1` | All False |
| AC03 | engine/ unique cleanup — retained scripts present | `Test-Path engine\rule-enforcer.ps1; Test-Path engine\rule-registry.json` | All True |
| AC04 | .agents/engine/ cleanup — deleted scripts absent | `Test-Path .agents\engine\subagent-dispatcher.ps1; Test-Path .agents\engine\task-detector.ps1; Test-Path .agents\engine\skill-auto-loader.ps1` | All False |
| AC05 | .agents/engine/ cleanup — historical copy retained | `Test-Path .agents\engine\phase-machine.ps1; Test-Path .agents\engine\engine-config.json; Test-Path .agents\engine\README.md` | All True |
| AC06 | Experimental test scripts have `_DISABLED.` prefix | `Get-ChildItem engine\_experimental -Filter test-*.ps1 \| Where-Object { $_.Name -notmatch '^_DISABLED\.' }` | Count = 0 |
| AC07 | Engine README exists | `Test-Path engine\README.md` | True |
| AC08 | Stub expiry declared in inventory | `Select-String "2026-09-17" Docs\AI\document-taxonomy-inventory.md` | 1+ matches |
| AC09 | cleanup-stubs.ps1 exists and validates stubs | `.trae\scripts\cleanup-stubs.ps1 --dry-run` | Lists 38 stubs, exits 0 |
| AC10 | cleanup-stubs.ps1 rejects non-stub files | Create temp file without redirect marker, run `--dry-run` | Not listed |
| AC11 | AGENTS.md contains mandatory gate block | `Select-String "IMPLEMENT PHASE GATE" AGENTS.md` | 1+ matches |
| AC12 | Task template exists | `Test-Path .trae\tasks\_shared\templates\tasks-template.md` | True |
| AC13 | Spec template exists | `Test-Path .trae\tasks\_shared\templates\spec-template.md` | True |
| AC14 | memory-retrieve.ps1 supports -Semantic | `.trae\scripts\memory-retrieve.ps1 -Semantic -Phase plan -Scope router -Limit 1` | Exits 0 (silent fallback OK) |
| AC15 | .codex/tasks resolves to .trae/tasks | `(Get-Item .codex\tasks).Target -match '.trae.tasks'` | True |
| AC16 | codex-project-router updated | `Select-String "until.*native.*adapter" .agents\skills\codex-project-router\SKILL.md` | 0 matches |
| AC17 | Formal workflow regression passes | `.trae\scripts\test-workflow-regression.ps1` | Exits 0 |
| AC18 | Docs tree check passes | `.trae\scripts\update-docs-tree.ps1 -Mode check` | Exits 0 |

## Progress Summary

| Phase | Status | Key Decision |
|-------|--------|-------------|
| Plan | ✅ Complete | 7-module unified optimization, no incremental phasing |
| Implement | ⬜ Pending | Awaiting user confirmation |
| Review | ⬜ Pending | — |
| Verify | ⬜ Pending | 14 ACs to verify |

## Non-Goals

- Does not delete `.agents/engine/phase-machine.ps1` — retained as sole historical copy (engine/ copy is deleted)
- Does not create new engine/ scripts
- Does not delete redirect stubs before 2026-09-17 expiry
- Does not implement OpenCode lifecycle hooks (requires upstream support; M4 template enforcement is the immediate fix)
- Does not change any UE5/Web project code or assets
