# Tasks: Jinli Knowledge Graph Runtime Implementation

## Dependency Graph

```text
WP01 contracts/config
  -> WP02 worker gateway
  -> WP03 video sources
  -> WP04 segments/enrichment/search
  -> WP05 graph/dedup/Obsidian
  -> WP06 obra index/MCP
  -> WP07 visual candidates
  -> WP08 Soul Core bridge
  -> WP09 setup/docs/E2E
  -> Codex Review and Verify
```

## WP01 Runtime Foundation
- [ ] T1.1: Lead reviews `reports/ds4-WP01-result.md` and independently reruns WP01 verification.
- [ ] T1.2: Confirm AC01 and AC02 evidence before releasing WP02.

## WP02 Local Worker Gateway
- [ ] T2.1: Lead reviews `reports/ds4-WP02-result.md` and independently reruns WP02 verification.
- [ ] T2.2: Confirm AC03 and AC06 gateway failure behavior before releasing WP03.

## WP03 Video Sources
- [ ] T3.1: Lead reviews `reports/ds4-WP03-result.md` and independently reruns WP03 verification.
- [ ] T3.2: Confirm AC04 and AC05 without live-network dependence before releasing WP04.

## WP04 Segmentation And Enrichment
- [ ] T4.1: Lead reviews `reports/ds4-WP04-result.md` and independently reruns WP04 verification.
- [ ] T4.2: Confirm timestamp preservation and raw-search fallback before releasing WP05.

## WP05 Graph And Obsidian Export
- [ ] T5.1: Lead reviews `reports/ds4-WP05-result.md` and independently reruns WP05 verification.
- [ ] T5.2: Confirm AC07, AC08, and AC09 before releasing WP06.

## WP06 Index And MCP Bridge
- [ ] T6.1: Lead reviews `reports/ds4-WP06-result.md` and independently reruns WP06 verification.
- [ ] T6.2: Confirm AC10 against a fixture vault before releasing WP07.

## WP07 Visual Candidate Extension
- [ ] T7.1: Lead reviews `reports/ds4-WP07-result.md` and independently reruns WP07 verification.
- [ ] T7.2: Confirm AC11 candidate-only authority boundary before releasing WP08.

## WP08 Soul Core Integration
- [ ] T8.1: Lead reviews `reports/ds4-WP08-result.md` and independently reruns WP08 verification.
- [ ] T8.2: Confirm AC12 and AC13 compatibility before releasing WP09.

## WP09 Operations And End-To-End
- [ ] T9.1: Lead reviews `reports/ds4-WP09-result.md`.
- [ ] T9.2: Run the complete offline suite and record raw output.
- [ ] T9.3: Set or confirm `JINLI_KG_TEST_VIDEO_URL`, run live ingestion, and retain generated evidence paths.
- [ ] T9.4: Verify Obsidian Graph View manually shows generated source/concept links and record screenshot/evidence.
- [ ] T9.5: Run documentation governance and update `Project/Jinli/Docs/DOCS_TREE.md`.

## Final Verification
- [ ] Verify selected mature path was implemented and no rejected shortcut was introduced.
- [ ] Run automated verification and record command output in `verification-report.md`.
- [ ] Map implementation result to Acceptance Criteria in `verification-report.md`.
- [ ] Confirm every worker report declares `Status: done` and `Extra scope taken: no`.
- [ ] Confirm Codex independently reran worker commands and did not accept worker success claims without verification.
