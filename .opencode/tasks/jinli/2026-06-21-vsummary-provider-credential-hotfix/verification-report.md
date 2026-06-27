# Verification Report: vsummary Provider Credential Hotfix

Date: 2026-06-21
Verifier: Codex lead

## Automated Verification

1. Focused settings suite:

   ```powershell
   $env:PYTHONPATH='E:\Obsidian\tools\vsummary\src'
   E:\Obsidian\tools\vsummary\.venv\Scripts\python.exe E:\Obsidian\tools\vsummary\tests\backend\unit\settings\test_workspace_settings_service.py
   ```

   Result: 17 tests ran and passed.

2. Python syntax verification:

   ```powershell
   E:\Obsidian\tools\vsummary\.venv\Scripts\python.exe -m py_compile `
     src\backend\video_summary\infrastructure\settings_service.py `
     tests\backend\unit\settings\test_workspace_settings_service.py `
     test_llm_compare.py test_litellm_nvidia.py test_trace_bug.py `
     test_async_bug.py test_full_gateway.py test_direct_generate.py `
     test_gateway.py test_gateway_format.py test_litellm_debug.py
   ```

   Result: exit code 0.

3. Secret-pattern scan of the 11 changed source, test, and diagnostic files:

   Result: zero files matched provider-key or bearer-token patterns.

4. Whitespace validation:

   ```powershell
   git diff --check
   ```

   Result: exit code 0; only existing line-ending conversion warnings were emitted.

5. Documentation governance:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/doc-guard.ps1 `
     check-task jinli/2026-06-21-vsummary-provider-credential-hotfix -Stage implement
   ```

   Result: passed.

## Test Evidence

- RED: before implementation, the focused 17-test suite failed the two new rejection tests because malformed credentials were accepted.
- GREEN: after settings-boundary validation, all 17 tests passed.
- Runtime invalid-input test: a Chinese placeholder sent to `PUT /api/provider-settings` returned HTTP 400 and did not replace the recovered credential.
- Runtime credential metadata: provider settings reported that a credential remained present; no credential value was printed.
- Original regression path: `GET /api/videos/__playground__/BV1UF7m68E1K/summary` returned HTTP 200 with a 7,629-byte structured summary after generation.
- The returned summary contained the expected structured fields: title, one-sentence summary, core problem, chapters, and key takeaways.

## Acceptance Criteria

| AC | Result | Evidence |
|---|---|---|
| AC01 Reject non-ASCII credentials | Pass | focused unit test and live HTTP 400 |
| AC02 Reject masked placeholders | Pass | focused unit test |
| AC03 Preserve valid ASCII credentials | Pass | focused unit test and restored-key metadata |
| AC04 Credential reaches provider path | Pass | original generation completed; no encoding failure |
| AC05 Original generate path works | Pass | summary HTTP 200, 7,629 bytes |
| AC06 No secrets added | Pass | bounded secret scan found zero matching files |
| AC07 Documentation synchronized | Pass | operations runbook added and doc-guard passed |

## Architecture Compliance

- Validation is performed at the provider-settings boundary before HTTP header construction.
- Existing Ollama and empty-key reuse behavior remains intact.
- The repair does not rely on console encoding or LiteLLM logging suppression as the root fix.
- Diagnostic scripts read credentials from environment variables.
- No Jinli runtime code or unrelated vsummary files were overwritten.
- The separately existing changes in `server.py` and `litellm_gateway.py` were preserved and are outside this hotfix's authored diff.

## Residual Risk

- `POST /api/provider-settings/test` has a short model timeout and returned HTTP 503 for the current provider. The stronger original video-generation path completed successfully, so this is classified as diagnostic timeout behavior rather than a credential or encoding failure.
- The recovered provider credential was found in approved local state but was not rotated at the provider account. Rotation remains an operator security decision.
- The vsummary worktree contains pre-existing user/Hermes changes and untracked scripts. This hotfix intentionally did not clean or commit that worktree.

