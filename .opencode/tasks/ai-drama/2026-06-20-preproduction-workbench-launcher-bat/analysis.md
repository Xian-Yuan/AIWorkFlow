# Analysis: Preproduction Workbench BAT Launcher

## Architecture Context

### System boundaries

- AIDramaProducer owns the launcher.
- The BAT file is an operations convenience entrypoint only.
- The existing Vite workbench app remains the UI implementation owner.

### Dependency map

- `start-preproduction-workbench.bat` -> `apps/preproduction-workbench/package.json` scripts -> Vite dev server -> browser URL `http://localhost:5173`.

### Data and state ownership

- The launcher owns no application data.
- Browser local storage and workbench runtime state remain owned by the frontend app.
- Node dependencies remain under `apps/preproduction-workbench/node_modules`.

### Integration points

- Windows command shell.
- Node.js and npm on PATH.
- Existing `npm run dev` script in `Project/AIDramaProducer/apps/preproduction-workbench/package.json`.

## Mature Solution Evidence

### Project-local evidence

- The workbench already has a working `npm run dev`, build, unit test and Playwright setup.
- AIDramaProducer project root is the natural place for a double-click launcher.

### Official/framework evidence

- Vite apps are normally launched through `npm run dev`; wrapping that in BAT preserves the existing framework path.

### External mature references

- Common Windows local tool workflows provide root-level `start-*.bat` launchers for non-technical users.

### Options compared

| Option | Source | Pros | Cons | Decision |
|---|---|---|---|---|
| Root-level BAT launcher | Windows local tool convention | Double-clickable, simple, no new dependencies | Windows-only | Selected |
| PowerShell-only launcher | Windows scripting | Better process control | May be blocked by execution policy | Rejected as primary |
| Desktop packaging | Tauri/Electron | Polished one-click app | Too heavy for immediate need | Rejected |

### Rejected shortcuts

- Do not require Ba Ba to manually open a terminal and type npm commands.
- Do not hard-code absolute user-specific paths.
- Do not install global packages.

### Selected mature path

- Add a portable project-root BAT file that resolves paths relative to itself, checks prerequisites, installs local dependencies if missing, opens the browser after a short delay and runs the existing Vite dev server.

## Acceptance Criteria

- AC01: Double-clicking the BAT from `Project/AIDramaProducer` starts the workbench dev server.
- AC02: If `node_modules` is missing, the BAT runs `npm install` before launch.
- AC03: The BAT opens `http://localhost:5173` in the default browser and gives readable error messages when Node/npm is missing.

## Automated Verification Plan

- Command: `cmd /c Project\AIDramaProducer\start-preproduction-workbench.bat --check`
- Expected: exits 0 after Node/npm and app directory checks.
- Command: `npm.cmd run build` from `Project/AIDramaProducer/apps/preproduction-workbench`
- Expected: build exits 0.

