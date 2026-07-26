# Load Test Evidence

**Date**: 2026-07-26  
**Command**: `make load-test`  
**Tool**: `loadgen/loadgen.py`

## Configuration

| Parameter    | Value                         |
|--------------|-------------------------------|
| Target URL   | https://gateway.srzlab.tech   |
| Concurrency  | 8 workers                     |
| Duration     | 30 seconds                    |
| Prompt Set   | `eval/eval_set.jsonl`         |

## Results

| Metric         | Value        |
|----------------|--------------|
| Total Requests | 491          |
| Errors         | 0 (0.0%)     |
| Throughput     | 16.11 req/s  |
| Latency p50    | 504 ms       |
| Latency p95    | 682 ms       |
| Latency p99    | 698 ms       |
| Latency max    | 751 ms       |

## Gate Decision: PASS

- **Zero errors** under 8-way concurrency -- confirms the event-loop starvation fix in `gateway` and `rag-api` is working correctly.
- **p99 latency of 698 ms** is well within the acceptable SLA threshold.
- **16.11 req/s throughput** with no crashes or pod restarts observed.

## Raw Output

```
=== Running Concurrency Load Test ===
python3 loadgen/loadgen.py --url https://gateway.srzlab.tech --concurrency 8 --duration 30 --prompts eval/eval_set.jsonl
target          https://gateway.srzlab.tech
concurrency     8
duration        30.5s
requests        491 (0 errors, 0.0%)
throughput      16.11 req/s
latency p50     504 ms
latency p95     682 ms
latency p99     698 ms
latency max     751 ms
```
