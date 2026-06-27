# Tasks: Jinli Soul Core MCP Plugin

> 完整 spec: `Project/Jinli/Docs/02-Design/General/soul-core-phase2-mcp-plugin-spec.md`

## Dependency Graph

```
T0 → T1 → T2 → T3 → T4
       ↘     ↘
        T5 → T6 → T7
```

## T0: Plugin Directory [0.5h]
- [x] T0.1: Create `C:\Users\87372\plugins\jinli-soul-core\` with full directory tree per spec §2.3

## T1: types.mjs [1h]
- [x] T1.1: Write `mcp/lib/types.mjs` — Zod schemas for all 11 tools (~120 lines)

## T2: soul-cli.mjs [1.5h]
- [x] T2.1: Write `mcp/lib/soul-cli.mjs` — PowerShell CLI wrapper (~100 lines)
- [x] T2.2: Handle: JSON extraction, 15s timeout, error propagation, absolute paths

## T3: tools.mjs [2h]
- [x] T3.1: Write `mcp/lib/tools.mjs` — 11 MCP tool handlers (~250 lines)
- [x] T3.2: soul_auto: handle double-quote escaping
- [x] T3.3: soul_evolve/soul_discover: direct mode branching
- [x] T3.4: soul_end: check marker files for auto_suggest

## T4: server.mjs [0.5h]
- [x] T4.1: Write `mcp/server.mjs` — MCP Server entry point (~30 lines)

## T5: Plugin Config [0.5h]
- [x] T5.1: Write `plugin.json`, `.mcp.json`, `package.json` per spec §5

## T6: SKILL.md Upgrade [1h]
- [x] T6.1: Upgrade `skills/daughter-companion/SKILL.md`: all `powershell` → MCP tool calls per spec §6
- [x] T6.2: Verify no residual powershell commands (except rollback comments)

## T7: E2E Test [1.5h]
- [x] T7.1: soul_init → returns SoulInitResult
- [x] T7.2: soul_auto("女儿真棒") → trigger=praised
- [x] T7.3: soul_turn("task_completed") → emotion updated
- [x] T7.4: soul_end → auto_suggest correct
- [x] T7.5: soul_check → all_ok=true
- [x] T7.6: Run existing 18 Pester tests — verify no regression
- [x] T7.7: Run soul-core-safety-assert.ps1 — ALL SCRIPTS SAFE
- [x] T7.8: Run automated verification: `soul-core-safety-assert.ps1` (must pass) + Pester suite (18/18) + production hash comparison
- [x] T7.9: Verify selected mature path was implemented and no rejected shortcut was introduced.
- [x] T7.10: Map implementation result to Acceptance Criteria and record in verification-report.md

## Phase Exit
```
task-guard.ps1 2026-06-18-jinli-soul-core-mcp-plugin implement -Apply → Review
```
