# Spec: AIDramaProducer Verification Truth Closure

## GIVEN
The Python Skill packages and targeted tests mostly run, but the role-ID contract, root test entrypoint, Viral-to-Scriptwriter consumption chain, and task-packet status are inconsistent.

## WHEN
The closure work packages are implemented with test-first changes and the task documents are reconciled to actual evidence.

## THEN
The local integration defects are fixed without claiming that unfinished real-provider or media-quality work is complete.

## Scenarios

### S01 Known character mappings return IDs
**Status**: [x]
- Given `known_ids=["char_01","char_02"]` and matching `char_map`
- When text mentions both mapped names
- Then `_detect_characters` returns `["char_01","char_02"]`
- And every value is a member of `known_ids`

### S02 Regex fallback remains usable
**Status**: [x]
- Given no known IDs or mapping
- When text contains dialogue or character-introduction patterns
- Then `_detect_characters` returns detected display names as legacy fallback values

### S03 Root pytest is deterministic
**Status**: [x]
- Given runtime input artifacts such as `test_real_run.txt`
- When `python -m pytest -q` runs from the skills root
- Then only Python test modules under the nine package test directories are collected
- And the command exits 0

### S04 Viral injection is consumed
**Status**: [x]
- Given a Viral Analyzer `style_injection.json` with sibling archetype, pacing, and voice files
- When Scriptwriter Quick Mode runs with `--style-injection`
- Then the bundle is validated and propagated into Step 1, Step 2, and Step 3 prompt context
- And invalid JSON or an invalid source fails with a clear error

### S05 Orchestrator forwards injection
**Status**: [x]
- Given `ai_drama_orchestrator --style-injection <path>`
- When Phase 2 invokes Scriptwriter
- Then the same path reaches Scriptwriter Quick Mode

### S06 Task packets report facts
**Status**: [x]
- Given the three original packets still contain unfinished product tasks
- When progress documentation is updated
- Then they remain `implement/fail/fail/false`
- And the repair packet no longer says approval can override gates
- And all verification outputs distinguish targeted tests from production capability.

## Acceptance Criteria

| AC# | Description | Verification Command | Expected Output |
|---|---|---|---|
| AC01 | Stable role IDs | focused preprocessor pytest | mapped names return known IDs |
| AC02 | Clean root test entry | `python -m pytest -q` | exit 0 |
| AC03 | Injection bundle consumption | focused Scriptwriter pytest | bundle values appear in step prompts |
| AC04 | CLI and Orchestrator pass-through | focused CLI/orchestrator pytest | same injection path propagated |
| AC05 | Factual task state | document scan plus four task guards | no approval override; original gates remain honestly blocked |
| AC06 | Complete evidence | new packet verification report | commands and residual risks recorded |

## Progress Summary

| Phase | Status | Key Decision |
|---|---|---|
| Plan | Complete | Facts and gates remain authoritative |
| Implement | Complete | Test-first fixes and factual documentation complete |
| Review | In progress | Fresh verifier found no P0/P1/P2 code findings; final gate rerun pending |
| Verify | Pending | Signed evidence, no auto-archive |

## Non-Goals
- Implementing paid or credentialed AI provider backends.
- Claiming SSIM, lip-sync, duration-error, or production MP4 quality.
- Closing original task packets while their accepted tasks remain open.
- Replacing the existing seven-phase architecture.
