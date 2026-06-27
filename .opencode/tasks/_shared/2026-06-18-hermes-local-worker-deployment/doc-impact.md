# Documentation Impact: Hermes Local Worker Deployment

## Project Document Scope

- Project: _shared
- System: AI Workflow / Hermes Worker Runtime
- Owner: lead-model planning and verification

## Code Changes

- Planned: `.trae/scripts/invoke-hermes-worker.ps1`
- Planned: `.trae/scripts/test-invoke-hermes-worker.ps1`
- Planned runtime installation: `.tools/hermes-worker/**`

## No Code Changes

Reason: No `Project/` application or game code changes are planned. The only planned scripts are global workflow adapters under `.trae/scripts/`.

## Documentation Updates

- `.trae/tasks/_shared/2026-06-18-hermes-local-worker-deployment/routing.md`
- `.trae/tasks/_shared/2026-06-18-hermes-local-worker-deployment/analysis.md`
- `.trae/tasks/_shared/2026-06-18-hermes-local-worker-deployment/spec.md`
- `.trae/tasks/_shared/2026-06-18-hermes-local-worker-deployment/tasks.md`
- `.trae/tasks/_shared/2026-06-18-hermes-local-worker-deployment/work-packages/WP01-deploy-hermes-local-worker.md`
- `.trae/tasks/_shared/2026-06-18-hermes-local-worker-deployment/DISPATCH.md`
- `Docs/superpowers/plans/2026-06-18-hermes-local-worker-deployment-plan.md`

## Docs Tree Updates

- Not applicable: this is a global AI workflow task and does not change a project-specific documentation tree.

## Documentation Governance Decision

- Runtime truth lives in this task packet.
- The durable execution plan lives under `Docs/superpowers/plans/`.
- No new global policy document is required until the integration is verified and promoted from optional Worker runtime to an active workflow component.
