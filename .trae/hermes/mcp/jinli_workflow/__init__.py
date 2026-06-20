"""jinli_workflow — Typed, path-safe, role-authorized MCP server.

Exposes a narrow workflow interface over authoritative PowerShell scripts.
All path operations validate against traversal.
All gate decisions are delegated to .trae/scripts.
Secrets are redacted from diagnostics.
"""

__version__ = "1.0.0"
