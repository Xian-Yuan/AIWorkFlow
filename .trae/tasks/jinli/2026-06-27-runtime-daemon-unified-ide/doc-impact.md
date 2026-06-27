# Doc Impact Assessment

- Project: Jinli
- System: Runtime daemon, MCP adapter, IDE integration
- Owner: Ba Ba and Jinli lead agent

## Code Changes

- Project/Jinli/services/runtime/
- Project/Jinli/services/jinli_service.py
- Project/Jinli/services/jinli_daemon.py
- Project/Jinli/services/memory/
- Project/Jinli/services/nervous/
- Project/Jinli/services/evolution/
- Project/Jinli/services/proactive/
- Project/Jinli/services/persona/
- C:/Users/87372/plugins/jinli-soul-core/mcp/
- .trae/scripts/jinli-system.ps1
- .trae/scripts/jinli-ide-sync.ps1
- .trae/scripts/validate-codex-capabilities.ps1
- .opencode/mcp.json
- opencode.json
- C:/Users/87372/.codex/config.toml

## No Code Changes

Reason: Not applicable. This task is expected to change runtime and adapter code after Plan approval. No project implementation files may be changed before edit gates pass.

## Documentation Updates

- Project/Jinli/Docs/03-Architecture/runtime-daemon-unified-ide.md
- Project/Jinli/Docs/03-Architecture/runtime-enforcement-layer.md
- Project/Jinli/Docs/04-Implementation/runtime-protocol.md
- Project/Jinli/Docs/06-Operations/runtime-daemon-runbook.md
- Project/Jinli/Docs/DOCS_TREE.md
- Docs/AI/47-Jinli-Runtime-Enforcement-Layer.md
- AGENTS.md

## Docs Tree Updates

- Project/Jinli/Docs/DOCS_TREE.md

## Governance Notes

- If implementation changes code under `Project/Jinli`, same-project docs must be updated.
- If Codex/OpenCode/Trae behavior changes, the relevant AI workflow documentation or AGENTS table of contents must be updated.
- If a listed path is not touched during implementation, verification-report.md must explain why the doc-impact prediction changed.
