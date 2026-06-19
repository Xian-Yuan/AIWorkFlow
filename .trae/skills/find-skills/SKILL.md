---
name: "find-skills"
description: "Search and discover relevant skills from the project skill registry. Use when the current task requires a capability not yet loaded, or when the user asks what skills are available for a specific domain."
---

# Find Skills

## Purpose

Search the project skill registry (`skills/`) to discover skills matching a domain, keyword, or capability need. This skill is invoked when the agent needs to locate domain-specific guidance that has not been pre-loaded.

## Usage

1. Search by keyword: `find-skills <keyword>` returns matching skill names and descriptions.
2. Search by domain: `find-skills --domain ue5` returns all UE5-related skills.
3. List all: `find-skills --all` returns the full active skill inventory.

## Integration

This skill is typically invoked by `task-orchestrator` during the Plan phase to assemble the correct skill stack for a task. It reads from the canonical `skills/` directory and respects the `_archived/` exclusion.
