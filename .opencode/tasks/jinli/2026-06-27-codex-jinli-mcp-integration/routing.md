# Routing Decision

## Task
jinli/2026-06-27-codex-jinli-mcp-integration

## Project Type
Other (Infrastructure — Codex plugin/MCP integration)

## Requirement Classification: deep-discovery

## Requirement Discovery Gate
- Plain-language summary confirmed: yes
- Unresolved high-impact questions: none

## Quality Gate
- jinli-soul-core plugin loads successfully as Codex MCP Server
- All 18 MCP tools are available to Codex Agent
- soul_init returns valid state (not disabled)
- Python runtime services (memory/dreamer/evolution/nervous/persona/proactive) connect via adapter
- Existing Codex capabilities (node_repl, browser, computer-use) unaffected
- contract-verify/task-guard/doc-guard still work

## Work Package Policy
- External workers: no
- MVP/prototype requested by user: no
- Expected file changes: 3-5 (plugin.json, .mcp.json, server.mjs, Skill updates, Codex config)
- Expected test changes: 0 (manual verification via MCP tool calls)
- No cross-system impact
