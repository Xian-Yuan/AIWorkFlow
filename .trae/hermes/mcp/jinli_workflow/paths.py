"""Path validation, traversal rejection, and secret redaction."""

import os
import re
from pathlib import Path, PurePath
from typing import Optional


# Task packet document names allowed for reading/writing
ALLOWED_DOCUMENT_NAMES = {
    "spec.md", "tasks.md", "routing.md", "analysis.md",
    "doc-impact.md", "spec-living.md", "verification-report.md",
}

# Task name pattern: _shared/YYYY-MM-DD-name or project/name
TASK_NAME_PATTERN = re.compile(r"^[a-zA-Z0-9_\-]+/[a-zA-Z0-9_\-/.]+$")

# Work package ID pattern
WP_ID_PATTERN = re.compile(r"^WP\d{2,3}$")

# Document name pattern (no traversal, no absolute paths)
DOC_NAME_PATTERN = re.compile(r"^[a-zA-Z0-9_\-][a-zA-Z0-9_\-.]*$")

# Secret patterns to redact
SECRET_PATTERNS = [
    (re.compile(r'(?:api[_-]?key|apikey|API_KEY|secret|token|password|credential)s?\s*[:=]\s*["\']?([^\s"\']+)', re.IGNORECASE), r'\1'),
    (re.compile(r'(?:Authorization|Bearer)\s+["\']?([^\s"\']+)', re.IGNORECASE), r'\1'),
    (re.compile(r'(?:sk-|ghp_|gho_|github_pat_|hf_|xox[bprs]-)[a-zA-Z0-9_\-]+'), r'[REDACTED]'),
]

# Paths that are globally forbidden regardless of work package
GLOBAL_FORBIDDEN = {
    "Project",
    ".tools/hermes-worker/hermes-agent",
    ".trae/scripts/task-state.ps1",
    ".trae/scripts/task-guard.ps1",
    ".trae/scripts/doc-guard.ps1",
    ".git",
}


def get_repo_root() -> Path:
    """Get the repository root from environment or default."""
    root = os.environ.get("UEGAMEDEV_ROOT", r"E:\UEGameDevelopment")
    return Path(root).resolve()


def is_safe_path(repo_root: Path, target: Path) -> bool:
    """Check if target path is safely within repo_root."""
    if not target or str(target).strip() == "":
        return False
    # Reject null bytes
    if "\0" in str(target):
        return False
    try:
        # Resolve path relative to repo_root
        if target.is_absolute():
            resolved = target.resolve()
        else:
            resolved = (repo_root / target).resolve()
        # Check containment
        repo_resolved = repo_root.resolve()
        try:
            resolved.relative_to(repo_resolved)
            return True
        except ValueError:
            return False
    except (OSError, ValueError, RuntimeError):
        return False


def is_global_forbidden(repo_root: Path, target: Path) -> bool:
    """Check if a path hits a globally forbidden area."""
    try:
        if target.is_absolute():
            relative = str(target.relative_to(repo_root)).replace("\\", "/")
        else:
            relative = str(target).replace("\\", "/")
    
        relative = relative.lstrip("/")
        for forbidden in GLOBAL_FORBIDDEN:
            f = forbidden.rstrip("/").rstrip("\\")
            if relative == f or relative.startswith(f + "/") or relative.startswith(f + "\\"):
                return True
        return False
    except ValueError:
        return True  # Outside repo = forbidden


def validate_task_name(name: str) -> bool:
    """Validate a task name (no traversal, valid format)."""
    if not name or not isinstance(name, str):
        return False
    if "\0" in name:
        return False
    # Reject traversal characters
    if ".." in name:
        return False
    if "\\" in name:
        return False  # All forward slashes for cross-platform
    # Check pattern
    parts = name.split("/")
    if len(parts) < 2:
        return False
    for part in parts:
        if not part or part == "." or part == "..":
            return False
        if not re.match(r"^[a-zA-Z0-9_\-][a-zA-Z0-9_\-.]*$", part):
            return False
    return True


def validate_work_package_id(wp_id: str) -> bool:
    """Validate work package ID format."""
    if not wp_id or not isinstance(wp_id, str):
        return False
    return bool(WP_ID_PATTERN.match(wp_id))


def validate_document_name(name: str) -> bool:
    """Validate document name (no traversal)."""
    if not name or not isinstance(name, str):
        return False
    if "\0" in name:
        return False
    if ".." in name:
        return False
    if "/" in name or "\\" in name:
        return False
    return bool(DOC_NAME_PATTERN.match(name))


def get_task_root(repo_root: Path, task_name: str) -> Optional[Path]:
    """Resolve task root directory path."""
    if not validate_task_name(task_name):
        return None
    task_path = repo_root / ".trae" / "tasks" / task_name
    if not is_safe_path(repo_root, task_path):
        return None
    return task_path


def get_claim_path(repo_root: Path, task_name: str, wp_id: str) -> Optional[Path]:
    """Resolve claim file path for a work package."""
    if not validate_task_name(task_name) or not validate_work_package_id(wp_id):
        return None
    task_root = get_task_root(repo_root, task_name)
    if not task_root:
        return None
    claim_path = task_root / "claims" / f"hermes-mcp-{wp_id}.md"
    if not is_safe_path(repo_root, claim_path):
        return None
    return claim_path


def get_report_path(repo_root: Path, task_name: str, wp_id: str) -> Optional[Path]:
    """Resolve report file path for a work package."""
    if not validate_task_name(task_name) or not validate_work_package_id(wp_id):
        return None
    task_root = get_task_root(repo_root, task_name)
    if not task_root:
        return None
    report_path = task_root / "reports" / f"hermes-mcp-{wp_id}-result.md"
    if not is_safe_path(repo_root, report_path):
        return None
    return report_path


def get_work_package_path(repo_root: Path, task_name: str, wp_id: str) -> Optional[Path]:
    """Resolve work package file path."""
    if not validate_task_name(task_name) or not validate_work_package_id(wp_id):
        return None
    task_root = get_task_root(repo_root, task_name)
    if not task_root:
        return None
    wp_path = task_root / "work-packages" / f"{wp_id}-*.md"
    return wp_path


def is_under_root(repo_root: str, target: str) -> bool:
    """Check if target path is safely under repo_root. Accepts string args."""
    if not target:
        return False
    try:
        root = Path(repo_root).resolve()
        t = Path(target).resolve()
        t.relative_to(root)
        return True
    except (ValueError, OSError):
        return False


def validate_task_path(name: str) -> bool:
    """Alias for validate_task_name - rejects traversal."""
    return validate_task_name(name)


def resolve_path(repo_root: Path, rel: str) -> Optional[Path]:
    """Resolve a relative path under repo_root."""
    if not rel:
        return None
    try:
        target = repo_root / rel
        if is_safe_path(repo_root, target):
            return target.resolve()
        return None
    except Exception:
        return None


def list_task_packets(repo_root = None) -> list[dict]:
    """List all task packets under .trae/tasks. Accepts str or Path."""
    if isinstance(repo_root, str):
        repo_root = Path(repo_root)
    if repo_root is None:
        repo_root = get_repo_root()
    
    tasks_dir = repo_root / ".trae" / "tasks"
    if not tasks_dir.exists():
        return []
    
    packets = []
    for project_dir in tasks_dir.iterdir():
        if not project_dir.is_dir():
            continue
        if project_dir.name == "_shared":
            # Shared tasks: scan directly
            for task_dir in project_dir.iterdir():
                if task_dir.is_dir() and (task_dir / "spec.md").exists():
                    packets.append(_describe_task(repo_root, f"_shared/{task_dir.name}", task_dir))
        else:
            # Project tasks
            for task_dir in project_dir.iterdir():
                if task_dir.is_dir() and (task_dir / "spec.md").exists():
                    packets.append(_describe_task(repo_root, f"{project_dir.name}/{task_dir.name}", task_dir))
    return packets


def _describe_task(repo_root: Path, name: str, path: Path) -> dict:
    """Build a task description dict."""
    spec_path = path / "spec.md"
    phase = "unknown"
    title = name
    if spec_path.exists():
        try:
            content = spec_path.read_text(encoding="utf-8", errors="replace")
            for line in content.splitlines():
                if "Current Phase" in line:
                    phase = line.split(":")[-1].strip().strip("*").strip()
                if line.startswith("# ") and "Spec" not in line and title == name:
                    title = line.lstrip("# ").strip()
        except Exception:
            pass
    
    task_files = []
    for f in path.iterdir():
        if f.is_file() and f.suffix == ".md":
            task_files.append(f.name)
    
    return {
        "name": name,
        "title": title,
        "phase": phase,
        "path": str(path.relative_to(repo_root)).replace("\\", "/"),
        "files": task_files,
    }


def redact_secrets(text: str) -> str:
    """Redact secrets from text output."""
    if not text:
        return text
    
    result = text
    
    # Pattern-based redaction for known API key formats
    result = re.sub(
        r'(?:api[_-]?key|apikey|API_KEY)\s*[:=]\s*["\']?\K[^\s"\']+',
        '[REDACTED]',
        result,
        flags=re.IGNORECASE,
    )
    result = re.sub(
        r'(?:Authorization|Bearer)\s+\K[^\s"\']+',
        '[REDACTED]',
        result,
        flags=re.IGNORECASE,
    )
    # Known token prefixes
    result = re.sub(
        r'(?:sk-|ghp_|gho_|github_pat_|hf_|xox[bprs]-)[a-zA-Z0-9_\-]+',
        '[REDACTED]',
        result,
    )
    # Generic secret/credential patterns
    result = re.sub(
        r'(?:secret|token|password|credential)\s*[:=]\s*["\']?\K[^\s"\']+',
        '[REDACTED]',
        result,
        flags=re.IGNORECASE,
    )
    
    return result
