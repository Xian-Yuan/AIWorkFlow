---
domain: ai
domain_path: ai/workflow
kg_node_id: node.doc-ai-ai-39-root-git-workspace-boundary-dcb2
t13_retro_classified_at: "2026-06-24T04:47:04Z"
kg_id: doc.ai.ai.39-root-git-workspace-boundary.dcb2

---

# Root Git Workspace Boundary

Date: 2026-06-19  
Status: Active  
Scope: Codex, OpenCode, Trae, VS Code, and other IDEs using the root repository

## Purpose

The root repository manages shared AI workflow sources, documentation, and
cross-IDE configuration. Projects under `Project/` use independent
repositories.

The root repository uses a default-deny boundary: new root directories are
ignored unless explicitly approved in `.gitignore`. This prevents IDEs from
recursively scanning model caches, build outputs, package caches, and
independent project repositories.

## Managed Paths

- `Docs/`
- `skills/`
- `.trae/` workflow directories
- `.opencode/` adapters and task mirrors
- `.github/`
- `.vscode/`
- explicitly listed root policy and package files

All other root directories are local by default.

## Line Ending Policy

`.gitattributes` is authoritative:

- text files use LF;
- Windows `.bat` and `.cmd` launchers use CRLF;
- binary formats are never normalized.

The local repository sets `core.autocrlf=false`, preventing machine-level Git
settings from generating a warning for every workflow file.

## Push Safety

The guard disables each remote push URL locally by replacing it with:

```text
DISABLED_BY_WORKSPACE_POLICY
```

Fetch URLs remain unchanged. Restore push only for an intentional, approved
operation:

```powershell
& .\.trae\scripts\workspace-git-guard.ps1 -Mode EnablePush -ConfirmEnablePush
```

Disable it again afterward:

```powershell
& .\.trae\scripts\workspace-git-guard.ps1 -Mode DisablePush
```

## Commands

Apply local protection:

```powershell
& .\.trae\scripts\workspace-git-guard.ps1 -Mode Apply
```

Inspect repository health:

```powershell
& .\.trae\scripts\workspace-git-guard.ps1 -Mode Inspect
```

Stop currently running IDE Git scans:

```powershell
& .\.trae\scripts\workspace-git-guard.ps1 -Mode StopScans
```

Temporarily monitor and stop recurring scans:

```powershell
& .\.trae\scripts\workspace-git-guard.ps1 -Mode Watch -WatchSeconds 900
```

Verify the complete policy:

```powershell
& .\.trae\scripts\test-root-git-boundary.ps1
```

## IDE Rules

1. Open a concrete project repository when editing game or web project files.
2. Open the root repository only for shared workflow and documentation work.
3. Do not add local tools, caches, models, or generated directories to the
   root allowlist.
4. Do not restore root push access unless an intentional push was approved.
5. Run the boundary test after changing `.gitignore`, `.gitattributes`, or Git
   policy scripts.

## Incident Basis

On 2026-06-19, IDE diff generation repeatedly executed `git add -A` against:

- more than 90,000 local ComfyUI files;
- more than 50,000 Rust temporary files;
- a stale Codex profile Junction pointing at a removed Windows user;
- workflow files affected by machine-level `core.autocrlf=true`.

The resulting Git errors filled more than 1 GB of Codex logs and caused the
desktop renderer to restart. The default-deny boundary prevents recurrence
without deleting user files or discarding tracked changes.
