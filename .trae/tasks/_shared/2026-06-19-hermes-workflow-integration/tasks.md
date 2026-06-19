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

- [ ] T1.1: Run `task-guard.ps1 _shared/2026-06-19-hermes-workflow-integration plan`.
- [ ] T1.2: Transition the task to Implement with the authoritative task-state script.
- [ ] T1.3: Run `task-state.ps1 can-edit _shared/2026-06-19-hermes-workflow-integration`.

## WP01 — Profiles, Skills, Policy, and Sync

- [ ] T2.1: Create the WP01 claim before edits.
- [ ] T2.2: Write failing shared-Skill/profile compatibility tests.
- [ ] T2.3: Create four thin Hermes adapter Skills.
- [ ] T2.4: Create Planner and Implementer repository-owned profile sources.
- [ ] T2.5: Create Plan, Implement, and Verify Skill Bundles.
- [ ] T2.6: Create the role policy manifest.
- [ ] T2.7: Implement idempotent profile/plugin synchronization with `-Check` and `-Apply`.
- [ ] T2.8: Migrate generated runtime config away from inline credentials without printing secret values.
- [ ] T2.9: Pass compatibility tests and submit `reports/hermes-profile-WP01-result.md`.
- [ ] T2.10: Verify AC01, AC02, AC03, AC04, AC08, and AC10 evidence.

## WP02 — Workflow MCP Server

- [ ] T3.1: Create the WP02 claim before edits.
- [ ] T3.2: Write failing MCP unit tests.
- [ ] T3.3: Implement task/path resolution and traversal rejection.
- [ ] T3.4: Implement role-specific workflow tool authorization.
- [ ] T3.5: Wrap Plan and Can-Edit gates with structured evidence.
- [ ] T3.6: Implement collision-safe claims and schema-validated reports.
- [ ] T3.7: Prevent Worker architecture and Verify ownership.
- [ ] T3.8: Pass MCP tests and submit `reports/hermes-mcp-WP02-result.md`.
- [ ] T3.9: Verify AC05 and AC06 evidence.

## WP03 — Workflow Guard Plugin

- [ ] T4.1: Create the WP03 claim before edits.
- [ ] T4.2: Write failing guard plugin unit tests.
- [ ] T4.3: Implement session role/workspace validation.
- [ ] T4.4: Implement task context injection.
- [ ] T4.5: Implement fail-closed mutation authorization.
- [ ] T4.6: Enforce work-package Allowed/Forbidden Paths.
- [ ] T4.7: Add secret-safe audit records and subagent result validation.
- [ ] T4.8: Pass guard tests and submit `reports/hermes-guard-WP03-result.md`.
- [ ] T4.9: Verify AC07 evidence.

## WP04 — Launcher, End-to-End Regression, and Documentation

- [ ] T5.1: Confirm WP01-WP03 reports are complete before claiming WP04.
- [ ] T5.2: Create the WP04 claim.
- [ ] T5.3: Write failing launcher/integration tests.
- [ ] T5.4: Implement role/task/WP-aware Hermes launcher with dry-run.
- [ ] T5.5: Integrate sync, profile, MCP, plugin, claim, and report resolution.
- [ ] T5.6: Document architecture, operations, security, and troubleshooting.
- [ ] T5.7: Pass deterministic integration regression.
- [ ] T5.8: Submit `reports/hermes-launcher-WP04-result.md`.
- [ ] T5.9: Verify AC08, AC09, AC10, AC11, and AC13 evidence.

## Runtime Verification

- [ ] T6.1: Run profile synchronization in Apply mode.
- [ ] T6.2: Run synchronization in Check mode and confirm no drift.
- [ ] T6.3: Run Hermes doctor for `jinli-planner`.
- [ ] T6.4: Run Hermes doctor for `jinli-implementer`.
- [ ] T6.5: Run Planner and Implementer dry-run launch checks.
- [ ] T6.6: Run Chinese read-only smoke tests if valid credentials are available; otherwise record not-run.
- [ ] T6.7: Verify AC12 evidence.

## Final Verification

- [ ] T7.1: Review all changed paths against every work package's Allowed and Forbidden Paths.
- [ ] T7.2: Review all worker reports; do not accept worker success claims without rerunning checks.
- [ ] T7.3: Verify selected mature path was implemented and no rejected shortcut was introduced.
- [ ] T7.4: Run automated verification and record command output in `verification-report.md`.
- [ ] T7.5: Map implementation result to Acceptance Criteria in `verification-report.md`.
- [ ] T7.6: Run documentation governance at Implement stage.
- [ ] T7.7: Set verification state only from independent evidence.
- [ ] T7.8: Run `task-guard.ps1 _shared/2026-06-19-hermes-workflow-integration verify`.

