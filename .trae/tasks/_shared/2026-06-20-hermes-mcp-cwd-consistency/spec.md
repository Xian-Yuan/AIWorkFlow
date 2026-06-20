# Spec: Hermes MCP CWD Consistency

## GIVEN

`mcp.json` uses the correct package-parent cwd while profile overlays still use the package directory.

## WHEN

The compatibility assertion is strengthened and the overlays are synchronized.

## THEN

### S01: Source and runtime agreement

**Status**: [x] verified

All four repository config surfaces and both runtime configs use the package-parent cwd, and stdio initialization succeeds.

## Acceptance Criteria

| AC# | Description | Verification |
|---|---|---|
| AC01 | Source configs agree | compatibility suite |
| AC02 | Runtime configs agree | sync check and grep |
| AC03 | MCP starts | stdio tests |
| AC04 | No regression | full Hermes verification |

## Progress Summary

| Phase | Status |
|---|---|
| Plan | Complete |
| Implement | Complete |
| Review | Complete |
| Verify | Complete |
