#!/usr/bin/env python3
"""sync-workflow-registry.py
Scans skills/*/status.yaml and aggregates into skills/ai-workflow-registry/registry.yaml.
Idempotent: safe to run multiple times. Preserves manual entries without status.yaml.
"""

import os
import sys
from pathlib import Path

# Try to import yaml, fall back to simple parser
try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False


def parse_simple_yaml(path: Path) -> dict:
    """Parse a simple flat YAML file (key: value, with optional simple lists)."""
    result = {}
    current_key = None
    list_items = []

    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue

        if stripped.startswith("- "):
            val = stripped[2:].strip().strip('"').strip("'")
            list_items.append(val)
            continue

        if ":" in stripped:
            # Flush previous list
            if current_key and list_items:
                result[current_key] = list_items
                list_items = []

            key, _, val = stripped.partition(":")
            key = key.strip()
            val = val.strip().strip('"').strip("'")
            result[key] = val
            current_key = key if not val else None

    if current_key and list_items:
        result[current_key] = list_items

    return result


def load_yaml(path: Path) -> dict:
    """Load YAML using pyyaml if available, else simple parser."""
    if HAS_YAML:
        with open(path, "r", encoding="utf-8") as f:
            return yaml.safe_load(f) or {}
    return parse_simple_yaml(path)


def dump_yaml(data: dict) -> str:
    """Dump dict to YAML string."""
    if HAS_YAML:
        return yaml.dump(data, allow_unicode=True, default_flow_style=False, sort_keys=False)

    # Simple fallback
    lines = []
    for key, val in data.items():
        if isinstance(val, str):
            lines.append(f"{key}: \"{val}\"")
        elif isinstance(val, list):
            lines.append(f"{key}:")
            for item in val:
                lines.append(f"  - {item}")
        else:
            lines.append(f"{key}: {val}")
    return "\n".join(lines) + "\n"


def main():
    repo_root = Path(os.environ.get("UEGAMEDEV_ROOT", "E:\\UEGameDevelopment"))
    skills_dir = repo_root / "skills"
    registry_path = skills_dir / "ai-workflow-registry" / "registry.yaml"

    # Read existing registry
    existing = {}
    if registry_path.exists():
        reg_data = load_yaml(registry_path)
        for wf in reg_data.get("workflows", []):
            if isinstance(wf, dict) and "name" in wf:
                existing[wf["name"]] = wf

    # Scan skills/*/status.yaml
    updated = {}
    for d in skills_dir.iterdir():
        if not d.is_dir():
            continue
        if d.name in ("ai-workflow-registry", "_archived"):
            continue
        status_file = d / "status.yaml"
        if not status_file.exists():
            continue

        status = load_yaml(status_file)
        name = status.get("name", d.name)

        # Merge with existing entry (preserve manual fields)
        entry = dict(existing.get(name, {}))
        entry["name"] = name

        # Update from status.yaml
        if "status" in status:
            entry["status"] = status["status"]
        if "last_run" in status:
            entry["last_run"] = status["last_run"]
        if "progress" in status:
            entry["progress"] = status["progress"]
        entry["skill_path"] = f"skills/{d.name}/SKILL.md"

        # If new entry, try to read description from SKILL.md
        if "description" not in entry:
            skill_file = d / "SKILL.md"
            if skill_file.exists():
                content = skill_file.read_text(encoding="utf-8")
                import re
                m = re.search(r'^description:\s*["\']?(.+?)["\']?\s*$', content, re.MULTILINE)
                if m:
                    entry["description"] = m.group(1)
            if "trigger_keywords" not in entry:
                entry["trigger_keywords"] = [name]
            if "category" not in entry:
                entry["category"] = "general"

        updated[name] = entry

    # Preserve entries without status.yaml
    for name, entry in existing.items():
        if name not in updated:
            updated[name] = entry

    # Write registry.yaml
    registry_data = {
        "workflows": list(updated.values())
    }

    registry_path.parent.mkdir(parents=True, exist_ok=True)
    with open(registry_path, "w", encoding="utf-8") as f:
        if HAS_YAML:
            f.write("# AI Workflow Registry\n")
            f.write("# Auto-maintained by sync-workflow-registry.py\n")
            f.write("# Manual edits are preserved for entries without status.yaml\n\n")
            yaml.dump(registry_data, f, allow_unicode=True, default_flow_style=False, sort_keys=False)
        else:
            f.write(dump_yaml(registry_data))

    print(f"Registry synced: {len(updated)} workflows registered")
    print(f"Output: {registry_path}")


if __name__ == "__main__":
    main()
