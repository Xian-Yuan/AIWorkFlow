"""
MCP stdio initialize regression test.

Verifies the MCP server starts as a subprocess, responds to JSON-RPC
initialize, and shuts down cleanly. This prevents regression of cwd/path
or framing issues that unit tests cannot catch.

Requires: Python 3.11+, pytest
"""
import json
import os
import subprocess
import sys
import time
from pathlib import Path

import pytest


REPO_ROOT = Path(__file__).parent.parent.parent.parent.resolve()
SERVER_MODULE = "jinli_workflow"
SERVER_DIR = REPO_ROOT / ".trae" / "hermes" / "mcp"
SERVER_PYTHON = os.environ.get(
    "TEST_PYTHON",
    str(REPO_ROOT / ".tools" / "hermes-worker" / "hermes-agent" / "venv" / "Scripts" / "python.exe"),
)


def _find_python():
    """Return a working Python interpreter, preferring the Hermes venv."""
    candidates = [
        SERVER_PYTHON,
        "python",
        sys.executable,
    ]
    for c in candidates:
        try:
            result = subprocess.run(
                [c, "--version"], capture_output=True, text=True, timeout=10
            )
            if result.returncode == 0:
                return c
        except (FileNotFoundError, subprocess.TimeoutExpired):
            continue
    raise RuntimeError("No working Python interpreter found")


def _start_server(python_exe: str, role: str = "planner") -> subprocess.Popen:
    """Start the MCP server as a subprocess.

    Returns:
        Popen object with stdin/stdout pipes.
    """
    env = os.environ.copy()
    env["JINLI_ROLE"] = role
    # Ensure the MCP package is on sys.path for -m invocation
    mcp_parent = str(SERVER_DIR)
    existing = env.get("PYTHONPATH", "")
    env["PYTHONPATH"] = f"{mcp_parent};{existing}" if existing else mcp_parent
    proc = subprocess.Popen(
        [python_exe, "-m", SERVER_MODULE, "--role", role],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        cwd=str(REPO_ROOT),
        env=env,
        text=True,
        # Windows PIPE needs bufsize for flush() to work
        bufsize=1,
    )
    return proc


def _send_request(proc: subprocess.Popen, request: dict) -> dict:
    """Send a JSON-RPC request and read the response.

    Reads exactly one JSON line from stdout.  stderr is NOT drained
    (it contains log lines we ignore).

    Returns:
        Parsed JSON-RPC response dict.
    """
    raw = json.dumps(request) + "\n"
    proc.stdin.write(raw)
    proc.stdin.flush()

    # Read one JSON line from stdout
    line = proc.stdout.readline()
    if not line:
        raise RuntimeError("Server closed stdout unexpectedly")
    return json.loads(line.strip())


def _shutdown(proc: subprocess.Popen, timeout: float = 5.0):
    """Send shutdown request and wait for clean exit."""
    try:
        req = {"jsonrpc": "2.0", "id": 99, "method": "shutdown", "params": {}}
        proc.stdin.write(json.dumps(req) + "\n")
        proc.stdin.flush()
        _ = proc.stdout.readline()  # consume shutdown response
    except Exception:
        pass
    finally:
        try:
            proc.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()


@pytest.fixture
def mcp_server():
    """Fixture: start MCP server as subprocess, yield proc, shutdown after."""
    python_exe = _find_python()
    proc = _start_server(python_exe, role="planner")
    # Give the server a moment to start
    time.sleep(0.5)
    yield proc
    _shutdown(proc)


class TestStdioInitialize:
    """Regression test: MCP server stdio initialize handshake."""

    def test_initialize_handshake(self, mcp_server):
        """Verify server responds to initialize with correct serverInfo."""
        request = {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "initialize",
            "params": {
                "protocolVersion": "2024-11-05",
                "capabilities": {},
                "clientInfo": {"name": "test", "version": "1.0"},
            },
        }

        response = _send_request(mcp_server, request)

        # Validate JSON-RPC structure
        assert response.get("jsonrpc") == "2.0", "Missing or invalid jsonrpc version"
        assert response.get("id") == 1, f"Expected id 1, got {response.get('id')}"
        assert "result" in response, f"Expected 'result' in response: {response}"
        assert "error" not in response, f"Unexpected error: {response.get('error')}"

        # Validate serverInfo
        result = response["result"]
        assert "serverInfo" in result, "Missing serverInfo in result"
        assert "jinli-workflow" in result["serverInfo"].get("name", ""), (
            f"Expected 'jinli-workflow' in serverInfo.name, "
            f"got: {result['serverInfo'].get('name')}"
        )
        assert result["serverInfo"].get("version", "").startswith("1."), (
            f"Expected version 1.x, got: {result['serverInfo'].get('version')}"
        )

        # Validate protocol version echo
        assert result.get("protocolVersion") == "2024-11-05", (
            f"Expected protocolVersion 2024-11-05, "
            f"got: {result.get('protocolVersion')}"
        )

        # Validate capabilities
        assert "capabilities" in result, "Missing capabilities"
        assert "tools" in result["capabilities"], "Missing tools in capabilities"

    def test_initialize_rejects_invalid_json(self, mcp_server):
        """Server should not crash on invalid JSON input."""
        mcp_server.stdin.write("not json\n")
        mcp_server.stdin.flush()

        # Send a valid request after the garbage — server should still respond
        request = {
            "jsonrpc": "2.0",
            "id": 2,
            "method": "initialize",
            "params": {"protocolVersion": "2024-11-05", "capabilities": {}, "clientInfo": {"name": "t", "version": "1"}},
        }
        response = _send_request(mcp_server, request)
        assert response.get("id") == 2
        assert "result" in response

    def test_initialize_unknown_method(self, mcp_server):
        """Server should return error for unknown method."""
        request = {
            "jsonrpc": "2.0",
            "id": 3,
            "method": "unknown_method",
            "params": {},
        }
        response = _send_request(mcp_server, request)
        assert response.get("id") == 3
        assert "error" in response
        assert response["error"]["code"] == -32601

    def test_shutdown_cleanup(self, mcp_server):
        """Server should exit cleanly after shutdown."""
        # Send initialize first
        _send_request(mcp_server, {
            "jsonrpc": "2.0", "id": 4, "method": "initialize",
            "params": {"protocolVersion": "2024-11-05", "capabilities": {}, "clientInfo": {"name": "t", "version": "1"}},
        })

        # Shutdown
        _send_request(mcp_server, {
            "jsonrpc": "2.0", "id": 5, "method": "shutdown", "params": {},
        })

        # Server should close stdin/stdout within 3 seconds
        try:
            mcp_server.wait(timeout=3)
            assert mcp_server.returncode == 0, (
                f"Expected exit code 0, got {mcp_server.returncode}"
            )
        except subprocess.TimeoutExpired:
            pytest.fail("Server did not exit after shutdown within 3 seconds")

    def test_tools_list_after_initialize(self, mcp_server):
        """Verify tools/list returns at least the expected tools."""
        # Initialize first
        _send_request(mcp_server, {
            "jsonrpc": "2.0", "id": 6, "method": "initialize",
            "params": {"protocolVersion": "2024-11-05", "capabilities": {}, "clientInfo": {"name": "t", "version": "1"}},
        })

        # List tools
        response = _send_request(mcp_server, {
            "jsonrpc": "2.0", "id": 7, "method": "tools/list", "params": {},
        })

        assert "result" in response, f"Missing result: {response}"
        tools = response["result"].get("tools", [])
        tool_names = [t["name"] for t in tools]

        # Planner should see these tools
        expected_tools = [
            "workflow_list_tasks",
            "workflow_read_packet",
            "workflow_init_task",
            "workflow_write_task_document",
            "workflow_check_plan",
            "workflow_run_verify",
        ]
        for tname in expected_tools:
            assert tname in tool_names, (
                f"Planner missing tool '{tname}'. Available: {tool_names}"
            )

        # Planner should NOT see implementer-only tools
        blocked_tools = ["workflow_can_edit", "workflow_claim_work_package", "workflow_submit_report"]
        for tname in blocked_tools:
            assert tname not in tool_names, (
                f"Planner should NOT see '{tname}', but it's in tools/list"
            )
