# Electron/Chromium App Control Reference

## Problem

Electron apps (VS Code, OpenCode, Discord, Slack, Figma, Notion, etc.) render their UI through Chromium's internal compositor, bypassing the Windows UI Automation (UIA) protocol. This means:

- `computer_get_uia_tree()` returns only the window shell (Window → Pane → RootView), no internal elements
- `computer_click(element_name=...)` cannot find any named elements
- `computer_type(element_name=...)` cannot target specific input fields by name

## Verified Solution: Screenshot + Vision + Coordinates

### Step-by-step workflow

```
1. computer_activate_window("AppTitle")     → bring app to front
2. computer_screenshot()                     → capture current state
3. Vision: "Describe the UI, find the coordinates of [target]"  → get (x, y)
4. computer_click(x, y)                      → click at coordinates
5. computer_type(text)                        → type into focused element
6. computer_screenshot()                      → verify result
```

### Tested: OpenCode (2026-06-21)

| Step | Tool Call | Result |
|------|-----------|--------|
| List windows | `computer_list_windows()` | Found OpenCode PID 32368, class Chrome_WidgetWin_1 |
| Activate | `computer_activate_window("OpenCode")` | ✅ Window brought to front |
| UIA tree | `computer_get_uia_tree("OpenCode", depth=3)` | ❌ Only Window→Pane→RootView, no inner elements |
| Screenshot | `computer_screenshot(window_title="OpenCode")` | ✅ Full 1920x1080 capture |
| Vision analysis | Analyze screenshot | ✅ Identified: input box at bottom, Chat/Diff/History tabs, Context panel |
| Click input | `computer_click(x=960, y=990)` | ✅ Clicked into message input area |
| Type text | `computer_type(text="Hello from Hermes!")` | ✅ 18 chars typed successfully |

### Coordinate reference (1920x1080 fullscreen)

| UI Region | Approximate Y | Approximate X |
|-----------|---------------|---------------|
| Title/tab bar | 0-40 | full width |
| Main content | 40-950 | 300-1920 |
| Sidebar | 40-950 | 0-300 |
| Input/message area | 950-1020 | center (960) |
| Send button | 980-1000 | right of input |

### Screenshot capture gotcha

When capturing screenshots via MCP JSON-RPC, the base64-encoded PNG can be too large for JSON parsing in a single pipe. Workaround:

```python
# Direct Python capture (more reliable than MCP for large screenshots)
import pyautogui
img = pyautogui.screenshot()
img.save('screenshot.png')
```

Then use `vision_analyze(image_url='screenshot.png')` to analyze.

## Native (Win32/WPF/WinForms) Apps vs Electron

| Feature | Native Apps | Electron Apps |
|---------|-------------|---------------|
| UIA tree | ✅ Full element hierarchy | ❌ Empty shell only |
| Element name click | ✅ `computer_click(element_name=...)` | ❌ Not available |
| Coordinate click | ✅ Works | ✅ Works (primary method) |
| Screenshot + Vision | ✅ Works | ✅ Works (required method) |
| Type into named element | ✅ `computer_type(element_name=...)` | ❌ Must click first, then type |

## App Classification Quick Reference

| App | Type | UIA Support | Control Strategy |
|-----|------|-------------|------------------|
| VS Code | Electron | ❌ | Screenshot + Vision + Coordinates |
| OpenCode | Electron | ❌ | Screenshot + Vision + Coordinates |
| Discord | Electron | ❌ | Screenshot + Vision + Coordinates |
| Notion | Electron | ❌ | Screenshot + Vision + Coordinates |
| Chrome/Edge | Chromium | ❌ | Screenshot + Vision + Coordinates |
| Notepad | Win32 | ✅ | UIA tree + element_name |
| Word/Excel | Win32/Office | ✅ | UIA tree + element_name |
| UE5 Editor | Custom | ⚠️ Partial | unreal-mcp preferred, UIA fallback |
| Windows Terminal | UWP | ⚠️ Limited | desktop-commander preferred |
