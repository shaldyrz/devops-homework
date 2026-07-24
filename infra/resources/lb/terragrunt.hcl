# Terragrunt resource configuration for Load Balancer IP

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/lb"
}

inputs = {
  project_id = "ambient-stone-281407"
  region     = "asia-southeast2"
}
