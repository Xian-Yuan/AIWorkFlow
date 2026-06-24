# Hermes Session History Diagnosis

When users report conversation history anomalies (content disappearing, duplicate
sessions, unexpected stops), use this systematic diagnosis workflow against the
Hermes `state.db` SQLite store.

## Three Root Causes

1. **Over-aggressive compression** — `target_ratio: 0.2` can compress 545 messages
   down to 6, effectively destroying context. The `auxiliary.compression` model
   falling back to `auto` (same unstable provider) and hitting 401 errors makes
   it worse — degraded to crude truncation instead of intelligent summarization.

2. **Session branching** — API connection drops (`APITimeoutError`,
   `APIConnectionError`, `stream_interrupt_abort`) cause Hermes to create new
   child sessions. The parent session stays in the list, producing "duplicate
   history" in the UI. Some sessions accumulate 4-6 children.

3. **Ghost sessions** — Compression creates child sessions with `message_count=0`
   that never receive messages. These pollute the session list.

## Diagnosis Queries

All queries run against `<HERMES_HOME>/state.db` (for profiles:
`<HERMES_HOME>/profiles/<name>/state.db`).

### Check compression aggressiveness

```sql
SELECT s1.id, s1.title, s1.message_count AS before_msgs,
       s2.message_count AS after_msgs, s1.end_reason
FROM sessions s1
LEFT JOIN sessions s2 ON s2.parent_session_id = s1.id
WHERE s1.end_reason = 'compression'
ORDER BY s1.started_at;
```

If `after_msgs / before_msgs` is below 10%, compression is too aggressive.

### Find sessions with multiple children (branching)

```sql
SELECT s1.id, s1.title, s1.end_reason,
       (SELECT count(*) FROM sessions s2 WHERE s2.parent_session_id = s1.id) AS child_count,
       (SELECT group_concat(s2.id, ' | ') FROM sessions s2 WHERE s2.parent_session_id = s1.id) AS children
FROM sessions s1
WHERE (SELECT count(*) FROM sessions s2 WHERE s2.parent_session_id = s1.id) > 1
ORDER BY s1.started_at;
```

### Find ghost sessions (0 messages in both metadata and messages table)

```sql
-- Metadata says 0
SELECT id, title, message_count FROM sessions WHERE message_count = 0;
```

Before deleting, verify actual message count:
```sql
SELECT count(*) FROM messages WHERE session_id = '<id>';
```

Only delete if BOTH are 0. Some sessions have `message_count=0` in metadata but
actual messages in the messages table (compression children that received messages
after metadata was written).

### Check API stability

```bash
grep -c "APITimeoutError\|APIConnectionError" <HERMES_HOME>/logs/agent.log
grep "stream_interrupt_abort\|tcp_force_closed" <HERMES_HOME>/logs/agent.log | tail -10
grep "Failed to generate context summary" <HERMES_HOME>/logs/errors.log | tail -5
```

### Check model context_length detection failures

```bash
grep "Could not detect context length" <HERMES_HOME>/logs/agent.log | tail -5
```

## Fix Commands

### Adjust compression settings

```bash
hermes config set compression.threshold 0.7     # Trigger at 70% instead of 50%
hermes config set compression.target_ratio 0.5   # Keep 50% instead of 20%
hermes config set compression.protect_last_n 40  # Protect 40 recent messages
```

### Configure dedicated compression model

When the main provider is unreliable, use a separate provider for compression:

```bash
hermes config set auxiliary.compression.provider openrouter
hermes config set auxiliary.compression.model google/gemini-2.5-flash
```

Requires `OPENROUTER_API_KEY` in `.env`.

### Set model context_length

Stops repeated detection failures and avoids premature compression triggers:

```bash
hermes config set model.context_length 131072   # 128K for typical coding models
```

### Clean ghost sessions

Use Python sqlite3 directly (hermes CLI requires interactive confirmation):

```python
import sqlite3
db = sqlite3.connect(r'<path_to_state.db>')
# Find truly empty sessions
rows = db.execute('SELECT id, title, message_count FROM sessions WHERE message_count=0').fetchall()
for r in rows:
    actual = db.execute('SELECT count(*) FROM messages WHERE session_id=?', (r[0],)).fetchone()[0]
    if actual == 0:
        db.execute('DELETE FROM messages WHERE session_id=?', (r[0],))
        db.execute('DELETE FROM sessions WHERE id=?', (r[0],))
        print(f'Deleted {r[0]}')
db.commit()
db.close()
```

## Key Pitfalls

- **Never delete sessions that have actual messages** — some sessions show
  `message_count=0` in metadata but have hundreds of messages in the messages
  table. Always check both.
- **Compression config changes require session restart** — `/reset` in chat or
  restart the TUI/gateway process.
- **`hermes config set` refuses to edit config.yaml from `patch` tool** — use
  the CLI command instead.
- **Profile-based state.db paths differ** — for named profiles, state.db is at
  `<HERMES_HOME>/profiles/<name>/state.db`, not `~/.hermes/state.db`.
