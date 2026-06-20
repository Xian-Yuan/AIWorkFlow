"""Claim and report schema validation.

Enforces the shared task-packet contract for claims and reports:
- Claims must identify task, WP, owner, and claimed paths
- Reports must declare Status (done|blocked) and scope markers
- Done reports require Extra scope taken: no
"""

from typing import Any, Dict


REQUIRED_CLAIM_FIELDS = {
    "task_packet",
    "work_package",
    "owner_model",
    "claimed_paths",
}

REQUIRED_REPORT_FIELDS = {
    "task_packet",
    "work_package",
    "status",
}

VALID_STATUS_VALUES = {"done", "blocked"}

DONE_REPORT_REQUIRED_FIELDS = {
    "extra_scope_taken",
    "changed_files",
    "commands_run",
}


def validate_claim(claim: Dict[str, Any]) -> bool:
    """Validate a work package claim structure.

    Args:
        claim: Claim dict with task_packet, work_package, owner_model, claimed_paths

    Returns:
        True if valid
    """
    if not isinstance(claim, dict):
        return False
    
    # Required fields
    for field in REQUIRED_CLAIM_FIELDS:
        if field not in claim:
            return False
        if not claim[field]:
            return False
    
    # claimed_paths must be a non-empty list
    if not isinstance(claim["claimed_paths"], list) or len(claim["claimed_paths"]) == 0:
        return False
    
    # Must have claimed_at
    if "claimed_at" not in claim or not claim["claimed_at"]:
        return False
    
    return True


def validate_report(report: Dict[str, Any]) -> bool:
    """Validate a worker report structure.

    Args:
        report: Report dict following the agent-result template

    Returns:
        True if valid
    """
    if not isinstance(report, dict):
        return False
    
    # Required base fields
    for field in REQUIRED_REPORT_FIELDS:
        if field not in report:
            return False
    
    status = report.get("status", "")
    if status not in VALID_STATUS_VALUES:
        return False
    
    # "done" reports MUST declare Extra scope taken: no
    if status == "done":
        extra = report.get("extra_scope_taken", "")
        if extra != "no":
            return False
        # Must have at minimum changed_files and commands_run
        if "changed_files" not in report:
            return False
        if "commands_run" not in report:
            return False
    
    # "blocked" reports are valid without the done markers
    return True


def validate_report_sections(report: Dict[str, Any]) -> Dict[str, bool]:
    """Check which required report sections are present.

    Returns a dict of section → present flag.
    """
    sections = {
        "changed_files": "changed_files" in report,
        "commands_run": "commands_run" in report,
        "acceptance_criteria": "acceptance_criteria" in report,
        "extra_scope_taken": report.get("extra_scope_taken") == "no",
        "forbidden_paths_touched": "forbidden_paths_touched" in report,
        "unresolved_risks": "unresolved_risks" in report,
    }
    return sections


def validate_report_content(content: str) -> bool:
    """Validate a report string for required markers.
    
    Accepts a raw string (e.g., markdown content).
    Checks for Status field and basic structure.
    Used by tests for content-based validation.
    """
    if not content or not isinstance(content, str):
        return False
    if content.strip() == "":
        return False
    
    # Check for Status field
    has_status = "Status:" in content
    if not has_status:
        return False
    
    return True
