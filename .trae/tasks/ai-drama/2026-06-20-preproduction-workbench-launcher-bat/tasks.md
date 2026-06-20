# Tasks: Preproduction Workbench BAT Launcher

## Dependency Graph

```text
T1 launcher -> T2 operations docs -> T3 verification
```

---

## Launcher

- [x] T1.1: Add root-level `Project/AIDramaProducer/start-preproduction-workbench.bat`.
- [x] T1.2: Support `--check` mode for non-blocking verification.
- [x] T1.3: Ensure the launcher uses paths relative to itself and does not require global installs.
- [x] T1.4: Open the browser only after the Vite server is reachable.
- [x] T1.5: Add `--smoke-test` mode for automated reachability verification.

## Documentation

- [x] T2.1: Add operations note for double-click launch.
- [x] T2.2: Update `Project/AIDramaProducer/Docs/DOCS_TREE.md`.

## Final Verification

- [x] T3.1: Run launcher check mode and record output.
- [x] T3.2: Run launcher smoke mode and record reachable URL output.
- [x] T3.3: Run frontend build and record output.
- [x] T3.4: Verify selected mature path was implemented and no rejected shortcut was introduced.
- [x] T3.5: Run automated verification and record command output in `verification-report.md`.
- [x] T3.6: Map implementation result to Acceptance Criteria in `verification-report.md`.
