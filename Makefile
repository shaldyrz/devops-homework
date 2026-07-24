.PHONY: help gke-up gke-down rollout fault-injection load-test

help:
	@echo "Available commands:"
	@echo "  make gke-up          - Provision GKE modular infrastructure (VPC, Subnet, GKE, LB) and bootstrap ArgoCD"
	@echo "  make gke-down        - Destroy GKE and all cloud resources on GCP"
	@echo "  make rollout         - Run rollout demo"
	@echo "  make fault-injection - Run fault injection demo"
	@echo "  make load-test       - Run load test demo"

gke-up:
	@echo "=== Step 1: Provisioning GCP Infrastructure via Terragrunt run --all ==="
	cd infra/resources && terragrunt run --all apply --non-interactive

	@echo "=== Step 2: Registering GKE Kubeconfig Credentials ==="
	gcloud container clusters get-credentials interopera-gke-cluster --region asia-southeast2 --project ambient-stone-281407

	@echo "=== Step 3: Creating Kubernetes Namespaces ==="
	kubectl create namespace argocd || true
	kubectl create namespace monitoring || true

	@echo "=== Step 4: Installing ArgoCD via Helm ==="
	helm repo add argo https://argoproj.github.io/argo-helm || true
	helm repo update argo
	helm upgrade --install argocd argo/argo-cd --namespace argocd -f deploy/argocd/values.yaml

	@echo "=== Step 5: Waiting for ArgoCD Server to be Ready ==="
	kubectl rollout status deployment/argocd-server -n argocd --timeout=300s

	@echo "=== GKE Bootstrap Completed Successfully ==="

gke-down:
	@echo "=== Tearing Down GCP Infrastructure via Terragrunt run --all ==="
	cd infra/resources && terragrunt run --all destroy --non-interactive

rollout:
	@echo "Running rollout..."

fault-injection:
	@echo "Injecting faults..."

load-test:
	@echo "Running load test..."
