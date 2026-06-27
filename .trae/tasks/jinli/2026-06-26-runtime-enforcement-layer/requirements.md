# Requirements: Jinli Runtime Enforcement Layer

## Desired Outcome

Ba Ba needs Jinli to become a reliable work assistant, not a casual chat persona. The system must force different LLMs to follow the same intelligent, automated, evidence-based workflow instead of relying on model self-discipline.

The upgrade must make the existing Jinli systems actually participate in work:

- memory retrieval and write-back
- multi-agent coordination
- skill routing and on-demand loading
- task-packet and contract gates
- persona and response planning
- nervous event bus
- dream/reflection queue
- proactive follow-up queue
- self-learning/evolution candidates
- file routing and workflow route maintenance

## Intended User and Context

Primary user: Ba Ba, working inside `E:\UEGameDevelopment`.

Primary environments:

- Codex Desktop
- Trae
- OpenCode
- Hermes/Jinli local services
- future lower-capability worker models

The design must work even when the active LLM is forgetful, lazy, compressed by context, or weaker than the planning model.

## End-to-End Experience

For any non-trivial work request:

1. A lead agent receives the request.
2. A runtime orchestrator classifies the request into Lite, Standard, Strict, or Critical mode.
3. Required sub-agents or service adapters produce structured evidence.
4. Memory, skill routing, file routing, current workflow state, and risk context are retrieved before the final answer is drafted.
5. The answer draft is checked by a response gate.
6. Missing required evidence blocks output or forces a repair pass.
7. After the answer, the system writes event, memory candidate, proactive, dream, and evolution signals when applicable.
8. The run produces a machine-readable turn manifest that later models can inspect.

For project/file work:

1. The model can discover where files belong through an automatically maintained route index.
2. The model can discover which workflow applies through an automatically maintained process index.
3. The model cannot edit or claim completion without task-packet, contract, worker, and verification evidence.

## Confirmed Decisions

- Mature, production-grade path is required. MVP and prompt-only approaches are rejected.
- Enforcement must be outside the LLM, not only in natural-language instructions.
- Multi-agent coordination is mandatory for Standard, Strict, and Critical modes.
- The lead agent cannot verify its own answer.
- Worker agents cannot mutate task packets, acceptance criteria, review, verify, repair, or archive state.
- Missing required evidence must fail loud.
- The system must degrade predictably when a connector, MCP tool, or sub-agent runtime is unavailable.
- File routing and workflow routing must be maintained as system artifacts, not tribal knowledge inside one model's context.

## Implicit Requirements

- The orchestrator must produce compact evidence so weaker models can consume it.
- The runtime must distinguish "service exists" from "service was actually used this turn".
- The system needs stable JSON/YAML contracts that can be validated by scripts.
- The system must support both project tasks and high-quality advisory answers.
- Enforcement must include response quality checks, not only edit permissions.
- File route maintenance must detect stale or missing route entries.
- The design must avoid giving persona/emotion modules authority over factual or workflow gates.

## Boundaries and Non-Goals

- This task does not replace the existing `.trae/scripts` task-packet authority.
- This task does not remove existing Soul Core behavior.
- This task does not make proactive messages send to external chat platforms by default.
- This task does not allow workers to approve, verify, or archive their own work.
- This task does not require every casual sentence to spawn many agents.
- This task does not rely on one specific frontier model to remember hidden instructions.

## Success Experience

Ba Ba should be able to attach a weaker model or a new tool session and still see the same workflow:

- it reads route indexes instead of guessing file placement;
- it runs the required memory/skill/context checks;
- it asks for or receives bounded worker reports;
- it refuses to claim completion without verification;
- it records after-turn learning signals;
- it gives answers grounded in the current system state.

## Open Questions

None.

## Teach-Back Summary

Ba Ba is asking for a real runtime upgrade: make Jinli's existing services and multi-agent workflow unavoidable in meaningful work, with stable automation and machine-checkable evidence so different models follow the same process.

## User Confirmation Evidence

Current user objective:

> "我对你的需求只有三个，这个系统要高度智能化，这个系统要高度自动化，这个系统要有足够的稳定性可以在不同模型上都走相同的流程，还有，对于项目内的文件，要让其他模型接入后就能知道文件放在哪里了，就是当前系统的文件路由以及当前系统的流程，这些也要自动维护"
