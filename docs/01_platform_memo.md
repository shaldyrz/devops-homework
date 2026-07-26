# Platform Design Memo: Meridian Inference Stack

This document serves as the technical reference for engineers joining the Meridian Platform on-call rotation. It details the system architecture, reliability objectives, deployment processes, and future transition plan to dedicated GPU-based inference.

---

## 1. System Architecture & Trust Boundaries

The system is deployed on Google Kubernetes Engine (GKE) as a private zonal cluster in `asia-southeast2-a`. 

```text
[ Client (Internet) ]
         │ (HTTPS / port 443)
         ▼
[ Ingress-Nginx Controller ] <── (TLS terminated via gateway-tls secret / cert-manager)
         │
         │ (HTTP / port 8000)
         ▼
┌─────────────────────────────────────────────────────────────┐
│ Trust Boundary: development namespace                      │
│                                                             │
│  [ gateway-service ] (ClusterIP, exposed via Ingress class) │
│         │                                                   │
│         │ (HTTP / port 8080)                                │
│         ▼                                                   │
│  [ rag-api-service ] (Private ClusterIP, not exposed)      │
│         │                                                   │
│         │ (HTTP / port 8001)                                │
│         ▼                                                   │
│  [ model-server ]    (Private ClusterIP, has admin/fault)   │
│         ▲                                                   │
│         │ (Bundled Guideline Corpus)                        │
│         └─ [ corpus/ ]                                      │
└─────────────────────────────────────────────────────────────┘
```

### Trust Boundary & Exposure Controls
* **Public-Facing Zone**: The **Ingress Controller** and **Gateway** are the only components facing the internet. The Ingress Class (`external-ingress`) restricts incoming traffic to secure domain paths (`gateway.srzlab.tech`).
* **Private-Only Zone**: The `rag-api` and the `model-server` are deployed as internal `ClusterIP` services. They have no Ingress resources.
* **Fault Injection Protection**: The `model-server` exposes an administrative route (`POST /admin/fault`) for injecting errors and latencies during resiliency testing. Because `model-server` is entirely internal, this route is **physically isolated** from the internet and cannot be called by clients.

---

## 2. Service Level Objectives (SLOs) & Alerting Policy

The platform tracks two key Service Level Indicators (SLIs) aligned with the Meridian service level agreement:

| SLI Name | Metric Definition | Target (SLO) | Alerting Window |
| :--- | :--- | :--- | :--- |
| **Availability** | % of `/v1/chat/completions` requests returning `2xx` / `4xx` status codes. | **99.9%** | 30-day rolling window |
| **Latency** | % of `/v1/chat/completions` requests completing in **$\le$ 2.0s**. | **95.0%** | 30-day rolling window |

### Alerting Hierarchy
1. **Critical Alert (P1 - PagerDuty / On-Call Wakeup)**:
   * **Trigger**: Error budget burn rate indicates that the 30-day SLO will be exhausted in less than 24 hours. (e.g., Availability drops below 99% or p95 Latency exceeds 5.0 seconds for >5 minutes).
   * **Why**: Requires immediate human intervention to restore services before violating SLA agreements.
2. **Warning Alert (P2 - Slack / Notification Only)**:
   * **Trigger**: High CPU utilization (>80%) on microservice pods, HPA scaling to its maximum limit (5 replicas), or Cert-Manager failing to renew certificates within 15 days of expiration.
   * **Why**: Alerts engineers of impending capacity constraints or configuration drift that does not yet impact the customer SLA.

---

## 3. Rollout Strategy for Model Versions

When transitioning between model versions (e.g. from version `1.0` to `2.0`), we employ a **Canary Rollout** strategy using Nginx Ingress traffic splitting.

### Canary vs. Blue/Green Tradeoffs
* **Blue/Green**: Requires spinning up a duplicate pool of GPU nodes. While simple and providing absolute rollback guarantees, the **capital cost overhead** of idling GPU resources during transition is prohibitive for high-memory LLMs.
* **Canary**: Splits traffic incrementally (e.g., 90% to `v1.0`, 10% to `v2.0`). This minimizes blast radius for new model regressions and runs efficiently within existing resource limits, but requires strict validation of the incoming request distribution.

### Promotion Criteria ("Healthy Enough to Promote")
A canary version is promoted to 100% traffic only if it satisfies all the following gates over a 24-hour observation window:
1. **SLA Adherence**: Canary p95 latency remains $\le$ 2.0 seconds, and success rate $\ge$ 99.9%.
2. **Zero Evaluation Regression**: Automated evaluation runs on `eval_set.jsonl` verify that accuracy remains at **≥ 95%** and no hallucinations occur (monitored via log checks for refusal strings). Baseline accuracy on current corpus: **95.24%** (20/21 queries).
3. **Hardware Health**: GPU memory usage stays stable with no memory leaks or growth in waiting queue depth.

---

## 4. RAG Data Plane & Scaling

### Vector Store Architecture
* **Selected Engine**: **FAISS** (`faiss-cpu`, Facebook AI Similarity Search) — an in-memory flat index running inside the `rag-api` pod.
* **Rationale**: FAISS provides zero-infrastructure-overhead vector search suitable for the current corpus size (~tens of documents). It requires no external service, simplifying the deployment topology. The index is built at container startup from the `corpus/` directory and held in memory for the lifetime of the pod.
* **Embedding Model**: `sentence-transformers/all-MiniLM-L6-v2` (384 dimensions) — runs fully in-process, no external API calls required for retrieval.

### Embedding Pipeline & Lifecycle
1. **Ingestion**: At `rag-api` pod startup, all documents under `corpus/` are read, chunked by paragraph, and embedded using the local sentence-transformer model.
2. **Index Build**: Embeddings are indexed into a FAISS `IndexFlatL2` flat index in memory. No persistence layer is required at current corpus scale.
3. **Query**: At inference time, the user query is embedded using the same model and the top-k nearest chunks are retrieved via L2 distance search and passed as context to the model server.

### Scaling to 10,000 Documents
When corpus size grows beyond in-memory feasibility, the following migration path applies:
* **FAISS → Qdrant or Weaviate**: Replace the in-memory FAISS index with a persistent, network-accessible vector database (Qdrant recommended) deployed as a StatefulSet in GKE.
* **HNSW Indexing**: Upgrade from `IndexFlatL2` (exact, O(n)) to HNSW (approximate, O(log n)) to maintain sub-10ms retrieval at scale.
* **Index Versioning (Double Buffering)**: Write new embeddings to a versioned collection (`meridian-corpus-v<git-sha>`) and atomically swap an alias to achieve zero-downtime re-indexing.
* **Quantization**: Apply Scalar Quantization (SQ8) or Product Quantization (PQ) to reduce VRAM requirements by up to 75% with negligible recall degradation.

---

## 5. GPU-Readiness & MLOps Plan

Moving from the mock server to a production **vLLM engine** requires restructuring GKE node configurations.

### Node Pools & Device Plugins
* **GPU Node Pool**: Configure a dedicated GKE node pool using GCE `g2-standard-8` instances equipped with NVIDIA L4 GPUs (24GB VRAM).
* **Device Plugin**: Deploy the **NVIDIA GPU Device Plugin** via GKE daemonsets to expose GPU allocatable resources to the Kubernetes scheduler.

### Sharing Models: MIG vs. Time-Slicing
* **Multi-Instance GPU (MIG)**: Hardware-level isolation. Best for splitting larger A100/H100 GPUs into independent, secure slices with hardware-guaranteed VRAM and compute isolation.
* **Time-Slicing**: Software-level scheduling. Best for small, low-traffic environments using L4 or T4 GPUs where multiple replica pods share the same physical GPU, though it lacks strict resource isolation.
* **Choice**: For the production stack, we will use **MIG** on A100s for strict SLA enforcement, or dedicated **L4 node pools** for single-tenant vLLM processes.

### Autoscaling Signal (Why CPU Scaling is Wrong)
* **The CPU Flaw**: Standard HPAs scale on CPU utilization. An LLM inference server (like vLLM) consumes very little CPU while performing intensive tensor operations on the GPU. Scaling on CPU will cause the cluster to remain un-scaled under extreme GPU load, leading to massive queueing delays.
* **Production Signal**: Autoscale using custom Prometheus metrics exported by vLLM:
  * **`vllm:num_requests_waiting`** (Queue Depth): Scale up immediately if requests are waiting in the scheduler queue.
  * **`vllm:gpu_cache_usage_factor`** (KV Cache Capacity): Scale up when KV-cache allocation exceeds 85%, indicating the model has run out of context memory for concurrent generation.

### Latency Optimization (KV Cache & Batching)
* **PagedAttention**: vLLM uses PagedAttention to partition the KV-cache into virtual blocks, eliminating fragmentation and allowing concurrent requests to share system memory.
* **Continuous Batching**: Requests are batched dynamically at the token level, preventing requests with short prompts from being blocked by long-running text generation.
* **Quantization**: Run the model using **AWQ** or **FP8** quantization to decrease GPU memory footprint, enabling larger batch sizes and doubling token throughput per GPU.

### Cost Modeling (Cost per 1M Tokens)
$$Cost_{1M} = \frac{\text{Hourly GPU Instance Cost}}{\text{Average Tokens Per Hour}} \times 1,000,000$$

For example, an N1 instance with 1x NVIDIA L4 costs approximately **$0.75/hr**. If the vLLM engine outputs an average of **200 tokens/sec** under sustained load (720,000 tokens/hr):
$$Cost_{1M} = \frac{\$0.75}{720,000} \times 1,000,000 \approx \$1.04 \text{ per million tokens}$$

---

## 6. Security & Residency Notes

* **Secrets Management**: Do not store passwords or service account keys in YAML manifests. Use **Google Cloud Secret Manager** and mount credentials into pods dynamically using the **Secret Store CSI Driver**.
* **Egress Restricting**: Restrict all egress from GKE worker nodes using NetworkPolicies (`NetPol`). Pods in the `development` namespace are blocked from connecting to the public internet, except for communication to Google Artifact Registry and cert-manager Let's Encrypt endpoint.
* **Data Residency**: Pin the GCP bucket and GKE cluster location strictly to `asia-southeast2` (Jakarta) to meet local sovereignty and regulatory compliance.
