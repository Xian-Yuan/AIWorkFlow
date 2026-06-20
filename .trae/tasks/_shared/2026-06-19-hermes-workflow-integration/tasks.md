# Tasks: Hermes Workflow Integration

## Dependency Graph

```text
T1 Plan authorization
  -> T2 WP01 Profiles/Skills/Sync
  -> T3 WP02 Workflow MCP       } T2-T4 may execute in parallel
  -> T4 WP03 Guard Plugin       }
       -> T5 WP04 Launcher/E2E/Docs
          -> T6 Runtime verification
             -> T7 Lead Review and Verify
```

## Plan Authorization

- [x] T1.1: Run `task-guard.ps1 _shared/2026-06-19-hermes-workflow-integration plan`.
- [x] T1.2: Transition the task to Implement with the authoritative task-state script.
- [x] T1.3: Run `task-state.ps1 can-edit _shared/2026-06-19-hermes-workflow-integration`.

## WP01 — Profiles, Skills, Policy, and Sync

- [x] T2.1: Create the WP01 claim before edits.
- [x] T2.2: Write failing shared-Skill/profile compatibility tests.
- [x] T2.3: Create four thin Hermes adapter Skills.
- [x] T2.4: Create Planner and Implementer repository-owned profile sources.
- [x] T2.5: Create Plan, Implement, and Verify Skill Bundles.
- [x] T2.6: Create the role policy manifest.
- [x] T2.7: Implement idempotent profile/plugin synchronization with `-Check` and `-Apply`.
- [x] T2.8: Migrate generated runtime config away from inline credentials without printing secret values.
- [x] T2.9: Pass compatibility tests and submit `reports/hermes-profile-WP01-result.md`.
- [x] T2.10: Verify AC01, AC02, AC03, AC04, AC08, and AC10 evidence.

## WP02 — Workflow MCP Server

- [x] T3.1: Create the WP02 claim before edits.
- [x] T3.2: Write failing MCP unit tests.
- [x] T3.3: Implement task/path resolution and traversal rejection.
- [x] T3.4: Implement role-specific workflow tool authorization.
- [x] T3.5: Wrap Plan and Can-Edit gates with structured evidence.
- [x] T3.6: Implement collision-safe claims and schema-validated reports.
- [x] T3.7: Prevent Worker architecture and Verify ownership.
- [x] T3.8: Pass MCP tests and submit `reports/hermes-mcp-WP02-result.md`.
- [x] T3.9: Verify AC05 and AC06 evidence.

## WP03 — Workflow Guard Plugin

- [x] T4.1: Create the WP03 claim before edits.
- [x] T4.2: Write failing guard plugin unit tests.
- [x] T4.3: Implement session role/workspace validation.
- [x] T4.4: Implement task context injection.
- [x] T4.5: Implement fail-closed mutation authorization.
- [x] T4.6: Enforce work-package Allowed/Forbidden Paths.
- [x] T4.7: Add secret-safe audit records and subagent result validation.
- [x] T4.8: Pass guard tests and submit `reports/hermes-guard-WP03-result.md`.
- [x] T4.9: Verify AC07 evidence.

## WP04 — Launcher, End-to-End Regression, and Documentation

- [x] T5.1: Confirm WP01-WP03 reports are complete before claiming WP04.
- [x] T5.2: Create the WP04 claim.
- [x] T5.3: Write failing launcher/integration tests.
- [x] T5.4: Implement role/task/WP-aware Hermes launcher with dry-run.
- [x] T5.5: Integrate sync, profile, MCP, plugin, claim, and report resolution.
- [x] T5.6: Document architecture, operations, security, and troubleshooting.
- [x] T5.7: Pass deterministic integration regression.
- [x] T5.8: Submit `reports/hermes-launcher-WP04-result.md`.
- [x] T5.9: Verify AC08, AC09, AC10, AC11, and AC13 evidence.

## Runtime Verification

- [x] T6.1: Run profile synchronization in Apply mode.
- [x] T6.2: Run synchronization in Check mode and confirm no drift.
- [x] T6.3: Run Hermes doctor for `jinli-planner`.
- [x] T6.4: Run Hermes doctor for `jinli-implementer`.
- [x] T6.5: Run Planner and Implementer dry-run launch checks.
- [x] T6.6: Run Chinese read-only smoke tests if valid credentials are available; otherwise record not-run.
- [x] T6.7: Verify AC12 evidence.

## Final Verification

- [x] T7.1: Review all changed paths against every work package's Allowed and Forbidden Paths.
- [x] T7.2: Review all worker reports; do not accept worker success claims without rerunning checks.
- [x] T7.3: Verify selected mature path was implemented and no rejected shortcut was introduced.
- [x] T7.4: Run automated verification and record command output in `verification-report.md`.
- [x] T7.5: Map implementation result to Acceptance Criteria in `verification-report.md`.
- [x] T7.6: Run documentation governance at Implement stage.
- [x] T7.7: Set verification state only from independent evidence.
- [x] T7.8: Run `task-guard.ps1 _shared/2026-06-19-hermes-workflow-integration verify`.

