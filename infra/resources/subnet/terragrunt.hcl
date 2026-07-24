# Terragrunt resource configuration for Subnet

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/subnet"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id   = "mock-vpc-id"
    vpc_name = "mock-vpc-name"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  project_id = "ambient-stone-281407"
  region     = "asia-southeast2"
  vpc_id     = dependency.vpc.outputs.vpc_id
}
