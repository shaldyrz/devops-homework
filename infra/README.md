# Infrastructure (Terraform & Terragrunt)

This directory contains the infrastructure configuration as code (IaC) for the Interopera project.

## Technologies Used

- **[Terraform](https://www.terraform.io/)**: Used to define and provision the target cloud infrastructure.
- **[Terragrunt](https://terragrunt.gruntwork.io/)**: A thin wrapper for Terraform that provides extra tools for keeping configurations DRY, managing remote state, and orchestrating multiple modules.

## Getting Started

1. **Install Prerequisites**: Make sure you have both `terraform` and `terragrunt` installed:
   ```bash
   brew install terraform terragrunt
   ```
2. **Execution**:
   - Navigate to the specific environment/module folder under `infra/`.
   - Run `terragrunt run-all plan` or `terragrunt plan` to preview the execution plan.
   - Run `terragrunt run-all apply` or `terragrunt apply` to deploy resources.
