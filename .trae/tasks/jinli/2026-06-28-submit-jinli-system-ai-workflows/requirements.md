# Requirement Understanding: Submit Jinli System And AI Workflows

## Desired Outcome

Prepare a task packet that lets another model safely commit the complete Jinli system and the current AI-related workflow state.

## Underlying Problem

The workspace has many modified and untracked files across root workflow docs, skills, task packets, OpenCode mirrors, and the ignored `Project/Jinli` project. A direct `git add -A && git commit` would either miss Jinli entirely or include too much unrelated/runtime content.

## Intended User and Context

Ba Ba will give this task packet to another model. That worker needs exact commit boundaries, safety checks, staging commands, secret scans, and stop conditions.

## End-to-End Experience

1. Worker reads this task packet and the work packages.
2. Worker creates one root repository commit for shared AI workflow state.
3. Worker creates or uses an independent `Project/Jinli` repository and commits the Jinli system baseline there.
4. Worker records commit hashes, staged scope, exclusions, and verification output in a report.

## Confirmed Decisions

- Do not force-add `Project/Jinli` into the root repository.
- Treat root AI workflow and `Project/Jinli` as separate commit streams.
- Exclude secrets, runtime state, generated outputs, node modules, caches, and temporary test folders.
- Other model performs the actual staging and commits.

## Implicit Requirements

| Requirement inferred by the planner | Status | Reason |
|---|---|---|
| Root commit must not include `Project/` | Confirmed | Root `.gitignore` says projects own independent repositories. |
| Jinli must exclude `.env` and runtime data | Confirmed | Secrets and personal state must not be committed. |
| Worker must write a final report | Confirmed | Ba Ba needs evidence of what was submitted. |
| Worker may initialize `Project/Jinli/.git` | Confirmed | Current check shows no `.git` exists there. |

## Boundaries and Non-Goals

- This task packet does not perform the commits.
- Do not push to a remote unless Ba Ba explicitly asks.
- Do not delete or revert existing user changes.
- Do not commit generated media, node modules, caches, temp folders, `.env`, runtime state, or output logs.

## Success Experience

Ba Ba can hand the packet to another model and get two clean commits: one for shared AI workflow state and one for the Jinli system baseline, with a report proving what was included and what was excluded.

## Open Questions

None.

## Teach-Back Summary

The safe submission design is a two-repository workflow. The root repository captures AI workflow docs, skills, scripts, task packets, and IDE adapters. The ignored `Project/Jinli` tree becomes its own repository and commits source/docs/config templates/tests while excluding secrets and runtime artifacts.

## User Confirmation Evidence

- Ba Ba said: "我的构想是jinli整个系统和当前的ai涉及到的工作流都要提交"
- Ba Ba then said: "你来设计任务包，我让其他模型提交小璃"

