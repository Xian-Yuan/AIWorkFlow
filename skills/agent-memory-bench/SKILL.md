# Agent Memory Benchmark Skill

> Inspired by: rohitg00/agentmemory (23K+ stars) — "#1 Persistent memory for AI coding agents based on real-world benchmarks"

## Purpose

Add quantitative benchmarking to the existing `failure-memory` system. Instead of just recording failures, measure recall rates, precision, and failure prevention effectiveness. Give agents a data-driven way to query "which past failure is most relevant to my current task?"

## When to Activate

- **Plan phase Step 1d**: `memory-retrieve.ps1` now includes benchmark scores in retrieval results
- **After each Review failure**: Record failure + benchmark the memory system's ability to have predicted it
- **Weekly**: Run the memory benchmark to report health scores to the agent dashboard
- **Whenever adding new Memory Candidate**: Run self-benchmark

## Architecture

```
Docs\Memory\
├── README.md                          # Updated with benchmark rules
├── benchmark\
│   ├── benchmark-config.json          # Benchmark parameters
│   ├── recall-history.jsonl           # Recall test results
│   └── benchmark-report.md            # Latest benchmark report
├── failures\                          # Existing: promoted failure memories
├── candidates\                        # Existing: pre-promotion candidates
├── indexes\memory-index.md            # Existing: retrieval index
└── templates\                         # Existing: templates
```

Add:
```
.trae\scripts\memory-benchmark.ps1     # Benchmark execution engine
```

## Benchmark Metrics

### 1. Recall Rate (Top-K)
"How often does the memory system return the right failure in the top K results?"

```
recall@1: Did the exact matching failure appear as #1 on retrieval?
recall@3: Did it appear in top 3?
recall@5: Did it appear in top 5?
```

### 2. Prevention Rate
"Of failures that occurred, how many had a prior similar failure already recorded?"

```
prevention_rate = (failures with prior similar entry) / (total failures)
```

A low prevention rate means the memory system isn't being used or queried properly.

### 3. Precision
"Of retrieved memories, what fraction was actually relevant?"

```
precision = (relevant retrieved) / (total retrieved)
```

### 4. Rotten Memory Detection
Memory entries older than 90 days with 0 hits → candidate for archival or deletion.

## Benchmark Script: `memory-benchmark.ps1`

### Run benchmark

```powershell
.\memory-benchmark.ps1 -Action run -TopK 5
```

Behavior:
1. Load all failure entries from `Docs/Memory/failures/`
2. Load `recall-history.jsonl` for past queries
3. For each failure entry:
   a. Use it as a simulated "new failure"
   b. Query the memory system (excluding itself) using keyword matching
   c. Check if the source failure appears in top-K results
   d. Record recall@1, recall@3, recall@5
4. Calculate precision and prevention rate
5. Output `benchmark-report.md`

### Query with benchmark context

```powershell
.\memory-benchmark.ps1 -Action query -Query "AbilitySystemComponent compile error UAttributeSet"
```

Returns: matching failures + confidence scores

### Report

```powershell
.\memory-benchmark.ps1 -Action report
```

Outputs current benchmark health report with trend lines.

## Integration with Existing System

### `memory-retrieve.ps1` Enhancement

Existing:
```
.\memory-retrieve.ps1 -Keywords "GAS, ASC, compile error"
→ Returns top 2 failure summaries
```

Enhanced:
```
.\memory-retrieve.ps1 -Keywords "GAS, ASC, compile error" -WithBenchmark
→ Returns top 2 failure summaries + recall confidence + "most relevant +1"
  based on benchmark scores
```

### `failure-memory` Skill Enhancement

When the agent records a failure:
1. Query the memory system with failure keywords BEFORE adding
2. Record "could this have been prevented?" flag
3. If yes: increment the matched failure's `would_have_prevented` counter
4. If no: this is a novel failure → higher value for recording

## Benchmark Configuration

```json
{
  "top_k": 5,
  "min_failures_for_benchmark": 10,
  "rotten_threshold_days": 90,
  "max_recall_history": 1000,
  "benchmark_interval_days": 7
}
```

## Token Impact

- Before: Agent queries failure memory, gets 2 summaries → ~300 tokens
- After: Agent queries with benchmark scores, gets 2 summaries + confidence → ~400 tokens
- Net: +100 tokens but 3x more likely to retrieve the RIGHT failure → saves re-fixing cycles

## Relationship to Existing Skills

- Extends `failure-memory`: adds quantitative scoring layer
- Feeds `anti-degradation`: "same error twice" detection now benchmark-backed
- Feeds `implicit-requirements`: memory recall failures hint at missing constraints
- Feeds `ue-project-router` Plan Step 1d: richer memory context with confidence scores
