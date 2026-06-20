# Analysis: AIDramaProducer Verification Truth Closure

## Architecture Context

### System boundaries
- `ai_drama_text_preprocessor` owns chapter-event character references.
- `ai_drama_viral_analyzer` produces a four-file injection bundle.
- `ai_drama_scriptwriter` owns loading and applying that bundle to generation prompts.
- `ai_drama_orchestrator` passes an optional injection path into Scriptwriter.
- Pytest configuration owns the canonical repository-level test entrypoint.
- Task packets record facts but do not redefine unfinished product requirements.

### Dependency map
```text
WP01 character-ID contract
  └─ WP03 factual documentation

WP02 pytest root + injection consumer
  ├─ Scriptwriter loader and prompt plumbing
  ├─ Viral CLI command contract
  └─ Orchestrator pass-through
       └─ WP03 factual documentation

WP03 task-packet reconciliation
  └─ WP04 fresh verification and signed review
```

### Data and state ownership
- Character graph values use stable character IDs whenever `known_ids` and `char_map` are supplied.
- Injection bundle files remain owned by Viral Analyzer; Scriptwriter reads them without mutating them.
- Scriptwriter applies injection only to prompt context and generated character defaults, never silently overwriting explicit model output.
- `.task.yaml` phase and result fields are changed only by issuer-authorized commands.

### Integration points
- `_detect_characters(text, known_ids, char_map)`
- `load_injection_bundle(style_injection_path)`
- `run_step1`, `run_step2`, `run_step3`
- `ai_drama_scriptwriter quick --style-injection`
- `ai_drama_orchestrator --style-injection`
- `python -m pytest -q` from `Project/AIDramaProducer/skills`

## Current failure evidence
- AC03 currently returns role names instead of the required known IDs.
- Root-level pytest collects `test_real_run.txt` and fails UTF-8 decoding.
- Viral Analyzer prints a Scriptwriter flag that Scriptwriter does not implement.
- Three original packets have open product tasks and no worker reports, so their gates correctly fail.
- The 2026-06-19 repair packet incorrectly describes failed gates as waiting for approval.

## Acceptance Criteria
- AC01: Character detection returns a subset of `known_ids` when a mapping is provided, while legacy regex mode remains available without IDs.
- AC02: `python -m pytest -q` from the skills root completes without collecting runtime input artifacts.
- AC03: Scriptwriter accepts a Viral Analyzer injection bundle and includes its values in Step 1/2/3 prompt context.
- AC04: Viral Analyzer emits a valid `python -m ai_drama_scriptwriter` command and Orchestrator can pass the injection path through Phase 2.
- AC05: Original and repair task packets state only evidence-backed progress; no approval-override language remains.
- AC06: Targeted tests, root tests, module CLIs, non-dry-run placeholder pipeline, doc guard, and task gates have recorded fresh outputs.

## Automated Verification Plan
- Command: `python -m pytest -q`
  - Expected: all collected tests pass and no `.txt` collection error occurs.
- Command: `python -m pytest ai_drama_text_preprocessor/tests ai_drama_scriptwriter/tests ai_drama_viral_analyzer/tests ai_drama_orchestrator/tests -q`
  - Expected: focused regression tests pass.
- Command: `python -m ai_drama_scriptwriter quick --help`
  - Expected: `--style-injection` is present.
- Command: `python -m ai_drama_orchestrator --help`
  - Expected: `--style-injection` is present.
- Command: `task-guard.ps1 ai-drama/2026-06-20-verification-truth-closure implement`
  - Expected: exit 0 only after every task is checked and documentation governance passes.
- Command: fresh-context verification commands recorded in `verification-report.md`
  - Expected: all new-packet ACs pass; original unfinished packets remain unarchived.

## Mature Solution Evidence

### Project-local evidence
- Viral Analyzer already emits four structured JSON files.
- Scriptwriter already centralizes prompt construction in three generation modules.
- Orchestrator already creates Scriptwriter argument objects in Phase 2.
- Existing pytest suites provide 95 passing targeted tests.

### Official/framework evidence
- Pytest supports a repository-local `pytest.ini` with explicit `testpaths` and `python_files`.
- Python CLI options should be defined by the consuming command rather than printed as undocumented pseudo-contracts.
- Stable identifiers, rather than display names, are the correct cross-module reference contract.

### Options compared
| Option | Pros | Cons | Decision |
|---|---|---|---|
| Change the AC to accept names | Minimal code | Breaks stable-ID contract and hides the bug | Rejected |
| Return IDs when mappings exist, names only in regex fallback | Preserves compatibility and stable references | Requires explicit dual-mode behavior | Selected |
| Delete runtime `.txt` files before every test | Fast locally | Destructive and non-repeatable | Rejected |
| Add canonical pytest discovery configuration | Repeatable and preserves artifacts | Adds one config file | Selected |
| Concatenate raw JSON into one prompt only | Small patch | Weak ownership and difficult testing | Rejected |
| Load a validated bundle and pass typed sections to each step | Clear boundary and independently testable | Touches several function signatures | Selected |
| Mark original packets complete after documenting non-goals | Makes gates green | Falsifies their accepted scope | Rejected |
| Keep original tasks open and report actual completion | Truthful and mechanically consistent | Original packets remain active | Selected |

### Rejected shortcuts
- User approval as a substitute for failed mechanical gates.
- Renaming or deleting unfinished acceptance criteria.
- Tests that assert only CLI flag presence without checking prompt consumption.
- Treating a 32-byte placeholder MP4 as proof of production video quality.
- Archiving original packets with open tasks.

### Selected mature path
Use stable-ID semantics, explicit pytest discovery, a validated read-only injection bundle, prompt-level propagation through all Scriptwriter steps, Orchestrator pass-through, and evidence-backed task reconciliation. Completion is limited to this closure packet; original product work stays open.
