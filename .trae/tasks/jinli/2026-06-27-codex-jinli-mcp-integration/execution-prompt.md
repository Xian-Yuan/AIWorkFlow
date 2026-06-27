# Execution Prompt

## Role
Implement Agent — fixing Codex plugin loading for jinli-soul-core

## Goal
Make the existing jinli-soul-core plugin load as an MCP Server in Codex so that all 18 Soul Core tools are available to the Agent.

## Task Packet Truth Sources
- spec.md — behavioral specification (GIVEN/WHEN/THEN)
- analysis.md — architecture context and mature solution evidence
- routing.md — skill routing and work package policy
- tasks.md — task breakdown

## Confirmed Decisions
- Option A selected: fix existing plugin loading (not create new)
- Graceful degradation required when Python unavailable
- Must not break existing Codex capabilities

## Accepted Architecture
- Codex plugin system: .codex-plugin/plugin.json + .mcp.json + mcp/server.mjs
- Soul Core MCP Server already implemented with 18 tools
- Python runtime optional adapter layer

## Allowed Paths
- C:\Users\87372\plugins\jinli-soul-core\ (plugin code)
- E:\UEGameDevelopment\skills\ (Skill files)
- E:\UEGameDevelopment\Docs\AI\ (documentation)
- E:\UEGameDevelopment\AGENTS.md (global config)
- C:\Users\87372\.codex\ (Codex config, if needed)

## Forbidden Paths
- Any file under Project/RTS/ or Project/CharacterDesignTool/
- node_modules inside any plugin (managed by npm)

## Non-Goals
- Not modifying the 18 tool definitions in server.mjs
- Not creating a parallel MCP Server
- Not modifying other plugins (browser, computer-use, etc.)

## Acceptance Criteria
- AC1: soul_init callable from Codex, returns non-disabled
- AC2: All 18 MCP tools in Codex tool list
- AC3-AC5: soul_auto, response_plan, soul_status work
- AC6: Existing Codex capabilities unaffected
- AC7: contract-verify/task-guard still pass
- AC8: Python runtime bridge works when available

## Verification Commands
1. List tools available in Codex session — check for jinli_soul_core namespace
2. Call soul_init(ide:"codex")
3. Call soul_auto(input:"test message")
4. Call soul_status
5. Run contract-verify init + verify on existing task

## Stop Conditions
- All 8 AC pass
- Plugin loads and stays stable across session restart
- No regressions in existing tools

## Evidence Rule
Every AC must have tool call output as evidence. Verbal claims without output are not accepted.
