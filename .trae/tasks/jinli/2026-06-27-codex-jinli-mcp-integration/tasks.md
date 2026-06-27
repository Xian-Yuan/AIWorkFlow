# Tasks: Codex Jinli MCP Integration

## Task 1: Diagnose plugin loading failure
- [ ] Check Codex plugin cache for jinli-soul-core presence
- [ ] Verify plugin.json format matches working plugins (browser, figma)
- [ ] Check .mcp.json command/args point to valid Node.js entry
- [ ] Test server.mjs standalone: 
ode mcp/server.mjs from plugin directory
- [ ] Check Codex personal marketplace registration
- [ ] Identify the specific failure point (registration vs. loading vs. runtime)
- Basis: analysis.md Architecture Context

## Task 2: Fix plugin registration/loading
- [ ] Fix identified loading issue (could be: marketplace not registered, plugin not installed, MCP server startup failure, etc.)
- [ ] If marketplace issue: register "personal" marketplace in Codex config
- [ ] If plugin install issue: install jinli-soul-core into Codex plugin cache
- [ ] If MCP startup issue: fix server.mjs or .mcp.json configuration
- [ ] Verify plugin appears in Codex's MCP tool list after fix
- Basis: Task 1 findings

## Task 3: Test MCP tool connectivity
- [ ] Call soul_init(ide:"codex") and verify response
- [ ] Call soul_auto with test input
- [ ] Call soul_status for full state
- [ ] Call response_plan for tone modulation
- [ ] Test graceful degradation when Python unavailable
- Basis: spec.md Acceptance Criteria

## Task 4: Verify Python runtime bridge
- [ ] Test jinli-runtime-turn.ps1 -Mode lite -UserInput "test"
- [ ] Verify adapters (memory, persona, dreamer, evolution, nervous, proactive) load
- [ ] Check graceful degradation when Python venv not found
- Basis: analysis.md Automated Verification Plan

## Task 5: Regression verification — automated verification
- [ ] Run contract-verify init + verify on existing task
- [ ] Run task-guard plan on existing task
- [ ] Call node_repl tool to verify no regression
- [ ] Confirm all AC pass
- Basis: analysis.md Acceptance Criteria

## Task 6: Update Skill integration references
- [ ] Update 金璃小天才 SKILL.md to note MCP tools are now available
- [ ] Update 金璃好帮手 SKILL.md to note MCP tools are now available
- [ ] Update jinli-agent-soul SKILL.md with Codex-specific activation notes
- [ ] Update AGENTS.md with Soul Core MCP activation section
- Basis: analysis.md Architecture Context

## Task 7: Mature-path verification
- [ ] Verify selected mature path (Option A: fix existing plugin) is followed
- [ ] Verify rejected shortcuts (Option B/C) are not taken
- Basis: analysis.md Selected mature path and Rejected shortcuts
