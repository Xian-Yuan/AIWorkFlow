# Spec: Bilibili Favorites Knowledge Automation

### S1 Favorite Snapshot
**Status**: [ ]

GIVEN the authenticated Bilibili session and folder id `3972516389`  
WHEN discovery runs  
THEN all pages are recorded with BVID, title, duration, and source revision without changing the folder.

### S2 Duration Boundary
**Status**: [ ]

GIVEN videos of 1,799, 1,800, and 1,801 seconds  
WHEN eligibility runs  
THEN only the 1,799-second video is eligible.

### S3 Non-SSD Storage
**Status**: [ ]

GIVEN an eligible item without local media  
WHEN download starts  
THEN the destination is below the configured root and the root is verified as non-SSD with sufficient free space.

### S4 Legacy Reconciliation
**Status**: [ ]

GIVEN an existing Hermes/vsummary media file with unambiguous BVID evidence  
WHEN reconciliation runs  
THEN the ledger adopts or safely moves it without redownloading.

### S5 Required Metadata
**Status**: [ ]

GIVEN a summarizable video  
WHEN export succeeds  
THEN the note contains title, BVID, canonical URL, uploader, duration, summary, category, and provenance.

### S6 Optional Evidence
**Status**: [ ]

GIVEN a missing description or pinned comment  
WHEN the item is processed  
THEN export succeeds and records the evidence as unavailable rather than failing.

### S7 Important Links
**Status**: [ ]

GIVEN repository, paper, model, or documentation URLs in source evidence  
WHEN the note is built  
THEN normalized deduplicated links appear in a dedicated section.

### S8 Classification
**Status**: [ ]

GIVEN a valid summary  
WHEN classification runs  
THEN the note receives one allowed primary category, tags, confidence, and evidence; low confidence falls back to `Other`.

### S9 Idempotent Skip
**Status**: [ ]

GIVEN a completed BVID and unchanged content revision that remains in the folder  
WHEN a later run snapshots it  
THEN it is reported as skipped and no media or model work runs.

### S10 Safe Cleanup
**Status**: [ ]

GIVEN successful vsummary output but no committed note  
WHEN cleanup is evaluated  
THEN no media is deleted; deletion becomes eligible only after atomic export and ledger commit.

### S11 Graph Degradation
**Status**: [ ]

GIVEN the graph indexer is unavailable  
WHEN Markdown export succeeds  
THEN the item is durable, a graph queue record is written, and media cleanup may continue.

### S12 Secret Hygiene
**Status**: [ ]

GIVEN runtime failures  
WHEN logs and reports are produced  
THEN cookies, authorization headers, and model provider keys are redacted.

## Acceptance Criteria

| AC# | Scenario | Required Evidence |
|---|---|---|
| AC01 | S1 | recorded fixture and live dry-run counts |
| AC02 | S2 | boundary unit test |
| AC03 | S3 | physical-disk and path-containment test |
| AC04 | S4 | reconciliation test with no download call |
| AC05 | S5-S8 | schema and Markdown snapshot tests |
| AC06 | S9 | second-run canary with skip evidence |
| AC07 | S10 | failure-injection cleanup tests |
| AC08 | S11 | graph-offline integration test |
| AC09 | S12 | secret scan |
| AC10 | S1-S12 | end-to-end canary and verification report |

## Quality Checklist

- [x] Eligibility is decided before download.
- [x] Completion and cleanup are separate transactional states.
- [x] Optional platform evidence cannot block core processing.
- [x] Existing downloads and unchanged completed favorites have explicit behavior.
- [x] Manual and scheduled operation use one pipeline.
- [x] Secrets and unmanaged files are protected.

## Non-Goals

- Removing favorites from Bilibili.
- Summarizing videos of 30 minutes or longer.
- Building a new graph database or graph UI.
- Mandatory visual frame analysis.
- Credential or cookie management.

