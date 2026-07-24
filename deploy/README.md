# Deployment (Kubernetes Manifests)

This directory contains the Kubernetes deployment manifests, Helm wrapper charts, and environment-specific values files for all platform services.

## Directory Structure

```text
deploy/
├── argocd/
│   ├── values.yaml                         # ArgoCD Helm installation values
│   ├── app_of_apps/                        # ArgoCD App-of-Apps parent configuration
│   │   └── root.yaml                       # Parent ArgoCD application definition
│   ├── victoria-metrics-application.yaml   # Child VM stack application definition
│   ├── grafana-application.yaml            # Child Grafana application definition
│   ├── alertmanager-application.yaml       # Child Alertmanager application definition
│   ├── gateway-application.yaml            # Child Gateway application definition
│   ├── model-server-application.yaml       # Child Model Server application definition
│   └── rag-api-application.yaml            # Child RAG API application definition
├── victoria-metrics/
│   ├── Chart.yaml                # Helm wrapper Chart (dependencies: VM stack)
│   └── values.yaml               # VM Stack configuration values
├── grafana/
│   ├── Chart.yaml                # Helm wrapper Chart (dependencies: Grafana)
│   └── values.yaml               # Grafana configuration values
├── alertmanager/
│   ├── Chart.yaml                # Helm wrapper Chart (dependencies: Alertmanager)
│   └── values.yaml               # Alertmanager configuration values
└── <name-apps>/
    ├── stg/
    │   └── values.yaml           # Staging environment configuration values
    └── prod/
        └── values.yaml           # Production environment configuration values
```

## ArgoCD GitOps Integration

1. **Bootstrap ArgoCD**:
   Install ArgoCD using the root Makefile (`make up`).
2. **Apply Parent App**:
   Deploy the parent application to bootstrap all child applications (monitored resources):
   ```bash
   kubectl apply -f deploy/argocd/app_of_apps/root.yaml
   ```
   *Note: Ensure to update the `repoURL` in the manifests once your Git repository URL is established.*

