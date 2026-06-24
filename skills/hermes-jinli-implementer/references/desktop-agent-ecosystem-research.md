# Desktop Agent Ecosystem Research — Key Projects & Architecture Patterns

Date: 2026-06-21 (Updated with Windows compatibility findings)
Source: GitHub API + web search + DuckDuckGo, verified star counts + actual install testing

## Tier 1 Projects (MUST integrate or reference)

### microsoft/UFO (9,067★, Python, Active)
- **URL**: https://github.com/microsoft/UFO
- **What**: Windows desktop agent benchmark. UFO³ supports multi-device, multi-app orchestration.
- **Architecture**: Dual-agent (AppAgent per-app + GlobalAgent cross-app). Uses Windows UIA API + GPT-4V.
- **Papers**: arXiv:2511.11332 (UFO³ Galaxy), arXiv:2504.14603 (UFO²), arXiv:2402.03939 (original)
- **YouTube demo**: https://www.youtube.com/watch?v=NGrVWGcJL8o
- **Relevance**: Architecture reference for multi-app orchestration. Our multi-Profile system can map to UFO's Galaxy pattern.

### chongdashu/unreal-mcp (2,000★, C++, Active)
- **URL**: https://github.com/chongdashu/unreal-mcp
- **What**: MCP server that lets AI control Unreal Engine 5.5+ through natural language.
- **Capabilities**: Actor management (create/delete/transform), Blueprint development (create classes, add components, compile), Blueprint node graph editing, input mapping creation, level querying
- **Status**: Experimental (API subject to change), MIT license
- **Relevance**: KILLER INTEGRATION for our UE project. Install this MCP and Hermes can directly control UE Editor — create Blueprints, spawn actors, compile, etc. Saves building a custom UE MCP from scratch.
- **Hermes Status**: MCP Client created (`.trae/hermes/mcp/unreal_mcp/`), UE Plugin installation pending UE5 project readiness.

### lahfir/agent-desktop (870★, Rust, Active) — ⚠️ NOT AVAILABLE ON WINDOWS

- **URL**: https://github.com/lahfir/agent-desktop
- **What**: Native desktop automation CLI for AI agents. Controls any app through OS accessibility trees.
- **Key claim**: 97% token savings vs screenshot-based approaches
- **⚠️ WINDOWS INCOMPATIBILITY (verified 2026-06-21)**:
  - `npm install -g agent-desktop` succeeds but binary is missing
  - Error: `Error: Native binary not found for win32-x64`
  - Source code explicitly states: "Windows and Linux support is coming in Phase 2"
  - Only macOS ARM64 and x64 binaries are included in the npm package
  - **DO NOT attempt to use agent-desktop on Windows until Phase 2 ships**
- **Replacement**: Self-built `windows-computer-use` MCP Server (pywinauto + pyautogui), functionally equivalent with better Windows native support.

### wonderwhy-er/DesktopCommanderMCP (6,188★, TypeScript, Active) — ✅ VERIFIED WORKING

- **URL**: https://github.com/wonderwhy-er/DesktopCommanderMCP
- **What**: Most popular desktop MCP server. Terminal control + file system search + diff editing.
- **Install**: `npm install -g @wonderwhy-er/desktop-commander`
- **⚠️ MCP Startup**: Must use `node dist/index.js` as command, NOT the npm bin `desktop-commander`:
  ```json
  {"command": "node", "args": ["D:/npm-global/node_modules/@wonderwhy-er/desktop-commander/dist/index.js"]}
  ```
- **Hermes Status**: Installed and configured, 20+ tools available.

### windows-computer-use (Self-built, Python) — ✅ VERIFIED WORKING

- **What**: Custom Windows desktop control MCP Server. pywinauto (UIA) + pyautogui (screenshot/keyboard/mouse).
- **Tools**: computer_screenshot, computer_list_windows, computer_activate_window, computer_click, computer_type, computer_press_key, computer_scroll, computer_get_uia_tree
- **Code**: `.trae/hermes/mcp/windows_computer_use/`
- **Dependencies**: `pip install pywinauto pyautogui Pillow mcp`
- **Hermes Status**: Installed and configured, all 8 tools verified working.

## Tier 2 Projects (Architecture reference)

### browser-use/browser-use (99,708★, Python)
- Most popular browser automation agent. Playwright + DOM + vision hybrid. Architecture pattern applicable to desktop.

### pywinauto/pywinauto (6,077★, Python)
- Standard Windows GUI automation library. Win32 API + UIA backend. **Now in active use as core of windows-computer-use MCP.**

### asweigart/pyautogui (12,566★, Python)
- Cross-platform screenshot + keyboard/mouse. **Now in active use as fallback layer in windows-computer-use MCP.**

### showlab/computer_use_ootb (1,949★, Python)
- Anthropic computer-use out-of-the-box. Docker sandbox. Screenshot→LLM→Action loop reference implementation.

### xlang-ai/OSWorld (2,953★, Python, NeurIPS 2024)
- OS-level agent benchmark framework. Evaluation methodology reference.

### OpenAdaptAI/OpenAdapt (1,618★, Python)
- Record→Replay→Automate with AI generalization. Generative RPA approach.

## Three Technical Approaches Compared

### Approach A: Accessibility Tree (Recommended ⭐⭐⭐⭐⭐)
- **Examples**: agent-desktop (macOS only), UFO, pywinauto (our implementation)
- **Pros**: Deterministic element location, 97% token savings, fast (direct API), full UI tree
- **Cons**: Some apps don't support UIA (games, custom renderers), per-app adaptation needed
- **Best for**: VS Code, Office, browsers, UE Editor, standard Win32/WPF apps

### Approach B: Screenshot + Vision LLM (Universal but slow)
- **Examples**: Anthropic computer-use, computer_use_ootb
- **Pros**: Works with any app, cross-platform consistent, simple implementation
- **Cons**: Huge token cost (screenshot per step), low precision (coordinate drift), 2-5s latency per step
- **Best for**: Games, custom-rendered apps, UIA-unavailable scenarios

### Approach C: Hybrid (Best practice ⭐⭐⭐⭐⭐) — ✅ NOW IMPLEMENTED
- **Priority chain**: Accessibility Tree first → OCR+screenshot fallback → Vision LLM last resort
- **Our implementation**: windows-computer-use MCP (UIA via pywinauto → screenshot via pyautogui → Vision LLM via Hermes)

## Current Status (2026-06-21)

| Component | Status | Tools |
|-----------|--------|-------|
| windows-computer-use MCP | ✅ Installed & verified | 8 tools |
| DesktopCommanderMCP | ✅ Installed & verified | 20+ tools |
| unreal-mcp MCP Client | ✅ Created, graceful degradation | 6 tools |
| unreal-mcp UE Plugin | ⏳ Pending UE5 project readiness | — |
| windows-desktop-control Skill | ✅ Created | SKILL.md + safety-policy + mcp-config |
| Gateway + Telegram | ⏳ Next phase | — |

## Remaining Action Items

| Priority | Action | Time | Effect |
|----------|--------|------|--------|
| ★★★★★ | Restart Hermes to load new MCP config | 1min | Tools become available in sessions |
| ★★★★★ | Install unreal-mcp UE Plugin when UE5 project ready | 1-2 days | Hermes controls UE Editor directly |
| ★★★★ | Configure Gateway + Telegram | 1 day | Anywhere-anytime control |
| ★★★ | Add OCR layer (Tesseract/WinOCR) to windows-computer-use | 2-3 days | Better fallback for non-UIA apps |
| ★★ | Reference UFO³ Galaxy architecture | Ongoing | Multi-device multi-app orchestration |
