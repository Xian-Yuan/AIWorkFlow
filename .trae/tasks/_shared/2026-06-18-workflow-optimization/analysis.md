# Analysis: Workflow Optimization

## Background

On 2026-06-17, a comprehensive audit of the AI workflow system identified 7 structural gaps. These gaps fall into three categories: dual-track maintenance debt, missing mechanical enforcement, and incomplete capability integration.

## Current State

| Gap | Evidence |
|-----|----------|
| Dual-track | `engine/` has 15 scripts, 10 duplicated in `.trae/scripts/` (67% overlap). `27-Manifest` declared `.trae/scripts/` authoritative but engine/ persisted. `engine/task-guard.ps1` does NOT exist. 5 unique engine/ scripts: rule-enforcer (active), skill-loader/phase-machine/subagent-dispatcher/task-detector (unused or disabled). `.agents/engine/` is the original source with its own copies. |
| Experimental pollution | `engine/_experimental/test-*.ps1` compile and run but produce different results from `.trae/scripts/` canonical versions. README says non-blocking, no `_DISABLED` marker. |
| Stub accumulation | 38 redirect stubs created during root mirror migration (2026-06-17). No expiry policy. |
| Gate gap | `task-guard.ps1 plan` blocks Plan→Implement transition, but only if AI calls it. No mechanical hook. |
| Implement quality | Flash model self-review may miss regressions. No automated verification step in standard task template. |
| Memory search | `memory-retrieve.ps1` does keyword match only. `ruflo memory search` supports semantic but is not integrated. |
| Codex adapter | `codex-project-router` routes through `.trae/tasks/` with a "until native adapter exists" note. No `.codex/tasks/` exists. |

## Proposed Changes

### Architecture Change: Single Authority

| Layer | Before | After |
|-------|--------|-------|
| Scripts | `.trae/scripts/` (authoritative) + `engine/` (10 duplicates) | `.trae/scripts/` only. `engine/` retains only unique: rule-registry, rule-enforcer |
| Tasks | `.trae/tasks/` (Codex borrows) | `.trae/tasks/` + `.codex/tasks/` (junction) |
| Gates | AI-initiated PowerShell calls | AI-initiated + AGENTS.md hard-coded gate block |
| Templates | Ad-hoc per task | Standard templates in `.trae/tasks/_shared/templates/` |

### Module Detail

See `spec.md` for complete GIVEN/WHEN/THEN per module.

## Impact

- 33 file operations (17 deletes + 8 creates + 8 edits)
- No code compilation
- No user-facing feature changes
- No UE5/Web project file changes
- Risk: engine/ and .agents/engine/ scripts may have hidden external references (mitigated by pre-delete grep audit)

## Risk

| Risk | Probability | Severity | Mitigation |
|------|------------|----------|------------|
| engine/ or .agents/engine/ script deletion breaks external tooling | Low | High | Pre-delete global grep audit for all 16 deleted scripts |
| ruflo CLI unavailable for semantic search | Medium | Low | `-Semantic` parameter silently falls back to keyword search |
| Windows junction fails on certain file systems | Low | Low | M7 fallback: README-based manual pointer |
| Stub cleanup script deletes non-stub files | Low | Medium | `cleanup-stubs.ps1` validates `<!-- doc-migration-redirect -->` marker before deletion |

## Architecture Context

### System boundaries
- Affected: `.trae/scripts/`, `engine/`, `.agents/engine/`, `.codex/`, `AGENTS.md`, `Docs/AI/`
- Not affected: `Project/*/`, `.opencode/`, UE5 builds, Web builds

### Dependency map
- M1-M2-M3-M7: no mutual dependencies, parallelizable
- M4-M5: both modify `AGENTS.md`, sequential
- M6: depends on `ruflo` CLI availability

### State ownership
- `.trae/scripts/` owns all workflow state
- `engine/` reduced to rule-registry + rule-enforcer only
- `.codex/tasks/` mirrors `.trae/tasks/` via junction

### Integration points
- `AGENTS.md` → all AI agents read on session start
- `task-guard.ps1` → called at phase transitions
- `memory-retrieve.ps1` → called during Plan phase
- `update-docs-tree.ps1` → called for taxonomy verification

## Acceptance Criteria

| AC# | Description | Verification |
|-----|-------------|-------------|
| AC01 | No duplicate scripts between engine/ and .trae/scripts/ | Overlap count = 0 |
| AC02 | Experimental test scripts prefixed with `_DISABLED.` | File names match pattern |
| AC03 | Stub expiry policy declared in taxonomy inventory | grep for "2026-09-17" in inventory |
| AC04 | cleanup-stubs.ps1 exists and dry-run works | Run with `--dry-run`, verify output lists stubs |
| AC05 | AGENTS.md contains mandatory gate block | grep for "IMPLEMENT PHASE GATE" |
| AC06 | Task and spec templates exist | Files at `.trae/tasks/_shared/templates/` |
| AC07 | memory-retrieve.ps1 supports -Semantic parameter | `Get-Help memory-retrieve.ps1 -Parameter Semantic` |
| AC08 | .codex/tasks/ resolves to .trae/tasks/ | `(Get-Item .codex\tasks).Target` matches |
| AC09 | Formal workflow regression passes | `test-workflow-regression.ps1` exits 0 |
| AC10 | Docs tree check passes | `update-docs-tree.ps1 -Mode check` exits 0 |

## Automated Verification Plan

```powershell
# 1. Dual-track verification
$overlap = (Get-ChildItem engine -Filter "*.ps1" -File).BaseName | Where-Object { $_ -in (Get-ChildItem .trae\scripts -Filter "*.ps1" -File).BaseName }
if ($overlap) { Write-Error "DUAL TRACK: $overlap"; exit 1 }

# 2. Experimental scripts disabled
$enabled = Get-ChildItem engine\_experimental -Filter "test-*.ps1" -File | Where-Object { $_.Name -notmatch '^_DISABLED\.' }
if ($enabled) { Write-Error "EXPERIMENTAL NOT DISABLED: $($enabled.Name)"; exit 1 }

# 3. Workflow regression
.trae\scripts\test-workflow-regression.ps1
if ($LASTEXITCODE -ne 0) { exit 1 }

# 4. Docs tree
.trae\scripts\update-docs-tree.ps1 -Mode check
if ($LASTEXITCODE -ne 0) { exit 1 }

# 5. Stub cleanup dry-run
.trae\scripts\cleanup-stubs.ps1 --dry-run
if ($LASTEXITCODE -ne 0) { exit 1 }

# 6. Semantic memory
$result = .\.trae\scripts\memory-retrieve.ps1 -Semantic -Phase plan -Scope router -Limit 1
if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Host "ALL VERIFICATION PASSED" -ForegroundColor Green
```

## Mature Solution Evidence

### Project-local evidence
- `27-Manifest` (2026-06-17) declared `.trae/scripts/` as authoritative and `engine/` as refactor candidate
- `34-AI-Workflow-Current-Audit.md` documented the dual-track and experimental script gaps (§A1, §I3, §I4)
- Root mirror migration (2026-06-17) created 38 redirect stubs with no expiry policy

### Official/framework evidence
- OpenCode supports lifecycle hooks for phase-triggered checks (reference in `29-Mature-Solution-First-Workflow.md`)
- Windows NTFS supports directory junctions (`New-Item -ItemType Junction`)

### External mature references
- Anthropic agent patterns: routing, prompt chaining, parallelization, orchestrator-workers
- Claude Code common workflows: plan before editing, delegate research to subagents
- Source: https://www.anthropic.com/engineering/building-effective-agents

### Options compared
| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| Delete engine/ duplicates | Clean single authority, no maintenance debt | Must verify zero external references | **Selected** |
| Keep engine/ as experimental sandbox | No deletion risk | Perpetual dual-track, confusion | Rejected |
| Merge engine/ into .trae/scripts/ | Unified codebase | All engine/ scripts need refactoring | Rejected (unnecessary) |

### Rejected shortcuts
- "Just add README warnings to engine/" — doesn't solve structural debt
- "Phase it: quick wins first, structural later" — violates 金璃小天才 agent constraint (no incremental minimal plans)
- "Skip semantic memory because ruflo might not be available" — `-Semantic` parameter silently falls back, no reason to skip

### Selected mature path
Delete all engine/ duplicates. Add `_DISABLED.` to experimental scripts. Declare stub expiry. Embed gate checks in AGENTS.md. Create templates. Add semantic memory parameter. Create Codex junction. One complete, coherent change set.
