# Terragrunt resource configuration for Nginx Ingress static public IP

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/ip"
}

inputs = {
  project_id = "ambient-stone-281407"
  region     = "asia-southeast2"
  ip_name    = "external-ingress"
}
