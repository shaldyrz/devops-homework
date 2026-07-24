.PHONY: help up down rollout fault-injection load-test

help:
	@echo "Available commands:"
	@echo "  make up              - Provision Kind cluster, configure namespaces, and bootstrap ArgoCD"
	@echo "  make down            - Destroy the Kind cluster and clean up state"
	@echo "  make rollout         - Run rollout demo"
	@echo "  make fault-injection - Run fault injection demo"
	@echo "  make load-test       - Run load test demo"

up:
	@echo "=== Step 1: Provisioning Kind Cluster via Terragrunt ==="
	cd infra/k8s-cluster && terragrunt apply --terragrunt-non-interactive

	@echo "=== Step 2: Creating Kubernetes Namespaces ==="
	kubectl create namespace argocd || true
	kubectl create namespace monitoring || true

	@echo "=== Step 3: Installing ArgoCD via Helm ==="
	helm repo add argo https://argoproj.github.io/argo-helm || true
	helm repo update argo
	helm upgrade --install argocd argo/argo-cd --namespace argocd -f deploy/argocd/values.yaml

	@echo "=== Step 4: Waiting for ArgoCD Server to be Ready ==="
	kubectl rollout status deployment/argocd-server -n argocd --timeout=300s

	@echo "=== Bootstrap Completed Successfully ==="

down:
	@echo "=== Tearing Down Kind Cluster ==="
	cd infra/k8s-cluster && terragrunt destroy --terragrunt-non-interactive

rollout:
	@echo "Running rollout..."

fault-injection:
	@echo "Injecting faults..."

load-test:
	@echo "Running load test..."
