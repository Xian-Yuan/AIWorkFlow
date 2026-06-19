# Result: <agent-name> WP<NN>

Task packet: `.trae/tasks/<project>/<task-name>/`
Work package: `work-packages/WP<NN>-<name>.md`
Status: done | blocked
Worker model: <model>
Worker context: fresh | continued

> Implement gate accepts this report only when `Status: done` and `Extra scope taken: no`.

## Changed Files
- `<path>` - `<summary>`

## Commands Run
| Command | Result | Notes |
|---|---|---|
| `<command>` | pass/fail/not-run | `<notes>` |

## Acceptance Criteria Touched
- ACxx: pass/fail/not-run - `<evidence>`

## Scope Control
- Extra scope taken: no
- Forbidden paths touched: no
- Architecture decisions changed: no

## Worker Authority
- Review result set by worker: no
- Verify result set by worker: no
- Task state changed by worker: no
- Acceptance criteria changed by worker: no
- Tests weakened by worker: no

## Unresolved Risks
- `<risk or None>`
