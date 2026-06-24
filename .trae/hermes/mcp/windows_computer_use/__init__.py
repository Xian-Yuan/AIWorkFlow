"""Windows Computer Use MCP Server — pywinauto + pyautogui based desktop control."""

import base64
import io
import json
import os
import sys
import time
from typing import Any, Optional

# MCP SDK
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent, ImageContent

# Desktop automation
try:
    import pywinauto
    from pywinauto import Desktop, Application
    HAS_PYWINAUTO = True
except ImportError:
    HAS_PYWINAUTO = False

try:
    import pyautogui
    HAS_PYAUTOGUI = True
except ImportError:
    HAS_PYAUTOGUI = False

try:
    from PIL import Image
    HAS_PIL = True
except ImportError:
    HAS_PIL = False


app = Server("windows-computer-use")


# ── Tool definitions ──────────────────────────────────────────────

@app.list_tools()
async def list_tools() -> list[Tool]:
    return [
        Tool(
            name="computer_screenshot",
            description="Take a screenshot of the current screen or a specific window. Returns a base64-encoded PNG image.",
            inputSchema={
                "type": "object",
                "properties": {
                    "window_title": {
                        "type": "string",
                        "description": "Optional window title to capture. If omitted, captures the full screen."
                    }
                }
            }
        ),
        Tool(
            name="computer_list_windows",
            description="List all visible windows with titles, process IDs, and positions.",
            inputSchema={"type": "object", "properties": {}}
        ),
        Tool(
            name="computer_activate_window",
            description="Activate (bring to front) a window by title substring match.",
            inputSchema={
                "type": "object",
                "properties": {
                    "title": {
                        "type": "string",
                        "description": "Window title substring to match"
                    }
                },
                "required": ["title"]
            }
        ),
        Tool(
            name="computer_click",
            description="Click at screen coordinates or on a UI element by name.",
            inputSchema={
                "type": "object",
                "properties": {
                    "x": {"type": "integer", "description": "Screen X coordinate"},
                    "y": {"type": "integer", "description": "Screen Y coordinate"},
                    "element_name": {"type": "string", "description": "UI element name (uses pywinauto accessibility, more reliable than coordinates)"},
                    "button": {"type": "string", "enum": ["left", "right", "middle"], "description": "Mouse button (default: left)"},
                    "clicks": {"type": "integer", "description": "Number of clicks (default: 1)"}
                }
            }
        ),
        Tool(
            name="computer_type",
            description="Type text into the active window. Optionally target a specific UI element first.",
            inputSchema={
                "type": "object",
                "properties": {
                    "text": {"type": "string", "description": "Text to type"},
                    "element_name": {"type": "string", "description": "Optional UI element to focus before typing"},
                    "clear_first": {"type": "boolean", "description": "Clear existing text before typing (default: false)"}
                },
                "required": ["text"]
            }
        ),
        Tool(
            name="computer_press_key",
            description="Press a key combination (e.g. 'ctrl+c', 'alt+f4', 'enter').",
            inputSchema={
                "type": "object",
                "properties": {
                    "keys": {
                        "type": "string",
                        "description": "Key combination using '+' as separator (e.g. 'ctrl+c', 'alt+f4', 'enter')"
                    }
                },
                "required": ["keys"]
            }
        ),
        Tool(
            name="computer_scroll",
            description="Scroll the mouse wheel at current position or specified coordinates.",
            inputSchema={
                "type": "object",
                "properties": {
                    "direction": {"type": "string", "enum": ["up", "down"], "description": "Scroll direction"},
                    "amount": {"type": "integer", "description": "Number of scroll clicks (default: 3)"},
                    "x": {"type": "integer", "description": "Optional X coordinate"},
                    "y": {"type": "integer", "description": "Optional Y coordinate"}
                },
                "required": ["direction"]
            }
        ),
        Tool(
            name="computer_get_uia_tree",
            description="Get the UI Automation tree for a window. Returns structured element hierarchy with names, types, and bounding rectangles.",
            inputSchema={
                "type": "object",
                "properties": {
                    "window_title": {
                        "type": "string",
                        "description": "Window title substring to match. If omitted, uses the foreground window."
                    },
                    "depth": {
                        "type": "integer",
                        "description": "Maximum tree depth (default: 3, max: 6 to avoid huge outputs)"
                    }
                }
            }
        ),
    ]


# ── Tool implementations ──────────────────────────────────────────

@app.call_tool()
async def call_tool(name: str, arguments: dict[str, Any]) -> list[TextContent | ImageContent]:
    try:
        if name == "computer_screenshot":
            return await _screenshot(arguments.get("window_title"))
        elif name == "computer_list_windows":
            return await _list_windows()
        elif name == "computer_activate_window":
            return await _activate_window(arguments["title"])
        elif name == "computer_click":
            return await _click(
                arguments.get("x"), arguments.get("y"),
                arguments.get("element_name"), arguments.get("button", "left"),
                arguments.get("clicks", 1)
            )
        elif name == "computer_type":
            return await _type_text(
                arguments["text"], arguments.get("element_name"),
                arguments.get("clear_first", False)
            )
        elif name == "computer_press_key":
            return await _press_key(arguments["keys"])
        elif name == "computer_scroll":
            return await _scroll(
                arguments["direction"], arguments.get("amount", 3),
                arguments.get("x"), arguments.get("y")
            )
        elif name == "computer_get_uia_tree":
            return await _get_uia_tree(
                arguments.get("window_title"), arguments.get("depth", 3)
            )
        else:
            return [TextContent(type="text", text=f"Unknown tool: {name}")]
    except Exception as e:
        return [TextContent(type="text", text=f"Error: {type(e).__name__}: {str(e)}")]


async def _screenshot(window_title: Optional[str] = None) -> list[TextContent | ImageContent]:
    if not HAS_PYAUTOGUI or not HAS_PIL:
        return [TextContent(type="text", text="Error: pyautogui or Pillow not installed")]

    if window_title and HAS_PYWINAUTO:
        try:
            desktop = Desktop(backend="uia")
            win = desktop.window(title_re=f".*{window_title}.*")
            if win.exists(timeout=3):
                win.set_focus()
                rect = win.rectangle()
                img = pyautogui.screenshot(region=(rect.left, rect.top, rect.width(), rect.height()))
            else:
                img = pyautogui.screenshot()
        except Exception:
            img = pyautogui.screenshot()
    else:
        img = pyautogui.screenshot()

    buf = io.BytesIO()
    img.save(buf, format="PNG")
    b64 = base64.b64encode(buf.getvalue()).decode("utf-8")

    return [ImageContent(type="image", data=b64, mimeType="image/png")]


async def _list_windows() -> list[TextContent]:
    if not HAS_PYWINAUTO:
        return [TextContent(type="text", text="Error: pywinauto not installed")]

    desktop = Desktop(backend="uia")
    windows = []
    for win in desktop.windows():
        try:
            title = win.window_text()
            if not title or title == "":
                continue
            rect = win.rectangle()
            info = {
                "title": title,
                "pid": win.process_id(),
                "visible": win.is_visible(),
                "position": {"left": rect.left, "top": rect.top, "width": rect.width(), "height": rect.height()},
                "class_name": win.element_info.class_name or "",
            }
            windows.append(info)
        except Exception:
            continue

    return [TextContent(type="text", text=json.dumps(windows, indent=2, ensure_ascii=False))]


async def _activate_window(title: str) -> list[TextContent]:
    if not HAS_PYWINAUTO:
        return [TextContent(type="text", text="Error: pywinauto not installed")]

    desktop = Desktop(backend="uia")
    win = desktop.window(title_re=f".*{title}.*")
    if win.exists(timeout=5):
        win.set_focus()
        return [TextContent(type="text", text=f"Activated window: {win.window_text()}")]
    else:
        return [TextContent(type="text", text=f"Window not found matching: {title}")]


async def _click(x=None, y=None, element_name=None, button="left", clicks=1) -> list[TextContent]:
    if element_name and HAS_PYWINAUTO:
        try:
            desktop = Desktop(backend="uia")
            # Try to find element in foreground window
            fg = desktop.window(active_only=True)
            elem = fg.child_window(title=element_name, control_type="Button")
            if elem.exists(timeout=3):
                elem.click()
                return [TextContent(type="text", text=f"Clicked element: {element_name}")]
            # Try broader search
            elem = fg.child_window(title_re=f".*{element_name}.*")
            if elem.exists(timeout=2):
                elem.click()
                return [TextContent(type="text", text=f"Clicked element matching: {element_name}")]
        except Exception as e:
            return [TextContent(type="text", text=f"Element click failed ({e}), falling back to coordinates")]

    if x is not None and y is not None and HAS_PYAUTOGUI:
        pyautogui.click(x=x, y=y, button=button, clicks=clicks)
        return [TextContent(type="text", text=f"Clicked at ({x}, {y}) button={button} clicks={clicks}")]

    return [TextContent(type="text", text="Error: provide either (x, y) coordinates or element_name")]


async def _type_text(text: str, element_name=None, clear_first=False) -> list[TextContent]:
    if element_name and HAS_PYWINAUTO:
        try:
            desktop = Desktop(backend="uia")
            fg = desktop.window(active_only=True)
            elem = fg.child_window(title_re=f".*{element_name}.*")
            if elem.exists(timeout=3):
                if clear_first:
                    elem.set_focus()
                    pyautogui.hotkey('ctrl', 'a')
                    time.sleep(0.1)
                    pyautogui.press('delete')
                elem.type_keys(text, with_spaces=True)
                return [TextContent(type="text", text=f"Typed into element: {element_name}")]
        except Exception:
            pass

    if HAS_PYAUTOGUI:
        if clear_first:
            pyautogui.hotkey('ctrl', 'a')
            time.sleep(0.1)
            pyautogui.press('delete')
        pyautogui.write(text, interval=0.02)
        return [TextContent(type="text", text=f"Typed text ({len(text)} chars)")]

    return [TextContent(type="text", text="Error: no typing method available")]


async def _press_key(keys: str) -> list[TextContent]:
    if not HAS_PYAUTOGUI:
        return [TextContent(type="text", text="Error: pyautogui not installed")]

    parts = [k.strip().lower() for k in keys.split("+")]
    if len(parts) > 1:
        pyautogui.hotkey(*parts)
    else:
        pyautogui.press(parts[0])
    return [TextContent(type="text", text=f"Pressed: {keys}")]


async def _scroll(direction: str, amount: int = 3, x=None, y=None) -> list[TextContent]:
    if not HAS_PYAUTOGUI:
        return [TextContent(type="text", text="Error: pyautogui not installed")]

    if x is not None and y is not None:
        pyautogui.moveTo(x, y)
    scroll_val = amount if direction == "down" else -amount
    pyautogui.scroll(scroll_val)
    return [TextContent(type="text", text=f"Scrolled {direction} by {amount}")]


async def _get_uia_tree(window_title: Optional[str] = None, depth: int = 3) -> list[TextContent]:
    if not HAS_PYWINAUTO:
        return [TextContent(type="text", text="Error: pywinauto not installed")]

    depth = min(depth, 6)  # Cap depth to avoid huge outputs

    def _walk(element, current_depth: int) -> dict:
        if current_depth > depth:
            return {"name": "...", "truncated": True}
        try:
            info = element.element_info
            result = {
                "name": info.name or "",
                "type": info.control_type or "",
                "class": info.class_name or "",
                "automation_id": info.automation_id or "",
            }
            try:
                rect = element.rectangle()
                result["rect"] = {"l": rect.left, "t": rect.top, "r": rect.right, "b": rect.bottom}
            except Exception:
                pass
            if current_depth < depth:
                children = []
                for child in element.children():
                    try:
                        children.append(_walk(child, current_depth + 1))
                    except Exception:
                        continue
                if children:
                    result["children"] = children[:50]  # Limit children
            return result
        except Exception:
            return {"error": "cannot read element"}

    try:
        desktop = Desktop(backend="uia")
        if window_title:
            win = desktop.window(title_re=f".*{window_title}.*")
        else:
            win = desktop.window(active_only=True)

        if not win.exists(timeout=5):
            return [TextContent(type="text", text=f"Window not found: {window_title}")]

        tree = _walk(win, 0)
        return [TextContent(type="text", text=json.dumps(tree, indent=2, ensure_ascii=False))]
    except Exception as e:
        return [TextContent(type="text", text=f"Error getting UIA tree: {e}")]


# ── Main ───────────────────────────────────────────────────────────

async def main():
    async with stdio_server() as (read_stream, write_stream):
        await app.run(read_stream, write_stream, app.create_initialization_options())


if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
