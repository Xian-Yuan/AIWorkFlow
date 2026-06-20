"""Workflow service — business logic layer.

Delegates gate decisions to authoritative PowerShell scripts.
All subprocess calls use argument arrays (not shell strings).
Sets cwd to repo root. Redacts secrets from output.
"""

import json
import os
import subprocess
import time
import traceback
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

# Support both package-relative and direct imports
try:
    from . import paths
    from . import schemas
except ImportError:
    import paths
    import schemas


# Default timeout for script calls
DEFAULT_SCRIPT_TIMEOUT = 30  # seconds


def _run_script(
    repo_root: Path,
    args: List[str],
    timeout: int = DEFAULT_SCRIPT_TIMEOUT,
    env_extra: Optional[Dict[str, str]] = None,
) -> Dict[str, Any]:
    """Run a PowerShell script with argument array, not shell interpolation.

    Args:
        repo_root: Working directory for the process
        args: Argument array (no shell interpolation)
        timeout: Timeout in seconds
        env_extra: Additional environment variables

    Returns:
        Dict with stdout, stderr, exit_code, success, redacted_output
    """
    result = {
        "stdout": "",
        "stderr": "",
        "exit_code": -1,
        "success": False,
        "redacted_output": "",
        "error": None,
    }

    env = os.environ.copy()
    if env_extra:
        env.update(env_extra)
    env.setdefault("UEGAMEDEV_ROOT", str(repo_root))

    try:
        # Use argument array — NEVER shell=True
        process = subprocess.Popen(
            args,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            cwd=str(repo_root),
            env=env,
            shell=False,  # Non-negotiable: argument arrays only
            text=False,   # We decode manually to handle encoding
        )

        try:
            stdout_bytes, stderr_bytes = process.communicate(timeout=timeout)
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
            result["error"] = f"Script timed out after {timeout}s"
            result["exit_code"] = process.returncode or -1
            return result

        # Decode output (Windows PowerShell may use various encodings)
        for encoding in ["utf-8", "gbk", "cp936", "latin-1"]:
            try:
                stdout_text = stdout_bytes.decode(encoding)
                break
            except (UnicodeDecodeError, AttributeError):
                continue
        else:
            stdout_text = stdout_bytes.decode("utf-8", errors="replace")

        for encoding in ["utf-8", "gbk", "cp936", "latin-1"]:
            try:
                stderr_text = stderr_bytes.decode(encoding)
                break
            except (UnicodeDecodeError, AttributeError):
                continue
        else:
            stderr_text = stderr_bytes.decode("utf-8", errors="replace")

        result["stdout"] = stdout_text
        result["stderr"] = stderr_text
        result["exit_code"] = process.returncode
        result["success"] = process.returncode == 0
        
        # Redact secrets from output
        redacted = paths.redact_secrets(stdout_text)
        if stderr_text:
            redacted += "\n" + paths.redact_secrets(stderr_text)
        result["redacted_output"] = redacted.strip()

    except FileNotFoundError as e:
        result["error"] = f"Script not found: {e}"
    except Exception as e:
        result["error"] = f"Script execution failed: {e}"
        result["error_traceback"] = traceback.format_exc()

    return result


def _powershell_args(script_path: Path, *args: str) -> List[str]:
    """Build PowerShell arguments array.

    Args:
        script_path: Path to the .ps1 script file
        *args: Arguments to pass to the script

    Returns:
        Argument array for subprocess.Popen
    """
    return [
        "powershell",
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", str(script_path),
        *args,
    ]


# ============================================================================
# Tool implementations
# ============================================================================

def list_tasks(repo_root: Path) -> Dict[str, Any]:
    """List all active task packets and their phases."""
    try:
        packets = paths.list_task_packets(repo_root)
        return {
            "tasks": packets,
            "count": len(packets),
            "repo_root": str(repo_root),
        }
    except Exception as e:
        return {"error": str(e), "tasks": []}


def read_packet(repo_root: Path, task_name: str, doc_name: str) -> Dict[str, Any]:
    """Read approved task packet files.

    Only allowed document names are readable.
    Path traversal is rejected.
    Global forbidden paths are rejected.
    """
    if not paths.validate_task_name(task_name):
        return {"error": f"Invalid task name: {task_name}", "rejected": True}

    if not paths.validate_document_name(doc_name):
        return {"error": f"Invalid document name: {doc_name}", "rejected": True}

    task_root = paths.get_task_root(repo_root, task_name)
    if not task_root:
        return {"error": f"Task root not found or invalid: {task_name}", "rejected": True}

    if not task_root.exists():
        return {"error": f"Task packet not found: {task_name}", "not_found": True}

    # Check global forbidden paths
    if paths.is_global_forbidden(repo_root, task_root):
        return {"error": f"Path is globally forbidden: {task_name}", "rejected": True}

    file_path = task_root / doc_name
    if not paths.is_safe_path(repo_root, file_path):
        return {"error": f"Path traversal detected: {doc_name}", "rejected": True}

    if not file_path.exists():
        return {"error": f"File not found: {doc_name}", "not_found": True}

    try:
        content = file_path.read_text(encoding="utf-8", errors="replace")
        return {
            "content": content,
            "file": str(file_path.relative_to(repo_root)).replace("\\", "/"),
            "task_name": task_name,
        }
    except Exception as e:
        return {"error": f"Failed to read file: {e}"}


def init_task(
    repo_root: Path,
    task_name: str,
    project_type: str = "_shared",
    task_title: str = "",
) -> Dict[str, Any]:
    """Initialize a new task packet.

    Planner-only: creates the task directory and spec.md skeleton.
    """
    if not paths.validate_task_name(task_name):
        return {"error": f"Invalid task name: {task_name}", "success": False}

    task_root = paths.get_task_root(repo_root, task_name)
    if not task_root:
        return {"error": "Could not resolve task root", "success": False}

    if task_root.exists():
        return {"error": f"Task already exists: {task_name}", "success": False, "exists": True}

    try:
        task_root.mkdir(parents=True, exist_ok=True)
        # Create subdirectories
        (task_root / "claims").mkdir(exist_ok=True)
        (task_root / "reports").mkdir(exist_ok=True)
        (task_root / "work-packages").mkdir(exist_ok=True)

        # Write spec.md skeleton
        spec_content = f"""# {task_title or task_name} — Living Spec

## Quick Status (AI Entry Point)

- **Current Phase**: Plan
- **Last Updated**: {time.strftime('%Y-%m-%d')}
- **Progress**: 0/0 acceptance criteria verified
- **Next Step**: Complete planning and run Plan gate.

## GIVEN

## WHEN

## THEN

## Acceptance Criteria

## Quality Checklist
"""
        (task_root / "spec.md").write_text(spec_content, encoding="utf-8")

        return {
            "success": True,
            "task_name": task_name,
            "task_root": str(task_root.relative_to(repo_root)).replace("\\", "/"),
            "created": time.strftime("%Y-%m-%d %H:%M"),
        }
    except Exception as e:
        return {"error": f"Failed to initialize task: {e}", "success": False}


def write_task_document(
    repo_root: Path,
    task_name: str,
    doc_name: str,
    content: str,
) -> Dict[str, Any]:
    """Write a task document.

    Only allowed document names can be written.
    Overwrite is allowed for existing files.
    """
    if not paths.validate_task_name(task_name):
        return {"error": f"Invalid task name: {task_name}", "success": False}

    if not paths.validate_document_name(doc_name):
        return {"error": f"Invalid document name: {doc_name}", "success": False}

    task_root = paths.get_task_root(repo_root, task_name)
    if not task_root:
        return {"error": "Could not resolve task root", "success": False}

    if not task_root.exists():
        return {"error": f"Task packet not found: {task_name}", "success": False}

    file_path = task_root / doc_name
    if not paths.is_safe_path(repo_root, file_path):
        return {"error": f"Path traversal detected", "success": False}

    try:
        task_root.mkdir(parents=True, exist_ok=True)
        file_path.write_text(content, encoding="utf-8")
        return {
            "success": True,
            "file": str(file_path.relative_to(repo_root)).replace("\\", "/"),
            "written": time.strftime("%Y-%m-%d %H:%M"),
        }
    except Exception as e:
        return {"error": f"Failed to write document: {e}", "success": False}


def check_plan(repo_root: Path = None, task_name: str = "") -> Dict[str, Any]:
    """Run Plan gate via task-guard.ps1.

    Delegates to authoritative script, captures structured evidence.
    """
    if repo_root is None:
        repo_root = paths.get_repo_root()
    if not paths.validate_task_name(task_name):
        return {"error": f"Invalid task name: {task_name}"}

    script_path = repo_root / ".trae" / "scripts" / "task-guard.ps1"
    if not script_path.exists():
        return {"error": "task-guard.ps1 not found"}

    args = _powershell_args(script_path, task_name, "plan")
    result = _run_script(repo_root, args)

    output = result.get("redacted_output", "")
    
    # Parse pass/fail from output
    guard_passed = "ALL GUARDS PASSED" in output or "ready to transition" in output.lower()
    plan_passed = "[PASS]" in output or guard_passed

    return {
        "plan_pass": plan_passed,
        "guard_pass": guard_passed,
        "exit_code": result["exit_code"],
        "evidence": output,
        "error": result.get("error"),
    }


def can_edit(repo_root: Path = None, task_name: str = "") -> Dict[str, Any]:
    """Run Can-Edit check via task-state.ps1.

    Delegates to authoritative script.
    """
    if repo_root is None:
        repo_root = paths.get_repo_root()
    if not paths.validate_task_name(task_name):
        return {"error": f"Invalid task name: {task_name}"}

    script_path = repo_root / ".trae" / "scripts" / "task-state.ps1"
    if not script_path.exists():
        return {"error": "task-state.ps1 not found"}

    args = _powershell_args(script_path, "can-edit", task_name)
    result = _run_script(repo_root, args)

    output = result.get("redacted_output", "")
    
    # Parse can-edit result
    can_edit_passed = (
        result["exit_code"] == 0 and 
        ("not locked" in output.lower() or "can edit" in output.lower() or "true" in output.lower() or not output.strip())
    )
    # If script exits 0 with "PASS" or "can edit", it's good
    if "[PASS]" in output or "ALLOWED" in output:
        can_edit_passed = True

    return {
        "can_edit": can_edit_passed,
        "exit_code": result["exit_code"],
        "evidence": output,
        "error": result.get("error"),
    }

# Alias for test compatibility
check_can_edit = can_edit


def read_work_package(repo_root: Path, task_name: str, wp_id: str) -> Dict[str, Any]:
    """Read a work package and resolve its allowed/forbidden paths."""
    if not paths.validate_task_name(task_name):
        return {"error": f"Invalid task name: {task_name}"}

    if not paths.validate_work_package_id(wp_id):
        return {"error": f"Invalid work package ID: {wp_id}"}

    task_root = paths.get_task_root(repo_root, task_name)
    if not task_root:
        return {"error": "Could not resolve task root"}

    # Find the WP file (pattern: WP02-*.md)
    wp_dir = task_root / "work-packages"
    if not wp_dir.exists():
        return {"error": "Work packages directory not found"}

    wp_file = None
    for f in wp_dir.iterdir():
        if f.is_file() and f.name.startswith(f"{wp_id}-") and f.name.endswith(".md"):
            wp_file = f
            break

    if not wp_file:
        # Try exact match
        for f in wp_dir.iterdir():
            if f.is_file() and wp_id in f.name:
                wp_file = f
                break

    if not wp_file:
        return {"error": f"Work package not found: {wp_id}", "not_found": True}

    try:
        content = wp_file.read_text(encoding="utf-8", errors="replace")
        
        # Parse allowed and forbidden paths from the WP
        allowed_paths = _parse_paths_section(content, "Allowed Paths")
        forbidden_paths = _parse_paths_section(content, "Forbidden Paths")
        
        # Parse verification command
        verification = _parse_verification_command(content)

        return {
            "work_package": wp_id,
            "file": str(wp_file.relative_to(repo_root)).replace("\\", "/"),
            "content": content,
            "allowed_paths": allowed_paths,
            "forbidden_paths": forbidden_paths,
            "verification": verification,
        }
    except Exception as e:
        return {"error": f"Failed to read work package: {e}"}


def _parse_paths_section(content: str, section_name: str) -> List[str]:
    """Parse paths from a markdown section."""
    paths_list = []
    in_section = False
    for line in content.splitlines():
        if f"## {section_name}" in line:
            in_section = True
            continue
        if in_section and line.startswith("## "):
            break
        if in_section:
            stripped = line.strip()
            if stripped.startswith("- `"):
                p = stripped[3:].rstrip("`").strip()
                if p:
                    paths_list.append(p)
    return paths_list


def _parse_verification_command(content: str) -> Optional[str]:
    """Parse verification command from ## Required Verification section."""
    in_section = False
    for line in content.splitlines():
        if "## Required Verification" in line:
            in_section = True
            continue
        if in_section and line.startswith("## "):
            break
        if in_section and line.strip().startswith("- Command:"):
            cmd = line.split("Command:", 1)[1].strip().strip("`")
            return cmd
    return None


def create_claim(
    repo_root: Path,
    task_name: str,
    work_package: str,
    owner: str,
    claimed_paths: List[str],
    scope_in: str = "",
    scope_out: str = "",
) -> Dict[str, Any]:
    """Create a collision-safe claim.

    Refuses to overwrite existing claims.
    """
    if not paths.validate_task_name(task_name):
        return {"error": f"Invalid task name: {task_name}", "success": False}

    if not paths.validate_work_package_id(work_package):
        return {"error": f"Invalid work package ID: {work_package}", "success": False}

    claim_path = paths.get_claim_path(repo_root, task_name, work_package)
    if not claim_path:
        return {"error": "Could not resolve claim path", "success": False}

    # Collision check: refuse overwrite
    if claim_path.exists():
        try:
            existing = claim_path.read_text(encoding="utf-8", errors="replace")
            # Extract owner
            owner_line = [l for l in existing.splitlines() if "Owner model" in l]
            current_owner = owner_line[0].split(":", 1)[-1].strip().strip("`") if owner_line else "unknown"
            return {
                "success": False,
                "collision": True,
                "current_owner": current_owner,
                "claim_path": str(claim_path.relative_to(repo_root)).replace("\\", "/"),
                "error": f"Claim already exists for {work_package}. Owner: {current_owner}",
            }
        except Exception:
            pass

    # Ensure directory exists
    claim_path.parent.mkdir(parents=True, exist_ok=True)

    # Build claim content
    claim_content = f"""# Claim: {owner} {work_package}

Task packet: `.trae/tasks/{task_name}/`
Work package: `work-packages/{work_package}-*.md`
Claimed at: `{time.strftime('%Y-%m-%d %H:%M')}`
Owner model: `{owner}`

## Claimed Paths
"""
    for p in claimed_paths:
        claim_content += f"- `{p}`\n"

    claim_content += f"""
## Scope Boundary
- In scope: {scope_in or 'Implement work package tasks'}
- Out of scope: {scope_out or 'Architecture, verification, other work packages'}

## Expected Report
- `reports/hermes-mcp-{work_package}-result.md`
"""

    try:
        claim_path.write_text(claim_content, encoding="utf-8")
        return {
            "success": True,
            "collision": False,
            "claim_path": str(claim_path.relative_to(repo_root)).replace("\\", "/"),
            "claimed_at": time.strftime("%Y-%m-%d %H:%M"),
        }
    except Exception as e:
        return {"error": f"Failed to write claim: {e}", "success": False}


def read_claim(repo_root: Path, task_name: str, wp_id: str) -> Dict[str, Any]:
    """Read an existing claim file."""
    if not paths.validate_task_name(task_name):
        return {"error": f"Invalid task name: {task_name}"}

    if not paths.validate_work_package_id(wp_id):
        return {"error": f"Invalid WP ID: {wp_id}"}

    claim_path = paths.get_claim_path(repo_root, task_name, wp_id)
    if not claim_path:
        return {"error": "Could not resolve claim path", "exists": False}

    if not claim_path.exists():
        return {"exists": False, "error": "Claim not found"}

    try:
        content = claim_path.read_text(encoding="utf-8", errors="replace")
        owner_line = [l for l in content.splitlines() if "Owner model" in l]
        owner = owner_line[0].split(":", 1)[-1].strip().strip("`") if owner_line else "unknown"
        return {
            "exists": True,
            "owner": owner,
            "path": str(claim_path.relative_to(repo_root)).replace("\\", "/"),
            "content": content,
        }
    except Exception as e:
        return {"error": str(e), "exists": False}


def submit_report(repo_root: Path, report: Dict[str, Any]) -> Dict[str, Any]:
    """Validate and write a worker report.

    Report must pass schema validation.
    Report path is derived from task_name + wp_id.
    """
    if not schemas.validate_report(report):
        return {
            "success": False,
            "error": "Report failed schema validation",
            "validation_details": schemas.validate_report_sections(report) if isinstance(report, dict) else {},
        }

    task_name = report.get("task_packet", "")
    wp_id = report.get("work_package", "")

    # Normalize task name (remove .trae/tasks/ prefix if present)
    if task_name.startswith(".trae/tasks/"):
        task_name = task_name[len(".trae/tasks/"):]
    if task_name.endswith("/"):
        task_name = task_name.rstrip("/")

    if not paths.validate_task_name(task_name):
        return {"error": f"Invalid task name in report: {task_name}", "success": False}

    if not paths.validate_work_package_id(wp_id):
        return {"error": f"Invalid WP ID in report: {wp_id}", "success": False}

    report_path = paths.get_report_path(repo_root, task_name, wp_id)
    if not report_path:
        return {"error": "Could not resolve report path", "success": False}

    report_path.parent.mkdir(parents=True, exist_ok=True)

    # Format report as markdown
    md = f"""# Result: {wp_id}

Task packet: `.trae/tasks/{task_name}/`
Work package: `{wp_id}`
Status: {report.get('status', 'unknown')}

> Implement gate accepts this report only when `Status: done` and `Extra scope taken: no`.

## Changed Files
"""
    for f in report.get("changed_files", []):
        md += f"- `{f}`\n"

    md += "\n## Commands Run\n| Command | Result | Notes |\n|---|---|---|\n"
    for cmd in report.get("commands_run", []):
        if isinstance(cmd, dict):
            md += f"| `{cmd.get('command', '')}` | {cmd.get('result', '')} | {cmd.get('notes', '')} |\n"
        else:
            md += f"| `{cmd}` | - | - |\n"

    md += "\n## Acceptance Criteria Touched\n"
    for ac, result_val in report.get("acceptance_criteria", {}).items():
        md += f"- {ac}: {result_val}\n"

    md += f"""
## Scope Control
- Extra scope taken: {report.get('extra_scope_taken', 'no')}
- Forbidden paths touched: {report.get('forbidden_paths_touched', 'no')}
- Architecture decisions changed: {report.get('architecture_decisions_changed', 'no')}

## Unresolved Risks
"""
    for risk in report.get("unresolved_risks", ["None"]):
        md += f"- {risk}\n"

    try:
        report_path.write_text(md, encoding="utf-8")
        return {
            "success": True,
            "report_path": str(report_path.relative_to(repo_root)).replace("\\", "/"),
            "status": report.get("status"),
            "written": time.strftime("%Y-%m-%d %H:%M"),
        }
    except Exception as e:
        return {"error": f"Failed to write report: {e}", "success": False}


def run_verify(repo_root: Path, task_name: str) -> Dict[str, Any]:
    """Run verification commands for a task.

    Does NOT self-declare pass. Returns evidence only.
    """
    if not paths.validate_task_name(task_name):
        return {"error": f"Invalid task name: {task_name}"}

    task_root = paths.get_task_root(repo_root, task_name)
    if not task_root or not task_root.exists():
        return {"error": f"Task not found: {task_name}"}

    results = []
    
    # Run pytest if test file exists
    test_file = repo_root / ".trae" / "hermes" / "tests" / "test_workflow_mcp.py"
    if test_file.exists():
        venv_python = repo_root / ".tools" / "hermes-worker" / "hermes-agent" / "venv" / "Scripts" / "python.exe"
        if venv_python.exists():
            test_args = [
                str(venv_python), "-m", "pytest",
                str(test_file), "-q", "--tb=short",
            ]
            test_result = _run_script(repo_root, test_args, timeout=120)
            results.append({
                "type": "unit_test",
                "command": f"pytest {test_file.name}",
                "exit_code": test_result["exit_code"],
                "evidence": test_result.get("redacted_output", ""),
                "error": test_result.get("error"),
            })

    # Task guard verify (not self-declared)
    script_path = repo_root / ".trae" / "scripts" / "task-guard.ps1"
    if script_path.exists():
        args = _powershell_args(script_path, task_name, "verify")
        guard_result = _run_script(repo_root, args)
        results.append({
            "type": "task_guard_verify",
            "command": f"task-guard.ps1 {task_name} verify",
            "exit_code": guard_result["exit_code"],
            "evidence": guard_result.get("redacted_output", ""),
            "error": guard_result.get("error"),
        })

    return {
        "task_name": task_name,
        "results": results,
        "verification_pass": None,  # NEVER self-declare pass
        "note": "Verification evidence collected. Lead must independently review.",
    }
