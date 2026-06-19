# Codex and CC Switch Capability Consistency Design

Date: 2026-06-18
Status: Approved design
Scope: Codex project skills, local plugins, CC Switch provider configuration, automated validation

## Goal

Make the UEGameDevelopment project skills and approved local Codex plugins consistently available when Codex switches between official ChatGPT authentication and API-backed models routed through CC Switch, without sharing credentials or duplicating skill sources.

## Confirmed Current State

1. `E:\UEGameDevelopment\skills` is the canonical project-skill source.
2. `E:\UEGameDevelopment\.agents\skills` is a Windows junction to the canonical source.
3. Codex currently discovers 56 active project skills through that junction. The count is dynamic and must not be hard-coded as 52 or 56.
4. `C:\Users\87372\.codex` is a junction to `C:\Users\87372\.codex-shared`.
5. CC Switch stores a separate Codex provider configuration snapshot for each provider.
6. The CC Switch Codex common configuration currently contains only part of the desired marketplace and plugin configuration.
7. API-backed provider snapshots omit plugin and marketplace sections, which makes the Codex plugin panel appear different after provider switching.
8. `jinli-soul-core` exists in the personal marketplace and has a valid plugin manifest, but plugin installation/enabling is a separate concern from project-skill discovery.

## Architecture

### Layer 1: Repository Skill Authority

```text
E:\UEGameDevelopment\skills
        |
        +-- .agents\skills junction for Codex discovery
        +-- OpenCode adapter or junction
```

`skills/` remains the only editable source for project skills. Discovery adapters may point to it, but must not copy its contents.

### Layer 2: Declarative Capability Baseline

The repository owns a machine-readable baseline that declares:

- required project-skill source and adapter path;
- required local marketplaces;
- required plugin identifiers;
- required MCP identifiers that are safe to share;
- sections that are provider-specific and must never be overwritten;
- sections that may contain secrets and must never be exported.

The baseline contains identifiers and policy, not credentials, absolute runtime installation paths, OAuth tokens, API keys, session state, or generated caches.

### Layer 3: CC Switch Common Configuration

CC Switch common configuration is the supported distribution layer for provider-independent Codex settings. All Codex providers that support common configuration must opt into the same baseline.

Provider snapshots continue to own:

- provider ID and model;
- API base URL;
- protocol or API format;
- provider authentication;
- provider-specific reasoning and compatibility settings.

The common layer owns:

- marketplace registrations;
- approved plugin enablement records;
- safe MCP declarations;
- stable feature flags;
- project trust settings where portable;
- other explicitly allowlisted provider-independent settings.

### Layer 4: Runtime Verification

Validation runs at three levels:

1. Static: paths, junction targets, skill manifests, plugin manifests, marketplace entries, and baseline schema.
2. Configuration: the effective shared capability set is equivalent for every enabled CC Switch Codex provider.
3. Runtime smoke: after a real provider switch and a fresh Codex thread, required skills and plugins are discoverable.

## Configuration Merge Rules

The merge is allowlist-based and fail-closed.

Shared sections may be added or updated only when declared in the capability baseline. Provider-specific and secret-bearing fields are preserved byte-for-byte or semantically unchanged.

The implementation must prefer an official CC Switch common-configuration interface when available. If no supported CLI or import API exists, an offline database migration is permitted only when all of these safeguards exist:

- CC Switch and Codex write processes are stopped or the migration runs in a vendor-supported maintenance state;
- database schema and expected table/column signatures are verified;
- a timestamped backup is created and validated before mutation;
- the update runs in a transaction;
- only `common_config_codex` and the provider `commonConfigEnabled` flag may be changed;
- provider auth and provider configuration payloads are not rewritten;
- post-write validation runs before success is reported;
- rollback is automatic on validation failure.

Direct edits to `auth.json`, provider API keys, OAuth tokens, Codex session databases, or plugin caches are prohibited.

## Plugin Policy

Plugin availability has three distinct states:

1. Available in a marketplace.
2. Installed and enabled in Codex configuration.
3. Runtime callable after authentication and process reload.

The system must report these states separately. A marketplace entry alone must not be reported as an installed plugin.

The initial required baseline includes:

- the currently approved bundled and primary-runtime plugins;
- `jinli-soul-core@personal`;
- their required marketplace registrations.

Cached curated plugins are not automatically installed. They enter the baseline only through an explicit user decision.

## Security Boundary

The following data must remain local and unshared:

- `auth.json`;
- ChatGPT session tokens;
- API keys;
- OAuth and connector credentials;
- cookies and browser profiles;
- Codex session/history databases;
- CC Switch provider secrets;
- machine-specific runtime paths unless generated locally.

Diagnostics and reports may contain booleans, identifiers, section names, hashes, and redacted differences. They must never contain secret values.

## Failure Behavior

- A missing or incorrect project-skill junction blocks validation.
- An invalid active `SKILL.md` blocks validation.
- Archived skills are excluded from the active capability set.
- Unknown CC Switch schema blocks apply mode and permits inspect mode only.
- A running-process or file-lock conflict blocks mutation.
- Provider-specific field drift blocks success.
- A failed post-switch smoke test records a failed acceptance criterion even if static configuration looks correct.
- The system must retain the last known-good backup and produce a deterministic rollback command.

## Testing Strategy

Automated tests use temporary fixture directories and a temporary SQLite database. They must cover:

- dynamic skill discovery;
- invalid and duplicate skill detection;
- junction target validation;
- common/provider configuration classification;
- allowlisted merge behavior;
- preservation of auth and provider-specific fields;
- schema mismatch failure;
- transaction rollback;
- secret redaction;
- provider-switch capability parity;
- local plugin manifest and marketplace validation.

A controlled manual smoke test remains necessary for the Codex desktop UI because plugin panel refresh and new-thread loading are runtime product behavior.

## Non-Goals

- Sharing ChatGPT or API credentials between authentication modes.
- Installing every plugin present in a cache.
- Copying all project skills into `jinli-soul-core`.
- Moving project skills into global `~/.codex/skills`.
- Treating CC Switch provider selection as a separate Codex account.
- Modifying UE5 or Web project code.

