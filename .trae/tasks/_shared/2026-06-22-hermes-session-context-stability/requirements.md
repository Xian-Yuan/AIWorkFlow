# Requirement Understanding: Hermes Session Context Stability

## Desired Outcome

HermesAgent should keep conversation history stable and trustworthy. Recent user content must not suddenly disappear, similar duplicate sessions should not confuse the session picker, automatic compression should preserve continuity instead of violently truncating context, and configured profile metadata should show the intended model and context window.

## Underlying Problem

Ba Ba observed that Hermes conversations sometimes lose latest content, show an extra similar history, stop automatically, display a configured model name that is not `glm-5.1`, and report an incorrect context limit. Existing evidence shows this is a combined runtime/profile problem, not only a weak summarization model.

## Intended User and Context

- Primary user: Ba Ba using Hermes Desktop Agent profiles in `E:/UEGameDevelopment`.
- Affected profiles: `jinli-planner` and `jinli-implementer`.
- Affected systems: Hermes profile source overlays, runtime profile sync, session listing/search, context compression, and diagnostics.
- Constraints: Do not modify secrets or real `.env` values. Do not delete sessions with real messages. Preserve unrelated dirty worktree changes.

## End-to-End Experience

1. Ba Ba starts Hermes with a Jinli profile.
2. The active profile reports the intended main model name and an explicit context length.
3. When history grows large, compression triggers later, protects recent turns, and fails closed if summarization cannot be generated.
4. The session list hides true empty ghost sessions by default and presents compression lineages as one logical conversation tip instead of many near-duplicates.
5. Diagnostics can explain existing risky sessions without destructive cleanup.
6. Verification records focused tests and config sync evidence before the task is called fixed.

## Confirmed Decisions

- Fix conversation history, context limit, and violent truncation first.
- Treat Zhipu/free compression as a possible contributor but not the sole root cause.
- Analyze Hermes workflow, agent, skill, MCP, and other integration points for related issues.
- Use repository-owned profile overlays as the durable source; sync them into `.tools/hermes-worker`.
- Do not edit or reveal secrets.
- Do not delete session rows unless a future explicit cleanup is requested and both metadata and actual message count are zero.

## Implicit Requirements

| Requirement inferred by the planner | Status | Reason |
|---|---|---|
| Profile model and context length must be explicit, not inferred from fragile provider probing | Confirmed | Logs show context detection fallback and model-name drift |
| Compression must fail closed instead of falling back to destructive truncation | Confirmed | Latest content disappearance is worse than asking the user to retry |
| Session UI/API should treat compression children as one logical chat | Confirmed | Multi-child compression lineages produce duplicate-looking histories |
| True ghost sessions should not pollute default history | Confirmed | Empty children confuse the user and add no recoverable content |
| Diagnostics must distinguish risky lineages from safe cleanup candidates | Confirmed | Some rows with `message_count=0` still have real messages |
| Verification must cover config source, runtime sync, and Hermes code behavior | Confirmed | This bug spans config, DB state, and API/UI behavior |

## Boundaries and Non-Goals

- Do not redesign Hermes architecture wholesale.
- Do not change project game/Web application code.
- Do not rotate, edit, print, or create real API keys.
- Do not destructively delete or rewrite existing session history in this task.
- Do not depend on a free compression model being perfect; add protective behavior around it.
- Do not bypass task packet gates.

## Success Experience

Ba Ba should be able to open Hermes and feel that the chat history is boringly stable: latest content remains visible, history entries make sense, model/context info matches the intended profile, and compression behaves conservatively instead of eating the conversation.

## Open Questions

None.

## Teach-Back Summary

This repair will stabilize Hermes history by addressing the root causes together: durable profile config, explicit model/context metadata, safer compression defaults, fail-closed summarization, session-list deduping/hiding of ghost rows, and non-destructive diagnostics. It will not touch secrets or delete real history.

## User Confirmation Evidence

- Ba Ba requested: "开始修复小璃".
- Ba Ba specified the priority: "当前先修复对话历史和上下文以及上下文压缩暴力截断的问题".
- Ba Ba requested broader analysis: "整体分析hermes工作流，agent，skill，或者mcp和其他地方是否有问题".
