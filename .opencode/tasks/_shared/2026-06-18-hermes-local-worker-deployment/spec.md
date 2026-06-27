# Spec: Hermes Local Worker Deployment

## GIVEN

- The workspace root is `E:\UEGameDevelopment`.
- Third-party tools belong under `.tools/` and transient downloads under `.tmp/`.
- The repository uses a Lead/Worker/Reviewer task-packet workflow.
- Hermes Agent is not currently an authoritative workflow component.
- The user approved a native Windows deployment under `.tools\hermes-worker`.

## WHEN

- A worker executes `work-packages/WP01-deploy-hermes-local-worker.md` after the Plan and Can-Edit gates pass.
- The worker installs Hermes using the official installer with explicit `HermesHome` and `InstallDir`.
- The worker adds and tests the task-packet adapter.

## THEN

### Installation

- Hermes runtime and state are contained under `E:\UEGameDevelopment\.tools\hermes-worker`.
- Downloads are staged under `E:\UEGameDevelopment\.tmp\hermes-install`.
- Existing Hermes data outside this location is detected and preserved.

### Configuration

- Hermes starts with `E:\UEGameDevelopment` as its working directory.
- Manual approval and secret redaction remain enabled.
- Delegation is flat and limited; Hermes cannot become a nested orchestrator.
- Gateway, cron, and autonomous publication remain disabled.

### Workflow integration

- Hermes receives one task-local work package at a time.
- The adapter checks Plan and Can-Edit before launching a mutating worker session.
- The worker creates one claim and one evidence report.
- Architecture decisions, task transitions, Review, and Verify remain with the lead model.

### Verification

- Adapter behavior has automated tests independent of external model credentials.
- Installation health is checked through version and doctor commands.
- Final acceptance maps evidence back to AC01–AC08.

### Failure behavior

- A failed mechanical gate stops execution without launching Hermes.
- A missing or ambiguous work package stops execution.
- Missing model credentials do not invalidate installation verification; they are reported as a residual limitation.
- Pre-existing external Hermes data is never deleted automatically.

## Acceptance Criteria

| AC# | Description | Verification Command | Expected Output |
|-----|-------------|---------------------|-----------------|
| AC01 | Workspace-local installation | `Test-Path "E:\UEGameDevelopment\.tools\hermes-worker\hermes-agent"` | `True` |
| AC02 | Healthy CLI runtime | `hermes --version; hermes doctor` using the managed executable | Both commands exit zero without blocking errors |
| AC03 | Safe worker configuration | inspect `.tools/hermes-worker/config.yaml` | cwd, approvals, security, and delegation match the approved design |
| AC04 | Mechanical gates enforced | run adapter tests | failed gates prevent launch |
| AC05 | One-package scope enforced | run adapter tests | missing or ambiguous WP is rejected |
| AC06 | Automated regression coverage | `test-invoke-hermes-worker.ps1` | all tests pass |
| AC07 | Worker evidence returned | inspect `reports/hermes-WP01-result.md` | complete report with no extra scope |
| AC08 | Independent final verification | run Verify gate | passes only with lead-owned evidence |

## Progress Summary

| Phase | Status | Key Decision |
|-------|--------|-------------|
| Plan | Ready for mechanical gate | Native Windows, workspace-local home, Worker-only role |
| Implement | Pending | Execute WP01 only after phase transition |
| Review | Pending | Lead checks scope, adapter behavior, and installation evidence |
| Verify | Pending | Lead maps AC01–AC08 and runs Verify gate |

## Non-Goals

- Replacing Codex, Trae, OpenCode, or the shared Router.
- Enabling Telegram, Discord, Slack, WhatsApp, or other messaging gateways.
- Creating unattended cron jobs.
- Installing or tuning a local LLM.
- Giving Hermes repository-wide autonomous write permission.
- Migrating `Docs/Memory` into Hermes memory.
- Modifying UE5 or web project code.
