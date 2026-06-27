# Spec: Codex and CC Switch Capability Consistency

## GIVEN

1. The repository owns project skills under `E:\UEGameDevelopment\skills`.
2. Codex discovers repository skills through `E:\UEGameDevelopment\.agents\skills`.
3. CC Switch can route Codex requests to official or API-backed model providers.
4. CC Switch stores provider-specific Codex configuration snapshots and a separate common Codex configuration.
5. API-backed provider snapshots currently omit plugin and marketplace sections.
6. The personal marketplace contains `jinli-soul-core`, while its installed/enabled/runtime state may differ.
7. Credentials, provider secrets, connector authorization, sessions, and caches must remain isolated.

## WHEN

A mature capability-consistency layer is implemented for repository skills, Codex plugins, and CC Switch provider switching.

## THEN

### S01: Canonical project-skill discovery

**Status**: [x]

Given the canonical source is `E:\UEGameDevelopment\skills`, when Codex skill discovery is validated, then `.agents/skills` must resolve to that source and no copied project-skill tree may be treated as authoritative.

### S02: Dynamic active-skill inventory

**Status**: [x]

Given skills may be added, removed, or archived, when the inventory is generated, then the active count must be computed dynamically, archived skills must be excluded, required metadata must be validated, and duplicate active names must fail validation.

### S03: Declarative shared capability baseline

**Status**: [x]

Given provider-independent settings need to survive CC Switch switching, when the baseline is loaded, then it must declare required marketplaces, plugins, safe MCP IDs, merge ownership, and secret exclusions without containing credentials or machine-generated session state.

### S04: Provider-specific configuration preservation

**Status**: [x]

Given each CC Switch provider owns its model and API settings, when shared capabilities are synchronized, then provider ID, model, base URL, API format, reasoning compatibility, and authentication must remain semantically unchanged.

### S05: Common configuration normalization

**Status**: [x]

Given CC Switch common configuration is the provider-independent layer, when normalization runs, then every eligible Codex provider must enable the common layer and resolve to the same required shared capability set.

### S06: Plugin lifecycle state separation

**Status**: [x]

Given a plugin can exist in a marketplace without being installed or callable, when plugin status is reported, then `available`, `installed/enabled`, and `runtime callable` must be separate fields with separate evidence.

### S07: Guarded apply and rollback

**Status**: [x]

Given configuration mutation can corrupt a provider setup, when apply mode runs, then it must verify schema compatibility, detect unsafe running state, create and validate a backup, use a transaction, validate the result, and automatically roll back on failure.

### S08: Secret isolation

**Status**: [x]

Given authentication data is outside the shared capability boundary, when baseline, diagnostics, fixtures, logs, and reports are produced, then no API key, OAuth token, auth payload, session token, cookie, or connector credential may be included.

### S09: Drift and idempotence

**Status**: [x]

Given CC Switch may rewrite live Codex configuration during provider switching, when official -> API -> official is exercised, then required shared capabilities must remain equivalent and a second synchronization run must produce no changes.

### S10: Runtime verification

**Status**: [x]

Given static configuration cannot prove Codex desktop reload behavior, when verification is completed, then fresh-thread smoke tests in official and API-backed modes must confirm project-skill discovery and approved local plugin registration, with unsupported cloud authorization reported separately.

## Acceptance Criteria

| AC# | Description | Verification Command | Expected Output |
|-----|-------------|---------------------|-----------------|
| AC01 | Project skill junction targets canonical `skills/` | `.\.trae\scripts\validate-codex-capabilities.ps1 -Mode Inspect` | Junction check PASS |
| AC02 | Active inventory is dynamic and excludes archived skills | `.\.trae\scripts\test-codex-skill-discovery.ps1` | Dynamic inventory cases PASS |
| AC03 | Invalid metadata and duplicate active names fail | `.\.trae\scripts\test-codex-skill-discovery.ps1` | Negative fixtures blocked |
| AC04 | Capability baseline is valid and secret-free | `.\.trae\scripts\test-codex-capability-baseline.ps1` | Schema and secret checks PASS |
| AC05 | Provider-specific settings are preserved | `.\.trae\scripts\test-ccswitch-codex-config-sync.ps1` | Preservation fixture PASS |
| AC06 | Eligible providers receive equivalent shared capabilities | `.\.trae\scripts\test-ccswitch-codex-config-sync.ps1` | Provider parity PASS |
| AC07 | Plugin availability/install/runtime states are separate | `.\.trae\scripts\validate-codex-capabilities.ps1 -Mode Inspect` | Three-state report present |
| AC08 | Unknown CC Switch schema blocks apply | `.\.trae\scripts\test-ccswitch-codex-config-sync.ps1` | Schema mismatch blocked |
| AC09 | Backup, transaction, and rollback are verified | `.\.trae\scripts\test-ccswitch-codex-config-sync.ps1` | Rollback fixture PASS |
| AC10 | No secret values appear in artifacts | `.\.trae\scripts\test-codex-capability-baseline.ps1` | Secret scan PASS |
| AC11 | Synchronization is idempotent | `.\.trae\scripts\test-ccswitch-codex-config-sync.ps1` | Second-run diff empty |
| AC12 | Official/API switch cycle preserves baseline | `.\.trae\scripts\validate-codex-capabilities.ps1 -Mode VerifySwitchCycle` | Capability drift count 0 |
| AC13 | Both modes discover required project skills in fresh threads | Manual smoke protocol recorded in `verification-report.md` | PASS with evidence |
| AC14 | Both modes expose approved local plugin registrations | Manual smoke protocol recorded in `verification-report.md` | PASS or entitlement-separated finding |
| AC15 | Workflow and documentation regressions pass | `.\.trae\scripts\test-workflow-regression.ps1`; `.\.trae\scripts\test-doc-guard.ps1` | Both exit 0 |

## Progress Summary

| Phase | Status | Key Decision |
|-------|--------|-------------|
| Plan | Complete | Single skill authority plus CC Switch common capability baseline |
| Implement | Pending | Requires Plan gate transition |
| Review | Pending | Independent review required |
| Verify | Pending | Automated tests plus two-mode runtime smoke |

## Non-Goals

- Share credentials between official and API-backed authentication.
- Install all cached curated plugins.
- Copy project skills into a plugin.
- Use a global project-skill junction outside the repository.
- Modify any UE5 or Web project code.
- Promise identical cloud entitlements between authentication modes.

