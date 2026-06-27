# WP06 Compatibility Docs Verification

Status: unclaimed

## Task Packet

- Task: jinli/2026-06-27-runtime-daemon-unified-ide
- Package: WP06-compat-docs-verification
- Owner: unassigned worker
- Phase: implement after runtime and MCP behavior are available
- Claim file: `claims/WP06-compat-docs-verification.claim.json`

## Allowed Paths

- `Project/Jinli/docs/03-Architecture/**`
- `Project/Jinli/docs/04-Implementation/**`
- `Project/Jinli/docs/06-Operations/**`
- `Project/Jinli/docs/DOCS_TREE.md`
- `Docs/AI/47-Jinli-Runtime-Enforcement-Layer.md`
- `AGENTS.md`
- `.trae/scripts/jinli-system.ps1`
- `.trae/scripts/jinli-mcp-smoke.ps1`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/verification-report.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/claims/WP06-compat-docs-verification.claim.json`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/reports/WP06-compat-docs-verification.md`

## Forbidden Paths

- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/.task.yaml`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/routing.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/analysis.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/spec.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/tasks.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/requirements.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/execution-prompt.md`
- `C:/Users/87372/.codex/**`
- `C:/Users/87372/plugins/jinli-soul-core/**`
- `.opencode/**`
- `Project/Jinli/services/**`
- `Project/RTS/**`
- `Project/CharacterDesignTool/**`

## Read First

- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/requirements.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/spec.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/tasks.md`
- `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/doc-impact.md`
- `Project/Jinli/docs/03-Architecture/runtime-enforcement-layer.md`
- `Project/Jinli/docs/04-Implementation/runtime-protocol.md`
- `Docs/AI/47-Jinli-Runtime-Enforcement-Layer.md`

## Goal

Keep legacy compatibility explicit, update the human-facing runtime contract, and collect final verification evidence without hiding any degraded or manual-only areas.

## Steps

1. Confirm which daemon, MCP, and IDE sync work packages have completed and read their reports.
2. Document source-of-truth policy for daemon state, SQLite memory, event logs, JSON compatibility files, and PowerShell CLI compatibility.
3. Update architecture, protocol, and operations docs so future systems can extend via service registry, runtime API, and adapter layers.
4. Preserve `soul-core.ps1 -Command check` as a compatibility health check or document the new daemon compatibility mode.
5. Assemble `verification-report.md` with commands, outputs, acceptance criteria mapping, and known risks.
6. Do not mark verification successful unless command evidence supports it.

## Done Definition

- Docs explain how a future IDE or system integrates without duplicating runtime ownership.
- Legacy PowerShell and JSON behavior is documented as compatibility, mirror, or fallback.
- `verification-report.md` maps AC01 through AC15 to evidence or explicit gaps.
- Any failed command is recorded with cause and next repair action.

## Required Verification

- `powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/jinli-system.ps1 doctor`
- `powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/jinli-mcp-smoke.ps1`
- `powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/validate-codex-capabilities.ps1 -Mode Inspect`
- `powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/task-guard.ps1 jinli/2026-06-27-runtime-daemon-unified-ide verify`

## Return Report

- Path: `reports/WP06-compat-docs-verification.md`
- Include doc changes, verification-report status, failed checks, unresolved risks, and recommended final lead decision.
