# Hermes Local Worker Deployment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deploy NousResearch Hermes Agent as a workspace-local, bounded Worker and integrate it with the existing task-packet workflow without creating a competing orchestrator.

**Architecture:** Install the official native Windows runtime under `E:\UEGameDevelopment\.tools\hermes-worker`, keep all Hermes-owned state isolated there, and launch it only through a tested PowerShell adapter. The adapter resolves one work package, checks Plan and Can-Edit gates, and leaves Review and Verify with the lead model.

**Tech Stack:** Windows PowerShell, official Hermes Agent installer, Python 3.11 managed by Hermes/uv, Markdown task packets, Pester-free PowerShell regression script.

---

## Authoritative task packet

All implementation details, acceptance criteria, scope boundaries, and reporting requirements are maintained at:

```text
.trae/tasks/_shared/2026-06-18-hermes-local-worker-deployment/
```

The implementing model must execute only:

```text
work-packages/WP01-deploy-hermes-local-worker.md
```

## Planned file structure

```text
.tools/hermes-worker/                         Hermes-owned runtime and state
.tmp/hermes-install/install.ps1               Verified transient installer
.trae/scripts/invoke-hermes-worker.ps1        Task-packet launch adapter
.trae/scripts/test-invoke-hermes-worker.ps1   Adapter regression tests
.trae/tasks/_shared/2026-06-18-hermes-local-worker-deployment/
  claims/hermes-WP01.md                       Worker claim
  reports/hermes-WP01-result.md               Worker evidence
```

## Task 1: Authorize implementation

- [ ] Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\task-guard.ps1 _shared/2026-06-18-hermes-local-worker-deployment plan
```

Expected: Plan gate passes.

- [ ] Have the lead transition the task into Implement.

- [ ] Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\task-state.ps1 can-edit _shared/2026-06-18-hermes-local-worker-deployment
```

Expected: editing is allowed.

## Task 2: Claim scope and preserve existing state

- [ ] Create the exact claim required by the work package:

```text
.trae/tasks/_shared/2026-06-18-hermes-local-worker-deployment/claims/hermes-WP01.md
```

- [ ] Record, but do not modify, pre-existing default Hermes state:

```powershell
Test-Path "$env:LOCALAPPDATA\hermes"
```

- [ ] Resolve the latest official non-prerelease GitHub release tag and record it in the result report:

```powershell
$release = Invoke-RestMethod `
  -Uri "https://api.github.com/repos/NousResearch/hermes-agent/releases/latest" `
  -Headers @{ "User-Agent" = "UEGameDevelopment-Hermes-Installer" }
$releaseTag = $release.tag_name
if ([string]::IsNullOrWhiteSpace($releaseTag)) {
    throw "Unable to resolve an official Hermes release tag."
}
$releaseTag
```

Expected: one immutable official release tag such as `v2026.5.29.2`.

## Task 3: Install Hermes into the workspace-local tool home

- [ ] Create the transient installer directory:

```powershell
New-Item -ItemType Directory -Force "E:\UEGameDevelopment\.tmp\hermes-install"
```

- [ ] Download the official installer:

```powershell
Invoke-WebRequest `
  -Uri "https://hermes-agent.nousresearch.com/install.ps1" `
  -OutFile "E:\UEGameDevelopment\.tmp\hermes-install\install.ps1"
```

- [ ] Record its SHA256:

```powershell
Get-FileHash "E:\UEGameDevelopment\.tmp\hermes-install\install.ps1" -Algorithm SHA256
```

- [ ] Run the installer with explicit paths and the selected stable tag:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File "E:\UEGameDevelopment\.tmp\hermes-install\install.ps1" `
  -HermesHome "E:\UEGameDevelopment\.tools\hermes-worker" `
  -InstallDir "E:\UEGameDevelopment\.tools\hermes-worker\hermes-agent" `
  -Tag $releaseTag `
  -SkipSetup
```

Do not use an unrecorded moving branch. Preserve `$releaseTag` and include it in the worker report.

## Task 4: Configure the bounded Worker profile

- [ ] Configure `E:\UEGameDevelopment\.tools\hermes-worker\config.yaml` so it contains the following effective policy:

```yaml
terminal:
  backend: local
  cwd: "E:/UEGameDevelopment"
  timeout: 300
  home_mode: profile

approvals:
  mode: manual

security:
  redact_secrets: true

delegation:
  max_concurrent_children: 2
  max_spawn_depth: 1
  orchestrator_enabled: false
```

- [ ] Confirm no gateway or cron job is configured or started.

## Task 5: Write adapter regression tests

- [ ] Create `.trae/scripts/test-invoke-hermes-worker.ps1`.

- [ ] Cover these deterministic cases without a live model call:

```text
failed Plan gate -> adapter refuses launch
failed Can-Edit -> adapter refuses launch
missing work package -> adapter refuses launch
ambiguous work package -> adapter refuses launch
valid dry-run -> prints one resolved package, claim path, report path, and Hermes executable
```

- [ ] Run the tests before adapter implementation.

Expected: tests fail because the adapter does not exist.

## Task 6: Implement the launch adapter

- [ ] Create `.trae/scripts/invoke-hermes-worker.ps1` with parameters for task name, WP ID, and dry-run.

- [ ] Require:

```text
one existing task packet
one matching work package
successful Plan gate
successful Can-Edit check
concrete claim path
concrete report path
managed Hermes executable under .tools/hermes-worker
```

- [ ] Ensure dry-run performs all resolution and gate checks but does not start Hermes.

- [ ] Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-invoke-hermes-worker.ps1
```

Expected: all test cases pass.

## Task 7: Verify the installed runtime

- [ ] Run:

```powershell
& "E:\UEGameDevelopment\.tools\hermes-worker\hermes-agent\venv\Scripts\hermes.exe" --version
```

Expected: a Hermes Agent version string and exit code 0.

- [ ] Run:

```powershell
& "E:\UEGameDevelopment\.tools\hermes-worker\hermes-agent\venv\Scripts\hermes.exe" doctor
```

Expected: no blocking installation error.

- [ ] If model credentials are available, launch Hermes from `E:\UEGameDevelopment` and request a read-only summary of the Implement gates.

Expected: Hermes identifies `task-guard.ps1 plan` and `task-state.ps1 can-edit` without modifying files.

## Task 8: Return evidence

- [ ] Write:

```text
.trae/tasks/_shared/2026-06-18-hermes-local-worker-deployment/reports/hermes-WP01-result.md
```

- [ ] Include installed tag or commit, installer SHA256, changed files, every command and result, AC01–AC08 status, scope control, and unresolved risks.

- [ ] Stop after the report. The lead model owns Review, Verify, and archival.
