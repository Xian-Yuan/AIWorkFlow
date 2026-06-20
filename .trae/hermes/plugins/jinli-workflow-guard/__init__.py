"""jinli-workflow-guard — Hermes plugin for fail-closed workflow guard.

Registers five hooks:
- on_session_start: validate profile/workspace identity
- pre_llm_call: inject role/task/WP context
- pre_tool_call: block unauthorized mutation
- post_tool_call: record secret-safe audit trail
- subagent_stop: require bounded child report contract

Reads context from environment variables:
- JINLI_ROLE: planner | implementer | verifier
- JINLI_TASK_NAME: task identifier
- JINLI_WORK_PACKAGE: WPxx work package ID
- UEGAMEDEV_ROOT: repository root path
"""

import os
import json
import logging
from datetime import datetime, timezone
from typing import Optional, Dict, Any

from guard import (
    get_environment_context,
    authorize_mutation,
    is_mutation_tool,
    ROLE_PLANNER,
    ROLE_IMPLEMENTER,
    ROLE_VERIFIER,
    VALID_ROLES,
)
from audit import (
    redact_secrets,
    sanitize_for_audit,
    AuditRecord,
    audit_tool_call,
)

logger = logging.getLogger(__name__)

# In-memory context (set at session start, refreshed from env)
_session_context: Dict[str, Any] = {}


def _refresh_context():
    """Refresh session context from environment variables."""
    global _session_context
    _session_context = get_environment_context()


def _build_role_context_text() -> str:
    """Build the role/task/WP context text for pre_llm_call injection."""
    ctx = _session_context
    role = ctx.get("role")
    task = ctx.get("task_name")
    wp = ctx.get("work_package")
    root = ctx.get("root")

    lines = ["[jinli-workflow-guard] Current workflow context:"]
    lines.append(f"  Role: {role or 'NOT SET'}")
    lines.append(f"  Task: {task or 'NOT SET'}")
    lines.append(f"  Work Package: {wp or 'NOT SET (Planner does not require WP)'}")
    lines.append(f"  Repository Root: {root}")

    if role == ROLE_PLANNER:
        lines.append("  Scope: May research, create/update task design documents, coordinate Review/Verify.")
        lines.append("  Forbidden: Application code, .trae/scripts, skills, Project.")
    elif role == ROLE_IMPLEMENTER:
        lines.append("  Scope: One work package at a time. Follow Allowed Paths. Submit report and stop.")
        lines.append("  Forbidden: Architecture decisions, verification, out-of-scope paths.")
        if not task or not wp:
            lines.append("  WARNING: task or work package is missing — mutation tools are BLOCKED.")
    elif role == ROLE_VERIFIER:
        lines.append("  Scope: Read-only except verification-report.md.")
        lines.append("  Forbidden: Any other file writes, architecture changes.")
    else:
        lines.append("  WARNING: No valid role set — mutation tools are BLOCKED.")

    return "\n".join(lines)


def _validate_subagent_report(result: Optional[str]) -> Dict[str, Any]:
    """Validate that a subagent result follows the bounded report contract.

    Required fields: status, changed_files, ac_coverage
    """
    if not result:
        return {"valid": False, "reason": "Missing subagent result"}

    try:
        data = json.loads(result)
        if not isinstance(data, dict):
            return {"valid": False, "reason": "Subagent result is not a JSON object"}

        missing = []
        for field in ("status", "changed_files", "ac_coverage"):
            if field not in data:
                missing.append(field)

        if missing:
            return {"valid": False, "reason": f"Missing required fields: {', '.join(missing)}"}

        return {"valid": True, "reason": ""}
    except json.JSONDecodeError:
        # Result may not be JSON; try to extract key info
        if "status" in (result or "").lower() and "done" in (result or "").lower():
            return {"valid": True, "reason": "non-JSON result appears valid"}
        return {"valid": False, "reason": "Subagent result is not valid JSON"}


# ──────────────────────────────────────────────────
# Hook callbacks
# ──────────────────────────────────────────────────

def on_session_start_callback(session_id: str, model: str, platform: str, **kwargs):
    """Validate profile and workspace identity on session start."""
    _refresh_context()
    ctx = _session_context
    role = ctx.get("role")
    task = ctx.get("task_name")

    logger.info(
        "Session started: session=%s role=%s task=%s wp=%s model=%s platform=%s",
        session_id, role, task, ctx.get("work_package"), model, platform,
    )

    if role == ROLE_IMPLEMENTER and not task:
        logger.warning(
            "Implementer session started without task name. "
            "Mutation tools will be blocked."
        )


def pre_llm_call_callback(
    session_id: str,
    user_message: str,
    conversation_history: list,
    is_first_turn: bool,
    model: str,
    platform: str,
    **kwargs,
):
    """Inject role/task/WP context into the LLM call."""
    _refresh_context()
    context_text = _build_role_context_text()
    return {"context": context_text}


def pre_tool_call_callback(
    tool_name: str,
    args: dict,
    task_id: str,
    **kwargs,
):
    """Block unauthorized mutation tools before execution.

    Returns {"action": "block", "message": "..."} for blocked calls.
    """
    _refresh_context()
    ctx = _session_context

    role = ctx.get("role")
    task_name = ctx.get("task_name")
    work_package = ctx.get("work_package")
    root = ctx.get("root")

    # Read-only tools: always allow
    if not is_mutation_tool(tool_name):
        return None

    # For mutation tools: run authorization
    # Note: Allowed/Forbidden paths should come from work package resolution.
    # In the pre_tool_call hook, we use the available context.
    # The work-package path resolution is done by the MCP/launcher.
    # Here we do the role-based and basic path checks.

    allowed_paths = os.environ.get("JINLI_ALLOWED_PATHS", "").split(os.pathsep) if os.environ.get("JINLI_ALLOWED_PATHS") else []
    forbidden_paths = os.environ.get("JINLI_FORBIDDEN_PATHS", "").split(os.pathsep) if os.environ.get("JINLI_FORBIDDEN_PATHS") else []

    # Filter empty strings
    allowed_paths = [p for p in allowed_paths if p.strip()]
    forbidden_paths = [p for p in forbidden_paths if p.strip()]

    result = authorize_mutation(
        role=role,
        task_name=task_name,
        work_package=work_package,
        tool_name=tool_name,
        tool_args=args,
        allowed_paths=allowed_paths,
        forbidden_paths=forbidden_paths,
        root=root,
    )

    if result["action"] == "block":
        logger.warning(
            "BLOCKED tool=%s role=%s task=%s wp=%s reason=%s",
            tool_name, role, task_name, work_package, result["message"],
        )
        return {"action": "block", "message": result["message"]}

    return None


def post_tool_call_callback(
    tool_name: str,
    args: dict,
    result: str,
    task_id: str,
    duration_ms: int,
    **kwargs,
):
    """Record secret-safe audit trail after tool execution."""
    _refresh_context()
    ctx = _session_context

    # Only audit mutation tools to minimize overhead
    if not is_mutation_tool(tool_name):
        return

    record = audit_tool_call(
        tool_name=tool_name,
        args=args,
        result=result,
        task_id=task_id,
        duration_ms=duration_ms,
        role=ctx.get("role"),
        task_name=ctx.get("task_name"),
        work_package=ctx.get("work_package"),
    )

    # Log the audit record (no secrets)
    logger.info("AUDIT: %s", record.to_json())


def subagent_stop_callback(
    parent_session_id: str,
    child_role: Optional[str],
    child_summary: Optional[str],
    child_status: str,
    duration_ms: int,
    **kwargs,
):
    """Validate delegated child result follows bounded report contract."""
    _refresh_context()
    ctx = _session_context

    validation = _validate_subagent_report(child_summary)
    if not validation["valid"]:
        logger.warning(
            "SUBAGENT_REPORT_INVALID: parent=%s child_role=%s status=%s reason=%s",
            parent_session_id, child_role, child_status, validation["reason"],
        )
    else:
        logger.info(
            "SUBAGENT_COMPLETE: parent=%s child_role=%s status=%s duration_ms=%d",
            parent_session_id, child_role, child_status, duration_ms,
        )


# ──────────────────────────────────────────────────
# Plugin registration
# ──────────────────────────────────────────────────

def register(ctx):
    """Register all hooks and tools with the Hermes plugin system."""

    # Lifecycle hooks
    ctx.register_hook("on_session_start", on_session_start_callback)
    ctx.register_hook("pre_llm_call", pre_llm_call_callback)
    ctx.register_hook("pre_tool_call", pre_tool_call_callback)
    ctx.register_hook("post_tool_call", post_tool_call_callback)
    ctx.register_hook("subagent_stop", subagent_stop_callback)

    logger.info(
        "jinli-workflow-guard plugin registered: "
        "on_session_start, pre_llm_call, pre_tool_call, post_tool_call, subagent_stop"
    )
