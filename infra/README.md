# Infrastructure (Terraform & Terragrunt)

This directory contains the infrastructure configuration as code (IaC) for the Interopera project, separated into Terraform module blueprints and Terragrunt resource configurations.

## Directory Structure

```text
infra/
├── modules/               # Pure Terraform configuration files (blueprints)
│   ├── vpc/               # VPC Network blueprint
│   ├── subnet/            # Subnetwork blueprint with secondary GKE ranges
│   ├── gke/               # GKE Cluster and Spot Node Pool blueprint
│   └── lb/                # Global/Regional Static Load Balancer IP blueprint
└── resources/             # Terragrunt environment configurations
    ├── root.hcl           # Parent Terragrunt configurations (defines GCS state backend)
    ├── vpc/               # Terragrunt VPC module deployment configuration
    ├── subnet/            # Terragrunt Subnet deployment (depends on VPC)
    ├── gke/               # Terragrunt GKE deployment (depends on Subnet & VPC)
    └── lb/                # Terragrunt Load Balancer IP deployment
```

## GKE Node Pool Provisioning

The **GKE Spot Node Pool** is provisioned dynamically alongside the GKE Cluster. It is defined as the `google_container_node_pool` `spot_nodes` resource inside the GKE module:
- [infra/modules/gke/main.tf](file:///Users/flp9shaldyzein/Documents/work/dev/interopera/infra/modules/gke/main.tf#L33-L60)

When you run the GKE module, it will automatically provision the cluster control plane and attach this single-node `e2-medium` Spot VM node pool.

## Getting Started

### 1. Configure Credentials
Before executing, update your Application Default Credentials (ADC) to ensure Terraform accesses Google Cloud using your target account (`zshaldy@gmail.com`):
```bash
gcloud auth application-default login
```

### 2. Execution (Applying All Modules)

Because of the Terragrunt CLI redesign (v0.93+), multi-module commands are run using `run --all` from the `infra/resources/` directory.

- **Plan all resources**:
  ```bash
  cd infra/resources
  terragrunt run --all plan
  ```
  *(Terragrunt will evaluate the dependencies: VPC ➔ Subnet ➔ GKE, and execute plans for all in order)*

- **Apply and provision all resources**:
  ```bash
  cd infra/resources
  terragrunt run --all apply --non-interactive
  ```

- **Teardown all resources**:
  ```bash
  cd infra/resources
  terragrunt run --all destroy --non-interactive
  ```
