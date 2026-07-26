# Interopera — RAG Platform on GKE

A production-grade Retrieval-Augmented Generation (RAG) platform deployed on Google Kubernetes Engine, with full GitOps, observability, and evaluation pipeline.

## Architecture

```
User → Gateway (FastAPI) → RAG API (FastAPI + FAISS) → Model Server (LLM)
                                                ↑
                                           corpus/ (PDF docs)
```

All services are deployed via **ArgoCD** from this repository. Metrics are collected by **Grafana Alloy** and stored in **Victoria Metrics**, visualised in **Grafana**.

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| `gcloud` CLI | ≥ 470.0 | [cloud.google.com/sdk](https://cloud.google.com/sdk/docs/install) |
| `kubectl` | ≥ 1.29 | `gcloud components install kubectl` |
| `terraform` | ≥ 1.6 | [terraform.io](https://developer.hashicorp.com/terraform/install) |
| `terragrunt` | ≥ 0.55 | [terragrunt.gruntwork.io](https://terragrunt.gruntwork.io/docs/getting-started/install/) |
| `helm` | ≥ 3.14 | [helm.sh](https://helm.sh/docs/intro/install/) |
| `python3` | ≥ 3.11 | [python.org](https://www.python.org/downloads/) |
| `make` | any | pre-installed on macOS/Linux |

### GCP Authentication

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project ambient-stone-281407
```

---

## One Bring-Up Command

Provision all cloud infrastructure and bootstrap ArgoCD:

```bash
make gke-up
```

This single command:
1. Provisions GCP infrastructure (VPC, Subnet, GKE cluster, Load Balancer) via Terragrunt
2. Registers GKE credentials into your local kubeconfig
3. Creates `argocd`, `monitoring`, and `development` namespaces
4. Installs ArgoCD via Helm
5. Waits for ArgoCD to become ready

Once ArgoCD is running, it automatically syncs all applications from this repository (services, observability stack, ingress, etc.).

To tear down all cloud resources:

```bash
make gke-down
```

---

## Demo Commands

### Rollout

Check ArgoCD sync status and verify all deployments are healthy:

```bash
make rollout
```

### Load Test

Run a concurrency load test (8 workers, 30 seconds) against the gateway:

```bash
make load-test
```

Expected output:
```
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

### Fault Injection

Inject a 30% error rate into the model server to observe alerting behaviour:

```bash
make inject-fault
```

Clear the fault afterward:

```bash
make clear-fault
```

### RAG Evaluation Gate

Run the evaluation harness against 21 ground-truth QA pairs:

```bash
make eval-gate
```

Results are saved to `evidence/rag_eval_results.json`.

---

## Services

| Service | Port | Description |
|---------|------|-------------|
| `gateway` | 8000 | Public-facing API proxy with request routing |
| `rag-api` | 8080 | RAG retrieval pipeline (FAISS + corpus) |
| `model-server` | 8001 | LLM inference with fault injection support |

### Public Endpoints

| URL | Description |
|-----|-------------|
| `https://gateway.srzlab.tech` | Gateway API |
| `https://grafana.srzlab.tech` | Grafana dashboards (admin / prom-operator) |
| `https://argocd.srzlab.tech` | ArgoCD GitOps dashboard |

---

## Observability

- **Metrics**: Victoria Metrics (via Grafana Alloy scraping)
- **Dashboards**: `observability/dashboard/services-dashboard.json` (auto-synced via Grafana Git Sync)
- **Alerts**: `observability/alert/`
- **Scraped targets**: gateway, rag-api, model-server, kube-state-metrics, node-exporter, cAdvisor

---

## Repository Structure

```
├── Makefile                  ← All demo commands
├── infra/                    ← Terraform / Terragrunt (GCP infra)
├── deploy/                   ← Kubernetes manifests (ArgoCD apps, services, observability)
├── ci/                       ← GitHub Actions CI/CD pipeline
├── observability/
│   ├── dashboard/            ← Grafana dashboard JSON (Git Sync)
│   └── alert/                ← Alert rules as code
├── eval/                     ← Evaluation harness and dataset
├── services/
│   ├── model-server/         ← LLM inference service
│   ├── gateway/              ← API gateway
│   └── rag-api/              ← RAG retrieval service
├── corpus/                   ← Source documents for RAG
├── docs/
│   ├── 01_platform_memo.md   ← Platform architecture memo
│   └── 02_postmortem.md      ← Concurrency incident postmortem
└── evidence/                 ← Load test + eval gate results
```
