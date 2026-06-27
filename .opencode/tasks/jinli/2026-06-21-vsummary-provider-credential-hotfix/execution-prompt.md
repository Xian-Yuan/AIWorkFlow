# Execution Prompt: vsummary Provider Credential Hotfix

## Role
Act as the bounded implementation agent for the vsummary provider credential hotfix. Preserve user changes and produce evidence before claims.

## Goal
Restore working provider authentication, prevent invalid placeholder credentials from reaching HTTP header construction, and verify the original video generation API.

## Task Packet Truth Sources
- `.trae/tasks/jinli/2026-06-21-vsummary-provider-credential-hotfix/analysis.md`
- `.trae/tasks/jinli/2026-06-21-vsummary-provider-credential-hotfix/spec.md`
- `.trae/tasks/jinli/2026-06-21-vsummary-provider-credential-hotfix/tasks.md`
- `.trae/tasks/jinli/2026-06-21-vsummary-provider-credential-hotfix/doc-impact.md`

## Confirmed Decisions
- Treat the corrupted provider credential as the confirmed root cause.
- Use test-driven development for validation behavior.
- Restore the credential without displaying it.
- Do not delete user diagnostic files.

## Accepted Architecture
Validate provider credentials in the existing settings service before save, connection test, Gateway construction, or HTTP header encoding. Keep the Gateway provider-neutral.

## Allowed Paths
- `E:\Obsidian\tools\vsummary\src\backend\video_summary\infrastructure\settings_service.py`
- `E:\Obsidian\tools\vsummary\tests\backend\unit\settings\test_workspace_settings_service.py`
- Existing local vsummary diagnostic scripts that contain the same exposed credential
- `E:\Obsidian\tools\vsummary\.env` through the documented provider settings API
- `Project/Jinli/Docs/06-Operations/KnowledgeGraph/vsummary-provider-credential-recovery.md`
- `Project/Jinli/Docs/DOCS_TREE.md`
- This task packet for progress and evidence updates

## Forbidden Paths
- Bilibili cookie values and browser data
- Unrelated vsummary modules
- Knowledge graph runtime implementation
- Remote provider account settings
- Deleting any file

## Non-Goals
- Do not build the favorites automation in this hotfix.
- Do not replace LiteLLM globally.
- Do not change media cleanup behavior.

## Acceptance Criteria
- AC01 through AC07 in `analysis.md` and `spec.md` must be evidenced.

## Verification Commands
- Run the focused provider settings pytest file.
- Run the provider settings test endpoint without exposing secrets.
- Run and poll the original video generation endpoint.
- Run a bounded secret scan and documentation guard.

## Stop Conditions
- Stop if no valid local provider credential can be recovered.
- Stop if provider authentication fails after the credential is restored.
- Stop if the generate path exposes a different root cause requiring broader architecture changes.

## Evidence Rule
Record commands, exit codes, HTTP statuses, and sanitized result summaries. Never include the credential or cookie values in task files, logs, or the final response.
