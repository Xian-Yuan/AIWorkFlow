# Spec: vsummary Provider Credential Hotfix

## GIVEN
vsummary is running on Windows and its local `.env` contains a Chinese explanatory sentence in `OPENAI_API_KEY`.

## WHEN
provider settings are validated, restored, and video generation is retried.

## THEN
the invalid value is rejected before HTTP request construction and a valid local credential allows generation to proceed.

### S1 Invalid Non-ASCII Credential
**Status**: [x]

GIVEN a non-Ollama provider and a credential containing non-ASCII text  
WHEN provider settings are tested or saved  
THEN the backend rejects the credential with an actionable API Key configuration error.

### S2 Placeholder Credential
**Status**: [x]

GIVEN a masked or explanatory placeholder value  
WHEN provider settings are tested or saved  
THEN the backend rejects it and does not persist it.

### S3 Valid Credential
**Status**: [x]

GIVEN a valid ASCII credential  
WHEN provider settings are tested or saved  
THEN existing provider behavior remains compatible.

### S4 Original API Regression
**Status**: [x]

GIVEN the cached transcript for `BV1UF7m68E1K` and restored provider settings  
WHEN the generate endpoint runs  
THEN it does not fail with `UnicodeEncodeError`.

## Acceptance Criteria
| AC# | Description | Verification Command | Expected Output |
|---|---|---|---|
| AC01 | Reject non-ASCII credentials | Focused pytest | Pass |
| AC02 | Reject placeholder credentials | Focused pytest | Pass |
| AC03 | Preserve valid ASCII credentials | Focused pytest | Pass |
| AC04 | Restored credential reaches the provider path | Provider test API plus original generate path | No encoding failure; generate path completes |
| AC05 | Original generate path works | Generate API plus status poll | No encoding failure |
| AC06 | Secrets are not added to tests or reports | Secret scan | No new matches |
| AC07 | Operations guidance is synchronized | doc-guard | Pass |

## Quality Checklist
- [x] [OK] Current failure and desired outcome are explicit.
- [x] [OK] Happy path, invalid input, and regression path are covered.
- [x] [OK] The fix stays at the configuration boundary.
- [x] [OK] Real credentials are excluded from tests and reports.

## Progress Summary
| Phase | Status | Key Decision |
|---|---|---|
| Plan | Complete | Validate credential at settings boundary |
| Implement | Complete | TDD, local credential recovery, and live summary generation |
| Review | Pending | Independent diff and secret review |
| Verify | Pending | Unit and original API evidence |

## Non-Goals
- Implement Bilibili favorites automation.
- Implement Obsidian export or graph indexing.
- Rotate the provider credential in NVIDIA account settings.
- Delete user-created diagnostic files.
