# Output Compressor Skill

> Inspired by: chopratejas/headroom (29K+ stars) — "Compress tool outputs, logs, files, and RAG chunks before they reach the LLM. 60-95% fewer tokens, same answers. Library, proxy, MCP server."

## Purpose

Compress large tool outputs (compile errors, grep results, log files) before they enter the agent's context window. Uses pattern-based summarization to extract only the signal from massive noise.

## When to Activate

- **After any tool call with output > 500 lines**: Automatically compress before presenting to agent
- **Compile errors**: Deduplicate repeated warnings, group by file, extract root causes
- **Grep results**: Summarize file/line hits, group by pattern, show context around matches
- **Log files**: Extract ERROR/FATAL lines, group by error type, show timestamps
- **Multi-file reads**: Summarize key findings across files

## Compression Strategies

### 1. Compile Error Compression

**Before** (500+ lines of output):
```
Error C2143 in Foo.cpp:42
Error C2143 in Foo.cpp:42  (duplicate)
Warning C4100 in Bar.h:15
Error C3861 in Baz.cpp:108
...
```

**After** (50 lines):
```
[3 unique errors | 127 total warnings collapsed to 0 unique]

[C2143] syntax error: missing ';' before '}' (2 occurrences)
  - Foo.cpp:42, 87

[C3861] identifier not found: 'GetActorLocation' (1 occurrence)
  - Baz.cpp:108
  → Suggestion: include Engine/Engine.h or use UActorComponent base
```

### 2. Grep Result Compression

**Before** (200 lines):
```
Source/RTS/Private/RTSCharacter.cpp:45:void ARTSCharacter::BeginPlay()
Source/RTS/Private/RTSCharacter.cpp:128:void ARTSCharacter::Tick(float)
Source/RTS/Public/RTSCharacter.h:22:  virtual void BeginPlay() override;
...
```

**After** (15 lines):
```
[Matched 'BeginPlay|Tick' across 4 files, 12 hits]

Source/RTS/Private/RTSCharacter.cpp: 2 lifecycle methods (lines 45, 128)
Source/RTS/Private/RTSController.cpp: 1 lifecycle method (line 56)
Source/RTS/Public/RTSCharacter.h: 3 declarations (lines 22, 45, 67)
Source/RTS/Public/RTSController.h: 1 declaration (line 30)

[Highest signal file]: RTSCharacter.cpp
```

### 3. Log File Compression

**Before** (1000 lines of runtime log):
```
[2026-06-17 12:00:01.123] LogTemp: Display: SomeComponent initialized
[2026-06-17 12:00:01.456] LogGAS: Warning: Attribute 'Health' clamped
...
```

**After** (20 lines):
```
[Log summary: 1000 lines → 3 errors, 2 warnings, 0 fatals]

ERROR:
  12:00:45 - LogBlueprint: Failed to load BP_RTSCharacter (E:/Project/RTS/...)
  12:01:02 - LogTemp: Null reference in AbilityTask_Tick::OnTick
  12:05:33 - LogStreaming: Texture RTX_Character_D not found

WARNING:
  12:00:01 - LogGAS: Attribute 'Health' clamped (min=0)
  12:03:15 - LogNet: (ignore - singleplayer, no replication)
```

## Integration with Existing Tools

### MCP Server Mode (Optional)
If Python is available:
```python
pip install headroom
```
The headroom MCP server provides a `compress` tool accessible to any MCP-compatible agent.

### Built-in Mode (This Skill)
When Python/headroom is NOT available, this skill provides compression patterns as instructions the agent follows when reading large tool outputs.

### Integration with `context-mode`
The existing `.tools/context-mode/` tool already sandboxes large outputs. This skill adds an additional semantic compression layer on top of context-mode's sandboxing.

## Token Savings Estimate

| Scenario | Raw Output | Compressed | Savings |
|----------|-----------|------------|---------|
| UE5 compile error (1 file) | ~800 lines | ~30 lines | 96% |
| Grep across Source/ (50 files) | ~300 lines | ~15 lines | 95% |
| Runtime log (5 min session) | ~2000 lines | ~25 lines | 99% |
| Read 5 source files (avg 300 lines) | ~1500 lines | ~80 lines summary | 95% |

**Cumulative**: ~95% token reduction on tool outputs.

## Compression Rules for Agents

When an agent receives large tool output, apply these rules before analyzing:

1. **Deduplicate identical errors**: Show only first occurrence + occurrence count
2. **Group by source file**: Errors from same file = same root cause usually
3. **Extract only highest-severity lines**: ERROR > WARNING > INFO > DEBUG
4. **Collapse repeated patterns**: 50x "Warning: unused variable" → "50 unused variable warnings"
5. **Strip boilerplate**: Tool headers, execution timestamps, blank lines between errors
6. **Keep context**: Always show line numbers, file paths, and the error/warning text itself
7. **Add suggestions**: When a common error pattern is recognized, add a fix hint
