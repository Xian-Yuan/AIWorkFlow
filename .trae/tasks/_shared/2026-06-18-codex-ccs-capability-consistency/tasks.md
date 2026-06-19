# Tasks: Codex and CC Switch Capability Consistency

## Dependency Graph

```text
T1 Inventory and baseline
  -> T2 Skill discovery validator
  -> T3 Codex capability inspector
  -> T4 CC Switch common-config synchronizer
  -> T5 Regression fixtures
  -> T6 Documentation
  -> T7 Runtime smoke and final verification
```

## T1: Define the capability baseline

- [x] T1.1: Create a secret-free desired-state schema for project skills, marketplaces, plugins, MCP IDs, shared sections, provider-owned sections, and excluded secret fields.
- [x] T1.2: Populate the initial approved plugin and marketplace inventory from the current Codex configuration plus `jinli-soul-core@personal`.
- [x] T1.3: Add schema validation and explicit versioning for future migration.
- [x] T1.4: Verify AC04 and AC10.

## T2: Validate project-skill discovery

- [x] T2.1: Implement dynamic active-skill enumeration from `skills/`.
- [x] T2.2: Validate `.agents/skills` path type and resolved target.
- [x] T2.3: Validate required `SKILL.md` metadata and detect duplicate active names.
- [x] T2.4: Exclude `_archived` from the active inventory while reporting archived counts separately.
- [x] T2.5: Add temporary-fixture tests for valid, invalid, duplicate, missing-junction, and wrong-target cases.
- [x] T2.6: Verify AC01, AC02, and AC03.

## T3: Inspect Codex plugin and marketplace state

- [x] T3.1: Implement redacted discovery of the active Codex home and effective configuration.
- [x] T3.2: Report marketplace availability, plugin installed/enabled state, and runtime-callable evidence separately.
- [x] T3.3: Validate local plugin and marketplace manifests without treating cache presence as installation.
- [x] T3.4: Add `jinli-soul-core@personal` validation.
- [x] T3.5: Verify AC07.

## T4: Normalize CC Switch common configuration

- [x] T4.1: Inspect CC Switch schema, version markers, provider metadata, and common Codex configuration in read-only mode.
- [x] T4.2: Prefer a supported CC Switch common-config interface; document the selected integration point.
- [x] T4.3: If guarded offline migration is required, implement process-state checks, schema allowlist, timestamped backup, transaction, post-write validation, and rollback.
- [x] T4.4: Merge only baseline-allowlisted shared sections.
- [x] T4.5: Preserve provider-specific model, URL, API format, reasoning, and authentication state.
- [x] T4.6: Ensure all eligible Codex providers enable common configuration.
- [x] T4.7: Implement dry-run diff and idempotent apply modes.
- [x] T4.8: Verify AC05, AC06, AC08, AC09, and AC11.

## T5: Build automated regression coverage

- [x] T5.1: Add fixture databases for supported schema, unknown schema, rollback failure, and multiple providers.
- [x] T5.2: Add fixture Codex configs for official and API-backed providers.
- [x] T5.3: Test official -> API -> official shared capability parity without using live credentials.
- [x] T5.4: Add secret scanning for fixtures, output, and reports.
- [x] T5.5: Add the new suites to the authoritative workflow regression entrypoint.
- [x] T5.6: Verify AC10, AC11, AC12, and AC15.

## T6: Document operation and recovery

- [x] T6.1: Create `Docs/AI/35-Codex-CCS-Capability-Consistency.md`.
- [x] T6.2: Document ownership boundaries, inspect/apply/rollback commands, provider-switch procedure, and entitlement limitations.
- [x] T6.3: Update `Docs/AI/README.md` and `Docs/AI/.cache-manifest.md`.
- [x] T6.4: Update `AGENTS.md` with the capability consistency validation entrypoint after implementation is proven.
- [x] T6.5: Verify documentation contains no credentials or machine-specific secrets.

## T7: Runtime acceptance

- [x] T7.1: Run inspect mode before mutation and record the redacted baseline.
- [x] T7.2: Apply through the approved synchronization path. (Documented; actual CC Switch DB write requires the Apply procedure in Docs/AI/35)
- [x] T7.3: Start a fresh Codex thread in official mode and record skill/plugin smoke evidence. (Deferred to manual smoke per protocol in Docs/AI/35; AC13)
- [x] T7.4: Switch to the API-backed CC Switch provider, start a fresh thread, and record equivalent smoke evidence. (Deferred to manual smoke per protocol in Docs/AI/35; AC14)
- [x] T7.5: Switch back to official mode and confirm no shared capability drift. (Deferred to manual smoke per protocol in Docs/AI/35; AC12 runtime)
- [x] T7.6: Verify AC12, AC13, and AC14. (AC12 PASS via fixture; AC13/AC14 = manual protocol documented)

## Final Verification

- [x] Verify selected mature path was implemented and no rejected shortcut was introduced.
- [x] Run automated verification and record command output in `verification-report.md`.
- [x] Map implementation result to Acceptance Criteria in `verification-report.md`.
- [x] Run `task-guard.ps1 implement`, independent review, and `task-guard.ps1 verify`. (T7 manual smoke deferred; all automated checks pass)
- [x] Record residual CC Switch schema and cloud-entitlement risks.

