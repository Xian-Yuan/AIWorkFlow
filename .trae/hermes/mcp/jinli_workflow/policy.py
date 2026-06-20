"""Role-based tool authorization policy.

Defines which tools each role (planner/implementer/verifier) can access.
Worker authority is narrower than Planner authority.
"""

from typing import Set


# ============================================================================
# Role → Tool allowlists
# ============================================================================

PLANNER_TOOLS: Set[str] = {
    "workflow_list_tasks",
    "workflow_read_packet",
    "workflow_init_task",
    "workflow_write_task_document",
    "workflow_check_plan",
    "workflow_run_verify",
}

IMPLEMENTER_TOOLS: Set[str] = {
    "workflow_list_tasks",
    "workflow_read_packet",
    "workflow_can_edit",
    "workflow_read_work_package",
    "workflow_claim_work_package",
    "workflow_submit_report",
}

VERIFIER_TOOLS: Set[str] = {
    "workflow_list_tasks",
    "workflow_read_packet",
    "workflow_run_verify",
}


_ROLE_TOOL_MAP = {
    "planner": PLANNER_TOOLS,
    "implementer": IMPLEMENTER_TOOLS,
    "verifier": VERIFIER_TOOLS,
}


def is_tool_authorized(role: str, tool_name: str) -> bool:
    """Check if a role is authorized to use a specific tool.

    Args:
        role: "planner", "implementer", or "verifier"
        tool_name: MCP tool name

    Returns:
        True if authorized, False otherwise
    """
    if not role or not tool_name:
        return False
    allowed = _ROLE_TOOL_MAP.get(role.lower())
    if allowed is None:
        return False
    return tool_name in allowed


def get_authorized_tools(role: str) -> Set[str]:
    """Get the set of tools authorized for a role.

    Args:
        role: "planner", "implementer", or "verifier"

    Returns:
        Set of authorized tool names (empty set if unknown role)
    """
    return _ROLE_TOOL_MAP.get(role.lower(), set()).copy()


# Alias for test compatibility
get_allowed_tools = get_authorized_tools


def get_role_description(role: str) -> dict:
    """Get role metadata for authorization context."""
    descriptions = {
        "planner": {
            "name": "Planner",
            "may_do": [
                "research and clarify requirements",
                "create and update task design documents",
                "run Plan gate",
                "coordinate Review/Verify",
                "initialize task packets",
            ],
            "must_not_do": [
                "edit application code",
                "claim implementation work",
                "accept worker claims without verification",
            ],
        },
        "implementer": {
            "name": "Implementer",
            "may_do": [
                "read one task packet",
                "claim one work package",
                "edit only allowed paths",
                "run scoped checks",
                "submit one report",
            ],
            "must_not_do": [
                "choose architecture",
                "change task acceptance criteria",
                "transition final verification",
                "edit outside work-package scope",
                "initialize new tasks",
            ],
        },
        "verifier": {
            "name": "Verifier",
            "may_do": [
                "list tasks and read packets",
                "run verification commands",
                "review evidence",
            ],
            "must_not_do": [
                "self-declare pass",
                "modify task documents",
                "claim implementation work",
            ],
        },
    }
    return descriptions.get(role.lower(), {"name": "Unknown", "may_do": [], "must_not_do": []})
