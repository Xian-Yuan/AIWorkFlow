# Verification Report: Hermes Workflow Integration

## 2026-06-20 Post-Archive Bugfix Addendum (Config Migration)

### Discovery

After archive, both Hermes profiles failed at runtime with a 1-second error flash. Root cause: when a profile's `config.yaml` lacks `_config_version`, Hermes auto-migrates from v0 → v27, generating an entire default config that overwrites the custom `model` section (switching from `custom`/XF-Coding to `openrouter`/Claude).

### Fix Applied (two rounds)

| Round | What | Result |
|:------|:-----|:------:|
| 1 | Added `model` section via env var refs + cleared old sessions | Planner worked, Implementer still migrated |
| 2 | Added `_config_version: 27` to profile overlays | **Both profiles work** |

### Verification (2026-06-20, 02:30)

```
Planner:   provider=custom, default=astron-code-latest, 46 lines   ✅
Implementer: provider=custom, default=astron-code-latest, 46 lines ✅
Planner -z "Say hi":  "嗨，爸爸！小璃在这里～ 💫"                    ✅
Implementer -z "Say hi": "嗨爸爸！我是金璃好帮手"                   ✅
```

### Root Cause Summary

Three interconnected issues, all now fixed:

1. **Missing `_config_version`** → Hermes auto-migrated profile configs, overwriting model settings
2. **Missing `model` section in overlay** (from earlier credential fix) → Hermes fell back to OpenRouter default
3. **Old session in state.db** → cached the broken model, restored it even after config was fixed

### Key Lesson

Profile overlays must always include `_config_version: 27` to prevent destructive migration. The `model` section cannot be inherited from the main config — it must be explicitly present in every profile config.

This addendum is the authoritative final status and supersedes earlier provisional status text.

- Phase: `archive`
- Review result: `pass`
- Verify result: `pass`
- Archived: `true`
- Acceptance criteria: 13/13 verified
- Scenarios: 7/7 verified
- Deterministic checks: 66/66 passed
- MCP stdio subprocess regression: 5/5 passed
- Both Hermes Profile doctor commands exited 0
- Original Verify and Archive gates passed

The 66 checks are: Skill Compatibility 27, MCP unit tests 12, Guard unit tests 6, stdio subprocess tests 5, E2E integration tests 14, and Sync checks 2.

- **Task**: _shared/2026-06-19-hermes-workflow-integration
- **Reviewer**: 金璃好帮手 (lead model, independent context)
- **Date**: 2026-06-20
- **Phase**: Archive complete (13/13 AC and 7/7 scenarios verified)

## Independent Re-Run Results

### 1. Skill Compatibility Tests (WP01 — AC01-04, AC08, AC10)

```
Command: .\.trae\scripts\test-hermes-skill-compatibility.ps1
Result: 27/27 passed
```

| Check | Result |
|-------|:------:|
| Adapter Skills exist (4) | ✅ |
| Adapter frontmatter valid (4) | ✅ |
| Canonical Skills resolve (4) | ✅ |
| No skill shadowing (2) | ✅ |
| external_dirs configured (2) | ✅ |
| No inline secrets (2) | ✅ |
| Bundle resolution (2) | ✅ |
| Profile structure (2) | ✅ |
| Policy manifest (4) | ✅ |
| Sync script exists | ✅ |

### 2. MCP Unit Tests (WP02 — AC05, AC06)

```
Command: python -m pytest .trae/hermes/tests/test_workflow_mcp.py -q
Result: 12 passed
```

| Check | Result |
|-------|:------:|
| Root containment | ✅ |
| Task path traversal rejection | ✅ |
| Absolute path outside root | ✅ |
| Task discovery | ✅ |
| Plan gate delegation | ✅ |
| Can-Edit delegation | ✅ |
| Claim collision safety | ✅ |
| Claim WP name validation | ✅ |
| Report content validation | ✅ |
| Report status validation | ✅ |
| Role-specific tool allowlists | ✅ |
| Implementer architecture boundary | ✅ |

### 3. Guard Plugin Unit Tests (WP03 — AC07)

```
Command: python -m pytest .trae/hermes/tests/test_workflow_guard.py -q
Result: 6 passed
```

| Check | Result |
|-------|:------:|
| Missing role blocks mutation | ✅ |
| Planner cannot edit app code | ✅ |
| Implementer requires task + WP | ✅ |
| Forbidden paths override allowed | ✅ |
| Read-only tools available when blocked | ✅ |
| Audit records redact secrets | ✅ |

### 4. Integration Tests (WP04 — AC08-11, AC13)

```
Command: .\.trae\scripts\test-hermes-workflow-integration.ps1
Result: 14/14 passed
```

| Check | Result |
|-------|:------:|
| Unknown role rejected | ✅ |
| Missing task rejected | ✅ |
| Missing WP rejected | ✅ |
| Planner dry-run resolves | ✅ |
| Implementer dry-run resolves | ✅ |
| Sync check passes | ✅ |
| Compatibility tests pass | ✅ |
| Runtime directory exists | ✅ |
| Profile sources exist (2) | ✅ |
| MCP package exists (2) | ✅ |
| Guard plugin exists (2) | ✅ |

### 5. Sync Check

```
Command: .\.trae\scripts\sync-hermes-workflow.ps1 -Check
Result: Passed: 2, Failed: 0
```

### 6. Documentation Governance

```
Command: doc-guard.ps1 check-task "_shared/2026-06-19-hermes-workflow-integration" -Stage implement
Result: DOCUMENTATION GOVERNANCE PASSED
```

### 7. Credential Check

Repository files scanned: no inline credential values detected.
Profile overlays intentionally omit `model` section — inherit user's existing config.yaml model configuration.
No env var references to unset variables remaining.

## Acceptance Criteria Evidence

| AC# | Description | Evidence |
|-----|-------------|:--------:|
| AC01 | Two role Profiles with Chinese identity | ✅ SOUL.md + config present |
| AC02 | Shared Skill root, no shadowing | ✅ 27/27 compat tests |
| AC03 | Four adapter Skills compatible | ✅ frontmatter valid |
| AC04 | Plan/Implement/Verify bundles resolve | ✅ bundle tests pass |
| AC05 | MCP typed, bounded, traversal-safe | ✅ 12/12 MCP tests |
| AC06 | Role-specific tool allowlists | ✅ planner/impl tool separation verified |
| AC07 | Guard blocks unauthorized mutation | ✅ 6/6 guard tests |
| AC08 | Sync idempotent, preserves user state | ✅ Check/Apply pass |
| AC09 | Launcher rejects invalid, resolves valid | ✅ 14/14 integration tests |
| AC10 | No inline credential | ✅ env-var references, scan clean |
| AC11 | Deterministic tests pass without live model | ✅ 66/66 total |
| AC12 | Hermes doctor + smoke tests | ✅ Both profiles pass doctor, API key inherited from config.yaml |
| AC13 | Operations/security docs + Verify | ✅ Docs/AI/39 exists, governance passed |

## Automated Verification

All automated verification commands have been independently re-run and recorded above. This section confirms that deterministic evidence supports every acceptance criterion.

| Command | Exit Code | Result |
|---------|:---------:|:------:|
| `test-hermes-skill-compatibility.ps1` | 0 | 27/27 PASS |
| `pytest test_workflow_mcp.py` | 0 | 12/12 PASS |
| `pytest test_workflow_guard.py` | 0 | 6/6 PASS |
| `test-hermes-workflow-integration.ps1` | 0 | 14/14 PASS |
| `sync-hermes-workflow.ps1 -Check` | 0 | No drift |
| `doc-guard check-task -Stage implement` | 0 | GOVERNANCE PASSED |
| `hermes -p jinli-planner doctor` | 0 | ✅ API key configured |
| `hermes -p jinli-implementer doctor` | 0 | ✅ API key configured |

**Total deterministic evidence: 66/66 checks pass + 2 Hermes doctor passes.**

## Architecture Compliance

The implemented architecture matches the approved design document (`Docs/superpowers/specs/2026-06-19-hermes-workflow-integration-design.md`):

- ✅ Two native Hermes Profiles (jinli-planner, jinli-implementer) — not prompt aliases
- ✅ Four thin adapter Skills — no domain content duplicated from canonical Skills
- ✅ Shared canonical Skill root via `skills.external_dirs` — no second truth source
- ✅ Typed `jinli-workflow` MCP server — delegates to authoritative `.trae/scripts`
- ✅ Fail-closed `jinli-workflow-guard` plugin — defense in depth, not sole boundary
- ✅ Repository-owned sync/launch adapters — runtime state preserved under `.tools`
- ✅ No Hermes core patch — only documented extension points used
- ✅ No inline credentials — env var references only
- ✅ Worker cannot own architecture or final verification — MCP + plugin enforce

No rejected shortcut was introduced. The selected mature path (native Profiles + shared Skills + MCP + guard plugin) was implemented as specified.

## Acceptance Criteria

| AC# | Description | Status | Evidence Source |
|-----|-------------|:------:|-----------------|
| AC01 | Two role Profiles with Chinese identity and repository cwd | ✅ | Skill compat 27/27 |
| AC02 | Shared canonical Skill root with no shadowing | ✅ | Skill compat 27/27 |
| AC03 | Four thin Hermes adapter Skills are compatible | ✅ | Skill compat 27/27 |
| AC04 | Plan/Implement/Verify bundles resolve | ✅ | Skill compat 27/27 |
| AC05 | Workflow MCP is typed, bounded, traversal-safe, delegates gates | ✅ | MCP tests 12/12 |
| AC06 | MCP tools are role-specific and Worker cannot own architecture/Verify | ✅ | MCP tests 12/12 |
| AC07 | Guard plugin blocks unauthorized mutation and enforces WP paths | ✅ | Guard tests 6/6 |
| AC08 | Sync is idempotent and preserves user state | ✅ | Integration 14/14 + sync check |
| AC09 | Launcher rejects invalid context and resolves valid dry-runs | ✅ | Integration 14/14 |
| AC10 | No inline credential remains; provider rotation is documented | ✅ | Compat scan + sync check |
| AC11 | Deterministic tests pass without live model | ✅ | 66/66 total |
| AC12 | Both Profiles pass doctor and optional Chinese smoke tests | ✅ | Doctor run for both profiles post-credential fix |
| AC13 | Operations/security docs and independent Verify evidence exist | ✅ | Doc guard PASS + this report |

**13/13 AC verified by deterministic evidence.**

## Test Evidence

All test execution output was captured during independent verification:

| Suite | Tests | Result | Command |
|-------|:-----:|:------:|---------|
| Skill Compatibility | 27 | PASS | `test-hermes-skill-compatibility.ps1` |
| MCP Unit Tests | 12 | PASS | `pytest test_workflow_mcp.py -q` |
| Guard Plugin | 6 | PASS | `pytest test_workflow_guard.py -q` |
| stdio subprocess | 5 | PASS | `pytest test_stdio_initialize.py -q` |
| E2E Integration | 14 | PASS | `test-hermes-workflow-integration.ps1` |
| Sync Check | 2 | PASS | `sync-hermes-workflow.ps1 -Check` |
| **Total** | **66** | **66/66 PASS** | — |

No test was accepted based on worker claims alone. All tests were independently re-run in this verification session.

## Residual Risks

1. Provider credential rotation remains an external human action. Revoke the previously exposed provider key if that has not already been completed.

## Total Test Summary

| Suite | Count | Result |
|-------|:------:|:------:|
| Skill Compatibility | 27 | 27/27 ✅ |
| MCP Unit Tests | 12 | 12/12 ✅ |
| Guard Plugin Unit Tests | 6 | 6/6 ✅ |
| stdio subprocess | 5 | 5/5 ✅ |
| E2E Integration | 14 | 14/14 ✅ |
| Sync checks | 2 | 2/2 ✅ |
| **Total** | **66** | **66/66 ✅** |
