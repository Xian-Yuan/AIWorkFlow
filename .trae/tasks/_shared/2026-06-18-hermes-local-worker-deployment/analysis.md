# Analysis: Hermes Local Worker Deployment

## Architecture Context

### System boundaries

- The affected system is the global AI workflow under `E:\UEGameDevelopment`.
- Hermes Agent is an external runtime tool, not a project feature and not a replacement workflow authority.
- The authoritative workflow remains `.trae/scripts`, `.trae/tasks`, `Docs/AI`, and the lead-model verification process.
- No files under `Project/RTS`, `Project/CharacterDesignTool`, or other project repositories are in scope.

### Dependency map

```text
Official Hermes installer
        |
        v
.tools/hermes-worker
        |
        +-- config / secrets / memories / skills / sessions / logs
        |
        v
.trae/scripts/invoke-hermes-worker.ps1
        |
        v
.trae/tasks/{scope}/{task}/work-packages/WPxx-*.md
        |
        +-- claims/{agent}-WPxx.md
        +-- reports/{agent}-WPxx-result.md
        |
        v
Lead model Review + Verify
```

### Data and state ownership

- Hermes runtime binaries and managed Python environment: `.tools/hermes-worker/hermes-agent/`.
- Hermes configuration and secrets: `.tools/hermes-worker/config.yaml` and `.tools/hermes-worker/.env`.
- Hermes private memory and generated skills: `.tools/hermes-worker/memories/` and `.tools/hermes-worker/skills/`.
- Shared project truth: `Docs/AI/`, `Docs/Memory/`, project documentation, and task packets.
- Task phase state: `.trae/tasks/.../.task.yaml`, owned by the lead workflow.
- Worker claims and evidence: task-local `claims/` and `reports/`.

### Integration points

- Official installer parameters: `-HermesHome` and `-InstallDir`.
- Project context discovery: root `AGENTS.md`.
- Mechanical authorization: `.trae/scripts/task-guard.ps1` and `.trae/scripts/task-state.ps1`.
- Worker contract: `.trae/scripts/work-package-template.md`, `agent-claim-template.md`, and `agent-result-template.md`.
- Launch adapter: `.trae/scripts/invoke-hermes-worker.ps1`.

### Allowed files

- `.tools/hermes-worker/**`
- `.tmp/hermes-install/**`
- `.trae/scripts/invoke-hermes-worker.ps1`
- `.trae/scripts/test-invoke-hermes-worker.ps1`
- `.trae/tasks/_shared/2026-06-18-hermes-local-worker-deployment/claims/**`
- `.trae/tasks/_shared/2026-06-18-hermes-local-worker-deployment/reports/**`
- Task-local progress and verification documents when updated by the lead model.

### Forbidden files

- `Project/**`
- `Docs/Memory/**`
- `skills/**`
- `.agents/**`
- `.trae/scripts/task-state.ps1`
- `.trae/scripts/task-guard.ps1`
- `.trae/scripts/doc-guard.ps1`
- Other task packets
- Git history, branches, remotes, or credentials

## Mature Solution Evidence

### Project-local evidence

- Repository rules place third-party tools under `.tools/` and transient downloads under `.tmp/`.
- `.gitignore` already excludes `.tools/` and `.tmp/`.
- `Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md` requires external workers to use bounded work packages, claims, reports, and independent verification.
- The current workflow mechanically guards Plan, Implement, and Verify through `.trae/scripts`.

### Official/framework evidence

- The official Windows installer accepts `-HermesHome` and `-InstallDir`, so installation does not need to use `%LOCALAPPDATA%\hermes`.
- Hermes supports native Windows, project context files including `AGENTS.md`, custom model providers, local models, and local terminal execution.
- Hermes configuration separates normal settings in `config.yaml` from secrets in `.env`.

Official references:

- `https://github.com/NousResearch/hermes-agent`
- `https://github.com/NousResearch/hermes-agent/blob/main/scripts/install.ps1`
- `https://hermes-agent.nousresearch.com/docs/getting-started/quickstart`
- `https://hermes-agent.nousresearch.com/docs/user-guide/configuration`

### External mature references

- Hermes implements a managed runtime, configuration home, approval controls, context-file discovery, and multiple terminal backends.
- The local deployment uses those official extension points instead of patching Hermes source code.

### Options compared

| Option | Pros | Cons | Decision |
|---|---|---|---|
| Native Windows under `.tools/hermes-worker` | Matches PowerShell and UE tooling; direct access to task packets; custom home supported | Local terminal backend has host-user access | Selected, with manual approvals and bounded adapter |
| WSL2 installation | Unix-like environment and good shell compatibility | Path translation and Windows UE build integration add friction | Rejected for initial deployment |
| Docker-only runtime | Stronger isolation | Windows path mounts, host PowerShell scripts, and UBT integration are more complex | Deferred as a later hardening option |
| Default `%LOCALAPPDATA%\hermes` | Fastest official default | Violates repository placement policy and splits runtime from workspace tooling | Rejected |

### Rejected shortcuts

- Do not run the one-line installer without explicit directory parameters.
- Do not grant Hermes unrestricted repository-wide editing.
- Do not let Hermes update `.task.yaml` or mark its own work verified.
- Do not enable gateway, cron, or autonomous publishing before the CLI Worker flow is validated.
- Do not copy project truth into Hermes memory as a second authoritative source.
- Do not modify Hermes source solely to integrate it with this repository.

### Selected mature path

Use the official native Windows installer with an explicit workspace-local Hermes home, add a repository-owned adapter with tests, enforce work-package boundaries, and retain independent lead-model verification. This provides reproducibility, discoverability, and rollback without introducing a competing orchestrator.

## Acceptance Criteria

- AC01: Hermes is installed under `E:\UEGameDevelopment\.tools\hermes-worker` and no task-created Hermes home exists under `%LOCALAPPDATA%\hermes`.
- AC02: `hermes --version`, `hermes doctor`, and a non-mutating repository-context smoke test complete successfully.
- AC03: Hermes configuration uses the repository root as the working directory, manual approvals, secret redaction, and a flat delegation boundary.
- AC04: `.trae/scripts/invoke-hermes-worker.ps1` refuses execution when Plan or Can-Edit gates fail.
- AC05: The adapter resolves exactly one work package, requires a claim path and report path, and does not permit architecture or verification ownership.
- AC06: Automated adapter tests pass without requiring a live model call.
- AC07: The worker report records every changed file, command result, acceptance criterion touched, scope control, and unresolved risk.
- AC08: Lead verification confirms no forbidden path was modified and no rejected shortcut was introduced.

## Automated Verification Plan

- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-invoke-hermes-worker.ps1`
- Expected: all adapter tests pass, including failed-gate, missing-package, ambiguous-package, and valid dry-run cases.
- Command: `& "E:\UEGameDevelopment\.tools\hermes-worker\hermes-agent\venv\Scripts\hermes.exe" --version`
- Expected: exits zero and prints the installed Hermes Agent version.
- Command: `& "E:\UEGameDevelopment\.tools\hermes-worker\hermes-agent\venv\Scripts\hermes.exe" doctor`
- Expected: no blocking installation or configuration errors.
- Command: `Test-Path "$env:LOCALAPPDATA\hermes"`
- Expected: `False`, unless the path existed before this task; pre-existing state must be documented rather than deleted.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\task-guard.ps1 _shared/2026-06-18-hermes-local-worker-deployment verify`
- Expected: passes only after the lead creates a complete `verification-report.md` and sets verification state to pass.

## Risks and mitigations

- Installer drift: record the installed tag or commit and installer SHA in the worker report.
- Host access: keep approvals manual and launch only through the adapter.
- Secret leakage: keep `.env` in the ignored Hermes home and retain secret redaction.
- Memory divergence: Hermes memory remains advisory and private; project truth stays in repository documents.
- Existing `%LOCALAPPDATA%\hermes`: detect and report it; do not delete or overwrite user data.
- Model availability: installation verification must not depend on a paid model call; chat smoke testing is separate and may be marked blocked if credentials are unavailable.
