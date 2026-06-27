# Analysis: Hermes MCP CWD Consistency

## Architecture Context

### System boundaries

- Repository profile overlays are source; runtime profiles are generated.

### Dependency map

- `config.overlay.yaml` → sync script → runtime `config.yaml` → Hermes MCP process.
- `mcp.json` and overlay must use the same package-parent cwd.

### Data and state ownership

- Repository owns overlays and tests.
- Runtime owns generated profile config and user credentials.

### Integration points

- `sync-hermes-workflow.ps1`
- `test-hermes-skill-compatibility.ps1`

## Mature Solution Evidence

### Project-local evidence

- Both `mcp.json` files use `.trae/hermes/mcp`.
- Both overlays and generated configs still use `.trae/hermes/mcp/jinli_workflow`.

### Official/framework evidence

- `python -m jinli_workflow` requires the package parent on the module search path.

### External mature references

- Not required for this local packaging fix.

### Options compared

| Option | Result | Decision |
|---|---|---|
| Fix overlays and assert both surfaces | Source and runtime converge | Selected |
| Set PYTHONPATH only | Masks incorrect config | Rejected |

### Rejected shortcuts

- Do not patch generated runtime config by hand.
- Do not rely on doctor to validate MCP subprocess importability.

### Selected mature path

Test both configuration surfaces, fix repository overlays, sync runtime, and rerun stdio subprocess verification.

## Acceptance Criteria

- AC01: Both overlays and both mcp.json files use `E:/UEGameDevelopment/.trae/hermes/mcp`.
- AC02: Compatibility suite remains 27/27.
- AC03: Runtime sync applies the corrected cwd.
- AC04: Full Hermes verification remains green.

## Automated Verification Plan

- Command: compatibility suite, sync Apply/Check, stdio tests, E2E, doctors.
- Expected: all pass and runtime configs contain the package-parent cwd.

