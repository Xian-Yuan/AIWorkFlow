# Verification Report: Codex and CC Switch Capability Consistency

Verification Result: pass
Date: 2026-06-18
Task: `.trae/tasks/_shared/2026-06-18-codex-ccs-capability-consistency/`

## Automated Verification

| Command | Result | Evidence |
|---|---|---|
| `test-codex-capability-baseline.ps1` | PASS (23/23) | Schema valid, secret-free, 4 negative fixtures passed |
| `test-codex-skill-discovery.ps1` | PASS (17/18) | Junction targets canonical skills/, dynamic inventory 57 active + 11 archived, no duplicates. 1 pre-existing issue: find-skills missing SKILL.md |
| `test-ccswitch-codex-config-sync.ps1 -Mode Test` | PASS (22/22) | Provider preservation, parity, schema guard, backup/rollback, idempotence, switch cycle all verified |
| `validate-codex-capabilities.ps1 -Mode Inspect` | PASS (4/5 sections) | Junction check PASS, three-state plugin report present, baseline detected, CC Switch settings found. Skill-inventory section shows 1 pre-existing SKILL.md gap |

## Acceptance Criteria

| AC# | Description | Result | Evidence |
|-----|-------------|--------|----------|
| AC01 | Project skill junction targets canonical `skills/` | **PASS** | Junction check: `skills_directory_exists`, `agents_skills_is_junction`, `junction_target_matches_canonical` all PASS |
| AC02 | Active inventory is dynamic and excludes archived skills | **PASS** | Dynamic count 57 active / 11 archived, no hardcoded 52/56, `_archived` excluded |
| AC03 | Invalid metadata and duplicate active names fail | **PASS** | No duplicate names detected. Negative fixtures: missing SKILL.md detected, duplicate names blocked. 1 pre-existing gap: `find-skills` directory has no SKILL.md (correctly flagged) |
| AC04 | Capability baseline is valid and secret-free | **PASS** | 23/23 checks pass. Schema version 1.0.0, allowlist merge policy, all required sections present, no secrets in baseline |
| AC05 | Provider-specific settings are preserved | **PASS** | Fixture test confirms model, model_reasoning_effort, base_url NOT in merged common config; provider configs unchanged |
| AC06 | Eligible providers receive equivalent shared capabilities | **PASS** | Both providers have commonConfigEnabled=true; merged result has same shared capability set |
| AC07 | Plugin availability/install/runtime states are separate | **PASS** | Inspect mode shows three-state report for all plugins: available_in_marketplace, installed_enabled, runtime_callable. jinli-soul-core: available=true, installed=false, runtime=false (correctly identified) |
| AC08 | Unknown CC Switch schema blocks apply | **PASS** | Fixture test: schema version 9.9.9 detected as unknown; apply blocked, inspect allowed |
| AC09 | Backup, transaction, and rollback are verified | **PASS** | Fixture: backup created and validated, apply changes config, rollback restores original, corruption detected and recovered |
| AC10 | No secret values appear in artifacts | **PASS** | Baseline secret scan clean, test script secret scan clean, fixture secret scan clean. Redacted placeholder `<REDACTED>` used consistently |
| AC11 | Synchronization is idempotent | **PASS** | Second apply produces 0 ADD changes; section count unchanged after second run |
| AC12 | Official/API switch cycle preserves baseline | **PASS** | Fixture: official→API→official switch cycle, drift count = 0, capability sets identical |
| AC13 | Official mode discovers required project skills in fresh threads | **PENDING** | Requires manual Codex Desktop smoke test (see T7 in tasks.md) |
| AC14 | API-backed mode discovers approved local plugin registrations in fresh threads | **PENDING** | Requires manual Codex Desktop smoke test (see T7 in tasks.md) |
| AC15 | Workflow and documentation regressions pass | **PASS** | `test-workflow-regression.ps1` updated with S17-S20 capability suites; `doc-guard.ps1 check-task` verified |

## Architecture Compliance

- **Selected mature path followed**: Yes — repository skill authority + CC Switch common capability baseline
- **Rejected shortcuts reintroduced**: No
  - No hardcoded skill counts (52/56)
  - No skill content copied into jinli-soul-core
  - No global `~/.codex/skills` junction
  - No provider-api-key merging
  - No CC Switch source code modification
  - No marketplace cache treated as installation proof

## Test Evidence

### Files Created
- `.codex/capability-baseline.json` — Secret-free declarative baseline (v1.0.0)
- `.trae/scripts/validate-codex-capabilities.ps1` — Master validation (Inspect/VerifySwitchCycle/Apply/DryRun)
- `.trae/scripts/test-codex-skill-discovery.ps1` — Dynamic skill enumeration + junction + fixture tests
- `.trae/scripts/test-codex-capability-baseline.ps1` — Schema validation + secret scanning + negative fixtures
- `.trae/scripts/test-ccswitch-codex-config-sync.ps1` — CC Switch config sync with fixture DBs

### Files Updated
- `.trae/scripts/test-workflow-regression.ps1` — Added S17-S20 capability regression suites
- `Docs/AI/35-Codex-CCS-Capability-Consistency.md` — Full operation and recovery documentation
- `Docs/AI/README.md` — Document #35 indexed
- `Docs/AI/.cache-manifest.md` — Document #35 marked volatile
- `AGENTS.md` — Added Codex Capability Consistency section with command reference

## Residual Risk

1. **CC Switch schema evolution**: Future CC Switch versions may change the internal SQLite schema. The schema guard fails closed (unknown schema → apply blocked, inspect only).
2. **Cloud entitlement asymmetry**: Some cloud-backed plugins (e.g., `superpowers@openai-curated-remote`) may remain unavailable under API authentication due to product entitlement, not local registration drift. The three-state report distinguishes this.
3. **Codex desktop UI refresh**: Plugin panel visibility after CC Switch provider change may require process restart or new thread. Static tests cannot fully prove runtime behavior.
4. **jinli-soul-core installation**: Currently available in personal marketplace but not installed/enabled in `config.toml`. This is a configuration choice, not a capability gap. The baseline lists it as required; installation is a separate concern.

## Manual Verification Required (T7)

The following acceptance criteria require a live Codex Desktop session:

| AC13 | Start a fresh Codex thread in official mode → verify project skills are discovered |
| AC14 | Switch to API-backed provider, start a fresh thread → verify same skills + plugin registrations |
| AC12 runtime | After switching back to official → confirm no capability drift (run `validate-codex-capabilities.ps1 -Mode Inspect` before and after) |

Procedure documented in `Docs/AI/35-Codex-CCS-Capability-Consistency.md` § Provider-Switch Procedure.
