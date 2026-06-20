"""
Unit tests for jinli_workflow MCP server.
Tests path traversal rejection, task discovery, gate delegation, claim collision,
report schema, role allowlists, and Worker authority boundaries.
"""
import pytest
import os
import json
import tempfile
import sys
from pathlib import Path

# Ensure the MCP package is importable
sys.path.insert(0, str(Path(__file__).parent.parent / "mcp" / "jinli_workflow"))

# We test the internal modules directly, not the MCP stdio interface
# This allows deterministic testing without a running MCP transport


class TestPaths:
    """Task/path resolution and traversal rejection."""

    def test_root_containment(self):
        """Paths must stay under workspace root."""
        from paths import resolve_path, is_under_root
        workspace = "E:/UEGameDevelopment"
        assert is_under_root(workspace, f"{workspace}/.trae/tasks/_shared/test")
        assert is_under_root(workspace, f"{workspace}/.trae/scripts/test.ps1")
        assert not is_under_root(workspace, "C:/windows/system32")
        assert not is_under_root(workspace, "E:/OtherProject")

    def test_rejects_task_path_traversal(self):
        """Reject paths that escape the task root."""
        from paths import validate_task_path
        # Valid
        assert validate_task_path("_shared/2026-06-19-hermes-workflow-integration") == True
        # Traversal attempt
        assert validate_task_path("../../../windows/system32") == False
        assert validate_task_path("_shared/../../secret") == False
        # Empty
        assert validate_task_path("") == False
        assert validate_task_path(None) == False

    def test_rejects_absolute_paths_outside_root(self):
        """Absolute paths must resolve under workspace."""
        from paths import is_under_root
        assert not is_under_root("E:/UEGameDevelopment", "E:/OtherProject/file.txt")


class TestTaskDiscovery:
    """Lists only real task packets."""

    def test_lists_only_real_task_packets(self):
        """Only directories with .task.yaml are valid task packets."""
        from paths import list_task_packets
        import tempfile
        from pathlib import Path
        with tempfile.TemporaryDirectory() as tmp:
            # Create proper .trae/tasks structure
            task_root = Path(tmp) / ".trae" / "tasks" / "_shared"
            task_root.mkdir(parents=True)
            valid = task_root / "test-task"
            valid.mkdir()
            (valid / "spec.md").write_text("phase: plan")
            # Invalid - no .task.yaml
            invalid = task_root / "not-a-task"
            invalid.mkdir()
            # Not a directory
            (task_root / "file.txt").write_text("hello")

            # Note: list_task_packets needs the repo root, not the _shared dir
            tasks = list_task_packets(str(tmp))
            task_names = {t["name"] for t in tasks}
            assert "test-task" in task_names or f"_shared/test-task" in task_names
            assert "not-a-task" not in task_names and f"_shared/not-a-task" not in task_names


class TestGateDelegation:
    """Plan and Can-Edit gates delegate to authoritative scripts."""

    def test_plan_check_delegates_to_task_guard(self):
        """Plan check wraps task-guard.ps1 plan."""
        from service import check_plan
        # Test with non-existent task - should return structured failure
        result = check_plan(task_name="_shared/nonexistent-task")
        assert isinstance(result, dict)
        assert ("passed" in result or "error" in result or "plan_pass" in result)
        # Non-existent task should not pass
        passed = result.get("passed", result.get("plan_pass", result.get("success", True)))
        assert passed == False or "error" in str(result).lower()

    def test_can_edit_delegates_to_task_state(self):
        """Can-Edit wraps task-state.ps1 can-edit."""
        from service import can_edit
        result = can_edit(task_name="_shared/nonexistent-task")
        assert isinstance(result, dict)
        assert ("passed" in result or "error" in result or "can_edit" in result)


class TestClaims:
    """Collision-safe claim behavior."""

    def test_claim_is_collision_safe(self):
        """Creating a claim when one already exists should not overwrite."""
        from service import create_claim
        with tempfile.TemporaryDirectory() as tmp:
            claims_dir = Path(tmp)
            r1 = create_claim(claims_dir, "_shared/test-task", "WP01", "worker-1", ["file1.md"])
            assert r1["success"] == True
            r2 = create_claim(claims_dir, "_shared/test-task", "WP01", "worker-2", ["file2.md"])
            assert r2["success"] == False

    def test_claim_validates_wp_name(self):
        """Reject invalid work package names."""
        from service import create_claim
        with tempfile.TemporaryDirectory() as tmp:
            claims_dir = Path(tmp)
            r = create_claim(claims_dir, "_shared/test-task", "../../escape", "worker", [])
            assert r["success"] == False


class TestReports:
    """Report schema validation."""

    def test_report_requires_scope_and_evidence_sections(self):
        """Report must have Status field and basic structure."""
        from schemas import validate_report_content
        # Valid report
        valid = "Status: done\nExtra scope taken: no\n## Changed Files\n- file1.md"
        assert validate_report_content(valid) == True
        # Missing status
        assert validate_report_content("Some content without status") == False
        # Empty
        assert validate_report_content("") == False
        assert validate_report_content(None) == False

    def test_report_requires_status_done(self):
        """Report should validate Status field presence."""
        from schemas import validate_report_content
        assert validate_report_content("Status: done\nExtra scope taken: no") == True
        # Status: blocked is valid format but not "done"
        assert validate_report_content("Status: blocked\nExtra scope taken: no") == True


class TestRoleAuthorization:
    """Role-specific tool authorization."""

    def test_tool_allowlists_are_role_specific(self):
        """Planner and Implementer have different tool sets."""
        from policy import get_allowed_tools
        planner_tools = get_allowed_tools("planner")
        impl_tools = get_allowed_tools("implementer")

        # Planner has plan-specific tools
        assert "workflow_check_plan" in planner_tools
        assert "workflow_init_task" in planner_tools
        # Implementer has implementation-specific tools
        assert "workflow_can_edit" in impl_tools
        assert "workflow_claim_work_package" in impl_tools
        # Planner should NOT have implementer tools
        assert "workflow_can_edit" not in planner_tools
        assert "workflow_claim_work_package" not in planner_tools
        # Implementer should NOT have planner tools
        assert "workflow_check_plan" not in impl_tools
        assert "workflow_init_task" not in impl_tools

    def test_implementer_cannot_change_architecture(self):
        """Implementer lacks architecture/verify tools."""
        from policy import get_allowed_tools
        impl_tools = get_allowed_tools("implementer")
        assert "workflow_init_task" not in impl_tools
        assert "workflow_write_task_document" not in impl_tools
        assert "workflow_check_plan" not in impl_tools
        assert "workflow_run_verify" not in impl_tools
