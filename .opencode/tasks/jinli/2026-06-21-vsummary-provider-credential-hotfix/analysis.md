# Analysis: vsummary Provider Credential Hotfix

## Architecture Context

### System boundaries
- The external vsummary application owns provider settings and video generation.
- Jinli owns the integration documentation and later automation workflow.
- This hotfix does not implement the Bilibili favorites automation or knowledge graph runtime.

### Dependency map
- Runtime configuration: `E:\Obsidian\tools\vsummary\.env`.
- Configuration loader: `src/backend/video_summary/infrastructure/settings.py`.
- Validation and persistence boundary: `src/backend/video_summary/infrastructure/settings_service.py`.
- Provider API: `/api/provider-settings` and `/api/provider-settings/test`.
- Original failure endpoint: `/api/videos/{series_id}/{video_id}/generate`.
- Existing cached test video: `__playground__/BV1UF7m68E1K`.

### Data and state ownership
- The provider credential remains in the ignored local `.env`.
- Tests must use synthetic credentials and never persist real secrets.
- vsummary summary artifacts remain in its workspace.
- No knowledge graph canonical state is written by this hotfix.

### Integration points
- Frontend provider settings submit values through the provider settings API.
- Backend settings validation must reject invalid secrets before the Gateway or httpx constructs an Authorization header.
- A backend restart may be required because generation services can cache the provider gateway.

## Root Cause Evidence
- The API reports the configured key as a 26-character non-ASCII Chinese explanatory sentence.
- Direct Gateway scripts succeed because they hard-code a real ASCII NVIDIA credential.
- httpx encodes HTTP header values as ASCII and raises at the first Chinese character.
- `LITELLM_LOG=ERROR` and UTF-8 stdout wrapping did not alter the failure.

## Mature Solution Evidence

### Project-local evidence
- `settings_service.py` is the established provider validation and persistence boundary.
- Existing provider settings tests exercise validation and `.env` persistence.
- The original endpoint provides a bounded live regression check using cached transcription.

### Official/framework evidence
- HTTP header values passed by httpx are encoded as ASCII unless explicitly supplied as bytes.
- Provider API keys are opaque ASCII credentials and should be validated before header construction.

### External mature references
- FastAPI/Pydantic-style boundary validation is preferred over catching a low-level encoding exception after request construction.

### Options compared
| Option | Pros | Cons | Decision |
|---|---|---|---|
| Only restore `.env` | Fast | Recurrence remains possible | Rejected |
| Catch `UnicodeEncodeError` in Gateway | Masks the invalid credential | Misdiagnoses configuration as transport failure | Rejected |
| Restore credential and validate at settings boundary | Fixes current state and prevents recurrence | Requires focused tests | Selected |
| Replace LiteLLM globally with httpx | Avoids one library layer | Broad behavior change and loses structured request compatibility | Rejected |

### Rejected shortcuts
- Do not treat this as a stdout or log encoding repair.
- Do not accept masked or explanatory UI text as a secret.
- Do not print the restored credential in command output or reports.
- Do not broaden the hotfix into the full ingestion workflow.

### Selected mature path
- Write failing unit tests for invalid credential forms.
- Add one validation helper at the provider settings boundary and reuse it for save/test paths.
- Restore the locally available valid credential through the settings API without echoing it.
- Restart the backend if needed and verify both provider connection and the original generate endpoint.

## Acceptance Criteria
- AC01: Non-ASCII provider credentials are rejected with an explicit configuration error.
- AC02: Masked and explanatory placeholder credentials are rejected.
- AC03: Valid ASCII provider credentials remain accepted.
- AC04: Provider connection succeeds with the restored local credential.
- AC05: `POST /api/videos/__playground__/BV1UF7m68E1K/generate` no longer fails with `UnicodeEncodeError`.
- AC06: No real API credential is present in modified test code or verification reports.
- AC07: Jinli operations documentation records the diagnosis and safe recovery rule.

## Automated Verification Plan
- Command: `E:\Obsidian\tools\vsummary\.venv\Scripts\python.exe -m pytest E:\Obsidian\tools\vsummary\tests\backend\unit\settings\test_workspace_settings_service.py -q`
- Expected: all provider settings unit tests pass.
- Command: call `POST http://127.0.0.1:8001/api/provider-settings/test` without printing the credential.
- Expected: HTTP 200 and success response.
- Command: call the original generate endpoint and poll its status.
- Expected: completed generation or a non-encoding upstream error; no ASCII credential exception.

## Residual Constraints
- Remote credential rotation cannot be performed without the provider account control plane.
- Existing untracked diagnostic scripts contain a credential and must be sanitized, but they will not be deleted without explicit permission.
