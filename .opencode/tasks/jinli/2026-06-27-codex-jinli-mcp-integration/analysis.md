# Analysis: Codex Jinli MCP Integration

## Architecture Context
Codex supports a plugin system via .codex-plugin/plugin.json and .mcp.json. The jinli-soul-core plugin already exists at C:\Users\87372\plugins\jinli-soul-core with 18 MCP tools, but it's not loaded in the current Codex session. The capability-baseline.json declares it as required, yet Codex's runtime doesn't activate it.

**System boundaries**: Integration scope is Codex plugin loading mechanism + Soul Core MCP Server connectivity. The Python services (memory/dreamer/evolution/nervous/persona/proactive) are already implemented and tested; they need to be connected via runtime adapters.

**Dependency map**: Codex App → .codex-plugin/plugin.json → .mcp.json → mcp/server.mjs → Python services via jinli-runtime-turn.ps1. Current gap: the plugin exists but Codex doesn't load it.

## Mature Solution Evidence
**Project-local evidence**: jinli-soul-core plugin is fully implemented at C:\Users\87372\plugins\jinli-soul-core with server.mjs, 18 tool definitions, Zod validation, and complete node_modules. The Python runtime (Project/Jinli/services/runtime/) has TurnOrchestrator with 8 adapters.

**Official/framework evidence**: Codex supports .codex-plugin format with mcpServers field pointing to .mcp.json. Other plugins (browser, computer-use, figma) use this exact pattern and load successfully.

**Options compared**:
1. Option A: Fix the existing plugin's loading in Codex (investigate why it's not loading despite being in capability-baseline) — minimal change, leverages existing code
2. Option B: Create a new simpler MCP Server that wraps jinli-runtime-turn.ps1 directly — bypasses plugin system, but creates duplicate infrastructure
3. Option C: Register MCP Server in Codex's config.toml directly — may not be supported by Codex's current architecture

**Rejected shortcuts**: Option B rejected because it duplicates the existing server.mjs that already has 18 well-tested tools. Option C rejected because config.toml only has sandbox_mode; Codex uses plugin system, not raw config.

**Selected mature path**: Option A — diagnose why the existing plugin isn't loading and fix it. The plugin is complete; the gap is in the registration/activation path.

1. **Project internal**: jinli-soul-core plugin fully implemented with 18 MCP tools
2. **Official reference**: Codex plugin system documented via existing working plugins (browser, figma, etc.)
3. **Open source reference**: MCP SDK (@modelcontextprotocol/sdk) already in node_modules
4. **Design doc**: Docs/AI/38-Jinli-Agent-Soul-Architecture.md, capability-baseline.json
5. **Existing implementation**: server.mjs handles all 18 tools with Zod validation
6. **Risk assessment**: Low risk — plugin code is done; only activation path needs investigation

## Acceptance Criteria
- AC1: soul_init MCP tool is callable from Codex Agent and returns non-disabled state
- AC2: All 18 MCP tools appear in Codex's available tool list
- AC3: soul_auto correctly classifies emotion triggers from user input
- AC4: esponse_plan returns tone modulation directives
- AC5: soul_status shows valid emotion/persona state
- AC6: Existing Codex capabilities (node_repl, browser) remain functional
- AC7: contract-verify/task-guard/doc-guard still pass
- AC8: Python runtime services can be invoked via jinli-runtime-turn.ps1 through the MCP adapter

## Automated Verification Plan
- Step 1: List MCP tools available to Codex — verify jinli_soul_core namespace appears
- Step 2: Call soul_init(ide:"codex") — verify non-disabled response
- Step 3: Call soul_auto(input:"test") — verify emotion classification
- Step 4: Call soul_status — verify persona state
- Step 5: Run contract-verify init + verify — verify existing enforcement still works
- Step 6: Call existing node_repl tool — verify no regression
