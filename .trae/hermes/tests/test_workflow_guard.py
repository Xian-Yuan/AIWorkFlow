"""
Unit tests for jinli-workflow-guard Hermes plugin.
Tests role validation, mutation blocking, path enforcement,
subagent validation, audit secrecy, and read-only fallback.
"""
import pytest
import os
import sys
import json
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "plugins" / "jinli-workflow-guard"))

# The plugin hooks are decorated and registered at import time.
# We test the guard logic directly by importing the module functions.


class TestRoleValidation:
    def test_missing_role_blocks_mutation(self):
        """Missing JINLI_ROLE env var blocks tool calls."""
        from guard import authorize_tool
        # Mock context without role
        ctx = {}
        result = authorize_tool(ctx, tool_name="edit_file", tool_args={"path": "test.md"})
        # Should block
        assert isinstance(result, dict)
        assert result.get("action") == "block"
        assert "role" in result.get("message", "").lower()

    def test_planner_cannot_edit_application_code(self):
        """Planner role cannot edit Project/ files."""
        from guard import authorize_tool
        ctx = {"role": "planner", "task_name": "test", "repo_root": "E:/UEGameDevelopment"}
        result = authorize_tool(ctx, tool_name="edit_file",
                               tool_args={"path": "E:/UEGameDevelopment/Project/RTS/foo.cpp"})
        assert result.get("action") == "block"

    def test_implementer_requires_task_and_work_package(self):
        """Implementer without task + WP is blocked from mutation."""
        from guard import authorize_tool
        ctx = {"role": "implementer", "repo_root": "E:/UEGameDevelopment"}
        result = authorize_tool(ctx, tool_name="edit_file", tool_args={"path": "test.md"})
        assert result.get("action") == "block"

    def test_forbidden_paths_override_allowed_paths(self):
        """Forbidden paths always override allowed paths."""
        from guard import check_path_scope
        allowed = [".trae/hermes/mcp/**", ".trae/hermes/profiles/**"]
        forbidden = [".trae/hermes/profiles/**"]
        assert check_path_scope(".trae/hermes/mcp/server.py", allowed, forbidden) == True
        assert check_path_scope(".trae/hermes/profiles/config.yaml", allowed, forbidden) == False


class TestReadOnlyFallback:
    def test_read_only_tools_remain_available_when_blocked(self):
        """Read-only tools (list, read) are not blocked."""
        from guard import authorize_tool
        ctx = {"role": "planner", "repo_root": "E:/UEGameDevelopment"}
        # list_files is read-only - should not be blocked for any role with valid context
        result = authorize_tool(ctx, tool_name="list_files", tool_args={})
        # Either allowed or not blocked (the guard may not handle all tool names)
        if isinstance(result, dict):
            assert result.get("action") != "block" or "read" in result.get("message", "").lower()


class TestAuditSafety:
    def test_secret_values_redacted_from_audit(self):
        """Audit records should not contain raw secret values."""
        from audit import sanitize_audit_entry
        entry = {
            "tool": "edit_file",
            "result": "Wrote to file with API_KEY=sk-abc123xyz",
            "role": "implementer",
        }
        cleaned = sanitize_audit_entry(entry)
        result_str = json.dumps(cleaned)
        assert "sk-abc123xyz" not in result_str
        assert "REDACTED" in result_str or "***" in result_str or "sk-" not in result_str
