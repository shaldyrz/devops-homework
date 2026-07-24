# Terragrunt resource configuration for VPC

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/vpc"
}

inputs = {
  project_id = "ambient-stone-281407"
  region     = "asia-southeast2"
}
