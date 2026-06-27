# Spec: Preproduction Workbench BAT Launcher

## GIVEN

Ba Ba wants a foolproof double-click way to open the preproduction creative workbench.

## WHEN

The user runs `Project/AIDramaProducer/start-preproduction-workbench.bat`.

## THEN

The script checks prerequisites, installs local dependencies if needed, starts the existing Vite dev server and opens the app URL in the default browser.

### S01 Normal Launch

**Status**: [x]

With Node.js/npm installed and dependencies present, the BAT starts `npm run dev` in the workbench directory and opens `http://localhost:5173`.

### S02 First Launch

**Status**: [x]

If `node_modules` is missing, the BAT runs `npm install` once before starting the dev server.

### S03 Missing Prerequisite

**Status**: [x]

If Node.js or npm is missing, the BAT prints a readable message and pauses instead of closing instantly.

## Acceptance Criteria

| AC# | Description | Verification Command | Expected Output |
|-----|-------------|---------------------|-----------------|
| AC01 | Launcher check mode validates app path and prerequisites | `cmd /c Project\AIDramaProducer\start-preproduction-workbench.bat --check` | exit 0 and `CHECK PASSED` |
| AC02 | Workbench still builds | `npm.cmd run build` | exit 0 |
| AC03 | Docs governance passes | `.trae\scripts\doc-guard.ps1 check-task ... -Stage implement` | DOCUMENTATION GOVERNANCE PASSED |

## Progress Summary

| Phase | Status | Key Decision |
|-------|--------|-------------|
| Plan | Complete | Root-level BAT selected |
| Implement | Complete | No source behavior change |
| Review | Complete | Launcher check, build and doc guard passed |
| Verify | Complete | Verification report records command outputs |

## Non-Goals

- Packaging a desktop installer.
- Changing frontend behavior.
- Adding media generation.
