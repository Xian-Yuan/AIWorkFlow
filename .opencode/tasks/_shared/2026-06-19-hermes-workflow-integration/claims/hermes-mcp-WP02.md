# WP02 Claim: Hermes Workflow MCP Server

- **Claim ID**: hermes-mcp-WP02
- **Task**: _shared/2026-06-19-hermes-workflow-integration
- **Claimed by**: 金璃好帮手 (lead model)
- **Status**: active

## Claim Scope

Implementation of the jinli-workflow MCP server:
1. Path validation and traversal rejection (paths.py)
2. Role-based tool authorization (policy.py)
3. Claim and report schema validation (schemas.py)
4. Business logic layer delegating to PowerShell scripts (service.py)
5. JSON-RPC MCP server over stdio (server.py)
6. Package entry point (__main__.py, __init__.py)
7. Unit tests (test_workflow_mcp.py)

## Allowed Paths
- `.trae/hermes/mcp/jinli_workflow/**`
- `.trae/hermes/tests/test_workflow_mcp.py`

## Gates
- [x] Plan gate: PASS
- [x] Can-Edit: PASS
