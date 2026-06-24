# Requirement Understanding: Bilibili Favorites Knowledge Automation

## Desired Outcome

Ba Ba can start one command or scheduled job that reads the Bilibili favorite folder `ai相关`, selects videos shorter than 30 minutes, downloads them to a mechanical disk, generates structured Chinese knowledge notes, queues them for the Jinli knowledge graph, deletes expendable media only after durable export, and skips completed favorites on every later run.

## Underlying Problem

vsummary can summarize a single video, but the current Bilibili scripts stop at discovery or download. They do not enforce the duration boundary, attach description and pinned-comment evidence, maintain an authoritative completion ledger, export classified knowledge, or safely reclaim media. Existing downloaded files and progress JSON also disagree, so blind reruns risk duplicate work and unsafe deletion.

## Intended User and Context

The workflow is for Ba Ba on the current Windows workstation. Bilibili authentication is already available locally. Raw media must stay off SSD storage. Summaries and metadata may be retained in the Obsidian/Jinli knowledge vault. The favorite folder remains unchanged after processing, so idempotent skipping is mandatory.

## End-to-End Experience

1. The runner snapshots favorite folder `ai相关` and records every BVID without downloading.
2. It filters on authoritative duration and marks videos of 1,800 seconds or longer as ineligible.
3. It reconciles already-downloaded Hermes/vsummary media into a SQLite ledger and moves or adopts eligible files under the configured HDD cache.
4. For each eligible unfinished video, it captures title, BVID, URL, uploader, duration, description when available, and pinned comment when available.
5. It calls vsummary, validates the structured result, extracts important URLs such as Git repositories, and writes an atomic Markdown note with category and provenance.
6. It records graph-ingestion work or indexes the note when the graph runtime is available.
7. Only after durable note export and ledger commit does it delete raw video, extracted audio, and disposable temporary files.
8. Later runs keep seeing the same favorites but skip completed BVID and content revision pairs.
9. Failures remain retryable and visible without corrupting completed state.

## Confirmed Decisions

- Source folder: Bilibili favorite folder `ai相关`, current folder id `3972516389`.
- Eligibility: duration strictly less than 30 minutes.
- Raw media: configurable HDD root, default `G:\JinliVideoCache` on this machine.
- Knowledge output: Markdown/Obsidian first; graph indexing may consume the same accepted records later.
- Required identity: title and BVID, plus canonical Bilibili URL.
- Optional evidence: description and pinned comment; absence must not fail the job.
- Important links from metadata, comments, or transcript must be preserved in the note.
- Completed favorites remain in the folder and must be skipped automatically.
- Raw media is deleted after successful durable export; transcript, metadata, summary, and ledger records are retained.
- Existing local downloads must be reconciled instead of blindly downloaded again.

## Implicit Requirements

| Requirement inferred by the planner | Status: Confirmed / Rejected / Deferred | Reason |
|---|---|---|
| SQLite is the authoritative workflow ledger | Confirmed | Multi-stage crash recovery and idempotency need transactions, not a loose progress JSON file. |
| Classification is independent from processing priority | Confirmed | A note can have one primary topic and multiple tags without confusing scheduling state. |
| Deletion is a post-commit cleanup phase | Confirmed | Prevents losing media before a valid note exists. |
| The HDD path is configurable and checked by physical disk type | Confirmed | Drive letters can move and D, F, and G currently map to the same HDD. |
| Pinned comment retrieval is best-effort | Confirmed | Platform access or missing comments must not block summarization. |
| Existing knowledge runtime contracts are reused | Confirmed | Avoids a second graph database, schema, or vault format. |
| DRM, paywall, CAPTCHA, and login bypass are prohibited | Confirmed | The workflow uses only the user's valid local session and public/authorized data. |
| Automatic scheduling ships after the manual runner is proven | Confirmed | A deterministic command is required before unattended execution. |

## Boundaries and Non-Goals

- Do not remove videos from the Bilibili favorite folder.
- Do not download videos with duration equal to or greater than 1,800 seconds.
- Do not build a new graph UI or replace the selected Obsidian knowledge-graph layer.
- Do not make description, comments, visual analysis, or cloud models mandatory.
- Do not delete user-authored notes, cookies, browser profiles, or unknown files.
- Do not expose Bilibili cookies or model credentials in logs and reports.
- Do not silently classify a failed or partial note as completed.

## Success Experience

The workflow feels like an inbox processor: Ba Ba can run it repeatedly without babysitting, see exactly what was eligible, skipped, completed, failed, or cleaned up, and trust that storage is reclaimed only after the useful knowledge is safely retained.

## Open Questions

None.

## Teach-Back Summary

Build a restartable Windows pipeline around vsummary and the Jinli knowledge runtime. It snapshots `ai相关`, filters before download, uses the mechanical disk for media, enriches each summary with Bilibili identity and optional evidence, writes classified Markdown with important links, records completion transactionally, deletes only disposable media after export, and treats prior successful BVID/revision records as permanent skip evidence even though the favorite remains present.

## User Confirmation Evidence

- User requirement: “把我b站收藏夹：ai相关 里长度小于30分钟的视频批量下载到本地，非固态硬盘，然后批量执行总结……总结后删除视频……对于收藏夹中已经总结的内容下次总结时可以直接跳过，我不会移除收藏夹中的内容。”
- User sequencing decision on 2026-06-21: “下一步应先修复并验证 Key，再补完整自动化任务包。”

