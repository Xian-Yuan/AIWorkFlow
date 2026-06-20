# .trae/hermes/ — Repository-Owned Hermes Integration Sources

This directory contains the **repository-owned, version-controlled** source files for the Hermes workflow integration. Runtime state (profiles, memories, sessions, logs) lives under `.tools/hermes-worker/` and is never committed.

## Structure

```text
.trae/hermes/
  profiles/
    jinli-planner/          Planner profile source
      SOUL.md               Chinese Planner persona
      config.overlay.yaml   Config overlay (no inline secrets)
      mcp.json              MCP tool allowlist
      skill-bundles/        Role-specific Skill bundles
    jinli-implementer/      Implementer profile source
      SOUL.md               Chinese Implementer persona
      config.overlay.yaml   Config overlay (no inline secrets)
      mcp.json              MCP tool allowlist
      skill-bundles/        Role-specific Skill bundles
  policies/
    roles.yaml              Role/tool/path policy manifest
  mcp/
    jinli_workflow/         Workflow MCP server (Python package)
  plugins/
    jinli-workflow-guard/   Fail-closed guard plugin
  tests/
    test_workflow_mcp.py    MCP unit tests
    test_workflow_guard.py  Guard plugin unit tests
```

## Synchronization

Run `sync-hermes-workflow.ps1 -Check` to detect drift, or `-Apply` to synchronize repository sources to the runtime.

## Launching

Run `invoke-hermes-agent.ps1 -Role planner -DryRun` for a dry-run, or without `-DryRun` to start a live session.

## Credentials

Repository profile overlays contain no model credential. Hermes resolves provider credentials from each runtime profile's preserved `.env`/authentication state. Never store inline credentials in repository files, and rotate exposed credentials through the provider.
