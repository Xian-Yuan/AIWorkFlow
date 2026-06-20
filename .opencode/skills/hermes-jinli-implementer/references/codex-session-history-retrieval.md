# Codex Session History Retrieval

When a user says "I lost a Codex conversation" or "find my recent Codex chat about X", use this procedure.

## Data Locations

Codex stores session data in two SQLite databases under `C:\Users\<user>\.codex\`:

| Database | Purpose | Key Table |
|----------|---------|-----------|
| `state_5.sqlite` | Thread metadata (title, preview, timestamps, CWD, model) | `threads` |
| `logs_2.sqlite` | Low-level logs (not useful for content retrieval) | `logs` |

Conversation content is stored in JSONL rollout files:
```
C:\Users\<user>\.codex\sessions\<YYYY>\<MM>\<DD>\rollout-<timestamp>-<thread-id>.jsonl
```

The rollout path is recorded in `threads.rollout_path`.

## Retrieval Procedure

1. **Find candidate threads** — Query `state_5.sqlite` threads table, sort by `updated_at_ms DESC`:
   ```python
   import sqlite3
   conn = sqlite3.connect(r"C:\Users\87372\.codex\state_5.sqlite")
   cur = conn.cursor()
   cur.execute("SELECT id, title, preview, updated_at_ms, rollout_path FROM threads ORDER BY updated_at_ms DESC")
   ```
   Match by title, preview, or first_user_message content.

2. **Read the rollout file** — Each line is a JSON object with `type`, `timestamp`, `payload`. Filter for:
   - `type == 'response_item'` and `payload.role == 'user'` → user messages
   - `type == 'response_item'` and `payload.role == 'assistant'` → assistant responses
   - `type == 'response_item'` and `payload.type == 'tool_call'` → tool invocations

   Content is in `payload.content` (may be a list of `{type: 'input_text'/'output_text', text: '...'}` dicts).

3. **Extract user messages** — Flatten content lists, concatenate text items. Filter out system/instruction messages (role='developer').

## Key Column Reference (threads table)

- `id` — Thread UUID (matches session_index.jsonl)
- `title` — Human-readable thread name
- `first_user_message` — First user input (truncated)
- `preview` — Latest preview (truncated)
- `updated_at_ms` — Last activity timestamp (epoch ms)
- `created_at_ms` — Creation timestamp (epoch ms)
- `rollout_path` — Full path to the JSONL conversation file
- `archived` — 1 if archived, 0 if active
- `model_provider` — Which provider was used (e.g. 'openai', 'packycode')
- `tokens_used` — Total tokens consumed

## Pitfalls

- **Rollout files can be very large** (1M+ lines). Don't try to read the entire file at once. Use targeted extraction: filter by role, skip system messages, limit to first/last N messages.
- **session_index.jsonl** is a lightweight index file, but `state_5.sqlite` is more reliable and up-to-date.
- **`sqlite3` CLI is not installed on Windows git-bash**. Use Python's `sqlite3` module via `execute_code` instead.
- **Thread IDs change** when Codex renames a conversation. The same thread ID may appear twice in session_index.jsonl with different titles.
- **Archived threads** (`archived=1`) are still in the database. Don't filter them out — the user may want old conversations.
