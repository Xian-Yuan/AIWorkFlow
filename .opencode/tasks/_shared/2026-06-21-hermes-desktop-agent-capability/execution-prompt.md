# Task Execution Prompt: Hermes Desktop Agent Capability

## Role

Act as the lead integration engineer. Install, configure, and verify three MCP Servers that give Hermes Agent Windows desktop control capabilities.

## Goal

Integrate agent-desktop, DesktopCommanderMCP, and unreal-mcp into the Hermes jinli-implementer Profile, write a windows-desktop-control Skill with safety policies, and verify end-to-end desktop manipulation works.

## Task Packet Truth Sources

Read in order:

1. `.trae/tasks/_shared/2026-06-21-hermes-desktop-agent-capability/requirements.md`
2. `.trae/tasks/_shared/2026-06-21-hermes-desktop-agent-capability/analysis.md`
3. `.trae/tasks/_shared/2026-06-21-hermes-desktop-agent-capability/spec.md`
4. `.trae/tasks/_shared/2026-06-21-hermes-desktop-agent-capability/tasks.md`
5. `Docs/AI/research/2026-06-21-Hermes-Desktop-Agent-Capability-Research.md`

## Confirmed Decisions

- Integration-first: use existing mature projects, don't build from scratch
- Three-layer hybrid: pywinauto(UIA) → OCR+Screenshot → Vision LLM (priority descending)
- Only build glue layer + Skill + safety policy, no Hermes core code changes
- Phase 1: get agent-desktop + DesktopCommanderMCP + unreal-mcp running
- Safety: dangerous operations require confirmation, operation logging, window allowlist

## Accepted Architecture

- agent-desktop MCP: accessibility-tree-based desktop control (Rust, 870★)
- DesktopCommanderMCP: terminal + file system control (TypeScript, 6188★)
- unreal-mcp: UE5 Editor control (C++, 2000★)
- windows-desktop-control Skill: operation decision logic + safety policy
- All integrated via Hermes MCP configuration in Profile mcp.json

## Allowed Paths

- `E:/UEGameDevelopment/.tools/hermes-worker/profiles/jinli-implementer/mcp.json`
- `E:/UEGameDevelopment/.tools/hermes-worker/profiles/jinli-implementer/config.yaml`
- `E:/UEGameDevelopment/.tools/hermes-worker/profiles/jinli-implementer/skills/`
- `E:/UEGameDevelopment/skills/`
- `E:/UEGameDevelopment/.trae/tasks/_shared/2026-06-21-hermes-desktop-agent-capability/`
- `E:/UEGameDevelopment/Docs/AI/`
- `E:/UEGameDevelopment/AGENTS.md`
- `E:/UEGameDevelopment/Project/RTS/Plugins/` (for unreal-mcp plugin only)

## Forbidden Paths

- `E:/UEGameDevelopment/.tools/hermes-worker/hermes-agent/` (Hermes core code)
- `E:/UEGameDevelopment/Project/RTS/Source/` (game code)
- Other active task packets
- Git history or remote publication

## Non-Goals

- Do not modify Hermes Agent core Python code
- Do not build a new GUI framework or OCR engine
- Do not configure Gateway/Telegram in this task
- Do not handle Linux/macOS desktop control
- Do not implement record/replay automation

## Acceptance Criteria

- AC01: agent-desktop MCP installed and configured, tools callable
- AC02: DesktopCommanderMCP installed and configured, tools callable
- AC03: unreal-mcp installed to UE5 project, Hermes can call via MCP
- AC04: windows-desktop-control Skill written with operation logic and safety policy
- AC05: All three MCP Server connection tests pass
- AC06: Safety policy document complete with window allowlist and dangerous operation rules
- AC07: Integration verification: at least one end-to-end scenario passes
- AC08: Documentation updated: AGENTS.md / Docs/AI/ reflect new capabilities

## Verification Commands

- `hermes mcp list` — Expected: agent-desktop, desktop-commander, unreal-mcp listed
- `hermes mcp test agent-desktop` — Expected: connection successful
- `hermes mcp test desktop-commander` — Expected: connection successful
- `hermes tools list` — Expected: desktop_* tools visible
- `hermes skills list | grep windows-desktop` — Expected: skill found

## Stop Conditions

Stop and report if:

- npm/cargo installation fails and cannot be resolved
- MCP Server cannot connect after configuration
- unreal-mcp UE Plugin causes UE5 project to fail loading
- Existing Hermes functionality breaks after changes
- Security policy cannot be enforced

## Evidence Rule

Do not claim a tool is installed, a MCP is connected, or a test passed without a current-session command result.
