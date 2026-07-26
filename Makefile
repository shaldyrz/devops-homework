.PHONY: help gke-up gke-down rollout inject-fault clear-fault load-test eval-gate

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
	gcloud container clusters get-credentials interopera-gke-cluster --zone asia-southeast2-a --project ambient-stone-281407 --dns-endpoint

	@echo "=== Step 3: Creating Kubernetes Namespaces ==="
	kubectl create namespace argocd || true
	kubectl create namespace monitoring || true
	kubectl create namespace development || true

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
	@echo "=== Checking GitOps Sync Status ==="
	kubectl get applications -n argocd
	@echo "=== Rollout status of Development namespace deployments ==="
	kubectl rollout status deployment/gateway -n development --timeout=90s
	kubectl rollout status deployment/rag-api -n development --timeout=90s
	kubectl rollout status deployment/model-server -n development --timeout=90s

inject-fault:
	@echo "=== Port-forwarding Private Model Server ==="
	kubectl port-forward svc/model-server 8001:8001 -n development > /dev/null & PID=$$!; \
	sleep 2; \
	echo "=== Injecting 30% Error Rate Fault ==="; \
	curl -X POST http://localhost:8001/admin/fault -H "Content-Type: application/json" -d '{"mode": "error", "rate": 0.3}'; \
	kill $$PID

clear-fault:
	@echo "=== Port-forwarding Private Model Server ==="
	kubectl port-forward svc/model-server 8001:8001 -n development > /dev/null & PID=$$!; \
	sleep 2; \
	echo "=== Clearing Faults ==="; \
	curl -X POST http://localhost:8001/admin/fault -H "Content-Type: application/json" -d '{"mode": "off"}'; \
	kill $$PID

load-test:
	@echo "=== Running Concurrency Load Test ==="
	python3 loadgen/loadgen.py --url https://gateway.srzlab.tech --concurrency 8 --duration 30 --prompts eval/eval_set.jsonl

eval-gate:
	@echo "=== Running Evaluation Gate ==="
	python3 eval/eval_gate.py --url https://gateway.srzlab.tech --eval-set eval/eval_set.jsonl

