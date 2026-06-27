# Requirement Understanding: Conversational Requirements Gate

## Desired Outcome

When Ba Ba describes a new system or meaningful feature in ordinary language, Jinli must understand it through a patient multi-turn conversation before designing or implementing it. Ba Ba should not need coding knowledge or prompt-engineering knowledge.

## Underlying Problem

Previous AI drama frontend work produced an unsatisfactory result because early discussion did not expose ambiguity, misunderstandings, or implicit needs. Existing workflow fields can say clarification is complete without proving shared understanding.

## Intended User and Context

- Primary decision maker: Ba Ba, who understands the desired outcome but may not know technical terminology.
- Primary planner: Jinli / 金璃小天才.
- Downstream executors: Codex, Hermes, OpenCode, Trae, Flash workers, or other models receiving a task packet.

## End-to-End Experience

1. Ba Ba describes an idea naturally.
2. Jinli classifies the change as deep discovery or fast track.
3. For deep discovery, Jinli asks one plain-language question per turn, offers concrete choices, recommends one, and allows free-form correction.
4. Jinli restates what was understood and surfaces likely implicit needs.
5. Ba Ba confirms the plain-language requirement picture.
6. Jinli independently writes the technical design, execution prompt, task packet, acceptance criteria, and verification plan.
7. Ba Ba sees a short plain-language plan summary and confirms implementation.
8. Executors work from the packet, not from a guessed interpretation of the original request.

## Confirmed Decisions

- New systems, meaningful features, workflow/UI redesigns, and ambiguous changes use deep discovery.
- Clearly bounded bugs and small changes may use fast track.
- Uncertain classification defaults to deep discovery.
- Deep discovery has no fixed number of rounds.
- One question is asked per turn.
- Questions use plain language, two or three choices, a recommendation with reasons, and a free-form option.
- Jinli owns technical translation and prompt/task-packet writing.
- Ba Ba confirms a short plain-language summary before implementation.

## Implicit Requirements

| Requirement | Status | Reason |
|---|---|---|
| The workflow must distinguish task size and ambiguity | Confirmed | Small fixes should remain efficient |
| Clarification must be iterative, not a one-shot questionnaire | Confirmed | Mirrors the successful persona-core design conversation |
| The agent must show inferred needs for correction | Confirmed | Missing implicit needs caused prior dissatisfaction |
| “Answered” must not be enough evidence by itself | Confirmed | Existing state can be set without shared understanding |
| Other models must receive an execution-ready prompt | Confirmed | Prevents them from starting from the raw user sentence |
| Requirements and prompt artifacts must be mechanically checked | Confirmed | Soft instructions alone are easy to skip |
| Technical choices should be researched and decided by the planner | Confirmed | Ba Ba should not be forced to speak in code terminology |

## Boundaries and Non-Goals

- Do not require deep discovery for typo fixes, exact isolated bugs, or tiny bounded changes.
- Do not ask Ba Ba questions answerable from repository evidence or official documentation.
- Do not treat silence as approval.
- Do not allow executors to change acceptance criteria or silently reduce scope.
- Do not replace mature-solution research, design review, testing, or verification.

## Success Experience

Ba Ba should feel that Jinli first understands the desired experience, explains choices plainly, notices missing considerations, and only then turns that understanding into professional technical work.

## Open Questions

None.

## Teach-Back Summary

For meaningful design work, Jinli will talk with Ba Ba one decision at a time until the intended experience and important hidden needs are clear. Jinli will then write the technical prompt and task packet herself. Small, precise repairs keep a fast path. If there is doubt about which path applies, Jinli slows down and asks.

## User Confirmation Evidence

- Decision 1: Ba Ba confirmed the deep-discovery versus fast-track split.
- Decision 2: Ba Ba confirmed no fixed interview round limit.
- Decision 3: Ba Ba confirmed one plain-language question per turn with choices, recommendation, and free-form response.
- Decision 4: Ba Ba confirmed Jinli authors the technical prompt and task packet after requirements are understood.
- Final delegation: “确认，剩下的我相信小璃，开始设计方案并发布任务包把小璃”.
