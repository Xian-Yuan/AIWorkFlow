# .codex/tasks/

This directory is a Windows junction to `.trae/tasks/`. Task packets are shared between Codex, OpenCode, and Trae.

## Task Packet Format

See `Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md` for the standard task packet contract.

## How It Works

- `.codex/tasks/<project>/<task-name>/` resolves to `.trae/tasks/<project>/<task-name>/`
- All files are shared — no duplication
- Codex loads `skills/codex-project-router/SKILL.md` before project work
