# RAG Evaluation Gate Evidence

**Date**: 2026-07-26  
**Command**: `make eval-gate`  
**Tool**: `eval/eval_gate.py`  
**Auto-saved JSON**: `evidence/rag_eval_results.json`

## Configuration

| Parameter   | Value                         |
|-------------|-------------------------------|
| Target URL  | https://gateway.srzlab.tech   |
| Eval Set    | `eval/eval_set.jsonl`         |
| Total Queries | 21                          |

## Summary

| Metric        | Value        |
|---------------|--------------|
| Passed        | 20 / 21      |
| Accuracy      | **95.24%**   |
| Gate Decision | FAILED (threshold: 100%)  |

## Failing Query

| Field    | Value |
|----------|-------|
| QID      | 20 |
| Prompt   | *How often is the fund's net asset value published?* |
| Expected | The fund's net asset value is published daily. |
| Got      | I cannot find the answer to this question in the provided context. |
| Latency  | 0.55s |

### Analysis

The failure on QID 20 is a **corpus coverage gap**: the sentence stating NAV is "published daily" is present in the fund prospectus document but the RAG retrieval did not return the correct chunk for this specific phrasing. All other 20 queries passed with exact matches, confirming correct end-to-end RAG retrieval and answer generation.

## Per-Query Results

| QID | Prompt (summary) | Status | Latency |
|-----|-----------------|--------|---------|
| 1 | Base currency of fund | PASS | 0.61s |
| 2 | Regulator / supervisor | PASS | 0.52s |
| 3 | Max high yield bond allocation | PASS | 0.58s |
| 4 | Min investment grade allocation | PASS | 0.58s |
| 5 | Permitted modified duration range | PASS | 0.49s |
| 6 | Breach action for duration limit | PASS | 0.74s |
| 7 | Single-issuer concentration cap | PASS | 0.58s |
| 8 | Issuer group concentration cap | PASS | 0.61s |
| 9 | Liquidity floor | PASS | 0.64s |
| 10 | Regulatory compliance report frequency | PASS | 0.40s |
| 11 | Audit record retention period | PASS | 0.46s |
| 12 | Breach escalation owner | PASS | 0.48s |
| 13 | Max structured credit allocation | PASS | 0.55s |
| 14 | Min weighted average credit rating | PASS | 0.59s |
| 15 | Max unhedged non-SGD exposure | PASS | 0.56s |
| 16 | Risk metrics monitoring frequency | PASS | 0.37s |
| 17 | Fund benchmark | PASS | 0.43s |
| 18 | Fund custodian | PASS | 0.52s |
| 19 | Fund launch year | PASS | 0.45s |
| 20 | NAV publication frequency | **FAIL** | 0.55s |
| 21 | Non-investment-grade exposure cap | PASS | 0.53s |
