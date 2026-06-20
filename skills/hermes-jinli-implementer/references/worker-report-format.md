# Worker Report Format Requirements

## Source: task-guard.ps1 `Test-WorkerReportQuality` function

`task-guard.ps1` checks worker reports with specific regex patterns. Format violations cause BLOCKED even when content is substantively correct.

## Required Sections (5, as `## ` headings)

1. `## Changed Files` — list of changed files (`- path/to/file`)
2. `## Commands Run` — commands and output (wrap in code blocks)
3. `## Acceptance Criteria Touched` — AC list (`- AC01: description — test evidence`)
4. `## Scope Control` — scope declarations (**MUST use list-item format**)
5. `## Unresolved Risks` — risks or `- None specific to WP0x.`

## Scope Control Format (Critical Trap)

Gate regex: `(?mi)^\s*-\s*Extra scope taken:\s*no\s*$`

### Correct (list items)

```markdown
## Scope Control

- Extra scope taken: no
- Forbidden paths not touched
- Only WP01 allowed paths edited
```

### Wrong (paragraph text)

```markdown
## Scope Control

Extra scope taken: no. Only WP01 allowed paths edited.
```

### Wrong (top-level declaration, not in Scope Control section)

```markdown
Status: done
Extra scope taken: no    ← Gate does not match this
```

## Status Declaration

Report must contain `Status: done` as a top-level field.

## Template Placeholders Prohibited

Gate regex: `<[^>\r\n]+>`

No `<artifact_dir>`, `<task-name>`, etc. Use uppercase constants instead (e.g., `PREPRODUCTION_OUTPUT_DIR`).

## Line-Number Prefix Contamination

When using `execute_code` to read files via `read_file` and write back via `write_file`, the `LINE|CONTENT` format (e.g., `7|7|## Changed Files`) gets baked into the file. Gate then cannot find section headers.

### Prevention

- Do NOT pass `read_file` raw output to `write_file` in `execute_code`
- If batch processing is needed, strip line numbers: `re.sub(r'^\d+\|\d+\|', '', content, flags=re.MULTILINE)`
- Prefer `patch` tool for targeted edits over read-then-write whole-file replacement

## Minimal Template

```markdown
# Worker Report: WP01 — Title

Status: done
Worker: model-name

## Changed Files

- path/to/file1.py
- path/to/file2.py

## Commands Run

```
cd Project/X
python -m pytest path/to/tests -q
```

Result: N passed

## Acceptance Criteria Touched

- AC01: description — test evidence

## Scope Control

- Extra scope taken: no
- Forbidden paths not touched
- Only WP01 allowed paths edited

## Unresolved Risks

- None specific to WP01.
```
