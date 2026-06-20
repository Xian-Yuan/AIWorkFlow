# WP04: Independent Verification and Signed Closure

Owner model: fresh-context verifier
Difficulty: hard
Status: done

## Task Packet
- Root: `.trae/tasks/ai-drama/2026-06-20-verification-truth-closure`
- Parent task: `2026-06-20-verification-truth-closure`

## Allowed Paths
- Read-only workspace inspection
- New task verification evidence and approval artifacts through issuer commands

## Forbidden Paths
- Production-code edits
- Test weakening
- Original packet archival

## Read First
- `routing.md`
- `analysis.md`
- `spec.md`
- `tasks.md`
- `verification-report.md`

## Goal
Independently reproduce the closure evidence and reject any unsupported claim.

## Steps
- Run all AC commands from a fresh context.
- Inspect source boundaries and task truth.
- Return findings before approval.
- Sign Review/Verify only if all new-packet ACs pass.

## Done Definition
- Independent evidence agrees with the implementation report.
- New packet Verify passes.
- Archive remains a separate explicit issuer action.

## Required Verification
- Command: full command set in `analysis.md#Automated-Verification-Plan`
- Expected: every new-packet AC passes; original packets remain honestly open.

## Return Report
- Path: `reports/fresh-verifier-WP04-result.md`
- Fresh verifier returns evidence to the issuer; it does not edit packet state.
