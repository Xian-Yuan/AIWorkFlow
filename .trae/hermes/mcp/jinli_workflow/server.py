"""MCP server — typed, path-safe, role-authorized workflow interface.

Communicates over stdio using JSON-RPC 2.0.
Exposes a narrow set of workflow tools with role-specific authorization.
All path operations are validated against traversal.
All gate decisions are delegated to authoritative scripts.

Supported MCP methods:
- initialize
- tools/list
- tools/call
- shutdown
"""

import json
import os
import sys
import traceback
from pathlib import Path
from typing import Any, Dict, List, Optional

# Support both package-relative and direct imports
try:
    from . import service
    from . import policy
    from . import paths
    from . import schemas
except ImportError:
    import service
    import policy
    import paths
    import schemas


# ============================================================================
# Tool Definitions — JSON Schema for each MCP tool
# ============================================================================

TOOL_DEFINITIONS = [
    {
        "name": "workflow_list_tasks",
        "description": "List all active task packets and their current phases.",
        "inputSchema": {
            "type": "object",
            "properties": {},
            "required": [],
        },
    },
    {
        "name": "workflow_read_packet",
        "description": "Read approved task packet files (spec.md, tasks.md, routing.md, analysis.md). Validates task names and document names against path traversal.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "task_name": {
                    "type": "string",
                    "description": "Task name (e.g. _shared/2026-06-19-hermes-workflow-integration)",
                },
                "doc_name": {
                    "type": "string",
                    "description": "Document name (e.g. spec.md, tasks.md, routing.md, analysis.md)",
                },
            },
            "required": ["task_name", "doc_name"],
        },
    },
    {
        "name": "workflow_init_task",
        "description": "Initialize a new task packet under .trae/tasks. Creates directory structure and spec.md skeleton. PLANNER ONLY.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "task_name": {
                    "type": "string",
                    "description": "Task name (e.g. _shared/2026-06-19-new-feature)",
                },
                "project_type": {
                    "type": "string",
                    "description": "Project scope: _shared, rts, or character-design-tool",
                    "default": "_shared",
                },
                "task_title": {
                    "type": "string",
                    "description": "Human-readable task title",
                    "default": "",
                },
            },
            "required": ["task_name"],
        },
    },
    {
        "name": "workflow_write_task_document",
        "description": "Write a task document (spec.md, tasks.md, routing.md, analysis.md). Only allowed document names. PLANNER ONLY.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "task_name": {
                    "type": "string",
                    "description": "Task name",
                },
                "doc_name": {
                    "type": "string",
                    "description": "Document name (spec.md, tasks.md, routing.md, analysis.md)",
                },
                "content": {
                    "type": "string",
                    "description": "Markdown content to write",
                },
            },
            "required": ["task_name", "doc_name", "content"],
        },
    },
    {
        "name": "workflow_check_plan",
        "description": "Run the Plan gate via task-guard.ps1. Returns structured pass/fail evidence. PLANNER ONLY.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "task_name": {
                    "type": "string",
                    "description": "Task name to check",
                },
            },
            "required": ["task_name"],
        },
    },
    {
        "name": "workflow_can_edit",
        "description": "Run Can-Edit check via task-state.ps1. Returns structured authorization evidence. IMPLEMENTER ONLY.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "task_name": {
                    "type": "string",
                    "description": "Task name to check",
                },
            },
            "required": ["task_name"],
        },
    },
    {
        "name": "workflow_read_work_package",
        "description": "Read a work package and resolve its allowed/forbidden paths, verification commands, and scope. IMPLEMENTER ONLY.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "task_name": {
                    "type": "string",
                    "description": "Task name",
                },
                "wp_id": {
                    "type": "string",
                    "description": "Work package ID (e.g. WP01, WP02)",
                },
            },
            "required": ["task_name", "wp_id"],
        },
    },
    {
        "name": "workflow_claim_work_package",
        "description": "Create a collision-safe claim for a work package. Refuses to overwrite existing claims. IMPLEMENTER ONLY.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "task_name": {
                    "type": "string",
                    "description": "Task name",
                },
                "work_package": {
                    "type": "string",
                    "description": "Work package ID (e.g. WP02)",
                },
                "owner": {
                    "type": "string",
                    "description": "Owner model name",
                },
                "claimed_paths": {
                    "type": "array",
                    "items": {"type": "string"},
                    "description": "List of claimed file paths",
                },
                "scope_in": {
                    "type": "string",
                    "description": "Short statement of in-scope work",
                    "default": "",
                },
                "scope_out": {
                    "type": "string",
                    "description": "Short statement of out-of-scope work",
                    "default": "",
                },
            },
            "required": ["task_name", "work_package", "owner", "claimed_paths"],
        },
    },
    {
        "name": "workflow_submit_report",
        "description": "Validate and write a worker report. Report must pass schema validation. Status=done requires Extra scope taken: no. IMPLEMENTER ONLY.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "report": {
                    "type": "object",
                    "description": "Report object with status, changed_files, commands_run, etc.",
                },
            },
            "required": ["report"],
        },
    },
    {
        "name": "workflow_run_verify",
        "description": "Run verification commands for a task. Returns evidence without self-declaring pass. PLANNER/VERIFIER ONLY.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "task_name": {
                    "type": "string",
                    "description": "Task name to verify",
                },
            },
            "required": ["task_name"],
        },
    },
]


# ============================================================================
# Tool dispatch map
# ============================================================================

def _get_repo_root() -> Path:
    """Resolve repo root from environment or default."""
    return paths.get_repo_root()


def _dispatch(tool_name: str, args: Dict[str, Any], role: str) -> Dict[str, Any]:
    """Dispatch a tool call to the service layer.

    All calls go through role authorization before dispatch.
    """
    repo_root = _get_repo_root()

    dispatchers = {
        "workflow_list_tasks": lambda: service.list_tasks(repo_root),
        "workflow_read_packet": lambda: service.read_packet(
            repo_root, args.get("task_name", ""), args.get("doc_name", ""),
        ),
        "workflow_init_task": lambda: service.init_task(
            repo_root,
            args.get("task_name", ""),
            args.get("project_type", "_shared"),
            args.get("task_title", ""),
        ),
        "workflow_write_task_document": lambda: service.write_task_document(
            repo_root,
            args.get("task_name", ""),
            args.get("doc_name", ""),
            args.get("content", ""),
        ),
        "workflow_check_plan": lambda: service.check_plan(
            repo_root, args.get("task_name", ""),
        ),
        "workflow_can_edit": lambda: service.can_edit(
            repo_root, args.get("task_name", ""),
        ),
        "workflow_read_work_package": lambda: service.read_work_package(
            repo_root, args.get("task_name", ""), args.get("wp_id", ""),
        ),
        "workflow_claim_work_package": lambda: service.create_claim(
            repo_root,
            args.get("task_name", ""),
            args.get("work_package", ""),
            args.get("owner", ""),
            args.get("claimed_paths", []),
            args.get("scope_in", ""),
            args.get("scope_out", ""),
        ),
        "workflow_submit_report": lambda: service.submit_report(
            repo_root, args.get("report", {}),
        ),
        "workflow_run_verify": lambda: service.run_verify(
            repo_root, args.get("task_name", ""),
        ),
    }

    handler = dispatchers.get(tool_name)
    if not handler:
        return {"error": f"Unknown tool: {tool_name}"}

    return handler()


def handle_tool_call(tool_name: str, args: Dict[str, Any], role: str) -> Dict[str, Any]:
    """Handle a tool call with role authorization check.

    Args:
        tool_name: MCP tool name
        args: Tool arguments
        role: Calling role ("planner", "implementer", "verifier")

    Returns:
        Result dict (always structured JSON-compatible)
    """
    # 1. Role authorization
    if not policy.is_tool_authorized(role, tool_name):
        role_info = policy.get_role_description(role)
        return {
            "error": f"Tool '{tool_name}' is not authorized for role '{role}'",
            "unauthorized": True,
            "role_description": role_info.get("name", role),
            "available_tools": sorted(policy.get_authorized_tools(role)),
        }

    # 2. Dispatch
    try:
        result = _dispatch(tool_name, args, role)
        return result
    except Exception as e:
        return {
            "error": f"Tool execution failed: {e}",
            "error_type": type(e).__name__,
            "error_trace": traceback.format_exc(),
        }


def get_tools() -> List[Any]:
    """Return tool definitions as simple objects for MCP listing."""
    class ToolDef:
        def __init__(self, **kwargs):
            self.__dict__.update(kwargs)
    
    return [ToolDef(**td) for td in TOOL_DEFINITIONS]


# ============================================================================
# MCP JSON-RPC Server
# ============================================================================

def _send_response(response: Dict[str, Any]) -> None:
    """Send a JSON-RPC response to stdout."""
    sys.stdout.write(json.dumps(response, ensure_ascii=False, default=str) + "\n")
    sys.stdout.flush()


def _send_error(request_id: Any, code: int, message: str) -> None:
    """Send a JSON-RPC error response."""
    _send_response({
        "jsonrpc": "2.0",
        "id": request_id,
        "error": {"code": code, "message": message},
    })


def _handle_request(request: Dict[str, Any], role: str) -> Optional[Dict[str, Any]]:
    """Handle a single JSON-RPC request.

    Returns:
        Response dict, or None if the request is a notification (no id).
    """
    method = request.get("method", "")
    params = request.get("params", {})
    req_id = request.get("id")

    if method == "initialize":
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {
                "protocolVersion": "2024-11-05",
                "capabilities": {
                    "tools": {},
                },
                "serverInfo": {
                    "name": "jinli-workflow-mcp",
                    "version": "1.0.0",
                },
            },
        }
    elif method == "tools/list":
        tools_data = [
            {
                "name": td["name"],
                "description": td["description"],
                "inputSchema": td["inputSchema"],
            }
            for td in TOOL_DEFINITIONS
            # Filter by role: only show authorized tools
            if policy.is_tool_authorized(role, td["name"])
        ]
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {"tools": tools_data},
        }
    elif method == "tools/call":
        tool_name = params.get("name", "")
        arguments = params.get("arguments", {})
        result = handle_tool_call(tool_name, arguments, role)
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {
                "content": [
                    {"type": "text", "text": json.dumps(result, ensure_ascii=False, default=str, indent=2)},
                ],
            },
        }
    elif method == "shutdown":
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {},
        }
    elif method == "notifications/initialized":
        # Notification — no response
        return None
    else:
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "error": {"code": -32601, "message": f"Method not found: {method}"},
        }


def run_server(role: str = "planner") -> None:
    """Run the MCP server on stdio.

    The server reads JSON-RPC requests from stdin and writes responses to stdout.
    Logs go to stderr to avoid corrupting the JSON-RPC stream.

    Args:
        role: Default role if JINLI_ROLE env var is not set.
    """
    # Resolve role from environment
    role = os.environ.get("JINLI_ROLE", role).lower()
    if role not in ("planner", "implementer", "verifier"):
        print(f"Warning: Unknown role '{role}', defaulting to 'planner'", file=sys.stderr)
        role = "planner"

    repo_root = _get_repo_root()
    print(f"[jinli-workflow-mcp] Server starting. Role: {role}, Repo: {repo_root}", file=sys.stderr)

    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue

        try:
            request = json.loads(line)
        except json.JSONDecodeError as e:
            print(f"[jinli-workflow-mcp] Invalid JSON: {e}", file=sys.stderr)
            continue

        # Handle the request
        try:
            response = _handle_request(request, role)
            if response is not None:
                _send_response(response)
        except Exception as e:
            print(f"[jinli-workflow-mcp] Error handling request: {e}", file=sys.stderr)
            traceback.print_exc(file=sys.stderr)
            req_id = request.get("id")
            if req_id is not None:
                _send_error(req_id, -32603, f"Internal error: {e}")

        # Check for shutdown
        if request.get("method") == "shutdown":
            print("[jinli-workflow-mcp] Shutting down.", file=sys.stderr)
            break


# ============================================================================
# Entry point
# ============================================================================

def main():
    """Entry point for python -m jinli_workflow."""
    import argparse
    parser = argparse.ArgumentParser(description="jinli-workflow MCP server")
    parser.add_argument("--role", default="planner", help="Role: planner, implementer, verifier")
    args = parser.parse_args()
    run_server(role=args.role)


if __name__ == "__main__":
    main()
