# Repomix Workflow

## Purpose

Repomix is a packaging tool for producing a bounded, reviewable repository snapshot for AI consumption.

Use it when:
- handing a subset of the project to another model or external review session;
- preparing a compact context bundle for docs, skills, or memory review;
- comparing a focused area without loading the whole UE project.

Do not use it as the normal Codex file-reading path. Codex should still inspect local files directly when working inside this workspace.

## Project Rules

- Tool install path: `G:\UEGameDevelopment\.tools\repomix\`
- Launcher: `G:\UEGameDevelopment\.trae\scripts\repomix.ps1`
- Default output: `G:\UEGameDevelopment\.tmp\repomix-output.xml`
- Config: `G:\UEGameDevelopment\repomix.config.json`
- Ignore file: `G:\UEGameDevelopment\.repomixignore`

All generated bundles must stay under `G:\UEGameDevelopment\.tmp\`. Do not write Repomix outputs to C drive.

## Standard Commands

Pack a focused documentation or memory area:

```powershell
powershell -ExecutionPolicy Bypass -File "G:\UEGameDevelopment\.trae\scripts\repomix.ps1" -Target "Docs\Memory" -Output "G:\UEGameDevelopment\.tmp\repomix-memory.xml" -Compress
```

Pack a focused code area as Markdown:

```powershell
powershell -ExecutionPolicy Bypass -File "G:\UEGameDevelopment\.trae\scripts\repomix.ps1" -Target "Project\CharacterDesignTool" -Output "G:\UEGameDevelopment\.tmp\repomix-character-tool.md" -Compress -Markdown
```

## Safety Checklist

- Keep target scope narrow.
- Keep `security.enableSecurityCheck` enabled.
- Confirm `.repomixignore` excludes generated folders, UE binary assets, caches, and local tools.
- Do not include secrets, API keys, private credentials, or large binary assets.
- Delete obsolete bundles from `.tmp` after they are no longer needed.
