"""Secret-safe audit recording for jinli-workflow-guard.

Provides:
- Secret redaction from tool arguments, results, and context
- Structured AuditRecord for tracking tool calls and authorization decisions
- No credential values, tokens, API keys, or authorization headers in audit output
"""

import re
import json
import copy
from typing import Optional, Dict, Any, List


# ──────────────────────────────────────────────────
# Secret detection patterns
# ──────────────────────────────────────────────────

# Patterns that match credential-like values
_SECRET_PATTERNS = [
    # API keys (OpenAI, Anthropic, etc.)
    (re.compile(r'sk-[A-Za-z0-9-_]{20,}'), '[REDACTED_API_KEY]'),
    (re.compile(r'sk-proj-[A-Za-z0-9-_]{20,}'), '[REDACTED_API_KEY]'),
    (re.compile(r'sk-ant-[A-Za-z0-9-_]{20,}'), '[REDACTED_API_KEY]'),

    # JWT tokens
    (re.compile(r'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'), '[REDACTED_JWT]'),

    # Bearer tokens
    (re.compile(r'Bearer\s+([A-Za-z0-9_\-\.=]{20,})'), 'Bearer [REDACTED_TOKEN]'),

    # GitHub tokens
    (re.compile(r'ghp_[A-Za-z0-9]{30,}'), '[REDACTED_GH_TOKEN]'),
    (re.compile(r'gho_[A-Za-z0-9]{30,}'), '[REDACTED_GH_TOKEN]'),
    (re.compile(r'ghu_[A-Za-z0-9]{30,}'), '[REDACTED_GH_TOKEN]'),
    (re.compile(r'ghs_[A-Za-z0-9]{30,}'), '[REDACTED_GH_TOKEN]'),
    (re.compile(r'ghr_[A-Za-z0-9]{30,}'), '[REDACTED_GH_TOKEN]'),

    # Discord bot tokens (base64-like pattern with dots)
    (re.compile(r'[A-Za-z0-9_-]{24,}\.[A-Za-z0-9_-]{6,}\.[A-Za-z0-9_-]{27,}'), '[REDACTED_DISCORD_TOKEN]'),

    # Generic password=value or token=value patterns
    (re.compile(r'(?:password|passwd|pwd|secret|token|api_key|apikey|auth)\s*[=:]\s*["\']?([^\s"\'\,;\}]{8,})', re.IGNORECASE),
     lambda m: f'{m.group(0).split("=")[0].split(":")[0]}=[REDACTED]'),

    # Authorization headers
    (re.compile(r'(?:Authorization|X-API-Key|api-key)\s*[=:]\s*["\']?([^\s"\'\,;\}]{8,})', re.IGNORECASE),
     lambda m: f'{m.group(0).split("=")[0].split(":")[0]}=[REDACTED]'),

    # Environment variable assignments with secrets
    (re.compile(r'(?:DISCORD_TOKEN|TELEGRAM_BOT_TOKEN|SLACK_BOT_TOKEN|HERMES_API_KEY)\s*=\s*["\']?([^\s"\']{8,})', re.IGNORECASE),
     lambda m: f'{m.group(0).split("=")[0]}=[REDACTED]'),
]

# Keys in dictionaries that likely contain secrets
_SECRET_KEYS = {
    "api_key", "apikey", "api_secret", "secret", "password", "passwd", "pwd",
    "token", "access_token", "refresh_token", "auth_token", "bearer_token",
    "authorization", "private_key", "credential", "credentials",
    "discord_token", "telegram_token", "slack_token",
}

# Keys whose values should be recursively sanitized
_SANITIZE_RECURSIVE_KEYS = {
    "env", "environment", "headers", "auth", "credentials", "secrets",
}


def redact_secrets(text: str) -> str:
    """Redact secret patterns from a text string.

    Returns the text with credential-like values replaced by placeholders.
    """
    if not text or not isinstance(text, str):
        return text if text is not None else ""

    result = text
    for pattern, replacement in _SECRET_PATTERNS:
        if callable(replacement):
            result = pattern.sub(replacement, result)
        else:
            result = pattern.sub(replacement, result)

    return result


def _redact_dict_secrets(data: Dict[str, Any], depth: int = 0) -> Dict[str, Any]:
    """Recursively redact secrets from dictionary values."""
    if depth > 10:
        return data

    result = {}
    for key, value in data.items():
        key_lower = key.lower()

        # Skip keys that are known to contain secrets
        if key_lower in _SECRET_KEYS:
            result[key] = "[REDACTED]"
            continue

        # Recursively sanitize known container keys
        if key_lower in _SANITIZE_RECURSIVE_KEYS and isinstance(value, dict):
            result[key] = _redact_dict_secrets(value, depth + 1)
        elif isinstance(value, dict):
            result[key] = _redact_dict_secrets(value, depth + 1)
        elif isinstance(value, list):
            result[key] = [
                _redact_dict_secrets(v, depth + 1) if isinstance(v, dict)
                else redact_secrets(str(v)) if isinstance(v, str)
                else v
                for v in value
            ]
        elif isinstance(value, str):
            result[key] = redact_secrets(value)
        else:
            result[key] = value

    return result


def sanitize_for_audit(data: Any) -> Any:
    """Deep sanitize data for audit recording.

    Removes secrets from any data structure (dicts, lists, strings).
    """
    if data is None:
        return None
    if isinstance(data, str):
        return redact_secrets(data)
    if isinstance(data, dict):
        return _redact_dict_secrets(copy.deepcopy(data))
    if isinstance(data, list):
        return [sanitize_for_audit(item) for item in data]
    if isinstance(data, (int, float, bool)):
        return data
    return redact_secrets(str(data))


# ──────────────────────────────────────────────────
# Audit Record
# ──────────────────────────────────────────────────

class AuditRecord:
    """A single audit record for a tool call or authorization decision."""

    def __init__(
        self,
        event: str,
        tool_name: str,
        role: Optional[str],
        task_name: Optional[str],
        work_package: Optional[str],
        decision: str,
        reason: str,
        timestamp: str,
        tool_args: Optional[Dict] = None,
        tool_result: Optional[str] = None,
        session_id: Optional[str] = None,
        duration_ms: Optional[int] = None,
    ):
        self.event = event
        self.tool_name = tool_name
        self.role = role
        self.task_name = task_name
        self.work_package = work_package
        self.decision = decision
        self.reason = reason
        self.timestamp = timestamp
        self.tool_args = sanitize_for_audit(tool_args) if tool_args else None
        self.tool_result = redact_secrets(tool_result) if tool_result else None
        self.session_id = session_id
        self.duration_ms = duration_ms

    def to_dict(self) -> Dict[str, Any]:
        """Convert to a dictionary, ensuring no raw secrets."""
        d = {
            "event": self.event,
            "tool_name": self.tool_name,
            "role": self.role,
            "task_name": self.task_name,
            "work_package": self.work_package,
            "decision": self.decision,
            "reason": self.reason,
            "timestamp": self.timestamp,
        }
        if self.tool_args is not None:
            d["tool_args"] = self.tool_args
        if self.tool_result is not None:
            d["tool_result"] = self.tool_result
        if self.session_id is not None:
            d["session_id"] = self.session_id
        if self.duration_ms is not None:
            d["duration_ms"] = self.duration_ms
        return d

    def to_json(self) -> str:
        """Serialize to JSON string."""
        return json.dumps(self.to_dict(), ensure_ascii=False, default=str)


def sanitize_audit_entry(entry: Dict[str, Any]) -> Dict[str, Any]:
    """Convenience wrapper: sanitize a dict for audit output.

    Removes all secret values from the dict recursively.
    Used by tests for audit safety verification.
    """
    if not isinstance(entry, dict):
        return entry
    return _redact_dict_secrets(copy.deepcopy(entry))


def audit_tool_call(
    tool_name: str,
    args: Optional[Dict],
    result: Optional[str],
    task_id: Optional[str],
    duration_ms: Optional[int],
    role: Optional[str],
    task_name: Optional[str],
    work_package: Optional[str],
    decision: str = "allow",
    reason: str = "",
) -> AuditRecord:
    """Create an audit record for a tool call.

    All arguments are sanitized to remove secrets.
    """
    from datetime import datetime, timezone
    timestamp = datetime.now(timezone.utc).isoformat()

    return AuditRecord(
        event="post_tool_call",
        tool_name=tool_name,
        role=role,
        task_name=task_name,
        work_package=work_package,
        decision=decision,
        reason=reason,
        timestamp=timestamp,
        tool_args=args,
        tool_result=result,
        session_id=task_id,
        duration_ms=duration_ms,
    )
