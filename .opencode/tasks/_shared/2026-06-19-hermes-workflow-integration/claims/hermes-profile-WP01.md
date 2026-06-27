# WP01 Claim: Hermes Profiles, Shared Skills, and Synchronization

- **Claim ID**: hermes-profile-WP01
- **Task**: _shared/2026-06-19-hermes-workflow-integration
- **Claimed by**: 金璃好帮手 (lead model)
- **Claimed at**: 2026-06-19
- **Status**: active

## Claim Scope

This claim covers the creation of:
1. Four thin Hermes adapter Skills (hermes-project-router, hermes-jinli-planner, hermes-jinli-implementer, hermes-jinli-verifier)
2. Two repository-owned Profile sources (jinli-planner, jinli-implementer)
3. Role-specific Skill Bundles
4. Role policy manifest (roles.yaml)
5. Synchronization script (sync-hermes-workflow.ps1)
6. Compatibility test script (test-hermes-skill-compatibility.ps1)

## Allowed Paths

- `skills/hermes-project-router/**`
- `skills/hermes-jinli-planner/**`
- `skills/hermes-jinli-implementer/**`
- `skills/hermes-jinli-verifier/**`
- `.trae/hermes/profiles/**`
- `.trae/hermes/policies/roles.yaml`
- `.trae/scripts/sync-hermes-workflow.ps1`
- `.trae/scripts/test-hermes-skill-compatibility.ps1`

## Gates

- [x] Plan gate: PASS
- [x] Can-Edit: PASS
- [x] No Forbidden Path modification
