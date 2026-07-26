import json
import time
import requests
import argparse
import sys
import os

def main():
    parser = argparse.ArgumentParser(description="Meridian Inference Stack Evaluation Gate")
    parser.add_argument("--url", default="https://gateway.srzlab.tech", help="Gateway completions endpoint URL")
    parser.add_argument("--eval-set", default="eval/eval_set.jsonl", help="Path to eval_set.jsonl")
    parser.add_argument("--output", default="evidence/rag_eval_results.json", help="Path to save evaluation evidence")
    args = parser.parse_args()

    if not os.path.exists(args.eval_set):
        print(f"Error: evaluation set file '{args.eval_set}' not found.")
        sys.exit(1)

    print(f"Starting evaluation gate against: {args.url}")
    print(f"Loading evaluation dataset from {args.eval_set}...")

    queries = []
    with open(args.eval_set, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                queries.append(json.loads(line))

    total = len(queries)
    passed = 0
    results = []

    print(f"Running {total} test queries...")
    for idx, query_item in enumerate(queries):
        qid = query_item["id"]
        prompt = query_item["prompt"]
        expected = query_item["expected"]

        payload = {
            "model": "meridian-slm",
            "messages": [
                {"role": "user", "content": prompt}
            ]
        }

        started = time.perf_counter()
        status_code = -1
        answer = ""
        error_msg = ""
        
        try:
            res = requests.post(f"{args.url}/v1/chat/completions", json=payload, timeout=30.0)
            status_code = res.status_code
            if status_code == 200:
                data = res.json()
                answer = data["choices"][0]["message"]["content"].strip()
            else:
                error_msg = f"HTTP {status_code}: {res.text}"
        except Exception as exc:
            error_msg = str(exc)

        elapsed = time.perf_counter() - started

        # Normalize answers to compare
        norm_expected = " ".join(expected.split()).lower()
        norm_answer = " ".join(answer.split()).lower()
        is_correct = norm_expected == norm_answer

        if is_correct:
            passed += 1
            print(f"  [{idx+1}/{total}] QID {qid}: PASSED ({elapsed:.2f}s)")
        else:
            print(f"  [{idx+1}/{total}] QID {qid}: FAILED ({elapsed:.2f}s)")
            print(f"    Prompt:   {prompt}")
            print(f"    Expected: {expected}")
            print(f"    Got:      {answer if status_code == 200 else error_msg}")

        results.append({
            "id": qid,
            "prompt": prompt,
            "expected": expected,
            "got": answer if status_code == 200 else error_msg,
            "status_code": status_code,
            "latency_sec": elapsed,
            "correct": is_correct
        })

    accuracy = (passed / total) * 100 if total > 0 else 0
    print(f"\nEvaluation Finished. Passed: {passed}/{total} | Accuracy: {accuracy:.2f}%")

    # Ensure evidence folder exists
    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    
    # Save evidence metadata
    evidence_data = {
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "target_url": args.url,
        "total_queries": total,
        "passed_queries": passed,
        "accuracy_pct": accuracy,
        "results": results
    }

    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(evidence_data, f, indent=2)
    print(f"Evidence report saved to: {args.output}")

    if passed == total:
        print("Success: All test queries matched exactly. Gate PASSED.")
        sys.exit(0)
    else:
        print(f"Failure: {total - passed} queries failed or mismatch. Gate FAILED.")
        sys.exit(1)

if __name__ == "__main__":
    main()
