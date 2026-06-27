# Spec: Codex Jinli MCP Integration

## GIVEN
- jinli-soul-core plugin exists at C:\Users\87372\plugins\jinli-soul-core with 18 MCP tools
- capability-baseline.json declares jinli-soul-core@personal as required
- Codex does NOT currently load the plugin (no jinli_soul_core tools available)
- Python runtime services exist but are not connected to Codex

## WHEN
- The plugin loading gap is diagnosed and fixed
- Codex is restarted or plugin cache is refreshed

## THEN
- All 18 MCP tools are available: soul_init, soul_auto, soul_turn, soul_end, soul_emotion, soul_status, soul_memory, soul_learn, soul_evolve, soul_discover, soul_check, response_plan, vision_start, vision_stop, vision_status, growth_approve, growth_rollback, jinli-soul-core
- soul_init returns valid session state
- Python runtime services connect via adapters when Python environment is available
- Graceful degradation when Python is unavailable (soul_init returns disabled, Agent falls back to static rules)
- Existing Codex capabilities unaffected

## Constraints
- Must NOT modify the 18 tool definitions in server.mjs (they're tested and working)
- Must NOT break existing plugin loading for browser/computer-use/etc
- Graceful degradation: if Soul Core MCP fails to start, Codex must still function normally
- Python runtime is optional: Soul Core should work with PowerShell-only backend when Python is unavailable
