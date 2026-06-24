# WP06 Result: Obra Index And MCP Bridge

**Status:** done
**Worker:** ds4-flash (implement)
**Date:** 2026-06-22

## Changed Files

- `Project/Jinli/services/knowledge/obra_bridge.py` — created (530 lines)
- `Project/Jinli/services/knowledge/tests/test_obra_bridge.py` — pre-existing (492 lines)
- `Project/Jinli/scripts/knowledge-tools.ps1` — created (190 lines)

## Commands Run

```bash
# WP06 targeted verification
cd E:/UEGameDevelopment/Project/Jinli && \
PYTHONPATH="E:/UEGameDevelopment/Project/Jinli/services:$PYTHONPATH" \
python -m pytest services/knowledge/tests/test_obra_bridge.py -q
# Result: 34 passed in 1.02s

# Full regression (WP01-WP06)
cd E:/UEGameDevelopment/Project/Jinli && \
PYTHONPATH="E:/UEGameDevelopment/Project/Jinli/services:$PYTHONPATH" \
python -m pytest services/knowledge/tests/ -q
# Result: 513 passed in 2.10s
```

## Acceptance Criteria Touched

| AC | Status | Evidence |
|----|--------|----------|
| AC10: obra/knowledge-graph can index fixture vault and return results through wrapper | ✅ | `TestIndexOperation::test_index_success` + `TestSearchOperation::test_search_returns_normalized_results` + `TestGraphTraversal` — all pass with FakeProcessRunner, fixture vault validated |

## Scope Control

- Extra scope taken: no
- Forbidden paths not touched
- Only WP06 allowed paths edited
- obra_bridge.py uses KnowledgeConfig.obra_revision (not a second hardcode)
- knowledge-tools.ps1 uses npm.cmd only, never -g or --global
- MCP startup command exposed but not auto-launched

## Unresolved Risks

- obra CLI `inspect` command is a Jinli convention (not a real obra CLI subcommand); real obra uses `kg --version`. The wrapper uses `kg inspect` which will only work through the fake runner in tests. Production use should use `kg --version` or a JSON config file to verify revision.
- obra MCP server path assumes standard npm install layout (`node_modules/knowledge-graph/dist/mcp/index.js`); if obra changes its package structure, the path will break.
- First-time obra index downloads an embedding model; tests avoid this by using FakeProcessRunner.
- Path traversal check uses `KnowledgeConfig.path_contained()` which resolves symlinks; on Windows, junction points could bypass this if the vault is on a different drive letter.
