# Analysis: Codex and CC Switch Capability Consistency

## Problem Statement

Codex shows different plugin sets when switching between official authentication and API-backed models through CC Switch. Earlier analysis incorrectly treated this as two Codex accounts and assumed project skills were unavailable. Local inspection on 2026-06-18 established that:

- Codex already discovers the repository project skills;
- CC Switch stores provider-specific Codex configuration snapshots;
- the API provider snapshots omit plugin and marketplace sections;
- CC Switch common configuration is enabled but contains only a partial shared capability set.

The architecture must therefore normalize provider-independent capabilities without merging credentials or copying skills.

## Architecture Context

### System boundaries

In scope:

- project skill source and Codex discovery adapter;
- declarative capability baseline;
- Codex marketplace/plugin/MCP configuration classification;
- CC Switch common Codex configuration;
- provider-switch consistency checks;
- backup, rollback, diagnostics, and regression tests.

Out of scope:

- UE5 and Web project implementation;
- ChatGPT account entitlements;
- API provider credentials;
- cloud connector authorization;
- automatically installing every cached curated plugin;
- changing CC Switch source code.

### Dependency map

```text
skills/
  -> .agents/skills junction
  -> skill inventory validator

capability baseline
  -> Codex config inspector
  -> CC Switch common-config synchronizer
  -> provider parity validator

personal marketplace
  -> jinli-soul-core manifest validator
  -> plugin desired-state validator

all validators
  -> regression suite
  -> verification-report.md
```

### Data and state ownership

| State | Owner | Mutation Rule |
|---|---|---|
| Project skill source | Repository `skills/` | Edit only canonical skill directories |
| Codex skill discovery adapter | Repository `.agents/skills` | Junction must target canonical source |
| Desired capability baseline | Repository `.codex/` | Version-controlled, secret-free |
| Codex live configuration | Active Codex home | Generated or synchronized, never treated as canonical |
| CC Switch common Codex config | CC Switch | Updated through supported interface or guarded offline migration |
| Provider model/API settings | Individual CC Switch provider | Preserve; never normalized as shared capability |
| Plugin source | Local marketplace/plugin directory | Validate manifest; do not duplicate into project skills |
| Credentials and sessions | Authentication runtime | Never exported, merged, or reported |

### Integration points

- Codex project customization: `.agents/skills`, `AGENTS.md`, trusted project configuration.
- Codex plugin system: marketplaces, plugin installation records, local plugin manifests.
- CC Switch: `common_config_codex`, provider `commonConfigEnabled`, provider snapshots, local proxy mode.
- Existing workflow: `.trae/scripts`, task packets, `task-guard.ps1`, `doc-guard.ps1`.

## Current Evidence

| Evidence | Result |
|---|---|
| `E:\UEGameDevelopment\.agents\skills` | Junction to `E:\UEGameDevelopment\skills` |
| Active project skills | 56 at inspection time; count is dynamic |
| `C:\Users\87372\.codex` | Junction to `.codex-shared` |
| CC Switch Codex providers | Official plus API-backed providers |
| API provider plugin sections | None in inspected provider snapshots |
| API provider marketplace sections | None in inspected provider snapshots |
| `common_config_codex` | Exists, partial shared sections only |
| Provider `commonConfigEnabled` | Enabled for inspected API providers |
| `jinli-soul-core` | Present in personal marketplace; manifest parses successfully |

## Security and Reliability Constraints

- No secret value may enter repository files, logs, fixtures, diffs, or verification reports.
- Apply mode must not run against an unknown CC Switch schema.
- Configuration mutation must be transactional and reversible.
- Runtime paths are generated locally rather than committed as portable configuration.
- Effective capability parity means the same required local skills and approved plugin registrations, not identical cloud entitlements.

## Mature Solution Evidence

### Project-local evidence

- `.agents/skills` already provides the correct single-source project skill adapter.
- `skills/codex-project-router/SKILL.md` already requires shared task packets and mechanical gates.
- `Docs/AI/29-Mature-Solution-First-Workflow.md` rejects temporary copying and reduced-quality shortcuts.
- `Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md` requires architecture context, acceptance criteria, and automated verification.
- Local CC Switch data proves provider-specific config snapshots are the source of plugin drift.

### Official/framework evidence

- OpenAI Codex customization separates repository instructions, project skills, configuration, plugins, and authentication.
- Codex plugins are installable bundles and require marketplace/install state in addition to files on disk.
- Codex configuration is rooted in the active Codex home and project configuration, while authentication remains a separate boundary.
- References:
  - https://developers.openai.com/codex/concepts/customization
  - https://developers.openai.com/codex/config-basic/
  - https://developers.openai.com/codex/config-reference/
  - https://developers.openai.com/codex/plugins/
  - https://developers.openai.com/codex/auth/

### External mature references

- CC Switch exposes common Codex configuration and provider-specific configuration as separate concepts in the installed runtime.
- Transactional migration, schema guards, backup-before-write, and fail-closed validation are standard requirements when integrating with a third-party SQLite configuration store.

### Options compared

| Option | Pros | Cons | Decision |
|---|---|---|---|
| Copy every project skill into `jinli-soul-core` | Plugin install makes skills global | Duplicates sources, causes drift, pollutes unrelated projects | Rejected |
| Point global `~/.codex/skills` at the repository | Simple global visibility | Machine/account coupling and cross-project pollution | Rejected |
| Copy one full `config.toml` across providers | Superficially identical configuration | Overwrites provider URL, model, auth, and runtime paths | Rejected |
| Repository skill authority plus CC Switch common capability baseline | Preserves ownership, provider isolation, and automated parity | Requires baseline schema, merge logic, and tests | Selected |

### Rejected shortcuts

- Hard-code the current skill count as 52 or 56.
- Manually add plugin blocks to each provider after every switch.
- Treat marketplace presence as proof that a plugin is installed.
- Edit `auth.json` or copy authentication state.
- Directly edit the CC Switch database without schema checks, backup, transaction, and rollback.
- Validate only `config.toml` without performing a fresh-thread runtime smoke test.

### Selected mature path

Keep repository skills single-sourced through `.agents/skills`. Introduce a secret-free desired capability baseline and validators. Use CC Switch common configuration as the provider-independent distribution layer. Preserve provider-specific API configuration and authentication. Add guarded synchronization, rollback, drift detection, and runtime smoke tests.

## Acceptance Criteria

| ID | Requirement | Verification |
|---|---|---|
| AC01 | `.agents/skills` resolves to the canonical repository `skills/` directory | Junction/path validator exits 0 |
| AC02 | Active skills are discovered dynamically and archived skills are excluded | Inventory test passes without a hard-coded count |
| AC03 | Every active skill has valid required metadata and duplicate names are reported | Skill validation suite exits 0 |
| AC04 | A secret-free capability baseline declares required marketplaces, plugins, MCP IDs, and merge policy | Baseline schema validation exits 0 |
| AC05 | Provider-specific model, URL, API format, reasoning settings, and auth remain unchanged after normalization | Fixture preservation test passes |
| AC06 | All common-config-enabled Codex providers resolve to the same required shared capability set | Provider parity test exits 0 |
| AC07 | `jinli-soul-core@personal` is distinguished as available, installed/enabled, and runtime-callable | Plugin state report shows three separate states |
| AC08 | Unknown CC Switch schema blocks apply mode but allows redacted inspect mode | Schema mismatch test passes |
| AC09 | Apply mode creates a validated backup, uses a transaction, and rolls back on post-write failure | Rollback integration test passes |
| AC10 | Reports and fixtures contain no API keys, tokens, auth payloads, or unredacted secrets | Secret scanner exits 0 |
| AC11 | Re-running synchronization is idempotent and produces no config churn | Second-run diff is empty |
| AC12 | Switching official -> API -> official preserves the required shared capability inventory | Switch-cycle verification passes |
| AC13 | A fresh Codex thread in official and API-backed modes discovers required project skills | Runtime smoke checklist passes |
| AC14 | A fresh Codex thread in official and API-backed modes shows approved local plugin registrations | Runtime smoke checklist passes |
| AC15 | Workflow regression, documentation guard, and task verification report all pass | Required commands exit 0 |

## Automated Verification Plan

Planned commands:

```powershell
& .\.trae\scripts\test-codex-skill-discovery.ps1
& .\.trae\scripts\test-codex-capability-baseline.ps1
& .\.trae\scripts\test-ccswitch-codex-config-sync.ps1
& .\.trae\scripts\validate-codex-capabilities.ps1 -Mode Inspect
& .\.trae\scripts\test-workflow-regression.ps1
& .\.trae\scripts\test-doc-guard.ps1
& .\.trae\scripts\task-guard.ps1 "_shared/2026-06-18-codex-ccs-capability-consistency" verify
```

Expected:

- all test scripts exit 0;
- no secret scanner findings;
- provider parity reports no missing required capability;
- idempotence check reports no second-run changes;
- runtime smoke evidence is recorded in `verification-report.md`.

## Residual Risks

- CC Switch may change its internal schema in a future version. The schema guard must fail closed.
- Some cloud-backed plugins or connectors may remain unavailable under API authentication because of product entitlement or OAuth requirements. The report must distinguish this from local registration drift.
- Codex desktop plugin-panel refresh may require process restart or a new thread and cannot be fully proven by static tests alone.

