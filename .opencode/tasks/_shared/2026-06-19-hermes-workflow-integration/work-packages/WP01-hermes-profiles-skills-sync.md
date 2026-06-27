# WP01: Hermes Profiles, Shared Skills, and Synchronization

Owner model: unclaimed  
Difficulty: hard  
Status: unclaimed

## Task Packet

- Root: `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/`
- Parent task: `2026-06-19-hermes-workflow-integration`

## Allowed Paths

- `skills/hermes-project-router/**`
- `skills/hermes-jinli-planner/**`
- `skills/hermes-jinli-implementer/**`
- `skills/hermes-jinli-verifier/**`
- `.trae/hermes/profiles/**`
- `.trae/hermes/policies/roles.yaml`
- `.trae/scripts/sync-hermes-workflow.ps1`
- `.trae/scripts/test-hermes-skill-compatibility.ps1`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/claims/hermes-profile-WP01.md`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/reports/hermes-profile-WP01-result.md`

## Forbidden Paths

- `Project/**`
- `.tools/hermes-worker/hermes-agent/**`
- `.tools/hermes-worker/**` during WP execution; runtime synchronization is lead-owned after WP01-WP03 integration
- `.trae/hermes/mcp/**`
- `.trae/hermes/plugins/**`
- `.trae/hermes/tests/**`
- `.trae/scripts/task-state.ps1`
- `.trae/scripts/task-guard.ps1`
- `.trae/scripts/doc-guard.ps1`
- `.trae/scripts/invoke-hermes-agent.ps1`
- `.trae/scripts/test-hermes-workflow-integration.ps1`
- `skills/**` except the four exact adapter directories under Allowed Paths
- `Docs/**`
- other task packets
- Git metadata, branches, commits, remotes, pushes, resets, rebases, and credential stores

## Read First

- `AGENTS.md`
- `Docs/AI/27-AI-Workflow-Refactor-Manifest.md`
- `Docs/AI/29-Mature-Solution-First-Workflow.md`
- `Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md`
- `Docs/superpowers/specs/2026-06-19-hermes-workflow-integration-design.md`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/routing.md`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/analysis.md`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/spec.md`
- `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/tasks.md`
- `skills/金璃小天才/SKILL.md`
- `skills/金璃好帮手/SKILL.md`
- `.tools/hermes-worker/hermes-agent/website/docs/user-guide/profiles.md`
- `.tools/hermes-worker/hermes-agent/website/docs/user-guide/features/skills.md`

## Goal

- Define reproducible Planner and Implementer profile sources, four thin Hermes adapter Skills, role-specific Skill Bundles, a role policy manifest, and an idempotent synchronization/check script without duplicating canonical domain knowledge or exposing credentials.

## Steps

- [ ] Run the Plan gate and Can-Edit check before editing.
- [ ] Create `claims/hermes-profile-WP01.md`.
- [ ] Write `test-hermes-skill-compatibility.ps1` first and run it to observe expected failures for missing integration files.
- [ ] Create the four adapter Skill directories with valid Agent Skills frontmatter.
- [ ] Each adapter must reference canonical project rules and its matching shared role; do not copy UE/Web domain sections.
- [ ] Create profile source directories for `jinli-planner` and `jinli-implementer`.
- [ ] Add Chinese `SOUL.md`, secret-free config overlays, role-specific `mcp.json`, and Skill Bundles.
- [ ] Configure `skills.external_dirs` to `E:/UEGameDevelopment/skills`.
- [ ] Add `.trae/hermes/policies/roles.yaml` with explicit role, tool, and path rules.
- [ ] Implement `sync-hermes-workflow.ps1` with `-Check`, `-Apply`, and `-Profile` modes.
- [ ] Preserve `.env`, memories, sessions, logs, state databases, and other user-owned runtime files.
- [ ] Detect profile-local Skill shadowing and inline credential fields without printing secret values.
- [ ] Ensure a second Check/Apply cycle is idempotent.
- [ ] Run compatibility tests and record exact output.
- [ ] Write `reports/hermes-profile-WP01-result.md` and stop.

## Done Definition

- Four adapter Skills exist and remain thin role/tool translations.
- Both profile source trees contain persona, config overlay, MCP allowlist, and bundles.
- Role policy is concrete and contains no unresolved values.
- Compatibility tests verify canonical Skill resolution, bundle resolution, shadow detection, and no inline credentials.
- Synchronization supports check/apply, preserves user state, and is idempotent by design and test.
- The report maps evidence to AC01, AC02, AC03, AC04, AC08, and AC10.

## Required Verification

- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-hermes-skill-compatibility.ps1`
- Expected: all profile, adapter Skill, bundle, shadowing, and credential checks pass.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\sync-hermes-workflow.ps1 -Check`
- Expected: repository-owned profile sources are internally valid; if runtime has not yet been synchronized, drift is reported clearly without changing files.

## Return Report

- Path: `reports/hermes-profile-WP01-result.md`
- Required status for merge: `done`
- Must include changed files, commands run, results, acceptance criteria touched, scope control, and unresolved risks.
- Must declare `Extra scope taken: no`.
- Must not contain any credential value.

## Failure Reporting

- If blocked, write the same report path with `Status: blocked`.
- Include the blocker, commands already run, and the smallest question needed from the lead.
- Do not modify runtime state or any path outside Allowed Paths while blocked.

## Publisher Checklist

- [x] No template placeholder text remains.
- [x] Allowed and Forbidden Paths are concrete.
- [x] Verification commands and expected outcomes are concrete.
- [x] Return report path is concrete.

