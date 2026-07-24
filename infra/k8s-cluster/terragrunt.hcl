# Child Terragrunt configuration for the Kind cluster module.
# Sourced locally, it executes Terraform files in the same directory.
include "root" {
  path = find_in_parent_folders()
}
