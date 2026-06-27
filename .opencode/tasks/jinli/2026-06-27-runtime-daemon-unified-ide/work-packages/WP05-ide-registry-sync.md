# WP05 IDE Registry Sync

Status: unclaimed

## Task Packet

- Task: jinli/2026-06-27-runtime-daemon-unified-ide
- Package: WP05-ide-registry-sync
- Owner: unassigned worker
- Phase: implement after MCP adapter path is known
- Claim file: `claims/WP05-ide-registry-sync.claim.json`

## Allowed Paths

- `.trae/scripts/jinli-ide-sync.ps1`
- `.trae/scripts/validate-codex-capabilities.ps1`
- `.trae/scripts/test-codex-skill-discovery.ps1`
- `.trae/scripts/test-codex-capability-baseline.ps1`
- `.codex/capability-baseline.json`
- `.opencode/mcp.json`
- `opencode.json`
- `Project/Jinli/config/**`
- `Project/Jinli/docs/06-Operations/**`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/claims/WP05-ide-registry-sync.claim.json`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/reports/WP05-ide-registry-sync.md`

## Forbidden Paths

- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/.task.yaml`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/routing.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/analysis.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/spec.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/tasks.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/requirements.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/execution-prompt.md`
- `C:/Users/87372/.codex/config.toml`
- `C:/Users/87372/.codex/**`
- `C:/Users/87372/plugins/jinli-soul-core/**`
- `Project/Jinli/services/**`
- `Project/RTS/**`
- `Project/CharacterDesignTool/**`

## Read First

- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/spec.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/analysis.md`
- `Docs/AI/35-Codex-CCS-Capability-Consistency.md`
- `.codex/capability-baseline.json`
- `.opencode/mcp.json`
- `opencode.json`
- `.trae/scripts/validate-codex-capabilities.ps1`

## Goal

Define and implement a shared IDE registry and sync check so Codex, OpenCode, Trae, and future MCP clients can attach to the same Jinli MCP adapter without hand-maintained drift.

## Steps

1. Inspect current Codex capability validation and OpenCode MCP configuration without printing secrets.
2. Define a declarative registry shape for IDE name, MCP server id, command, args, environment policy, and installed state.
3. Implement `jinli-ide-sync.ps1 check|apply|doctor -Ide all`.
4. Ensure apply mode backs up generated config before changing it.
5. Update validation so it can report installed, enabled, and runtime callable for `jinli-soul-core@personal`.
6. Document any manual Codex restart or plugin installation step required by the host app.

## Done Definition

- A single registry can describe all supported IDE MCP entries.
- Check mode detects drift without editing files.
- Apply mode is backed up and reversible.
- Doctor mode explains why an IDE cannot call Jinli.
- Secrets are never printed into logs, reports, or task packet files.

## Required Verification

- `powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/jinli-ide-sync.ps1 check -Ide all`
- `powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/jinli-ide-sync.ps1 doctor -Ide all`
- `powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/validate-codex-capabilities.ps1 -Mode Inspect`

## Return Report

- Path: `reports/WP05-ide-registry-sync.md`
- Include registry file path, drift findings, backup behavior, validation output summary, and any host-app manual step.
