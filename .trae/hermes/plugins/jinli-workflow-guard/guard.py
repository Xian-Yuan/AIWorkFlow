"""Core guard logic for jinli-workflow-guard.

Provides fail-closed mutation authorization based on:
- Explicit launch environment variables (JINLI_ROLE, JINLI_TASK_NAME,
  JINLI_WORK_PACKAGE, UEGAMEDEV_ROOT)
- Work-package Allowed/Forbidden path resolution
- Role-specific mutation policies (Planner/Implementer/Verifier)

Never infers authorization from conversation text.
"""

import os
import re
import pathlib
from typing import Optional, List, Dict, Any, Tuple

# ──────────────────────────────────────────────────
# Role constants
# ──────────────────────────────────────────────────

ROLE_PLANNER = "planner"
ROLE_IMPLEMENTER = "implementer"
ROLE_VERIFIER = "verifier"

VALID_ROLES = {ROLE_PLANNER, ROLE_IMPLEMENTER, ROLE_VERIFIER}

Role = str


# ──────────────────────────────────────────────────
# Tool classification
# ──────────────────────────────────────────────────

# Tools that mutate the filesystem or state
MUTATION_TOOLS = {
    "write", "write_file",
    "edit", "patch",
    "bash", "terminal", "execute_command",
    "task",  # launches subagents
    "jinli-soul-core_growth_approve",
    "jinli-soul-core_growth_rollback",
}

# Specific bash-like tools that could mutate
MUTATION_TOOL_PREFIXES = (
    "write", "edit", "patch", "bash", "terminal",
)

# Tools that are always read-only (safe for diagnosis)
READ_ONLY_TOOLS = {
    "read", "glob", "grep",
    "list_files", "list_directory",
    "webfetch",
    "context7_query-docs",
    "context7_resolve-library-id",
    "jinli-soul-core_soul_check",
    "jinli-soul-core_soul_discover",
    "jinli-soul-core_soul_emotion",
    "jinli-soul-core_soul_memory",
    "jinli-soul-core_soul_status",
    "jinli-soul-core_response_plan",
    "jinli-soul-core_soul_auto",
    "jinli-soul-core_vision_status",
    "skill",
    "search", "find", "cat",
}


def is_mutation_tool(tool_name: str) -> bool:
    """Returns True if the tool can mutate filesystem or state."""
    if not tool_name:
        return False
    name_lower = tool_name.lower()
    if name_lower in MUTATION_TOOLS:
        return True
    if name_lower.startswith("jinli-soul-core_growth_"):
        return True
    return False


def is_read_only_tool(tool_name: str) -> bool:
    """Returns True if the tool is safe and read-only."""
    if not tool_name:
        return True  # unknown tools: be safe, but allow read classification
    name_lower = tool_name.lower()
    if name_lower in READ_ONLY_TOOLS:
        return True
    if is_mutation_tool(tool_name):
        return False
    # Unknown tools: classify as potentially mutating (fail-safe)
    return False


# ──────────────────────────────────────────────────
# Path utilities
# ──────────────────────────────────────────────────

def normalize_path(path: str) -> str:
    """Normalize a path: resolve separators to forward slash, strip trailing slashes."""
    if not path:
        return ""
    # Convert backslashes to forward slashes
    normalized = path.replace("\\", "/")
    # Remove redundant slashes
    while "//" in normalized:
        normalized = normalized.replace("//", "/")
    # Strip trailing slash unless it's a root
    if len(normalized) > 1 and normalized.endswith("/"):
        normalized = normalized[:-1]
    return normalized


def _contains_traversal(path: str) -> bool:
    """Check if a path contains '..' traversal segments."""
    parts = normalize_path(path).split("/")
    return ".." in parts


def matches_glob_pattern(file_path: str, pattern: str) -> bool:
    """Check if a file path matches a glob pattern.

    Supports:
    - ** for recursive matching
    - * for single-segment matching
    - Exact path matching
    - Windows path normalization
    - Traversal rejection
    """
    if not file_path or not pattern:
        return False

    # Reject traversal attempts
    if _contains_traversal(file_path):
        return False

    file_path = normalize_path(file_path)
    pattern = normalize_path(pattern)

    # Exact match
    if file_path == pattern:
        return True

    # Pattern with **
    if "**" in pattern:
        prefix = pattern.split("**")[0].rstrip("/")
        if prefix:
            # The file path must start with the prefix
            if not file_path.startswith(prefix):
                return False
            # After the prefix, the remaining part must start with /
            remaining = file_path[len(prefix):]
            if remaining and not remaining.startswith("/"):
                return False
            return True
        else:
            # Pattern starts with **, matches everything (but that would be unusual)
            return True

    # Pattern with single *
    if "*" in pattern:
        pattern_parts = pattern.split("/")
        file_parts = file_path.split("/")

        if len(pattern_parts) != len(file_parts) and "**" not in pattern:
            return False

        for pp, fp in zip(pattern_parts, file_parts):
            if pp == "*":
                continue
            if pp != fp:
                return False
        return True

    # Suffix match (path ends with pattern)
    if file_path.endswith("/" + pattern) or file_path == pattern:
        return True

    return False


def _resolve_glob_to_absolute(pattern: str, root: pathlib.Path) -> str:
    """Resolve a glob pattern to an absolute path prefix.

    Removes **/* parts and returns the base directory.
    """
    pattern = normalize_path(pattern)
    # Strip ** and everything after it
    if "**" in pattern:
        pattern = pattern.split("**")[0].rstrip("/")
    if pattern.endswith("/*"):
        pattern = pattern[:-2]
    # Remove leading ./ if present
    if pattern.startswith("./"):
        pattern = pattern[2:]
    return str(root / pattern)


def resolve_allowed_paths(patterns: List[str], root: pathlib.Path) -> List[str]:
    """Resolve allowed path patterns to absolute paths."""
    result = []
    for p in patterns:
        p = normalize_path(p)
        resolved = _resolve_glob_to_absolute(p, root)
        result.append(resolved)
    return result


def resolve_forbidden_paths(patterns: List[str], root: pathlib.Path) -> List[str]:
    """Resolve forbidden path patterns to absolute paths."""
    return resolve_allowed_paths(patterns, root)


def check_path_allowed(file_path: str, allowed_abs_patterns: List[str], root: pathlib.Path) -> bool:
    """Check if a file path is within any allowed pattern."""
    if not allowed_abs_patterns:
        return False

    file_path = normalize_path(file_path)
    # Convert to absolute if relative
    if not os.path.isabs(file_path):
        file_path = str(root / file_path)
    file_path = normalize_path(file_path)
    root_str = normalize_path(str(root))

    for pattern_base in allowed_abs_patterns:
        pattern_base = normalize_path(pattern_base)
        if file_path.startswith(pattern_base):
            return True
        # Also check if the file path matches the original glob
        rel_path = file_path
        if file_path.startswith(root_str):
            rel_path = file_path[len(root_str):].lstrip("/")

        # Try matching relative path against the pattern prefix
        # (the pattern_base is the resolved directory prefix)
        # For ** patterns, check if file is under that directory
        if file_path.startswith(pattern_base.rstrip("/") + "/") or file_path == pattern_base.rstrip("/"):
            return True

    return False


def check_path_forbidden(file_path: str, forbidden_abs_patterns: List[str], root: pathlib.Path) -> bool:
    """Check if a file path is within any forbidden pattern.

    Returns True if the path IS forbidden.
    """
    if not forbidden_abs_patterns:
        return False
    # Reuse the same logic as allowed check
    return check_path_allowed(file_path, forbidden_abs_patterns, root)


# ──────────────────────────────────────────────────
# Context parsing from environment
# ──────────────────────────────────────────────────

def get_environment_context() -> Dict[str, Any]:
    """Read role, task, and work package from explicit environment variables.

    Returns a dict with keys: role, task_name, work_package, root.
    Values may be None if not set.
    """
    role = os.environ.get("JINLI_ROLE", "").strip().lower() or None
    task_name = os.environ.get("JINLI_TASK_NAME", "").strip() or None
    work_package = os.environ.get("JINLI_WORK_PACKAGE", "").strip() or None
    root_str = os.environ.get("UEGAMEDEV_ROOT", "").strip() or os.getcwd()

    # Validate role
    if role and role not in VALID_ROLES:
        role = None  # Invalid role treated as None (fail-closed)

    # Validate task name (must not contain traversal)
    if task_name and _contains_traversal(task_name):
        task_name = None  # Malformed task = fail-closed

    # Validate work package format (WP followed by digits)
    if work_package and not re.match(r'^WP\d+$', work_package, re.IGNORECASE):
        work_package = None

    return {
        "role": role,
        "task_name": task_name,
        "work_package": work_package,
        "root": pathlib.Path(root_str),
    }


# ──────────────────────────────────────────────────
# Role-specific mutation validation
# ──────────────────────────────────────────────────

# Planner allowed patterns (may write to task design documents)
PLANNER_ALLOWED_PATTERNS = [
    ".trae/tasks/**",
    ".opencode/tasks/**",
    "Docs/superpowers/specs/**",
    "Docs/superpowers/plans/**",
    "Docs/AI/**",
]

# Planner forbidden patterns (must not write to)
PLANNER_FORBIDDEN_PATTERNS = [
    "Project/**",
    ".trae/scripts/**",
    ".opencode/scripts/**",
    ".tools/hermes-worker/hermes-agent/**",
    "skills/**",
]


def is_task_document_path(file_path: str, root: pathlib.Path) -> bool:
    """Check if a path is a task document path (spec, analysis, tasks, routing, doc-impact)."""
    file_path = normalize_path(file_path)
    rel_path = file_path
    root_str = normalize_path(str(root))
    if file_path.startswith(root_str):
        rel_path = file_path[len(root_str):].lstrip("/")

    task_doc_patterns = [
        ".trae/tasks/",
        ".opencode/tasks/",
        "Docs/superpowers/specs/",
        "Docs/superpowers/plans/",
        "Docs/AI/",
    ]
    for pattern in task_doc_patterns:
        if rel_path.startswith(pattern):
            return True
    return False


def extract_file_paths_from_args(tool_name: str, args: Optional[Dict]) -> List[str]:
    """Extract file path arguments from tool arguments.

    Handles various tool argument formats:
    - write/edit: filePath
    - bash: command (extracts any path-like args)
    """
    if not args:
        return []

    paths = []
    # Primary file path
    for key in ("filePath", "file_path", "path", "file"):
        if key in args and isinstance(args[key], str):
            paths.append(args[key])

    # For edit tool, oldString/newString don't contain paths
    # For bash, extract paths from command if possible (best-effort)
    if tool_name in ("bash", "terminal", "execute_command"):
        command = args.get("command", "")
        if command:
            # Best effort: look for the workdir or explicit path args
            if "workdir" in args and isinstance(args["workdir"], str):
                paths.append(args["workdir"])

    return paths


def validate_planner_mutation(
    tool_name: str,
    tool_args: Optional[Dict],
    allowed_paths: List[str],
    forbidden_paths: List[str],
    root: pathlib.Path,
) -> Dict[str, str]:
    """Validate a Planner mutation request.

    Planner may:
    - Use read-only tools anywhere
    - Write to task design documents
    - NOT write to Project/**, .trae/scripts/**, skills/**
    """
    # Read-only tools: always allowed
    if is_read_only_tool(tool_name):
        return {"action": "allow", "message": ""}

    # For mutation tools, check file paths
    file_paths = extract_file_paths_from_args(tool_name, tool_args)
    if not file_paths:
        return {"action": "block", "message": "Planner: cannot determine target path for mutation"}

    # Resolve forbidden patterns
    planner_forbidden = resolve_forbidden_paths(
        PLANNER_FORBIDDEN_PATTERNS + forbidden_paths, root
    )

    for fp in file_paths:
        if _contains_traversal(fp):
            return {"action": "block", "message": "Planner: path traversal detected"}
        if check_path_forbidden(fp, planner_forbidden, root):
            return {"action": "block", "message": f"Planner: path '{fp}' is in forbidden scope"}
        if not is_task_document_path(fp, root):
            return {"action": "block", "message": f"Planner: '{fp}' is not a task design document. Planner may only write to task documents and design specs."}

    return {"action": "allow", "message": ""}


def validate_implementer_mutation(
    tool_name: str,
    tool_args: Optional[Dict],
    task_name: Optional[str],
    work_package: Optional[str],
    allowed_paths: List[str],
    forbidden_paths: List[str],
    root: pathlib.Path,
) -> Dict[str, str]:
    """Validate an Implementer mutation request.

    Implementer requires:
    - Valid task name
    - Valid work package
    - File paths within Allowed Paths
    - File paths NOT in Forbidden Paths
    """
    # Read-only tools: always allowed for diagnosis
    if is_read_only_tool(tool_name):
        return {"action": "allow", "message": ""}

    # Validate context
    if not task_name:
        return {"action": "block", "message": "Implementer: missing task name. Set JINLI_TASK_NAME."}
    if not work_package:
        return {"action": "block", "message": "Implementer: missing work package. Set JINLI_WORK_PACKAGE."}

    # For mutation tools, check file paths
    file_paths = extract_file_paths_from_args(tool_name, tool_args)
    if not file_paths:
        return {"action": "block", "message": "Implementer: cannot determine target path for mutation"}

    # Resolve paths
    resolved_allowed = resolve_allowed_paths(allowed_paths, root)
    resolved_forbidden = resolve_forbidden_paths(forbidden_paths, root)

    for fp in file_paths:
        # Reject traversal
        if _contains_traversal(fp):
            return {"action": "block", "message": "Implementer: path traversal detected"}

        # Forbidden paths win (check first)
        if check_path_forbidden(fp, resolved_forbidden, root):
            return {"action": "block", "message": f"Implementer: path '{fp}' is in forbidden scope"}

        # Must be in allowed paths
        if not check_path_allowed(fp, resolved_allowed, root):
            return {"action": "block", "message": f"Implementer: path '{fp}' is not in work-package Allowed Paths"}

    return {"action": "allow", "message": ""}


def validate_verifier_mutation(
    tool_name: str,
    tool_args: Optional[Dict],
    root: pathlib.Path,
) -> Dict[str, str]:
    """Validate a Verifier mutation request.

    Verifier is read-only except:
    - verification-report.md (and approved verification state updates)
    """
    # Read-only tools: always allowed
    if is_read_only_tool(tool_name):
        return {"action": "allow", "message": ""}

    # Verifier can only write to verification-report.md
    file_paths = extract_file_paths_from_args(tool_name, tool_args)
    if not file_paths:
        return {"action": "block", "message": "Verifier: cannot determine target path for mutation"}

    for fp in file_paths:
        if _contains_traversal(fp):
            return {"action": "block", "message": "Verifier: path traversal detected"}

        normalized = normalize_path(fp)
        if not normalized.endswith("verification-report.md"):
            return {"action": "block", "message": f"Verifier: may only write to verification-report.md, got '{fp}'"}

    return {"action": "allow", "message": ""}


# ──────────────────────────────────────────────────
# Main authorization entry point
# ──────────────────────────────────────────────────

def authorize_mutation(
    role: Optional[str],
    task_name: Optional[str],
    work_package: Optional[str],
    tool_name: str,
    tool_args: Optional[Dict],
    allowed_paths: List[str],
    forbidden_paths: List[str],
    root: pathlib.Path,
) -> Dict[str, str]:
    """Main entry point for mutation authorization.

    Returns {"action": "allow", "message": ""} or
            {"action": "block", "message": "reason"}.

    Fail-closed: any missing or malformed context blocks mutation.
    Read-only tools bypass all checks for diagnosis.
    """
    # Read-only tools bypass all checks
    if is_read_only_tool(tool_name):
        return {"action": "allow", "message": ""}

    # Validate role
    if not role or role not in VALID_ROLES:
        return {"action": "block", "message": f"Missing or invalid role: '{role}'. Set JINLI_ROLE to one of: {', '.join(sorted(VALID_ROLES))}"}

    # Validate task name (for implementer - malformed task is blocked)
    if task_name and _contains_traversal(task_name):
        return {"action": "block", "message": f"Malformed task name: '{task_name}'"}

    # Route to role-specific validator
    if role == ROLE_PLANNER:
        return validate_planner_mutation(
            tool_name, tool_args, allowed_paths, forbidden_paths, root
        )
    elif role == ROLE_IMPLEMENTER:
        return validate_implementer_mutation(
            tool_name, tool_args, task_name, work_package,
            allowed_paths, forbidden_paths, root
        )
    elif role == ROLE_VERIFIER:
        return validate_verifier_mutation(
            tool_name, tool_args, root
        )

    # Fallthrough: unknown role
    return {"action": "block", "message": f"Unknown role: '{role}'"}


# ──────────────────────────────────────────────────
# Convenience wrappers for test and direct use
# ──────────────────────────────────────────────────

def authorize_tool(ctx: Dict[str, Any], tool_name: str, tool_args: Optional[Dict] = None) -> Dict[str, str]:
    """Convenience entry point for tests and direct invocation.

    Args:
        ctx: Context dict with keys: role, task_name, work_package, repo_root
        tool_name: Name of the tool being called
        tool_args: Tool arguments dict (optional)

    Returns:
        {"action": "allow"|"block", "message": "..."}
    """
    role = ctx.get("role")
    task_name = ctx.get("task_name")
    work_package = ctx.get("work_package")
    root = ctx.get("repo_root", ctx.get("root", os.getcwd()))
    if isinstance(root, str):
        root = pathlib.Path(root)

    # Read-only tools: always allow
    if is_read_only_tool(tool_name):
        return {"action": "allow", "message": ""}

    allowed_paths = ctx.get("allowed_paths", [])
    forbidden_paths = ctx.get("forbidden_paths", [])

    return authorize_mutation(
        role=role,
        task_name=task_name,
        work_package=work_package,
        tool_name=tool_name,
        tool_args=tool_args,
        allowed_paths=allowed_paths,
        forbidden_paths=forbidden_paths,
        root=root,
    )


def check_path_scope(file_path: str, allowed: List[str], forbidden: List[str], root: Optional[pathlib.Path] = None) -> bool:
    """Check if a file path is within allowed scope and not forbidden.

    Args:
        file_path: The file path to check
        allowed: List of allowed glob patterns
        forbidden: List of forbidden glob patterns
        root: Repository root (defaults to cwd)

    Returns:
        True if the path is allowed (in allowed AND not in forbidden)
    """
    if root is None:
        root = pathlib.Path(os.getcwd())

    if _contains_traversal(file_path):
        return False

    resolved_allowed = resolve_allowed_paths(allowed, root)
    resolved_forbidden = resolve_forbidden_paths(forbidden, root)

    # Forbidden wins
    if check_path_forbidden(file_path, resolved_forbidden, root):
        return False

    # Must be in allowed
    if not check_path_allowed(file_path, resolved_allowed, root):
        return False

    return True
