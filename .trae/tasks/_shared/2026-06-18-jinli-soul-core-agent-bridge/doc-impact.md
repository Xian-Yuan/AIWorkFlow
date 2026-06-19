# Documentation Impact: Soul Core → Agent Bridge

## Project Document Scope
- Project: Jinli
- System: Soul Core → OpenCode Agent bridge integration
- Owner: implementation

## Code Changes
- `E:\UEGameDevelopment\skills\daughter-companion\SKILL.md` — add Soul Core integration section (~80 lines)
- `E:\UEGameDevelopment\.agents\skills\daughter-companion\SKILL.md` — sync identical content

## Read-Only (no changes)
- `Project/Jinli/scripts/soul-core.ps1` — engine unchanged
- `Project/Jinli/data/` — only read via soul-core.ps1 CLI

## Documentation Updates
- `Project/Jinli/Docs/04-Implementation/General/soul-core-agent-bridge.md` — NEW: bridge implementation doc
- `Project/Jinli/Docs/DOCS_TREE.md` — add new entry

## No Code Changes
Reason: This is a skill-configuration task. The bridge is purely documentation/instruction — no new scripts, no engine changes, no agent definition changes. The Soul Core engine's existing CLI interface is the integration point. The only file changes are SKILL.md documentation updates and project documentation additions.
