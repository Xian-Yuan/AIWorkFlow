# Analysis: Bilibili Favorites Knowledge Automation

## Architecture Context

vsummary already provides local media probing, transcription, and structured summarization. The separate Jinli knowledge-runtime task owns canonical records, Markdown graph export, and later graph indexing. This task supplies the missing orchestration layer between a persistent Bilibili favorite folder and those two systems.

Current evidence from the local snapshot:

- 88 favorites were discovered.
- 84 are shorter than 30 minutes.
- 79 eligible primary media files already exist locally.
- only 68 entries are represented in the old progress file.
- 5 eligible videos are missing.
- 4 ineligible videos of 30 minutes or longer were downloaded.
- about 2.57 GB of media currently resides on the E: NVMe SSD.
- D:, F:, and G: map to one mechanical disk; G: has the most free space and is the selected configurable default.

## System boundaries

- Bilibili source adapter: read folder pages, metadata, duration, description, and optional pinned comment with the existing authenticated session.
- Eligibility engine: decide before download using `duration_seconds < 1800`.
- Reconciler: inspect managed and legacy downloads, hash or fingerprint candidates, and adopt only unambiguous files.
- Ledger: own per-BVID/revision stage state, attempts, paths, errors, and cleanup status.
- Media adapter: download into the managed HDD root and prevent path escape.
- vsummary adapter: submit local media, wait with bounded retries, and validate structured output.
- Knowledge exporter: merge metadata, important URLs, transcript evidence, classification, and summary into atomic Markdown and canonical records.
- Cleanup worker: delete only ledger-owned disposable files after export commit.
- Scheduler adapter: invoke the same manual runner; it owns no business logic.

The pipeline does not own Bilibili account management, vsummary internals, the knowledge graph UI, or user notes outside the managed vault root.

## Dependency map

```text
Bilibili session
  -> favorite snapshot
  -> duration eligibility
  -> legacy reconciliation or HDD download
  -> vsummary transcription and summary
  -> metadata and URL enrichment
  -> atomic Markdown plus canonical record
  -> graph queue or index
  -> cleanup commit
  -> permanent skip evidence
```

Required implementation dependency:

```text
knowledge runtime foundation
  -> this task WP01-WP04
  -> integrated runner WP05
  -> optional scheduler
```

## Data and State Model

Use a SQLite ledger keyed by `(source, collection_id, bvid, content_revision)`. The revision is derived from stable source metadata such as CID, publish/update timestamp, duration, and title. A current successful revision is skipped. A changed revision is reprocessed without erasing historical evidence.

Stages:

```text
discovered -> eligible -> media_ready -> transcribed -> summarized
-> exported -> graph_queued_or_indexed -> media_deleted
```

Terminal side states:

```text
ineligible | failed_retryable | failed_terminal | cleanup_pending
```

An item is considered summarized only after the Markdown and canonical record are atomically written and the ledger transaction commits. Cleanup is independently retryable.

## Classification Contract

Each note receives one primary category and zero or more tags. Initial categories:

- AI-Agent
- Memory
- Skills-Harness
- Token-Context
- Code-Search-RAG
- Models-Papers
- Tools-Projects
- Knowledge-Graph
- Other

Classification must include confidence and evidence. Low-confidence results fall back to `Other`; they do not block export.

## Metadata and Link Preservation

Required note fields:

- title
- BVID
- canonical Bilibili URL
- uploader
- duration
- favorite collection id and name
- processing timestamp and content revision
- structured summary and key takeaways
- primary category and tags
- provenance paths or identifiers

Optional fields:

- description
- pinned comment
- transcript reference

HTTP and HTTPS URLs are extracted from description, pinned comment, transcript, and model output. They are normalized and deduplicated. GitHub, GitLab, Gitee, Hugging Face, model, paper, and documentation links are highlighted without inventing missing destinations.

## Safety and Recovery

- Resolve every cleanup path and prove it is below the configured managed media root.
- Never delete on summary failure, schema failure, note-write failure, or ledger-commit failure.
- Use atomic temporary-file replacement for notes and records.
- Store the final note digest before cleanup.
- Check physical disk type and free-space floor before a new download.
- Bound concurrency separately for download, transcription, and LLM calls.
- Redact cookies, authorization headers, and provider keys from logs.
- Dry-run lists actions without downloading, summarizing, writing notes, or deleting.

## Mature Solution Evidence

### Project-local evidence

- Existing vsummary code and live API prove local transcription and structured summary generation.
- Existing Bilibili helper scripts prove authenticated favorite discovery and download access, but also expose the missing duration, ledger, export, and cleanup boundaries.
- The knowledge-runtime task defines canonical schemas, Markdown export, graph queueing, and the Obsidian vault ownership boundary.
- The current 88-item snapshot and local media inventory provide concrete reconciliation fixtures.

### Official/framework evidence

- Bilibili source fields and pagination remain behind an adapter so platform changes do not leak into orchestration.
- vsummary's OpenAPI contract is the integration boundary; provider implementation details remain internal to vsummary.
- SQLite transactions and atomic filesystem replacement provide standard durable state and artifact semantics on Windows.
- Windows physical-disk inspection is required before selecting a raw-media destination.

### Options compared

| Option | Result | Reason |
|---|---|---|
| Extend the existing loose download scripts | Rejected | They lack transactional stages, safe cleanup, accepted-artifact contracts, and graph integration. |
| Put all behavior inside vsummary | Rejected | Favorite scheduling and Jinli knowledge ownership do not belong to the summarizer. |
| Build a second independent knowledge service | Rejected | It would duplicate the runtime task's schemas, vault, and graph queue. |
| Add a Jinli orchestration layer over source, vsummary, and knowledge adapters | Selected | It preserves ownership boundaries and supports restartable end-to-end operation. |

Selected mature path:

- transactional SQLite state instead of a single download-progress JSON;
- adapter boundaries for Bilibili and vsummary instead of embedding HTTP calls in the CLI;
- pre-download duration filtering instead of post-download cleanup;
- atomic accepted artifacts plus provenance instead of model text alone;
- post-commit deletion with a managed-root guard instead of deleting immediately after an API response;
- reconciliation of legacy media instead of restarting all work;
- one pipeline shared by manual and scheduled execution.

Rejected shortcuts:

- treating the favorite list itself as completion state;
- considering a downloaded file equivalent to a summarized item;
- parsing filename text as the only BVID identity;
- requiring comments or graph service availability;
- moving all existing files without reconciliation evidence;
- deleting media as soon as vsummary returns;
- hard-coding secrets or the drive letter inside business logic.

## Acceptance Criteria

- AC01: folder `ai相关` is snapshotted and paginated without mutation.
- AC02: only videos with duration below 1,800 seconds enter download or adoption.
- AC03: existing eligible media can be reconciled without duplicate download.
- AC04: new media is stored under a verified non-SSD managed root.
- AC05: title, BVID, URL, summary, classification, and provenance are always exported.
- AC06: description and pinned comment enrich output when available and never block when absent.
- AC07: important URLs are preserved and deduplicated.
- AC08: a completed current revision is skipped on later runs.
- AC09: raw media is deleted only after atomic export and ledger commit.
- AC10: failures are retryable and cleanup can resume independently.
- AC11: Markdown export works when graph indexing is unavailable and records a graph queue item.
- AC12: logs and reports contain no cookies, authorization headers, or provider keys.

## Automated Verification Plan

- Unit tests for duration boundaries, URL extraction, classification fallback, path containment, revision identity, and ledger transitions.
- Contract tests with recorded sanitized Bilibili payloads for pagination, description, and missing/present pinned comments.
- Adapter tests with a fake vsummary server for success, timeout, invalid schema, and retry.
- Reconciliation tests against synthetic legacy file layouts.
- Filesystem tests proving no deletion before commit and no deletion outside managed root.
- End-to-end dry-run against the live favorite folder with zero mutations.
- End-to-end canary on one eligible video, followed by a second run proving skip behavior.
- Secret scan and documentation guard.
