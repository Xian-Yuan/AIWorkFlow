"""Unreal Engine MCP Client — connects to unreal-mcp server running inside UE5 Editor.

This is a thin MCP proxy that connects to the unreal-mcp Python server
(which runs as a UE5 Editor plugin). When UE5 is not running, this server
will report a connection error gracefully.

Prerequisites:
- unreal-mcp UE5 Plugin installed in the target project
- UE5 Editor running with the plugin active
- The unreal-mcp Python server listening on localhost (default port 55557)
"""

import json
import socket
import sys
from typing import Any

from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

app = Server("unreal-mcp")

UE_MCP_HOST = "127.0.0.1"
UE_MCP_PORT = 55557
UE_MCP_TIMEOUT = 5  # seconds


def _ue_is_running() -> bool:
    """Check if the unreal-mcp server is reachable."""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(2)
        s.connect((UE_MCP_HOST, UE_MCP_PORT))
        s.close()
        return True
    except (ConnectionRefusedError, socket.timeout, OSError):
        return False


def _send_to_ue(command: dict) -> dict:
    """Send a command to the unreal-mcp server and return the response."""
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(UE_MCP_TIMEOUT)
    s.connect((UE_MCP_HOST, UE_MCP_PORT))
    s.sendall((json.dumps(command) + "\n").encode("utf-8"))
    data = s.recv(65536).decode("utf-8")
    s.close()
    return json.loads(data)


@app.list_tools()
async def list_tools() -> list[Tool]:
    return [
        Tool(
            name="ue_status",
            description="Check if UE5 Editor with unreal-mcp plugin is running and connected.",
            inputSchema={"type": "object", "properties": {}}
        ),
        Tool(
            name="ue_list_actors",
            description="List all actors in the current UE5 level.",
            inputSchema={"type": "object", "properties": {}}
        ),
        Tool(
            name="ue_create_actor",
            description="Create an actor in the current UE5 level.",
            inputSchema={
                "type": "object",
                "properties": {
                    "actor_type": {"type": "string", "description": "Actor class name (e.g. 'Cube', 'Sphere', 'Light', 'Camera')"},
                    "location": {"type": "array", "items": {"type": "number"}, "description": "Optional [X, Y, Z] location"},
                    "name": {"type": "string", "description": "Optional actor name"}
                },
                "required": ["actor_type"]
            }
        ),
        Tool(
            name="ue_delete_actor",
            description="Delete an actor by name.",
            inputSchema={
                "type": "object",
                "properties": {
                    "name": {"type": "string", "description": "Actor name to delete"}
                },
                "required": ["name"]
            }
        ),
        Tool(
            name="ue_set_actor_transform",
            description="Set an actor's transform (location, rotation, scale).",
            inputSchema={
                "type": "object",
                "properties": {
                    "name": {"type": "string", "description": "Actor name"},
                    "location": {"type": "array", "items": {"type": "number"}, "description": "[X, Y, Z]"},
                    "rotation": {"type": "array", "items": {"type": "number"}, "description": "[Pitch, Yaw, Roll]"},
                    "scale": {"type": "array", "items": {"type": "number"}, "description": "[X, Y, Z]"}
                },
                "required": ["name"]
            }
        ),
        Tool(
            name="ue_compile_blueprint",
            description="Compile a Blueprint by name.",
            inputSchema={
                "type": "object",
                "properties": {
                    "name": {"type": "string", "description": "Blueprint name"}
                },
                "required": ["name"]
            }
        ),
    ]


@app.call_tool()
async def call_tool(name: str, arguments: dict[str, Any]) -> list[TextContent]:
    if name == "ue_status":
        running = _ue_is_running()
        return [TextContent(type="text", text=json.dumps({
            "ue_running": running,
            "host": UE_MCP_HOST,
            "port": UE_MCP_PORT,
            "message": "UE5 Editor with unreal-mcp is reachable" if running
                       else "UE5 Editor not reachable. Start UE5 with unreal-mcp plugin first."
        }, indent=2))]

    if not _ue_is_running():
        return [TextContent(type="text", text="Error: UE5 Editor is not running or unreal-mcp plugin is not active. Start UE5 first.")]

    try:
        # Map tool calls to unreal-mcp commands
        cmd_map = {
            "ue_list_actors": {"command": "list_actors"},
            "ue_create_actor": {"command": "create_actor", "params": arguments},
            "ue_delete_actor": {"command": "delete_actor", "params": arguments},
            "ue_set_actor_transform": {"command": "set_actor_transform", "params": arguments},
            "ue_compile_blueprint": {"command": "compile_blueprint", "params": arguments},
        }

        if name not in cmd_map:
            return [TextContent(type="text", text=f"Unknown tool: {name}")]

        result = _send_to_ue(cmd_map[name])
        return [TextContent(type="text", text=json.dumps(result, indent=2, ensure_ascii=False))]

    except Exception as e:
        return [TextContent(type="text", text=f"Error communicating with UE5: {type(e).__name__}: {str(e)}")]


async def main():
    async with stdio_server() as (read_stream, write_stream):
        await app.run(read_stream, write_stream, app.create_initialization_options())


if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
