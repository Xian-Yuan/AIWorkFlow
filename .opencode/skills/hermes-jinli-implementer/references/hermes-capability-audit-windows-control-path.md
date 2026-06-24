# Hermes Agent Capability Audit & Windows Desktop Control Path

Date: 2026-06-21 (Updated with implementation results)
Context: Full audit of Hermes Agent's current toolset, MCP, plugin, profile, and platform status; gap analysis vs "Mavis-level" desktop application control.

## Current Hermes Status (jinli-implementer profile)

### Toolsets Enabled
web, browser, terminal, file, code_execution, vision, image_gen, tts, skills, todo, memory, session_search, clarify, delegation, cronjob, messaging, computer_use

### Toolsets Disabled
video, video_gen, x_search, moa, context_engine, homeassistant, spotify, yuanbao

### MCP Servers (Updated — 4 servers)
- `jinli-workflow` (6 tools: workflow_list_tasks, workflow_read_packet, workflow_can_edit, workflow_read_work_package, workflow_claim_work_package, workflow_submit_report)
- `windows-computer-use` (8 tools: computer_screenshot, computer_list_windows, computer_activate_window, computer_click, computer_type, computer_press_key, computer_scroll, computer_get_uia_tree)
- `desktop-commander` (20+ tools: execute_command, read_output, force_terminate, list_sessions, list_processes, kill_process, search_files, list_directory, directory_tree, create_directory, move_file, search_code, read_multiple_files, write_file, edit_file, get_file_info, read_file, start_process, interact_with_process, read_process_output, etc.)
- `unreal-mcp` (6 tools: ue_status, ue_list_actors, ue_create_actor, ue_delete_actor, ue_set_actor_transform, ue_compile_blueprint)

### Plugins (all disabled)
disk-cleanup, google_meet, security-guidance, spotify, teams_pipeline

### Profiles
- default (z-ai/glm-5.1)
- jinli-implementer (astron-code-latest, custom endpoint)
- jinli-planner (astron-code-latest, custom endpoint)

### Messaging Platforms
None configured. Gateway stopped.

### Cron Jobs
0 scheduled.

## Five-Layer Capability Gap (vs Mavis-level control) — Updated

### Layer 1: GUI Control — ✅ PARTIALLY FILLED
- `windows-computer-use` MCP installed and verified (8 tools)
- `desktop-commander` MCP installed and verified (20+ tools)
- Three-layer hybrid architecture: UIA → Screenshot → Vision LLM
- Remaining gap: OCR layer not yet built, Vision LLM closed loop not yet tested

### Layer 2: Application Integration — ✅ PARTIALLY FILLED
- 4 MCP servers now connected (was 1)
- `unreal-mcp` MCP Client created, UE Plugin pending
- Still missing: GitHub MCP, Playwright MCP, Notion/Slack MCP

### Layer 3: Scheduling & Persistent Runtime — ❌ NOT STARTED
- Cron framework complete but 0 jobs
- Gateway not started — no push events
- No messaging platform configured

### Layer 4: Multi-Agent Collaboration — ❌ NOT STARTED
- delegate_task available, max_spawn_depth=1
- Kanban framework exists but not enabled

### Layer 5: Perception & Memory — ✅ BASE LEVEL
- Memory enabled, cross-session persistent
- Session Search available for history
- Lacks proactive perception (build status, file changes)

## Verified Test Results (2026-06-21)

| Test | Tool | Result |
|------|------|--------|
| List windows | computer_list_windows | ✅ 9 windows found (QQ, Hermes, Edge, Explorer...) |
| Activate window | computer_activate_window("Edge") | ✅ Edge activated |
| UIA tree | computer_get_uia_tree("Hermes", depth=2) | ✅ Full tree returned |
| Screenshot | computer_screenshot | ✅ 1920x1080 captured |
| Press key | computer_press_key("escape") | ✅ Key pressed |
| Multi-MCP | activate + list sequential | ✅ Both succeeded |
| UE5 graceful degradation | ue_list_actors (no UE5) | ✅ Correctly reports unreachable |
| Desktop Commander | tools/list | ✅ 20+ tools available |

## Key Finding: agent-desktop Does NOT Support Windows

agent-desktop (870★, Rust) is frequently recommended for desktop automation but **does not work on Windows**:
- npm package contains only macOS binaries
- Source code states: "Windows and Linux support is coming in Phase 2"
- Running on Windows produces: `Error: Native binary not found for win32-x64`
- Self-built `windows-computer-use` MCP (pywinauto + pyautogui) serves as the Windows equivalent

## Key Finding: DesktopCommanderMCP Startup

Must use `node dist/index.js` as MCP command, NOT the npm bin symlink `desktop-commander`:
```json
{"command": "node", "args": ["D:/npm-global/node_modules/@wonderwhy-er/desktop-commander/dist/index.js"]}
```

## Updated Roadmap

```
Phase 1 (DONE): Desktop Control Foundation ✅
├── windows-computer-use MCP (pywinauto + pyautogui) ✅
├── DesktopCommanderMCP installed ✅
├── unreal-mcp MCP Client created ✅
└── windows-desktop-control Skill + safety policy ✅

Phase 2 (1-2 days): Activation & Integration
├── Start Gateway + connect Telegram
├── Install unreal-mcp UE Plugin when UE5 project ready
├── Connect GitHub MCP
└── Test end-to-end: Hermes session → desktop control

Phase 3 (3-5 days): Deep Application Integration
├── Add OCR layer to windows-computer-use (Tesseract/WinOCR)
├── Vision LLM closed loop (screenshot → analyze → act)
├── Connect Playwright MCP (browser automation)
└── Kanban multi-agent scheduling

Phase 4 (ongoing): Autonomy
├── File system Watcher + Webhook triggers
├── Proactive inspection Cron
├── Memory auto-archival
└── Multi-Profile collaboration pipeline
```

## Competitive Comparison (Updated)

| Capability | Claude Code | Codex | Mavis | Hermes (current) |
|------------|-------------|-------|-------|-------------------|
| Terminal | ✅ | ✅ | ✅ | ✅ |
| File editing | ✅ | ✅ | ✅ | ✅ |
| Browser control | ✅ | ❌ | ✅ | ✅ |
| Desktop app control | ❌ | ❌ | ✅ | ✅ (via MCP) |
| Messaging platforms | ❌ | ❌ | ❌ | ✅ |
| Scheduling/Cron | ❌ | ❌ | ❌ | ✅ |
| Persistent memory | ❌ | ❌ | partial | ✅ |
| MCP ecosystem | ✅ | ❌ | ❌ | ✅ |
| Multi-Profile | ❌ | ❌ | ❌ | ✅ |
| Skill self-improvement | ❌ | ❌ | ❌ | ✅ |
| Sub-agents | ✅ | ❌ | ✅ | ✅ |
