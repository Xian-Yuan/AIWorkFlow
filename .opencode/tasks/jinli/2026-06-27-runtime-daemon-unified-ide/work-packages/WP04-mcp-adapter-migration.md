# WP04 MCP Adapter Migration

Status: unclaimed

## Task Packet

- Task: jinli/2026-06-27-runtime-daemon-unified-ide
- Package: WP04-mcp-adapter-migration
- Owner: unassigned worker
- Phase: implement after WP03 runtime API contract is stable
- Claim file: `claims/WP04-mcp-adapter-migration.claim.json`

## Allowed Paths

- `C:/Users/87372/plugins/jinli-soul-core/mcp/**`
- `C:/Users/87372/plugins/jinli-soul-core/src/**`
- `C:/Users/87372/plugins/jinli-soul-core/package.json`
- `C:/Users/87372/plugins/jinli-soul-core/package-lock.json`
- `.trae/scripts/jinli-mcp-smoke.ps1`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/claims/WP04-mcp-adapter-migration.claim.json`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/reports/WP04-mcp-adapter-migration.md`

## Forbidden Paths

- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/.task.yaml`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/routing.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/analysis.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/spec.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/tasks.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/requirements.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/execution-prompt.md`
- `C:/Users/87372/.codex/**`
- `.opencode/**`
- `Project/Jinli/services/**`
- `Project/RTS/**`
- `Project/CharacterDesignTool/**`

## Read First

- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/spec.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/analysis.md`
- `Project/Jinli/docs/04-Implementation/runtime-protocol.md`
- `C:/Users/87372/plugins/jinli-soul-core/mcp/server.mjs`
- Existing MCP handler files under `C:/Users/87372/plugins/jinli-soul-core/mcp/**`

## Goal

Migrate Jinli MCP tools so their stable public tool names call the Python runtime daemon through a client adapter, while preserving emergency compatibility with the existing PowerShell path.

## Steps

1. Inspect the MCP server and current tool schemas before editing.
2. Add a daemon client module for Node MCP code.
3. Route representative tools through the daemon API: `soul_init`, `soul_auto`, `soul_status`, `soul_memory`, and `response_plan`.
4. Preserve existing tool names, argument schemas, and response compatibility where clients rely on them.
5. Keep PowerShell fallback available only as an explicit degraded fallback path and include fallback evidence in responses.
6. Add a local smoke script that can list MCP tools and call representative daemon-backed tools.

## Done Definition

- MCP remains schema-compatible for existing IDE clients.
- MCP status reveals daemon authority, daemon health, and fallback state.
- MCP no longer silently bypasses the Python runtime for standard status, memory, or response planning.
- Emergency fallback is visible and testable.

## Required Verification

- `node C:/Users/87372/plugins/jinli-soul-core/mcp/server.mjs --help`
- `powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/jinli-mcp-smoke.ps1`
- `powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/jinli-system.ps1 doctor`

## Return Report

- Path: `reports/WP04-mcp-adapter-migration.md`
- Include changed files, preserved tool schemas, smoke output, fallback behavior, and any IDE restart requirement.
