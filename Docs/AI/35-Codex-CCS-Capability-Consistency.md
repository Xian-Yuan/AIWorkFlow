---
domain: ai
domain_path: ai/coding
kg_node_id: node.doc-ai-ai-35-codex-ccs-capability-consistency-c8df
t13_retro_classified_at: "2026-06-24T04:47:04Z"
kg_id: doc.ai.ai.35-codex-ccs-capability-consistency.c8df

---

# 35: Codex and CC Switch Capability Consistency

Status: Active
Version: 1.0.0
Last Updated: 2026-06-18
Owner: workflow

## Purpose

This document defines the capability-consistency layer that ensures Codex discovers the same project skills and approved local plugins whether running under official ChatGPT authentication or API-backed models routed through CC Switch.

## Architecture

### Layer 1: Repository Skill Authority

`E:\UEGameDevelopment\skills` is the canonical source. Codex discovers skills through `E:\UEGameDevelopment\.agents\skills` (a Windows junction). No skill content is copied into plugins or global directories.

### Layer 2: Declarative Capability Baseline

`.codex/capability-baseline.json` declares the desired provider-independent state:

- Required marketplaces: openai-bundled, openai-primary-runtime, personal
- Required plugins: documents, pdf, spreadsheets, presentations, computer-use, chrome, browser, jinli-soul-core
- Safe MCP IDs: node_repl
- Provider-owned fields: model, API URL, auth, reasoning settings
- Secret exclusions: all auth tokens, API keys, cookies

The baseline contains identifiers and policy only. It never contains credentials, runtime paths, or session state.

### Layer 3: CC Switch Common Configuration

CC Switch stores a `common_config_codex` setting that applies to all Codex providers with `commonConfigEnabled: true`. The synchronization is **allowlist-based and fail-closed**:

- Only sections declared in the capability baseline are merged
- Provider-specific sections (model, auth, URL, etc.) are preserved byte-for-byte
- Unknown CC Switch schema blocks apply, allows inspect only
- Every mutation uses: **backup → transaction → validate → rollback on failure**

### Layer 4: Runtime Verification

Three levels of validation:

| Level | Type | How |
|---|---|---|
| Static | paths, junctions, manifests | `test-codex-skill-discovery.ps1` |
| Configuration | shared capability parity | `test-ccswitch-codex-config-sync.ps1` |
| Runtime | fresh-thread smoke test | Manual protocol (see below) |

## Command Reference

### Inspect current state

```powershell
# Full capability inspection (junction, inventory, plugins, baseline, CC Switch)
.\.trae\scripts\validate-codex-capabilities.ps1 -Mode Inspect
```

### Validate project skill discovery

```powershell
# Dynamic inventory, junction check, metadata validation, fixture tests
.\.trae\scripts\test-codex-skill-discovery.ps1
```

### Validate capability baseline

```powershell
# Schema check, secret scanning, negative fixtures
.\.trae\scripts\test-codex-capability-baseline.ps1
```

### Test CC Switch config sync

```powershell
# Full test suite (fixture-based): preservation, parity, schema guard, backup, rollback, idempotence
.\.trae\scripts\test-ccswitch-codex-config-sync.ps1 -Mode Test

# Inspect live CC Switch state (read-only)
.\.trae\scripts\test-ccswitch-codex-config-sync.ps1 -Mode Inspect

# Preview changes without applying
.\.trae\scripts\test-ccswitch-codex-config-sync.ps1 -Mode DryRun
```

### Full regression suite

```powershell
# Includes all new capability tests as S17-S20
.\.trae\scripts\test-workflow-regression.ps1
```

## Provider-Switch Procedure

1. **Before switch**: Run `validate-codex-capabilities.ps1 -Mode Inspect` and record the redacted baseline
2. **Switch** in CC Switch UI to the desired provider
3. **After switch**: Run inspect again and compare
4. **Drift check**: Run `test-ccswitch-codex-config-sync.ps1 -Mode Test` to confirm shared capabilities are equivalent

## Plugin Three-State Reporting

The `validate-codex-capabilities.ps1 -Mode Inspect` command reports each plugin with three independent states:

| State | Meaning | Evidence |
|---|---|---|
| Available in marketplace | The marketplace entry exists | Config TOML or marketplace directory |
| Installed/Enabled | The plugin is listed and enabled in config | `enabled = true` in config |
| Runtime callable | Available for use after process reload | Installed + enabled + reload |

A marketplace entry alone does not indicate installation.

## Security Boundaries

The following must **never** appear in baselines, diagnostics, fixtures, logs, or reports:

- `auth.json` contents
- ChatGPT session tokens
- API keys (OpenAI, Volcengine, etc.)
- OAuth and connector credentials
- Cookies and browser profiles
- Codex session/history databases
- CC Switch provider secrets
- Machine-specific runtime paths (unless generated locally)

Reports may contain booleans, identifiers, section names, hashes, and redacted differences.

## Failure Behavior

| Failure | Behavior |
|---|---|
| Missing or incorrect project-skill junction | Validation blocks |
| Invalid active SKILL.md | Validation blocks |
| Archived skills | Excluded from active set |
| Unknown CC Switch schema | Apply blocked; inspect allowed |
| Running process conflict | Mutation blocked |
| Provider-specific field drift | Success blocked |
| Failed post-switch smoke test | AC recorded as failed |
| Post-write corruption | Automatic rollback from backup |

## Ownership

| State | Owner | Mutation Rule |
|---|---|---|
| Project skill source | Repository `skills/` | Edit only canonical skill directories |
| Codex skill discovery adapter | Repository `.agents/skills` | Junction must target canonical source |
| Desired capability baseline | Repository `.codex/` | Version-controlled, secret-free |
| Codex live configuration | Active Codex home | Generated/synchronized, not canonical |
| CC Switch common Codex config | CC Switch | Updated through supported interface or guarded offline migration |
| Provider model/API settings | Individual CC Switch provider | Preserved; never normalized |
| Plugin source | Local marketplace | Validate manifest; do not duplicate into project skills |
| Credentials and sessions | Authentication runtime | Never exported, merged, or reported |

## Residual Risks

1. CC Switch may change its internal schema in a future version. The schema guard must fail closed.
2. Some cloud-backed plugins or connectors may remain unavailable under API authentication due to product entitlement. The report distinguishes this from local registration drift.
3. Codex desktop plugin-panel refresh may require process restart or a new thread and cannot be fully proven by static tests alone.

## Related Documents

- `Docs/superpowers/specs/2026-06-18-codex-ccs-capability-consistency-design.md` — Architecture design spec
- `.codex/capability-baseline.json` — Declarative desired-state baseline
- `.trae/tasks/_shared/2026-06-18-codex-ccs-capability-consistency/` — Task packet
- `Docs/AI/29-Mature-Solution-First-Workflow.md` — Quality gate reference
- `Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md` — Workflow packet reference
